// swift-tools-version:5.9
// For `swift test` and for opening the project in Xcode. The app bundle
// itself is built by build.sh.
import PackageDescription

let package = Package(
    name: "Spotch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Spotch", path: "Sources"),
        .executableTarget(name: "SpotchWatcher", path: "Watcher"),
        .testTarget(name: "SpotchTests", dependencies: ["Spotch"], path: "Tests"),
    ]
)
