#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Desktop/Panel.app"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
swiftc "$DIR/overlay.swift" -o "$APP/Contents/MacOS/Panel"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Panel</string>
  <key>CFBundleIdentifier</key><string>local.util.panel</string>
  <key>CFBundleName</key><string>Panel</string>
  <key>CFBundleDisplayName</key><string>Panel</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force -s - "$APP" >/dev/null 2>&1 || true
echo "built: $APP"
