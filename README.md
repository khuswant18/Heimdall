# Heimdall 1.2.9 (arm64) - extracted

The Electron app's JavaScript, recovered from Resources/app.asar. It was minified and webpack-bundled, and no source maps were shipped.

- raw/asar-contents/   - exactly what was in app.asar
- bundled-pretty/      - the bundles, prettier-formatted (main.js ~106k lines, renderer.js ~105k lines)
- main/, renderer/     - each bundle split into one file per webpack module (`<id>_<exported names>.js`)
  - app/    - modules that look like Heimdall's own code (a keyword heuristic, so expect some mistakes)
  - vendor/ - libraries (electron-updater, Sentry, React, styled-components, ...)
  - _index.tsv - module id -> file -> size

## Main process: where to start
- 60575_*initHeimdall*            - core orchestrator (proctoring socket, capture, lockdown, quit handling)
- 47160_channels                  - every IPC channel between the UI and the main process
- 36339_GLOBALS                   - global state (exam duration, flags)
- 77146 / 74189 / 55714 / 30938   - network lockdown (system-extension proxy, socket, SNI probe)
- 91668 / 47854                   - native addon loader and VM detection tiers
- 27265 / 22605 / 57114 / 87589   - snapshot capture, cache, and upload
- 81609 / 68565                   - peer-auth checks against the helper process
- 6861 / 62469                    - Apple App Attest
- 10018 / 26256 / 40182           - auto-update and version gating (S3 bucket in raw/app-update.yml)

## Renderer: UI screens
PermissionsPage, SecuringPage, ExtensionApprovalPage, ExamScreens, LockdownPageLayout, AudioRecorder, camera select.

## Native parts (not JS; only symbols and strings were inspected)
- *.node addon: App Attest, code-signature self-check, socket peer identity,
  VM signals (kern.hv_vmm_present, hw.model vs vmware/parallels/virtualbox), audio devices, screen-capture access
- Contents/Library/SystemExtensions/com.newton.heimdall.helper.proxy.systemextension - network-filter proxy
- Contents/Library/Heimdall Updater.app, and Contents/MacOS/Heimdall (a native launcher in front of "Heimdall (Electron)")
