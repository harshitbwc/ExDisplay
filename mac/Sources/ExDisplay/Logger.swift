import Foundation
import os

// Unified logging — visible in Terminal without any file writing:
//   log stream --predicate 'subsystem == "com.exdisplay.app"' --style compact
private let _osLog = os.Logger(subsystem: "com.exdisplay.app", category: "main")

// In-memory ring buffer — holds the last 500 lines so the log window
// can show history when first opened. Zero disk I/O.
private let _buffer = _LogBuffer()

// Set by AppDelegate when the log window is created
var sharedLogWindow: LogWindow?

func log(_ message: String) {
    let ts = _timeFmt.string(from: Date())
    let line = "[\(ts)]  \(message)"

    Swift.print(line)           // stdout (visible if launched from Terminal)
    _osLog.log("\(message)")    // unified log (terminal: log stream …)
    _buffer.append(line)
    DispatchQueue.main.async { sharedLogWindow?.append(line) }
}

// Called by LogWindow.show() to populate history before live updates start
func logBufferSnapshot() -> [String] { _buffer.snapshot() }

// ── Internal ─────────────────────────────────────────────────────────────────

private let _timeFmt: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f
}()

private final class _LogBuffer {
    private var lines: [String] = []
    private let lock = NSLock()
    private let max = 500

    func append(_ line: String) {
        lock.lock(); defer { lock.unlock() }
        lines.append(line)
        if lines.count > max { lines.removeFirst() }
    }

    func snapshot() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return lines
    }
}
