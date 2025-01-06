import Foundation
import IssueReporting

/// A mechanism to communicate with a shared key's external system, synchronously or asynchronously.
///
/// A continuation is passed to ``SharedReaderKey/load(context:continuation:)`` so that state
/// can be shared from an external system.
///
/// > Important: You must call a resume method exactly once on every execution path from the shared
/// > key it is passed to, _i.e._ in ``SharedReaderKey/load(context:continuation:)``.
/// >
/// > Resuming from a continuation more than once is considered a logic error, and only the first
/// > call to `resume` will be executed. Never resuming leaves the task awaiting the call to
/// > ``Shared/load()`` in a suspended state indefinitely and leaks any associated resources.
/// > `LoadContinuation` reports an issue if either of these invariants is violated.
public struct LoadContinuation<Value>: Sendable {
  private let box: ContinuationBox<Value>

  package init(
    _ description: @autoclosure @escaping @Sendable () -> String = "",
    callback: @escaping @Sendable (Result<Value?, any Error>) -> Void
  ) {
    self.box = ContinuationBox(
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

  /// Resume the task awaiting the continuation by having it return the initial value from its
  /// suspension point.
  public func resumeReturningInitialValue() {
    resume(with: .success(nil))
  }

  /// Resume the task awaiting the continuation by having it either return normally or throw an
  /// error based on the state of the given `Result` value.
  ///
  /// - Parameter result: A value to either return or throw from the
  ///   continuation.
  public func resume(with result: Result<Value?, any Error>) {
    box.resume(with: result)
  }
}

/// A mechanism to synchronize with a shared key's external system.
///
/// A subscriber is passed to ``SharedReaderKey/subscribe(context:subscriber:)`` so that updates to
/// an external system can be shared.
public struct SharedSubscriber<Value>: Sendable {
  let callback: @Sendable (Result<Value?, any Error>) -> Void

  package init(callback: @escaping @Sendable (Result<Value?, any Error>) -> Void) {
    self.callback = callback
  }

  /// Yield an updated value from an external source.
  ///
  /// - Parameter value: An updated value.
  public func yield(_ value: Value) {
    yield(with: .success(value))
  }

  /// Yield the initial value provided to the property wrapper when none exists in the external
  /// source.
  ///
  /// This method can be invoked when the external system detects that the associated value was
  /// deleted and the associated shared key should revert back to its default.
  public func yieldReturningInitialValue() {
    yield(with: .success(nil))
  }

  /// Yield an error from an external source.
  ///
  /// - Parameter error: An error.
  public func yield(throwing error: any Error) {
    yield(with: .failure(error))
  }

  /// Yield a result of an updated value or error from an external source.
  ///
  /// - Parameter result: A result of an updated value or error.
  public func yield(with result: Result<Value?, any Error>) {
    callback(result)
  }
}

/// A subscription to a ``SharedReaderKey``'s updates.
///
/// This object is returned from ``SharedReaderKey/subscribe(context:subscriber:)``, which will feed
/// updates from an external system for its lifetime, or till ``cancel()`` is called.
public struct SharedSubscription: Sendable {
  private let box: Box

  /// Initializes the subscription with the given cancel closure.
  ///
  /// - Parameter cancel: A closure that the `cancel()` method executes.
  public init(_ cancel: @escaping @Sendable () -> Void) {
    self.box = Box(cancel)
  }

  /// Cancels the subscription.
  public func cancel() {
    box.cancel()
  }

  private final class Box: Sendable {
    let onCancel: Mutex<(@Sendable () -> Void)?>

    init(_ onCancel: @escaping @Sendable () -> Void) {
      self.onCancel = Mutex(onCancel)
    }

    func cancel() {
      onCancel.withLock { onCancel in
        defer { onCancel = nil }
        onCancel?()
      }
    }

    deinit {
      cancel()
    }
  }
}

/// A mechanism to communicate with a shared key's external system, synchronously or asynchronously.
///
/// A continuation is passed to ``SharedKey/save(_:context:continuation:)`` so that state can be
/// shared to an external system.
///
/// > Important: You must call a resume method exactly once on every execution path from the shared
/// > key it is passed to, _i.e._ in ``SharedReaderKey/load(context:continuation:)`` and
/// > ``SharedKey/save(_:context:continuation:)``.
/// >
/// > Resuming from a continuation more than once is considered a logic error, and only the first
/// > call to `resume` will be executed. Never resuming leaves the task awaiting the call to
/// > ``Shared/save()`` in a suspended state indefinitely and leaks any associated resources.
/// > `SaveContinuation` reports an issue if either of these invariants is violated.
public struct SaveContinuation: Sendable {
  private let box: ContinuationBox<Never>

  package init(
    _ description: @autoclosure @escaping @Sendable () -> String = "",
    callback: @escaping @Sendable (Result<Never?, any Error>) -> Void
  ) {
    self.box = ContinuationBox(
      callback: callback,
      description: {
        let description = description()
        return description.isEmpty ? "A shared key" : "'\(description)'"
      }
    )
  }

  /// Resume the task awaiting the continuation by having it return normally from its suspension
  /// point.
  public func resume() {
    resume(with: .success(()))
  }

  /// Resume the task awaiting the continuation by having it throw an error from its
  /// suspension point.
  ///
  /// - Parameter error: The error to throw from the continuation.
  public func resume(throwing error: any Error) {
    resume(with: .failure(error))
  }

  /// Resume the task awaiting the continuation by having it either return normally or throw an
  /// error based on the state of the given `Result` value.
  ///
  /// - Parameter result: A value to either return or throw from the
  ///   continuation.
  public func resume(with result: Result<Void, any Error>) {
    box.resume(with: result.map { nil })
  }
}

private final class ContinuationBox<Value>: Sendable {
  private let callback: Mutex<(@Sendable (Result<Value?, any Error>) -> Void)?>
  private let description: @Sendable () -> String
  private let resumeCount = Mutex(0)

  init(
    callback: @escaping @Sendable (Result<Value?, any Error>) -> Void,
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
        \(description()) leaked its continuation without one of its resume methods being \
        invoked. This will cause tasks waiting on it to resume immediately.
        """
      )
      callback.withLock { $0?(.success(nil)) }
    }
  }

  func resume(with result: Result<Value?, any Error>) {
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
