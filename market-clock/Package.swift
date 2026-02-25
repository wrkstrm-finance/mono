// swift-tools-version:6.1
import Foundation
import PackageDescription

let package = Package(
  name: "MarketClockKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .watchOS(.v11),
  ],
  products: [
    .library(name: "MarketClockKit", targets: ["MarketClockKit"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "MarketClockKit",
      path: "Sources",
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warn-long-expression-type-checking=10"])]
    ),
    .testTarget(
      name: "MarketClockKitTests",
      dependencies: ["MarketClockKit"],
      path: "tests/market-clock-kit-tests"
    ),
  ]
)
