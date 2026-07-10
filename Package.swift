// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SkillsBar",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SkillsBarCore", targets: ["SkillsBarCore"]),
        .executable(name: "SkillsBar", targets: ["SkillsBar"])
    ],
    targets: [
        .target(name: "SkillsBarCore"),
        .executableTarget(
            name: "SkillsBar",
            dependencies: ["SkillsBarCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SkillsBarCoreTests",
            dependencies: ["SkillsBarCore"]
        ),
        .testTarget(
            name: "SkillsBarTests",
            dependencies: ["SkillsBar", "SkillsBarCore"],
            resources: [.process("Fixtures")]
        )
    ]
)
