// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacRecorder",
    // SCRecordingOutput (direct-to-file recording) requires macOS 15.
    // String form so swift-tools-version 5.9 accepts it (.v15 needs 6.0).
    platforms: [.macOS("15.0")],
    products: [
        .library(name: "MacRecorderCore", targets: ["MacRecorderCore"]),
    ],
    dependencies: [
        .package(path: "../HotkeyKit"),
    ],
    targets: [
        .target(
            name: "MacRecorderCore",
            dependencies: [.product(name: "HotkeyKit", package: "HotkeyKit")]
        ),
        .testTarget(name: "MacRecorderCoreTests", dependencies: ["MacRecorderCore"]),
    ]
)
