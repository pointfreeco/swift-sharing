#if canImport(AppKit) || canImport(UIKit) || canImport(WatchKit)
  import Dependencies
  @preconcurrency import Foundation

  #if canImport(AppKit)
    import AppKit
  #endif
  #if canImport(UIKit)
    import UIKit
  #endif
  #if canImport(WatchKit)
    import WatchKit
  #endif

  extension SharedReaderKey {
    /// Creates a shared key that can read and write to a boolean user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Bool> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an integer user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Int> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a double user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Double> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a string user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<String> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a URL user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<URL> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a user default as data.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Data> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a date user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Date> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an integer user default, transforming
    /// that to a `RawRepresentable` data type.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage<Value: RawRepresentable<Int>>(
      _ key: String, store: UserDefaults? = nil
    ) -> Self
    where Self == AppStorageKey<Value> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a string user default, transforming
    /// that to a `RawRepresentable` data type.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage<Value: RawRepresentable<String>>(
      _ key: String, store: UserDefaults? = nil
    ) -> Self
    where Self == AppStorageKey<Value> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional boolean user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Bool?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional integer user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Int?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional double user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Double?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional string user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<String?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional URL user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<URL?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to a user default as optional data.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Data?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional date user default.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage(_ key: String, store: UserDefaults? = nil) -> Self
    where Self == AppStorageKey<Date?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional integer user default,
    /// transforming that to a `RawRepresentable` data type.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage<Value: RawRepresentable>(
      _ key: String, store: UserDefaults? = nil
    ) -> Self
    where Value.RawValue == Int, Self == AppStorageKey<Value?> {
      AppStorageKey(key, store: store)
    }

    /// Creates a shared key that can read and write to an optional string user default,
    /// transforming that to a `RawRepresentable` data type.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults store.
    ///   - store: The user defaults store to read and write to. A value of `nil` will use the user
    ///     default store from dependencies.
    /// - Returns: A user defaults shared key.
    public static func appStorage<Value: RawRepresentable>(
      _ key: String, store: UserDefaults? = nil
    ) -> Self
    where Value.RawValue == String, Self == AppStorageKey<Value?> {
      AppStorageKey(key, store: store)
    }
  }

  /// A type defining a user defaults persistence strategy.
  public struct AppStorageKey<Value: Sendable>: SharedKey {
    private let lookup: any Lookup<Value>
    private let key: String
    private let store: UncheckedSendable<UserDefaults>

    public var id: AppStorageKeyID {
      AppStorageKeyID(key: key, store: store.wrappedValue)
    }

    private init(lookup: some Lookup<Value>, key: String, store: UserDefaults?) {
      @Dependency(\.defaultAppStorage) var defaultStore
      self.lookup = lookup
      self.key = key
      let store = store ?? defaultStore
      self.store = UncheckedSendable(store)
      #if DEBUG
        if store.responds(to: Selector(("_identifier"))),
          let suiteName = store.perform(Selector(("_identifier"))).takeUnretainedValue() as? String
        {
          let objectID = ObjectIdentifier(store)
          suites.withLock { suites in
            defer { suites[suiteName] = objectID }
            if let id = suites[suiteName], id != objectID {
              reportIssue(
                """
                '@Shared(\(self))' was given a new store object for an existing suite name \
                (\(suiteName.debugDescription)).

                Shared app storage for a given suite should all share the same store object to \
                ensure synchronization and observation. For example, define a store as a \
                'static let' and refer to this single instance when creating shared app storage:

                    extension UserDefaults {
                      nonisolated(unsafe) static let mySuite = UserDefaults(
                        suiteName: \(suiteName.debugDescription)
                      )!
                    }

                    @Shared(.appStorage(\(key.debugDescription), store: .mySuite) var myProperty
                """
              )
            }
          }
        }
      #endif
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Bool {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Int {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Double {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == String {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == URL {
      self.init(lookup: URLLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Data {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Date {
      self.init(lookup: CastableLookup(), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value: RawRepresentable<Int> {
      self.init(lookup: RawRepresentableLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value: RawRepresentable<String> {
      self.init(lookup: RawRepresentableLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Bool? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Int? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Double? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == String? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == URL? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Data? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init(_ key: String, store: UserDefaults?) where Value == Date? {
      self.init(lookup: OptionalLookup(base: CastableLookup()), key: key, store: store)
    }

    fileprivate init<R: RawRepresentable<Int>>(_ key: String, store: UserDefaults?)
    where Value == R? {
      self.init(
        lookup: OptionalLookup(base: RawRepresentableLookup(base: CastableLookup())),
        key: key,
        store: store
      )
    }

    fileprivate init<R: RawRepresentable<String>>(_ key: String, store: UserDefaults?)
    where Value == R? {
      self.init(
        lookup: OptionalLookup(base: RawRepresentableLookup(base: CastableLookup())),
        key: key,
        store: store
      )
    }

    public func load(initialValue: Value?) -> Value? {
      lookup.loadValue(from: store.wrappedValue, at: key, default: initialValue)
    }

    public func save(_ value: Value, immediately: Bool) {
      lookup.saveValue(value, to: store.wrappedValue, at: key)
    }

    public func subscribe(
      initialValue: Value?,
      didSet receiveValue: @escaping @Sendable (_ newValue: Value?) -> Void
    ) -> SharedSubscription {
      let previousValue = LockIsolated(initialValue)
      let removeObserver: @Sendable () -> Void
      let keyContainsPeriod = key.contains(".")
      if keyContainsPeriod || key.hasPrefix("@") {
        @Dependency(\.appStorageKeyFormatWarningEnabled) var appStorageKeyFormatWarningEnabled
        if appStorageKeyFormatWarningEnabled {
          let character = keyContainsPeriod ? "." : "@"
          reportIssue(
            """
            A Shared app storage key (\(key.debugDescription)) contains an invalid character \
            (\(character.debugDescription)) for key-value observation. External updates will be \
            observed less efficiently and accurately via notification center, instead.

            Please reformat this key by removing invalid characters in order to ensure efficient, \
            cross-process observation.

            If you cannot control the format of this key and would like to silence this warning, \
            override the '\\.appStorageKeyFormatWarningEnabled' dependency at the entry point of \
            your application. For example:

                + import Dependencies

                  @main
                  struct MyApp: App {
                    init() {
                +     prepareDependencies {
                +       $0.appStorageKeyFormatWarningEnabled = false
                +     }
                      // ...
                    }

                    var body: some Scene { /* ... */ }
                  }
            """
          )
        }
        let userDefaultsDidChange = NotificationCenter.default.addObserver(
          forName: UserDefaults.didChangeNotification,
          object: store.wrappedValue,
          queue: nil
        ) { _ in
          let newValue = load(initialValue: initialValue)
          defer { previousValue.withValue { $0 = newValue } }
          func isEqual<T>(_ lhs: T, _ rhs: T) -> Bool? {
            func open<U: Equatable>(_ lhs: U) -> Bool {
              lhs == rhs as? U
            }
            guard let lhs = lhs as? any Equatable else { return nil }
            return open(lhs)
          }
          guard
            !(isEqual(newValue, previousValue.value) ?? false)
              || (isEqual(newValue, initialValue) ?? true)
          else {
            return
          }
          guard !SharedAppStorageLocals.isSetting
          else { return }
          DispatchQueue.main.async { receiveValue(newValue) }
        }
        removeObserver = { NotificationCenter.default.removeObserver(userDefaultsDidChange) }
      } else {
        let observer = Observer {
          guard !SharedAppStorageLocals.isSetting
          else { return }
          receiveValue(load(initialValue: initialValue))
        }
        store.wrappedValue.addObserver(observer, forKeyPath: key, context: nil)
        removeObserver = { store.wrappedValue.removeObserver(observer, forKeyPath: key) }
      }
      let willEnterForeground: (any NSObjectProtocol)?
      if let willEnterForegroundNotificationName {
        willEnterForeground = NotificationCenter.default.addObserver(
          forName: willEnterForegroundNotificationName,
          object: nil,
          queue: .main
        ) { _ in
          receiveValue(load(initialValue: initialValue))
        }
      } else {
        willEnterForeground = nil
      }
      return SharedSubscription {
        removeObserver()
        if let willEnterForeground {
          NotificationCenter.default.removeObserver(willEnterForeground)
        }
      }
    }

    private final class Observer: NSObject, Sendable {
      let didChange: @Sendable () -> Void
      init(didChange: @escaping @Sendable () -> Void) {
        self.didChange = didChange
        super.init()
      }
      override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
      ) {
        self.didChange()
      }
    }
  }

  extension AppStorageKey: CustomStringConvertible {
    public var description: String {
      ".appStorage(\(String(reflecting: key)))"
    }
  }

  public struct AppStorageKeyID: Hashable {
    fileprivate let key: String
    fileprivate let store: UserDefaults
  }

  extension DependencyValues {
    public var defaultAppStorage: UserDefaults {
      get { self[DefaultAppStorageKey.self].value }
      set { self[DefaultAppStorageKey.self].value = newValue }
    }

    public var appStorageKeyFormatWarningEnabled: Bool {
      get { self[AppStorageKeyFormatWarningEnabledKey.self] }
      set { self[AppStorageKeyFormatWarningEnabledKey.self] = newValue }
    }
  }

  private enum DefaultAppStorageKey: DependencyKey {
    static var testValue: UncheckedSendable<UserDefaults> {
      UncheckedSendable(
        UserDefaults(
          suiteName:
            "\(NSTemporaryDirectory())co.pointfree.Sharing.\(UUID().uuidString)"
        )!
      )
    }
    static var previewValue: UncheckedSendable<UserDefaults> {
      testValue
    }
    static var liveValue: UncheckedSendable<UserDefaults> {
      UncheckedSendable(UserDefaults.standard)
    }
  }

  private enum AppStorageKeyFormatWarningEnabledKey: DependencyKey {
    static let liveValue = true
    static let testValue = true
  }

  // NB: This is mainly used for tests, where observer notifications can bleed across cases.
  private enum SharedAppStorageLocals {
    @TaskLocal static var isSetting = false
  }

  private protocol Lookup<Value>: Sendable {
    associatedtype Value: Sendable
    func loadValue(from store: UserDefaults, at key: String, default defaultValue: Value?) -> Value?
    func saveValue(_ newValue: Value, to store: UserDefaults, at key: String)
  }

  private struct CastableLookup<Value: Sendable>: Lookup {
    func loadValue(
      from store: UserDefaults,
      at key: String,
      default defaultValue: Value?
    ) -> Value? {
      guard let value = store.object(forKey: key) as? Value
      else {
        guard !SharedAppStorageLocals.isSetting
        else { return nil }
        SharedAppStorageLocals.$isSetting.withValue(true) {
          store.set(defaultValue, forKey: key)
        }
        return nil
      }
      return value
    }

    func saveValue(_ newValue: Value, to store: UserDefaults, at key: String) {
      SharedAppStorageLocals.$isSetting.withValue(true) {
        store.set(newValue, forKey: key)
      }
    }
  }

  private struct URLLookup: Lookup {
    typealias Value = URL

    func loadValue(from store: UserDefaults, at key: String, default defaultValue: URL?) -> URL? {
      guard let value = store.url(forKey: key)
      else {
        guard !SharedAppStorageLocals.isSetting
        else { return nil }
        SharedAppStorageLocals.$isSetting.withValue(true) {
          store.set(defaultValue, forKey: key)
        }
        return nil
      }
      return value
    }

    func saveValue(_ newValue: URL, to store: UserDefaults, at key: String) {
      SharedAppStorageLocals.$isSetting.withValue(true) {
        store.set(newValue, forKey: key)
      }
    }
  }

  private struct RawRepresentableLookup<Value: RawRepresentable & Sendable, Base: Lookup>: Lookup
  where Value.RawValue == Base.Value {
    let base: Base
    func loadValue(
      from store: UserDefaults, at key: String, default defaultValue: Value?
    ) -> Value? {
      base.loadValue(from: store, at: key, default: defaultValue?.rawValue)
        .flatMap(Value.init(rawValue:))
    }
    func saveValue(_ newValue: Value, to store: UserDefaults, at key: String) {
      base.saveValue(newValue.rawValue, to: store, at: key)
    }
  }

  private struct OptionalLookup<Base: Lookup>: Lookup {
    let base: Base
    func loadValue(
      from store: UserDefaults, at key: String, default defaultValue: Base.Value??
    ) -> Base.Value?? {
      base.loadValue(from: store, at: key, default: defaultValue ?? nil)
        .flatMap(Optional.some)
        ?? .none
    }
    func saveValue(_ newValue: Base.Value?, to store: UserDefaults, at key: String) {
      if let newValue {
        base.saveValue(newValue, to: store, at: key)
      } else {
        SharedAppStorageLocals.$isSetting.withValue(true) {
          store.removeObject(forKey: key)
        }
      }
    }
  }

  private let willEnterForegroundNotificationName: Notification.Name? = {
    #if os(macOS)
      return NSApplication.willBecomeActiveNotification
    #elseif os(iOS) || os(tvOS) || os(visionOS)
      return UIApplication.willEnterForegroundNotification
    #elseif os(watchOS)
      if #available(watchOS 7, *) {
        return WKExtension.applicationWillEnterForegroundNotification
      } else {
        return nil
      }
    #else
      return nil
    #endif
  }()

  #if DEBUG
    private let suites = Mutex<[String: ObjectIdentifier]>([:])
  #endif
#endif
