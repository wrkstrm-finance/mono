// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "SwiftDerivativesPricing",
  platforms: [
    .macOS(.v11)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SwiftDerivativesPricing",
      targets: ["SwiftDerivativesPricing"],
    )
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftDerivativesPricing",
    ),
    .testTarget(
      name: "SwiftDerivativesPricingTests",
      dependencies: ["SwiftDerivativesPricing"],
    ),
  ],
)
