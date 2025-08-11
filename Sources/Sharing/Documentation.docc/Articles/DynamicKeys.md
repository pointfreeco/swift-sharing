# Dynamic Keys

Learn how to dynamically change the key that powers your shared state.

## Overview

Sharing uses the ``SharedKey`` protocol to express the functionality of loading, saving and 
subscribing to changes of an external storage system, such as user defaults, the file system
and more. Often one needs to dynamically update the key so that the shared state can load 
different data. A common example of this is using `@SharedReader` to load data from a SQLite
database, and needing to update the query with info specified by the user, such as a search string.

Learn about the techniques to do this below.

### Loading a new key

There are two ways to load a new key into `@Shared` and `@SharedReader`. If the change is due to
the user changing something, such as a search string, you can use ``Shared/load(_:)``:

```swift
.task(id: searchText) {
  do {
    try await $items.load(.search(searchText))
  } catch {
    // Handle error
  }
}
```

If the change is not due to user action, such as the first appearance of the view, then you can
re-assign the projected value of the shared state directly:

```swift
init() {
  $items = SharedReader(.search(searchText))
}
```

### SwiftUI views

There is one nuance to be aware of when using [`@Shared`](<doc:Shared>) and 
 [`@SharedReader`](<doc:SharedReader>) directly in a SwiftUI view. When the view is recreated 
(which can happen many times and is an intentional design of SwiftUI), the corresponding 
`@Shared` and `@SharedReader` wrappers can also be created.

If you dynamically change the key of the property wrapper in the view, for example like this:

```swift
$value.load(.newKey)
// or...
$value = Shared(.newKey)
```

…then this key may be reset when the view is recreated. In order to prevent this you can use the
version of `Shared` and `SharedReader` that works like `@State` in views:

```swift
@State.Shared(.key) var value
```

See ``SwiftUICore/State/Shared`` and ``SwiftUICore/State/SharedReader`` for more info.
