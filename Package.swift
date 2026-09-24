// swift-tools-version:6.2

import PackageDescription

// Two products, one dependency direction: SwiftGovInfoDocumentsModels describes GovInfo's API
// and depends on nothing, so a consumer with a networking stack of its own can take it alone, and
// SwiftGovInfoDocuments sends those descriptions through swifty-networking.
let package = Package(
  name: "swift-govinfo",
  platforms: [
    .iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
  ],
  products: [
    .library(name: "SwiftGovInfoDocuments", targets: ["SwiftGovInfoDocuments"]),
    .library(name: "SwiftGovInfoDocumentsModels", targets: ["SwiftGovInfoDocumentsModels"]),
  ],
  traits: [
    // Nothing is on by default, stated at the declaration site rather than left to SwiftPM's implicit
    // empty default: an Apple consumer sends through URLSession and never fetches the SwiftNIO stack.
    .default(enabledTraits: []),
    .trait(
      name: "HTTPPortable",
      description:
        "Send through swifty-networking's AsyncHTTPClient transport on Linux and Android."
    ),
  ],
  dependencies: [
    // Streaming source receipts use the maintained portable SHA-256 implementation.
    .package(url: "https://github.com/apple/swift-crypto.git", from: "4.0.0"),
    // HTTPCore's requests and responses carry their header fields as swift-http-types values, and
    // HTTPCore does not re-export the module, so the SDK names the dependency it uses. The floor is
    // swifty-networking's own, so the graph does not change.
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.6.0"),
    // The trait of the same name is forwarded only while this package's own `HTTPPortable` trait is
    // enabled, so the AsyncHTTPClient and SwiftNIO packages behind it are resolved for no one else.
    .package(
      url: "https://github.com/KalebCooper/swifty-networking.git",
      from: "1.3.1",
      traits: [.trait(name: "HTTPPortable", condition: .when(traits: ["HTTPPortable"]))]
    ),
  ],
  targets: [
    // `HTTPURLSession` compiles only on Apple platforms, and `HTTPPortable` is an empty module unless
    // its trait is enabled, so each edge is conditioned on the case where the module has content.
    .target(
      name: "SwiftGovInfoDocuments",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "HTTPCore", package: "swifty-networking"),
        .product(
          name: "HTTPPortable", package: "swifty-networking",
          condition: .when(traits: ["HTTPPortable"])),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(
          name: "HTTPURLSession", package: "swifty-networking",
          condition: .when(platforms: [.iOS, .macCatalyst, .macOS, .tvOS, .visionOS, .watchOS])),
        "SwiftGovInfoDocumentsModels",
      ],
      swiftSettings: swiftSettings
    ),
    .target(name: "SwiftGovInfoDocumentsModels", swiftSettings: swiftSettings),
    // Support shared by the test targets: responses recorded from the live API, and the suite time
    // limit. It is in no product, so nothing here reaches a consumer.
    .target(
      name: "SwiftGovInfoDocumentsTestSupport",
      resources: [.copy("Fixtures")],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SwiftGovInfoDocumentsModelsTests",
      dependencies: ["SwiftGovInfoDocumentsModels", "SwiftGovInfoDocumentsTestSupport"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SwiftGovInfoDocumentsTests",
      dependencies: [
        .product(name: "HTTPCore", package: "swifty-networking"),
        .product(name: "HTTPTesting", package: "swifty-networking"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        "SwiftGovInfoDocuments",
        "SwiftGovInfoDocumentsModels",
        "SwiftGovInfoDocumentsTestSupport",
      ],
      swiftSettings: swiftSettings
    ),
  ],
  swiftLanguageModes: [.v6]
)

// Library code is nonisolated by default (the inverse of an app target's MainActor default), async
// entry points run on the caller's actor until they truly suspend, and every `unsafe` is spelled out.
var swiftSettings: [SwiftSetting] {
  [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
  ]
}
