#if canImport(SwiftUI)
  import SwiftUI

  extension State {
    /// A dynamic property that holds a shared property in view state.
    ///
    /// This property is a more ergonomic shorthand for holding a ``Shared`` in SwiftUI's `@State`
    /// property wrapper, and can be initialized in all the same ways `@Shared` can be initialized.
    ///
    /// Instead of explicitly going through extra layers of `$state.wrappedValue` to get to the
    /// shared property wrapper, you can project directly to it:
    ///
    /// ```diff
    ///  struct BooksView: View {
    /// -  @State @Shared var books: [Book]
    /// +  @State.Shared var books: [Book]
    ///
    ///    init(
    /// -    _books = State(wrappedValue: Shared(.books(searchText)))
    /// +    _books = State.Shared(.books(searchText))
    ///    )
    ///
    ///    var body: some View {
    ///      List {
    ///        // ...
    ///      }
    ///      .refreshable {
    /// -      try? await $books.wrappedValue.load(.books(searchText))
    /// +      try? await $books.load(.books(searchText))
    ///      }
    ///      .searchable(text: $searchText)
    ///      .onChange(of: searchText) {
    /// -      $books.wrappedValue = Shared(.books(searchText))
    /// +      $books = Shared(.books(searchText))
    ///      }
    ///    }
    ///  }
    /// ```
    @propertyWrapper
    public struct Shared: DynamicProperty {
      @SwiftUI.State private var shared: Sharing.Shared<Value>

      @_documentation(visibility: private)
      public var wrappedValue: Value {
        shared.wrappedValue
      }

      @_documentation(visibility: private)
      public var projectedValue: Sharing.Shared<Value> {
        get { shared }
        nonmutating set { shared.projectedValue = newValue }
      }

      #if compiler(>=6)
        @_documentation(visibility: private)
        public init(value: sending Value) {
          shared = Sharing.Shared(value: value)
        }
      #else
        @_documentation(visibility: private)
        public init(value: Value) {
          shared = Sharing.Shared(value: value)
        }
      #endif

      @_documentation(visibility: private)
      public init(projectedValue: Sharing.Shared<Value>) {
        shared = projectedValue
      }

      @_documentation(visibility: private)
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: some SharedKey<Value>
      ) {
        shared = Sharing.Shared(wrappedValue: wrappedValue(), key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init<Wrapped>(_ key: some SharedKey<Value>) where Value == Wrapped? {
        shared = Sharing.Shared(key)
      }

      @_documentation(visibility: private)
      public init(_ key: (some SharedKey<Value>).Default) {
        shared = Sharing.Shared(wrappedValue: key.initialValue, key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(
        wrappedValue: @autoclosure () -> Value,
        _ key: (some SharedKey<Value>).Default
      ) {
        shared = Sharing.Shared(wrappedValue: wrappedValue(), key)
      }

      @_documentation(visibility: private)
      public init(require key: some SharedKey<Value>) async throws {
        shared = try await Sharing.Shared(require: key)
      }

      @_documentation(visibility: private)
      @available(*, unavailable, message: "Assign a default value")
      public init(_ key: some SharedKey<Value>) {
        fatalError()
      }
    }

    /// A dynamic property that holds a shared reader in view state.
    ///
    /// This property is a more ergonomic shorthand for holding a ``SharedReader`` in SwiftUI's
    /// `@State` property wrapper, and can be initialized in all the same ways `@SharedReader` can
    /// be initialized.
    ///
    /// Instead of explicitly going through extra layers of `$state.wrappedValue` to get to the
    /// shared property wrapper, you can project directly to it:
    ///
    /// ```diff
    ///  struct BooksView: View {
    /// -  @State @SharedReader var books: [Book]
    /// +  @State.SharedReader var books: [Book]
    ///
    ///    init(
    /// -    _books = State(wrappedValue: SharedReader(.books(searchText)))
    /// +    _books = State.SharedReader(.books(searchText))
    ///    )
    ///
    ///    var body: some View {
    ///      List {
    ///        // ...
    ///      }
    ///      .refreshable {
    /// -      try? await $books.wrappedValue.load(.books(searchText))
    /// +      try? await $books.load(.books(searchText))
    ///      }
    ///      .searchable(text: $searchText)
    ///      .onChange(of: searchText) {
    /// -      $books.wrappedValue = SharedReader(.books(searchText))
    /// +      $books = SharedReader(.books(searchText))
    ///      }
    ///    }
    ///  }
    /// ```
    @propertyWrapper
    public struct SharedReader: DynamicProperty {
      @SwiftUI.State private var shared: Sharing.SharedReader<Value>

      @_documentation(visibility: private)
      public var wrappedValue: Value {
        shared.wrappedValue
      }

      @_documentation(visibility: private)
      public var projectedValue: Sharing.SharedReader<Value> {
        get { shared }
        nonmutating set { shared.projectedValue = newValue }
      }

      #if compiler(>=6)
        @_documentation(visibility: private)
        public init(value: sending Value) {
          shared = Sharing.SharedReader(value: value)
        }
      #else
        @_documentation(visibility: private)
        public init(value: Value) {
          shared = Sharing.SharedReader(value: value)
        }
      #endif

      @_documentation(visibility: private)
      public init(projectedValue: Sharing.SharedReader<Value>) {
        shared = projectedValue
      }

      @_documentation(visibility: private)
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

      @_documentation(visibility: private)
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

      @_documentation(visibility: private)
      public init(require key: some SharedReaderKey<Value>) async throws {
        shared = try await Sharing.SharedReader(require: key)
      }

      @_disfavoredOverload
      @_documentation(visibility: private)
      public init(require key: some SharedKey<Value>) async throws {
        shared = try await Sharing.SharedReader(require: key)
      }

      @_documentation(visibility: private)
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

  #if compiler(>=6)
    extension State.Shared: Sendable where Value: Sendable {}

    extension State.SharedReader: Sendable where Value: Sendable {}
  #endif
#endif
