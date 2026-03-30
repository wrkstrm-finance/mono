// swift-tools-version:6.1
import Foundation
import PackageDescription

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return false }
  let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return value == "1" || value == "true" || value == "yes"
}()

func localOrRemote(
  name: String,
  path: String,
  url: String,
  from version: Version
) -> Package.Dependency {
  if useLocalDeps { return .package(name: name, path: path) }
  return .package(url: url, from: version)
}

let package: Package = .init(
  name: "swift-omni-brokerage",
  platforms: [
    .iOS(.v17),
    .macOS(.v15),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(
      name: "OmniBrokerageLib",
      targets: ["OmniBrokerageLib"]
    ),
    .library(
      name: "OmniBroker",
      targets: ["OmniBrokerageLib"]
    ),
  ],
  dependencies: [
    .package(
      name: "common-broker-schemas-v000-001-000",
      path: "../../universal-schemas/private/universal/domain/finance/schema-families/common-broker-schemas/v0.1.0/spm/common-broker-schemas-v000-001-000"
    ),
    localOrRemote(
      name: "CommonBroker",
      path: "../public/universal/spm/domain/finance/common-broker",
      url: "https://github.com/wrkstrm-finance/common-broker.git",
      from: "0.1.3"
    ),
    localOrRemote(
      name: "swift-public-brokerage-lib",
      path: "../public/universal/spm/domain/finance/swift-public-brokerage-lib",
      url: "https://github.com/wrkstrm-finance/swift-public-brokerage-lib.git",
      from: "0.1.1"
    ),
    localOrRemote(
      name: "swift-tradier-lib",
      path: "../public/universal/spm/domain/finance/swift-tradier-lib",
      url: "https://github.com/wrkstrm-finance/swift-tradier-lib.git",
      from: "0.2.3"
    ),
  ],
  targets: [
    .target(
      name: "OmniBrokerageLib",
      dependencies: [
        .product(name: "CommonBroker", package: "CommonBroker"),
        .product(
          name: "CommonBrokerSchemas_v000_001_000",
          package: "common-broker-schemas-v000-001-000"
        ),
        .product(name: "PublicBrokerageCommonAdapters", package: "swift-public-brokerage-lib"),
        .product(name: "PublicBrokerageLib", package: "swift-public-brokerage-lib"),
        .product(name: "TradierBrokerageCommonAdapters", package: "swift-tradier-lib"),
      ],
      path: "Sources/OmniBrokerageLib"
    ),
    .testTarget(
      name: "OmniBrokerageLibTests",
      dependencies: ["OmniBrokerageLib"],
      path: "Tests/OmniBrokerageLibTests",
      resources: [.process("Resources")]
    ),
  ]
)
