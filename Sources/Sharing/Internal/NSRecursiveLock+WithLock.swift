#if swift(<6) && !os(iOS) && !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)
  import Foundation

  extension NSRecursiveLock {
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
      lock()
      defer { unlock() }
      return try body()
    }
  }
#endif
