#if IssueReporting
  import IssueReporting

  @_transparent
  public func reportIssue(
    _ message: @autoclosure () -> String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    IssueReporting.reportIssue(
      message(),
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }

  @_transparent
  func reportIssue(
    _ error: any Error,
    _ message: @autoclosure () -> String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    IssueReporting.reportIssue(
      error,
      message(),
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
#else
  #if canImport(os)
    public import os
    public import Foundation
  #else
    import Foundation
  #endif

  #if canImport(os)
    @_transparent
  #endif
  public func reportIssue(
    _ message: @autoclosure () -> String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    runtimeWarn(
      message(),
      fileID: fileID,
      line: line,
    )
  }

  #if canImport(os)
    @_transparent
  #endif
  func reportIssue(
    _ error: any Error,
    _ message: @autoclosure () -> String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    runtimeWarn(
      "Caught error: \(error)\(message().map { ": \($0)" } ?? "")",
      fileID: fileID,
      line: line,
    )
  }

  #if canImport(os)
    @_transparent
    @inlinable
  #endif
  func runtimeWarn(
    _ message: @autoclosure () -> String?,
    fileID: StaticString,
    line: UInt
  ) {
    #if canImport(os)
      guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1"
      else {
        print("🟣 \(fileID):\(line): \(message() ?? "")")
        return
      }
      let moduleName = String(
        Substring("\(fileID)".utf8.prefix(while: { $0 != UTF8.CodeUnit(ascii: "/") }))
      )
      var message = message() ?? ""
      if message.isEmpty {
        message = "Issue reported"
      }
      os_log(
        .fault,
        dso: dso,
        log: OSLog(subsystem: "com.apple.runtime-issues", category: moduleName),
        "%@",
        "\(isTesting ? "\(fileID):\(line): " : "")\(message)"
      )
    #else
      fputs("\(message)\n", stderr)
    #endif
  }

  @usableFromInline nonisolated(unsafe) let dso: UnsafeRawPointer = {
    #if canImport(os)
      let count = _dyld_image_count()
      for i in 0..<count {
        if let name = _dyld_get_image_name(i) {
          let swiftString = String(cString: name)
          if swiftString.hasSuffix("/SwiftUI") {
            if let header = _dyld_get_image_header(i) {
              return UnsafeRawPointer(header)
            }
          }
        }
      }
    #endif
    return #dsohandle
  }()

  @usableFromInline let isTesting = ProcessInfo.processInfo.isTesting

  extension ProcessInfo {
    fileprivate var isTesting: Bool {
      if environment.keys.contains("XCTestBundlePath") { return true }
      if environment.keys.contains("XCTestBundleInjectPath") { return true }
      if environment.keys.contains("XCTestConfigurationFilePath") { return true }
      if environment.keys.contains("XCTestSessionIdentifier") { return true }

      return arguments.contains { argument in
        let path = URL(fileURLWithPath: argument)
        return path.lastPathComponent == "swiftpm-testing-helper"
          || argument == "--testing-library"
          || path.lastPathComponent == "xctest"
          || path.pathExtension == "xctest"
      }
    }
  }
#endif
