// swift-tools-version:6.2
import Foundation
import PackageDescription

private func envBool(_ key: String) -> Bool {
  guard let raw = ProcessInfo.processInfo.environment[key] else { return false }
  let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return normalized == "1" || normalized == "true" || normalized == "yes"
}

private let packageDir: URL = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()

private func resolvedPath(_ path: String) -> String {
  if path.hasPrefix("/") { return path }
  return packageDir.appendingPathComponent(path).standardizedFileURL.path
}

private func pathExists(_ path: String) -> Bool {
  FileManager.default.fileExists(atPath: resolvedPath(path))
}

private let commonBrokerPath = "../common-broker"
private let alpacaSchemasPath =
  "../../../../../../../schema-universal/private/universal/domain/finance/schema-families/alpaca-schemas/v0.1.0/spm/alpaca-schemas-v000-001-000"

private let schemaPublishedGitHubOrg: String = {
  let value = ProcessInfo.processInfo.environment["SCHEMA_PUBLISHED_GITHUB_ORG"]?
    .trimmingCharacters(in: .whitespacesAndNewlines)
  if let value, !value.isEmpty {
    return value
  }
  return "schema-universal"
}()

private let alpacaSchemasRemoteURL =
  "https://github.com/\(schemaPublishedGitHubOrg)/alpaca-schemas-v000-001-000.git"

private let useLocalDeps: Bool = {
  if ProcessInfo.processInfo.environment["SPM_CI_USE_LOCAL_DEPS"] != nil {
    return envBool("SPM_CI_USE_LOCAL_DEPS")
  }

  if ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] != nil {
    return envBool("SPM_USE_LOCAL_DEPS")
  }

  return pathExists(commonBrokerPath)
}()

private func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if useLocalDeps {
    return .package(path: resolvedPath(path))
  }
  return .package(url: url, from: version)
}

private let commonLogDependency = localOrRemote(
  path: "../../../../../../../swift-universal/private/universal/spm/domain/system/common-log",
  url: "https://github.com/swift-universal/common-log.git",
  from: "3.0.0"
)

private let wrkstrmNetworkingDependency = localOrRemote(
  path: "../../../../../../../wrkstrm/private/universal/spm/domain/system/wrkstrm-networking",
  url: "https://github.com/wrkstrm/wrkstrm-networking.git",
  from: "3.0.5"
)

let package: Package = .init(
  name: "swift-alpaca-lib",
  platforms: [
    .iOS(.v17),
    .macOS(.v15),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(name: "AlpacaLib", targets: ["AlpacaLib"]),
    .library(name: "AlpacaBrokerageCommonAdapters", targets: ["AlpacaBrokerageCommonAdapters"]),
  ],
  dependencies: [
    localOrRemote(
      path: alpacaSchemasPath,
      url: alpacaSchemasRemoteURL,
      from: "0.1.1"
    ),
    localOrRemote(
      path: commonBrokerPath,
      url: "https://github.com/wrkstrm-finance/common-broker.git",
      from: "0.1.8"
    ),
    commonLogDependency,
    wrkstrmNetworkingDependency,
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"),
  ],
  targets: [
    .target(
      name: "AlpacaLib",
      dependencies: [
        .product(
          name: "AlpacaSchemas_v000_001_000",
          package: "alpaca-schemas-v000-001-000"
        ),
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "WrkstrmNetworking", package: "wrkstrm-networking"),
      ],
      path: "sources/AlpacaLib"
    ),
    .target(
      name: "AlpacaBrokerageCommonAdapters",
      dependencies: [
        "AlpacaLib",
        .product(name: "CommonBroker", package: "common-broker"),
      ],
      path: "sources/alpaca-brokerage-common-adapters"
    ),
    .testTarget(
      name: "AlpacaLibTests",
      dependencies: ["AlpacaLib"],
      path: "tests/AlpacaLibTests",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "AlpacaBrokerageCommonAdaptersTests",
      dependencies: [
        "AlpacaBrokerageCommonAdapters",
        "AlpacaLib",
        .product(name: "CommonBroker", package: "common-broker"),
      ],
      path: "tests/AlpacaBrokerageCommonAdaptersTests",
      resources: [.process("Resources")]
    ),
  ]
)
