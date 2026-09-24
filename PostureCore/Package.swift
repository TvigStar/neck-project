// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PostureCore",
    products: [
        .library(name: "PostureCore", targets: ["PostureCore"]),
    ],
    targets: [
        .target(name: "PostureCore"),
        .testTarget(name: "PostureCoreTests", dependencies: ["PostureCore"]),
    ]
)
