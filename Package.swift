// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Hearts",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "libHearts", targets: ["libHearts"]),
        .executable(name: "Hearts", targets: ["Hearts"]),
        .executable(name: "GenerateColors", targets: ["GenerateColors"]),
        .executable(name: "GenerateGroups", targets: ["GenerateGroups"]),
        .executable(name: "GenerateCharacters", targets: ["GenerateCharacters"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/jkandzi/Progress.swift.git", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.6.2"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "libCommon",
                resources: [.process("Localizable.xcstrings")]),
        .target(name: "libHearts",
                dependencies: ["libCommon"],
                resources: [
                    .copy("Resources/colors.json"),
                    .copy("Resources/groups.json"),
                    .process("Localizable.xcstrings")
                ]),
        .executableTarget(name: "Hearts",
                          dependencies: [
                            "libHearts",
                            .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ],
                          resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "HeartsTests",
                    dependencies: ["libHearts", "Nimble", "Quick"],
                    resources: [.process("Resources")]),
        .executableTarget(name: "GenerateColors",
                          dependencies: [
                            "libCommon",
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "Progress", package: "Progress.swift")
                          ],
                          resources: [.process("Resources")]),
        .executableTarget(name: "GenerateGroups",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ]),
        .executableTarget(name: "GenerateCharacters",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ])
    ],
    swiftLanguageModes: [.v6]
)
