#!/bin/bash
# Removes the watcher and the installed app.
LABEL=com.aidenn8.spotch.watcher
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
pkill -x Spotch 2>/dev/null
rm -rf "$HOME/Applications/Spotch.app"
echo "uninstalled"
