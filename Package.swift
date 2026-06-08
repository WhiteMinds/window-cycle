// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WindowCycle",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WindowCycle", targets: ["WindowCycle"])
    ],
    targets: [
        .executableTarget(
            name: "WindowCycle",
            path: "Sources/WindowCycle"
        )
    ]
)
