import Foundation
import Sharing
import Synchronization

extension SharedReaderKey where Self == FactKey {
  static func fact(_ number: Int?) -> Self {
    Self(number: number)
  }
}

// NB: This 'SharedReaderKey` conformance is designed to allow one to hold onto a 'fact: String?'
//     in their features, while secretly it is powered by a network request to fetch the fact.
//     Conformances to 'SharedReaderKey' must be Sendable, and so this is why the 'loadTask'
//     variable is held in a mutex.
final class FactKey: SharedReaderKey {
  let id = UUID()
  let number: Int?
  let loadTask = Mutex<Task<Void, Never>?>(nil)

  init(number: Int?) {
    self.number = number
  }

  func load(context _: LoadContext<String?>, continuation: LoadContinuation<String?>) {
    guard let number else {
      continuation.resume(returning: nil)
      return
    }
    loadTask.withLock { task in
      task?.cancel()
      task = Task {
        do {
          // NB: This dependence on 'URLSession.shared' should be hidden behind a dependency
          //     so that features that use this shared state are still testable.
          let (data, _) = try await URLSession.shared.data(
            from: URL(string: "http://numbersapi.com/\(number)")!
          )
          // NB: The Numbers API can be quite fast. Let's simulate a slower connection.
          try await Task.sleep(for: .seconds(1))
          // NB: Simulate errors from the API for negative numbers.
          guard number >= 0 else {
            struct BoringNumber: LocalizedError {
              let number: Int
              var errorDescription: String? { "\(number) is a boring number." }
            }
            throw BoringNumber(number: number)
          }
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
