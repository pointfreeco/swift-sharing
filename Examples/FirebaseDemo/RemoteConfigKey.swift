import Dependencies
@preconcurrency import FirebaseRemoteConfig
import Sharing

extension SharedReaderKey  {
  static func remoteConfig<Value>(_ key: String) -> Self where Self == RemoteConfigKey<Value> {
    RemoteConfigKey(key: key)
  }
}

struct RemoteConfigKey<Value: Decodable & Sendable>: SharedReaderKey {
  let key: String
  var id: some Hashable { key }
  @Dependency(RemoteConfigDependencyKey.self) var remoteConfig
  func load(
    initialValue: Value?,
    didReceive callback: @escaping (Result<Value?, any Error>) -> Void
  ) {
    remoteConfig.fetchAndActivate { changed, error in
      if let error {
        callback(.failure(error))
      } else {
        callback(Result { try remoteConfig.configValue(forKey: key).decoded() })
      }
    }
  }
  func subscribe(
    initialValue: Value?,
    didReceive callback: @escaping (Result<Value?, any Error>) -> Void
  ) -> SharedSubscription {
    let registration = remoteConfig.addOnConfigUpdateListener { update, error in
      guard error == nil else { return }
      remoteConfig.activate { changed, error in
        guard error == nil else { return }
        callback(Result { try remoteConfig.configValue(forKey: key).decoded() })
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
