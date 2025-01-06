#if canImport(Combine)
import Combine
import CombineSchedulers
import ConcurrencyExtras
import Foundation
import Sharing
import Testing

@Suite struct SharedPublisherTests {
  @Test func publisher() {
    @Shared(value: 0) var count

    let counts = Mutex<[Int]>([])
    let cancellable = $count.publisher.sink { value in counts.withLock { $0.append(value) } }
    defer { _ = cancellable }

    $count.withLock { $0 += 1 }
    $count.withLock { $0 += 1 }
    $count.withLock { $0 += 1 }

    #expect(counts.withLock(\.self) == [0, 1, 2, 3])
  }

  @MainActor
  @Test func reassign() {
    @Shared(.inMemory("count")) var value = 0
    let values = LockIsolated<[Int]>([])
    let cancellable = $value.publisher.sink { @Sendable value in
      values.withValue { $0.append(value) }
    }
    defer { _ = cancellable }

    #expect(values.value == [0])
    $value.withLock { $0 = 42 }
    #expect(values.value == [0, 42])

    $value = Shared(wrappedValue: 0, .inMemory("count"))
    #expect(values.value == [0, 42])
    $value.withLock { $0 = 1729 }
    #expect(values.value == [0, 42, 1729])
  }
}

private struct Key: SharedReaderKey {
  let id = UUID()
  let testScheduler: TestSchedulerOf<DispatchQueue>
  func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
    testScheduler.schedule {
      continuation.resume(returning: 42)
    }
  }
  func subscribe(
    context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}
#endif

