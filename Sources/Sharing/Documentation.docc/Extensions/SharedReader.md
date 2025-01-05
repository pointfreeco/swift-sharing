# ``Sharing/SharedReader``

## Overview

The `@Shared` property wrapper gives you access to a piece of shared state that is both readable 
and writable. That is by far the most common use case when it comes to shared state, but there are 
times when one wants to express access to shared state for which you are not allowed to write to it, 
or possibly it doesn't even make sense to write to it.

For those times there is the `@SharedReader` property wrapper. It represents a reference to some
piece of state shared with multiple parts of the application, but you are not allowed to write to 
it. For example, a feature that needs access to a user setting controlling the sound effects of the 
app can do so in a read-only manner:

```swift
struct FeatureView: View {
  @SharedReader(.appStorage("soundsOn")) var soundsOn = true

  var body: some View {
    Button("Tap") {
      if soundsOn {
        SoundEffects.shared.tap()
      }
    }
  }
}
```

This makes it clear that this view only needs access to the "soundsOn" on state, but does not need
to change it.

It is also possible to make custom persistence strategies that only have the notion of loading and
subscribing, but cannot write. To do this you will conform only to the ``SharedReaderKey`` protocol
instead of the full ``SharedKey`` protocol. 

For example, you could create a `.remoteConfig` strategy that loads (and subscribes to) a remote
configuration file held on your server so that it is kept automatically in sync:

```swift
@SharedReader(.remoteConfig) var remoteConfig
```

This will allow you to read data from the remove config:

```swift
if remoteConfig.isToggleEnabled {
  Toggle(/* ... */)
    .toggleStyle(
      remoteConfig.useToggleSwitch 
        ? .switch 
        : .automatic
    )
}
```

## Topics

### Creating a persisted reader

- ``init(wrappedValue:_:)-56tir``

### Creating a shared reader

- ``constant(_:)``
- ``init(projectedValue:)``

### Transforming a shared value

- ``subscript(dynamicMember:)-3jfdr``
- ``init(_:)-9wqv4``
- ``init(_:)-9ka0y``
- ``init(_:)-498ca``

### Reading the value

- ``wrappedValue``
- ``projectedValue``

### Loading the value

- ``load()``
- ``isLoading``
- ``init(require:)``

### Error handling

- ``loadError``

### SwiftUI integration

- ``Swift/RangeReplaceableCollection``

### Combine integration

- ``publisher``
