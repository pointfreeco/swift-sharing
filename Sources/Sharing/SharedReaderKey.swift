import Dependencies

/// A type that can load and subscribe to state in an external system.
///
/// Conform to this protocol to express loading state from an external system, and subscribing to
/// state changes in the external system. It is only necessary to conform to this protocol if the
/// ``AppStorageKey``, ``FileStorageKey``, or ``InMemoryKey`` strategies are not sufficient for your
/// use case.
///
/// See the article <doc:PersistenceStrategies#Custom-persistence> for more information.
public protocol SharedReaderKey<Value>: Sendable {
  /// A type that can be loaded or subscribed to in an external system.
  associatedtype Value: Sendable

  /// A type representing the hashable identity of a shared key.
  associatedtype ID: Hashable = Self

  /// The hashable identity of a shared key.
  ///
  /// Used to look up existing shared references associated with this shared key. For example,
  /// the ``AppStorageKey`` uses the string key and `UserDefaults` instance to define its ID.
  var id: ID { get }

  /// Loads the freshest value from storage.
  ///
  /// - Parameters
  ///   - context: The context of loading a value.
  ///   - continuation: A continuation that can be fed the result of loading a value from an
  ///     external system.
  func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>)

  /// Subscribes to external updates.
  ///
  /// - Parameters:
  ///   - context: The context of subscribing to updates.
  ///   - subscriber: A continuation that can be fed new results from an external system, or the
  ///     initial value if the external system no longer holds a value.
  /// - Returns: A subscription to updates from an external system. If it is cancelled or
  ///   deinitialized, `subscriber` will no longer receive updates from the external system.
  func subscribe(
    context: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription
}

extension SharedReaderKey where ID == Self {
  public var id: ID { self }
}

/// The context in which a value is loaded by a ``SharedReaderKey``.
public enum LoadContext<Value> {
  /// The value is being loaded implicitly at the initialization of a `@Shared` or `@SharedReader`
  /// property (via ``SharedReader/init(wrappedValue:_:)-56tir``).
  ///
  /// The associated value is the same value passed to the `wrappedValue` argument of the
  /// initializer.
  case initialValue(Value)

  /// The value is being loaded explicitly (via ``SharedReader/load()``, ``SharedReader/load(_:)``,
  /// or ``SharedReader/init(require:)``).
  case userInitiated

  /// The value associated with ``LoadContext/initialValue(_:)``.
  public var initialValue: Value? {
    guard case let .initialValue(value) = self else { return nil }
    return value
  }
}

extension LoadContext: Sendable where Value: Sendable {}

extension LoadContext: Equatable where Value: Equatable {}

extension LoadContext: Hashable where Value: Hashable {}

extension SharedReader {
  /// Creates a shared reference to a read-only value using a shared key.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading the
  ///     shared reference's value from some external source.
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: some SharedReaderKey<Value>
  ) {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(rethrowing: wrappedValue(), key, skipInitialLoad: false)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: some SharedKey<Value>
  ) {
    self.init(wrappedValue: wrappedValue(), key)
  }

  /// Creates a shared reference to an optional, read-only value using a shared key.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading the shared reference's value from some external source.
  @_disfavoredOverload
  public init<Wrapped>(_ key: some SharedReaderKey<Value>) where Value == Wrapped? {
    self.init(wrappedValue: nil, key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init<Wrapped>(_ key: some SharedKey<Value>) where Value == Wrapped? {
    self.init(wrappedValue: nil, key)
  }

  /// Creates a shared reference to a read-only value using a shared key with a default value.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading the shared reference's value from some external source.
  public init(_ key: (some SharedReaderKey<Value>).Default) {
    self.init(wrappedValue: key.initialValue, key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(_ key: (some SharedKey<Value>).Default) {
    self.init(key)
  }

  /// Creates a shared reference to a read-only value using a shared key by overriding its
  /// default value.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading the
  ///     shared reference's value from some external source.
  @_disfavoredOverload
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: (some SharedReaderKey<Value>).Default
  ) {
    self.init(wrappedValue: wrappedValue(), key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: (some SharedKey<Value>).Default
  ) {
    self.init(wrappedValue: wrappedValue(), key)
  }

  /// Replaces a shared reference's key and attempts to load its value.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading the shared reference's value from some external source.
  public func load(_ key: some SharedReaderKey<Value>) async throws {
    await MainActor.run {
      @Dependency(PersistentReferences.self) var persistentReferences
      SharedPublisherLocals.$isLoading.withValue(true) {
        projectedValue = SharedReader(
          reference: persistentReferences.value(
            forKey: key,
            default: wrappedValue,
            skipInitialLoad: true
          )
        )
      }
    }
    try await load()
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public func load(_ key: some SharedKey<Value>) async throws {
    try await load(key)
  }

  /// Creates a shared reference to a read-only value using a shared key by loading it from its
  /// external source.
  ///
  /// If the given shared key cannot load a value, an error is thrown. For a non-throwing,
  /// synchronous version of this initializer, see ``init(wrappedValue:_:)-56tir``.
  ///
  /// This initializer should only be used to create a brand new shared reference from a key. To
  /// replace the key of an existing shared reference, use ``load(_:)``, instead.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading the shared reference's value from some external source.
  public init(require key: some SharedReaderKey<Value>) async throws {
    let value = try await withUnsafeThrowingContinuation { continuation in
      key.load(
        context: .userInitiated,
        continuation: LoadContinuation { result in
          continuation.resume(with: result)
        }
      )
    }
    guard let value else { throw LoadError() }
    self.init(rethrowing: value, key, skipInitialLoad: true)
    if let loadError { throw loadError }
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(require key: some SharedKey<Value>) async throws {
    try await self.init(require: key)
  }

  @available(*, unavailable, message: "Assign a default value")
  public init(_ key: some SharedReaderKey<Value>) {
    fatalError()
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  @available(*, unavailable, message: "Assign a default value")
  public init(_ key: some SharedKey<Value>) {
    fatalError()
  }

  private init(
    rethrowing value: @autoclosure () throws -> Value, _ key: some SharedReaderKey<Value>,
    skipInitialLoad: Bool
  ) rethrows {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(
      reference: try persistentReferences.value(
        forKey: key,
        default: try value(),
        skipInitialLoad: skipInitialLoad
      )
    )
  }

  private struct LoadError: Error {}
}
