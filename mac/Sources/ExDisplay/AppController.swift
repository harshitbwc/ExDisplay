import Foundation
import CoreGraphics
import AppKit

// Owns all ExDisplay components. Must be accessed on the main thread.
final class AppController {
    private var virtualDisplay: VirtualDisplay?
    private(set) var capture: Capture?
    private var encoder: Encoder?
    private(set) var server: Server?
    private var input: Input?
    private var adbTimer: Timer?

    private(set) var settings = Settings.load()

    var onStateChanged: (() -> Void)?

    var isStreaming: Bool         { !(capture?.isPaused ?? true) }
    var isConnected: Bool         { server?.isClientConnected ?? false }
    private(set) var screenRecordingGranted: Bool? = nil   // nil = unknown
    private(set) var serverError: String? = nil
    var isAdbAvailable: Bool { adbPath != nil }

    // Live throughput, refreshed ~1 s by metricsTimer.
    private(set) var fps = 0
    private(set) var mbps = 0.0
    private var metricsTimer: Timer?
    private var lastFrames = 0
    private var lastBytes = 0

    /// Human-readable throughput for the menu, or nil when idle.
    var metricsText: String? {
        guard isConnected, fps > 0 else { return nil }
        return "\(fps) fps · \(String(format: "%.1f", mbps)) Mbps"
    }

    var resolution: String {
        guard let vd = virtualDisplay,
              let m = CGDisplayCopyDisplayMode(vd.displayID) else { return "—" }
        return "\(m.pixelWidth)×\(m.pixelHeight)"
    }

    // MARK: – Lifecycle

    func start() {
        serverError = nil
        let s = settings
        // VirtualDisplay.init() has blocking retries — run off main thread
        Task.detached(priority: .userInitiated) { [weak self] in
            let vd = VirtualDisplay(width: s.width, height: s.height)
            await self?.finish(with: vd)   // finish is @MainActor, so this hops to main
        }
    }

    @MainActor
    private func finish(with vd: VirtualDisplay?) {
        guard let vd else {
            log("[AppController] Fatal: could not create virtual display")
            onStateChanged?()
            return
        }
        virtualDisplay = vd
        log("[AppController] Virtual display online. displayID=\(vd.displayID)")

        guard let mode = CGDisplayCopyDisplayMode(vd.displayID) else { return }

        let inp = Input(displayID: vd.displayID)
        input = inp

        let srv = Server(width: UInt32(mode.pixelWidth), height: UInt32(mode.pixelHeight)) { action, nx, ny in
            // CGEvent.post(tap: .cghidEventTap) must run on the main thread on macOS 15+
            DispatchQueue.main.async { inp.handleTouch(action: action, nx: nx, ny: ny) }
        }
        srv.onScroll = { dx, dy in
            DispatchQueue.main.async { inp.handleScroll(dx: dx, dy: dy) }
        }
        srv.onSwipe = { direction in
            DispatchQueue.main.async { inp.handleSwipe(direction: direction) }
        }
        srv.onConnectionChanged = { [weak self] _ in self?.onStateChanged?() }
        srv.onListenerFailed = { [weak self] msg in
            self?.serverError = msg
            self?.onStateChanged?()
        }
        do {
            try srv.start()
        } catch {
            serverError = error.localizedDescription
            log("[AppController] Server failed to start: \(error.localizedDescription)")
        }
        server = srv
        startMetricsTimer()

        guard let enc = try? Encoder(width: mode.pixelWidth,
                                     height: mode.pixelHeight,
                                     bitrate: settings.bitrateMbps * 1_000_000,
                                     onEncoded: { data, isKF in
            srv.sendFrame(data, isKeyframe: isKF)
        }) else { return }
        encoder = enc

        let cap = Capture(displayID: vd.displayID) { pixelBuffer, pts in
            enc.encode(pixelBuffer: pixelBuffer, presentationTime: pts)
        }
        capture = cap

        Task {
            do {
                try await cap.start()
                self.screenRecordingGranted = true
                log("[Capture] Screen Recording OK")
            } catch {
                self.screenRecordingGranted = false
                log("[Capture] ⚠️  Failed to start — Screen Recording permission likely not granted")
                log("[Capture]    System Settings → Privacy & Security → Screen & System Audio Recording → add ExDisplay")
            }
            self.onStateChanged?()
        }

        // Auto-run adb reverse on start and every 30 s to survive cable reconnects
        runADBReverse()
        adbTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.runADBReverse()
        }

        onStateChanged?()
    }

    private func teardown() {
        adbTimer?.invalidate();     adbTimer = nil
        metricsTimer?.invalidate(); metricsTimer = nil
        capture?.stop();        capture = nil
        encoder?.stop();        encoder = nil
        server?.stop();         server = nil
        input = nil
        virtualDisplay = nil    // releasing destroys the virtual display
        screenRecordingGranted = nil
        fps = 0; mbps = 0
    }

    // MARK: – Metrics

    private func startMetricsTimer() {
        lastFrames = 0; lastBytes = 0; fps = 0; mbps = 0
        metricsTimer?.invalidate()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickMetrics()
        }
    }

    private func tickMetrics() {
        guard let srv = server else { return }
        let s = srv.statsSnapshot()
        fps  = max(0, s.frames - lastFrames)
        mbps = Double(max(0, s.bytes - lastBytes)) * 8.0 / 1_000_000.0
        lastFrames = s.frames
        lastBytes = s.bytes
        // Menu reads metricsText lazily on open; no rebuild here.
    }

    private func restart() {
        teardown()
        onStateChanged?()
        // Give CoreGraphics a moment to release the old display before recreating.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.start()
        }
    }

    // MARK: – Settings

    func applySettings(_ new: Settings) {
        let old = settings
        guard new != old else { return }
        settings = new
        new.save()

        if new.width == old.width && new.height == old.height {
            // Only bitrate changed — apply live, don't disrupt the display/connection.
            encoder?.setBitrate(new.bitrateMbps * 1_000_000)
            onStateChanged?()
        } else {
            log("[AppController] Resolution \(old.width)×\(old.height) → \(new.width)×\(new.height); restarting pipeline")
            restart()
        }
    }

    // MARK: – Streaming

    func toggleStreaming() {
        guard let cap = capture else { return }
        if cap.isPaused {
            Task { await cap.resume(); self.onStateChanged?() }
        } else {
            cap.pause()
            onStateChanged?()
        }
    }

    // MARK: – ADB

    private let adbPath: String? = {
        for p in ["/opt/homebrew/bin/adb", "/usr/local/bin/adb"] {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        return nil
    }()

    private func runADBReverse() {
        guard let adb = adbPath else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: adb)
        p.arguments = ["reverse", "tcp:8888", "tcp:8888"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError  = FileHandle.nullDevice
        try? p.run()
    }

    // MARK: – Launch at login (LaunchAgent)

    var isLaunchAtLoginEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func toggleLaunchAtLogin() {
        if isLaunchAtLoginEnabled {
            try? FileManager.default.removeItem(at: launchAgentURL)
        } else {
            let execPath = ProcessInfo.processInfo.arguments[0]
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0"><dict>
                <key>Label</key><string>com.exdisplay.app</string>
                <key>ProgramArguments</key><array><string>\(execPath)</string></array>
                <key>RunAtLoad</key><true/>
                <key>KeepAlive</key><false/>
            </dict></plist>
            """
            let dir = launchAgentURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? plist.write(to: launchAgentURL, atomically: true, encoding: .utf8)
        }
    }

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.exdisplay.plist")
    }
}
