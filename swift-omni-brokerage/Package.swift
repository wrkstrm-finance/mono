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
    localOrRemote(
      name: "CommonBroker",
      path: "../../../../../../../wrkstrm-finance/private/spm/universal/domain/finance/common-broker",
      url: "https://github.com/wrkstrm/common-broker.git",
      from: "0.1.0"
    ),
    localOrRemote(
      name: "swift-public-brokerage-lib",
      path:
        "../../../../../../../wrkstrm-finance/private/spm/universal/domain/finance/swift-public-brokerage-lib",
      url: "https://github.com/swift-universal/swift-public-brokerage-lib.git",
      from: "0.1.0"
    ),
    localOrRemote(
      name: "swift-tradier-lib",
      path: "../../../../../../../wrkstrm-finance/private/spm/universal/domain/finance/swift-tradier-lib",
      url: "https://github.com/swift-universal/swift-tradier-lib.git",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "OmniBrokerageLib",
      dependencies: [
        .product(name: "CommonBroker", package: "CommonBroker"),
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
