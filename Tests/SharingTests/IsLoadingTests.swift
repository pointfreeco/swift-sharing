import CombineSchedulers
import Dispatch
import Foundation
import Sharing
import Testing

@Suite struct IsLoadingTests {
  let testScheduler = DispatchQueue.test

  @Test func isLoading() {
    @SharedReader(Key(testScheduler: testScheduler)) var value = 0
    #expect($value.isLoading == true)
    testScheduler.advance()
    #expect($value.isLoading == false)
    #expect(value == 42)
  }

  @Test func isLoadingReassign() async throws {
    @SharedReader(Key(testScheduler: testScheduler)) var value = 0
    _ = { testScheduler.advance() }()
    #expect(value == 42)
    #expect($value.isLoading == false)

    $value = SharedReader(wrappedValue: 0, Key(testScheduler: testScheduler))
    #expect($value.isLoading == true)
    #expect(value == 0)
    _ = { testScheduler.advance() }()
    #expect($value.isLoading == false)
    #expect(value == 42)
  }

  @MainActor
  @Test func isLoadingInitRequire() async throws {
    @SharedReader(Key(testScheduler: testScheduler)) var value = 0
    _ = { testScheduler.advance() }()
    #expect(value == 42)

    let task = Task {
      $value = try await SharedReader(require: Key(testScheduler: testScheduler))
    }
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect($value.isLoading == false)
    #expect(value == 42)
    _ = { testScheduler.advance() }()
    try await task.value
    #expect($value.isLoading == false)
    #expect(value == 42)
  }

  @MainActor
  @Test func isLoadingLoadKey() async throws {
    @SharedReader(Key(testScheduler: testScheduler)) var value = 0
    _ = { testScheduler.advance() }()
    #expect(value == 42)

    let task = Task {
      try await $value.load(Key(testScheduler: testScheduler))
    }
    try await Task.sleep(nanoseconds: 100_000_000)
    #expect($value.isLoading == true)
    #expect(value == 42)
    _ = { testScheduler.advance() }()
    try await task.value
    #expect($value.isLoading == false)
    #expect(value == 42)
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
