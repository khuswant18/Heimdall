#!/bin/bash
LABEL="local.util.panel"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || launchctl unload "$HOME/Library/LaunchAgents/$LABEL.plist" 2>/dev/null
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
pkill -x Panel 2>/dev/null
echo "keep-alive OFF and Panel closed."
