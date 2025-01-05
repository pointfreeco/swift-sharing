import ConcurrencyExtras
import Foundation
import Sharing

extension SharedReaderKey where Self == FactAPIKey {
  static func fact(_ number: Int?) -> Self {
    Self(number: number)
  }
}

final class FactAPIKey: SharedReaderKey {
  let id = UUID()
  let number: Int?
  let loadTask = LockIsolated<Task<Void, Never>?>(nil)
  
  init(number: Int?) {
    self.number = number
  }

  func load(context _: LoadContext<String?>, continuation: LoadContinuation<String?>) {
    guard let number else {
      continuation.resume(returning: nil)
      return
    }
    loadTask.withValue { task in
      task?.cancel()
      task = Task {
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
  }

  func subscribe(
    context _: LoadContext<String?>, subscriber _: SharedSubscriber<String?>
  ) -> SharedSubscription {
    SharedSubscription {}
  }
}
