// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "tangent-tui",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/rensbreur/SwiftTUI", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "tangent-tui",
            dependencies: ["SwiftTUI"],
            path: "tui"
        )
    ]
)
