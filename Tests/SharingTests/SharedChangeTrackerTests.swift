import CustomDump
import PerceptionCore
@_spi(SharedChangeTracking) import Sharing
import Testing

@Suite struct SharedChangeTrackingTests {
  @Test func basics() {
    @Shared(value: 0) var count

    let tracker = SharedChangeTracker()
    tracker.track {
      $count.withLock { $0 += 1 }
    }

    tracker.assert {
      #expect($count != $count)
      #expect(diff($count, $count) == """
        - #1 0
        + #1 1
        """)

      $count.withLock { $0 = 1 }

      #expect($count == $count)
    }
  }

  @Test func independentShareds() {
    @Shared(value: 0) var count1
    @Shared(value: 0) var count2

    #expect($count1 == $count2)

    let tracker = SharedChangeTracker()
    tracker.track {
      $count1.withLock { $0 += 1 }
    }

    tracker.assert {
      #expect($count1 != $count1)
      #expect($count1 == $count2)
      #expect($count2 == $count2)

      $count1.withLock { $0 = 1 }

      #expect($count1 == $count1)
      #expect($count1 != $count2)
    }
  }

  @Test func differentProjections() {
    struct Stats: Equatable {
      var bool1 = false
      var bool2 = false
    }
    @Shared(value: Stats()) var stats

    #expect($stats.bool1 == $stats.bool2)

    let tracker = SharedChangeTracker()
    tracker.track {
      $stats.bool1.withLock { $0.toggle() }
    }

    tracker.assert {
      #expect($stats.bool1 != $stats.bool1)
      #expect($stats.bool1 == $stats.bool2)
      #expect($stats.bool2 == $stats.bool2)

      $stats.bool1.withLock { $0.toggle() }

      #expect($stats.bool1 == $stats.bool1)
      #expect($stats.bool1 != $stats.bool2)

      #expect($stats == $stats)
    }
  }

  @Test func unassertedChanges() {
    @Shared(value: 0) var count

    withKnownIssue {
      do {
        let tracker = SharedChangeTracker()
        tracker.track {
          $count.withLock { $0 += 1 }
        }
      }
    } matching: {
      $0.description == """
        Issue recorded: Tracked unasserted changes to 'Shared<Int>(value: 1)': 0 → 1
        """
    }
  }

  @Test func unreportedChanges() {
    @Shared(value: 0) var count

    let tracker = SharedChangeTracker(reportUnassertedChanges: false)
    tracker.track {
      $count.withLock { $0 += 1 }
    }
  }
}
