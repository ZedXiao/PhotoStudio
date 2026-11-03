#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/toolchain.sh"
cd "$PHOTOSTUDIO_ROOT"
swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --product PhotoStudioProbe
BIN_DIR="$(swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --show-bin-path)"
python3 script/validate_raw_samples.py "$BIN_DIR/PhotoStudioProbe"
