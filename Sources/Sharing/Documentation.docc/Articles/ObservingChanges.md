# Observing changes to shared state

Learn how to observe changes to shared state in order to update your UI or react to changes.

## Overview

Typically one does not have to worry about observing changes to shared state because it often
happens automatically for you. However, there are certain situations you should be aware of.

## SwiftUI

In SwiftUI observation is handled for you automatically. You can simply access shared state directly
in a view, and that will cause the view to subscribe to changes to that state. This is true
if you hold onto the shared state directly in the view:

```swift
struct CounterView: View {
  @Shared(.appStorage("count")) var count = 0
  var body: some View {
    Form {
      Text("\(count)")
      Button("Increment") { count += 1 }
    } 
  }
}
```

…or if you hold onto shared state in observable model:

```swift
@Observable class CounterModel {
  @ObservationIgnored 
  @Shared(.appStorage("count")) var count = 0
}
struct CounterView: View {
  @State var model = CounterModel()
  var body: some View {
    Form {
      Text("\(model.count)")
      Button("Increment") { model.count += 1 }
    } 
  }
}
```

In each of these cases the view will automatically re-compute its body when the shared state 
changes.

> Important: 
> There is one nuance to be aware of when using [`@Shared`](<doc:Shared>) and 
> [`@SharedReader`](<doc:SharedReader>) directly in a SwiftUI view. When the view is recreated 
> (which can happen many times and is an intentional design of SwiftUI), the corresponding 
> `@Shared` and `@SharedReader` wrappers can also be created.
> 
> If you dynamically change the key of the property wrapper in the view, for example like this:
> 
> ```swift
> $value.load(.newKey)
> // or…
> $value = Shared(.newKey)
> ```
> 
> …then this key may be reset when the view is recreated. In order to prevent this you can use the
> version of `Shared` and `SharedReader` that works like `@State` in views:
> 
> ```swift
> @State.Shared(.key) var value
> ```
> 
> See ``SwiftUICore/State/Shared`` and ``SwiftUICore/State/SharedReader`` for more info.

## Publisher of values

It is possible to get a Combine publisher of changes in a piece of shared state. Every `Shared` 
value has a ``Shared/publisher`` property, which emits the value every time the shared state
changes:

```swift
class Model {
  @Shared(.appStorage("count")) var count = 0

  var cancellables: Set<AnyCancellable> = []
  func startObservation() {
    $count.publisher.sink { count in
      print("count is now", count)
    }
    .store(in: &cancellables)
  }
}
```

> Important: You must be careful to not further mutate the shared state from within `sink`,
> otherwise you run the risk of an infinite loop.

## UIKit

UIKit does not get the same affordances as SwiftUI, but it is still possible to observe changes to
shared state in order to update the UI. You can use the ``Shared/publisher`` property described
above to listen for changes in `viewDidLoad` of you controller, and update your UI:

```swift
final class CounterViewController: UIViewController {
  @Shared(.appStorage("count")) var count = 0
  var cancellables: Set<AnyCancellable> = []

  func viewDidLoad() {
    super.viewDidLoad()

    let counterLabel = UILabel()
    // Set up constraints and add label to screen...

    $count.publisher.sink { count in
      counterLabel.text = "\(count)"
    }
    .store(in: &cancellables)
  }
}
```

If you are willing to further depend on our 
[Swift Navigation library](https://github.com/pointfreeco/swift-navigation), then you can make
use of its `observe(_:)` method to simplify this quite a bit:

```swift
final class CounterViewController: UIViewController {
  @Shared(.appStorage("count")) var count = 0

  func viewDidLoad() {
    super.viewDidLoad()

    let counterLabel = UILabel()
    // Set up constraints and add label to screen...

    observe { [weak self] in 
      guard let self else { return }

      counterLabel.text = "\(count)"
    }
  }
}
```

Any state accessed in the trailing closure of `observe` will be automatically observed, causing
the closure to be evaluated when the state changes.
