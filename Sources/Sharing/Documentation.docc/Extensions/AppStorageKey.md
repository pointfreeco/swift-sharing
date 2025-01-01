# ``Sharing/AppStorageKey``

A ``SharedKey`` conformance that persists simple pieces of data to user defaults, such as numbers,
strings, booleans and URLs. It can be used with ``Shared`` by providing the 
``SharedReaderKey/appStorage(_:store:)-45ltk`` value and specifying a default value:

```swift
@Shared(.appStorage("isOn")) var isOn = true
```

Any changes made to this value will be synchronized to user defaults. Further, any change made to 
the "isOn" key in user defaults will be immediately played back to the `@Shared` value, as this
test proves:

```swift
@Test func externalWrite() {
  @Shared(.appStorage("isOn")) var isOn = true
  #expect(isOn == true)  
  UserDefaults.standard.set(false, forKey: "isOn")
  #expect(isOn == false)
}
```

### Default app storage

When running your app in a simulator or device, `appStorage` will use the `standard` user defaults 
for persisting your state. If you want to use a different user defaults, you can invoke the 
`prepareDependencies` function in the entry point of your application:

```swift
@main struct EntryPoint: App {
  init() {
    prepareDependencies {
      $0.defaultAppStorage = UserDefaults(suiteName: "co.pointfree.suite")!
    }
  }
  // ...
}
```

That will make it so that all `@Shared(.appStorage)` instances use your custom user defaults.

In previews `@Shared` will use a temporary, ephemeral user defaults so that each run of the preview
gets a clean slate. This makes it so that previews do not mutate each other's storage and allows
you to fully control how your previews behave. If you want to use the `standard` user defaults
in previews you can use `prepareDependencies`:

```swift
#Preview {
  let _ = prepareDependencies { $0.defaultAppStorage = .standard }
  // ...
}
```

And finally, in tests `@Shared` will also use a temporary, ephemeral user defaults. This makes it
so that each test runs in a sandboxed environment that does not interfere with other tests or the 
simulator. A benefit of this is that your tests can pass deterministically and tests can be run
in parallel. If you want to use the `standard` user defaults in tests you can use the `dependency`
test trait:

```swift
@Test(.dependency(\.defaultAppStorage, .standard))
func basics() {
  // ...
}
```

### Special characters in keys

The `appStorage` persistence strategy can change its behavior depending on the characters its key
contains. If the key does not contain periods (".") or at-symbols ("@"), then `appStorage` can use
KVO to observe changes to the key. This has a number of benefits: it can observe changes to only
the key instead of all of user defaults, it can deliver changes to `@Shared` synchronously, and
changes can be animated.

If the key does contain periods or at-symbols, then `appStorage` must use `NotificationCenter`
to listen for changes since those symbols have special meaning in KVO. This has a number of 
downsides: `appStorage` must listen to the firehose of _all_ changes in `UserDefaults`, it must
perform extra work to de-duplicate changes, it must perform a thread hop before it updates the
`@Shared` state, and state changes cannot be animated.

When your key contains a period or at-symbol `appStorage` will emit a runtime warning letting you
know of its behavior. If you still wish to use periods or at-symbols you can disable this warning
by running the following in the entry point of your app:

```swift
prepareDependencies {
  $0.appStorageKeyFormatWarningEnabled = false
}
```

> Important: We highly recommend that you avoid using periods and at-symbols in your `appStorage`
keys. Instead you can use other delimiting symbols, such as ":", "|", "/", etc.

## Topics

### Storing a value

- ``SharedReaderKey/appStorage(_:store:)-45ltk``  <!-- Bool -->
- ``SharedReaderKey/appStorage(_:store:)-vqgl``   <!-- Data -->
- ``SharedReaderKey/appStorage(_:store:)-3dtm``   <!-- Date -->
- ``SharedReaderKey/appStorage(_:store:)-7dai0``  <!-- Double -->
- ``SharedReaderKey/appStorage(_:store:)-c6ap``   <!-- Int -->
- ``SharedReaderKey/appStorage(_:store:)-5663z``  <!-- String -->
- ``SharedReaderKey/appStorage(_:store:)-6msr0``  <!-- URL -->
- ``SharedReaderKey/appStorage(_:store:)-2tp0t``  <!-- RawRepresentable<Int> -->
- ``SharedReaderKey/appStorage(_:store:)-95ztf``  <!-- RawRepresentable<String> -->

### Storing an optional value

- ``SharedReaderKey/appStorage(_:store:)-8ys3t``  <!-- Bool? -->
- ``SharedReaderKey/appStorage(_:store:)-1vfr4``  <!-- Data? -->
- ``SharedReaderKey/appStorage(_:store:)-8cy6a``  <!-- Date? -->
- ``SharedReaderKey/appStorage(_:store:)-8f3hz``  <!-- Double? -->
- ``SharedReaderKey/appStorage(_:store:)-8bf8y``  <!-- Int? -->
- ``SharedReaderKey/appStorage(_:store:)-4la2p``  <!-- String? -->
- ``SharedReaderKey/appStorage(_:store:)-7fd26``  <!-- URL? -->
- ``SharedReaderKey/appStorage(_:store:)-2vfgj``  <!-- RawRepresentable<Int?> -->
- ``SharedReaderKey/appStorage(_:store:)-2i17q``  <!-- RawRepresentable<String?> -->

### Overriding app storage

- ``Dependencies/DependencyValues/defaultAppStorage``
- ``Dependencies/DependencyValues/appStorageKeyFormatWarningEnabled``

### Identifying storage

- ``AppStorageKeyID``
