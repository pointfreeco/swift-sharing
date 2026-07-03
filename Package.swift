// swift-tools-version: 6.1

import Foundation
import PackageDescription

let package = Package(
  name: "swift-sharing",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "Sharing",
      targets: ["Sharing"]
    )
  ],
  traits: [
    .trait(
      name: "CasePaths",
      description: "Derive Shared cases from Shared enums using CasePaths"
    ),
    .trait(
      name: "CustomDump",
      description: "Pretty-print and diff Sharing's data types using CustomDump"
    ),
    .trait(
      name: "IdentifiedCollections",
      description: "Derive Shared elements from Shared collections using IdentifiedCollections"
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.3"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.5.1"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-perception", "1.4.1"..<"3.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.3"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Sharing",
      dependencies: [
        "Sharing1",
        "Sharing2",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(
          name: "CustomDump",
          package: "swift-custom-dump",
          condition: .when(
            traits: ["CustomDump"]
          )
        ),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(
          name: "IdentifiedCollections",
          package: "swift-identified-collections",
          condition: .when(
            traits: ["IdentifiedCollections"]
          )
        ),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "PerceptionCore", package: "swift-perception"),
        .product(
          name: "CasePaths",
          package: "swift-case-paths",
          condition: .when(
            traits: ["CasePaths"]
          )
        ),
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "SharingTests",
      dependencies: [
        "Sharing",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
        .product(
          name: "CasePaths",
          package: "swift-case-paths",
          condition: .when(
            traits: ["CasePaths"]
          )
        ),
      ],
      exclude: ["Sharing.xctestplan"]
    ),
    .target(
      name: "Sharing1",
      path: "Sources/VersionMarkerModules/Sharing1"
    ),
    .target(
      name: "Sharing2",
      path: "Sources/VersionMarkerModules/Sharing2"
    ),
  ],
  swiftLanguageModes: [.v6]
)

let enableAllTraits = ProcessInfo.processInfo.environment["SPI_GENERATE_DOCS"] != nil
package.traits.insert(
  .default(
    enabledTraits: Set(
      enableAllTraits
        ? package.traits.map(\.name)
        : [
          "CustomDump",
          "IdentifiedCollections",
        ]
    )
  )
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ])
}
