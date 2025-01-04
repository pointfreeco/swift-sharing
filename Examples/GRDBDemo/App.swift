import Dependencies
import GRDB
import SwiftUI

@main
struct GRDBDemoApp: App {
  static let model = PlayersModel()

  init() {
    prepareDependencies {
      $0.defaultDatabase = .appDatabase
    }
  }

  var body: some Scene {
    WindowGroup {
      PlayersView(model: Self.model)
    }
  }
}
