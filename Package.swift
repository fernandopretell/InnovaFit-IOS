// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InnovaFit",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "InnovaFit",
            path: "InnovaFit"
        ),
        .testTarget(
            name: "InnovaFitTests",
            dependencies: ["InnovaFit"],
            path: "InnovaFitTests"
        )
    ]
)
