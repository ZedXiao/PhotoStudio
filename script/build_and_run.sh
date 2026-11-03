#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/toolchain.sh"
cd "$PHOTOSTUDIO_ROOT"
MODE="run"
CONFIGURATION="debug"
APP_NAME="PhotoStudio"
APP_BUNDLE="$PHOTOSTUDIO_ROOT/dist/$APP_NAME.app"
usage() { echo "usage: $0 [run|--build-only|--verify|--debug|--logs|--telemetry] [--configuration debug|release]" >&2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify|--build-only)
      MODE="$1"; shift ;;
    --configuration)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      CONFIGURATION="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
case "$CONFIGURATION" in
  debug|release) ;;
  *) usage; exit 2 ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
if [[ ! -f Resources/AppIcon.icns || ! -f Resources/AppIcon.png || script/generate_icon.swift -nt Resources/AppIcon.icns || Resources/AppIconArtwork.png -nt Resources/AppIcon.icns ]]; then
  swift script/generate_icon.swift "$PHOTOSTUDIO_ROOT/Resources"
fi
swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --configuration "$CONFIGURATION" --product PhotoStudio
BIN_DIR="$(swift build "${PHOTOSTUDIO_SWIFT_FLAGS[@]}" --configuration "$CONFIGURATION" --show-bin-path)"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp -R "$BIN_DIR/PhotoStudio_PhotoStudio.bundle" "$APP_BUNDLE/Contents/Resources/"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
codesign --force --deep --sign - "$APP_BUNDLE"
echo "Built: $APP_BUNDLE"
open_app() { /usr/bin/open -n "$APP_BUNDLE"; }
case "$MODE" in
  --build-only) ;;
  run) open_app ;;
  --debug|debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs|logs) open_app; /usr/bin/log stream --info --style compact --predicate 'process == "PhotoStudio"' ;;
  --telemetry|telemetry) open_app; /usr/bin/log stream --info --style compact --predicate 'subsystem == "app.photostudio.mac"' ;;
  --verify|verify) open_app; sleep 1; pgrep -x "$APP_NAME" >/dev/null; echo "PhotoStudio is running." ;;
esac
