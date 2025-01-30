import Foundation
import Sharing
import Testing

@Suite struct ErrorThrowingTests {
  @Test func saveErrorWhenInvokingSave() async {
    struct SaveError: Error {}
    struct Key: SharedKey {
      var id: some Hashable { 0 }
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resumeReturningInitialValue()
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
      func save(_ value: Int, context: SaveContext, continuation: SaveContinuation) {
        continuation.resume(throwing: SaveError())
      }
    }
    @Shared(Key()) var value = 0
    await withKnownIssue {
      await #expect(throws: SaveError.self) {
        try await $value.save()
      }
    }
    #expect($value.saveError is SaveError)
  }

  @Test func implicitLoadError() {
    struct Key: Sendable, SharedReaderKey {
      let id = UUID()
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resume(throwing: LoadError())
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
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
  
  @Test func userInitiatedLoadError() async {
    struct LoadError: Error {}
    struct Key: Hashable, Sendable, SharedReaderKey {
      let id = UUID()
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        switch context {
        case .initialValue:
          continuation.resume(returning: 42)
        case .userInitiated:
          continuation.resume(throwing: LoadError())
        }
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
    }
    
    @SharedReader(Key()) var value = 0
    
    await withKnownIssue {
      await #expect(throws: LoadError.self) {
        try await $value.load()
      }
    } matching: {
      $0.description == "Caught error: LoadError()"
    }
  }

  @Test func explicitRequireError() async {
    struct LoadError: Error {}
    struct Key: Sendable, SharedReaderKey {
      let id = UUID()
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resume(throwing: LoadError())
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
    }

    await #expect(throws: LoadError.self) {
      try await SharedReader(require: Key())
    }
  }

  @Test func subscribeError() {
    class Key: SharedReaderKey, @unchecked Sendable {
      let id = UUID()
      var subscriber: SharedSubscriber<Int>?
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resumeReturningInitialValue()
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        self.subscriber = subscriber
        return SharedSubscription {}
      }
      struct LoadError: Error {}
    }

    let key = Key()
    @SharedReader(key) var count = 0
    withKnownIssue {
      key.subscriber?.yield(throwing: Key.LoadError())
    } matching: {
      $0.description == "Caught error: LoadError()"
    }
    #expect($count.loadError != nil)

    key.subscriber?.yield(1)
    #expect(count == 1)
    #expect($count.loadError == nil)
  }

  @Test func saveError() {
    struct Key: SharedKey {
      let id = UUID()
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resumeReturningInitialValue()
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
      func save(_ value: Int, context: SaveContext, continuation: SaveContinuation) {
        continuation.resume(with: value < 0 ? .failure(SaveError()) : .success(()))
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
      var subscriber: SharedSubscriber<Int>?
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resumeReturningInitialValue()
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        self.subscriber = subscriber
        return SharedSubscription {}
      }
      func save(_ value: Int, context: SaveContext, continuation: SaveContinuation) {
        continuation.resume(with: value < 0 ? .failure(SaveError()) : .success(()))
      }
      struct LoadError: Error {}
      struct SaveError: Error {}
    }

    let key = Key()
    @Shared(key) var count = 0
    withKnownIssue {
      key.subscriber?.yield(throwing: Key.LoadError())
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

    key.subscriber?.yieldReturningInitialValue()
    #expect(count == 0)
    #expect($count.loadError == nil)
    #expect($count.saveError != nil)

    withKnownIssue {
      key.subscriber?.yield(throwing: Key.LoadError())
    } matching: {
      $0.description == "Caught error: LoadError()"
    }
    #expect($count.loadError != nil)
    #expect($count.saveError != nil)

    $count.withLock { $0 += 1 }
    #expect($count.loadError == nil)
    #expect($count.saveError == nil)
  }

  @Test func loadErrorSticksAround() async throws {
    final class Key: Sendable, SharedReaderKey {
      let id = UUID()
      let continuation = Mutex<LoadContinuation<Int>?>(nil)
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        self.continuation.withLock { $0 = continuation }
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
    }

    let key = Key()
    @SharedReader(key) var count = 0
    #expect($count.isLoading)
    #expect($count.loadError == nil)

    struct LoadError: Error {}
    withKnownIssue {
      key.continuation.withLock { $0?.resume(throwing: LoadError()) }
    }

    #expect(!$count.isLoading)
    #expect($count.loadError != nil)

    let task = Task { [$count] in try await $count.load() }
    try await Task.sleep(nanoseconds: 100_000_000)

    #expect($count.isLoading)
    #expect($count.loadError != nil)

    key.continuation.withLock { $0?.resume(returning: 42) }
    try await task.value

    #expect(!$count.isLoading)
    #expect($count.loadError == nil)
  }

  @Test func saveErrorSticksAround() async throws {
    final class Key: Sendable, SharedKey {
      let id = UUID()
      let continuation = Mutex<SaveContinuation?>(nil)
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resumeReturningInitialValue()
      }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
      func save(_ value: Int, context: SaveContext, continuation: SaveContinuation) {
        self.continuation.withLock { $0 = continuation }
      }
    }

    let key = Key()
    @Shared(key) var count = 0
    #expect($count.saveError == nil)

    $count.withLock { $0 += 1 }

    struct SaveError: Error {}
    withKnownIssue {
      key.continuation.withLock { $0?.resume(throwing: SaveError()) }
    }

    #expect($count.saveError != nil)

    $count.withLock { $0 += 1 }

    #expect($count.saveError != nil)

    key.continuation.withLock { $0?.resume() }

    #expect($count.saveError == nil)
  }
}
