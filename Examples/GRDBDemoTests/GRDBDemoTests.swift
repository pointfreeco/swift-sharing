import Dependencies
import DependenciesTestSupport
import GRDB
import Testing

@testable import GRDBDemo

@MainActor
@Suite(.dependency(\.defaultDatabase, .appDatabase))
struct GRDBDemoTests {
  @Dependency(\.defaultDatabase) var database

  init() throws {
    for index in 1...3 {
      try database.write { db in
        _ = try Player(name: "Blob \(index)", isInjured: index.isMultiple(of: 2))
          .inserted(db)
      }
    }
  }

  @Test func order() async throws {
    let model = PlayersModel()

    #expect(
      model.players
        == [
          Player(id: 1, name: "Blob 1", isInjured: false),
          Player(id: 2, name: "Blob 2", isInjured: true),
          Player(id: 3, name: "Blob 3", isInjured: false),
        ]
    )

    model.$order.withLock { $0 = .isInjured }

    try await Task.sleep(for: .milliseconds(100))
    #expect(
      model.players
        == [
          Player(id: 2, name: "Blob 2", isInjured: true),
          Player(id: 1, name: "Blob 1", isInjured: false),
          Player(id: 3, name: "Blob 3", isInjured: false),
        ]
    )
  }

  @Test func delete() async throws {
    let model = PlayersModel()

    model.deleteItems(offsets: [1])

    try await Task.sleep(for: .milliseconds(100))
    #expect(
      model.players
        == [
          Player(id: 1, name: "Blob 1", isInjured: false),
          Player(id: 3, name: "Blob 3", isInjured: false),
        ]
    )
  }
}
