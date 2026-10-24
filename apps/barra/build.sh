#!/bin/sh
# Builds "Barra Superior.app" with swiftc (no Xcode project), signs it ad hoc and installs it in
# /Applications. Bump VERSION on every change: major = new capability, minor = visible change,
# patch = fix.
set -e
VERSION=1.7.2
cd "$(dirname "$0")"
APP="build/Barra Superior.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O -target arm64-apple-macos14.0 -o "$APP/Contents/MacOS/BarraSuperior" Sources/*.swift
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>net.horacio.barrasuperior</string>
  <key>CFBundleName</key><string>Barra Superior</string>
  <key>CFBundleExecutable</key><string>BarraSuperior</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
codesign --force --sign - "$APP"
pkill -x BarraSuperior || true
rm -rf "/Applications/Barra Superior.app"
ditto "$APP" "/Applications/Barra Superior.app"
echo "v$VERSION instalada en /Applications/Barra Superior.app"
env -u ELECTRON_RUN_AS_NODE open "/Applications/Barra Superior.app"
