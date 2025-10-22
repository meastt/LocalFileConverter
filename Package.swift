// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalFileConverter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LocalFileConverter",
            targets: ["LocalFileConverter"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LocalFileConverter",
            dependencies: [],
            path: "Sources"
        )
    ]
)
