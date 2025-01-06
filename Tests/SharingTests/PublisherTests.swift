#if canImport(Combine)
  import Combine
  import CombineSchedulers
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
    @Test func reassignSameKey() {
      @Shared(.inMemory("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { value in values.withLock { $0.append(value) } }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      $value = Shared(wrappedValue: 0, .inMemory("count"))
      #expect(values.withLock(\.self) == [0, 42])
      $value.withLock { $0 = 1729 }
      #expect(values.withLock(\.self) == [0, 42, 1729])
    }
  }
#endif
