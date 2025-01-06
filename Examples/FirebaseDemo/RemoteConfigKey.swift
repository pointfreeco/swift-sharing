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
  var id: some Hashable { key }
  @Dependency(RemoteConfigDependencyKey.self) var remoteConfig
  func load(context _: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    remoteConfig.fetchAndActivate { changed, error in
      if let error {
        continuation.resume(throwing: error)
      } else {
        continuation.resume(with: Result { try remoteConfig.configValue(forKey: key).decoded() })
      }
    }
  }
  func subscribe(
    context _: LoadContext<Value>, subscriber: SharedSubscriber<Value>
  ) -> SharedSubscription {
    let registration = remoteConfig.addOnConfigUpdateListener { update, error in
      guard error == nil else { return }
      remoteConfig.activate { changed, error in
        guard error == nil else { return }
        subscriber.yield(with: Result { try remoteConfig.configValue(forKey: key).decoded() })
      }
    }
    return SharedSubscription {
      registration.remove()
    }
  }
}

private enum RemoteConfigDependencyKey: DependencyKey {
  public static var liveValue: RemoteConfig {
    let remoteConfig = RemoteConfig.remoteConfig()
    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    remoteConfig.configSettings = settings
    return remoteConfig
  }
}
