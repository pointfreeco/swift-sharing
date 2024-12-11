import CustomDump
import Dependencies
import Foundation
import IdentifiedCollections
import PerceptionCore

#if canImport(Combine)
  import Combine
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A property wrapper type that shares a value with other parts of the application and/or external
/// systems.
@dynamicMemberLookup
@propertyWrapper
public struct Shared<Value> {
  private let box: Box
  #if canImport(SwiftUI)
    @State private var generation = 0
  #endif

  var reference: any MutableReference<Value> {
    @storageRestrictions(initializes: box)
    init(initialValue) { box = Box(initialValue) }
    get { box.reference }
    nonmutating set { box.reference = newValue }
  }

  init(reference: any MutableReference<Value>) {
    #if canImport(SwiftUI)
      if !isTesting, Value.self is any _MutableIdentifiedCollection.Type {
        func open(_ reference: some MutableReference<Value>) -> any MutableReference<Value> {
          _CachedReference(base: reference)
        }
        self.box = Box(open(reference))
        return
      }
    #endif
    self.box = Box(reference)
  }

  /// Wraps a value in a shared reference.
  ///
  /// - Parameters:
  ///   - value: A value to wrap.
  #if compiler(>=6)
  public init(value: sending Value) {
    self.init(reference: _BoxReference(wrappedValue: value))
  }
  #else
  public init(value: Value) {
    self.init(reference: _BoxReference(wrappedValue: value))
  }
  #endif

  /// Unwraps a shared reference to an optional value.
  ///
  /// ```swift
  /// @Shared(.currentUser) var currentUser: User?
  ///
  /// if let sharedUnwrappedUser = Shared($currentUser) {
  ///   sharedUnwrappedUser  // Shared<User>
  /// }
  /// ```
  ///
  /// - Parameter base: A shared reference to an optional value.
  public init?(_ base: Shared<Value?>) {
    guard let initialValue = base.wrappedValue else { return nil }
    func open(_ reference: some MutableReference<Value?>) -> any MutableReference<Value> {
      _OptionalReference(base: reference, initialValue: initialValue)
    }
    self.init(reference: open(base.reference))
  }

  /// Creates a shared reference from another shared reference.
  ///
  /// You don't call this initializer directly. Instead, Swift calls it for you when you use a
  /// property-wrapper attribute on a shared closure parameter.
  ///
  /// - Parameter projectedValue: A shared reference.
  public init(projectedValue: Self) {
    self = projectedValue
  }

  /// The underlying value referenced by the shared variable.
  ///
  /// This property provides primary access to the value's data. However, you don't access
  /// `wrappedValue` directly. Instead, you use the property variable created with the ``Shared``
  /// attribute. In the following example, the shared variable `count` returns the value of
  /// `wrappedValue`:
  ///
  /// ```swift
  /// struct CounterView: View {
  ///   @Shared var count: Int
  ///
  ///   var body: some View {
  ///     Text("\(count)")
  ///     Button("Increment) { /* ... */ }
  ///     Button("Decrement) { /* ... */ }
  ///   }
  /// }
  /// ```
  public var wrappedValue: Value {
    get {
      @Dependency(\.snapshots) var snapshots
      if snapshots.isAsserting {
        return reference.snapshot ?? reference.wrappedValue
      } else {
        return reference.wrappedValue
      }
    }
    @available(
      *,
      unavailable,
      message: "Use '$shared.withLock' to modify a shared value with exclusive access."
    )
    nonmutating set {
      withLock { $0 = newValue }
    }
  }

  /// Perform an operation on shared state with isolated access to the underlying value.
  /// 
  /// See <doc:MutatingSharedState> for more information.
  /// 
  /// - Parameters
  ///   - operation: An operation given mutable, isolated access to the underlying shared value.
  ///   - fileID: The source `#fileID` associated with the lock.
  ///   - filePath: The source `#filePath` associated with the lock.
  ///   - line: The source `#line` associated with the lock.
  ///   - column: The source `#column` associated with the lock.
  /// - Returns: The value returned from `operation`.
  public func withLock<R>(
    _ operation: (inout Value) throws -> R,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) rethrows -> R {
    try reference.withLock { value in
      @Dependency(\.snapshots) var snapshots
      if snapshots.isAsserting {
        var snapshot = reference.snapshot ?? reference.wrappedValue
        defer {
          reference.takeSnapshot(
            snapshot,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
          )
        }
        return try operation(&snapshot)
      } else if snapshots.isTracking, reference.snapshot == nil {
        reference.takeSnapshot(
          value,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
      }
      return try operation(&value)
    }
  }

  /// A projection of the shared value that returns a shared reference.
  ///
  /// Use the projected value to pass a shared value down to another feature. This is most
  /// commonly done to share a value from one feature to another:
  ///
  /// ```swift
  /// struct SignUpView: View {
  ///   @Shared var signUpData: SignUpData
  ///
  ///   var body: some View {
  ///     // ...
  ///     PersonalInfoView(
  ///       signUpData: $signUpData
  ///     )
  ///   }
  /// }
  ///
  /// struct PersonalInfoView: View {
  ///   @Shared var signUpData: SignUpData
  ///   // ...
  /// }
  /// ```
  ///
  /// Further you can use dot-chaining syntax to derive a smaller piece of shared state to hand
  /// to another feature:
  ///
  /// ```swift
  /// struct SignUpView: View {
  ///   @Shared var signUpData: SignUpData
  ///
  ///   var body: some View {
  ///     // ...
  ///     PhoneNumberView(
  ///       signUpData: $signUpData.phoneNumber
  ///     )
  ///   }
  /// }
  ///
  /// PhoneNumberView(
  ///   phoneNumber: $signUpData.phoneNumber
  /// )
  /// ```
  ///
  /// See <doc:DerivingSharedState> for more details.
  public var projectedValue: Self {
    get {
      _ = reference.wrappedValue
      return self
    }
    nonmutating set {
      reference.touch()
      reference = newValue.reference
    }
  }

  /// Returns a shared reference to the resulting value of a given key path.
  ///
  /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
  /// property of the underlying value. In the following example, the property access
  /// `$signUpData.topics` returns the value of invoking this subscript with `\SignUpData.topics`:
  ///
  /// ```swift
  /// @Shared var signUpData: SignUpData
  ///
  /// $signUpData.topics  // Shared<Set<Topic>>
  /// ```
  ///
  /// - Parameter keyPath: A key path to a specific resulting value.
  /// - Returns: A new shared reference.
  public subscript<Member>(
    dynamicMember keyPath: WritableKeyPath<Value, Member>
  ) -> Shared<Member> {
    func open(_ reference: some MutableReference<Value>) -> Shared<Member> {
      Shared<Member>(
        reference: _AppendKeyPathReference(base: reference, keyPath: keyPath.unsafeSendable())
      )
    }
    return open(reference)
  }

  /// Returns a read-only shared reference to the resulting value of a given key path.
  ///
  /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
  /// property of the underlying value. In the following example, the property access
  /// `$topics.count` returns the value of invoking this subscript with `\Set<Topic>.count`:
  ///
  /// ```swift
  /// @Shared var topics: Set<Topic>
  ///
  /// $topics.count  // SharedReader<Int>
  /// ```
  ///
  /// - Parameter keyPath: A key path to a specific resulting value.
  /// - Returns: A new read-only shared reference.
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value, Member>
  ) -> SharedReader<Member> {
    SharedReader(self)[dynamicMember: keyPath]
  }

  /// Requests an up-to-date value from an external source.
  ///
  /// When a shared reference is powered by a ``SharedReaderKey``, this method will tell it to
  /// reload its value from the associated external source.
  ///
  /// Most of the time it is not necessary to call this method, as persistence strategies will often
  /// subscribe directly to the external source and automatically keep the shared reference
  /// synchronized. Some persistence strategies, however, may not have the ability to subscribe to
  /// their external source. In these cases, you should call this method whenever you need the most
  /// up-to-date value.
  public func load() {
    reference.load()
  }

  /// Requests the underlying value be persisted to an external source.
  ///
  /// When a shared reference is powered by a ``SharedKey``, this method will tell it to save its
  /// value to the associated external source.
  ///
  /// Most of the time it is not necessary to call this method, as persistence strategies will often
  /// save to the external source immediately upon modification. Some persistence strategies,
  /// however, may choose to debounce this work, in which case it may be desirable to tell the
  /// strategy to save more eagerly.
  public func save() {
    reference.save()
  }

  private final class Box: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var _reference: any MutableReference<Value>
    #if canImport(SwiftUI)
      private var cancellable: AnyCancellable?
    #endif
    var reference: any MutableReference<Value> {
      _read {
        lock.lock()
        defer { lock.unlock() }
        yield _reference
      }
      _modify {
        lock.lock()
        defer { lock.unlock() }
        yield &_reference
      }
      set {
        lock.withLock { _reference = newValue }
      }
    }
    init(_ reference: any MutableReference<Value>) {
      self._reference = reference
    }
    #if canImport(SwiftUI)
      func subscribe(state: State<Int>) {
        guard #unavailable(iOS 17, macOS 14, tvOS 17, watchOS 10) else { return }
        _ = state.wrappedValue
        func open(_ publisher: some Publisher<Value, Never>) -> AnyCancellable {
          publisher.dropFirst().sink { _ in
            state.wrappedValue &+= 1
          }
        }
        let cancellable = open(_reference.publisher)
        lock.withLock { self.cancellable = cancellable }
      }
    #endif
  }
}

extension Shared: CustomStringConvertible {
  public var description: String {
    "\(typeName(Self.self, genericsAbbreviated: false))(\(reference.description))"
  }
}

extension Shared: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    func open<T: MutableReference<Value>>(_ lhsReference: T) -> Bool {
      @Dependency(\.snapshots) var snapshots
      guard snapshots.isAsserting, lhsReference == rhs.reference as? T else { return false }
      snapshots.untrack(lhsReference)
      return true
    }
    if open(lhs.reference) {
      return lhs.wrappedValue == rhs.reference.wrappedValue
    } else {
      return lhs.wrappedValue == rhs.wrappedValue
    }
    // TODO: Explore 'isTesting ? (check snapshot against value) : lhs.reference == rhs.reference
  }
}

extension Shared: Identifiable where Value: Identifiable {
  public var id: Value.ID {
    wrappedValue.id
  }
}

extension Shared: Observable {}

#if compiler(>=6)
  extension Shared: Sendable {}
#else
  extension Shared: @unchecked Sendable {}
#endif

extension Shared: Perceptible {}

extension Shared: CustomDumpRepresentable {
  public var customDumpValue: Any {
    wrappedValue
  }
}

extension Shared: _CustomDiffObject {
  public var _customDiffValues: (Any, Any) {
    (reference.snapshot ?? reference.wrappedValue, reference.wrappedValue)
  }

  public var _objectIdentifier: ObjectIdentifier {
    func open(_ reference: some MutableReference<Value>) -> ObjectIdentifier {
      reference.id
    }
    return open(reference)
  }
}

#if canImport(SwiftUI)
  extension Shared: DynamicProperty {
    public func update() {
      box.subscribe(state: _generation)
    }
  }
#endif

// NB: While it would be ideal to make these conformances unavailable, these extensions would
//     actually do the opposite due to a Swift bug: https://github.com/swiftlang/swift/issues/77589
//
// @available(*, unavailable)
// extension Shared: Decodable where Value: Decodable {
//   public init(from decoder: any Decoder) throws {
//     fatalError()
//   }
// }
//
// @available(*, unavailable)
// extension Shared: Encodable where Value: Encodable {
//   public func encode(to encoder: any Encoder) throws {
//     fatalError()
//   }
// }
//
// @available(*, unavailable)
// extension Shared: Hashable where Value: Hashable {
//   public func hash(into hasher: inout Hasher) {
//     fatalError()
//   }
// }
