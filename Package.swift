// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdBlocker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AdBlocker",
            targets: ["AdBlocker"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AdBlocker",
            dependencies: [],
            path: "Sources/AdBlocker"
        )
    ]
)
