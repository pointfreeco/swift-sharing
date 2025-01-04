import Dependencies
import Foundation
import PerceptionCore

final class PersistentReferences: @unchecked Sendable, DependencyKey {
  static var liveValue: PersistentReferences { PersistentReferences() }
  static var testValue: PersistentReferences { PersistentReferences() }

  struct Pair<Key: SharedReaderKey> {
    var cachedValue: Key.Value
    var reference: _PersistentReference<Key>?
  }

  private var storage: [AnyHashable: Any] = [:]
  private let lock = NSRecursiveLock()

  func value<Key: SharedReaderKey>(
    forKey key: Key,
    default value: @autoclosure () throws -> Key.Value,
    isPreloaded: Bool
  ) rethrows -> _ManagedReference<Key> {
    try lock.withLock {
      guard var pair = storage[key.id] as? Pair<Key> else {
        let value = try value()
        let persistentReference = _PersistentReference(
          key: key,
          value: value,
          isPreloaded: isPreloaded
        )
        storage[key.id] = Pair(cachedValue: value, reference: persistentReference)
        return _ManagedReference(persistentReference)
      }
      guard let persistentReference = pair.reference else {
        let persistentReference = _PersistentReference(
          key: key,
          value: isPreloaded ? (try? value()) ?? pair.cachedValue : pair.cachedValue,
          isPreloaded: isPreloaded
        )
        pair.reference = persistentReference
        storage[key.id] = pair
        return _ManagedReference(persistentReference)
      }
      return _ManagedReference(persistentReference)
    }
  }

  func removeReference<Key: SharedReaderKey>(forKey key: Key) {
    lock.withLock {
      guard var pair = storage[key.id] as? Pair<Key> else { return }
      pair.reference = nil
      storage[key.id] = pair
    }
  }
}
