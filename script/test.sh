#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/toolchain.sh"
cd "$PHOTOSTUDIO_ROOT"
swift test "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" "$@"
