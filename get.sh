#!/bin/bash
# One-step install: downloads the latest Spotch release, puts the app in
# Applications, sets it up and opens Spotify. Run it in Terminal with:
#
#   curl -fsSL https://raw.githubusercontent.com/Aidenn8/spotch/main/get.sh | bash
#
# Running it again updates Spotch to the latest release.
set -euo pipefail

RELEASE="https://github.com/Aidenn8/spotch/releases/latest/download/Spotch.dmg"
AGENT="com.aidenn8.spotch.watcher"
TMP=""

cleanup() {
    [ -n "$TMP" ] || return 0
    hdiutil detach -quiet "$TMP/mnt" 2>/dev/null || true
    rm -rf "$TMP"
}

main() {
    if [ "$(uname -m)" != "arm64" ]; then
        echo "Spotch needs a Mac with Apple silicon (M1 or later)."
        exit 1
    fi
    local version major
    version=$(sw_vers -productVersion)
    major=${version%%.*}
    if [ "$major" -lt 14 ]; then
        echo "Spotch needs macOS 14 Sonoma or later (this Mac has $version)."
        exit 1
    fi

    # Update a copy where it already is; otherwise use /Applications if it's
    # writable, or the Applications folder in your home folder.
    local dest
    if [ -d "/Applications/Spotch.app" ]; then
        dest="/Applications/Spotch.app"
    elif [ -d "$HOME/Applications/Spotch.app" ] || [ ! -w /Applications ]; then
        dest="$HOME/Applications/Spotch.app"
    else
        dest="/Applications/Spotch.app"
    fi

    TMP=$(mktemp -d)
    trap cleanup EXIT

    echo "Downloading Spotch..."
    curl -fsSL "$RELEASE" -o "$TMP/Spotch.dmg"
    hdiutil attach -quiet -nobrowse -readonly -mountpoint "$TMP/mnt" "$TMP/Spotch.dmg"

    # Stop a running copy and its login agent first. The agent removes itself
    # when it sees its app deleted, and could otherwise remove the new one.
    launchctl bootout "gui/$(id -u)/$AGENT" 2>/dev/null || true
    pkill -x Spotch 2>/dev/null || true

    echo "Installing to $dest..."
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    ditto "$TMP/mnt/Spotch.app" "$dest"
    hdiutil detach -quiet "$TMP/mnt" || true

    # Opening the app once sets it up: it registers the login agent that
    # brings the widget up whenever Spotify opens, and opens Spotify.
    open "$dest"

    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if launchctl print "gui/$(id -u)/$AGENT" >/dev/null 2>&1; then
            echo "Spotch is set up. Play a song in Spotify and it appears in the notch."
            if [ ! -d "/Applications/Spotify.app" ] && [ ! -d "$HOME/Applications/Spotify.app" ]; then
                echo "The Spotify app isn't installed yet: get it from https://www.spotify.com/download"
            fi
            return 0
        fi
        sleep 1
    done
    echo "Spotch is installed but didn't finish setting up. Open it once from $(dirname "$dest")."
    exit 1
}

main
