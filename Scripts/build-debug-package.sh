#!/bin/bash

set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOGIN_KEYCHAIN="/Users/lidongqiang/Library/Keychains/login.keychain-db"
BUILD_DIR="$PROJECT_DIR/.build-debug-package"
DIST_DIR="$PROJECT_DIR/debug-output"
APP_DIR="$DIST_DIR/Silivue-Debug.app"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$DIST_DIR/Silivue-Debug.dmg"

echo "Building Silivue (Debug)..."
swift build \
    --package-path "$PROJECT_DIR" \
    --configuration debug \
    --build-path "$BUILD_DIR"

EXECUTABLE=$(find "$BUILD_DIR" -type f -path "*/debug/Silivue" -perm -111 | head -1)
if [ -z "$EXECUTABLE" ]; then
    echo "Silivue debug executable was not found."
    exit 1
fi

rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/Silivue"
cp "$PROJECT_DIR/Sources/StatusStats/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Sources/StatusStats/Silivue.icns" "$APP_DIR/Contents/Resources/Silivue.icns"

# SwiftPM emits processed resources as bundles next to the executable.
while IFS= read -r resource_bundle; do
    cp -R "$resource_bundle" "$APP_DIR/Contents/Resources/"
done < <(find "$(dirname "$EXECUTABLE")" -maxdepth 1 -type d -name '*.bundle')

# Do not let Finder/provenance metadata become part of the signed bundle.
xattr -cr "$APP_DIR"

SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F '"' '/Apple Development:|Developer ID Application:/ { print $2; exit }')

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "Signing with $SIGNING_IDENTITY"
    codesign --force --deep --options runtime --timestamp \
        --keychain "$LOGIN_KEYCHAIN" \
        --entitlements "$PROJECT_DIR/Config/Silivue.entitlements" \
        --sign "$SIGNING_IDENTITY" "$APP_DIR"
else
    echo "No Apple Development or Developer ID Application identity found; applying ad-hoc signature."
    codesign --force --deep \
        --entitlements "$PROJECT_DIR/Config/Silivue.entitlements" \
        --sign - "$APP_DIR"
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/Silivue-Debug.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "Silivue Debug" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "Debug package created:"
echo "  App: $APP_DIR"
echo "  DMG: $DMG_PATH"
