# Initialization rules

Learn the various ways to initialize shared state, both when using a persistence strategy and
when not.

## Overview

Because Sharing utilizes property wrappers there are special rules that must be followed when
writing custom initializers for your types. These rules apply to _any_ kind of property wrapper,
including those that ship with vanilla SwiftUI (e.g. `@State`, `@StateObject`, _etc._), but the
rules can be quite confusing and so below we describe the various ways to initialize shared state.

It is common to need to provide a custom initializer to your feature's types, especially when
working with classes or when modularizing. This can become complicated when your types hold onto
[`@Shared`](<doc:Shared>) properties. Depending on your exact situation you can do one of the
following:

* [Persisted @Shared state](#Persisted-Shared-state)
* [Non-persisted @Shared state owned by feature](#Non-persisted-Shared-state-owned-by-feature)
* [Non-persisted @Shared state owned by other feature](#Non-persisted-Shared-state-owned-by-other-feature)

### Persisted @Shared state

If you are using a persistence strategy with shared state (_e.g._ 
[`appStorage`](<doc:SharedReaderKey/appStorage(_:store:)-45ltk>), [`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>),
_etc._), then the initializer should take a plain, non-`Shared` value and you will construct
the `Shared` value in the initializer using ``Shared/init(wrappedValue:_:)-5xce4`` which takes a
``SharedKey`` as the second argument:

```swift
class FeatureModel {
  // A piece of shared state that is persisted to an external system.
  @Shared public var count: Int
  // Other fields...

  public init(count: Int, /* Other fields... */) {
    _count = Shared(wrappedValue: count, .appStorage("count"))
    // Other assignments...
  }
}
```

Note that the declaration of `count` as a property of the class can use `@Shared` without an 
argument because the persistence strategy is specified in the initializer.

> Important: The value passed to this initializer is only used if the external storage does not
> already have a value. If a value exists in the storage then it is not used. In fact, the
> `wrappedValue` argument of ``Shared/init(wrappedValue:_:)-5xce4`` is an `@autoclosure` so that it
> is not even evaluated if not used. For that reason you may prefer to make the argument to the
> initializer an `@autoclosure`, as well, so that it too is evaluated only if actually used:
> 
> ```swift
> public struct State {
>   @Shared public var count: Int
>   // Other fields...
> 
>   public init(count: @autoclosure () -> Int, /* Other fields... */) {
>     _count = Shared(wrappedValue: count(), .appStorage("count"))
>     // Other assignments...
>   }
> }
> ```

### Non-persisted @Shared state owned by feature

If you are using non-persisted shared state (_i.e._ no shared key argument is passed to `@Shared`),
and the "source of truth" of the state lives within the feature you are initializing, then the
initializer should take a plain, non-`Shared` value and you will construct the `Shared` value
directly in the initializer:

```swift
class FeatureModel {
  // A piece of shared state that this feature will own.
  @Shared public var count: Int
  // Other fields...

  public init(count: Int, /* Other fields... */) {
    _count = Shared(value: count)
    // Other assignments...
  }
}
```

By constructing a `Shared` value directly in the initializer we can guarantee that this feature
owns the state.

### Non-persisted @Shared state owned by other feature

If you are using non-persisted shared state (_i.e._ no shared key argument is passed to `@Shared`),
and the "source of truth" of the state lives in a parent feature, then the initializer should take a
`@Shared` value that you will assign directly through the underscored property:

```swift
class FeatureModel {
  // A piece of shared state that will be provided by whoever constructs this model.
  @Shared public var count: Int
  // Other fields...

  public init(count: Shared<Int>, /* Other fields... */) {
    _count = count
    // Other assignments...
  }
}
```

This will make it so that `FeatureModel`'s `count` stays in sync with whatever parent feature
holds onto the shared state.
