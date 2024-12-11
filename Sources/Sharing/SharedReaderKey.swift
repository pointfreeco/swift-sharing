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
  /// The `initialValue` provided can be used to supply a value in case the external storage has
  /// no value. This method is synchronous which means you cannot perform asynchronous work in it.
  /// If that is necessary to load the initial value from your external source, you can use the
  /// ``SharedReaderKey/subscribe(initialValue:didSet:)`` method.
  ///
  /// - Parameter initialValue: An initial value assigned to the `@Shared` property.
  /// - Returns: An initial value provided by an external system, or `nil`.
  func load(initialValue: Value?) -> Value?

  /// Subscribes to external updates.
  ///
  /// - Parameters:
  ///   - initialValue: An initial value assigned to the `@Shared` property.
  ///   - receiveValue: A closure that is invoked with new values from an external system, or `nil`
  ///     if the external system no longer holds a value.
  /// - Returns: A subscription to updates from an external system. If it is cancelled or
  ///   deinitialized, the `didSet` closure will no longer be invoked.
  func subscribe(
    initialValue: Value?, didSet receiveValue: @escaping @Sendable (Value?) -> Void
  ) -> SharedSubscription
}

extension SharedReaderKey where ID == Self {
  public var id: ID { self }
}

extension SharedReader {
  /// Creates a shared reference to a read-only value using a shared key.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading
  ///     and saving the shared reference's value from some external source.
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: some SharedReaderKey<Value>
  ) {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(rethrowing: wrappedValue(), key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: some SharedKey<Value>
  ) {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(rethrowing: wrappedValue(), key)
  }

  /// Creates a shared reference to an optional, read-only value using a shared key.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
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
  ///   loading and saving the shared reference's value from some external source.
  public init(_ key: (some SharedReaderKey<Value>).Default) {
    self.init(wrappedValue: key.defaultValue(), key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(_ key: (some SharedKey<Value>).Default) {
    self.init(wrappedValue: key.defaultValue(), key)
  }

  /// Creates a shared reference to a read-only value using a shared key by overriding its
  /// default value.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading
  ///     and saving the shared reference's value from some external source.
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

  /// Creates a shared reference to a read-only value using a shared key.
  ///
  /// If the given shared key cannot load a value, an error is thrown. For a non-throwing
  /// version of this initializer, see ``init(wrappedValue:_:)-56tir``.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  public init(require key: some SharedReaderKey<Value>) throws {
    let value = {
      guard let value = key.load(initialValue: nil) else { throw LoadError() }
      return value
    }
    try self.init(rethrowing: value(), key)
  }

  @_disfavoredOverload
  @_documentation(visibility: private)
  public init(require key: some SharedKey<Value>) throws {
    let value = {
      guard let value = key.load(initialValue: nil) else { throw LoadError() }
      return value
    }
    try self.init(rethrowing: value(), key)
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
    rethrowing value: @autoclosure () throws -> Value, _ key: some SharedReaderKey<Value>
  ) rethrows {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(reference: try persistentReferences.value(forKey: key, default: try value()))
  }
  private struct LoadError: Error {}
}
