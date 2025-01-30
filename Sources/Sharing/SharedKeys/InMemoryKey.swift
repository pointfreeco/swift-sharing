import Dependencies
import Foundation

extension SharedReaderKey {
  /// Creates a shared key for sharing data in-memory for the lifetime of an application.
  ///
  /// For example, one could initialize a key with the date and time at which the application was
  /// most recently launched, and access this date from anywhere using the ``Shared`` property
  /// wrapper:
  ///
  /// ```swift
  /// @main
  /// struct MyApp: App {
  ///   init() {
  ///     @Shared(.inMemory("appLaunchedAt")) var appLaunchedAt = Date()
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// - Parameter key: A string key identifying a value to share in memory.
  /// - Returns: An in-memory shared key.
  public static func inMemory<Value>(_ key: String) -> Self
  where Self == InMemoryKey<Value> {
    InMemoryKey(key)
  }
}

/// A type defining an in-memory persistence strategy
///
/// See ``SharedReaderKey/inMemory(_:)`` to create values of this type.
public struct InMemoryKey<Value: Sendable>: SharedKey {
  private let key: String
  private let store: InMemoryStorage
  fileprivate init(_ key: String) {
    @Dependency(\.defaultInMemoryStorage) var defaultInMemoryStorage
    self.key = key
    self.store = defaultInMemoryStorage
  }
  public var id: InMemoryKeyID {
    InMemoryKeyID(key: key, store: store)
  }
  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    switch context {
    case .initialValue(let initialValue):
      continuation.resume(returning: store.values[key, default: initialValue])
    case .userInitiated:
      switch store.values[key] {
      case let .some(value as Value):
        continuation.resume(returning: value)
      default:
        continuation.resumeReturningInitialValue()
      }
    }
  }
  public func subscribe(
    context _: LoadContext<Value>, subscriber _: SharedSubscriber<Value>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
  public func save(_ value: Value, context _: SaveContext, continuation: SaveContinuation) {
    store.values[key] = value
    continuation.resume()
  }
}

extension InMemoryKey: CustomStringConvertible {
  public var description: String {
    ".inMemory(\(String(reflecting: key)))"
  }
}

public struct InMemoryStorage: Hashable, Sendable {
  private let id = UUID()
  fileprivate let values = Values()
  public init() {}
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  fileprivate final class Values: Sendable {
    let storage = Mutex<[String: any Sendable]>([:])

    subscript(key: String) -> (any Sendable)? {
      get { storage.withLock { $0[key] } }
      set { storage.withLock { $0[key] = newValue } }
    }

    subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value {
      storage.withLock { storage in
        switch storage[key] {
        case let .some(value as Value):
          return value
        default:
          storage[key] = defaultValue
          return defaultValue
        }
      }
    }
  }
}

public struct InMemoryKeyID: Hashable {
  let key: String
  let store: InMemoryStorage
}

private enum DefaultInMemoryStorageKey: DependencyKey {
  static var liveValue: InMemoryStorage { InMemoryStorage() }
  static var testValue: InMemoryStorage { InMemoryStorage() }
}

extension DependencyValues {
  public var defaultInMemoryStorage: InMemoryStorage {
    get { self[DefaultInMemoryStorageKey.self] }
    set { self[DefaultInMemoryStorageKey.self] = newValue }
  }
}
