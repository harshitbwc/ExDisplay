import Foundation

struct Resolution: Equatable {
    let w: Int
    let h: Int
    var label: String { "\(w) × \(h)" }
}

/// User-configurable settings, persisted in UserDefaults.
/// Port is intentionally fixed at 8888 (the Android client hardcodes it).
struct Settings: Equatable {
    var width: Int
    var height: Int
    var bitrateMbps: Int

    // Presets shown in the menu.
    static let resolutions: [Resolution] = [
        Resolution(w: 1340, h: 800),    // Tab A9 native
        Resolution(w: 1280, h: 800),
        Resolution(w: 1600, h: 1000),
        Resolution(w: 1920, h: 1200),
        Resolution(w: 2560, h: 1600),
    ]
    static let bitrates = [8, 12, 18, 25, 40]   // Mbps

    static let `default` = Settings(width: 1340, height: 800, bitrateMbps: 18)

    private enum Key {
        static let width = "exdisplay.width"
        static let height = "exdisplay.height"
        static let bitrate = "exdisplay.bitrateMbps"
    }

    static func load() -> Settings {
        let d = UserDefaults.standard
        guard d.object(forKey: Key.width) != nil else { return .default }
        let s = Settings(
            width: d.integer(forKey: Key.width),
            height: d.integer(forKey: Key.height),
            bitrateMbps: d.integer(forKey: Key.bitrate)
        )
        // Guard against corrupted/zero defaults.
        guard s.width > 0, s.height > 0, s.bitrateMbps > 0 else { return .default }
        return s
    }

    func save() {
        let d = UserDefaults.standard
        d.set(width, forKey: Key.width)
        d.set(height, forKey: Key.height)
        d.set(bitrateMbps, forKey: Key.bitrate)
    }
}
