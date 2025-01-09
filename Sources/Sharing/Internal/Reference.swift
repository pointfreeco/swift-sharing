import Dependencies
import Foundation
import IdentifiedCollections
import PerceptionCore

#if canImport(Combine)
  import Combine
#endif

protocol Reference<Value>:
  AnyObject,
  CustomStringConvertible,
  Sendable,
  Perceptible
{
  associatedtype Value

  var id: ObjectIdentifier { get }
  var isLoading: Bool { get }
  var loadError: (any Error)? { get }
  var wrappedValue: Value { get }
  func load() async throws
  func touch()
  #if canImport(Combine)
    var publisher: any Publisher<Value, Never> { get }
  #endif
}

protocol MutableReference<Value>: Reference, Equatable {
  var saveError: (any Error)? { get }
  var snapshot: Value? { get }
  func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R
  func takeSnapshot(
    _ value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  )
  func save() async throws
}

final class _BoxReference<Value>: MutableReference, Observable, Perceptible, @unchecked Sendable {
  private let _$perceptionRegistrar = PerceptionRegistrar(isPerceptionCheckingEnabled: false)
  private let lock = NSRecursiveLock()

  #if canImport(Combine)
    private var value: Value {
      willSet {
        subject.send(newValue)
      }
    }
    let subject = PassthroughRelay<Value>()

    var publisher: any Publisher<Value, Never> {
      subject.prepend(lock.withLock { value })
    }
  #else
    private var value: Value
  #endif

  init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  deinit {
    #if canImport(Combine)
      subject.send(completion: .finished)
    #endif
  }

  var id: ObjectIdentifier { ObjectIdentifier(self) }

  var isLoading: Bool {
    false
  }

  var loadError: (any Error)? {
    nil
  }

  var saveError: (any Error)? {
    nil
  }

  var wrappedValue: Value {
    access(keyPath: \.value)
    return lock.withLock { value }
  }

  var snapshot: Value? {
    @Dependency(\.snapshots) var snapshots
    return snapshots[self]
  }

  func takeSnapshot(
    _ value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    @Dependency(\.snapshots) var snapshots
    snapshots.save(
      key: self,
      value: value,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  func load() {}

  func touch() {
    withMutation(keyPath: \.value) {}
  }

  func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    try withMutation(keyPath: \.value) {
      try lock.withLock { try body(&value) }
    }
  }

  func save() {}

  static func == (lhs: _BoxReference, rhs: _BoxReference) -> Bool {
    lhs === rhs
  }

  func access<Member>(
    keyPath: KeyPath<_BoxReference, Member>,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    _$perceptionRegistrar.access(
      self,
      keyPath: keyPath,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  func withMutation<Member, MutationResult>(
    keyPath: _SendableKeyPath<_BoxReference, Member>,
    _ mutation: () throws -> MutationResult
  ) rethrows -> MutationResult {
    #if os(WASI)
      return try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    #else
      if Thread.isMainThread {
        return try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
      } else {
        DispatchQueue.main.async {
          self._$perceptionRegistrar.withMutation(of: self, keyPath: keyPath) {}
        }
        return try mutation()
      }
    #endif
  }

  var description: String {
    "value: \(String(reflecting: wrappedValue))"
  }
}

final class _PersistentReference<Key: SharedReaderKey>:
  Reference, Observable, Perceptible, @unchecked Sendable
{
  private let _$perceptionRegistrar = PerceptionRegistrar(isPerceptionCheckingEnabled: false)
  private let key: Key
  private let lock = NSRecursiveLock()

  #if canImport(Combine)
    private var value: Key.Value {
      willSet {
        subject.send(newValue)
      }
    }
    private let subject = PassthroughRelay<Value>()

    var publisher: any Publisher<Key.Value, Never> {
      subject.prepend(lock.withLock { value })
    }
  #else
    private var value: Key.Value
  #endif

  private var _isLoading = false
  private var _loadError: (any Error)?
  private var _saveError: (any Error)?
  private var _referenceCount = 0
  private var subscription: SharedSubscription?

  init(key: Key, value initialValue: Key.Value, skipInitialLoad: Bool) {
    self.key = key
    self.value = initialValue
    let callback: @Sendable (Result<Value?, any Error>) -> Void = { [weak self] result in
      guard let self else { return }
      isLoading = false
      switch result {
      case let .failure(error):
        loadError = error
      case let .success(newValue):
        loadError = nil
        wrappedValue = newValue ?? initialValue
      }
    }
    if !skipInitialLoad {
      isLoading = true
      key.load(
        context: .initialValue(initialValue),
        continuation: LoadContinuation("\(key)", callback: callback)
      )
    }
    let context: LoadContext<Key.Value> = skipInitialLoad
      ? .userInitiated
      : .initialValue(initialValue)
    self.subscription = key.subscribe(
      context: context,
      subscriber: SharedSubscriber(callback: callback)
    )
  }

  deinit {
    #if canImport(Combine)
      subject.send(completion: .finished)
    #endif
  }

  var id: ObjectIdentifier { ObjectIdentifier(self) }

  var isLoading: Bool {
    get {
      access(keyPath: \._isLoading)
      return lock.withLock { _isLoading }
    }
    set {
      withMutation(keyPath: \._isLoading) {
        lock.withLock { _isLoading = newValue }
      }
    }
  }

  var loadError: (any Error)? {
    get {
      access(keyPath: \._loadError)
      return lock.withLock { _loadError }
    }
    set {
      withMutation(keyPath: \._loadError) {
        lock.withLock { _loadError = newValue }
      }
      if let newValue {
        reportIssue(newValue)
      }
    }
  }

  var wrappedValue: Key.Value {
    get {
      access(keyPath: \.value)
      return lock.withLock { value }
    }
    set {
      withMutation(keyPath: \.value) {
        lock.withLock { value = newValue }
      }
    }
  }

  func load() async throws {
    isLoading = true
    defer { isLoading = false }
    do {
      loadError = nil
      try await withUnsafeThrowingContinuation { continuation in
        let key = key
        key.load(
          context: .userInitiated,
          continuation: LoadContinuation("\(key)") { result in
            switch result {
            case .success(.some(let newValue)):
              self.wrappedValue = newValue
              continuation.resume()
            case .success(.none):
              continuation.resume()
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          }
        )
      }
    } catch {
      loadError = error
      throw error
    }
  }

  func touch() {
    withMutation(keyPath: \.value) {}
    withMutation(keyPath: \._isLoading) {}
    withMutation(keyPath: \._loadError) {}
    withMutation(keyPath: \._saveError) {}
  }

  func retain() {
    lock.withLock { _referenceCount += 1 }
  }

  func release() {
    let shouldRelease = lock.withLock {
      _referenceCount -= 1
      return _referenceCount <= 0
    }
    guard shouldRelease else { return }
    @Dependency(PersistentReferences.self) var persistentReferences
    persistentReferences.removeReference(forKey: key)
  }

  func access<Member>(
    keyPath: KeyPath<_PersistentReference, Member>,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    _$perceptionRegistrar.access(
      self,
      keyPath: keyPath,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  func withMutation<Member, MutationResult>(
    keyPath: _SendableKeyPath<_PersistentReference, Member>,
    _ mutation: () throws -> MutationResult
  ) rethrows -> MutationResult {
    #if os(WASI)
      return try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    #else
      if Thread.isMainThread {
        return try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
      } else {
        DispatchQueue.main.async {
          self._$perceptionRegistrar.withMutation(of: self, keyPath: keyPath) {}
        }
        return try mutation()
      }
    #endif
  }

  var description: String {
    String(reflecting: key)
  }
}

extension _PersistentReference: MutableReference, Equatable where Key: SharedKey {
  var saveError: (any Error)? {
    get {
      access(keyPath: \._saveError)
      return lock.withLock { _saveError }
    }
    set {
      withMutation(keyPath: \._saveError) {
        lock.withLock { _saveError = newValue }
      }
      if let newValue {
        reportIssue(newValue)
      }
    }
  }

  var snapshot: Key.Value? {
    @Dependency(\.snapshots) var snapshots
    return snapshots[self]
  }

  func takeSnapshot(
    _ value: Key.Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    @Dependency(\.snapshots) var snapshots
    snapshots.save(
      key: self,
      value: value,
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  func withLock<R>(_ body: (inout Key.Value) throws -> R) rethrows -> R {
    try withMutation(keyPath: \.value) {
      saveError = nil
      defer {
        let key = key
        key.save(
          value,
          context: .didSet,
          continuation: SaveContinuation("\(key)") { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
              loadError = nil
            case let .failure(error):
              saveError = error
            }
          }
        )
      }
      return try lock.withLock {
        try body(&value)
      }
    }
  }

  func save() async throws {
    saveError = nil
    do {
      _ = try await withUnsafeThrowingContinuation { continuation in
        let key = key
        key.save(
          lock.withLock { value },
          context: .userInitiated,
          continuation: SaveContinuation("\(key)") { result in
            continuation.resume(with: result)
          }
        )
      }
    } catch {
      saveError = error
      throw error
    }
    loadError = nil
  }

  static func == (lhs: _PersistentReference, rhs: _PersistentReference) -> Bool {
    lhs === rhs
  }
}

final class _ManagedReference<Key: SharedReaderKey>: Reference, Observable {
  private let base: _PersistentReference<Key>

  init(_ base: _PersistentReference<Key>) {
    base.retain()
    self.base = base
  }

  deinit {
    base.release()
  }

  var id: ObjectIdentifier {
    base.id
  }

  var isLoading: Bool {
    base.isLoading
  }

  var loadError: (any Error)? {
    base.loadError
  }

  var wrappedValue: Key.Value {
    base.wrappedValue
  }

  func load() async throws {
    try await base.load()
  }

  func touch() {
    base.touch()
  }

  #if canImport(Combine)
    var publisher: any Publisher<Key.Value, Never> {
      base.publisher
    }
  #endif

  var description: String {
    base.description
  }
}

extension _ManagedReference: MutableReference, Equatable where Key: SharedKey {
  var saveError: (any Error)? {
    base.saveError
  }

  var snapshot: Key.Value? {
    base.snapshot
  }

  func takeSnapshot(
    _ value: Key.Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    base.takeSnapshot(value, fileID: fileID, filePath: filePath, line: line, column: column)
  }

  func withLock<R>(_ body: (inout Key.Value) throws -> R) rethrows -> R {
    try base.withLock(body)
  }

  func save() async throws {
    try await base.save()
  }

  static func == (lhs: _ManagedReference, rhs: _ManagedReference) -> Bool {
    lhs.base == rhs.base
  }
}

final class _AppendKeyPathReference<
  Base: Reference, Value, Path: KeyPath<Base.Value, Value> & Sendable
>: Reference, Observable {
  private let base: Base
  private let keyPath: Path

  init(base: Base, keyPath: Path) {
    self.base = base
    self.keyPath = keyPath
  }

  var id: ObjectIdentifier {
    base.id
  }

  var isLoading: Bool {
    base.isLoading
  }

  var loadError: (any Error)? {
    base.loadError
  }

  var wrappedValue: Value {
    base.wrappedValue[keyPath: keyPath]
  }

  func load() async throws {
    try await base.load()
  }

  func touch() {
    base.touch()
  }

  #if canImport(Combine)
    var publisher: any Publisher<Value, Never> {
      func open(_ publisher: some Publisher<Base.Value, Never>) -> any Publisher<Value, Never> {
        publisher.map(keyPath)
      }
      return open(base.publisher)
    }
  #endif

  var description: String {
    "\(base.description)[dynamicMember: \(keyPath)]"
  }
}

extension _AppendKeyPathReference: MutableReference, Equatable
where Base: MutableReference, Path: WritableKeyPath<Base.Value, Value> {
  var saveError: (any Error)? {
    base.saveError
  }

  var snapshot: Value? {
    base.snapshot?[keyPath: keyPath]
  }

  func takeSnapshot(
    _ value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    var snapshot = base.snapshot ?? base.wrappedValue
    snapshot[keyPath: keyPath as WritableKeyPath] = value
    base.takeSnapshot(snapshot, fileID: fileID, filePath: filePath, line: line, column: column)
  }

  func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    try base.withLock { try body(&$0[keyPath: keyPath as WritableKeyPath]) }
  }

  func save() async throws {
    try await base.save()
  }

  static func == (lhs: _AppendKeyPathReference, rhs: _AppendKeyPathReference) -> Bool {
    lhs.base == rhs.base && lhs.keyPath == rhs.keyPath
  }
}

final class _OptionalReference<Base: Reference<Value?>, Value>:
  Reference,
  Observable,
  @unchecked Sendable
{
  private let base: Base
  private var cachedValue: Value
  private let lock = NSRecursiveLock()

  init(base: Base, initialValue: Value) {
    self.base = base
    self.cachedValue = initialValue
  }

  var id: ObjectIdentifier {
    base.id
  }

  var isLoading: Bool {
    base.isLoading
  }

  var loadError: (any Error)? {
    base.loadError
  }

  var wrappedValue: Value {
    guard let wrappedValue = base.wrappedValue else { return lock.withLock { cachedValue } }
    lock.withLock { cachedValue = wrappedValue }
    return wrappedValue
  }

  func load() async throws {
    try await base.load()
  }

  func touch() {
    base.touch()
  }

  #if canImport(Combine)
    var publisher: any Publisher<Value, Never> {
      func open(_ publisher: some Publisher<Value?, Never>) -> any Publisher<Value, Never> {
        publisher.compactMap { $0 }
      }
      return open(base.publisher)
    }
  #endif

  var description: String {
    "\(base.description)!"
  }
}

extension _OptionalReference: MutableReference, Equatable where Base: MutableReference {
  var saveError: (any Error)? {
    base.saveError
  }

  var snapshot: Value? {
    base.snapshot ?? nil
  }

  func takeSnapshot(
    _ value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    guard base.snapshot != nil else { return }
    base.takeSnapshot(value, fileID: fileID, filePath: filePath, line: line, column: column)
  }

  func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
    try base.withLock { value in
      guard var unwrapped = value else { return try lock.withLock { try body(&cachedValue) } }
      defer {
        value = unwrapped
        lock.withLock { cachedValue = unwrapped }
      }
      return try body(&unwrapped)
    }
  }

  func save() async throws {
    try await base.save()
  }

  static func == (lhs: _OptionalReference, rhs: _OptionalReference) -> Bool {
    lhs.base == rhs.base
  }
}
