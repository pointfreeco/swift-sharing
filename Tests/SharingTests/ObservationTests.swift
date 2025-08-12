import Dependencies
import PerceptionCore
import Sharing
import Testing

@MainActor
@Suite struct ObservationTests {
  @Test func nonPersistedShared() async {
    @Shared(value: 0) var count: Int
    await confirmation { confirm in
      withPerceptionTracking {
        _ = count
      } onChange: {
        confirm()
      }

      $count.withLock { $0 += 1 }
    }
  }

  @Test func persistedShared() async {
    @Shared(.inMemory("count")) var count = 0
    await confirmation { confirm in
      withPerceptionTracking {
        _ = count
      } onChange: {
        confirm()
      }

      $count.withLock { $0 += 1 }
    }
  }

  @Test func removeValueShared() async {
    @Dependency(\.defaultInMemoryStorage) var storage
    @Shared(.inMemory("count")) var count = 0
    await confirmation { confirm in
      withPerceptionTracking {
        _ = count
      } onChange: {
        confirm()
      }
      storage.removeValue(for: InMemoryKey<Int>.inMemory("count"), default: 0)
    }
  }

  @Test func removeValueSharedReader() async {
    @Dependency(\.defaultInMemoryStorage) var storage
    @SharedReader(.inMemory("count")) var count = 0
    await confirmation { confirm in
      withPerceptionTracking {
        _ = count
      } onChange: {
        confirm()
      }
      storage.removeValue(for: InMemoryKey<Int>.inMemory("count"), default: 0)
    }
  }
}
