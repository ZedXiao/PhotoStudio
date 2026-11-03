#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/toolchain.sh"
cd "$PHOTOSTUDIO_ROOT"

./script/build_and_run.sh --build-only --configuration release
APP_BUNDLE="$PHOTOSTUDIO_ROOT/dist/PhotoStudio.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
MINIMUM_OS="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP_BUNDLE/Contents/Info.plist")"
ARCHITECTURES="$(lipo -archs "$APP_BUNDLE/Contents/MacOS/PhotoStudio")"
PACKAGE_NAME="PhotoStudio-${VERSION}-macOS${MINIMUM_OS%%.*}-${ARCHITECTURES// /-}"
PACKAGE_WORK="$(mktemp -d "$PHOTOSTUDIO_ROOT/.build/package.XXXXXX")"
trap 'rm -rf "$PACKAGE_WORK"' EXIT

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
mkdir -p "$PACKAGE_WORK/image"
ditto "$APP_BUNDLE" "$PACKAGE_WORK/image/PhotoStudio.app"
ln -s /Applications "$PACKAGE_WORK/image/Applications"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$PACKAGE_WORK/$PACKAGE_NAME.zip"
hdiutil create -volname PhotoStudio -srcfolder "$PACKAGE_WORK/image" -fs HFS+ -format UDZO "$PACKAGE_WORK/$PACKAGE_NAME.dmg"
hdiutil verify "$PACKAGE_WORK/$PACKAGE_NAME.dmg"
mv "$PACKAGE_WORK/$PACKAGE_NAME.dmg" "$PHOTOSTUDIO_ROOT/dist/"
mv "$PACKAGE_WORK/$PACKAGE_NAME.zip" "$PHOTOSTUDIO_ROOT/dist/"
(
  cd "$PHOTOSTUDIO_ROOT/dist"
  shasum -a 256 "$PACKAGE_NAME.dmg" "$PACKAGE_NAME.zip" > "$PACKAGE_NAME.sha256"
)
echo "Packaged: $PHOTOSTUDIO_ROOT/dist/$PACKAGE_NAME.dmg"
echo "Packaged: $PHOTOSTUDIO_ROOT/dist/$PACKAGE_NAME.zip"
echo "Checksums: $PHOTOSTUDIO_ROOT/dist/$PACKAGE_NAME.sha256"
echo "Local build: ad hoc signed; not Developer ID signed or notarized."
