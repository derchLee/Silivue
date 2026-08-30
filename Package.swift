// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Silivue",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Silivue", targets: ["Silivue"]),
        .library(name: "MonitorEngine", targets: ["MonitorEngine"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
    ],
    targets: [
        // MARK: - App
        .executableTarget(
            name: "Silivue",
            dependencies: ["MonitorEngine", "DataLayer", "UIComponents"],
            path: "Sources/StatusStats",
            exclude: ["Info.plist"],
            resources: [.process("Assets.xcassets"), .copy("Silivue.icns")],
            linkerSettings: [.linkedFramework("CoreLocation")]
        ),

        // MARK: - MonitorEngine
        .target(
            name: "MonitorEngine",
            dependencies: [],
            linkerSettings: [.linkedFramework("IOKit"), .linkedFramework("CoreWLAN")]
        ),
        .testTarget(
            name: "MonitorEngineTests",
            dependencies: ["MonitorEngine"]
        ),

        
        
        
        // MARK: - DataLayer
        .target(
            name: "DataLayer",
            dependencies: ["MonitorEngine"],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),

        // MARK: - UIComponents
        .target(
            name: "UIComponents",
            dependencies: ["MonitorEngine", "DataLayer"]
        ),
        .testTarget(
            name: "UIComponentsTests",
            dependencies: ["UIComponents"]
        ),
    ]
)
