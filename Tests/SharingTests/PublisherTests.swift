#if canImport(Combine)
  import Combine
  import Dependencies
  import Foundation
  @testable import Sharing
  import Testing

  @MainActor
  @Suite struct SharedPublisherTests {
    @Test func publisher() {
      @Shared(value: 0) var count

      let counts = Mutex<[Int]>([])
      let cancellable = $count.publisher.sink { @Sendable value in
        counts.withLock { $0.append(value) }
      }
      defer { _ = cancellable }

      $count.withLock { $0 += 1 }
      $count.withLock { $0 += 1 }
      $count.withLock { $0 += 1 }

      #expect(counts.withLock(\.self) == [0, 1, 2, 3])
    }

    @Test func reassignSameKey() {
      @Shared(.inMemory("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock { $0.append(value) }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      $value = Shared(wrappedValue: 0, .inMemory("count"))
      #expect(values.withLock(\.self) == [0, 42, 42])
      $value.withLock { $0 = 1729 }
      #expect(values.withLock(\.self) == [0, 42, 42, 1729])
    }

    @Test func reassignDifferentKey() {
      @Dependency(\.defaultAppStorage) var store
      @Shared(.appStorage("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock { $0.append(value) }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      $value = Shared(wrappedValue: 0, .appStorage("anotherCount"))
      #expect(values.withLock(\.self) == [0, 42, 0])
      $value.withLock { $0 = 1729 }
      #expect(values.withLock(\.self) == [0, 42, 0, 1729])
      store.set(123, forKey: "count")
      #expect(values.withLock(\.self) == [0, 42, 0, 1729])
      store.set(456, forKey: "anotherCount")
      #expect(values.withLock(\.self) == [0, 42, 0, 1729, 456])
    }

    @Test func reassignDifferentKey_otherShared() {
      @Shared(.appStorage("count")) var count = 0
      defer { _ = count }

      @Dependency(\.defaultAppStorage) var store
      @Shared(.appStorage("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock { $0.append(value) }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      $value = Shared(wrappedValue: 0, .appStorage("anotherCount"))
      #expect(values.withLock(\.self) == [0, 42, 0])
      $value.withLock { $0 = 1729 }
      #expect(values.withLock(\.self) == [0, 42, 0, 1729])
      $count.withLock { $0 = 123 }
      #expect(values.withLock(\.self) == [0, 42, 0, 1729])
      store.set(456, forKey: "anotherCount")
      #expect(values.withLock(\.self) == [0, 42, 0, 1729, 456])

      $value = Shared(wrappedValue: 0, .appStorage("yetAnotherCount"))
      #expect(values.withLock(\.self) == [0, 42, 0, 1729, 456, 0])
      $count.withLock { $0 = 456 }
      #expect(values.withLock(\.self) == [0, 42, 0, 1729, 456, 0])
      $value.withLock { $0 = 789 }
      #expect(values.withLock(\.self) == [0, 42, 0, 1729, 456, 0, 789])
    }

    @Test func reloadDifferentKey() async throws {
      @Dependency(\.defaultAppStorage) var store
      @Shared(.appStorage("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock {
          $0.append(value)
        }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      try await $value.load(.appStorage("anotherCount"))
      #expect(values.withLock(\.self) == [0, 42])
      $value.withLock { $0 = 1729 }
      #expect(values.withLock(\.self) == [0, 42, 1729])
      store.set(123, forKey: "count")
      #expect(values.withLock(\.self) == [0, 42, 1729])
      store.set(456, forKey: "anotherCount")
      #expect(values.withLock(\.self) == [0, 42, 1729, 456])
    }

    @Test func reloadExistingShared() async throws {
      @Dependency(\.defaultAppStorage) var store
      @Shared(.appStorage("anotherCount")) var anotherCount = 1729
      @Shared(.appStorage("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock {
          $0.append(value)
        }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      store.set(1729, forKey: "anotherCount")
      try await $value.load(.appStorage("anotherCount"))
      #expect(values.withLock(\.self) == [0, 42, 1729])
    }

    @Test func reloadExistingPersistedValue() async throws {
      @Dependency(\.defaultAppStorage) var store
      @Shared(.appStorage("count")) var value = 0
      let values = Mutex<[Int]>([])
      let cancellable = $value.publisher.sink { @Sendable value in
        values.withLock {
          $0.append(value)
        }
      }
      defer { _ = cancellable }

      #expect(values.withLock(\.self) == [0])
      $value.withLock { $0 = 42 }
      #expect(values.withLock(\.self) == [0, 42])

      store.set(1729, forKey: "anotherCount")
      try await $value.load(.appStorage("anotherCount"))
      #expect(values.withLock(\.self) == [0, 42, 1729])
    }

    @Test func retainPublisherInDerivedShared() {
      struct Wrapper {
        var value = 0
      }
      @Shared(value: Wrapper()) var count

      let counts = Mutex<[Int]>([])

      let cancellable = $count.value.publisher.sink { completion in
        Issue.record()
      } receiveValue: { @Sendable value in
        counts.withLock { $0.append(value) }
      }
      defer { _ = cancellable }

      $count.withLock { $0.value += 1 }
      $count.withLock { $0.value += 1 }
      $count.withLock { $0.value += 1 }

      #expect(counts.withLock(\.self) == [0, 1, 2, 3])
    }
  }
#endif
