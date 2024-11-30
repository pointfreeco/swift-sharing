#if canImport(SwiftUI)
  import Sharing
  import SwiftUI
  import Testing

  @Suite
  @MainActor
  struct BindingTests {
    @Test
    func binding() throws {
      let count = Shared(value: 0)
      let binding = Binding(count)

      binding.wrappedValue += 1
      #expect(binding.wrappedValue == 1)
      #expect(count.wrappedValue == 1)

      count.withLock { $0 += 1 }
      #expect(binding.wrappedValue == 2)
      #expect(count.wrappedValue == 2)
    }
  }
#endif
