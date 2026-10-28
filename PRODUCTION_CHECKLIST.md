# ExDisplay — Production Readiness Checklist

Status legend: ☐ todo · ◐ partial · ☑ done

Priority tiers:
- **P0** — blocks any real distribution beyond your own machine
- **P1** — needed for a quality, shareable release
- **P2** — polish, hardening, and future features

---

## 1. Distribution & Code Signing (P0)

**Decision: no Apple Developer account.** Notarization / Developer ID signing are out
of scope. Distribution is the free path: **ad-hoc signing**, shared by either (a)
building from source per machine, or (b) a GitHub Release zip that users open via
Privacy & Security → Open Anyway (macOS 15+; right-click → Open only works on macOS 14).

- ☑ **Ad-hoc signing** in `make-app.sh` (`--sign -`) — chosen distribution method
- ☑ **Stale-TCC handling** — `make-app.sh` runs `tccutil reset` each rebuild so
  permission prompts are clean (the cost of ad-hoc: hash changes each build)
- ☑ **Document the Gatekeeper step** for recipients (README + TROUBLESHOOTING)
- ◐ **Android: signed release APK** — signing config + release workflow are in place;
  still needed: generate the keystore and add the four `ANDROID_*` repo secrets
  (see CONTRIBUTING.md)
- ☑ **Architecture coverage** — arm64 only; README states "Apple Silicon only"

> Trade-offs accepted by skipping a Developer account: recipients must use Open Anyway
> (or `xattr`) once; permissions re-grant after each rebuild; no Mac App Store (also blocked
> anyway by the private API). None of these affect functionality.

## 2. Protocol Hardening (P0)

We already hit one parser crash (the `Data` indexing bug). The wire protocol needs to be defensively coded.

- ☑ Touch parser is index-safe (`[UInt8]` buffer)
- ☑ **Protocol version byte** in the handshake — so Mac and Android can detect mismatches and refuse cleanly instead of misparsing
- ☑ **Frame size sanity cap** — reject absurd `[size: u32]` values before allocating (prevents OOM / DoS from a malformed peer)
- ☐ **Bounds validation on every field** — both sides, every message type
- ◐ **Fuzz the parsers** — Mac-side parser is fuzz-tested; the Android read loop is not
- ☐ **Graceful handling of partial/interleaved messages** on both sides

## 3. Robustness & Recovery (P1)

- ◐ Android auto-reconnect (done) — verify it survives Mac app restart, cable replug, sleep/wake
- ◐ Mac capture auto-restart on display reconfig (done) — verify no infinite-restart loops
- ☑ **adb dependency handling** — menu warns "adb not found" when the binary is absent
- ☑ **Port-in-use handling** — listener bind failure surfaced as a menu warning + log
- ☑ **Single-client enforcement** — newest connection wins (prior one is dropped)
- ☐ **adb reverse failure surfacing** — silent when no device attached; acceptable for now
- ☐ **Mac sleep / display-off behavior** — define and test what happens to stream + virtual display
- ☐ **Tablet sleep / app-backgrounded** — define reconnect behavior
- ☐ **Encoder/decoder error recovery** — request keyframe / reinit on decode errors (back-channel; needs §12)

## 4. Configuration & Settings (P1)

- ☑ **Settings UI** (Mac menu) — resolution + bitrate submenu with checkmarks
- ☑ **Persist settings** (UserDefaults) across launches
- ☑ **Multiple resolution presets** (1340×800 native, 1280×800, 1600×1000, 1920×1200, 2560×1600)
- ☑ **Live bitrate change** (no pipeline restart); resolution change restarts pipeline
- ☐ **Custom resolution entry** (free-form, beyond presets)
- ☐ **Configurable port** — fixed at 8888 (Android hardcodes it); needs Android host/port entry too
- ☐ **Codec selection** (H.264 / HEVC) — see §12

## 5. Observability (P1)

- ☑ In-app log window + unified logging
- ☑ **Connection metrics** — live fps + measured Mbps in the menu status line
- ☑ **Crash reporting** — uncaught ObjC exceptions logged (name, reason, stack) before exit
- ☑ **Diagnostics export** — "Copy Logs to Clipboard" menu item
- ☐ **Round-trip latency / dropped-frame metrics** — needs a ping/pong back-channel (§12)
- ☐ **Android-side logging surfaced** — currently only via `adb logcat`

## 6. Testing (P1)

- ☑ **Unit tests** — protocol encode/decode round-trips, bounds safety (`swift test`)
- ☑ **Parser fuzz tests** — random/truncated input never crashes or hangs
- ☑ **Manual QA checklist** — see [TESTING.md](TESTING.md)
- ☑ **Device matrix** — table in TESTING.md
- ☐ **Integration test** — loopback client that connects and validates framing end-to-end

## 7. CI/CD & Build Automation (P1)

- ☑ **Git repository** — on GitHub, `.gitignore` covers build output and keystores
- ☑ **CI build** — `swift build` + `swift test` + `gradlew assembleDebug` on push/PR
- ◐ **Automated release pipeline** — `release.yml` builds, ad-hoc signs/signs, checksums and
  attaches on `v*` tags (untested until the first tag; no notarization by design)
- ☑ **Version stamping** — repo-root `VERSION` feeds both builds

## 8. Documentation (P1)

- ☑ **README** — what it is, requirements, install, first-run, troubleshooting
- ◐ **User guide** — permissions walkthrough (Screen Recording + Accessibility), DRM pause, reconnect
- ☑ **Troubleshooting guide** — adb not found, tablet not authorized, no video, no touch, stale TCC
- ☑ **CONTRIBUTING / build-from-source** instructions
- ☑ **Known limitations** doc — DRM, USB-2 ceiling, single-touch, private API fragility

## 9. Versioning & Release Management (P2)

- ☑ Semantic versioning + [CHANGELOG.md](CHANGELOG.md)
- ☑ Mac ↔ Android compatibility matrix (protocol-version table in CHANGELOG.md)
- ☐ Update mechanism (or at least "check for updates" / release notifications)

## 10. Security & Privacy (P2)

- ☑ **Loopback-only binding confirmed** — documented in [SECURITY.md](SECURITY.md)
- ☑ **Privacy statement** — what's captured/transmitted + local-only, in SECURITY.md
- ☑ **Entitlements minimized & justified** — documented in SECURITY.md
- ☐ **Wireless mode auth** (when added) — pairing/auth handshake, TLS; do NOT ship LAN mode without it

## 11. UX Polish (P2)

- ☐ **App icon** — real icon for menu bar + bundle (currently SF Symbol)
- ☐ **First-run onboarding** — guided permission grants instead of warning items
- ☐ **Better connection status** — Mac menu + Android dot already there; add latency/quality
- ☐ **Android: optional on-screen keyboard passthrough** (separate from touch)
- ☐ **Graceful "waiting for tablet" vs "tablet connected" visuals**

## 12. Feature Completeness — the v2 backlog (P2)

Deferred from v1:

- ☑ **Multi-touch** — 2-finger scroll + 3-finger swipe (Spaces / Mission Control)
- ☐ **HEVC codec** option (better compression) — codec constant both sides + VPS handling
- ☐ **HiDPI / Retina mode** — sharper text (PPI ≥ 200); low value on the 1340×800 Tab A9 panel
- ☐ **Pinch / rotate gestures** — needs gesture-event synthesis (CGEvent can't; would need private API)
- ☐ **Keyframe-request back-channel** — fast recovery after loss/reconnect
- ☐ **Wireless mode** — TCP over LAN + auth + QR pairing (security-gated, see §10)
- ☐ **Multiple virtual displays** / multi-tablet
- ☐ **Audio** (if ever in scope) — currently video + touch only

## 13. Legal & Licensing (P2)

- ☑ **LICENSE file** — MIT, with a "distilled from Side Screen" note
- ◐ **Third-party attributions** — the reverse-engineered `CGVirtualDisplay` header, any borrowed patterns
- ☑ **Private API disclosure** — documented in the README that this uses an undocumented Apple API and may break on OS updates (App Store distribution is NOT possible because of this)

---

## Before the first public release

1. ☐ Generate the Android release keystore, back it up, add the four `ANDROID_*` secrets
2. ☐ Enable private vulnerability reporting (Settings → Code security)
3. ☐ README screenshots / demo GIF
4. ☐ Tag `v1.2.0` and verify the Release workflow end-to-end
5. ☐ Later: Homebrew tap, Obtainium/F-Droid listing, app icon, onboarding

> Notarization intentionally skipped — no Apple Developer account (see §1).
