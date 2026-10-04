#!/bin/bash
# Builds "build/Spotch.app" (ad-hoc signed), with the Spotify watcher inside.
set -euo pipefail
cd "$(dirname "$0")"
APP="build/Spotch.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers"
swiftc -O -target arm64-apple-macos14.0 Sources/*.swift -o "$APP/Contents/MacOS/Spotch"
swiftc -O -target arm64-apple-macos14.0 Watcher/main.swift -o "$APP/Contents/Helpers/SpotchWatcher"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP/Contents/Helpers/SpotchWatcher" >/dev/null 2>&1
codesign --force --sign - "$APP" >/dev/null 2>&1
echo "built $APP"
