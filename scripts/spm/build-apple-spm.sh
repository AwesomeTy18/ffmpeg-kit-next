#!/usr/bin/env bash
# Build LGPL Apple XCFrameworks (iOS + macOS umbrella) with upstream --spm support.
# Run from the ffmpeg-kit-next source root (the checked-out upstream/fork tag).
#
# Optional external libraries (LGPL / non-GPL only):
#   EXTRA_LIB_FLAGS   — flags passed to both nix-ios.sh and nix-macos.sh
#   IOS_LIB_FLAGS     — iOS-only --enable-lib-* flags
#   MACOS_LIB_FLAGS   — macOS-only --enable-lib-* flags
# Additional args are appended to EXTRA_LIB_FLAGS.
set -euo pipefail

PROFILE="${NIX_PROFILE:-xcode26}"

split_flags() {
  # shellcheck disable=SC2206
  local -a out=()
  if [[ -n "${1:-}" ]]; then
    # Trusted CI values: space-separated --enable-lib-* flags
    out=($1)
  fi
  printf '%s\n' "${out[@]+"${out[@]}"}"
}

COMMON_FLAGS=()
IOS_FLAGS=()
MACOS_FLAGS=()

while IFS= read -r flag; do
  [[ -z "${flag}" ]] && continue
  COMMON_FLAGS+=("${flag}")
done < <(split_flags "${EXTRA_LIB_FLAGS:-}")

while IFS= read -r flag; do
  [[ -z "${flag}" ]] && continue
  IOS_FLAGS+=("${flag}")
done < <(split_flags "${IOS_LIB_FLAGS:-}")

while IFS= read -r flag; do
  [[ -z "${flag}" ]] && continue
  MACOS_FLAGS+=("${flag}")
done < <(split_flags "${MACOS_LIB_FLAGS:-}")

if [[ $# -gt 0 ]]; then
  COMMON_FLAGS+=("$@")
fi

refuse_gpl() {
  local flag
  for flag in "$@"; do
    case "${flag}" in
      --enable-gpl|--enable-lib-x264|--enable-lib-x265|--enable-lib-xvidcore|--enable-lib-libvidstab|--enable-lib-rubberband)
        echo "error: refusing GPL flag in LGPL SPM build: ${flag}" >&2
        exit 1
        ;;
    esac
  done
}

refuse_gpl "${COMMON_FLAGS[@]+"${COMMON_FLAGS[@]}"}" "${IOS_FLAGS[@]+"${IOS_FLAGS[@]}"}" "${MACOS_FLAGS[@]+"${MACOS_FLAGS[@]}"}"

IOS_ARGS=("${COMMON_FLAGS[@]+"${COMMON_FLAGS[@]}"}" "${IOS_FLAGS[@]+"${IOS_FLAGS[@]}"}")
MACOS_ARGS=("${COMMON_FLAGS[@]+"${COMMON_FLAGS[@]}"}" "${MACOS_FLAGS[@]+"${MACOS_FLAGS[@]}"}")

if [[ ${#IOS_ARGS[@]} -gt 0 || ${#MACOS_ARGS[@]} -gt 0 ]]; then
  echo "==> Optional external libraries (common): ${COMMON_FLAGS[*]:-(none)}"
  echo "==> Optional external libraries (iOS-only): ${IOS_FLAGS[*]:-(none)}"
  echo "==> Optional external libraries (macOS-only): ${MACOS_FLAGS[*]:-(none)}"
else
  echo "==> Optional external libraries: (none — default LGPL minimal build)"
fi

# Helper some apple scripts expect (harmless if unused).
echo "export DEVELOPER_DIR=$(xcode-select -p)" > "${HOME}/.xcode.for.ffmpeg.kit.sh"

echo "==> Building iOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-ios.sh -p "${PROFILE}" -x --spm ${IOS_ARGS[@]+"${IOS_ARGS[@]}"}

echo "==> Building macOS XCFrameworks (LGPL, SPM) with profile ${PROFILE}"
./nix-macos.sh -p "${PROFILE}" -x --spm ${MACOS_ARGS[@]+"${MACOS_ARGS[@]}"}

echo "==> Creating umbrella Apple XCFrameworks + local Package.swift (iOS+macOS only)"
# apple.sh defaults to ALL Apple platform variants (including tvOS/visionOS).
# We only built iOS + macOS, so disable the rest or the umbrella step fails
# looking for missing prebuilt frameworks.
# Do not pass --enable-lib-* here; umbrella aggregates already-built frameworks.
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
