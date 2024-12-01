#if canImport(AppKit) || canImport(UIKit) || canImport(WatchKit)
  import Dependencies
  import Foundation
  import Sharing
  import Testing

  @Suite struct AppStorageTests {
    @Dependency(\.defaultAppStorage) var store

    @Test func bool() {
      @Shared(.appStorage("bool")) var bool = true
      #expect(store.bool(forKey: "bool"))
      store.set(false, forKey: "bool")
      #expect(!bool)
    }

    @Test func int() {
      @Shared(.appStorage("int")) var int = 42
      #expect(store.integer(forKey: "int") == 42)
      store.set(1729, forKey: "int")
      #expect(int == 1729)
    }

    @Test func double() {
      @Shared(.appStorage("double")) var double = 1.2
      #expect(store.double(forKey: "double") == 1.2)
      store.set(3.4, forKey: "double")
      #expect(double == 3.4)
    }

    @Test func string() {
      @Shared(.appStorage("string")) var string = "Blob"
      #expect(store.string(forKey: "string") == "Blob")
      store.set("Blob, Jr.", forKey: "string")
      #expect(string == "Blob, Jr.")
    }

    @Test func url() {
      @Shared(.appStorage("url")) var url = URL(fileURLWithPath: "/dev")
      #expect(store.url(forKey: "url") == URL(fileURLWithPath: "/dev"))
      store.set(URL(fileURLWithPath: "/tmp"), forKey: "url")
      #expect(url == URL(fileURLWithPath: "/tmp"))
    }

    @Test func data() {
      @Shared(.appStorage("data")) var data = Data([4, 2])
      #expect(store.data(forKey: "data") == Data([4, 2]))
      store.set(Data([1, 7, 2, 9]), forKey: "data")
      #expect(data == Data([1, 7, 2, 9]))
    }

    @Test func date() {
      @Shared(.appStorage("date")) var date = Date(timeIntervalSinceReferenceDate: 0)
      #expect(store.value(forKey: "date") as? Date == Date(timeIntervalSinceReferenceDate: 0))
      store.set(Date(timeIntervalSince1970: 0), forKey: "date")
      #expect(date == Date(timeIntervalSince1970: 0))
    }

    @Test func rawRepresentableInt() {
      struct ID: RawRepresentable {
        var rawValue: Int
      }
      @Shared(.appStorage("raw-representable-int")) var id = ID(rawValue: 42)
      #expect(store.integer(forKey: "raw-representable-int") == 42)
      store.set(1729, forKey: "raw-representable-int")
      #expect(id == ID(rawValue: 1729))
    }

    @Test func rawRepresentableString() {
      struct ID: RawRepresentable {
        var rawValue: String
      }
      @Shared(.appStorage("raw-representable-string")) var id = ID(rawValue: "Blob")
      #expect(store.string(forKey: "raw-representable-string") == "Blob")
      store.set("Blob, Jr.", forKey: "raw-representable-string")
      #expect(id == ID(rawValue: "Blob, Jr."))
    }

    @Test func optional() {
      @Shared(.appStorage("bool")) var bool: Bool?
      #expect(store.value(forKey: "bool") == nil)
      store.set(false, forKey: "bool")
      #expect(bool == false)
      $bool.withLock { $0 = nil }
      #expect(store.value(forKey: "bool") == nil)
    }

    @Test func optionalDefault() {
      @Shared(.appStorage("bool")) var bool: Bool? = true
      #expect(store.bool(forKey: "bool"))
      store.set(false, forKey: "bool")
      #expect(bool == false)
      store.removeObject(forKey: "bool")
      #expect(bool == true)
      store.set(Optional(false), forKey: "bool")
      #expect(bool == false)
      store.set(Bool?.none, forKey: "bool")
      #expect(bool == true)
      $bool.withLock { $0 = nil }
      #expect(bool == nil)
      #expect(store.value(forKey: "bool") == nil)
    }

    @Test func invalidKeyWarning() async {
      await withKnownIssue {
        @Shared(.appStorage("co.pointfree.isEnabled")) var isEnabled = false
        store.set(true, forKey: "co.pointfree.isEnabled")
        await MainActor.run {
          #expect(isEnabled)
        }
      } matching: {
        $0.description == """
          Issue recorded: A Shared app storage key ("co.pointfree.isEnabled") contains an invalid \
          character (".") for key-value observation. External updates will be observed less \
          efficiently and accurately via notification center, instead.

          Please reformat this key by removing invalid characters in order to ensure efficient, \
          cross-process observation.

          If you cannot control the format of this key and would like to silence this warning, \
          override the '\\.appStorageKeyFormatWarningEnabled' dependency at the entry point of your \
          application. For example:

              + import Dependencies

              \u{2007} @main
              \u{2007} struct MyApp: App {
              \u{2007}   init() {
              +     prepareDependencies {
              +       $0.appStorageKeyFormatWarningEnabled = false
              +     }
              \u{2007}     // ...
              \u{2007}   }

              \u{2007}   var body: some Scene { /* ... */ }
              \u{2007} }
          """
      }

      await withKnownIssue {
        @Shared(.appStorage("@count")) var count = 0
        store.set(42, forKey: "@count")
        await MainActor.run {
          #expect(count == 42)
        }
      } matching: {
        $0.description == """
          Issue recorded: A Shared app storage key ("@count") contains an invalid character ("@") \
          for key-value observation. External updates will be observed less efficiently and \
          accurately via notification center, instead.

          Please reformat this key by removing invalid characters in order to ensure efficient, \
          cross-process observation.

          If you cannot control the format of this key and would like to silence this warning, \
          override the '\\.appStorageKeyFormatWarningEnabled' dependency at the entry point of your \
          application. For example:

              + import Dependencies

              \u{2007} @main
              \u{2007} struct MyApp: App {
              \u{2007}   init() {
              +     prepareDependencies {
              +       $0.appStorageKeyFormatWarningEnabled = false
              +     }
              \u{2007}     // ...
              \u{2007}   }

              \u{2007}   var body: some Scene { /* ... */ }
              \u{2007} }
          """
      }
    }

    @Test func invalidKeyWarningSuppression() async {
      withDependencies {
        $0.appStorageKeyFormatWarningEnabled = false
      } operation: {
        @Shared(.appStorage("co.pointfree.isEnabled")) var isEnabled = false
        @Shared(.appStorage("@count")) var count = 0
      }
    }

    @Test func testPersistenceKeySubscription() async throws {
      let persistenceKey: AppStorageKey<Int> = .appStorage("shared")
      let changes = LockIsolated<[Int?]>([])
      var subscription: Optional = persistenceKey.subscribe(initialValue: nil) { value in
        changes.withValue { $0.append(value) }
      }
      @Dependency(\.defaultAppStorage) var userDefaults
      userDefaults.set(1, forKey: "shared")
      userDefaults.set(42, forKey: "shared")
      subscription?.cancel()
      userDefaults.set(123, forKey: "shared")
      subscription = nil
      #expect([1, 42] == changes.value)
      #expect(123 == persistenceKey.load(initialValue: nil))
    }
  }
#endif
