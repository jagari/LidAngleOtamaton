// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "LidAngleOtamaton",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "LidAngleOtamaton", targets: ["LidAngleOtamaton"])
    ],
    targets: [
        .executableTarget(
            name: "LidAngleOtamaton",
            path: "Sources/LidAngleOtamaton",
            linkerSettings: [
                .linkedFramework("CoreMotion"),
                .linkedFramework("AVFoundation")
            ]
        )
    ]
)
