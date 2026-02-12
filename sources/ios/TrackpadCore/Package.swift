// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "TrackpadCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v12)
    ],
    products: [
        .library(name: "TrackpadCore", targets: ["TrackpadCore"])
    ],
    targets: [
        .target(name: "TrackpadCore"),
        .testTarget(name: "TrackpadCoreTests", dependencies: ["TrackpadCore"])
    ]
)
