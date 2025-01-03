import Foundation
import Sharing

extension SharedReaderKey where Self == FactAPIKey {
  static func fact(_ number: Int?) -> Self {
    Self(number: number)
  }
}

struct FactAPIKey: SharedReaderKey {
  let id = UUID()
  let number: Int?

  func load(context _: LoadContext<String?>) async throws -> LoadResult<String?> {
    guard let number else {
      return .newValue(nil)
    }
    return try await .newValue(
      String(
        decoding: URLSession.shared.data(from: URL(string: "http://numbersapi.com/\(number)")!).0,
        as: UTF8.self
      )
    )
  }

  func subscribe(
    context _: LoadContext<String?>, subscriber _: SharedSubscriber<String?>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}
