// swift-tools-version:6.2
import Foundation
import PackageDescription

let package = Package(
  name: "TradierCLI",
  platforms: [
    .macOS(.v15),
    .macCatalyst(.v17),
  ],
  products: [
    .executable(name: "tradier-cli", targets: ["TradierCLI"])
  ],
  dependencies: [
    .package(
      name: "swift-tradier-lib",
      path: "../../public/universal/spm/domain/finance/swift-tradier-lib"
    ),
    .package(
      name: "common-log",
      path: "../../../swift-universal/private/universal/spm/domain/system/common-log"
    ),
    .package(
      name: "tradier-schemas-v000-001-000",
      path: "../../../schema-universal/private/universal/domain/finance/schema-families/tradier-schemas/v0.1.0/spm/tradier-schemas-v000-001-000"
    ),
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      from: "1.6.0",
    ),
  ],
  targets: [
    .executableTarget(
      name: "TradierCLI",
      dependencies: [
        .product(name: "TradierLib", package: "swift-tradier-lib"),
        .product(name: "CommonLog", package: "common-log"),
        .product(
          name: "Tradier_Schemas_v000_001_000",
          package: "tradier-schemas-v000-001-000"
        ),
      ],
    ),
    .testTarget(
      name: "TradierCLITests",
      dependencies: ["TradierCLI"],
    ),
  ],
)

// MARK: - Configuration Service

@MainActor
public struct ConfigurationService {
  public static let version = "1.0.0"

  public var swiftSettings: [SwiftSetting] = []
  var dependencies: [PackageDescription.Package.Dependency] = []

  public static let inject: ConfigurationService =
    ProcessInfo.useLocalDeps ? .local : .remote

  static var local: ConfigurationService = .init(swiftSettings: [
    .local
  ])
  static var remote: ConfigurationService = .init()
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// CONFIG_SERVICE_END_V1
