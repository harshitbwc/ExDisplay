#!/bin/bash
# Builds ExDisplay.app — run this once, then double-click the app forever after.
set -eo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/ExDisplay.app"
BUNDLE_ID="com.exdisplay.app"
VERSION="$(cat "$DIR/../VERSION" 2>/dev/null | tr -d '[:space:]')"
VERSION="${VERSION:-0.0.0}"
echo "ExDisplay version $VERSION"

echo "==> [1/3] Building binary..."
cd "$DIR"
swift build -c release

echo "==> [2/3] Assembling app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$DIR/.build/release/ExDisplay" "$APP/Contents/MacOS/"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleName</key>              <string>ExDisplay</string>
    <key>CFBundleDisplayName</key>       <string>ExDisplay</string>
    <key>CFBundleIdentifier</key>        <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>           <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleExecutable</key>        <string>ExDisplay</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>LSMinimumSystemVersion</key>    <string>14.0</string>
    <key>LSUIElement</key>               <true/>
    <key>NSPrincipalClass</key>          <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>   <true/>
</dict></plist>
PLIST

echo "==> [3/3] Signing (ad-hoc)..."
codesign --force --deep --sign - --entitlements "$DIR/entitlements.plist" "$APP"

# Clear stale TCC entries so the new binary gets a clean permission prompt.
# (Each rebuild changes the binary hash -> old entry becomes invalid -> must reset.)
echo "Clearing stale TCC entries for ${BUNDLE_ID}..."
tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null || true
tccutil reset ScreenCapture "${BUNDLE_ID}" 2>/dev/null || true

echo ""
echo "Built: $APP"
echo ""
echo "To install / update:"
echo "   cp -r ExDisplay.app /Applications/"
echo "   open /Applications/ExDisplay.app"
echo ""
echo "Grant BOTH permissions when prompted (menu bar shows warnings):"
echo "   - Screen & System Audio Recording  -> click warning in menu"
echo "   - Accessibility                     -> click warning in menu"
echo "Then quit (menu -> Quit ExDisplay) and reopen."
