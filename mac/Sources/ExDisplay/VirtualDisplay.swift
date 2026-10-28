import Foundation
import CoreGraphics
import CGVirtualDisplayBridge

final class VirtualDisplay {
    private let backing: CGVirtualDisplay
    let displayID: CGDirectDisplayID

    init?(width: Int, height: Int, refreshRate: Double = 60, ppi: Double = 182) {
        let desc = CGVirtualDisplayDescriptor()
        desc.name = "Tab A9"
        desc.vendorID = 0xEEEE
        desc.productID = 0x0001
        desc.serialNum = 0x0001
        desc.maxPixelsWide = UInt32(width)
        desc.maxPixelsHigh = UInt32(height)
        // mm = px * 25.4 / ppi
        desc.sizeInMillimeters = CGSize(width: Double(width) * 25.4 / ppi,
                                        height: Double(height) * 25.4 / ppi)

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 0
        settings.modes = [CGVirtualDisplayMode(width: UInt32(width), height: UInt32(height), refreshRate: refreshRate)]

        guard let vd = CGVirtualDisplay(descriptor: desc), vd.apply(settings) else {
            log("[ExDisplay] CGVirtualDisplay init/apply failed")
            return nil
        }
        self.backing = vd

        // The display may take up to ~5 s to register in CGGetOnlineDisplayList.
        let candidateID = CGDirectDisplayID(vd.displayID)
        var registered = false
        for attempt in 1...5 {
            if VirtualDisplay.isOnline(candidateID) {
                registered = true
                break
            }
            log("[ExDisplay] Waiting for display to register (attempt \(attempt)/5)…")
            Thread.sleep(forTimeInterval: 1.0)
        }

        guard registered else {
            log("[ExDisplay] Display did not appear in CGGetOnlineDisplayList after 5 s")
            return nil
        }

        self.displayID = candidateID
    }

    private static func isOnline(_ id: CGDirectDisplayID) -> Bool {
        var list = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetOnlineDisplayList(16, &list, &count)
        return list.prefix(Int(count)).contains(id)
    }
}
