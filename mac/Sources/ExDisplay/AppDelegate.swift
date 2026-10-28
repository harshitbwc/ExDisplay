import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let logWindow = LogWindow()
    private let menu = NSMenu()
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        sharedLogWindow = logWindow
        installCrashLogging()
        setupStatusBar()
        controller.onStateChanged = { [weak self] in
            DispatchQueue.main.async { guard let self else { return }; self.populate(self.menu) }
        }
        controller.start()
        Input.requestAccessibility()
    }

    /// Log uncaught ObjC exceptions before the process dies (retrievable via Show Logs / `log show`).
    private func installCrashLogging() {
        NSSetUncaughtExceptionHandler { ex in
            log("[CRASH] \(ex.name.rawValue): \(ex.reason ?? "")")
            for line in ex.callStackSymbols.prefix(20) { log("[CRASH]   \(line)") }
        }
    }

    // MARK: – Status bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let img = NSImage(systemSymbolName: "display.2", accessibilityDescription: "ExDisplay")
        img?.isTemplate = true
        statusItem.button?.image = img
        menu.delegate = self
        statusItem.menu = menu
        populate(menu)
    }

    // Refresh just before the menu opens, so live metrics are current.
    func menuNeedsUpdate(_ menu: NSMenu) { populate(menu) }

    private func populate(_ menu: NSMenu) {
        menu.removeAllItems()

        // ── Status ───────────────────────────────────────────────────────────
        var connStr: String
        if controller.isConnected {
            connStr = "● Tablet connected  \(controller.resolution)"
            if let m = controller.metricsText { connStr += "   ·   \(m)" }
        } else {
            connStr = "○ Waiting for tablet…"
        }
        addDisabled(to: menu, title: connStr)
        addDisabled(to: menu, title: controller.isStreaming ? "Streaming  ✓" : "Streaming paused")

        menu.addItem(.separator())

        // ── Controls ──────────────────────────────────────────────────────────
        let toggleTitle = controller.isStreaming
            ? "Pause Streaming  (for Netflix / DRM)"
            : "Resume Streaming"
        add(to: menu, title: toggleTitle, action: #selector(toggleStreaming), key: "p")

        menu.addItem(.separator())

        // ── Logs ──────────────────────────────────────────────────────────────
        let logsItem = add(to: menu, title: "Show Logs", action: #selector(showLogs), key: "l")
        logsItem.toolTip = "Terminal: log stream --predicate 'subsystem == \"com.exdisplay.app\"' --style compact"
        add(to: menu, title: "Copy Logs to Clipboard", action: #selector(copyLogs), key: "")

        menu.addItem(.separator())

        // ── Settings ──────────────────────────────────────────────────────────
        menu.addItem(buildSettingsMenuItem())

        menu.addItem(.separator())

        // ── Launch at login ───────────────────────────────────────────────────
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = controller.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(loginItem)

        // ── Warnings ──────────────────────────────────────────────────────────
        var hasWarning = false
        func warn(_ title: String, _ action: Selector) {
            if !hasWarning { menu.addItem(.separator()); hasWarning = true }
            add(to: menu, title: title, action: action, key: "")
        }
        if controller.screenRecordingGranted == false {
            warn("⚠️  Grant Screen Recording for Video", #selector(openScreenRecording))
        }
        if !AXIsProcessTrusted() {
            warn("⚠️  Grant Accessibility for Touch", #selector(openAccessibility))
        }
        if !controller.isAdbAvailable {
            warn("⚠️  adb not found — install android-platform-tools", #selector(noop))
        }
        if let err = controller.serverError {
            warn("⚠️  Server error: \(err)", #selector(noop))
        }

        menu.addItem(.separator())
        add(to: menu, title: "Quit ExDisplay", action: #selector(quit), key: "q")
    }

    @discardableResult
    private func add(to menu: NSMenu, title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    private func addDisabled(to menu: NSMenu, title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    // MARK: – Settings submenu

    private func buildSettingsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let s = controller.settings

        addDisabled(to: sub, title: "Resolution")
        for r in Settings.resolutions {
            let mi = NSMenuItem(title: "   \(r.label)", action: #selector(selectResolution(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = [r.w, r.h]
            mi.state = (r.w == s.width && r.h == s.height) ? .on : .off
            sub.addItem(mi)
        }

        sub.addItem(.separator())

        addDisabled(to: sub, title: "Bitrate")
        for mbps in Settings.bitrates {
            let mi = NSMenuItem(title: "   \(mbps) Mbps", action: #selector(selectBitrate(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = mbps
            mi.state = (mbps == s.bitrateMbps) ? .on : .off
            sub.addItem(mi)
        }

        sub.addItem(.separator())
        addDisabled(to: sub, title: "Changing resolution briefly reconnects the tablet")

        item.submenu = sub
        return item
    }

    @objc private func selectResolution(_ sender: NSMenuItem) {
        guard let wh = sender.representedObject as? [Int], wh.count == 2 else { return }
        var s = controller.settings
        s.width = wh[0]; s.height = wh[1]
        controller.applySettings(s)
    }

    @objc private func selectBitrate(_ sender: NSMenuItem) {
        guard let mbps = sender.representedObject as? Int else { return }
        var s = controller.settings
        s.bitrateMbps = mbps
        controller.applySettings(s)
    }

    // MARK: – Actions

    @objc private func quit()             { NSApp.terminate(self) }
    @objc private func noop()             {}
    @objc private func toggleStreaming()  { controller.toggleStreaming() }
    @objc private func showLogs()         { logWindow.toggle() }
    @objc private func toggleLogin()      { controller.toggleLaunchAtLogin(); populate(menu) }

    @objc private func copyLogs() {
        let text = logBufferSnapshot().joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        log("[ExDisplay] Logs copied to clipboard (\(logBufferSnapshot().count) lines)")
    }

    @objc private func openScreenRecording() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    @objc private func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
