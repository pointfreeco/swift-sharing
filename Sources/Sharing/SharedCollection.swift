import IdentifiedCollections
import IssueReporting

extension RangeReplaceableCollection {
  /// Creates an collection of shared elements from a shared collection.
  ///
  /// Useful in deriving a shared element when looping over a shared collection, for example in a
  /// SwiftUI `ForEach` view:
  ///
  /// ```swift
  /// @Shared var users: [User]
  ///
  /// ForEach($users) { $user in
  ///   UserView(user: $user)
  /// }
  /// ```
  ///
  /// - Parameter shared: A shared identified collection.
  public init<Value: _MutableIdentifiedCollection>(
    _ shared: Shared<Value>
  ) where Element == Shared<Value.Element>, Value.Index == Value.IDs.Index {
    self.init()
    let value = shared.wrappedValue
    self.reserveCapacity(value.count)
    for id in value.ids {
      self.append(Shared(shared[id: id])!)
    }
  }

  /// Creates an collection of shared elements from a shared collection.
  ///
  /// Useful in deriving a shared element when looping over a shared collection, for example in a
  /// SwiftUI `ForEach` view:
  ///
  /// ```swift
  /// @SharedReader var users: [User]
  ///
  /// ForEach($users) { $user in
  ///   UserView(user: $user)
  /// }
  /// ```
  /// - Parameter shared: A shared identified collection.
  public init<Value: _IdentifiedCollection>(
    _ shared: SharedReader<Value>
  ) where Element == SharedReader<Value.Element>, Value.Index == Value.IDs.Index {
    self.init()
    let value = shared.wrappedValue
    self.reserveCapacity(value.count)
    for id in value.ids {
      self.append(SharedReader(shared[id: id])!)
    }
  }
}
