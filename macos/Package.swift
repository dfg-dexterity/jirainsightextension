// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JiraQuickTicket",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "JiraQuickTicket",
            path: "Sources/JiraQuickTicket"
        )
    ]
)
