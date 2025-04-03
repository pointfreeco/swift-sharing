import Foundation

#if compiler(>=6)
  /// A synchronization primitive that protects shared mutable state via mutual exclusion.
  ///
  /// A back-port of Swift's `Mutex` type for wider platform availability.
  #if hasFeature(StaticExclusiveOnly)
    @_staticExclusiveOnly
  #endif
  package struct Mutex<Value: ~Copyable>: ~Copyable {
    private let _lock = NSLock()
    private let _box: Box

    /// Initializes a value of this mutex with the given initial state.
    ///
    /// - Parameter initialValue: The initial value to give to the mutex.
    package init(_ initialValue: consuming sending Value) {
      _box = Box(initialValue)
    }

    private final class Box {
      var value: Value
      init(_ initialValue: consuming sending Value) {
        value = initialValue
      }
    }
  }

  extension Mutex: @unchecked Sendable where Value: ~Copyable {}

  extension Mutex where Value: ~Copyable {
    /// Calls the given closure after acquiring the lock and then releases ownership.
    borrowing package func withLock<Result: ~Copyable, E: Error>(
      _ body: (inout sending Value) throws(E) -> sending Result
    ) throws(E) -> sending Result {
      _lock.lock()
      defer { _lock.unlock() }
      return try body(&_box.value)
    }

    /// Attempts to acquire the lock and then calls the given closure if successful.
    borrowing package func withLockIfAvailable<Result: ~Copyable, E: Error>(
      _ body: (inout sending Value) throws(E) -> sending Result
    ) throws(E) -> sending Result? {
      guard _lock.try() else { return nil }
      defer { _lock.unlock() }
      return try body(&_box.value)
    }
  }
#else
  package struct Mutex<Value> {
    private let _lock = NSLock()
    private let _box: Box

    package init(_ initialValue: consuming Value) {
      _box = Box(initialValue)
    }

    private final class Box {
      var value: Value
      init(_ initialValue: consuming Value) {
        value = initialValue
      }
    }
  }

  extension Mutex: @unchecked Sendable {}

  extension Mutex {
    borrowing package func withLock<Result>(
      _ body: (inout Value) throws -> Result
    ) rethrows -> Result {
      _lock.lock()
      defer { _lock.unlock() }
      return try body(&_box.value)
    }

    borrowing package func withLockIfAvailable<Result>(
      _ body: (inout Value) throws -> Result
    ) rethrows -> Result? {
      guard _lock.try() else { return nil }
      defer { _lock.unlock() }
      return try body(&_box.value)
    }
  }
#endif

extension Mutex where Value == Void {
  borrowing package func _unsafeLock() {
    _lock.lock()
  }

  borrowing package func _unsafeTryLock() -> Bool {
    _lock.try()
  }

  borrowing package func _unsafeUnlock() {
    _lock.unlock()
  }
}
