#!/bin/bash
# Build Silivue for distribution
# Usage: ./Scripts/build.sh

set -e

PROJECT_DIR=$(dirname "$(dirname "$0")")
BUILD_DIR="$PROJECT_DIR/build"

echo "📦 Building Silivue..."
echo "Working directory: $PROJECT_DIR"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build debug version
swift build --configuration release --build-path "$BUILD_DIR" 2>&1 || {
    echo "❌ Swift build failed, trying debug..."
    swift build --configuration debug --build-path "$BUILD_DIR"
}

# Find built executable
EXE=$(find "$BUILD_DIR" -name "Silivue" -type f | head -1)

if [ -z "$EXE" ]; then
    echo "❌ Executable not found!"
    exit 1
fi

echo ""
echo "✅ Build succeeded!"
echo "   Executable: $EXE"
echo ""

# Create distribution package
PKG_DIR="$BUILD_DIR/Silivue-Package"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"

# Copy executable and dependencies
EXE_NAME="Silivue"
cp "$EXE" "$PKG_DIR/$EXE_NAME"
cp "$PROJECT_DIR/Sources/StatusStats/Info.plist" "$PKG_DIR/Info.plist"
cp "$PROJECT_DIR/Sources/StatusStats/Silivue.icns" "$PKG_DIR/Silivue.icns"

# Create Assets folder
ASSETS_DIR="$PKG_DIR/Assets"
mkdir -p "$ASSETS_DIR"

# Copy Assets.xcassets if exists
if [ -d "$PROJECT_DIR/Sources/StatusStats/Assets.xcassets" ]; then
    cp -R "$PROJECT_DIR/Sources/StatusStats/Assets.xcassets" "$ASSETS_DIR/"
fi

# Create Distribution folder with instructions
DIST_DIR="$BUILD_DIR/Distribution"
mkdir -p "$DIST_DIR"
cp -R "$PKG_DIR" "$DIST_DIR/Silivue"

# Create README for distribution
cat > "$DIST_DIR/README.txt" << 'EOF'
Silivue - macOS Menu Bar System Monitor
============================================

Version: 1.0
Minimum macOS: 13.0 (Ventura)

HOW TO RUN:
-----------
1. Open Terminal
2. Navigate to this folder:
   cd ~/Downloads/Silivue   (or wherever you extracted)
3. Run:
   ./Silivue

Or double-click Silivue (you may need to allow in System Settings > Privacy & Security)

First Run:
- The app appears in the menu bar (top right)
- Click the icon to open the popover panel
- Go to Settings to configure refresh rate and display mode

To Quit:
- Right-click the menu bar icon → Quit

To Remove:
- Just delete this folder
EOF

echo ""
echo "📦 Distribution package created at:"
echo "   $DIST_DIR"
echo ""
ls -la "$DIST_DIR"
echo ""
echo "💡 Copy the entire 'Distribution' folder to other Macs to test."
