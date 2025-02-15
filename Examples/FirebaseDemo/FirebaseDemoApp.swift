import Dependencies
import FirebaseCore
import SwiftUI

@main
struct FirebaseDemoApp: App {
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
