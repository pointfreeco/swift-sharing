import Sharing
import Testing

@Suite struct ErrorThrowingTests {
  @Test func saveErrorWhenInvokingSave() async {
    struct Key: SharedKey {
      var id: some Hashable { 0 }
      func save(_ value: Int, immediately: Bool, continuation: SharedContinuation<Void>) {
        continuation.resume(throwing: SaveError())
      }
      func load(context: LoadContext, continuation: LoadContinuation) {
        continuation.resume()
      }
      func subscribe(initialValue: Int?, subscriber: SharedSubscriber<Int?>) -> SharedSubscription {
        SharedSubscription {}
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
