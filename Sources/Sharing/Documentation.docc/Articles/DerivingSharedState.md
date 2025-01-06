# Deriving shared state

Learn how to derive shared state to sub-parts of a larger piece of shared state.

## Overview

It is possible to derive shared state for sub-parts of an existing piece of shared state. For 
example, suppose you have a multi-step signup flow that uses `Shared<SignUpData>` in order to share
data between each screen. However, some screens may not need all of `SignUpData`, but instead just a
small part. The phone number confirmation screen may only need access to `signUpData.phoneNumber`,
and so that feature can hold onto just `Shared<String>` to express this fact:

```swift
@Observable
class PhoneNumberModel { 
  @ObservationIgnored
  @Shared var phoneNumber: String
  // ...
}
```

Then, when the parent feature constructs the `PhoneNumberModel` it can derive a small piece of
shared state from `Shared<SignUpData>` to pass along:

```swift
func nextButtonTapped() {
  path.append(
    PhoneNumberModel(phoneNumber: $signUpData.phoneNumber)
  )
}
```

Here we are using the ``Shared/projectedValue`` value using `$` syntax, `$signUpData`, and then
we further dot-chain onto that projection to derive a `Shared<String>`. This can be a powerful way
for features to hold onto only the bare minimum of shared state it needs to do its job.

It can be instructive to think of `@Shared` as an analogue of SwiftUI's `@Binding` that can be used
anywhere. You use it to express that the actual "source of truth" of the value lies elsewhere, but
you want to be able to read its most current value and write to it.

This also works for persistence strategies. If a parent feature holds onto a `@Shared` piece of 
state with a persistence strategy:

```swift
@Observable
class ParentModel {
  @ObservationIgnored
  @Shared(.fileStorage(.currentUser)) var currentUser
  // ...
}
```

…and a child feature wants access to just a shared _piece_ of `currentUser`, such as their name, 
then they can do so by holding onto a simple, unadorned `@Shared`:

```swift
@Observable
class EditNameModel {
  @ObservationIgnored
  @Shared var currentUserName: String
  // ...
}
```

And then the parent can pass along `$currentUser.name` to the child feature when constructing its
state:

```swift
func editNameButtonTapped() {
  destination = .editName(
    EditNameModel(currentUserName: $currentUser.name)
  )
}
```

Any changes the child feature makes to its shared `name` will be automatically made to the parent's
shared `currentUser`, and further those changes will be automatically persisted thanks to the
`.fileStorage` persistence strategy used. This means the child feature gets to describe that it
needs access to shared state without describing the persistence strategy, and the parent can be
responsible for persisting and deriving shared state to pass to the child.

### Optional shared state

If your shared state is optional, it is possible to unwrap it as a non-optional shared value via
``Shared/init(_:)-2z7om``.

```swift
@Shared var currentUser: User?

if let loggedInUser = Shared($currentUser) {
  loggedInUser  // Shared<User>
}
```

### Collections of shared state

If your shared state is a collection, in particular an `IdentifiedArray`, then we have another tool
for deriving shared state to a particular element of the array. You can pass the shared collection
to a ``Swift/RangeReplaceableCollection``'s ``Swift/RangeReplaceableCollection/init(_:)-53j6s`` to
create a collection of shared elements:

```swift
@Shared(.fileStorage(.todos)) var todos: IdentifiedArrayOf<Todo> = []

ForEach(Array($todos)) { $todo in  // '$todo' is a 'Shared<Todo>'
  // ...
}
```

You can also subscript into a ``Shared`` collection with the `IdentifiedArray[id:]` subscript. This
will give a piece of shared optional state, which you can then unwrap with the
``Shared/init(_:)-2z7om`` initializer:

```swift
@Shared(.fileStorage(.todos)) var todos: IdentifiedArrayOf<Todo> = []

guard let todo = Shared($todos[id: todoID])
else { return }
todo  // Shared<Todo>
```

### Read-only shared state

Any `@Shared` value can be made read-only via ``SharedReader/init(_:)-9wqv4``:

```swift
// Parent feature needs read-write access to the option
@Shared(.appStorage("isHapticsEnabled")) var isHapticsEnabled = true

// Child feature only needs to observe changes to the option
Child(isHapticsEnabled: SharedReader($isHapticsEnabled))
```
