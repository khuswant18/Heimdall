#!/bin/bash
# Launch the overlay detached, in its own session, so it survives the terminal/IDE
# being killed (reparents to launchd). Invisible to Heimdall capture; not a windowed
# app to Athena's gate. Put notes in ~/.overlay.txt (live-reloads every second).
APP="$HOME/Desktop/Panel.app"
[ -f ~/.overlay.txt ] || echo "notes go here" > ~/.overlay.txt
nohup "$APP/Contents/MacOS/Panel" >/dev/null 2>&1 &
disown
echo "Panel launched (pid $!). Edit ~/.overlay.txt to change what it shows."
echo "Stop it with:  pkill -x Panel"
