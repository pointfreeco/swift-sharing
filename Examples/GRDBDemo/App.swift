import Dependencies
import GRDB
import SwiftUI

@main
struct GRDBDemoApp: App {
  init() {
    prepareDependencies {
      $0.defaultDatabase = .appDatabase
    }
  }

  var body: some Scene {
    WindowGroup {
      PlayersView()
    }
  }
}

extension DatabaseQueue {
  fileprivate static var appDatabase: DatabaseQueue {
    let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
    print("open", path)
    var configuration = Configuration()
    configuration.prepareDatabase { db in
      db.trace { event in
        print(event)
      }
    }
    let databaseQueue = try! DatabaseQueue(path: path, configuration: configuration)
    try! databaseQueue.migrate()
    return databaseQueue
  }
}
