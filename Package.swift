// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tabular",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "Tabular",
            targets: ["Tabular"]),
    ],
    dependencies: [
      .package(url: "https://github.com/CoreOffice/CoreXLSX.git", .upToNextMajor(from: "0.14.2")),
    ],
    targets: [
        .target(
            name: "Tabular",
            dependencies: ["CoreXLSX"]
        ),
        .testTarget(
            name: "TabularTests",
            dependencies: ["Tabular"]),
    ]
)
