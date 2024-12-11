# Testing

Learn how to test features that use shared state, even when persistence strategies are involved.

## Overview

Introducing shared state to an application has the potential to complicate unit testing one's 
features. This is because shared state naturally behaves like a reference type, in that it can be
read and modified from anywhere in the app. And further, `@Shared` properties are often backed by 
external storages, such as user defaults and the file system, which can cause multiple tests to
trample over each other.

Luckily the tools in this library were built with testing in mind, and you can usually test your
features as if you were holding onto regular, non-shared state. For example, if you have a model
that holds onto an integer that is stored in
 [`appStorage`](<doc:SharedReaderKey/appStorage(_:store:)-45ltk>) like so:

```swift
@Observable
class CounterModel {
  @ObservationIgnored
  @Shared(.appStorage("count")) var count = 0
  func incrementButtonTapped() {
    $count.withLock { $0 += 1 }
  }
}
```

Then a simple test can be written for this in the exact same way as if you were not using `@Shared`
at all:

```swift
@Test func increment() {
  let model = CounterModel()
  model.incrementButtonTapped()
  #expect(model.count == 1)
}
```

This test will pass deterministically, 100% of the time, even when run in parallel with other tests
and when run repeatedly. This is true even though technically `appStorage` interfaces with user
defaults behind the scenes, which is a global, mutable store of data.

However, during tests the `appStorage` strategy will provision a unique and temporary user defaults
for each test case. That allows each test to make any changes it wants to the user defaults without
affecting other tests.

The same holds true for the [`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>)
and [`inMemory`](<doc:SharedReaderKey/inMemory(_:)>) strategies. Even though those strategies do
interact with a global store of data, they do so in a way that is quarantined from other tests.

### Testing when using custom persistence strategies

When creating your own custom persistence strategies you must careful to do so in a style that
is amenable to testing. For example, the ``SharedReaderKey/appStorage(_:store:)-45ltk`` persistence
strategy that comes with the library uses a ``Dependencies/DependencyValues/defaultAppStorage``
dependency so that one can inject a custom `UserDefaults` in order to execute in a controlled
environment. When your app runs in the simulator or on device, 
``Dependencies/DependencyValues/defaultAppStorage`` uses the standard user defaults so that data
is persisted. But when your app runs in a testing or preview context, 
``Dependencies/DependencyValues/defaultAppStorage`` uses a unique and temporary user defaults so
that each run of the test or preview starts with an empty storage. 

Similarly the ``SharedReaderKey/fileStorage(_:decoder:encoder:)`` persistence strategy uses an
internal dependency for changing how files are written to the disk and loaded from disk. In tests
the dependency will forgo any interaction with the file system and instead write data to an
internal `[URL: Data]` dictionary, and load data from that dictionary. That emulates how the file
system works, but without persisting any data to the global file system, which can bleed over into
other tests.

### Overriding shared state in tests

When testing features that use `@Shared` with a persistence strategy you may want to set the initial
value of that state for the test. Typically this can be done by declaring the shared state at 
the beginning of the test so that its default value can be specified:

```swift
@Test
func basics() {
  @Shared(.appStorage("count")) var count = 42

  // Shared state will be 42 for all features using it.
  let model = FeatureModel()
  // ...
}
```

However, if your test suite is a part of an app target, then the entry point of the app will execute
and potentially cause an early access of `@Shared`, thus capturing a different default value than
what is specified above. This is a quirk of app test targets in Xcode, and can cause lots of subtle
problems.

The most robust workaround to this issue is to simply not execute your app's entry point when tests
are running. This makes it so that you are not accidentally executing network requests, tracking
analytics, _etc._, while running tests.

You can do this by checking if tests are running in your entry point using the global `isTesting`
value provided by the library:

```swift
@main
struct EntryPoint: App {
  var body: some Scene {
    if !isTesting {
      WindowGroup {
        // ...
      }
    }
  }
}
```

#### UI Testing

When UI testing your app you must take extra care so that shared state is not persisted across
app runs because that can cause one test to bleed over into another test, making it difficult to
write deterministic tests that always pass. To fix this, you can set an environment value from
your UI test target, such as `UI_TESTING`, and then if that value is present in the app target you
can override the ``Dependencies/DependencyValues/defaultAppStorage`` and
``Dependencies/DependencyValues/defaultFileStorage`` dependencies so that they use in-memory 
storage, _i.e._ they do not persist, ever:

```swift
@main
struct EntryPoint: App {
  init() {
    if ProcessInfo.processInfo.environment["UI_TESTING"] != nil {
      prepareDependencies {
        $0.defaultAppStorage = UserDefaults(
          suiteName:"\(NSTemporaryDirectory())\(UUID().uuidString)"
        )!
        $0.defaultFileStorage = .inMemory
      }
    }
  }
}
```

> Note: The function `prepareDependencies` is provided by our Dependencies library, and allows for
> a one-time overriding of any dependency at the moment your app launches.
