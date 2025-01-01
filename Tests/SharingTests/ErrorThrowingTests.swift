import Sharing
import Testing

@Suite struct ErrorThrowingTests {
  @Test func saveErrorWhenInvokingSave() async {
    struct Key: SharedKey {
      var id: some Hashable { 0 }
      func load(context: LoadContext<Int>, continuation: LoadContinuation<Int>) {
        continuation.resume()
      }
      func subscribe(initialValue: Int?, subscriber: SharedSubscriber<Int?>) -> SharedSubscription {
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
}

private struct SaveError: Error {}
