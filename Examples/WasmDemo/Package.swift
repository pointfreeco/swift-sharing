// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "WasmDemo",
  platforms: [
    .macOS(.v14)
  ],
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.0.0"),
    .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.21.0"),
  ],
  targets: [
    .executableTarget(
      name: "WasmDemo",
      dependencies: [
        .product(name: "SwiftNavigation", package: "swift-navigation"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
        .product(name: "JavaScriptKit", package: "JavaScriptKit"),
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
