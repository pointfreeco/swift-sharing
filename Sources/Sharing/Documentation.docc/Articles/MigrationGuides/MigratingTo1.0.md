# Migrating to 1.0

In the official 1.0 release of Sharing we have removed some deprecated APIs and tweaked the
behavior of certain tools.

## Overview

### Mutating shared state

The most visible change to `@Shared` in its 1.0 release is the way in which the underlying value is
mutated.

Prior to version 1.0 of the library, it was possible to synchronously mutate `@Shared` values
directly. This API has been removed in order to minimize potential data races when shared state is
written to in parallel across multiple threads.

Instead, exclusively use the [`withLock`](<doc:Shared/withLock(_:fileID:filePath:line:column:)>)
method to mutate shared state with isolated access:

@Row {
  @Column {
    ```swift
    // Previously:
    @Shared var count: Int
    count += 1
    ```
  }
  @Column {
    ```swift
    // In 1.0:
    @Shared var count: Int
    $count.withLock { $0 += 1 }
    ```
  }
}

> Note:
>
> Prior to 1.0, the `withLock` method was isolated to the `@MainActor` and thus needed to be
`await`ed. In 1.0 this actor isolation has been removed and `withLock` can be synchronously called
from any thread.

For more information on this change, see <doc:MutatingSharedState>.

### App storage uses key-value observation

The ``AppStorageKey`` persistence strategy now uses key-value observation (KVO) instead of
notification center to observe external changes to user defaults when possible. KVO is more
efficient and supports cross-process observation, _e.g._ in widgets and other extensions, and does
not require a main thread hop to process updates.

> Important:
>
> It is not possible to use KVO when the user default key contains a period (`.`) or starts with an
at sign (`@`). These are reserved characters in KVO, and observation will fall back to the firehose
notification, instead. For example:
>
> ```swift
> @Shared(.appStorage("co.pointfree.haptics-enabled"))
> var isHapticsEnabled: Bool
> ```
>
> By default, the library will emit a warning when it encounters a KVO-incompatible key.
>
> To silence this warning, set the
> ``Dependencies/DependencyValues/appStorageKeyFormatWarningEnabled`` dependency to `false`, _e.g._
> at the entry point of your application:
>
> ```swift
> @main
> struct MyApp: App {
>   init() {
>     prepareDependencies { 
>       $0.appStorageKeyFormatWarningEnabled = false
>     }
>   }
>   // ...
> }
> ```

### File storage no longer saves on resignation/termination

Before 1.0, ``FileStorageKey`` subscribed to resignation and termination notifications in order to
eagerly flush any unwritten changes to disk.

In 1.0, these extra subscriptions have been eliminated in favor of simply waiting for the write to
happen on the existing debounce mechanism.

In practice this should not behave differently in applications running in the wild, but you may lose
a write to disk when terminating the simulator too quickly after a mutation, similar to the behavior
of user defaults, which can lose updates when terminated in a similar way.

### Shared publishers now immediately emit the current value

Before 1.0, a `$shared.publisher` subscription would wait for the shared value to be written to
before emitting a value, similar to a passthrough subject.

In 1.0, `$shared.publisher` behaves like a current value subject (as well as `@Published`
properties), and _immediately_ emits the current value when first subscribed to.

If you wish to skip this initial value, use Combine's `dropFirst` operator:

@Row {
  @Column {
    ```swift
    // Previously:
    $shared.publisher
    ```
  }
  @Column {
    ```swift
    // In 1.0, if you do not want
    // the current value emission:
    $shared.publisher
      .dropFirst()
    ```
  }
}

### Other renames

A number of APIs have been renamed for the 1.0 release with the old names deprecated with fix-its
where possible:

| 0.1                               | 1.0                             |
| --------------------------------- | ------------------------------- |
| `shared = …`                      | `$shared.withLock { … }`        |
| `PersistenceKey`                  | `SharedKey`                     |
| `PersistenceReaderKey`            | `SharedReaderKey`               |
| `PersistenceKeyDefault`           | `SharedKey.Default`             |
| `Shared(_:)`                      | `Shared(value:)`                |
| `try Shared(_:)`                  | `try Shared(require:)`          |
| `$shared.reader`                  | `SharedReader($shared)`         |
| `ForEach($shared.elements) { … }` | `ForEach(Array($shared)) { … }` |
