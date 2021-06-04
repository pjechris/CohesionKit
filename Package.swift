// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CohesionKit",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(
            name: "CohesionKit",
            targets: ["CohesionKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CombineCommunity/CombineExt", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "CohesionKit",
            dependencies: ["CombineExt"]),
        .testTarget(
            name: "CohesionKitTests",
            dependencies: ["CohesionKit"]),
    ]
)
