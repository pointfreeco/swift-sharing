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
  ///   - context: The context of saving a value.
  ///   - continuation: A continuation that should be notified upon the completion of saving a
  ///     shared value.
  func save(_ value: Value, context: SaveContext, continuation: SaveContinuation)
}

/// The context in which a value is saved by a ``SharedKey``.
///
/// A key may use this context to determine the behavior of the save. For example, an external
/// system that may be expensive to write to very frequently (_i.e._ network or file IO) could
/// choose to debounce saves when the value is simply updated in memory (via
/// ``Shared/withLock(_:fileID:filePath:line:column:)``), but forgo debouncing with an immediate
/// write when the value is saved explicitly (via ``Shared/save()``).
public enum SaveContext: Hashable, Sendable {
  /// The value is being saved implicitly (after a mutation via
  /// ``Shared/withLock(_:fileID:filePath:line:column:)``).
  case didSet

  /// The value is being saved explicitly (via ``Shared/save()``).
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
    self.init(rethrowing: wrappedValue(), key, skipInitialLoad: false)
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

  /// Replaces a shared reference's key and attempts to load its value.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  public func load(_ key: some SharedKey<Value>) async throws {
    await MainActor.run {
      @Dependency(PersistentReferences.self) var persistentReferences
      projectedValue = Shared(
        reference: persistentReferences.value(
          forKey: key,
          default: wrappedValue,
          skipInitialLoad: true
        )
      )
    }
    try await reference.load()
  }

  /// Creates a shared reference to a value using a shared key by loading it from its external
  /// source.
  ///
  /// If the given shared key cannot load a value, an error is thrown. For a non-throwing,
  /// synchronous version of this initializer, see ``init(wrappedValue:_:)-5xce4``.
  ///
  /// This initializer should only be used to create a brand new shared reference from a key. To
  /// replace the key of an existing shared reference, use ``load(_:)``, instead.
  ///
  /// - Parameter key: A shared key associated with the shared reference. It is responsible for
  ///   loading and saving the shared reference's value from some external source.
  public init(require key: some SharedKey<Value>) async throws {
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

  @available(*, unavailable, message: "Assign a default value")
  public init(_ key: some SharedKey<Value>) {
    fatalError()
  }

  private init(
    rethrowing value: @autoclosure () throws -> Value, _ key: some SharedKey<Value>,
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
