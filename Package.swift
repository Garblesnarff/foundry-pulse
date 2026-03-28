// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundryPulse",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FoundryPulse",
            targets: ["FoundryPulse"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FoundryPulse",
            path: "Sources"
        )
    ]
)
