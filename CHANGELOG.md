# Changelog

All notable changes to ExDisplay. Versioning is [SemVer](https://semver.org/);
the single source of truth for the current version is the repo-root `VERSION` file
(consumed by both `mac/make-app.sh` and `android/app/build.gradle`).

## [Unreleased]
### Changed
- Android application ID is now `io.github.harshitbwc.exdisplay` (was the placeholder
  `com.example.tabdisplay`). It installs as a new app; uninstall the old one.
- Android release builds can be signed via `keystore.properties` or environment
  variables; tagged releases are built and published by GitHub Actions.

## [1.2.0] — 2026-06-01
### Added
- **3-finger swipe** → Spaces / Mission Control / App Exposé (wire protocol v3).
  Mapped to Ctrl+arrow keyboard shortcuts (CGEvent can't emit real trackpad gestures).

## [1.1.0] — 2026-06-01
### Added
- **2-finger scroll** (wire protocol v2). The tablet now behaves like a trackpad:
  1 finger = cursor, 2 fingers = scroll.
- **Settings menu** — resolution presets (1340×800 … 2560×1600) and bitrate
  (8–40 Mbps), persisted in UserDefaults. Bitrate applies live; resolution restarts
  the pipeline.
- **Observability** — live fps · Mbps in the menu, "Copy Logs to Clipboard",
  uncaught-exception crash logging, warnings for missing adb / port-in-use.

## [1.0.0] — 2026-05-29
### Added
- Initial release: wired Android tablet as a Mac extended display.
- Mac host (SwiftPM menu-bar app): CGVirtualDisplay, ScreenCaptureKit capture,
  VideoToolbox H.264 encode, TCP server, CGEvent touch injection, pause/resume for
  DRM, launch-at-login, automatic `adb reverse`, log window.
- Android client: MediaCodec H.264 decode → SurfaceView, auto-reconnect, touch
  forwarding, status dot + pause control, sensor-landscape orientation.
- Hardened wire protocol (`ExDisplayCore`): version byte, frame-size cap,
  index-safe + fuzz-tested parser (wire protocol v1).
- Tooling: git, GitHub Actions CI, unit/fuzz tests, README, TROUBLESHOOTING,
  TESTING, MIT license.

---

## Mac ↔ Android compatibility (wire protocol)

Both ends negotiate via the version byte in the display-config handshake. On a
mismatch the tablet shows **"Incompatible Mac app"** rather than misbehaving — so
**rebuild and reinstall both sides together** when the protocol version changes.

| App version | Wire protocol | Capabilities |
|-------------|---------------|--------------|
| 1.0.x       | v1            | video + single-pointer touch |
| 1.1.x       | v2            | + 2-finger scroll |
| 1.2.x       | v3            | + 3-finger swipe |

Protocol version lives in `mac/Sources/ExDisplayCore/Protocol.swift` (`Proto.version`)
and must equal `PROTOCOL_VERSION` in
`android/.../StreamClient.kt`.
