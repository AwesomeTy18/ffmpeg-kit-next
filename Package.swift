// swift-tools-version:5.7
// Placeholder until the "Build and Publish SPM Release" workflow succeeds.
// See SPM.md for usage. After the first publish, this file lists remote binaryTargets.
import PackageDescription

let package = Package(
    name: "ffmpeg-kit",
    platforms: [
        .iOS("12.1"),
        .macOS("10.15")
    ],
    products: [
        .library(name: "ffmpeg-kit", targets: ["FFmpegKitSPMPlaceholder"])
    ],
    targets: [
        .target(
            name: "FFmpegKitSPMPlaceholder",
            path: "scripts/spm/StubPlaceholder"
        )
    ]
)
