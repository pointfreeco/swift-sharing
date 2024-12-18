# Mutating shared state

Learn how to mutate shared state in a safe manner in order to prevent race conditions and data loss.

## Overview

Shared state cannot be mutated directly and freely. One must go through the
``Shared/withLock(_:fileID:filePath:line:column:)`` method in order to synchronize access and
mutation to the underlying shared storage for a lexical scope. It may seem like an unfriendly API,
but it is necessary to ensure that there are not race conditions when mutating shared state from
multiple threads. To understand this in-depth, please continue reading.

### Race conditions in SwiftUI's state management tools

It may come as a surprise to you, but it is possible to mutate SwiftUI state from multiple threads
and cause race conditions in the form of data loss. This affects `@AppStorage`, `@State`, and
`@Binding`. To see this, consider the following SwiftUI view that runs 1,000 tasks in a task group, 
each of which increment an `@AppStorage` integer by 1:

```swift
import SwiftUI

struct AppStorageRaceCondition: View {
  @AppStorage("count") var count = 0
  var body: some View {
    Form {
      Text("\(count)")
      Button("Race!") {
        Task {
          await withTaskGroup(of: Void.self) { group in
            for _ in 1...1_000 {
              group.addTask { _count.wrappedValue += 1 }
            }
          }
        }
      }
    }
  }
}

#Preview("AppStorage race condition") {
  AppStorageRaceCondition()
}
```

If you run the preview for this view and tap the "Race!" button, you will find that the count
increments by far less than 1,000. This means this code has a race condition:

@Video(source: race.mov)

You will also get the same result if you replace `@AppStorage` with `@State` or `@Binding`.

However, this is perfectly legitimate Swift code that compiles without warnings or errors in Swift 6
mode and with the strictest of concurrency settings. The `_count` variable is of type 
`AppStorage<Int>`, which is `Sendable`, and hence is fine to transport into the task group's tasks.
And further, `wrappedValue` is a `nonmutating set` property, and so it is completely fine to mutate
it from an escaping closure.

While this demonstrates that `@AppStorage` is clearly susceptible to race conditions, it is at least
safe from data corruption. The `@AppStorage` property wrapper uses a lock under the hood in order
to synchronize access to its `wrappedValue`. The problem is that synchronization at that level does
not protect against data loss in code like this:

```swift
_count.wrappedValue += 1
```

That single line of code corresponds to multiple individual instructions:

1. Get the `wrappedValue`
2. Add 1 to the `wrappedValue`
3. Set the `wrappedValue`

The first and last of these steps are locked, but that still leaves open the possibility of
multiple threads interleaving and causing one thread to write an old value to `wrappedValue`.

In order to prevent this race condition one must provide the synchronization themselves by mutating 
the `count` on the main actor:

```swift
await withTaskGroup(of: Void.self) { group in
  for _ in 1...1_000 {
    group.addTask { 
      await MainActor.run { 
        count += 1 
      }
    }
  }
}
```

Again, Swift's concurrency checking is not able to detect this problem for us. It is on us to
know that we are responsible for providing synchronization when mutating `@AppStorage`.

Although it may seem problematic that `@AppStorage` has potential race conditions lurking in 
the shadows, it isn't usually a problem (famous last words 🤣). The `@AppStorage` property wrapper 
only works when installed in a SwiftUI view, which is `@MainActor`-bound, and so the vast majority 
of interactions with `@AppStorage` are serialized to the main actor, and hence there are no 
synchronization issues.

### Potential race conditions in @Shared

Now that we understand how technically `@AppStorage` is susceptible to race conditions, but that it
usually isn't a problem since most interactions with it are bound to the `@MainActor`, we can now
understand why `@Shared` was designed the way it was. Unlike the `@AppStorage` property wrapper,
`@Shared` is not relegated to only SwiftUI views. It can be used in `@Observable` models, UIKit
view controllers, actors, and basically _anywhere_. And so it does not have the benefit of being
primarily `@MainActor` bound.

If the `@Shared` property wrapper allowed direct mutations to its underlying `wrappedValue`, it
would be possible to write very reasonable looking code that was secretly hiding a race condition
that could cause data loss. While we think the potential for race conditions is incredibly small, we
think it is still certain, and so if we allowed direct mutation, you would very likely ship serious
bugs in your application without you ever knowing.

So this is why we require ``Shared/withLock(_:fileID:filePath:line:column:)`` for mutating shared
values. And when compared to what one needs to do with `@AppStorage` to ensure safety, it isn't
really that different:

```diff
 await withTaskGroup(of: Void.self) { group in
   for _ in 1...1_000 {
     group.addTask { 
-      await MainActor.run { 
-        count += 1 
+      $count.withLock { 
+        $0 += 1 
       }
     }
   }
 }
```

At the end of the day, we feel that it is a fair compromise to require
``Shared/withLock(_:fileID:filePath:line:column:)`` to mutate shared values. The benefits of
`@Shared` far outweighs this one single con. You get to use `@Shared`
[_anywhere_](<doc:Shared#Use-anywhere>) throughout your entire application, including UIKit and even
on non-Apple platforms. _And_ it works with more
[persistence strategies](<doc:PersistenceStrategies>) than just user defaults. _And_ it is
well-behaved in previews and [tests](<doc:Testing>), making it possible to write unit tests against
data that is typically difficult or impossible to test. And the list goes on…
