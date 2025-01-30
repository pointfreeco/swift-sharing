# ``Sharing/FileStorageKey``

A ``SharedKey`` conformance that persists complex pieces of data to the file system. It works with 
any kind of type that can be serialized to bytes, including all `Codable` types. It can be used
with ``Shared`` by providing the ``SharedReaderKey/fileStorage(_:decoder:encoder:)`` value and
specifying a default:

```swift
extension URL {
  static let users = URL(/* ... */)
}
@Shared(.fileStorage(.users)) var users: [User] = []
```

Any changes made to this value will be automatically synchronized to the URL on disk provided.
Further, any change made to the file stored at the URL will also be immediately played back to
the `@Shared` value, as this test proves:

```swift
@Test(.dependency(\.defaultFileStorage, .fileSystem))
func externalWrite() throws {
  let url = URL.temporaryDirectory.appending(component: "is-on.json")
  try? FileManager.default.removeItem(at: url)

  @Shared(.fileStorage(url)) var isOn = true
  #expect(isOn == true)
  try Data("false".utf8).write(to: url)
  #expect(isOn == false)
}
```

> Important: Data is not saved _immediately_ upon making changes to shared state. Writes to the disk
> are throttled so that at most one write per second is made. Any pending, un-persisted changes
> will also be saved when the app is backgrounded or terminated.

### Default file storage

When running your app in a simulator or device, `fileStorage` will use the actual file system for 
saving and loading data. However, in tests and previews `fileStorage` uses an in-memory, virtual
file system. This makes it possible for previews and tests to operate in their own sandboxed 
environment so that changes made to files do not spill over to other previews or tests, or the
simulator. It also allows your tests to pass deterministically and for tests to be run in parallel.

If you really do want to use the live file system in your previews, you can use
`prepareDependencies`:

```swift
#Preview {
  let _ = prepareDependencies { $0.defaultFileStorage = .fileSystem }
  // ...
}
```

And if you want to use the live file system in your tests you can use the `dependency` test trait:

```swift
@Test(.dependency(\.defaultFileStorage, .fileSystem))
func basics() {
  // ...
}
```

----

## Topics

### Storing a value

- ``SharedReaderKey/fileStorage(_:decoder:encoder:)``
- ``SharedReaderKey/fileStorage(_:decode:encode:)``

### Overriding storage

- ``Dependencies/DependencyValues/defaultFileStorage``
- ``FileStorage``

### Identifying storage

- ``FileStorageKeyID``
