// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WarpStatus",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "WarpStatus",
            targets: ["WarpStatus"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WarpStatus",
            dependencies: [],
            path: "Sources"
        ),
    ]
)