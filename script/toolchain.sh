#!/usr/bin/env bash
# Sourced by project scripts; keep caches inside the workspace.
PHOTOSTUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export MACOSX_DEPLOYMENT_TARGET=26.0
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
PHOTOSTUDIO_SDK_VERSION="$(xcrun --sdk macosx --show-sdk-version)"
if [[ "${PHOTOSTUDIO_SDK_VERSION%%.*}" -lt 26 ]]; then
  echo "PhotoStudio requires Xcode 26 or later and the macOS 26 SDK." >&2
  return 1
fi
export CLANG_MODULE_CACHE_PATH="$PHOTOSTUDIO_ROOT/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PHOTOSTUDIO_ROOT/.build/ModuleCache"
PHOTOSTUDIO_SWIFT_FLAGS=(--disable-sandbox --cache-path "$PHOTOSTUDIO_ROOT/.build/Cache" --config-path "$PHOTOSTUDIO_ROOT/.build/Configuration" --security-path "$PHOTOSTUDIO_ROOT/.build/Security")
