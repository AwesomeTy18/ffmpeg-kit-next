#!/usr/bin/env bash
# Build LGPL Apple XCFrameworks (iOS + macOS umbrella) with upstream --spm support.
# Run from the ffmpeg-kit-next source root (the checked-out upstream/fork tag).
set -euo pipefail

PROFILE="${NIX_PROFILE:-xcode26}"

echo "==> Building iOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-ios.sh -p "${PROFILE}" -x --spm

echo "==> Building macOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-macos.sh -p "${PROFILE}" -x --spm

echo "==> Creating umbrella Apple XCFrameworks + local Package.swift"
./nix-apple.sh -p "${PROFILE}" --spm

UMBRELLA="$(pwd)/prebuilt/umbrella-apple-xcframework"
if [[ ! -d "${UMBRELLA}" ]]; then
  echo "error: expected umbrella at ${UMBRELLA}" >&2
  ls -la prebuilt || true
  exit 1
fi

echo "UMBRELLA_DIR=${UMBRELLA}" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "Built umbrella at ${UMBRELLA}"
ls -la "${UMBRELLA}"
