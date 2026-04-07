// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoodJournal",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MoodJournal",
            targets: ["MoodJournal"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MoodJournal",
            dependencies: [],
            path: "MoodJournal"),
    ]
)
