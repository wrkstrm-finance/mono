// swift-tools-version:6.1
import Foundation
import PackageDescription

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
  let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return !(value == "0" || value == "false" || value == "no")
}()

func localOrRemote(path: String, url: String, from version: Version) -> Package.Dependency {
  if useLocalDeps { return .package(path: path) }
  return .package(url: url, from: version)
}

let package: Package = .init(
  name: "TastyTradeLib",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .macCatalyst(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(name: "TastyTradeLib", targets: ["TastyTradeLib"])
  ],
  dependencies: [
    localOrRemote(
      path: "../../../../../../../wrkstrm/private/spm/universal/domain/system/wrkstrm-foundation",
      url: "https://github.com/wrkstrm/wrkstrm-foundation.git",
      from: "3.0.0"
    ),
    localOrRemote(
      path: "../../../../../../../wrkstrm/private/spm/universal/domain/system/wrkstrm-networking",
      url: "https://github.com/wrkstrm/wrkstrm-networking.git",
      from: "3.0.0"
    ),
    localOrRemote(
      path: "../../../../../../../../modules/swift-universal/private/spm/universal/domain/system/common-log",
      url: "https://github.com/swift-universal/common-log.git",
      from: "3.0.0"
    ),
  ],
  targets: [
    .target(
      name: "TastyTradeLib",
      dependencies: [
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "WrkstrmNetworking", package: "wrkstrm-networking"),
        .product(name: "CommonLog", package: "common-log"),
      ],
    ),
    .testTarget(
      name: "TastyTradeLibTests",
      dependencies: ["TastyTradeLib"],
      resources: [.process("Resources")],
    ),
  ],
)
