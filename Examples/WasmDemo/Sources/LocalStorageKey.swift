import Foundation
import JavaScriptKit
import Sharing

extension SharedKey {
  static func localStorage<Value>(_ key: String) -> Self where Self == LocalStorageKey<Value> {
    LocalStorageKey(key: key)
  }
}

struct LocalStorageKey<Value: Codable & Sendable>: SharedKey {
  let key: String

  var id: some Hashable { key }

  func load(context _: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    continuation.resume(with: Result { try getAndDecodeItem() })
  }

  func subscribe(
    context _: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    nonisolated(unsafe) let listener = JSClosure { _ in
      subscriber.yield(with: Result { try getAndDecodeItem() })
      return .undefined
    }
    _ = JSObject.global.window.addEventListener("storage", listener)
    return SharedSubscription {
      _ = JSObject.global.window.removeEventListener("storage", listener)
    }
  }

  func save(_ value: Value, context _: SaveContext, continuation: SaveContinuation) {
    continuation.resume(
      with: Result {
        _ = try JSObject.global.window.localStorage.setItem(
          key,
          String(decoding: JSONEncoder().encode(value), as: UTF8.self)
        )
      }
    )
  }

  private func getAndDecodeItem() throws -> Value? {
    guard let string = JSObject.global.window.localStorage.getItem(key).string
    else { return nil }
    return try JSONDecoder().decode(Value.self, from: Data(string.utf8))
  }
}
