#!/bin/bash
# Removes the login agent and the app installed by install.sh.
DEST="$HOME/Applications/Spotch.app"
pkill -x Spotch 2>/dev/null
[ -d "$DEST" ] && "$DEST/Contents/MacOS/Spotch" --uninstall
rm -rf "$DEST"
echo "uninstalled"
