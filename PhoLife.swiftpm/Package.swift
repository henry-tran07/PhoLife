// swift-tools-version: 6.0

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "PhoLife",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .iOSApplication(
            name: "PhoLife",
            targets: ["AppModule"],
            bundleIdentifier: "com.henrytran.PhoLife",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources/Sounds"),
                .process("Resources/Data")
            ]
        )
    ]
)
