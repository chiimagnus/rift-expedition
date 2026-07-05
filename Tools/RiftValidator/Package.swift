// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RiftValidator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "RiftValidator", targets: ["RiftValidator"])
    ],
    targets: [
        .executableTarget(name: "RiftValidator"),
        .testTarget(
            name: "RiftValidatorTests",
            dependencies: ["RiftValidator"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
