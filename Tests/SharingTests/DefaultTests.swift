import Sharing
import Testing

@Suite struct DefaultTests {
  @Test func sharedCompetingDefaults() {
    @Shared(.isOn) var isOn1 = true
    @Shared(.isOn) var isOn2 = false
    @Shared(.isOn) var isOn3

    #expect(isOn1 == true)
    #expect(isOn2 == true)
    #expect(isOn3 == true)
  }

  @Test func sharedCompetingDefaultsSameDefault() {
    @Shared(.isOn) var isOn1 = false
    @Shared(.isOn) var isOn2 = true
    @Shared(.isOn) var isOn3

    #expect(isOn1 == false)
    #expect(isOn2 == false)
    #expect(isOn3 == false)
  }

  @Test func sharedUnspecifiedWrappedValue() {
    @Shared(.isOn) var isOn1
    @Shared(.isOn) var isOn2 = true
    @Shared(.isOn) var isOn3 = false

    #expect(isOn1 == false)
    #expect(isOn2 == false)
    #expect(isOn3 == false)
  }

  @Test func sharedReaderCompetingDefaults() {
    @SharedReader(.isOn) var isOn1 = true
    @SharedReader(.isOn) var isOn2 = false
    @SharedReader(.isOn) var isOn3

    #expect(isOn1 == true)
    #expect(isOn2 == true)
    #expect(isOn3 == true)
  }

  @Test func sharedReaderCompetingDefaultsSameDefault() {
    @SharedReader(.isOn) var isOn1 = false
    @SharedReader(.isOn) var isOn2 = true
    @SharedReader(.isOn) var isOn3

    #expect(isOn1 == false)
    #expect(isOn2 == false)
    #expect(isOn3 == false)
  }

  @Test func sharedReaderUnspecifiedWrappedValue() {
    @SharedReader(.isOn) var isOn1
    @SharedReader(.isOn) var isOn2 = true
    @SharedReader(.isOn) var isOn3 = false

    #expect(isOn1 == false)
    #expect(isOn2 == false)
    #expect(isOn3 == false)
  }

  @Test func assignedDefaultPersistsAfterReferenceRelease() {
    do {
      @Shared(.isOn) var isOn = true
      #expect(isOn == true)
    }
    do {
      @Shared(.isOn) var isOn
      #expect(isOn == true)
    }
  }

  @Test func defaultPersistsAfterSetting() {
    do {
      @Shared(.isOn) var isOn = false
      $isOn.withLock { $0 = true }
      #expect(isOn == true)
    }
    do {
      @Shared(.isOn) var isOn
      #expect(isOn == true)
    }
  }

  @Test func requireShouldThrow() {
    withKnownIssue {
      _ = try Shared(require: .isOn)
    }
  }
}

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
  fileprivate static var isOn: Self {
    Self[.inMemory("isOn"), default: false]
  }
}
