# ExDisplay — Manual QA Checklist

Automated tests (`EXDISPLAY_TESTS=1 swift test`, run in CI) cover the wire protocol.
Everything below needs real hardware (Mac + tablet + cable) and is run before tagging
a release. Tick each on the target macOS/Android versions.

## Setup
- [ ] `bash mac/make-app.sh` builds with no errors
- [ ] `cp -r ExDisplay.app /Applications/ && open` — menu-bar icon appears, no Dock icon
- [ ] First launch shows ⚠️ Screen Recording + Accessibility warnings in the menu
- [ ] Granting each warning + relaunch clears it
- [ ] `adb` present → no "adb not found" warning; rename adb → warning appears

## Milestone 1 — Virtual display
- [ ] System Settings → Displays shows "Tab A9"
- [ ] The display can be arranged relative to other monitors
- [ ] Coexists with the physical LG monitor (both present)

## Milestone 2–5 — Streaming
- [ ] Tablet app launches and the dot goes green within a few seconds
- [ ] Mac desktop is visible on the tablet
- [ ] Dragging a window onto the Tab A9 display shows it on the tablet
- [ ] Menu status shows resolution + live "N fps · X.X Mbps" when connected
- [ ] Scrolling/video on the virtual display looks smooth (no persistent smearing)

## Milestone 6 — Touch
- [ ] Tapping the tablet moves the Mac cursor to the right spot
- [ ] Tap = click; press-drag = drag; release = mouse up
- [ ] Rearranging displays mid-session: touch still maps correctly (no restart)
- [ ] App does NOT crash on touch (regression guard for the parser bug)

## Settings
- [ ] Changing **Bitrate** updates "Mbps" in the status, stream not interrupted
- [ ] Changing **Resolution** reconnects the tablet at the new size
- [ ] Chosen settings persist after quit + relaunch (checkmarks restored)

## Robustness / recovery
- [ ] Unplug cable → tablet shows "retrying"; replug → reconnects automatically
- [ ] Quit Mac app while tablet connected → tablet retries; reopen → reconnects
- [ ] Pause Streaming → DRM (Netflix) plays; Resume → tablet returns live
- [ ] Mac sleep/wake → stream recovers (or reconnects) without manual steps
- [ ] Protocol mismatch (old APK vs new Mac app) → tablet shows "Incompatible", no black screen
- [ ] Second tablet connecting → last-connected wins, no crash

## Observability
- [ ] Show Logs window opens, shows history + live lines
- [ ] Copy Logs places the log text on the clipboard
- [ ] `log stream --predicate 'subsystem == "com.exdisplay.app"' --style compact` works

## Shutdown
- [ ] Quit ExDisplay → "Tab A9" disappears from Displays
- [ ] Launch at Login toggle persists across reboot (when enabled)

---

## Device matrix (record what was tested)

| macOS | Mac model | Android | Tablet | Date | Result |
|-------|-----------|---------|--------|------|--------|
| 26.x  | M1 Air    | 13      | Tab A9 |      |        |
