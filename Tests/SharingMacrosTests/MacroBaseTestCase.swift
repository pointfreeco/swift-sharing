#if canImport(SharingMacros)
  import MacroTesting
  import SharingMacros
  import SwiftSyntaxMacros
  import SwiftSyntaxMacrosTestSupport
  import XCTest

  class MacroBaseTestCase: XCTestCase {
    override func invokeTest() {
      MacroTesting.withMacroTesting(
        //isRecording: true,
        macros: [
          ObservableValueMacro.self,
          ObservationValueTrackedMacro.self,
          ObservationValueIgnoredMacro.self,
        ]
      ) {
        super.invokeTest()
      }
    }
  }
#endif
