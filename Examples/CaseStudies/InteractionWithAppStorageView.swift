import Dependencies
import Sharing
import SwiftUI

struct InteractionWithAppStorageView: SwiftUICaseStudy {
  let caseStudyTitle = "Interaction with @AppStorage"
  let caseStudyNavigationTitle = "With @AppStorage"
  let readMe = """
    This case study demonstrates that `@Shared(.appStorage)` interacts with regular `@AppStorage` \
    exactly as you would expect. A change in one instantly updates the other.

    You might not typically want to use `@Shared(.appStorage)` directly in a SwiftUI view since \
    `@AppStorage` is available. But there are a few differences between the two that you may \
    find interesting.

    • In previews and tests, `@Shared(.appStorage)` operates on a quarantined instance of user \
    defaults that will not bleed over to other tests, previews or simulators.
    • `@Shared(.appStorage)` primarily uses KVO to observe changes to user defaults, which means \
    it will update when changes are made from other processes, such as widgets.
    • Because of its reliance on KVO, it is possible to animate changes to the value held in \
    app storage.
    """

  @Shared(.appStorage("count")) var sharedCount = 0
  @AppStorage("count") var appStorageCount = 0

  var body: some View {
    Section {
      Button("Reset UserDefaults directly") {
        UserDefaults.standard.set(0, forKey: "count")
      }
    }

    Section {
      Text("\(sharedCount)")
      Button("Increment") {
        $sharedCount.withLock { $0 += 1 }
      }
      Button("Decrement") {
        $sharedCount.withLock { $0 -= 1 }
      }
    } header: {
      Text("@Shared(.appStorage)")
    }

    Section {
      Text("\(appStorageCount)")
      Button("Increment") {
        appStorageCount += 1
      }
      Button("Decrement") {
        appStorageCount -= 1
      }
    } header: {
      Text("@AppStorage")
    }
  }
}

#Preview("Standard user defaults") {
  let _ = prepareDependencies { $0.defaultAppStorage = .standard }
  NavigationStack {
    CaseStudyView {
      InteractionWithAppStorageView()
    }
  }
}

#Preview("Quarantined user defaults") {
  let _ = UserDefaults(
    suiteName: "\(NSTemporaryDirectory())co.pointfree.Sharing.\(UUID().uuidString)"
  )!
  @Dependency(\.defaultAppStorage) var store
  NavigationStack {
    CaseStudyView {
      InteractionWithAppStorageView()
    }
  }
  .defaultAppStorage(store)
}
