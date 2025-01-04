import Dependencies
import SwiftUI

@main
struct CaseStudiesApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        RootView()
      }
    }
  }
}

private struct RootView: View {
  var body: some View {
    Form {
      CaseStudyGroupView("Persistence strategies") {
        InMemorySharedStateView()
        AppStorageStateView()
        FileStorageSharedState()
      }
      CaseStudyGroupView("SwiftUI") {
        InteractionWithAppStorageView()
        SharedStateInView()
        SharedStateInObservableModelView()
        SwiftUIBindingFromSharedView()
        GlobalRouterView()
      }
      CaseStudyGroupView("UIKit") {
        SharedStateInViewController()
      }
      CaseStudyGroupView("Custom SharedKey") {
        NotificationsView()
        APIClientView()
        GRDBView()
        FirebaseView()
      }
    }
    .navigationTitle(Text("Case studies"))
  }
}

#Preview {
  NavigationStack {
    RootView()
  }
}
