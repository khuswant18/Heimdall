#!/bin/bash
# Keep Panel.app open until YOU stop it. launchd relaunches it if it ever exits.
BIN="$HOME/Desktop/Panel.app/Contents/MacOS/Panel"
LABEL="local.util.panel"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
[ -f ~/.overlay.txt ] || echo "notes here" > ~/.overlay.txt
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>KeepAlive</key><true/>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Interactive</string>
  <key>ThrottleInterval</key><integer>1</integer>
</dict></plist>
PL
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null
launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || launchctl load "$PLIST"
sleep 1
echo "keep-alive ON. Panel will stay up (relaunched if killed)."
pgrep -x Panel >/dev/null && echo "Panel running (pid $(pgrep -x Panel))." || echo "Panel not up yet — check again in a second."
echo "Stop it with:  $(dirname "$0")/stop-overlay.sh"
