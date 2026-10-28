import Foundation
import CoreGraphics
import ApplicationServices
import CGVirtualDisplayBridge

final class Input {
    // nil source = let the system fill in the source (avoids HID-state permission issues)
    private let displayID: CGDirectDisplayID
    private var isDown = false

    init(displayID: CGDirectDisplayID) {
        self.displayID = displayID
        checkAccessibility()
    }

    @discardableResult
    static func requestAccessibility() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    private func checkAccessibility() {
        if AXIsProcessTrusted() {
            log("[Input] Accessibility OK — touch injection ready")
        } else {
            log("[Input] ⚠️  Accessibility not granted — touch will not work")
        }
    }

    // Called on main thread only (AppController dispatches here).
    func handleTouch(action: UInt8, nx: Float, ny: Float) {
        guard AXIsProcessTrusted() else { return }

        // Guard against NaN / infinity from malformed Android packets
        guard nx.isFinite, ny.isFinite else { return }

        let b = CGDisplayBounds(displayID)
        let pt = CGPoint(
            x: b.origin.x + Double(nx) * b.width,
            y: b.origin.y + Double(ny) * b.height
        )

        let type: CGEventType
        switch action {
        case 0: isDown = true;  type = .leftMouseDown
        case 1: type = isDown ? .leftMouseDragged : .mouseMoved
        case 2: isDown = false; type = .leftMouseUp
        default: return
        }

        guard let evt = CGEvent(
            mouseEventSource: nil,          // nil = system default source
            mouseType: type,
            mouseCursorPosition: pt,
            mouseButton: .left
        ) else {
            log("[Input] CGEvent creation returned nil")
            return
        }

        if action == 0 { evt.setIntegerValueField(.mouseEventClickState, value: 1) }

        // ExDisplayPostEvent wraps CGEventPost in ObjC @try/@catch.
        // Swift cannot catch ObjC exceptions; without this wrapper they kill the process.
        let ok = ExDisplayPostEvent(evt, .cgSessionEventTap)
        if !ok { log("[Input] CGEventPost failed (caught ObjC exception — check Console.app)") }
    }

    // Two-finger scroll → scroll-wheel events. dx/dy are pixel deltas.
    // Called on main thread only.
    func handleScroll(dx: Float, dy: Float) {
        guard AXIsProcessTrusted() else { return }
        guard dx.isFinite, dy.isFinite else { return }

        // Clamp to a safe range before Float→Int32 (avoids trap on huge values).
        let vy = Int32(max(-100_000, min(100_000, dy)))
        let vx = Int32(max(-100_000, min(100_000, dx)))

        // wheel1 = vertical, wheel2 = horizontal; pixel units.
        guard let evt = CGEvent(scrollWheelEvent2Source: nil, units: .pixel,
                                wheelCount: 2, wheel1: vy, wheel2: vx, wheel3: 0) else { return }
        _ = ExDisplayPostEvent(evt, .cgSessionEventTap)
    }

    // Three-finger swipe → Mission Control keyboard shortcuts (Ctrl+arrow).
    // macOS 3-finger trackpad gestures can't be synthesized via CGEvent, but their
    // keyboard equivalents are reliable. Requires Mission Control shortcuts enabled
    // (default) and >1 Space for left/right to do anything.
    //   0=left→Ctrl+Right (next Space)   1=right→Ctrl+Left (prev Space)
    //   2=up→Ctrl+Up (Mission Control)   3=down→Ctrl+Down (App Exposé)
    // Called on main thread only.
    func handleSwipe(direction: UInt8) {
        guard AXIsProcessTrusted() else { return }

        let keyRightArrow: CGKeyCode = 0x7C
        let keyLeftArrow:  CGKeyCode = 0x7B
        let keyUpArrow:    CGKeyCode = 0x7E
        let keyDownArrow:  CGKeyCode = 0x7D

        let key: CGKeyCode
        switch direction {
        case 0: key = keyRightArrow   // swipe left → next Space
        case 1: key = keyLeftArrow    // swipe right → previous Space
        case 2: key = keyUpArrow      // swipe up → Mission Control
        case 3: key = keyDownArrow    // swipe down → App Exposé
        default: return
        }

        postKey(key, down: true,  flags: .maskControl)
        postKey(key, down: false, flags: .maskControl)
    }

    private func postKey(_ key: CGKeyCode, down: Bool, flags: CGEventFlags) {
        guard let evt = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down) else { return }
        evt.flags = flags
        _ = ExDisplayPostEvent(evt, .cgSessionEventTap)
    }
}
