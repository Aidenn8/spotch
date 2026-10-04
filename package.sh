#!/bin/bash
# Builds the app and wraps it in dist/Spotch.dmg for a GitHub release.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
STAGE=$(mktemp -d)
ditto "build/Spotch.app" "$STAGE/Spotch.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
rm -f dist/Spotch.dmg
hdiutil create -quiet -volname "Spotch" -srcfolder "$STAGE" -format UDZO -ov dist/Spotch.dmg
rm -rf "$STAGE"
echo "packaged dist/Spotch.dmg"
