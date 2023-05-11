// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CohesionKit",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(
            name: "CohesionKit",
            targets: ["CohesionKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CohesionKit",
            dependencies: []),
        .testTarget(
            name: "CohesionKitTests",
            dependencies: ["CohesionKit"]),
    ]
)
