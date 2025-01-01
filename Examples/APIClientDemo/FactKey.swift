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

  func load(context: LoadContext<String?>, continuation: LoadContinuation<String?>) {
    guard let number else {
      continuation.resume()
      return
    }
    Task {
      do {
        let (data, _) = try await URLSession.shared.data(
          from: URL(string: "http://numbersapi.com/\(number)")!
        )
        continuation.resume(returning: String(decoding: data, as: UTF8.self))
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func subscribe(
    initialValue: String??, subscriber: SharedSubscriber<String??>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}
