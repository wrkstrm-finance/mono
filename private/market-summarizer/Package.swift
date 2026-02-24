// swift-tools-version:6.2
import Foundation
import PackageDescription

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if ProcessInfo.useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

let commonShellDependency = localOrRemote(
  path: "../../../../swift-universal/private/spm/universal/domain/system/common-shell",
  url: "https://github.com/swift-universal/common-shell.git",
  from: "0.0.1"
)
let commonCliDependency = localOrRemote(
  path: "../../../../swift-universal/private/spm/universal/domain/system/swift-common-cli",
  url: "https://github.com/swift-universal/swift-common-cli.git",
  from: "0.1.0"
)


let package = Package(
  name: "market-summarizer",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "eod-summary", targets: ["EODSummaryCLI"]),
    .library(name: "MarketSummarizer", targets: ["MarketSummarizer"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    commonShellDependency,
    commonCliDependency,
  ],
  targets: [
    .target(
      name: "MarketSummarizer",
      dependencies: [
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonCLI", package: "swift-common-cli"),
      ]
    ),
    .executableTarget(
      name: "EODSummaryCLI",
      dependencies: [
        "MarketSummarizer",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "MarketSummarizerTests",
      dependencies: ["MarketSummarizer"],
      swiftSettings: [
        // Use Swift Testing instead of XCTest
      ]
    ),
  ]
)

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return !(normalized == "0" || normalized == "false" || normalized == "no")
  }
}
