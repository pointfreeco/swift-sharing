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
  
  @Test func map() {
    @Shared(value: 0) var base: Int
    @SharedReader var lhs: Int
    @SharedReader var rhs: Int
    _lhs = $base.map { $0 * 2 }
    _rhs = $base.map { $0 * 3 }
    #expect(lhs == rhs)
    #expect($lhs == $rhs)
    
    $base.withLock { $0 += 1 }
    #expect(lhs != rhs)
    #expect($lhs != $rhs)
  }
}
