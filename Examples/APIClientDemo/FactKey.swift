import Foundation
import Sharing
import Synchronization

extension SharedReaderKey where Self == FactKey {
  static func fact(_ number: Int?) -> Self {
    Self(number: number)
  }
}

// NB: TODO: Basics explanation of why this is the way it is
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
          let (data, _) = try await URLSession.shared.data(
            from: URL(string: "http://numbersapi.com/\(number)")!
          )
          // The Numbers API can be quite fast. Let's simulate a slower connection.
          try await Task.sleep(for: .seconds(1))
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
