#if canImport(Combine)
  import Combine

  extension Shared {
    /// Returns a publisher that emits events when the underlying value changes.
    ///
    /// Useful when a feature needs to execute logic when a shared reference is updated outside of
    /// the feature itself.
    ///
    /// ```swift
    /// @Shared(.currentUser) var user: User?
    ///
    /// for await user in $user.publisher.values {
    ///   // Handle user update
    /// }
    /// ```
    public var publisher: some Publisher<Value, Never> {
      box.subject
        .handleEvents(receiveSubscription: { [box] _ in _ = box })
        .prepend(wrappedValue)
    }
  }

  extension SharedReader {
    /// Returns a publisher that emits events when the underlying value changes.
    ///
    /// Useful when a feature needs to execute logic when a shared reference is updated outside of
    /// the feature itself.
    ///
    /// ```swift
    /// @SharedReader var hapticsEnabled: Bool
    ///
    /// for await hapticsEnabled in $hapticsEnabled.publisher.values {
    ///   // Handle haptics settings change
    /// }
    /// ```
    public var publisher: some Publisher<Value, Never> {
      box.subject
        .handleEvents(receiveSubscription: { [box] _ in _ = box })
        .prepend(wrappedValue)
    }
  }
#endif

enum SharedPublisherLocals {
  @TaskLocal static var isLoading = false
}
