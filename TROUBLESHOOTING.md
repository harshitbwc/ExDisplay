# ExDisplay — Troubleshooting

Open **Show Logs** from the Mac menu bar (or run
`log stream --predicate 'subsystem == "com.exdisplay.app"' --style compact`) and
`adb logcat -s StreamClient Decoder MainActivity` for the tablet side. Most issues
announce themselves there.

---

## The "Tab A9" display never appears in System Settings → Displays
- The private `CGVirtualDisplay` API failed. Check the logs for
  `CGVirtualDisplay init/apply failed` or `did not appear in CGGetOnlineDisplayList`.
- Usually transient — quit and relaunch the app.
- If it persists after a macOS update, the private API may have changed (see
  Limitations in the README).

## No video on the tablet (black screen, dot stays yellow)
1. **Screen Recording not granted** — the menu shows
   "⚠️ Grant Screen Recording for Video". Click it, enable ExDisplay, then **quit and
   reopen** (TCC is only re-checked at launch).
2. **adb reverse not active** — unplug/replug, confirm `adb devices` shows the tablet
   as `device` (not `unauthorized` or empty). The Mac app re-runs `adb reverse` every
   30 s, but the tablet must be authorised first.
3. **Tablet app not launched / crashed** — relaunch it; it auto-reconnects every 3 s.

## Video works but touch does nothing
- **Accessibility not granted** — the menu shows "⚠️ Grant Accessibility for Touch".
  Click it, enable ExDisplay. Touch starts working without relaunch.
- If the cursor jumps to the wrong place, you likely rearranged displays — ExDisplay
  reads the display position live, so just try again; no restart needed.

## Touch worked, then the stream dropped abruptly
- This was a bug in older builds (a parser crash on touch). Rebuild from current
  source — `parseTouches` is now index-safe and fuzz-tested.

## `adb: command not found`
- `brew install android-platform-tools`, then confirm `adb version`.

## `adb devices` shows the tablet as `unauthorized`
- Unplug/replug and tap **Allow USB debugging** on the tablet (check "Always allow").

## Permissions keep re-prompting after every rebuild
- Expected with ad-hoc signing: each rebuild changes the binary hash, so macOS treats
  it as a new app. `make-app.sh` runs `tccutil reset` to give a clean prompt. Just
  re-grant. Downloaded release builds keep the same binary, so this mainly affects
  people building from source.

## Netflix / Apple TV+ / Disney+ shows a black video
- Expected. macOS blocks DRM decryption while any screen capture is active. Use
  **Pause Streaming** in the menu, watch, then **Resume**.

## Gatekeeper: "ExDisplay can't be opened because Apple cannot check it"
The app is ad-hoc signed, not notarized, so Gatekeeper blocks the first launch of a
downloaded copy. Pick one:
- **macOS 15 and later:** try to open the app once, then go to System Settings →
  Privacy & Security, scroll to the message about ExDisplay and click **Open Anyway**.
  (Right-click → Open no longer bypasses Gatekeeper on macOS 15+.)
- **macOS 14:** right-click the app → **Open** → **Open**.
- **Any version, Terminal:** `xattr -dr com.apple.quarantine /Applications/ExDisplay.app`
- Or build from source (see the README) — locally built apps are never quarantined.

## `./gradlew` fails with "SDK location not found"
- `echo "sdk.dir=$HOME/Library/Android/sdk" > android/local.properties`
- Install the SDK via Android Studio or `brew install --cask android-commandlinetools`.

## `./gradlew` fails with "Unable to locate a Java Runtime"
- `brew install --cask temurin@21`

## Port 8888 already in use
- Another process holds the port, or a previous ExDisplay instance didn't exit. Quit
  any stray instance (`pkill ExDisplay`) and relaunch. (Configurable port is on the
  roadmap.)
