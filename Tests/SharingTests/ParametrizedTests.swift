import DependenciesTestSupport
import Sharing
import Testing

@Suite(.dependencies)
struct MyTests {
  @Test(arguments: 0...10)
  func testCounterWithArguments(initialValue: Int) async throws {
    @Shared(.inMemory("count")) var counter = initialValue
    #expect(counter == initialValue)
  }
}
