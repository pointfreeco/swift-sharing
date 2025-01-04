#if canImport(Combine)
  import Combine
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
  }
#endif
