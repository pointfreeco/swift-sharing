@_spi(Navigation) import Sharing
import Testing

@Suite struct SharedUIBindingRootTests {
  @Test func uiBindingRootIsStablePerSharedBox() {
    @Shared(value: 0) var count

    #expect($count._uiBindingRoot === $count._uiBindingRoot)
  }

  @Test func uiBindingRootTracksSharedReassignment() {
    @Shared(value: 0) var count
    let root = $count._uiBindingRoot
    let next = Shared(value: 10)

    $count = next
    #expect(root.value == 10)

    root.value = 11
    #expect(root.value == 11)
    #expect(next.wrappedValue == 11)
  }
}
