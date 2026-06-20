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
            path: "Sources/WindowCycle",
            linkerSettings: [
                // Window previews call into the private SkyLight Window Server
                // capture API (CGSHWCaptureWindowList). SkyLight lives in
                // PrivateFrameworks, which is not on the default link path.
                .unsafeFlags([
                    "-F", "/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight"
                ])
            ]
        )
    ]
)
