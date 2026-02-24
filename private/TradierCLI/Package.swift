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
      path: "../../../../wrkstrm-finance/private/spm/universal/domain/finance/swift-tradier-lib"
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
        "TradierLib"
        //            .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        //            .product(name: "WrkstrmNetworking", package: "wrkstrm-foundation"),
        //            .product(name: "CommonLog", package: "common-log"),
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
