# ExDisplay

Turn an Android tablet into a **wired, touch-enabled extended display** for a Mac.

Not a mirror — macOS sees a real additional display it can render windows to. The
tablet shows that display's pixels over a USB cable, and touch on the tablet drives
the Mac cursor. It coexists with your existing physical monitors because the extra
display is a software-only virtual display (it does not consume a physical display
engine).

> Built and tested for a MacBook Air (M1) on macOS 26 (Tahoe) with a Samsung Galaxy
> Tab A9. Other Apple-Silicon Macs and recent Android tablets should work; see
> [Limitations](#limitations).

---

## How it works

```
Mac:  CGVirtualDisplay → ScreenCaptureKit → VideoToolbox H.264 → TCP :8888
                                                                    │  (adb reverse over USB)
Tab:  SurfaceView ← MediaCodec H.264 decode ← TCP :8888  ←─────────┘
            └─ touch → normalized x,y → TCP → CGEvent on Mac
```

`adb reverse` tunnels the tablet's `127.0.0.1:8888` to the Mac's localhost over USB,
so there is no raw USB or networking code on either side.

---

## Requirements

**Mac**
- Apple Silicon Mac, macOS 14+ (developed on macOS 26)
- Xcode Command Line Tools (`xcode-select --install`)
- `adb` — `brew install android-platform-tools`

**Tablet**
- Android 8.0+ (developed on Android 13)
- USB debugging enabled (Settings → About → tap Build number 7×, then Developer
  options → USB debugging)
- A data-capable USB cable

---

## Quick start

```bash
# 1. Build & install the Mac app
cd mac
bash make-app.sh
cp -r ExDisplay.app /Applications/
open /Applications/ExDisplay.app

# 2. Build & install the Android app (tablet plugged in, USB debugging authorised)
cd ../android
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties   # if not present
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

# 3. Launch the ExDisplay app on the tablet — it connects automatically.
```

On first launch the Mac app shows two ⚠️ warnings in its menu bar — click each to
grant **Screen Recording** and **Accessibility**, then quit and reopen the app.
`adb reverse` is run automatically by the Mac app and refreshed every 30 s.

---

## Using it

The Mac app lives in the **menu bar** (no Dock icon):

| Menu item | What it does |
|---|---|
| Connection status | Connected state, resolution, and live fps · Mbps |
| Pause / Resume Streaming | Pause to watch Netflix/DRM on the Mac (see Limitations) |
| Settings | Pick resolution + bitrate (persisted) |
| Show Logs / Copy Logs | Live log window; copy the buffer for bug reports |
| Launch at Login | Start ExDisplay automatically |
| Quit ExDisplay | Exit (the virtual display disappears) |

On the **tablet**: a small status dot (green = connected, yellow = connecting) and a
pause/resume button sit in the top-left corner. The screen follows the tablet's
landscape orientation.

To place windows on the tablet: System Settings → Displays → arrange the "Tab A9"
display, then drag windows onto it.

### Touch — the tablet works like a trackpad

| Gesture | Action |
|---|---|
| 1 finger tap / drag | click / drag the Mac cursor |
| 1 finger move | move the cursor |
| 2 fingers pan | scroll |
| 3 fingers swipe ← / → | next / previous Space |
| 3 fingers swipe ↑ | Mission Control |
| 3 fingers swipe ↓ | App Exposé |

3-finger swipes are mapped to Mission Control's keyboard shortcuts (Ctrl+arrow), so
they need **more than one Space** to exist and **Mission Control keyboard shortcuts
enabled** (System Settings → Keyboard → Keyboard Shortcuts → Mission Control) — both
are on by default.

---

## Configuration

| Setting | Value | Configurable |
|---|---|---|
| Resolution | 1340×800 default (also 1280×800 … 2560×1600) | ✅ Settings menu |
| Bitrate | 18 Mbps default (8–40 Mbps) | ✅ Settings menu (live) |
| Refresh | 60 Hz | — |
| Codec | H.264 (AVC), GOP 60 | — |
| Transport | TCP `127.0.0.1:8888` over `adb reverse` | port fixed |
| Touch | trackpad: 1-finger cursor, 2-finger scroll, 3-finger swipe | — |

Resolution/bitrate are chosen from the menu-bar **Settings** submenu and persist
across launches. Changing bitrate is instant; changing resolution briefly reconnects
the tablet. Remaining roadmap: see [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

---

## Limitations

- **DRM video** (Netflix, Apple TV+, Disney+) will not play anywhere on the Mac while
  streaming is active — macOS blocks decryption whenever a screen capture session is
  running. Use **Pause Streaming** to watch, then resume.
- **USB 2.0 tablets** cap throughput (~280 Mbps); the 18 Mbps stream is well within
  this but rules out uncompressed video.
- **3-finger swipes need >1 Space** and Mission Control keyboard shortcuts enabled
  (they map to Ctrl+arrow, not real trackpad gestures, which CGEvent can't synthesize).
- **Pinch-zoom / rotate** not supported (no multi-touch gesture passthrough).
- **Private API**: the virtual display uses an undocumented macOS API. It cannot be
  shipped on the Mac App Store and may break on future macOS versions.

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if something doesn't work.

---

## Repository layout

```
mac/      SwiftPM package — menu-bar host app + ExDisplayCore (protocol) + tests
android/  Gradle app — decoder + touch client
CLAUDE.md                 Original design brief / architecture decisions
CHANGELOG.md              Release history + Mac↔Android compatibility matrix
SECURITY.md               Privacy, network exposure, permissions
TESTING.md                Manual QA checklist + device matrix
TROUBLESHOOTING.md        Common issues and fixes
PRODUCTION_CHECKLIST.md   Roadmap to a production release
VERSION                   Single source of truth for the version number
```

## License

MIT — see [LICENSE](LICENSE). Distilled from the MIT-licensed Side Screen project.
