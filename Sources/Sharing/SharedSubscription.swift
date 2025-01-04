/// A subscription to a ``SharedReaderKey``'s updates.
///
/// This object is returned from ``SharedReaderKey/subscribe(initialValue:didSet:)``, which
/// will feed updates from an external system for its lifetime, or till ``cancel()`` is called.
public final class SharedSubscription: Sendable {
  let onCancel: Mutex<(@Sendable () -> Void)?>

  /// Initializes the subscription with the given cancel closure.
  ///
  /// - Parameter cancel: A closure that the `cancel()` method executes.
  public init(_ cancel: @escaping @Sendable () -> Void) {
    self.onCancel = Mutex(cancel)
  }

  deinit {
    cancel()
  }

  /// Cancels the subscription.
  public func cancel() {
    onCancel.withLock { onCancel in
      defer { onCancel = nil }
      onCancel?()
    }
  }
}
