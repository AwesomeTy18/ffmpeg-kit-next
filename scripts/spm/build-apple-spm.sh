#!/usr/bin/env bash
# Build LGPL Apple XCFrameworks (iOS + macOS umbrella) with upstream --spm support.
# Run from the ffmpeg-kit-next source root (the checked-out upstream/fork tag).
set -euo pipefail

PROFILE="${NIX_PROFILE:-xcode26}"

# Helper some apple scripts expect (harmless if unused).
echo "export DEVELOPER_DIR=$(xcode-select -p)" > "${HOME}/.xcode.for.ffmpeg.kit.sh"

echo "==> Building iOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-ios.sh -p "${PROFILE}" -x --spm

echo "==> Building macOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-macos.sh -p "${PROFILE}" -x --spm

echo "==> Creating umbrella Apple XCFrameworks + local Package.swift (iOS+macOS only)"
# apple.sh defaults to ALL Apple platform variants (including tvOS/visionOS).
# We only built iOS + macOS, so disable the rest or the umbrella step fails
# looking for missing prebuilt frameworks.
./nix-apple.sh -p "${PROFILE}" --spm \
  --disable-arch-appletvos \
  --disable-arch-appletvsimulator \
  --disable-arch-xros \
  --disable-arch-xrsimulator

# Directory name includes enabled platform min-versions, e.g.
# umbrella-apple-xcframework-ios12.1-mac-catalyst14.0-macos10.15
UMBRELLA="$(find prebuilt -maxdepth 1 -type d -name 'umbrella-apple-xcframework*' | head -n 1 || true)"
if [[ -z "${UMBRELLA}" || ! -d "${UMBRELLA}" ]]; then
  echo "error: expected an umbrella-apple-xcframework* directory under prebuilt/" >&2
  ls -la prebuilt || true
  if [[ -f build.log ]]; then
    echo "---- tail build.log ----" >&2
    tail -n 80 build.log >&2 || true
  fi
  exit 1
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "UMBRELLA_DIR=${UMBRELLA}" >> "${GITHUB_OUTPUT}"
fi
echo "Built umbrella at ${UMBRELLA}"
ls -la "${UMBRELLA}"
