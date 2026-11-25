# Heimdall 1.2.9 — security & robustness research notes

Static review of the extracted JavaScript only. The native `.node` addon and the
system-extension proxy were not disassembled, so claims about them are inferred
from exported symbols and strings. These are observations for the vendor / for
understanding the design — not an exam-bypass procedure.

## How enforcement is wired (threat model)
- **Heimdall** (this Electron app) does capture + lockdown + tamper checks.
- **Athena** (`org.erb.NewtonAthena`) is the exam browser. It is the authority on
  "is an exam live" and heartbeats Heimdall over a local socket.
- A **native addon** does App Attest, code-signature self-check, socket peer
  identity, VM signals, audio/screen access.
- A **system extension** (`com.newton.heimdall.helper.proxy`) does network filtering.

## What it does well (sets the bar)
- Strips dangerous Chromium/Node switches at launch (`98360`): `remote-debugging-port`,
  `inspect*`, `proxy-server`, `ignore-certificate-errors`, `disable-web-security`,
  `no-sandbox`, `host-resolver-rules`, … and deletes `SSLKEYLOGFILE`.
- **Cert pinning / anti-MITM** on Newton hosts (`57130`+`63143`): a non-standard root
  on `my.newtonschool.co` is rejected and reported.
- **Downgrade protection** in the updater (`26256`): an update older than the running
  version returns `downgradeRefused`.
- **Peer auth** (`68565`): codesign checks with Team ID `2Z288BV4R4`, strict + sideband,
  nested/deep/floor modes all `enforce`, Athena min version pinned.
- No hardcoded credentials found. (Sentry DSN and S3/CloudFront hosts are present but
  those are not secrets.)

## Findings / gaps

### 1. Over-broad IPC preload bridge — defense-in-depth gap
`dist/main/preload.js` exposes a **generic** bridge to the renderer:
`ipcRenderer.sendMessage(channel, …)`, `on`, `once`, `invoke` with **no channel
allowlist**. Any script running in the renderer can call *any* main-process IPC
handler (`upload_snapshot`, `lockdown_*`, `update_only_quit`, …). CSP is
`script-src 'self' 'unsafe-inline'`, so the renderer's own code is trusted — but
`unsafe-inline` + a generic bridge means any injected/inline script inherits full
IPC reach. Best practice is to wrap each channel in a named, validated method.
*Severity: medium (depends on a renderer injection to exploit).*

### 2. "Exam live" / quit-refusal authority is a heartbeat with a 3h window
`shouldRefuseQuit` (`46063`) = exam-in-progress AND not exit-approved AND
`athenaInTouch()`. `ATHENA_CONTACT_WINDOW_MS = 108e5` (**3 hours**, `51146`). The
lock on quitting is driven by Athena's last contact over a local socket, not by an
independently verified server state. The whole enforced-session concept rests on
that local IPC relationship staying trusted and timely.
*Severity: design observation — the trust root is local, not server-attested.*

### 3. VM detection is host-sysctl heuristic
Native `GetVMSignals` reads `kern.hv_vmm_present` and compares `hw.model` against
`vmware`/`parallels`/`virtualbox` strings (`strings` on the addon). Tiers are
`clean/primary/unknown` (`91668`). This catches consumer hypervisors but is
signal-based, so it is inherently probabilistic against a hypervisor configured to
hide those signals. Expected for any client-side VM check; worth knowing it is not
a hard guarantee.
*Severity: inherent limitation.*

### 4. Developer VM-enforcement bypass flag exists
`vmEnforceFrom` (`47854`): enforcement is off when argv has `--vm-enforce=0` **and**
the parent executable is the signed `Heimdall` launcher next to it. The signed-parent
gate makes it hard to trip from a plain shell, but a build-time/dev escape hatch
shipping in a release build is worth auditing — confirm the production launcher can
never be coaxed into passing it.
*Severity: low–medium (gated, but present in the shipped binary).*

### 5. Update feed: S3 bucket `acl: public-read`
`app-update.yml` points at S3 bucket `newton-macbook-app-artifacts`
(`ap-south-1`, `acl: public-read`) with a CloudFront alternate
(`dwlxi2tcafdc0.cloudfront.net`). Integrity on macOS still rests on Squirrel +
Apple code signing, and downgrade is refused (#above). But a world-readable
artifact bucket is an exposure (enumeration of all versions/builds) and makes the
signing chain the *only* thing between a bucket-write and code execution — verify
the bucket is write-locked and that `setFeedURL` validation in `10018` (it does
block `..` in the path and checks `provider: s3` + exact bucket) can't be widened.
*Severity: medium if bucket write-ACL is ever loose; low otherwise.*

### 6. CSP uses `unsafe-inline`
`index.html`: `script-src 'self' 'unsafe-inline'`. Combines with #1 to make any HTML
injection in the renderer directly script-capable. Prefer nonces/hashes.
*Severity: low–medium.*

### 7. Native-addon load failure degrades to a throwing Proxy
`91668`: if `heimdall_native_addons.node` fails to load, `addon` becomes a Proxy that
throws on use. Good that it's loud — but confirm every security path (peer auth,
App Attest, VM, self-check) *fails closed* (blocks the exam) rather than being caught
and skipped somewhere upstream. A caught-and-logged addon error on a check path would
silently drop enforcement.
*Severity: needs dynamic confirmation.*

### 8. Minor / robustness
- Telemetry Sentry DSN is embedded (normal, not a secret): `o296331.ingest.us.sentry.io`.
  Snapshots/logs flow to `brokk.newtonschool.co/v1/logs` and transport config is fetched
  per-upload (`7719`), so capture destinations are server-controlled at runtime.
- Version compare (`26256`) treats a literal `"x"` segment as a wildcard match — a
  malformed server-supplied version list could make gating behave unexpectedly.
- `uploadSnapshot` uses a simple in-flight boolean per stream (`7719`); overlapping
  captures are dropped to `deferred_busy` rather than queued (possible capture gaps).

## Suggested next steps for real validation
- Disassemble the `.node` and the proxy system extension (Ghidra/Hopper) to confirm
  fail-closed behavior and the exact VM/peer logic.
- Dynamic test (in a lab, not a live exam): does each native check block the session
  when forced to fail? Is the S3 bucket write-protected?
