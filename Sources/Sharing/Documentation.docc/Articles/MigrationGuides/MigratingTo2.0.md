# Migrating to 2.0

Sharing 2.0 introduces better support for error handling and concurrency.

## Overview

### Built-in persistence strategies

If you are using Sharing's built-in strategies, including `appStorage`, `fileStorage`, and
`inMemory`, Sharing 2.0 is for the most part a backwards-compatible update, with a few exceptions
related to new functionality.

This includes a few synchronous APIs that have introduced backwards-incompatible changes to support
Swift concurrency and error handling:

| 1.0                         | 2.0                               |
| --------------------------- | --------------------------------- |
| `$shared.load()`            | `try await $shared.load()`        |
| `$shared.save()`            | `try await $shared.save()`        |
| `try Shared(require: .key)` | `try await Shared(require: .key)` |

These APIs give you and your users greater insight into the status of loading or saving their data
to an external source.

For example, it is now possible to reload a shared value from a refreshable SwiftUI list using
simple constructs:

```swift
.refreshable {
  try? await $shared.load()
}
```

In addition to these actively throwing, asynchronous APIs, a number of passive properties have been
added to the `@Shared` and `@SharedReader` property wrappers that can be used to probe for
information regarding load and error states:

  * ``Shared/isLoading``: Whether or not the property is in the process of loading data from an
    external source.
  * ``Shared/loadError``: If present, an error that describes why the external source failed to
    load the associated data.
  * ``Shared/saveError``: If present, an error that describes why the external source failed to
    save the associated data.

These properties can be used to surface more precise state from `@Shared` values that was previously
impossible:

```swift
if $content.isLoading {
  ProgressView()
} else if let loadError = $content.loadError {
  ContentUnavailableView {
    Label("Failed to load content", systemImage: "xmark.circle")
  } description: {
    Text(loadError.localizedDescription)
  }
} else {
  MyView(content: content)
}
```

### Custom persistence strategies

The ``SharedReaderKey`` and ``SharedKey`` protocols have been updated to allow for error handling
and concurrency in their requirements: [`load`](<doc:SharedReaderKey/load(context:continuation:)>), 
[`subscribe`](<doc:SharedReaderKey/subscribe(context:subscriber:)>), and 
[`save`](<doc:SharedKey/save(_:context:continuation:)>):

##### Updates to loading

The `load` requirement of ``SharedReaderKey`` in 1.0 was as simple as this:

```swift
func load(initialValue: Value?) -> Value?
```

Its only job was to return an optional `Value` that represent loading the value from the external
storage system (_e.g._, user defaults, file system, _etc._). However, there were a few problems with
this signature:

 1. It does not allow for asynchronous or throwing work to load the data.
 2. The `initialValue` argument is not very descriptive and it wasn't clear what it represented.
 3. It wasn't clear why `load` returned an optional, nor was it clear what would happen if one 
    returned `nil`.

These problems are all fixed with the following updated signature for `load` in ``SharedReaderKey``:

```swift
func load(
  context: LoadContext<Value>,
  continuation: LoadContinuation<Value>
)
```

This fixes the above 3 problems in the following way:

 1. One can now load the value asynchronously, and when the value is finished loading it can be
    fed back into the shared state by invoking a `resume` method on ``LoadContinuation``. Further,
    there is a ``LoadContinuation/resume(throwing:)`` method for emitting a loading error.
 2. The `context` argument knows the manner in which this `load` method is being invoked, _i.e._ the
    value is being loaded implicitly by initializing the `@Shared` property wrapper, or the value is
    being loaded explicitly by invoking the ``SharedReader/load()`` method.
 3. The ``LoadContinuation`` makes explicit the various ways one can resume when the load is 
    complete. You can either invoke ``LoadContinuation/resume(returning:)`` if a value successfully 
    loaded, or invoke ``LoadContinuation/resume(throwing:)`` if an error occurred, or invoke 
    ``LoadContinuation/resumeReturningInitialValue()`` if no value was found in the external storage
    and you want to use the initial value provided to `@Shared` when it was created.

##### Updates to subscribing

The `subscribe` requirement of ``SharedReaderKey`` has undergone changes similar to `load`. In 1.0
the requirement was defined like so:

```swift
func subscribe(
  initialValue: Value?, 
  didSet receiveValue: @escaping @Sendable (Value?) -> Void
) -> SharedSubscription
```

This allows a conformance to subscribe to changes in the external storage system, and when a change
occurs it can replay that change back to `@Shared` state by invoking the `receiveValue` closure.

This method has many of the same problems as `load`, such as confusion of what `initialValue`
represents and what `nil` represents for the various optionals, as well as the inability to throw
errors when something goes wrong during the subscription.

These problems are all fixed with the new signature:

```swift
func subscribe(
  context: LoadContext<Value>, 
  subscriber: SharedSubscriber<Value>
) -> SharedSubscription
```

This new version of `subscribe` is handed the ``LoadContext`` that lets you know the context of the
subscription's creation, and the ``SharedSubscriber`` allows you to emit errors by invoking the
``SharedSubscriber/yield(throwing:)`` method.

##### Updates to saving

And finally, `save` also underwent some changes that are similar to `load` and `subscribe`. Its
prior form looked like this:

```swift
func save(_ value: Value, immediately: Bool)
```

This form has the problem that it does not support asynchrony or error throwing, and there was 
confusion of what `immediately` meant. That boolean was intended to communicate to the implementor
of this method that the value should be saved right away, and not be throttled.

The new form of this method fixes these problems:

```swift
func save(
  _ value: Value,
  context: SaveContext,
  continuation: SaveContinuation
)
```

The ``SaveContext`` lets you know if the `save` is being invoked merely because the value of the
`@Shared` state changed, or because of user initiation by explicitly invoking the ``Shared/save()``
method. It is the latter case that you may want to bypass any throttling logic and save the data
immediately.

And the ``SaveContinuation`` allows you to perform the saving logic asynchronously by resuming it
after the saving work has finished. You can either invoke ``SaveContinuation/resume()`` to indicate
that saving finished successfully, or ``SaveContinuation/resume(throwing:)`` to indicate that an
error occurred.
