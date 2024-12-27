# Gotchas of @Shared

Learn about a few gotchas to be aware of when using shared state in your application.

#### Hashability

Because the `@Shared` type is equatable based on its wrapped value, and because the value is held 
in a reference that can change over time, it cannot be hashable. This also means that types
containing `@Shared` properties should not compute their hashes from their shared values.

#### Codability

The `@Shared` type is not conditionally encodable or decodable because the source of truth of the 
wrapped value is rarely local: it might be derived from some other shared value, or it might rely on 
loading the value from a backing persistence strategy.

When introducing shared state to a data type that is encodable or decodable, you must explicitly
declare its non-shared coding keys in order to synthesize conformances:

```swift
struct TodosFeature {
  @Shared(.appStorage("launchCount")) var launchCount = 0
  var todos: [String] = []
}

extension TodosFeature: Codable {
  enum CodingKeys: String, CodingKey {
    // Omit 'launchCount'
    case todos
  }
}
```

Or you must provide your own implementations of `encode(to:)` and `init(from:)` that do the
appropriate thing.

For example, if the data type is sharing state with a persistence strategy, you can _decode_ by 
delegating to the memberwise initializer that implicitly loads the shared value from the property 
wrapper's persistence strategy, or you can explicitly initialize a shared value via
``Shared/init(wrappedValue:_:)-5xce4``. And you can _encode_ by skipping the shared value:

```swift
struct TodosFeature {
  @Shared(.appStorage("launchCount")) var launchCount = 0
  var todos: [String] = []
}

extension TodosFeature: Codable {
  enum CodingKeys: String, CodingKey {
    case todos
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Do not decode 'launchCount'
    self._launchCount = Shared(wrappedValue: 0, .appStorage("launchCount"))
    self.todos = try container.decode([String].self, forKey: .todos)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.todos, forKey: .todos)
    // Do not encode 'launchCount'
  }
}
```
