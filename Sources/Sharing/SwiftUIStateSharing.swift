#if canImport(SwiftUI)
  import SwiftUI

  extension State {
    @propertyWrapper
    public struct Shared: DynamicProperty, Sendable {
      @SwiftUI.State private var shared: Sharing.Shared<Value>

      public var wrappedValue: Value {
        shared.wrappedValue
      }

      public var projectedValue: Sharing.Shared<Value> {
        get { shared }
        nonmutating set { shared.projectedValue = newValue }
      }

      public init(value: sending Value) {
        shared = Sharing.Shared(value: value)
      }

      public init(projectedValue: Sharing.Shared<Value>) {
        shared = projectedValue
      }

      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: some SharedKey<Value>
      ) {
        shared = Sharing.Shared(wrappedValue: wrappedValue(), key)
      }

      @_disfavoredOverload
      public init<Wrapped>(_ key: some SharedKey<Value>) where Value == Wrapped? {
        shared = Sharing.Shared(key)
      }

      public init(_ key: (some SharedKey<Value>).Default) {
        shared = Sharing.Shared(wrappedValue: key.initialValue, key)
      }

      @_disfavoredOverload
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: (some SharedKey<Value>).Default
      ) {
        shared = Sharing.Shared(wrappedValue: wrappedValue(), key)
      }

      public init(require key: some SharedKey<Value>) async throws {
        shared = try await Sharing.Shared(require: key)
      }

      @available(*, unavailable, message: "Assign a default value")
      public init(_ key: some SharedKey<Value>) {
        fatalError()
      }
    }

    @propertyWrapper
    public struct SharedReader: DynamicProperty, Sendable {
      @SwiftUI.State private var shared: Sharing.SharedReader<Value>

      public var wrappedValue: Value {
        shared.wrappedValue
      }

      public var projectedValue: Sharing.SharedReader<Value> {
        get { shared }
        nonmutating set { shared.projectedValue = newValue }
      }

      public init(value: sending Value) {
        shared = Sharing.SharedReader(value: value)
      }

      public init(projectedValue: Sharing.SharedReader<Value>) {
        shared = projectedValue
      }

      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: some SharedReaderKey<Value>
      ) {
        shared = Sharing.SharedReader(wrappedValue: wrappedValue(), key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: some SharedKey<Value>
      ) {
        shared = Sharing.SharedReader(wrappedValue: wrappedValue(), key)
      }

      @_disfavoredOverload
      public init<Wrapped>(_ key: some SharedReaderKey<Value>) where Value == Wrapped? {
        shared = Sharing.SharedReader(key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init<Wrapped>(_ key: some SharedKey<Value>) where Value == Wrapped? {
        shared = Sharing.SharedReader(key)
      }

      public init(_ key: (some SharedReaderKey<Value>).Default) {
        shared = Sharing.SharedReader(key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(_ key: (some SharedKey<Value>).Default) {
        shared = Sharing.SharedReader(key)
      }

      @_disfavoredOverload
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: (some SharedReaderKey<Value>).Default
      ) {
        shared = Sharing.SharedReader(wrappedValue: wrappedValue(), key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: (some SharedKey<Value>).Default
      ) {
        shared = Sharing.SharedReader(wrappedValue: wrappedValue(), key)
      }

      public init(require key: some SharedReaderKey<Value>) async throws {
        shared = try await Sharing.SharedReader(require: key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(require key: some SharedKey<Value>) async throws {
        shared = try await Sharing.SharedReader(require: key)
      }

      @available(*, unavailable, message: "Assign a default value")
      public init(_ key: some SharedReaderKey<Value>) {
        fatalError()
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      @available(*, unavailable, message: "Assign a default value")
      public init(_ key: some SharedKey<Value>) {
        fatalError()
      }
    }
  }

  extension State.Shared: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.shared == rhs.shared
    }
  }

  extension State.Shared: Identifiable where Value: Identifiable {
    public var id: Value.ID {
      shared.id
    }
  }

  extension State.SharedReader: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.shared == rhs.shared
    }
  }

  extension State.SharedReader: Identifiable where Value: Identifiable {
    public var id: Value.ID {
      shared.id
    }
  }
#endif
