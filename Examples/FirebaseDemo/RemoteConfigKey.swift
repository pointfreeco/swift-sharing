@preconcurrency import Combine
import Dependencies
@preconcurrency import FirebaseRemoteConfig
import Sharing

extension SharedReaderKey {
  static func remoteConfig<Value>(_ key: String) -> Self where Self == RemoteConfigKey<Value> {
    RemoteConfigKey(key: key)
  }
}

struct RemoteConfigKey<Value: Decodable & Sendable>: SharedReaderKey {
  let key: String
  let remoteConfig: any RemoteConfigClient

  init(key: String) {
    self.key = key
    @Dependency(\.remoteConfig) var remoteConfig
    self.remoteConfig = remoteConfig
  }

  var id: some Hashable { key }

  func load(context _: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    remoteConfig.fetch(key: key, completion: continuation.resume(with:))
  }
  func subscribe(
    context _: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    let cancellable = remoteConfig.addUpdateListener(
      key: key,
      subscriber: subscriber.yield(with:)
    )
    return SharedSubscription {
      cancellable.cancel()
    }
  }
}

protocol RemoteConfigClient: Sendable {
  func fetch<T: Decodable>(
    key: String,
    completion: @escaping (Result<T, any Error>) -> Void
  )
  func addUpdateListener<T: Decodable>(
    key: String,
    subscriber: @escaping (Result<T, any Error>) -> Void
  ) -> AnyCancellable
}

private enum RemoteConfigClientKey: DependencyKey {
  static var liveValue: any RemoteConfigClient {
    FirebaseRemoteConfig()
  }
}

extension DependencyValues {
  var remoteConfig: any RemoteConfigClient {
    get { self[RemoteConfigClientKey.self] }
    set { self[RemoteConfigClientKey.self] = newValue }
  }
}

struct FirebaseRemoteConfig: RemoteConfigClient {
  let remoteConfig = RemoteConfig.remoteConfig()
  init() {
    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    remoteConfig.configSettings = settings
  }
  func fetch<T: Decodable>(key: String, completion: @escaping (Result<T, any Error>) -> Void) {
    remoteConfig.fetchAndActivate { _, error in
      completion(
        Result {
          try remoteConfig.configValue(forKey: key).decoded()
        }
      )
    }
  }
  func addUpdateListener<T: Decodable>(
    key: String,
    subscriber: @escaping (Result<T, any Error>) -> Void
  ) -> AnyCancellable {
    let registration = remoteConfig.addOnConfigUpdateListener { _, error in
      guard error == nil else { return }
      remoteConfig.activate { changed, error in
        guard error == nil else { return }
        subscriber(Result { try remoteConfig.configValue(forKey: key).decoded() })
      }
    }
    return AnyCancellable { registration.remove() }
  }
}

final class MockRemoteConfig: RemoteConfigClient {
  let config: [String: any Sendable]
  init(config: [String: any Sendable]) {
    self.config = config
  }
  func fetch<T: Decodable>(
    key: String,
    completion: @escaping (Result<T, any Error>) -> Void
  ) {
    guard let value = config[key] as? T
    else {
      completion(.failure(NotFound()))
      return
    }
    completion(.success(value))
  }
  func addUpdateListener<T: Decodable>(
    key: String,
    subscriber: @escaping (Result<T, any Error>) -> Void
  ) -> AnyCancellable {
    AnyCancellable {}
  }
  struct NotFound: Error {}
}
