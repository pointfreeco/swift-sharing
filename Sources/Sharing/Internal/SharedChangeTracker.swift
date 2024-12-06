import Dependencies
import Foundation
import IssueReporting

@_spi(SharedChangeTracking)
public struct SharedChangeTracker: Hashable, Sendable {
  fileprivate final class Changes: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storage: [ObjectIdentifier: any AnyChange] = [:]
    deinit {
      forEach { change in
        reportIssue(
          """
          Tracked unasserted changes to '\(String(reflecting: change.key))': \
          \(change.value) → \(change.key.wrappedValue)
          """ //,
          // fileID: fileID,
          // filePath: filePath,
          // line: line,
          // column: column
        )
      }
    }
    var hasChanges: Bool {
      lock.withLock { !storage.values.isEmpty }
    }
    func hasChanges(for key: some MutableReference) -> Bool {
      self[key] != nil
    }
    subscript<Value>(key: some MutableReference<Value>) -> Value? {
      _read {
        lock.lock()
        defer { lock.unlock() }
        let change = storage[ObjectIdentifier(key)] as? Change<Value>
        yield change?.value
      }
      _modify {
        lock.lock()
        defer { lock.unlock() }
        var change = storage[ObjectIdentifier(key)] as? Change<Value> ?? Change(reference: key)
        var value: Value? = change.value
        yield &value
        guard let value else { return }
        change.value = value
        storage[ObjectIdentifier(key)] = change
      }
      set {
        lock.withLock {
          guard let newValue else { return }
          var change = storage[ObjectIdentifier(key)] as? Change<Value> ?? Change(reference: key)
          defer { storage[ObjectIdentifier(key)] = change }
          change.value = newValue
        }
      }
    }
    func forEach(_ body: (any AnyChange) -> Void) {
      lock.withLock {
        for change in storage.values where change.shouldAssert {
          body(change)
        }
      }
    }
    func untrack<Value>(_ key: some MutableReference<Value>) {
      lock.withLock { storage[ObjectIdentifier(key)]?.shouldAssert = false }
    }
    func reset() {
      lock.withLock { storage.removeAll() }
    }
  }

  fileprivate struct Change<Value>: AnyChange {
    let reference: any MutableReference<Value>
    var shouldAssert = true
    var value: Value

    init(reference: any MutableReference<Value>) {
      self.reference = reference
      self.value = reference.wrappedValue
    }

    var key: any MutableReference {
      func open(_ reference: some MutableReference) -> any MutableReference {
        reference
      }
      return open(reference)
    }
  }

  @available(*, deprecated)
  static func tracker(for key: some MutableReference) -> Self? {
    @Dependency(SharedChangeTrackersKey.self) var sharedChangeTrackers
    var sharedChangeTracker: Self?
    for tracker in sharedChangeTrackers {
      if sharedChangeTracker == nil, tracker.changes.hasChanges(for: key) {
        sharedChangeTracker = tracker
      } else if tracker.changes.hasChanges(for: key) {
        break
      }
    }
    return sharedChangeTracker
  }

  fileprivate let changes = Changes()

  public var hasChanges: Bool { changes.hasChanges }

  public init() {}

  public func track(_ dependencies: inout DependencyValues) {
    dependencies[SharedChangeTrackersKey.self].insert(self)
  }

  public func track<R>(_ body: () throws -> R) rethrows -> R {
    try withDependencies {
      $0[SharedChangeTrackersKey.self].insert(self)
    } operation: {
      try body()
    }
  }

  public func assert<R>(_ body: () throws -> R) rethrows -> R {
    try withDependencies {
      $0[SharedChangeTrackerKey.self] = self
    } operation: {
      try body()
    }
  }

  public func reset() {
    changes.reset()
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.changes === rhs.changes
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(changes))
  }
}

fileprivate protocol AnyChange<Value> {
  associatedtype Value
  var key: any MutableReference { get }
  var value: Value { get }
  var shouldAssert: Bool { get set }
}

extension DependencyValues {
  var snapshots: Snapshots { Snapshots() }
}

struct Snapshots: Sendable {
  @Dependency(SharedChangeTrackerKey.self) var sharedChangeTracker
  @Dependency(SharedChangeTrackersKey.self) var sharedChangeTrackers

  var isTracking: Bool {
    !sharedChangeTrackers.isEmpty
  }

  var isAsserting: Bool {
    sharedChangeTracker != nil
  }

  func untrack<Value>(_ key: some MutableReference<Value>) {
    sharedChangeTracker?.changes.untrack(key)
  }

  subscript<Value>(key: some MutableReference<Value>) -> Value? {
    get { sharedChangeTracker?.changes[key] }
    nonmutating set {
      if let sharedChangeTracker {
        sharedChangeTracker.changes[key] = newValue
      } else {
        for sharedChangeTracker in sharedChangeTrackers {
          sharedChangeTracker.changes[key] = newValue
        }
      }
    }
  }
}

private enum SharedChangeTrackerKey: DependencyKey {
  static var liveValue: SharedChangeTracker? { nil }
  static var testValue: SharedChangeTracker? { nil }
}

private enum SharedChangeTrackersKey: DependencyKey {
  static var liveValue: Set<SharedChangeTracker> { [] }
  static var testValue: Set<SharedChangeTracker> { [] }
}
