import Foundation
import IdentifiedCollections
import PerceptionCore
import Sharing
import Testing

@Suite struct SharedTests {
  @Suite struct Persistence {
    @Test func laziness() {
      do {
        @Shared(.inMemory("count")) var count = 0
      }
      do {
        @Shared(.inMemory("count")) var count: Int = { fatalError() }()
      }
    }

    @Test func loadError() {
      struct Key: Hashable, Sendable, SharedReaderKey {
        let id = UUID()
        func load(initialValue: Int?, continuation: SharedContinuation<Int?>) {
          continuation.resume(throwing: LoadError())
        }
        func subscribe(
          initialValue: Int?,
          didReceive callback: @escaping (Result<Int?, any Error>) -> Void
        ) -> SharedSubscription {
          SharedSubscription {}
        }
        struct LoadError: Error {}
      }

      withKnownIssue {
        @SharedReader(Key()) var count = 0
        #expect($count.loadError != nil)
      } matching: {
        $0.description == "Caught error: LoadError()"
      }
    }

    @Test func subscribeError() {
      class Key: SharedReaderKey, @unchecked Sendable {
        let id = UUID()
        var callback: (@Sendable (Result<Int?, any Error>) -> Void)?
        func load(initialValue: Int?, continuation: SharedContinuation<Int?>) {
          continuation.resume(returning: nil)
        }
        func subscribe(
          initialValue: Int?,
          didReceive callback: @escaping @Sendable (Result<Int?, any Error>) -> Void
        ) -> SharedSubscription {
          self.callback = callback
          return SharedSubscription {}
        }
        struct LoadError: Error {}
      }

      let key = Key()
      @SharedReader(key) var count = 0
      withKnownIssue {
        key.callback?(.failure(Key.LoadError()))
      } matching: {
        $0.description == "Caught error: LoadError()"
      }
      #expect($count.loadError != nil)

      key.callback?(.success(1))
      #expect(count == 1)
      #expect($count.loadError == nil)
    }

    @Test func saveError() {
      struct Key: SharedKey {
        let id = UUID()
        func load(initialValue: Int?, continuation: SharedContinuation<Int?>) {
          continuation.resume(returning: nil)
        }
        func subscribe(
          initialValue: Int?,
          didReceive callback: @escaping (Result<Int?, any Error>) -> Void
        ) -> SharedSubscription {
          SharedSubscription {}
        }
        func save(
          _ value: Int,
          immediately: Bool,
          didComplete callback: @escaping (Result<Void, any Error>) -> Void
        ) {
          callback(value < 0 ? .failure(SaveError()) : .success(()))
        }
        struct SaveError: Error {}
      }

      @Shared(Key()) var count = 0
      withKnownIssue {
        $count.withLock { $0 -= 1 }
      } matching: {
        $0.description == "Caught error: SaveError()"
      }
      #expect($count.saveError != nil)

      $count.withLock { $0 += 1 }
      #expect($count.saveError == nil)
    }

    @Test func saveErrorLoadErrorInterplay() {
      class Key: SharedKey, @unchecked Sendable {
        let id = UUID()
        var callback: (@Sendable (Result<Int?, any Error>) -> Void)?
        func load(initialValue: Int?, continuation: SharedContinuation<Int?>) {
          continuation.resume(returning: nil)
        }
        func subscribe(
          initialValue: Int?,
          didReceive callback: @escaping @Sendable (Result<Int?, any Error>) -> Void
        ) -> SharedSubscription {
          self.callback = callback
          return SharedSubscription {}
        }
        func save(
          _ value: Int,
          immediately: Bool,
          didComplete callback: @escaping (Result<Void, any Error>) -> Void
        ) {
          callback(value < 0 ? .failure(SaveError()) : .success(()))
        }
        struct LoadError: Error {}
        struct SaveError: Error {}
      }

      let key = Key()
      @Shared(key) var count = 0
      withKnownIssue {
        key.callback?(.failure(Key.LoadError()))
      } matching: {
        $0.description == "Caught error: LoadError()"
      }
      #expect($count.loadError != nil)

      withKnownIssue {
        $count.withLock { $0 -= 1 }
      } matching: {
        $0.description == "Caught error: SaveError()"
      }
      #expect($count.loadError != nil)
      #expect($count.saveError != nil)

      key.callback?(.success(nil))
      #expect(count == 0)
      #expect($count.loadError == nil)
      #expect($count.saveError != nil)

      withKnownIssue {
        key.callback?(.failure(Key.LoadError()))
      } matching: {
        $0.description == "Caught error: LoadError()"
      }
      #expect($count.loadError != nil)
      #expect($count.saveError != nil)

      $count.withLock { $0 += 1 }
      #expect($count.loadError == nil)
      #expect($count.saveError == nil)
    }

    @Test func nesting() {
      struct C: Equatable {}
      struct B {
        @Shared(.inMemory("c")) var c = C()
      }
      struct A {
        @Shared(.inMemory("b")) var b = B()
      }

      let a = A()
      #expect(a.b.c == C())
    }
  }

  @Suite struct BoxReference {
    @Test func mutation() {
      @Shared(value: 0) var count
      $count.withLock { $0 += 1 }
      #expect(count == 1)

      @Shared var copy: Int
      _copy = $count
      $copy.withLock { $0 += 1 }
      #expect(count == 2)
      #expect(copy == 2)
    }
  }

  @Suite struct Transformations {
    @Test func appendWritableKeyPath() {
      struct User {
        var name = ""
      }

      @Shared(value: User(name: "Blob")) var user
      @Shared var name: String
      _name = $user.name

      $name.withLock { $0 += ", Jr." }
      #expect(user.name == "Blob, Jr.")

      $user.name.withLock { $0 += " III" }
      #expect(name == "Blob, Jr. III")
    }

    @Test func appendKeyPath() {
      struct User {
        let id: Int
      }

      @Shared(value: User(id: 1)) var user
      @SharedReader var id: Int
      _id = $user.id

      #expect(id == 1)

      $user.withLock { $0 = User(id: 42) }

      #expect(id == 42)

      $user = Shared(value: User(id: 1729))

      #expect(id == 42)
    }

    @Test func optional() throws {
      @Shared(value: nil) var wrappedCount: Int?
      #expect(Shared($wrappedCount) == nil)

      $wrappedCount.withLock { $0 = 0 }
      @Shared var count: Int
      _count = try #require(Shared($wrappedCount))

      #expect(count == 0)

      $count.withLock { $0 += 1 }
      #expect(wrappedCount == 1)

      $wrappedCount.withLock { $0? += 1 }
      #expect(count == 2)

      $wrappedCount.withLock { $0? += 1 }
      $wrappedCount.withLock { $0 = nil }

      #expect(count == 2)

      $wrappedCount.withLock { $0 = 4 }
      #expect(count == 4)
    }

    @Test func collection() {
      @Shared(value: IdentifiedArray(uniqueElements: [1, 2, 3], id: \.self)) var counts

      let sharedCounts = Array($counts)
      @Shared var first: Int
      _first = sharedCounts[0]
      @Shared var second: Int
      _second = sharedCounts[1]
      @Shared var third: Int
      _third = sharedCounts[2]

      #expect(first == 1)
      #expect(second == 2)
      #expect(third == 3)

      $counts.withLock { _ = $0.removeLast() }

      #expect(counts == IdentifiedArray(uniqueElements: [1, 2], id: \.self))
      #expect(third == 3)

      $third.withLock { $0 += 1 }

      #expect(third == 4)
      #expect(counts == IdentifiedArray(uniqueElements: [1, 2], id: \.self))
    }

    @Test func task() async {
      @Shared(value: 0) var count

      await Task { [$count] in
        $count.withLock { $0 = 1 }
      }
      .value

      #expect(count == 1)
    }

    @Test func reader() {
      @Shared(value: 0) var count

      @SharedReader var readOnlyCount: Int
      _readOnlyCount = SharedReader($count)

      $count.withLock { $0 = 1 }

      #expect(readOnlyCount == 1)
    }
  }

  @Suite struct StringRepresentations {
    @Test func valueDescription() {
      @Shared(value: 0) var count

      #expect($count.description == "Shared<Int>(value: 0)")

      #expect(SharedReader($count).description == "SharedReader<Int>(value: 0)")
    }

    @Test func appStorageDescription() {
      @Shared(.appStorage("count")) var count = 0

      #expect($count.description == #"Shared<Int>(.appStorage("count"))"#)

      #expect(SharedReader($count).description == #"SharedReader<Int>(.appStorage("count"))"#)
    }

    @Test func defaultDescription() {
      do {
        @Shared(AppStorageKey.Default[.appStorage("count"), default: 0]) var count

        #expect(
          $count.description == """
            Shared<Int>(AppStorageKey<Int>.Default[.appStorage("count"), default: 0])
            """
        )

        #expect(
          SharedReader($count).description == """
            SharedReader<Int>(AppStorageKey<Int>.Default[.appStorage("count"), default: 0])
            """
        )
      }
      do {
        @Shared(AppStorageKey.Default[.appStorage("count"), default: 0]) var count = 0

        #expect(
          $count.description == """
            Shared<Int>(AppStorageKey<Int>.Default[.appStorage("count"), default: 0])
            """
        )

        #expect(
          SharedReader($count).description == """
            SharedReader<Int>(AppStorageKey<Int>.Default[.appStorage("count"), default: 0])
            """
        )
      }
    }

    @Test func fileStorageDescription() {
      @Shared(.fileStorage(URL(filePath: "/"))) var count = 0

      #expect($count.description == #"Shared<Int>(.fileStorage(file:///))"#)
    }

    @Test func inMemory() {
      @Shared(.inMemory("count")) var count = 0

      #expect($count.description == #"Shared<Int>(.inMemory("count"))"#)
    }

    @Test func customDump() {
      @Shared(value: 0) var count

      #expect(String(customDumping: $count) == "#1 0")
      #expect(
        String(customDumping: [$count, $count]) == """
          [
            [0]: #1 0,
            [1]: #1 Int(↩︎)
          ]
          """
      )

      @Shared(value: 0) var anotherCount
      #expect(
        String(customDumping: [$count, $anotherCount, $count, $anotherCount]) == """
          [
            [0]: #1 0,
            [1]: #2 0,
            [2]: #1 Int(↩︎),
            [3]: #2 Int(↩︎)
          ]
          """
      )
    }

    @Test func customDumpWithProjection() {
      struct Stats {
        var count = 0
      }
      struct State {
        @Shared var count: Int
        @Shared var stats: Stats
      }
      @Shared(value: Stats()) var stats
      #expect(
        String(customDumping: State(count: $stats.count, stats: $stats)) == """
          SharedTests.StringRepresentations.State(
            _count: #1 0,
            _stats: #1 SharedTests.StringRepresentations.Stats(↩︎)
          )
          """,
        """
        This test shows that the custom dump behavior identifying by root object identifier is not \
        ideal: it causes a larger dump to be truncated if a smaller slice of it was dumped earlier.
        """
      )
    }
  }
}
