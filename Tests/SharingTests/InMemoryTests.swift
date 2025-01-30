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

  @Test func `default`() async throws {
    do {
      @SharedReader(.inMemory("count")) var count = 10
    }
    do {
      @SharedReader(.inMemory("count")) var count = 0
      #expect(count == 10)
    }
    do {
      let sharedCount = try await SharedReader<Int>(require: .inMemory("count"))
      #expect(sharedCount.wrappedValue == 10)
    } catch {
      throw error
    }
  }

  @Test func optionalDefault() async {
    do {
      @Shared(.inMemory("count")) var count: Int? = 0
      #expect(count == 0)
    }

    do {
      @Shared(.inMemory("nilCount")) var nilCount: Int? = nil
      #expect(nilCount == nil)
    }

    do {
      @Shared(.inMemory("optionalCount")) var optionalCount: Int?? = .some(0)
      #expect(optionalCount == .some(0))
    }

    do {
      @Shared(.inMemory("nestedOptionalCount")) var nestedOptionalCount: Int?? = .some(.none)
      #expect(nestedOptionalCount == .some(.none))

      @SharedReader(.inMemory("nestedOptionalCountReader")) var nestedOptionalCountReader: Int?? = .some(.none)
      #expect(nestedOptionalCountReader == .some(.none))
    }

    do {
      await #expect(throws: Error.self) {
        try await Shared<Int?>(require: .inMemory("countNotExist"))
      }
    }
  }
}
