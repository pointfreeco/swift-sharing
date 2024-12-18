import Dependencies
import Foundation
import Sharing
import Testing

@Suite struct InMemoryTests {
  @Test func mutation() {
    @Shared(.inMemory("count")) var count = 0

    #expect(count == 0)

    $count.withLock { $0 += 1 }

    #expect(count == 1)

    @Shared(.inMemory("count")) var anotherCount = 0

    #expect(anotherCount == 1)

    $anotherCount.withLock { $0 += 1 }

    #expect(count == 2)
  }

  @Test func referenceCounting() async throws {
    do {
      @Shared(.inMemory("count")) var count = 0

      #expect(count == 0)

      $count.withLock { $0 += 1 }

      #expect(count == 1)
    }

    do {
      @Shared(.inMemory("count")) var count = 0
      #expect(count == 1)
    }

    do {
      @SharedReader(.inMemory("count")) var count = 0
      #expect(count == 1)
    }

    await Task {
      @Shared(.inMemory("count")) var count = 0
      #expect(count == 1)
    }
    .value
  }

  @Test func `default`() {
    do {
      @SharedReader(.inMemory("count")) var count = 10
    }
    do {
      @SharedReader(.inMemory("count")) var count = 0
      #expect(count == 10)
    }
  }
}
