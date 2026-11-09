// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VirtualKeysPlease",
    platforms: [.macOS(.v13)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "VKPCrypto"),
        .target(name: "VirtualKeysPleaseKit", dependencies: ["VKPCrypto"]),
        .executableTarget(
            name: "VirtualKeysPlease",
            dependencies: ["VirtualKeysPleaseKit"],
            // App code runs on the main thread unless you say otherwise.
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "VirtualKeysPleaseKitTests", dependencies: ["VirtualKeysPleaseKit"]),
    ]
)
