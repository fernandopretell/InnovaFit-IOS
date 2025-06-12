// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InnovaFit",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.9.8")
    ],
    targets: [
        .executableTarget(
            name: "InnovaFit",
            path: "InnovaFit"
        ),
        .testTarget(
            name: "InnovaFitTests",
            dependencies: ["InnovaFit", "ViewInspector"],
            path: "InnovaFitTests",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
