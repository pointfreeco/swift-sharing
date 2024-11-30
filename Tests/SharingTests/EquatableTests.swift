import Sharing
import Testing

@Suite
struct EquatableTests {
  @Test func nonPersisted() {
    @Shared(value: 0) var lhs
    @Shared(value: 0) var rhs
    #expect(lhs == rhs)
    #expect($lhs == $rhs)

    $lhs.withLock { $0 += 1 }
    #expect(lhs != rhs)
    #expect($lhs != $rhs)

    $rhs.withLock { $0 += 1 }
    #expect(lhs == rhs)
    #expect($lhs == $rhs)
  }

  @Test func comparePersistedAndNonPersisted() {
    @Shared(value: 0) var lhs
    @Shared(.inMemory("rhs")) var rhs = 0
    #expect(lhs == rhs)
    #expect($lhs == $rhs)

    $lhs.withLock { $0 += 1 }
    #expect(lhs != rhs)
    #expect($lhs != $rhs)

    $rhs.withLock { $0 += 1 }
    #expect(lhs == rhs)
    #expect($lhs == $rhs)
  }
}
