import CustomDump
import Foundation
import IdentifiedCollections
import IssueReporting
import PerceptionCore

#if canImport(Combine)
  import Combine
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A property wrapper type that shares a read-only value with multiple parts of an application.
@dynamicMemberLookup
@propertyWrapper
public struct SharedReader<Value> {
  private let box: Box
  #if canImport(SwiftUI)
    @State private var generation = 0
  #endif

  var reference: any Reference<Value> {
    @storageRestrictions(initializes: box)
    init(initialValue) { box = Box(initialValue) }
    get { box.reference }
    nonmutating set { box.reference = newValue }
  }

  init(reference: some Reference<Value>) {
    self.box = Box(reference)
  }

  /// Creates a read-only shared reference from a shared reference.
  ///
  /// - Parameter base: A shared reference.
  public init(_ base: Shared<Value>) {
    self.init(reference: base.reference)
  }

  /// Unwraps a read-only shared reference to an optional value.
  ///
  /// ```swift
  /// @SharedReader(.currentUser) var currentUser: User?
  ///
  /// if let sharedUnwrappedUser = SharedReader($currentUser) {
  ///   sharedUnwrappedUser  // SharedReader<User>
  /// }
  /// ```
  ///
  /// - Parameter base: A read-only shared reference to an optional value.
  public init?(_ base: Shared<Value?>) {
    self.init(SharedReader<Value?>(base))
  }

  /// Unwraps a read-only shared reference to an optional value.
  ///
  /// ```swift
  /// @SharedReader(.currentUser) var currentUser: User?
  ///
  /// if let sharedUnwrappedUser = SharedReader($currentUser) {
  ///   sharedUnwrappedUser  // SharedReader<User>
  /// }
  /// ```
  ///
  /// - Parameter base: A read-only shared reference to an optional value.
  public init?(_ base: SharedReader<Value?>) {
    guard let initialValue = base.wrappedValue else { return nil }
    func open(_ reference: some Reference<Value?>) -> any Reference<Value> {
      _OptionalReference(base: reference, initialValue: initialValue)
    }
    self.init(reference: open(base.reference))
  }

  /// Creates a read-only shared reference from another read-only shared reference.
  ///
  /// You don't call this initializer directly. Instead, Swift calls it for you when you use a
  /// property-wrapper attribute on a shared reader closure parameter.
  ///
  /// - Parameter projectedValue: A read-only shared reference.
  public init(projectedValue: Self) {
    self = projectedValue
  }

  /// Constructs a read-only shared value that remains constant.
  ///
  /// This can be useful for providing ``SharedReader`` values to features in previews and tests:
  ///
  /// ```swift
  /// struct CounterView: View {
  ///   @SharedReader var count: Int
  ///   // ...
  /// }
  ///
  /// #Preview {
  ///   CounterView(count: .constant(42))
  /// )
  /// ```
  #if compiler(>=6)
    public static func constant(_ value: sending Value) -> Self {
      Self(Shared(value: value))
    }
  #else
    public static func constant(_ value: Value) -> Self {
      Self(Shared(value: value))
    }
  #endif

  /// The underlying value referenced by the shared variable.
  ///
  /// This property provides primary access to the value's data. However, you don't access
  /// `wrappedValue` directly. Instead, you use the property variable created with the
  /// ``SharedReader`` attribute. In the following example, the shared variable `topics` returns the
  /// value of `wrappedValue`:
  ///
  /// ```swift
  /// @SharedReader var subscriptions: [Subscription]
  ///
  /// var isSubscribed: Bool {
  ///   !subscriptions.isEmpty
  /// }
  /// ```
  public var wrappedValue: Value {
    reference.wrappedValue
  }

  /// A projection of the read-only shared value that returns a shared reference.
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

  /// Returns a read-only shared reference to the resulting value of a given key path.
  ///
  /// You don't call this subscript directly. Instead, Swift calls it for you when you access a
  /// property of the underlying value.
  ///
  /// - Parameter keyPath: A key path to a specific resulting value.
  /// - Returns: A new shared reader.
  public subscript<Member>(
    dynamicMember keyPath: KeyPath<Value, Member>
  ) -> SharedReader<Member> {
    func open(_ reference: some Reference<Value>) -> SharedReader<Member> {
      SharedReader<Member>(
        reference: _AppendKeyPathReference(base: reference, keyPath: keyPath.unsafeSendable())
      )
    }
    return open(reference)
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
  public func load() async throws {
    try await reference.load()
  }

  /// Whether or not an associated shared key is loading data from an external source.
  public var isLoading: Bool {
    reference.isLoading
  }

  /// An error encountered during the most recent attempt to load data.
  ///
  /// This value is `nil` unless a load attempt failed. It contains the latest error from the
  /// underlying ``SharedReaderKey``. Access it from `@Shared`'s projected value:
  ///
  /// ```swift
  /// @SharedReader(.fileStorage(.users)) var users: [User] = []
  ///
  /// var body: some View {
  ///   if let loadError = $users.loadError {
  ///     ContentUnavailableView {
  ///       Label("Failed to load users", systemImage: "xmark.circle")
  ///     } description: {
  ///       Text(loadError.localizedDescription)
  ///     }
  ///   } else {
  ///     ForEach(users) { user in /* ... */ }
  ///   }
  /// }
  /// ```
  ///
  /// > When a load error occurs, ``wrappedValue`` retains results from the last successful fetch.
  /// > Its value will update once a new load succeeds.
  public var loadError: (any Error)? {
    reference.loadError
  }

  private final class Box: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var _reference: any Reference<Value>
    #if canImport(SwiftUI)
      private var cancellable: AnyCancellable?
    #endif
    var reference: any Reference<Value> {
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
    init(_ reference: any Reference<Value>) {
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

extension SharedReader: CustomStringConvertible {
  public var description: String {
    "\(typeName(Self.self, genericsAbbreviated: false))(\(reference.description))"
  }
}

extension SharedReader: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.wrappedValue == rhs.wrappedValue
  }
}

extension SharedReader: Identifiable where Value: Identifiable {
  public var id: Value.ID {
    wrappedValue.id
  }
}

extension SharedReader: Observable {}

#if compiler(>=6)
  extension SharedReader: Sendable {}
#else
  extension SharedReader: @unchecked Sendable {}
#endif

extension SharedReader: Perceptible {}

extension SharedReader: CustomDumpRepresentable {
  public var customDumpValue: Any {
    wrappedValue
  }
}

#if canImport(SwiftUI)
  extension SharedReader: DynamicProperty {
    public func update() {
      box.subscribe(state: _generation)
    }
  }
#endif

// NB: While it would be ideal to make these conformances unavailable, these extensions would
//     actually do the opposite due to a Swift bug: https://github.com/swiftlang/swift/issues/77589
//
// @available(*, unavailable)
// extension SharedReader: Decodable where Value: Decodable {
//   public init(from decoder: any Decoder) throws {
//     fatalError()
//   }
// }
//
// @available(*, unavailable)
// extension SharedReader: Encodable where Value: Encodable {
//   public func encode(to encoder: any Encoder) throws {
//     fatalError()
//   }
// }
//
// @available(*, unavailable)
// extension SharedReader: Hashable where Value: Hashable {
//   public func hash(into hasher: inout Hasher) {
//     fatalError()
//   }
// }
