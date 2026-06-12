#if CasePaths
import CasePaths
@_spi(SharedChangeTracking) import Sharing
import Testing
import PerceptionCore

@Suite struct CasePathsTraitTests {
  @CasePathable
  @dynamicMemberLookup
  enum Route: Equatable {
    case detail(Int)
    case settings
  }

  struct Model: Equatable {
    var route: Route
  }

  @Test func readsCaseThroughShared() throws {
    @Shared(value: Model(route: .detail(42))) var model

    let detailReader: SharedReader<Int>? = $model.route.detail
    #expect(detailReader?.wrappedValue == 42)
    
    let detail: Shared<Int>? = $model.route.detail
    #expect(detail?.wrappedValue == 42)
  }

  @Test func writesCaseThroughShared() throws {
    @Shared(value: Model(route: .detail(42))) var model

    let _detail: Shared<Int>? = $model.route.detail
    let detail = try #require(_detail)
    detail.withLock { $0 = 100 }

    #expect(model.route == .detail(100))
  }

  @Test func returnsNilForNonMatchingCase() {
    @Shared(value: Model(route: .settings)) var model

    let detail: Shared<Int>? = $model.route.detail
    #expect(detail == nil)
  }
  
  @Test func sharedReaderReturnsNilForNonMatchingCase() {
    @Shared(value: Model(route: .settings)) var model
    let detailReader: SharedReader<Int>? = $model.route.detail
    #expect(detailReader == nil)
  }
  
  @Test func sharedCaseReflectsExternalMutation() throws {
    @Shared(value: Model(route: .detail(1))) var model
    let _detail: Shared<Int>? = $model.route.detail
    let detail = try #require(_detail)
    $model.withLock { $0.route = .detail(99) }
    #expect(detail.wrappedValue == 99)
  }
  
  @Test func sharedReaderCaseReflectsExternalMutation() throws {
    @Shared(value: Model(route: .detail(1))) var model
    let _detail: SharedReader<Int>? = $model.route.detail
    let detail = try #require(_detail)
    $model.withLock { $0.route = .detail(99) }
    #expect(detail.wrappedValue == 99)
  }
  
  @Test func writesAreDroppedAfterCaseSwitch() throws {
    @Shared(value: Model(route: .detail(1))) var model
    let _detail: Shared<Int>? = $model.route.detail
    let detail = try #require(_detail)
    $model.withLock { $0.route = .settings }   // switch away
    detail.withLock { $0 = 999 }               // should be a no-op
    #expect(model.route == .settings)
  }
  
  @MainActor
  @Test func casePathMutationTriggersObservation() async throws {
    @Shared(value: Model(route: .detail(0))) var model
    let _detail: Shared<Int>? = $model.route.detail
    let detail = try #require(_detail)
    await confirmation { confirm in
      withObservationTracking {
        _ = model.route
      } onChange: {
        confirm()
      }
      detail.withLock { $0 = 1 }
    }
  }
  
  @Test func tracking() throws {
    @Shared(value: Route.detail(0)) var model
    let _detail: Shared<Int>? = $model.detail
    let detail = try #require(_detail)

    withKnownIssue {
      do {
        let tracker = SharedChangeTracker()
        tracker.track {
          detail.withLock { $0 += 1 }
        }
      }
    } matching: {
      print("# " + $0.description)
      return $0.description.hasSuffix(
        """
        Tracked unasserted changes to 'Shared<CasePathsTraitTests.Route>(value: SharingTests.CasePathsTraitTests.Route.detail(1))': SharingTests.CasePathsTraitTests.Route.detail(0) → SharingTests.CasePathsTraitTests.Route.detail(1)
        """
      )
    }
  }
}
#endif
