import Dependencies
import Foundation
import IssueReporting

@_spi(SharedChangeTracking)
public struct SharedChangeTracker: Hashable, Sendable {
  fileprivate final class Changes: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storage: [ObjectIdentifier: any AnyChange] = [:]
    private let reportUnassertedChanges: Bool
    init(reportUnassertedChanges: Bool) {
      self.reportUnassertedChanges = reportUnassertedChanges
    }
    deinit {
      guard reportUnassertedChanges else { return }
      forEach { change in
        reportIssue(
          """
          Tracked unasserted changes to \
          'Shared<\(typeName(type(of: change.value)))>(\(String(reflecting: change.key)))': \
          \(String(reflecting: change.value)) → \(String(reflecting: change.key.wrappedValue))
          """,
          fileID: change.fileID,
          filePath: change.filePath,
          line: change.line,
          column: change.column
        )
      }
    }
    var hasChanges: Bool {
      lock.withLock { !storage.values.isEmpty }
    }
    func hasChanges(for key: some MutableReference) -> Bool {
      self[key] != nil
    }
    subscript<Value>(
      key: some MutableReference<Value>
    ) -> Value? {
      lock.withLock {
        (storage[ObjectIdentifier(key)] as? Change<Value>)?.value
      }
    }
    func track<Value>(
      key: some MutableReference<Value>,
      value: Value,
      fileID: StaticString,
      filePath: StaticString,
      line: UInt,
      column: UInt
    ) {
      lock.withLock {
        var change = storage[ObjectIdentifier(key)] as? Change<Value> ?? Change(
          reference: key,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
        defer { storage[ObjectIdentifier(key)] = change }
        change.value = value
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
    let fileID: StaticString
    let filePath: StaticString
    let line: UInt
    let column: UInt

    init(
      reference: any MutableReference<Value>,
      fileID: StaticString,
      filePath: StaticString,
      line: UInt,
      column: UInt
    ) {
      self.reference = reference
      self.value = reference.wrappedValue
      self.fileID = fileID
      self.filePath = filePath
      self.line = line
      self.column = column
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

  fileprivate let changes: Changes

  public var hasChanges: Bool { changes.hasChanges }

  public init(reportUnassertedChanges: Bool = isTesting) {
    self.changes = Changes(reportUnassertedChanges: reportUnassertedChanges)
  }

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
  var fileID: StaticString { get }
  var filePath: StaticString { get }
  var line: UInt { get }
  var column: UInt { get }
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
    sharedChangeTracker?.changes[key]
  }

  func save<Value>(
    key: some MutableReference<Value>,
    value: Value,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    if let sharedChangeTracker {
      sharedChangeTracker.changes.track(
        key: key,
        value: value,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    } else {
      for sharedChangeTracker in sharedChangeTrackers {
        sharedChangeTracker.changes.track(
          key: key,
          value: value,
          fileID: fileID,
          filePath: filePath,
          line: line,
          column: column
        )
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
