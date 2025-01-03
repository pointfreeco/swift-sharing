import Dependencies

/// A type that can persist shared state to an external storage.
///
/// Conform to this protocol to express persistence to some external storage by describing how to
/// save to and load from the external storage, and providing a stream of values that represents
/// when the external storage is changed from the outside. It is only necessary to conform to this
/// protocol if the ``AppStorageKey``, ``FileStorageKey``, or ``InMemoryKey`` strategies are not
/// sufficient for your use case.
///
/// See the article <doc:PersistenceStrategies#Custom-persistence> for more information.
public protocol SharedKey<Value>: SharedReaderKey {
  /// Saves a value to storage.
  ///
  /// - Parameters:
  ///   - value: The value to save.
  ///   - immediately: Tells the shared key to save the value as soon as possible. A key may choose
  ///     by default to delay writing to an external source in some way, for example throttling or
  ///     debouncing, if `immediately` is `false`. If `immediately` is `true` it should bypass these
  ///     delays.
  ///   - continuation: A continuation that should be notified upon the completion of saving a
  ///     shared value.
  func save(_ value: Value, context: SaveContext) async throws 
}

public enum SaveContext: Sendable {
  /// Value is being saved after mutation via ``Shared/withLock(_:fileID:filePath:line:column:)``.
  case didSet

  /// Value is being saved via ``Shared/save()``.
  case userInitiated
}

extension Shared {
  /// Creates a shared reference to a value using a shared key.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading
  ///     and saving the shared reference's value from some external source.
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: some SharedKey<Value>
  ) {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(rethrowing: wrappedValue(), key, isPreloaded: false)
  }

  /// Creates a shared reference to an optional value using a shared key.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  @_disfavoredOverload
  public init<Wrapped>(_ key: some SharedKey<Value>) where Value == Wrapped? {
    self.init(wrappedValue: nil, key)
  }

  /// Creates a shared reference to a value using a shared key with a default value.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  public init(_ key: (some SharedKey<Value>).Default) {
    self.init(wrappedValue: key.defaultValue(), key)
  }

  /// Creates a shared reference to a value using a shared key by overriding its default value.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value that is used when no value can be returned from the
  ///     shared key.
  ///   - key: A shared key associated with the shared reference. It is responsible for loading
  ///     and saving the shared reference's value from some external source.
  @_disfavoredOverload
  public init(
    wrappedValue: @autoclosure () -> Value,
    _ key: (some SharedKey<Value>).Default
  ) {
    self.init(wrappedValue: wrappedValue(), key)
  }

  /// Creates a shared reference to a value using a shared key.
  ///
  /// If the given shared key cannot load a value, an error is thrown. For a non-throwing
  /// version of this initializer, see ``init(wrappedValue:_:)-5xce4``.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  public init<Key: SharedKey<Value>>(require key: Key) async throws {
    let value = try await key.load(context: .userInitiated)
    guard let value = value.newValue else { throw LoadError() }
    self.init(rethrowing: value, key, isPreloaded: true)
    if let loadError { throw loadError }
  }

  @available(*, unavailable, message: "Assign a default value")
  public init(_ key: some SharedKey<Value>) {
    fatalError()
  }

  private init(
    rethrowing value: @autoclosure () throws -> Value, _ key: some SharedKey<Value>,
    isPreloaded: Bool
  ) rethrows {
    @Dependency(PersistentReferences.self) var persistentReferences
    self.init(
      reference: try persistentReferences.value(
        forKey: key,
        default: try value(),
        isPreloaded: isPreloaded
      )
    )
  }

  private struct LoadError: Error {}
}
