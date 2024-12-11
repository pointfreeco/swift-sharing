# Persistence strategies

Learn about the various persistence strategies that ship with the library, as well as how to create
your own custom strategies.

## Overview

When using `@Shared` you can supply an optional persistence strategy to represent that the state
you are holding onto is being shared with an external system. The library ships with 3 kinds of
strategies: [`appStorage`](<doc:SharedReaderKey/appStorage(_:store:)-45ltk>),
[`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>), and
[`inMemory`](<doc:SharedReaderKey/inMemory(_:)>). These strategies are defined as conformances to
the ``SharedKey`` protocol, and it is possible for you to provide your own conformances for sharing
state with other systems, such as remote servers, SQLite, or really anything!

### In-memory

This is the simplest persistence strategy in that it doesn't actually persist at all. It keeps
the data in memory and makes it available globally to every part of the application, but when the
app is relaunched the data will be reset back to its default.

It can be used by passing ``SharedReaderKey/inMemory(_:)`` to the `@Shared` property wrapper.
For example, suppose you want to share an integer count value with the entire application so that
any feature can read from and write to the integer. This can be done like so:

```swift
@Obsrevable
class FeatureModel {
  @ObservationIgnored
  @Shared(.inMemory("count")) var count = 0
  // ...
}
```

> Note: When using a persistence strategy with `@Shared` you must provide a default value, which is
> used for the first access of the shared state.

Now any part of the application can read from and write to this state, and features will never get
out of sync.

### User defaults

If you would like to persist your shared value across application launches, then you can use the
``SharedReaderKey/appStorage(_:store:)-45ltk`` strategy with `@Shared` in order to automatically
persist any changes to the value to user defaults. It works similarly to in-memory sharing discussed
above. It requires a key to store the value in user defaults, as well as a default value that will
be used when there is no value in the user defaults:

```swift
@Shared(.appStorage("count")) var count = 0
```

That small change will guarantee that all changes to `count` are persisted and will be 
automatically loaded the next time the application launches.

This form of persistence only works for simple data types because that is what works best with
`UserDefaults`. This includes strings, booleans, integers, doubles, URLs, data, and more. If you
need to store more complex data, such as custom data types serialized to bytes, then you will want
to use the [`.fileStorage`](<doc:PersistenceStrategies#File-system>) strategy or a
[custom persistence](<doc:PersistenceStrategies#Custom-persistence>) strategy.

### File system

If you would like to persist your shared value across application launches, and your value is
complex (such as a custom data type), then you can use the
``SharedReaderKey/fileStorage(_:decoder:encoder:)`` strategy with `@Shared`. It automatically
persists any changes to the file system.

It works similarly to the in-memory sharing discussed above, but it requires a URL to store the data
on disk, as well as a default value that will be used when there is no data in the file system:

```swift
@Shared(.fileStorage(/* URL */) var users: [User] = []
```

This strategy works by serializing your value to JSON to save to disk, and then deserializing JSON
when loading from disk. For this reason the value held in `@Shared(.fileStorage(…))` must conform to
`Codable`.

#### Custom persistence

It is possible to define all new persistence strategies for the times that user defaults or JSON
files are not sufficient. To do so, define a type that conforms to the ``SharedKey`` protocol:

```swift
public final class CustomSharedKey: SharedKey {
  // ...
}
```

> Note: Often `SharedKey` conformances will be classes because it will need to manage internal
> state, but that is not always the case. For example, ``FileStorageKey`` is a class, but 
> ``AppStorageKey`` and ``InMemoryKey`` are structs.

In order to conform to ``Shared`` you will need to provide 4 main requirements:

  * A `load(initialValue:)` method for synchronously loading a value from the external storage.
  * A `save(_:immediately:)` method for synchronously saving a value to the external storage.
  * A `subscribe(initialValue:didSet:)` method for subscribing to changes in the external storage
    in order to play back to the `@Shared` value.
  * And finally, an `id` that uniquely identifies the state held in the external storage system.

Once that is done it is customary to also define a static function helper on the ``SharedKey`` 
protocol for providing a simple API to use your new persistence strategy with `@Shared`:

```swift
extension SharedKey {
  public static func custom<Value>(/* ... */) -> Self
  where Self == CustomSharedKey<Value> {
    CustomSharedKey(/* ... */)
  }
}
```

With those steps done you can make use of the strategy in the same way one does for 
`appStorage` and `fileStorage`:

```swift
@Shared(.custom(/* ... */)) var myValue: Value
```

The ``SharedKey`` protocol represents loading from _and_ saving to some external storage, such as
the file system or user defaults. Sometimes saving is not a valid operation for the external system,
such as if your server holds onto a remote configuration file that your app uses to customize its
appearance or behavior, but the client cannot write to directly. In those situations you can conform
to the ``SharedReaderKey`` protocol, instead.
