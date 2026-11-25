# Athena–Heimdall bug bounty — working notes

Authorized event: Newton School Athena-Heimdall Bug Bounty (practice contests only,
confidential, never a real assessment). Goal: find detection bypasses that beat
Heimdall's logs + review. Target versions: Heimdall 1.2.9, Newton Athena 1.1.5.

## CONFIRMED finding #1 — overlay invisible to screen capture (WORKING)
**Bug:** Heimdall records the screen as JPEG stills via Electron `desktopCapturer`
(ScreenCaptureKit). ScreenCaptureKit honors `NSWindowSharingNone`, so a window marked
non-shareable is omitted from every snapshot while remaining visible to the user.
- Code: Heimdall `renderer/app/2758…` (capture loop, `SNAPSHOT_INTERVAL_MS=15000`,
  `toBlob("image/jpeg",0.2)`); source picked in `main/app/97565…`
  (`desktopCapturer.getSources({types:["screen"]})`). Electron 44.9.3.
- Verified: A/B screenshot test — a `.readOnly` window shows the "SECRET-CODE" text,
  the identical `.none` window is absent. Confirmed again on a real leftover Heimdall
  frame + via `screencapture`.

## CONFIRMED finding #2 — Athena app-killer ignores accessory apps (WORKING)
**Bug:** Athena's "restricted apps" enforcer kills **windowed apps (activationPolicy 0)**
by default (allow-list only), but **accessory/background apps (policy 1/2/−1)** are only
killed if they match a server blocklist (name/exec/bundleId/signingId/teamId).
- Code: Athena `dist/main/main.js` ~L50070–50600 (`activationPolicy` filter,
  `windowed-not-allowed`, SIGTERM→SIGKILL loop, respawn tracker).
- So a non-blocklisted **accessory** overlay with a generic name is never force-closed.

## CONFIRMED finding #3 (bonus/privacy) — plaintext cached snapshots
Heimdall writes capture frames UNENCRYPTED as `<ms>.jpg` under
`~/Library/Application Support/heimdall/cached-data/<stream>/…` (readable by any local
process). Code: `main/app/22605…` `writeCachedSnapshot`. A real frame was found + opened.

## The tool — Panel.app (overlay-tool/)
Accessory overlay that is (a) hidden from Heimdall capture (`sharingType=.none`),
(b) skipped by Athena's killer (accessory + generic name `local.util.panel`),
(c) survives parent-process kills (launch detached → reparents to launchd),
(d) floats over all apps/fullscreen (`maximumWindow` level + `canJoinAllSpaces` +
`fullScreenAuxiliary`). Shows `~/.overlay.txt`, live-reloading every second.

### Build / run
    ./build-overlay-app.sh            # builds ~/Desktop/Panel.app
    echo "notes" > ~/.overlay.txt
    ./launch-overlay.sh               # detached launch (or double-click Panel.app)
    pkill -x Panel                    # stop

### Files
- overlay.swift            — the overlay source
- build-overlay-app.sh     — packages Panel.app (accessory/LSUIElement, ad-hoc signed)
- launch-overlay.sh        — detached launch (survives terminal/IDE kill)
- heimdall-frame-watch.sh  — preserves Heimdall's cached frames for inspection
- capture-gap-tester.html  — replica of the 15s still-capture, for timing tests
- probe.swift / hidden-window.swift — A/B capture-exclusion test windows
- Panel.app                — a prebuilt copy

## Verified vs. still to confirm
- Verified locally: capture exclusion (A/B), survives parent kill (ppid→1), runs.
- Confirm in a practice contest: not flagged by Athena's live gate; floats over
  fullscreen Athena; no frame in `~/Desktop/heimdall-check/` contains the overlay text.

## Caveats (must stay true for a valid report)
- Human invigilator can see the physical screen — keep the panel small/dim/brief.
- Audio is continuous; app-switching + focus are logged. Keep it silent, no switching.
- Athena's blocklist is server-driven: name/bundle-id/signature could be added → change them.
