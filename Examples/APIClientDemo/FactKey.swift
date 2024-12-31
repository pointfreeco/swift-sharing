import Foundation
import Sharing

extension SharedReaderKey where Self == FactAPIKey.Default {
  static func fact(_ number: Int?) -> Self {
    Self[FactAPIKey(number: number), default: ""]
  }
}

struct FactAPIKey: SharedReaderKey {
  let number: Int?

  let id = UUID()

  func load(initialValue: String?, continuation: SharedContinuation<String?>) {
    guard let number/*, initialValue == nil*/ else {
      continuation.resume(returning: nil)
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
    initialValue: String?, subscriber: SharedSubscriber<String?>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}
