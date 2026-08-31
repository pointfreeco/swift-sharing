import Dispatch
import PerceptionCore
import Sharing
import Testing

#if canImport(Combine)
  import Combine

  @Suite struct NotificationOrderingTests {
    @Test(.timeLimit(.minutes(1)))
    func changeNotificationIsEnqueuedAfterBackgroundStore() async throws {
      @SharedReader(wrappedValue: 0, BackgroundLoadKey(value: 1)) var value: Int
      let reader = $value
      try await poll(until: { reader.wrappedValue == 1 })
      // NB: Drain the initial load's pending change notification before observing.
      await MainActor.run {}

      let events = Mutex<[String]>([])
      let recordStore: @Sendable () -> Void = { events.withLock { $0.append("store") } }
      let cancellable = reader.publisher
        .dropFirst()
        .sink { @Sendable _ in
          DispatchQueue.main.async(execute: recordStore)
        }
      defer { _ = cancellable }

      withPerceptionTracking {
        _ = reader.wrappedValue
      } onChange: {
        events.withLock { $0.append("change") }
      }

      try await Task.detached { try await reader.load() }.value
      try await poll(until: { events.withLock(\.count) >= 2 })

      #expect(events.withLock(\.self) == ["store", "change"])
    }
  }

  private struct BackgroundLoadKey: SharedReaderKey {
    let value: Int
    var id: Int { value }

    func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
      DispatchQueue.global(qos: .userInitiated).async {
        continuation.resume(returning: value)
      }
    }

    func subscribe(
      context: LoadContext<Int>,
      subscriber: SharedSubscriber<Int>
    ) -> SharedSubscription {
      SharedSubscription {}
    }
  }

  private func poll(
    until condition: @escaping @Sendable () -> Bool,
    timeout: Duration = .seconds(3)
  ) async throws {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
      if condition() { return }
      try await Task.sleep(for: .milliseconds(10))
    }
  }
#endif
