#!/bin/bash
# Launch the frame-watcher DETACHED so it survives the terminal/IDE being killed by
# Athena (reparents to launchd; a CLI process is not a windowed app, so it isn't flagged).
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$HOME/Desktop/heimdall-check/_watch.log"
mkdir -p "$HOME/Desktop/heimdall-check"
nohup "$DIR/heimdall-frame-watch.sh" >"$LOG" 2>&1 &
disown
echo "frame-watcher detached (pid $!). It keeps running after the terminal closes."
echo "Frames -> ~/Desktop/heimdall-check/   log -> $LOG"
echo "Check it's alive:  pgrep -fl heimdall-frame-watch"
echo "Stop it:           pkill -f heimdall-frame-watch"
