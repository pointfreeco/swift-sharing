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

  @Test func initialValue() {
    #expect(InMemoryKey<Bool>.Default.isOn.initialValue == false)
  }

  @Suite struct DefaultNotDefaultInterplay {
    @Test func writerDefault_readerDefault() {
      @Shared(.count1) var count
      @SharedReader(.count2) var countReader

      $count.withLock { $0 += 1 }

      #expect(count == 2)
      #expect(countReader == 2)
    }

    @Test func readerDefault_writerDefault() {
      @SharedReader(.count2) var countReader
      @Shared(.count1) var count

      $count.withLock { $0 += 1 }

      #expect(count == 3)
      #expect(countReader == 3)
    }

    @Test func writer_readerDefault() {
      @Shared(.count1) var count = 3
      @SharedReader(.count2) var countReader

      $count.withLock { $0 += 1 }

      #expect(count == 4)
      #expect(countReader == 4)
    }

    @Test func writerDefault_reader() {
      @Shared(.count1) var count
      @SharedReader(.count2) var countReader = 3

      $count.withLock { $0 += 1 }

      #expect(count == 2)
      #expect(countReader == 2)
    }

    @Test func reader_writerDefault() {
      @SharedReader(.count2) var countReader = 3
      @Shared(.count1) var count

      $count.withLock { $0 += 1 }

      #expect(count == 4)
      #expect(countReader == 4)
    }

    @Test func readerDefault_writer() {
      @SharedReader(.count2) var countReader
      @Shared(.count1) var count = 3

      $count.withLock { $0 += 1 }

      #expect(count == 3)
      #expect(countReader == 3)
    }
  }
}

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
  fileprivate static var isOn: Self {
    Self[.inMemory("isOn"), default: false]
  }
}

extension SharedKey where Self == InMemoryKey<Int>.Default {
  fileprivate static var count1: Self {
    Self[.inMemory("count"), default: 1]
  }
}

extension SharedReaderKey where Self == InMemoryKey<Int>.Default {
  fileprivate static var count2: Self {
    Self[.inMemory("count"), default: 2]
  }
}
