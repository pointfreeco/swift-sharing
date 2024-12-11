import Foundation
import IdentifiedCollections
import Sharing

private struct Item: Identifiable {
  let id = UUID()
}

extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<Item>>.Default {
  fileprivate static var items: Self {
    Self[.inMemory("items"), default: []]
  }
}

func test() {
  do {
    @Shared(.items) var items = []
  }
  do {
    @SharedReader(.items) var items = []
  }
}
