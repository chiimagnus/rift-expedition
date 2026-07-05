// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RiftCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "RiftCore", targets: ["RiftCore"])
    ],
    targets: [
        .target(name: "RiftCore"),
        .testTarget(
            name: "RiftCoreTests",
            dependencies: ["RiftCore"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
