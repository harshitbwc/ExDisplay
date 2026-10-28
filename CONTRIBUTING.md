# Contributing to ExDisplay

Bug reports, device reports and pull requests are welcome.

## Layout

- `mac/` — SwiftPM package: menu-bar host app (`ExDisplay`), the pure-Swift wire
  protocol (`ExDisplayCore`) and the private-API bridge (`CGVirtualDisplayBridge`).
- `android/` — Gradle app: `MainActivity`, `StreamClient`, `Decoder`.
- `VERSION` — the single source of truth for the version (read by both builds).

## Build and test

```bash
# Mac (Apple Silicon, macOS 14+, Command Line Tools are enough to build)
cd mac && swift build -c release
bash make-app.sh                      # assembles + ad-hoc signs ExDisplay.app

# Mac unit/fuzz tests need full Xcode (XCTest)
EXDISPLAY_TESTS=1 swift test

# Android
cd android
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties   # if not present
./gradlew assembleDebug
```

Manual QA steps are in [TESTING.md](TESTING.md). Please run the relevant ones before
opening a PR that touches streaming, input or the protocol.

## Changing the wire protocol

Bump `Proto.version` in `mac/Sources/ExDisplayCore/Protocol.swift` **and**
`PROTOCOL_VERSION` in `android/.../StreamClient.kt`, add tests, and update the
compatibility table in [CHANGELOG.md](CHANGELOG.md).

## Reporting a device

If ExDisplay works (or doesn't) on a Mac/tablet combination not in
[TESTING.md](TESTING.md), please open an issue with the model, OS versions and logs
(menu bar → **Copy Logs**).

## Releasing (maintainers)

1. Update `VERSION` and `CHANGELOG.md` (the section for the new version becomes the
   release notes).
2. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`. The `Release` workflow
   builds the ad-hoc-signed Mac app and the signed Android APK and publishes a
   GitHub Release with SHA-256 checksums. The tag must equal `v$(cat VERSION)`.

### One-time Android signing setup

```bash
keytool -genkeypair -v -keystore exdisplay-release.jks -alias exdisplay \
        -keyalg RSA -keysize 4096 -validity 10000
base64 -i exdisplay-release.jks | pbcopy        # paste into the secret below
```

Add these repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. **Back up the keystore somewhere safe and
never commit it** — every future update must be signed with the same key or users must
uninstall first. For local release builds, put the same values in an untracked
`android/keystore.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`).
