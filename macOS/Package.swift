// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DroidLink",
    defaultLocalization: "tr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DroidLink", targets: ["DroidLink"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DroidLink",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DroidLinkTests",
            dependencies: ["DroidLink"],
            path: "Tests"
        )
    ]
)
