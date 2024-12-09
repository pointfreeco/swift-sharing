import IdentifiedCollections
import IssueReporting

// TODO: Generalize to 'RangeReplaceableCollection' when deprecations become 'unavailable'
extension Array {
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

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension Shared: Collection, Sequence
where Value: _MutableIdentifiedCollection, Value.Index == Value.IDs.Index {
  public var startIndex: Value.Index { wrappedValue.startIndex }
  public var endIndex: Value.Index { wrappedValue.endIndex }
  public func index(after i: Value.Index) -> Value.Index { wrappedValue.index(after: i) }
  public subscript(position: Value.Index) -> Shared<Value.Element> {
    #if canImport(SwiftUI)
      if !isTesting, !wrappedValue.indices.contains(position) {
        let collectionReference = reference as! any _CachedReferenceProtocol
        let value = collectionReference.cachedValue as! Value
        func open(
          _ reference: some MutableReference<Value.Element?>
        ) -> any MutableReference<Value.Element> {
          _OptionalReference(
            base: reference,
            initialValue: value[position]
          )
        }
        let elementReference = self[id: value.ids[position]].reference
        defer { collectionReference.resetCache() }
        return Shared<Value.Element>(reference: open(elementReference))
      }
    #endif
    return Shared<Value.Element>(self[id: wrappedValue.ids[position]])!
  }
}

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension Shared: BidirectionalCollection
where
  Value: _MutableIdentifiedCollection & BidirectionalCollection,
  Value.Index == Value.IDs.Index
{
  public func index(before i: Value.Index) -> Value.Index { wrappedValue.index(before: i) }
}

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension Shared: RandomAccessCollection
where
  Value: _MutableIdentifiedCollection & RandomAccessCollection,
  Value.Index == Value.IDs.Index
{}

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension SharedReader: Collection, Sequence
where Value: _IdentifiedCollection, Value.Index == Value.IDs.Index {
  public var startIndex: Value.Index { wrappedValue.startIndex }
  public var endIndex: Value.Index { wrappedValue.endIndex }
  public func index(after i: Value.Index) -> Value.Index { wrappedValue.index(after: i) }
  public subscript(position: Value.Index) -> SharedReader<Value.Element> {
    #if canImport(SwiftUI)
      if !isTesting, !wrappedValue.indices.contains(position) {
        let collectionReference = reference as! any _CachedReferenceProtocol
        let value = collectionReference.cachedValue as! Value
        func open(
          _ reference: some Reference<Value.Element?>
        ) -> any Reference<Value.Element> {
          _OptionalReference(base: reference, initialValue: value[position])
        }
        let elementReference = self[id: value.ids[position]].reference
        defer { collectionReference.resetCache() }
        return SharedReader<Value.Element>(reference: open(elementReference))
      }
    #endif
    return SharedReader<Value.Element>(self[id: wrappedValue.ids[position]])!
  }
}

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension SharedReader: BidirectionalCollection
where Value: _IdentifiedCollection & BidirectionalCollection, Value.Index == Value.IDs.Index {
  public func index(before i: Value.Index) -> Value.Index { wrappedValue.index(before: i) }
}

@available(
  *,
  deprecated,
  message:
    "Derive shared elements from a stable subscript, like '$array[id:]' on 'IdentifiedArray', or pass 'Array($array)' to a 'ForEach' view."
)
extension SharedReader: RandomAccessCollection
where Value: _IdentifiedCollection & RandomAccessCollection, Value.Index == Value.IDs.Index {}
