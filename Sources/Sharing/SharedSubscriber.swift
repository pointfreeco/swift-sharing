/// A mechanism to synchronize with a shared key's external system.
///
/// A subscriber is passed to ``SharedReaderKey/subscribe(initialValue:subscriber:)`` so that
/// updates to an external system can be shared.
public struct SharedSubscriber<Value>: Sendable {
  let callback: @Sendable (Result<Value, any Error>) -> Void

  package init(callback: @escaping @Sendable (Result<Value, any Error>) -> Void) {
    self.callback = callback
  }

  /// Yield an updated value from an external source.
  ///
  /// - Parameter value: An updated value.
  public func yield(_ value: Value) {
    yield(with: .success(value))
  }

  /// Yield an error from an external source.
  ///
  /// - Parameter value: An error.
  public func yield(throwing error: any Error) {
    yield(with: .failure(error))
  }

  /// Yield a result of an updated value or error from an external source.
  ///
  /// - Parameter result: A result of an updated value or error.
  public func yield(with result: Result<Value, any Error>) {
    callback(result)
  }
}
