import Testing
import Sharing

@Suite struct ContinuationTests {
  @Test func dontResumeLoadContinuation() async throws {
    try await withKnownIssue {
      @SharedReader(DontResumeLoadContinuationKey()) var value = 0
      #expect($value.isLoading == false)
      try await $value.load()
      #expect($value.isLoading == false)
    } matching: { issue in
      issue.description == """
        Issue recorded: 'DontResumeLoadContinuationKey()' leaked its continuation without one of \
        its resume methods being invoked. This will cause tasks waiting on it to resume immediately.
        """
    }
  }

  @Test func dontResumeSaveContinuation() async throws {
    @Shared(DontResumeSaveContinuationKey()) var value = 0
    try await withKnownIssue {
      try await $value.save()
    } matching: { issue in
      issue.description == """
        Issue recorded: \'DontResumeSaveContinuationKey()\' leaked its continuation without one of \
        its resume methods being invoked. This will cause tasks waiting on it to resume immediately.
        """
    }
  }
}

private struct DontResumeLoadContinuationKey: SharedReaderKey {
  var id: some Hashable { 0 }
  func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {}
  func subscribe(
    context: LoadContext<Int>,
    subscriber: SharedSubscriber<Int>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}

private struct DontResumeSaveContinuationKey: SharedKey {
  var id: some Hashable { 0 }
  func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
    continuation.resume(returning: 42)
  }
  func subscribe(
    context: LoadContext<Int>,
    subscriber: SharedSubscriber<Int>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
  func save(_ value: Int, context: SaveContext, continuation: SaveContinuation) {}
}
