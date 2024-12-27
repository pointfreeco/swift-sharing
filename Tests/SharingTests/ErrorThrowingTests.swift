import Sharing
import Testing

@Suite struct ErrorThrowingTests {
  @Test func saveErrorWhenInvokingSave() {
    struct Key: SharedKey {
      var id: some Hashable { 0 }
      func save(_ value: Int, immediately: Bool) throws { throw SaveError() }
      func load(initialValue: Int?) throws -> Int? { nil }
      func subscribe(
        initialValue: Int?,
        didReceive callback: @escaping (Result<Int?, any Error>) -> Void
      ) -> SharedSubscription {
        SharedSubscription {}
      }
    }
    @Shared(Key()) var value = 0
    withKnownIssue {
      #expect(throws: SaveError.self) {
        try $value.save()
      }
    }
    #expect($value.saveError is SaveError)
  }
}

private struct SaveError: Error {}
