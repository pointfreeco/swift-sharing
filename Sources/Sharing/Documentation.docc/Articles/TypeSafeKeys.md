# Reusable, type-safe keys

Learn how to define keys for your shared state that allow you to reference your data in a statically
checked and type-safe manner.

## Overview

Due to the nature of persisting data to external systems, you lose some type safety when shuffling
data from your app to the persistence storage and back. For example, if you are using the
[`fileStorage`](<doc:SharedReaderKey/fileStorage(_:decoder:encoder:)>) strategy to save an array of
users to disk you might do so like this:

```swift
@Shared(
  .fileStorage(.documentsDirectory.appending(component: "users.json"))
)
var users: [User] = []
```

Not only is this a cumbersome line of code to write, but it is also not very safe. Say you have used
this file storage in multiple places throughout your application. But then, someday in the future 
you may decide to refactor this data to be an identified array instead of a plain array:

```swift
// Somewhere else in the application
@Shared(.fileStorage(/* ... */)) var users: IdentifiedArrayOf<User> = []
```

But if you forget to convert _all_ shared user arrays to the new identified array your application
will still compile, but it will be broken. The two types of storage will not share state.

To add some type-safety and reusability to this process you can extend the ``SharedKey`` protocol to
add a static variable for describing the details of your persistence:

```swift
extension SharedKey
where Self == FileStorageKey<IdentifiedArrayOf<User>> {
  static var users: Self {
    fileStorage(/* ... */)
  }
}
```

Then when using `@Shared` you can specify this key directly without `.fileStorage`:

```swift
@Shared(.users) var users: IdentifiedArrayOf<User> = []
```

And now that the type is baked into the key you cannot accidentally use the wrong type because you
will get an immediate compiler error:

```swift
@Shared(.users) var users: [User] = []
```

> 🛑 Error: Cannot convert value of type '[User]' to expected argument type
> 'IdentifiedArrayOf<User>'

This technique works for all types of persistence strategies. For example, a type-safe `.inMemory`
key can be constructed like so:

```swift
extension SharedReaderKey
where Self == InMemoryKey<IdentifiedArrayOf<User>> {
  static var users: Self {
    inMemory("users")
  }
}
```

And a type-safe `.appStorage` key can be constructed like so:

```swift
extension SharedReaderKey where Self == AppStorageKey<Int> {
  static var count: Self {
    appStorage("count")
  }
}
```

And this technique also works on custom persistence strategies that you may define in your own 
codebase.

Further, you can use the ``SharedReaderKey/Default`` type to pair a default value that with a
persistence strategy. For example, to use a default value of `[]` with the `.users` strategy
described above, we can do the following:

```swift
extension SharedReaderKey
where Self == FileStorageKey<IdentifiedArrayOf<User>>.Default {
  static var users: Self {
    Self[.fileStorage(URL(/* ... */)), default: []]
  }
}
```

And now any time you reference the shared users state you can leave off the default value, and
you can even leave off the type annotation:

```swift
@Shared(.users) var users
```
