// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "roundup-report",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "roundup-report", targets: ["RoundupReportCLI"])
  ],
  dependencies: [
    .package(name: "CommonShell", path: "../../../../../../../orgs/swift-universal/spm/universal/domain/system/common-shell"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
  ],
  targets: [
    .executableTarget(
      name: "RoundupReportCLI",
      dependencies: [
        .product(name: "CommonShell", package: "CommonShell"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    )
  ]
)
