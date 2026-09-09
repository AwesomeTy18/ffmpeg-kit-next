# Swift Package Manager (LGPL binaries)

This fork publishes **LGPL** Apple XCFrameworks for [arthenica/ffmpeg-kit-next](https://github.com/arthenica/ffmpeg-kit-next) and exposes them through Swift Package Manager.

## Add the package

**Xcode:** File → Add Package Dependencies… →  
`https://github.com/AwesomeTy18/ffmpeg-kit-next`

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/AwesomeTy18/ffmpeg-kit-next", from: "9.0.0")
]
```

Product to link: **`ffmpeg-kit`**.

Import the Objective-C module as `ffmpegkit` (same API as upstream Apple builds).

## How updates work

1. `.github/workflows/watch-upstream.yml` checks upstream releases twice daily.
2. When a new upstream tag has no SPM release assets here, it triggers `build-spm-release.yml`.
3. That workflow builds iOS + macOS XCFrameworks with Nix (`xcode26`, **no GPL**), zips them, updates root `Package.swift` checksums/URLs, retargets the version tag, and attaches the zips to a GitHub Release.

You can also run **Actions → Build and Publish SPM Release → Run workflow** and enter a tag like `v9.0.0`.

## First-time setup

1. Confirm this repository is **public** (SPM cannot download private binary assets with normal HTTPS).
2. Enable GitHub Actions on the fork.
3. Manually run **Build and Publish SPM Release** once for `v9.0.0` (or the latest upstream tag). The first build can take many hours on `macos-latest`.
4. After the release appears with `.xcframework.zip` assets and an updated `Package.swift`, resolve the package in Xcode.

## License

Binaries are built **without** `--enable-gpl` and remain under **LGPL 3.0**, matching upstream defaults. See [LICENSE](LICENSE) and upstream [Licenses and Notices](https://github.com/arthenica/ffmpeg-kit-next/wiki/Licenses-and-Notices).

## Tag note

On this fork, version tags such as `v9.0.0` are **moved** to the SPM packaging commit when a binary release is published (so SPM can resolve `Package.swift`). For the original source tree at that version, use [arthenica/ffmpeg-kit-next](https://github.com/arthenica/ffmpeg-kit-next).
