#if canImport(Foundation)
  import Foundation
#endif

// NB: Deprecated after 2.5.2

#if canImport(Foundation)
  @available(iOS, deprecated: 9999, message: "This will be removed in Sharing 3.")
  @available(macOS, deprecated: 9999, message: "This will be removed in Sharing 3.")
  @available(tvOS, deprecated: 9999, message: "This will be removed in Sharing 3.")
  @available(watchOS, deprecated: 9999, message: "This will be removed in Sharing 3.")
  extension Data {
    package static let stub = Self("co.pointfree.Sharing.FileStorage.stub".utf8)
  }
#endif

// NB: Deprecated after 2.2.0

extension SharedReader {
  #if compiler(>=6)
    @available(*, deprecated, message: "Use 'SharedReader(value:)', instead.")
    public static func constant(_ value: sending Value) -> Self {
      Self(Shared(value: value))
    }
  #else
    @available(*, deprecated, message: "Use 'SharedReader(value:)', instead.")
    public static func constant(_ value: Value) -> Self {
      Self(Shared(value: value))
    }
  #endif
}
