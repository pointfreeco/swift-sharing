# Sharing

Instantly share state among your app's features and external persistence layers, including user
defaults, the file system, and more.

[![CI](https://github.com/pointfreeco/swift-sharing/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-sharing/actions?query=workflow%3ACI)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-sharing%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-sharing)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-sharing%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-sharing)

  * [Learn more](#learn-more)
  * [Overview](#overview)
  * [Demos](#demos)
  * [Documentation](#documentation)
  * [Installation](#installation)
  * [Community](#community)
  * [License](#license)

## Learn more

This library was motivated and designed over the course of many episodes on
[Point-Free](https://www.pointfree.co), a video series exploring advanced programming topics in the
Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and [Stephen
Celis](https://twitter.com/stephencelis).

<a href="https://www.pointfree.co/collections/tours/tour-of-swift-sharing">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0305.jpeg" width="600">
</a>

## Overview

This library comes with a few tools that allow one to share state with multiple parts of your
application, as well as external systems such as user defaults, the file system, and more. The tool
works in a variety of contexts, such as SwiftUI views, `@Observable` models, and UIKit view
controllers, and it is completely unit testable.

As a simple example, you can have two different observable models hold onto a collection of data
that is also synchronized to the file system:

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

> [!NOTE]
> Due to the fact that Swift macros do not play nicely with property wrappers, you must annotate
> each `@Shared` held by an `@Observable` model with `@ObservationIgnored`. Views will still update
> when shared state changes since `@Shared` handles its own observation.

If either model makes a change to `meetings`, the other model will instantly see those changes.
And further, if the file on disk changes from an external write, both instances of `@Shared` will
also update to hold the freshest data.

### Automatic persistence

The [`@Shared`][shared-article] property wrapper gives you a succinct and consistent way to persist
any kind of data in your application. The library comes with 3 strategies:
[`appStorage`][app-storage-key-docs],
[`fileStorage`][file-storage-key-docs], and
[`inMemory`][in-memory-key-docs].

[shared-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/shared
[app-storage-key-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/appstoragekey
[file-storage-key-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/filestoragekey
[in-memory-key-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/inmemorykey

The [`appStorage`][app-storage-key-docs] strategy is useful for store small pieces of simple data
in user defaults, such as settings:

```swift
@Shared(.appStorage("soundsOn")) var soundsOn = true
@Shared(.appStorage("hapticsOn")) var hapticsOn = true
@Shared(.appStorage("userSort")) var userSort = UserSort.name
```

The [`fileStorage`][file-storage-key-docs] strategy is useful for persisting more complex data
types to the file system by serializing the data to bytes:

```swift
@Shared(.fileStorage(.meetingsURL)) var meetings: [Meeting] = []
```

And the [`inMemory`][in-memory-key-docs] strategy is useful for sharing any kind of data globally
with the entire app, but it will be reset the next time the app is relaunched:

```swift
@Shared(.inMemory("events")) var events: [String] = []
```

See ["Persistence strategies"][persistence-docs] for more information on leveraging the persistence
strategies that come with the library, as well as creating your own strategies.

[persistence-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/persistencestrategies

### Use anywhere

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
``Shared/publisher`` property or the `observe` tool from our [Swift Navigation][swift-navigation]
library. See  ["Observing changes"][observation-docs] for more information.

[swift-navigation]: http://github.com/pointfreeco/swift-navigation
[observation-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/observingchanges

### Testing shared state

Features using the `@Shared` property wrapper remain testable even though they interact with outside
storage systems, such as user defaults and the file system. This is possible because each test gets
a fresh storage system that is quarantined to only that test, and so any changes made to it will
only be seen by that test.

See ["Testing"][testing-docs] for more information on how to test your features when using `@Shared`.

[testing-docs]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/testing

## Documentation

The documentation for releases and `main` are available here:

* [`main`](https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/)
* [2.0.2](https://swiftpackageindex.com/pointfreeco/swift-sharing/2.0.2/documentation/sharing/)
* [1.1.1](https://swiftpackageindex.com/pointfreeco/swift-sharing/1.1.1/documentation/sharing/)

### Articles

- [Shared][Shared-article]
- [Persistence strategies][PersistenceStrategies-article]
- [Mutating shared state][MutatingSharedState-article]
- [Observing changes to shared state][ObservingChanges-article]
- [Deriving shared state][DerivingSharedState-article]
- [Reusable, type-safe keys][TypeSafeKeys-article]
- [Initialization rules][InitializationRules-article]
- [Testing][Testing-article]
- [Gotchas][Gotchas-article]

[Shared-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/shared
[PersistenceStrategies-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/persistencestrategies
[MutatingSharedState-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/mutatingsharedstate
[ObservingChanges-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/observingchanges
[DerivingSharedState-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/derivingsharedstate
[TypeSafeKeys-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/typesafekeys
[InitializationRules-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/initializationrules
[Testing-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/testing
[Gotchas-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/gotchas

## Demos

This repo comes with _lots_ of examples to demonstrate how to solve common and complex problems with
Sharing. Check out [this](./Examples) directory to see them all, including:

  * [Case Studies](./Examples/CaseStudies):
    A number of case studies demonstrating the built-in features of the library.

  * [API Client](./Examples/APIClientDemo):
    A demo showing how shared state can be powered by an API client.

  * [FirebaseDemo](./Examples/FirebaseDemo):
    A demo showing how shared state can be powered by a remote [Firebase][firebase] config.

  * [GRDBDemo](./Examples/GRDBDemo):
    A demo showing how shared state can be powered by SQLite in much the same way a view can be
    powered by SwiftData's `@Query` property wrapper using [GRDB][grdb].

  * [WasmDemo](./Examples/WasmDemo):
    A [SwiftWasm][swiftwasm] application that uses this library to share state with your web
    browser's local storage.

  * [SyncUps][syncups]: We also rebuilt Apple's [Scrumdinger][scrumdinger] demo application using
    modern, best practices for SwiftUI development, including using this library to share state and
    persist it to the file system.

[firebase]: https://firebase.google.com
[grdb]: https://github.com/groue/GRDB.swift
[swiftwasm]: https://swiftwasm.org
[scrumdinger]: https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
[syncups]: https://github.com/pointfreeco/syncups

## Installation

You can add Sharing to an Xcode project by adding it to your project as a package.

> https://github.com/pointfreeco/swift-sharing

If you want to use Sharing in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.0.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "Sharing", package: "swift-sharing"),
```

## Community

If you want to discuss this library or have a question about how to use it to solve a particular
problem, there are a number of places you can discuss with fellow
[Point-Free](http://www.pointfree.co) enthusiasts:

  * For long-form discussions, we recommend the
    [discussions](http://github.com/pointfreeco/swift-sharing/discussions) tab of this repo.

  * For casual chat, we recommend the
    [Point-Free Community Slack](http://www.pointfree.co/slack-invite).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
