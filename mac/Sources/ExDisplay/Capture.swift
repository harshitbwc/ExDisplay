import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreVideo

typealias FrameHandler = (CVPixelBuffer, CMTime) -> Void

final class Capture: NSObject {
    private var stream: SCStream?
    private let displayID: CGDirectDisplayID
    private let onFrame: FrameHandler
    private(set) var isPaused = false   // intentional pause — suppresses auto-restart

    init(displayID: CGDirectDisplayID, onFrame: @escaping FrameHandler) {
        self.displayID = displayID
        self.onFrame = onFrame
    }

    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let scDisplay = content.displays.first(where: { $0.displayID == self.displayID }) else {
            throw CaptureError.displayNotFound(displayID)
        }

        guard let mode = CGDisplayCopyDisplayMode(displayID) else {
            throw CaptureError.noDisplayMode
        }
        let pw = mode.pixelWidth
        let ph = mode.pixelHeight

        let cfg = SCStreamConfiguration()
        cfg.width = pw
        cfg.height = ph
        cfg.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        cfg.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        cfg.showsCursor = true
        cfg.queueDepth = 4
        cfg.scalesToFit = false

        let filter = SCContentFilter(display: scDisplay, excludingApplications: [], exceptingWindows: [])
        let s = SCStream(filter: filter, configuration: cfg, delegate: self)
        try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        try await s.startCapture()
        self.stream = s
        log("[Capture] Started. Physical: \(pw)×\(ph) @ 60 fps, NV12")
    }

    // Intentional pause — stops SCStream so DRM apps (Netflix etc.) can play.
    // The virtual display and tablet connection stay alive; tablet freezes on last frame.
    func pause() {
        guard !isPaused else { return }
        isPaused = true
        stream?.stopCapture(completionHandler: nil)
        stream = nil
        log("[Capture] Paused. DRM content (Netflix etc.) should now work on other displays.")
        log("[Capture] Type 'r' + Enter to resume streaming to tablet.")
    }

    func resume() async {
        guard isPaused else { return }
        isPaused = false
        log("[Capture] Resuming…")
        do {
            try await start()
        } catch {
            log("[Capture] Resume failed: \(error)")
        }
    }

    func stop() {
        isPaused = true   // prevent auto-restart on explicit stop
        stream?.stopCapture(completionHandler: nil)
        stream = nil
    }
}

extension Capture: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        log("[Capture] Stream stopped: \(error)")
        self.stream = nil
        guard !isPaused else { return }   // intentional pause — do not restart

        // Display reconfigured (e.g. displays rearranged) — restart after settling
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            log("[Capture] Restarting stream…")
            do {
                try await self.start()
            } catch {
                log("[Capture] Restart failed: \(error)")
            }
        }
    }
}

extension Capture: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sb: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let pixelBuffer = CMSampleBufferGetImageBuffer(sb) else { return }
        onFrame(pixelBuffer, CMSampleBufferGetPresentationTimeStamp(sb))
    }
}

enum CaptureError: Error {
    case displayNotFound(CGDirectDisplayID)
    case noDisplayMode
}
