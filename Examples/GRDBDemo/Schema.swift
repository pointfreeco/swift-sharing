import Dependencies
import Foundation
import GRDB
import Sharing

struct Player: Equatable {
  var id: Int64?
  var name = ""
  var isInjured = false
}

extension Player: Codable, FetchableRecord, MutablePersistableRecord {
  static let databaseTableName = "players"

  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}

extension DatabaseWriter {
  func migrate() throws {
    var migrator = DatabaseMigrator()
    defer {
      #if targetEnvironment(simulator)
        migrator.registerMigration("Create seed data") { db in
          try Player.deleteAll(db)
          for (index, name) in ["Blob", "Blob Jr.", "Blob Sr.", "Blob Esq."].enumerated() {
            _ = try Player(name: name, isInjured: index.isMultiple(of: 2))
              .inserted(db)
          }
        }
      #endif
      try! migrator.migrate(self)
    }
    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create 'players' table") { db in
      try db.create(table: Player.databaseTableName) { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("name", .text).notNull()
        t.column("isInjured", .boolean).defaults(to: false).notNull()
      }
    }
  }
}

enum PlayerOrder: String { case name, isInjured }

extension SharedReaderKey where Self == GRDBQueryKey<PlayersRequest>.Default {
  static func players(order: PlayerOrder = .name) -> Self {
    Self[
      .grdbQuery(PlayersRequest(order: order), animation: .default),
      default: []
    ]
  }
}

struct PlayersRequest: GRDBQuery {
  let order: PlayerOrder
  func fetch(_ db: Database) throws -> [Player] {
    let ordering: any SQLOrderingTerm =
      switch order {
      case .name:
        Column("name")
      case .isInjured:
        Column("isInjured").desc
      }
    return
      try Player
      .all()
      .order(ordering)
      .fetchAll(db)
  }
}

extension DatabaseQueue {
  static var appDatabase: DatabaseQueue {
    let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
    print("open", path)
    var configuration = Configuration()
    configuration.prepareDatabase { db in
      db.trace { event in
        print(event)
      }
    }
    let databaseQueue: DatabaseQueue
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
      databaseQueue = try! DatabaseQueue(path: path, configuration: configuration)
    } else {
      databaseQueue = try! DatabaseQueue(configuration: configuration)
    }
    try! databaseQueue.migrate()
    return databaseQueue
  }
}
