// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PuzzleAlarm",
    platforms: [.macOS(.v13)],
    products: [.library(name: "PuzzleAlarmCore", targets: ["PuzzleAlarmCore"])],
    targets: [
        .target(name: "PuzzleAlarmCore", path: "PuzzleAlarmCore/Sources/PuzzleAlarmCore"),
        .testTarget(
            name: "PuzzleAlarmCoreTests",
            dependencies: ["PuzzleAlarmCore"],
            path: "PuzzleAlarmCore/Tests/PuzzleAlarmCoreTests"
        )
    ]
)
