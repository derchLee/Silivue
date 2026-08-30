#!/bin/bash
# Build Silivue as .app bundle + .pkg + .dmg for distribution
# Requirements: Mac with Xcode/Command Line Tools installed

set -e
PROJECT_DIR="/Users/lidongqiang/Desktop/mactoolbar"
SPM_BUILD_DIR="$PROJECT_DIR/.build"  # SPM defaults to .build/
DIST_DIR="$PROJECT_DIR/dist-output"  # Output goes to project root

echo "=========================================="
echo "  Silivue Distribution Builder"
echo "=========================================="
echo ""

# Clean
echo "🧹 Cleaning previous builds..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ============ 1. Build with SPM ============
echo ""
echo "📦 Step 1: Building with Swift Package Manager..."
cd "$PROJECT_DIR"
swift build --configuration release 2>&1 | grep -E "error:|warning:|Build complete" || true

# Find executable
# Find executable
EXE=$(find "$SPM_BUILD_DIR" -name "Silivue" -type f -path "*/release/*" | grep -v ".dSYM" | head -1)

if [ -z "$EXE" ]; then
    echo "❌ Build failed - executable not found"
    exit 1
fi

echo "✅ Build succeeded: $EXE"

# ============ 2. Create .app bundle structure ============
echo ""
echo "🗂  Step 2: Creating .app bundle structure..."

APP_DIR="$DIST_DIR/Silivue.app"
rm -rf "$APP_DIR"

# Create standard macOS app bundle structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp "$EXE" "$APP_DIR/Contents/MacOS/Silivue"
chmod +x "$APP_DIR/Contents/MacOS/Silivue"

# Copy Info.plist
cp "$PROJECT_DIR/Sources/StatusStats/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Sources/StatusStats/Silivue.icns" "$APP_DIR/Contents/Resources/Silivue.icns"

# Copy Assets
if [ -d "$PROJECT_DIR/Sources/StatusStats/Assets.xcassets" ]; then
    cp -R "$PROJECT_DIR/Sources/StatusStats/Assets.xcassets" "$APP_DIR/Contents/Resources/"
fi

# Create Entitlements (required for IOKit/CoreWLAN)
ENTITLEMENTS="$PROJECT_DIR/Config/Silivue.entitlements"

echo "✅ App bundle created: $APP_DIR"

# ============ 3. Code Sign ============
echo ""
echo "🔏 Step 3: Code signing..."

# Check for Developer ID certificate
DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development\|Developer ID" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -n "$DEVELOPER_ID" ]; then
    echo "🔐 Signing with Developer ID: $DEVELOPER_ID"
    # security already returns the complete identity, e.g.
    # "Developer ID Application: Your Name (TEAMID)".
    codesign_result=$(codesign --deep --force --sign "$DEVELOPER_ID" \
        --entitlements "$ENTITLEMENTS" \
        --options runtime \
        "$APP_DIR" 2>&1)
    echo "$codesign_result"
    SIGNED=1
else
    echo "⚠️  No Developer ID certificate found. Using ad-hoc signing..."
        echo "   (Unsigned apps show 'unidentified developer' warning on other Macs)"
        echo "   To fix: enroll in Apple Developer Program ($99/year)"
        codesign --deep --force --sign - \
            --entitlements "$ENTITLEMENTS" \
            --options runtime \
            "$APP_DIR" 2>&1 || echo "   (ad-hoc signing applied)"
        SIGNED=1
fi

# ============ 4. Create .pkg installer ============
echo ""
echo "📦 Step 4: Creating .pkg installer..."

PKG_PATH="$DIST_DIR/Silivue-1.0.pkg"
rm -f "$PKG_PATH"

if [ "$SIGNED" = "1" ]; then
    PKG_SIGN_ARGS=()
    if [ -n "$DEVELOPER_ID" ]; then
        PKG_SIGN_ARGS=(--sign "$DEVELOPER_ID")
    fi
    pkgbuild --analyze --plist "$APP_DIR" "$DIST_DIR/tmp-plist.plist" 2>/dev/null || true
    pkgbuild --root "$APP_DIR" \
        --identifier "com.upupdays.silivue" \
        --version "1.0" \
        --install-location "/Applications" \
        "${PKG_SIGN_ARGS[@]}" \
        "$PKG_PATH" 2>&1 || {
            echo "   pkgbuild failed, creating unsigned..."
            pkgbuild --root "$APP_DIR" \
                --identifier "com.upupdays.silivue" \
                --version "1.0" \
                --install-location "/Applications" \
                "$PKG_PATH"
        }
else
    pkgbuild --root "$APP_DIR" \
        --identifier "com.upupdays.silivue" \
        --version "1.0" \
        --install-location "/Applications" \
        "$PKG_PATH" 2>&1
fi

echo "✅ PKG created: $PKG_PATH"

# ============ 5. Create .dmg ============
echo ""
echo "💿 Step 5: Creating .dmg..."

DMG_PATH="$DIST_DIR/Silivue-1.0.dmg"
rm -f "$DMG_PATH"

# Create a temp directory with app + readme
DMG_ROOT="$DIST_DIR/dmg-root"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"

# Copy app
cp -R "$APP_DIR" "$DMG_ROOT/Silivue.app"

# Copy README
cat > "$DMG_ROOT/Install Silivue.txt" << 'README'
Silivue - macOS Menu Bar System Monitor
============================================

Version 1.0 | macOS 13.0+

INSTALLATION:
1. Double-click "Silivue.pkg" to install
2. Follow the installer prompts
3. Find Silivue in your menu bar (top right)

OR simply drag "Silivue.app" to Applications folder.

If you see a security warning:
- Go to System Settings > Privacy & Security
- Find "Silivue" and click "Open Anyway"

TROUBLESHOOTING:
- Quit: Right-click the menu bar icon → Quit
- Restart: Re-run the installer or drag app back to Applications
README

# Create DMG using hdiutil
hdiutil create -volname "Silivue 1.0" \
    -srcfolder "$DMG_ROOT" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1

echo "✅ DMG created: $DMG_PATH"

# ============ Summary ============
echo ""
echo "=========================================="
echo "  ✅ Distribution package ready!"
echo "=========================================="
echo ""
echo "Output files:"
ls -lh "$DIST_DIR"
echo ""
echo "💿 DMG: $DMG_PATH"
echo "📦 PKG: $PKG_PATH"
echo ""
echo "To share with others:"
echo "  1. Upload the .dmg or .pkg to a cloud service"
echo "  2. Or copy to a USB drive"
echo ""
if [ "$SIGNED" != "1" ]; then
    echo "⚠️  NOTE: App is NOT code-signed."
    echo "   Recipients will need to approve in System Settings > Privacy & Security."
    echo "   To fix this: enroll in Apple Developer Program ($99/year) and use"
    echo "   'Developer ID Application' certificate to sign before creating packages."
fi
