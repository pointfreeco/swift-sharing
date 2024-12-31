import Foundation
import IssueReporting

public struct SharedContinuation<Value>: Sendable {
  private final class Box: Sendable {
    private let callback: @Sendable (Result<Value, any Error>) -> Void
    private let description: @Sendable () -> String
    private let resumeCount = Mutex(0)

    init(
      callback: @escaping @Sendable (Result<Value, any Error>) -> Void,
      description: @escaping @Sendable () -> String
    ) {
      self.callback = callback
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
      callback(result)
    }
  }

  private let box: Box

  init(
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

  public func resume(with result: Result<Value, any Error>) {
    box.resume(with: result)
  }

  public func resume(returning value: Value) {
    resume(with: .success(value))
  }

  public func resume(throwing error: any Error) {
    resume(with: .failure(error))
  }
}

extension SharedContinuation where Value == Void {
  public func resume() {
    resume(returning: ())
  }
}
