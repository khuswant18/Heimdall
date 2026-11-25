#!/bin/bash
# Preserves every screen/webcam frame Heimdall writes to its on-disk cache,
# so you can inspect exactly what it captured (and whether your hidden overlay is absent).
# Bash 3.2 compatible (no associative arrays).
SRC="$HOME/Library/Application Support/heimdall/cached-data"
DST="$HOME/Desktop/heimdall-check"
mkdir -p "$DST"
echo "Watching: $SRC"
echo "Saving copies to: $DST"
echo "Leave this running during your session. Ctrl+C to stop, then open $DST and look for your overlay's marker."
while true; do
  find "$SRC" -name '*.jpg' 2>/dev/null | while IFS= read -r f; do
    [ -z "$f" ] && continue
    mtime=$(stat -f %m "$f" 2>/dev/null)
    stream=$(basename "$(dirname "$f")")
    out="$DST/${stream}-$(basename "$f" .jpg)-${mtime}.jpg"
    if [ ! -e "$out" ]; then
      cp "$f" "$out" 2>/dev/null && echo "[$(date +%H:%M:%S)] grabbed $stream frame -> $(basename "$out")"
    fi
  done
  sleep 0.3
done
