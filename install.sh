#!/bin/bash
# Builds Spotch, copies it to ~/Applications and lets it set itself up
# (it registers the login agent that opens it whenever Spotify launches).
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
DEST="$HOME/Applications/Spotch.app"
pkill -x Spotch 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
ditto "build/Spotch.app" "$DEST"
open "$DEST" --args --quiet
echo "installed $DEST"
