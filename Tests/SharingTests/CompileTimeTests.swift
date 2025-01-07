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

func testIdentifiedDefaultValue() {
  do {
    @Shared(.items) var items = []
  }
  do {
    @SharedReader(.items) var items = []
  }
}

func testSharedReaderInitializerOverload() async throws {
  _ = SharedReader(wrappedValue: 42, .count)
}

func testSharedReaderLoadOverload() async throws {
  let shared = SharedReader(wrappedValue: 42, .count)
  try await shared.load(.count)
}

extension SharedKey where Self == InMemoryKey<Int> {
  fileprivate static var count: Self {
    .inMemory("count")
  }
}
