extension SharedReaderKey {
  /// Provides a default value to a shared key.
  ///
  /// Use this when constructing type-safe keys (see <doc:TypeSafeKeys> for more
  /// info) to provide a default that is used instead of providing one at the call site of using
  /// [`@Shared`](<doc:Shared>).
  ///
  /// For example, if an `isOn` value is backed by user defaults and it should default to `false`
  /// when there is no value in user defaults, then you can define a shared key like so:
  ///
  /// ```swift
  /// extension SharedKey where Self == AppStorageKey<Bool>.Default {
  ///   static var isOn: Self {
  ///     Self[.appStorage("isOn"), default: false]
  ///   }
  /// }
  /// ```
  ///
  /// And then use it like so:
  ///
  /// ```swift
  /// @Shared(.isOn) var isOn
  /// ```
  public typealias Default = _SharedKeyDefault<Self>
}

public struct _SharedKeyDefault<Base: SharedReaderKey>: SharedReaderKey {
  let base: Base
  let defaultValue: @Sendable () -> Base.Value

  public var id: Base.ID {
    base.id
  }

  /// Wraps an existing shared key in a shared key that provides a default value.
  ///
  /// - Parameters:
  ///   - key: A shared key.
  ///   - value: A default value that is used when no value can be returned from the given key's
  ///     persisted storage.
  public static subscript(
    _ key: Base,
    default value: @autoclosure @escaping @Sendable () -> Base.Value
  ) -> Self {
    Self(base: key, defaultValue: value)
  }

  public func load(initialValue: Base.Value?) -> Base.Value? {
    base.load(initialValue: initialValue ?? defaultValue())
  }

  public func subscribe(
    initialValue: Base.Value?,
    didSet receiveValue: @escaping @Sendable (Base.Value?) -> Void
  ) -> SharedSubscription {
    base.subscribe(initialValue: initialValue, didSet: receiveValue)
  }
}

extension _SharedKeyDefault: SharedKey where Base: SharedKey {
  public func save(_ value: Value, immediately: Bool) {
    base.save(value, immediately: immediately)
  }
}

extension _SharedKeyDefault: CustomStringConvertible {
  public var description: String {
    """
    \(typeName(type(of: base), genericsAbbreviated: false))\
    .Default[\(base), default: \(defaultValue())]
    """
  }
}
