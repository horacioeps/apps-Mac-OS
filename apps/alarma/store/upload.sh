#!/bin/bash
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
xcodegen generate
xcodebuild -project Alarma.xcodeproj -scheme Alarma -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ROOT/build/Archive.xcarchive" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=WMY552P2HR CODE_SIGN_STYLE=Automatic archive
xcodebuild -exportArchive \
  -archivePath "$ROOT/build/Archive.xcarchive" \
  -exportPath "$ROOT/build/export" \
  -exportOptionsPlist "$ROOT/store/ExportOptions.plist" \
  -allowProvisioningUpdates
echo "Upload solicitado. Revisa App Store Connect → Alarma → TestFlight/Activity."
