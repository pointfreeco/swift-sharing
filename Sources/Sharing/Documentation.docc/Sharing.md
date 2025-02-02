# ``Sharing``

Instantly share state among your app's features and external persistence layers, including user 
defaults, the file system, and more.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-sharing)
- [Discussions](https://github.com/pointfreeco/swift-sharing/discussions)
@Comment {
- [Point-Free Videos](https://www.pointfree.co/collections/persistence)
}

## Overview

This library comes with a few tools that allow one to share state with multiple parts of your 
application, as well as external store systems such as user defaults, the file system, and more.
The tool works in a variety of contexts, such as SwiftUI views, `@Observable` models, and UIKit
view controllers, and it is completely unit testable.

As a simple example, you can have two different obsevable models hold onto a collection of 
data that is also synchronized to the file system:

```swift
// MeetingsList.swift
@Observable
class MeetingsListModel {
  @ObservationIgnored
  @Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
}

// ArchivedMeetings.swift
@Observable
class ArchivedMeetingsModel {
  @ObservationIgnored
  @Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
}
```

> Note: Due to the fact that Swift macros do not play nicely with property wrappers, you must 
annotate each `@Shared` with `@ObservationIgnored`. Views will still update when shared state 
changes since `@Shared` handles its own observation.

If either model makes a change to `meetings`, the other model will instantly see those changes.
And further, if the file on disk changes from an external write, both instances of `@Shared` will
also update to hold the freshest data.

## Automatic persistence

The [`@Shared`](<doc:Shared>) property wrapper gives you a succinct and consistent way to persist 
any kind of data in your application. The library comes with 3 strategies:
[`appStorage`](<doc:SharedReaderKey/appStorage(_:store:)-45ltk>),
[`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>), and
[`inMemory`](<doc:SharedReaderKey/inMemory(_:)>). 

The [`appStorage`](<doc:SharedReaderKey/appStorage(_:store:)-45ltk>) strategy is useful for store small
pieces of simple data in user defaults, such as settings:

```swift
@Shared(.appStorage("soundsOn")) var soundsOn = true
@Shared(.appStorage("hapticsOn")) var hapticsOn = true
@Shared(.appStorage("userSort")) var userSort = UserSort.name
```

The [`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>) strategy is useful
for persisting more complex data types to the file system by serializing the data to bytes:

```swift
@Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
```

And the [`inMemory`](<doc:SharedReaderKey/inMemory(_:)>) strategy is useful for sharing any kind
of data globably with the entire app, but it will be reset the next time the app is relaunched:

```swift
@Shared(.inMemory("events")) var events: [String] = []
```

See <doc:PersistenceStrategies> for more information on leveraging the persistence strategies that
come with the library, as well as creating your own strategies.

## Use anywhere

It is possible to use `@Shared` state essentially anywhere, including observable models, SwiftUI
views, UIKit view controllers, and more. For example, if you have a simple view that needs access
to some shared state but does not need the full power of an observable model, then you can use
`@Shared` directly in the view:

```swift
struct DebugMeetingsView: View {
  @Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
  var body: some View {
    ForEach(meetings) { meeting in
      Text(meeting.title)
    }
  }
}
```

Similarly, if you need to use UIKit for a particular feature or have a legacy feature that can't use
SwiftUI yet, then you can use `@Shared` directly in a view controller:

```swift
final class DebugMeetingsViewController: UIViewController {
  @Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
  // ...
}
```

And to observe changes to `meetings` so that you can update the UI you can either use the 
``Shared/publisher`` property or the `observe` tool from our Swift Navigation library. See 
<doc:ObservingChanges> for more information.

## Testing shared state

Features using the `@Shared` property wrapper remain testable even though they interact with outside
storage systems, such as user defaults and the file system. This is possible because each test
gets a fresh storage system that is quarantined to only that test, and so any changes made to it
will only be seen by that test.

See <doc:Testing> for more information on how to test your features when using `@Shared`.

## Demos

The [Sharing][sharing-gh] repo comes with _lots_ of examples to demonstrate how to solve common and
complex problems with `@Shared`. Check out [this][examples-dir] directory to see them all,
 including:

  * [Case Studies][case-studies-dir]:
    A number of case studies demonstrating the built-in features of the library.

  * [FirebaseDemo][firebase-dir]:
    A demo showing how shared state can be powered by a remote [Firebase][firebase] config.
    
  * [GRDBDemo][grdb-dir]:
    A demo showing how shared state can be powered by SQLite in much the same way a view can be
    powered by SwiftData's `@Query` property wrapper using [GRDB][grdb]..
  
  * [WasmDemo][wasm-dir]:
    A [SwiftWasm][swiftwasm] application that uses this library to share state with your web
    browser's local storage.

  * [SyncUps][syncups]: We also rebuilt Apple's [Scrumdinger][scrumdinger] demo application using 
    modern, best practices for SwiftUI development, including using this library to share state and 
    persist it to the file system.

[sharing-gh]: https://github.com/pointfreeco/swift-sharing
[examples-dir]: https://github.com/pointfreeco/swift-sharing/tree/main/Examples
[case-studies-dir]: https://github.com/pointfreeco/swift-sharing/tree/main/Examples/CaseStudies
[firebase-dir]: https://github.com/pointfreeco/swift-sharing/tree/main/Examples/FirebaseDemo
[firebase]: https://firebase.google.com
[grdb-dir]: https://github.com/pointfreeco/swift-sharing/tree/main/GRDBDemo
[grdb]: https://github.com/groue/GRDB.swift
[wasm-dir]: https://github.com/pointfreeco/swift-sharing/tree/main/Examples/WasmDemo
[swiftwasm]: https://swiftwasm.org
[scrumdinger]: https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
[syncups]: https://github.com/pointfreeco/syncups

## Topics

### Essentials

- ``Shared``
- ``SharedReader``
- <doc:PersistenceStrategies>
- <doc:MutatingSharedState>
- <doc:ObservingChanges>
- <doc:DerivingSharedState>
- <doc:TypeSafeKeys>
- <doc:InitializationRules>
- <doc:Testing>
- <doc:Gotchas>

### Persistence

- ``AppStorageKey``
- ``FileStorageKey``
- ``InMemoryKey``
- ``SharedReaderKey/Default``

### Custom persistence

- ``SharedKey``
- ``SharedReaderKey``

### Migration guides

- <doc:MigrationGuides>
