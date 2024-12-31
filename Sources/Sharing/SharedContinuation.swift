import Foundation
import IssueReporting

/// A mechanism to communicate with a shared key's external system, synchronously or asynchronously.
///
/// A continuation is passed to ``SharedReaderKey/load(initialValue:continuation:)`` and
/// ``SharedKey/save(_:immediately:continuation:)`` so that state can be shared with an external
/// system.
///
/// > Important: You must call a resume method exactly once on every execution path from the shared
/// > key it is passed to, _i.e._ in ``SharedReaderKey/load(initialValue:continuation:)`` and
/// > ``SharedKey/save(_:immediately:continuation:)``.
/// >
/// > Resuming from a continuation more than once is considered a logic error, and only the first
/// > call to `resume` will be executed. Never resuming leaves the task awaiting the call to
/// > ``Shared/load()`` or ``Shared/save()`` in a suspended state indefinitely and leaks any
/// > associated resources. `SharedContinuation` reports an issue if either of these invariants is
/// > violated.
public struct SharedContinuation<Value>: Sendable {
  private let box: Box

  package init(
    _ description: @autoclosure @escaping @Sendable () -> String = "",
    callback: @escaping @Sendable (Result<Value, any Error>) -> Void
  ) {
    self.box = Box(
      callback: callback,
      description: {
        let description = description()
        return description.isEmpty ? "A shared key" : "'\(description)'"
      }
    )
  }

  /// Resume the task awaiting the continuation by having it return normally from its suspension
  /// point.
  ///
  /// - Parameter value: The value to return from the continuation.
  public func resume(returning value: Value) {
    resume(with: .success(value))
  }

  /// Resume the task awaiting the continuation by having it throw an error from its
  /// suspension point.
  ///
  /// - Parameter error: The error to throw from the continuation.
  public func resume(throwing error: any Error) {
    resume(with: .failure(error))
  }

  /// Resume the task awaiting the continuation by having it return normally from its suspension
  /// point.
  public func resume() where Value == Void {
    resume(returning: ())
  }

  /// Resume the task awaiting the continuation by having it either return normally or throw an
  /// error based on the state of the given `Result` value.
  ///
  /// - Parameter result: A value to either return or throw from the
  ///   continuation.
  public func resume(with result: Result<Value, any Error>) {
    box.resume(with: result)
  }

  private final class Box: Sendable {
    private let callback: Mutex<(@Sendable (Result<Value, any Error>) -> Void)?>
    private let description: @Sendable () -> String
    private let resumeCount = Mutex(0)

    init(
      callback: @escaping @Sendable (Result<Value, any Error>) -> Void,
      description: @escaping @Sendable () -> String
    ) {
      self.callback = Mutex(callback)
      self.description = description
    }

    deinit {
      let isComplete = resumeCount.withLock(\.self) > 0
      if !isComplete {
        reportIssue(
          """
          \(description()) leaked its continuation without resuming it. This may cause tasks \
          waiting on it to remain suspended forever.
          """
        )
      }
    }

    func resume(with result: Result<Value, any Error>) {
      let resumeCount = resumeCount.withLock {
        $0 += 1
        return $0
      }
      guard resumeCount == 1 else {
        reportIssue(
          """
          \(description()) tried to resume its continuation more than once.
          """
        )
        return
      }
      callback.withLock { callback in
        defer { callback = nil }
        callback?(result)
      }
    }
  }
}
