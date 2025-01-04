import Sharing
import Testing

@Suite struct ErrorThrowingTests {
  @Test func saveErrorWhenInvokingSave() async {
    struct Key: SharedKey {
      var id: some Hashable { 0 }
      func load(context: LoadContext<Int>) -> LoadResult<Int> { .initialValue }
      func subscribe(
        context: LoadContext<Int>, subscriber: SharedSubscriber<Int>
      ) -> SharedSubscription {
        SharedSubscription {}
      }
      func save(_ value: Int, context: SaveContext) throws { throw SaveError() }
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
