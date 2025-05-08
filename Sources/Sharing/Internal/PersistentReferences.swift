import Dependencies
import Foundation
import PerceptionCore

final class PersistentReferences: @unchecked Sendable, DependencyKey {
  static var liveValue: PersistentReferences { PersistentReferences() }
  static var testValue: PersistentReferences { PersistentReferences() }

  struct Weak<Key: SharedReaderKey> {
    weak var reference: _PersistentReference<Key>?
  }

  private var storage: [AnyHashable: Any] = [:]
  private let lock = NSRecursiveLock()

  func value<Key: SharedReaderKey>(
    forKey key: Key,
    default value: @autoclosure () throws -> Key.Value,
    skipInitialLoad: Bool
  ) rethrows -> _PersistentReference<Key> {
    if let reference = lock.withLock({ (storage[key.id] as? Weak<Key>)?.reference }) {
      return reference
    } else {
      let value = try value()
      let reference = _PersistentReference(
        key: key,
        value: value,
        skipInitialLoad: skipInitialLoad
      )
      return lock.withLock {
        if let reference = (storage[key.id] as? Weak<Key>)?.reference {
          return reference
        } else {
          storage[key.id] = Weak(reference: reference)
          reference.onDeinit = { [self] in
            removeReference(forKey: key)
          }
          return reference
        }
      }
    }
  }

  func removeReference<Key: SharedReaderKey>(forKey key: Key) {
    lock.withLock {
      _ = storage.removeValue(forKey: key.id)
    }
  }
}
