// swift-tools-version: 5.9
import PackageDescription
import Foundation

// XCTest requires full Xcode. To keep `swift build` working with Command Line Tools
// only, the test target is included solely when EXDISPLAY_TESTS=1 (set in CI, which
// has full Xcode). Locally: `swift build` always works; run tests with full Xcode via
//   EXDISPLAY_TESTS=1 swift test
let includeTests = ProcessInfo.processInfo.environment["EXDISPLAY_TESTS"] == "1"

var targets: [Target] = [
    // Pure-Swift wire protocol — no system frameworks, so it is unit-testable.
    .target(
        name: "ExDisplayCore",
        path: "Sources/ExDisplayCore"
    ),
    // Reverse-engineered private CoreGraphics header.
    .target(
        name: "CGVirtualDisplayBridge",
        path: "Sources/CGVirtualDisplayBridge",
        publicHeadersPath: "."
    ),
    // The app.
    .executableTarget(
        name: "ExDisplay",
        dependencies: ["CGVirtualDisplayBridge", "ExDisplayCore"],
        path: "Sources/ExDisplay",
        linkerSettings: [
            .linkedFramework("CoreGraphics"),
            .linkedFramework("Foundation")
        ]
    )
]

if includeTests {
    targets.append(
        .testTarget(
            name: "ExDisplayCoreTests",
            dependencies: ["ExDisplayCore"],
            path: "Tests/ExDisplayCoreTests"
        )
    )
}

let package = Package(
    name: "ExDisplay",
    platforms: [.macOS(.v14)],
    targets: targets
)
