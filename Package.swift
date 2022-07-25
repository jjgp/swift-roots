// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Roots",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Roots",
            targets: ["Roots"]
        ),
        .library(
            name: "RootsTest",
            targets: ["RootsTest"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Roots",
            dependencies: []
        ),
        .target(
            name: "RootsTest",
            dependencies: ["Roots"]
        ),
        .testTarget(
            name: "RootsTests",
            dependencies: ["Roots", "RootsTest"]
        ),
    ]
)
