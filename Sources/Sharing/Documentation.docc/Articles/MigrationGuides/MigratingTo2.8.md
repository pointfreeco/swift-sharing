# Migrating to 2.8.0

Sharing 2.8 addresses a disruptive Swift 6.3 bugfix.

## Overview

### @Shared's unavailable setter

For a long time `@Shared` has had an explicitly unavailable setter to guide users to the correct
`withLock` API:

```swift
struct Settings {
  @Shared var isEnabled: Bool
}

settings.isEnabled = false
// Error: Setter for 'isEnabled' is unavailable: Use '$shared.withLock' to modify a shared value
// with exclusive access
```

Unfortunately, a soundness hole in Swift failed to check availability through certain code paths,
like dynamic member lookup. This meant that something as innocent as chaining a binding into shared
state built just fine:

```swift
@Binding var settings: Settings

Toggle("Enabled", isOn: $settings.isEnabled)
```

…when in reality this writer should not be available, as it opens up the possibility of data races
in your applications.

In Swift 6.3 this bug has been fixed, and the above is now a compile-time failure in Sharing 2.7 and
earlier. To mitigate this, Sharing 2.8 introduces a softer deprecation, instead:

```swift
Toggle("Enabled", isOn: $settings.isEnabled)
// Warning: Setter for 'isEnabled' is deprecated: Use '$shared.withLock' to modify a shared value
// with exclusive access; when constructing a SwiftUI binding, use 'Binding($shared)'
```

The workaround is to use the dedicated ``SwiftUICore/Binding/init(_:)`` API, instead:

```diff
-Toggle("Enabled", isOn: $settings.isEnabled)
+Toggle("Enabled", isOn: Binding(settings.$isEnabled))
```
