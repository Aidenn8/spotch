#!/bin/bash
# Builds Spotch, copies it to ~/Applications and lets it set itself up
# (it registers the login agent that opens it whenever Spotify launches).
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
DEST="$HOME/Applications/Spotch.app"
# Stop the old login agent first: it removes itself when it sees its app
# deleted, and could otherwise remove the one the new copy sets up.
launchctl bootout "gui/$(id -u)/com.aidenn8.spotch.watcher" 2>/dev/null || true
pkill -x Spotch 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
ditto "build/Spotch.app" "$DEST"
open "$DEST" --args --quiet
echo "installed $DEST"
