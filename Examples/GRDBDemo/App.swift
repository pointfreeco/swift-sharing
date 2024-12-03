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
