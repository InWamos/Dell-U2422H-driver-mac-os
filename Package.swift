// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "U2422HControl",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "CDDC",
            linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("CoreFoundation")]
        ),
        .executableTarget(name: "U2422HControl", dependencies: ["CDDC"]),
        .executableTarget(name: "ddc", dependencies: ["CDDC"]),
    ]
)
