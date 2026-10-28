# Security & Privacy

## What ExDisplay captures and transmits

ExDisplay creates a **virtual display** and captures *only that virtual display* with
ScreenCaptureKit — not your built-in screen or other monitors. Those pixels are
H.264-encoded and sent to the tablet. Touch/scroll/swipe input flows back from the
tablet to drive the Mac cursor.

**Everything stays on your machine.** Nothing is uploaded to any server, and there is
no telemetry or analytics. The data path is:

```
Mac virtual display → H.264 → TCP 127.0.0.1:8888 → (adb reverse, USB) → tablet
```

## Network exposure: none

- The TCP server binds **`127.0.0.1:8888` (loopback only)**. It is not reachable from
  the local network or the internet.
- The only thing that can reach the port is a process on the same Mac. `adb reverse`
  forwards the tablet's localhost to the Mac's localhost **over the USB cable** — no
  Wi-Fi, no LAN, no pairing.
- There is **no wireless mode** in this version. If/when LAN mode is added it MUST
  ship with an auth handshake + TLS first (tracked in PRODUCTION_CHECKLIST §10); do
  not expose the stream to the network without it.

## Permissions and why they're needed

| Permission | Why | Scope |
|---|---|---|
| Screen & System Audio Recording | ScreenCaptureKit needs it to capture the virtual display | Required for video |
| Accessibility | `CGEvent` injection for cursor / scroll / swipe | Required for touch |

Both are standard macOS TCC permissions you grant explicitly in System Settings. They
are revocable at any time. No audio is actually captured (video frames only).

## Entitlements (minimal by design)

`mac/entitlements.plist` disables the App Sandbox and nothing else:

```xml
<key>com.apple.security.app-sandbox</key><false/>
```

Deliberately **not** present: `disable-library-validation` and
`allow-unsigned-executable-memory`. Those broaden the attack surface and — combined
with runtime `tccutil` calls — match XProtect's TCC-bypass malware heuristics. We keep
the entitlement set as small as possible and never call `tccutil` from inside the app
(permission resets are done manually in Terminal / by `make-app.sh` at build time).

## DRM interaction

While streaming is active, macOS blocks DRM-protected playback (Netflix, Apple TV+,
Disney+) system-wide — this is the OS enforcing content protection because a capture
session is running, not something ExDisplay controls. Use **Pause Streaming** to watch
protected content, then resume.

## Reporting a vulnerability

This is a hobby project with no formal security program, but reports are welcome.
Please use GitHub's **private vulnerability reporting**: open the repository's
[Security tab](https://github.com/harshitbwc/ExDisplay/security) and choose
**Report a vulnerability**. Please don't post exploit details in a public issue.
