import AppKit

final class LogWindow {
    private var panel: NSPanel?
    private weak var textView: NSTextView?

    func toggle() {
        if let p = panel, p.isVisible { p.orderOut(nil) } else { show() }
    }

    func show() {
        let isNew = panel == nil
        if isNew { build() }
        panel?.orderFrontRegardless()
        // On first open, fill history from the in-memory ring buffer
        if isNew {
            for line in logBufferSnapshot() { append(line) }
        }
    }

    func append(_ line: String) {
        guard let tv = textView else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(white: 0.85, alpha: 1)
        ]
        tv.textStorage?.append(NSAttributedString(string: line + "\n", attributes: attrs))
        tv.scrollRangeToVisible(NSRange(location: tv.string.utf16.count, length: 0))
    }

    private func build() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 280),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.title = "ExDisplay — Logs"
        p.isFloatingPanel = true
        p.isReleasedWhenClosed = false
        p.center()

        let scroll = NSScrollView(frame: p.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.backgroundColor = NSColor(white: 0.1, alpha: 1)

        let tv = NSTextView(frame: scroll.contentView.bounds)
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = NSColor(white: 0.1, alpha: 1)
        tv.textContainerInset = NSSize(width: 8, height: 8)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = true
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: CGFloat.greatestFiniteMagnitude)
        tv.autoresizingMask = [.width]

        scroll.documentView = tv
        p.contentView?.addSubview(scroll)

        self.panel = p
        self.textView = tv
    }
}
