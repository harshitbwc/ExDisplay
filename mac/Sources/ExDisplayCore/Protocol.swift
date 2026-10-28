import Foundation

/// ExDisplay wire protocol — shared constants and pure (system-free) codec.
///
/// All multi-byte fields are big-endian.
///
/// Mac → Android
///   type 1 = display config: [version: u8][width: u32][height: u32][rotation: u32]
///   type 0 = video frame:    [size: u32][H.264 Annex-B bytes]
/// Android → Mac
///   type 2 = touch:          [action: u8][x: f32][y: f32]   (x,y normalised 0..1)
///   type 3 = scroll:         [dx: f32][dy: f32]             (pixel deltas)
///   type 4 = swipe:          [direction: u8]                (3-finger; 0=L 1=R 2=U 3=D)
public enum Proto {
    /// Bump whenever the wire format changes incompatibly. Both ends must match.
    /// v2: added inbound scroll messages (type 3).
    /// v3: added 3-finger swipe messages (type 4).
    public static let version: UInt8 = 3

    /// Hard ceiling on a single video frame. A keyframe at 1340×800/18 Mbps is well
    /// under 1 MB; 8 MB is generous headroom while still rejecting malformed/huge sizes
    /// before allocation (prevents OOM from a desynced or hostile peer).
    public static let maxFrameBytes: Int = 8 * 1024 * 1024

    // Message type tags
    public static let typeVideo:  UInt8 = 0
    public static let typeConfig: UInt8 = 1
    public static let typeTouch:  UInt8 = 2
    public static let typeScroll: UInt8 = 3
    public static let typeSwipe:  UInt8 = 4

    // Fixed wire sizes of inbound messages
    public static let touchMessageSize  = 10   // type + action + x(f32) + y(f32)
    public static let scrollMessageSize = 9    // type + dx(f32) + dy(f32)
    public static let swipeMessageSize  = 2    // type + direction(u8)

    // 3-finger swipe directions
    public static let swipeLeft:  UInt8 = 0
    public static let swipeRight: UInt8 = 1
    public static let swipeUp:    UInt8 = 2
    public static let swipeDown:  UInt8 = 3
}

/// Pure byte (de)serialisation. No Network / CoreGraphics dependencies so it is
/// unit-testable and fuzzable in isolation. This is where the crash-prone parsing
/// lives, so it is deliberately defensive.
public enum ProtoCodec {

    // MARK: Encoding (Mac → Android)

    public static func u32be(_ v: UInt32) -> [UInt8] {
        [UInt8(truncatingIfNeeded: v >> 24),
         UInt8(truncatingIfNeeded: v >> 16),
         UInt8(truncatingIfNeeded: v >> 8),
         UInt8(truncatingIfNeeded: v)]
    }

    public static func encodeConfig(width: UInt32, height: UInt32, rotation: UInt32) -> [UInt8] {
        var b: [UInt8] = [Proto.typeConfig, Proto.version]
        b += u32be(width)
        b += u32be(height)
        b += u32be(rotation)
        return b
    }

    /// type(0) + size(u32) + payload
    public static func encodeFrameHeader(payloadCount: Int) -> [UInt8] {
        [Proto.typeVideo] + u32be(UInt32(truncatingIfNeeded: payloadCount))
    }

    // MARK: Decoding (Android → Mac)

    public static func readU32BE(_ b: [UInt8], at i: Int) -> UInt32? {
        guard i >= 0, i + 4 <= b.count else { return nil }
        return UInt32(b[i]) << 24 | UInt32(b[i+1]) << 16 | UInt32(b[i+2]) << 8 | UInt32(b[i+3])
    }

    private static func readF32BE(_ b: [UInt8], at i: Int) -> Float? {
        guard let bits = readU32BE(b, at: i) else { return nil }
        return Float(bitPattern: bits)
    }

    public enum Inbound: Equatable {
        case touch(action: UInt8, x: Float, y: Float)
        case scroll(dx: Float, dy: Float)
        case swipe(direction: UInt8)
    }

    public enum ParseResult: Equatable {
        case ok([Inbound])
        /// Stream is desynced (unknown type byte). Caller should drop the connection.
        case desync
    }

    /// Consumes as many whole inbound messages as are buffered, dispatching by type
    /// byte. Mutates `buf`, leaving any trailing partial message in place. Index-safe
    /// regardless of how many messages were already consumed (operates on a 0-based Array).
    public static func parseInbound(_ buf: inout [UInt8]) -> ParseResult {
        var out: [Inbound] = []
        while let type = buf.first {
            switch type {
            case Proto.typeTouch:
                guard buf.count >= Proto.touchMessageSize else { return .ok(out) }  // wait for more
                let action = buf[1]
                guard let x = readF32BE(buf, at: 2), let y = readF32BE(buf, at: 6) else { return .ok(out) }
                out.append(.touch(action: action, x: x, y: y))
                buf.removeFirst(Proto.touchMessageSize)

            case Proto.typeScroll:
                guard buf.count >= Proto.scrollMessageSize else { return .ok(out) }  // wait for more
                guard let dx = readF32BE(buf, at: 1), let dy = readF32BE(buf, at: 5) else { return .ok(out) }
                out.append(.scroll(dx: dx, dy: dy))
                buf.removeFirst(Proto.scrollMessageSize)

            case Proto.typeSwipe:
                guard buf.count >= Proto.swipeMessageSize else { return .ok(out) }  // wait for more
                out.append(.swipe(direction: buf[1]))
                buf.removeFirst(Proto.swipeMessageSize)

            default:
                return .desync
            }
        }
        return .ok(out)
    }

    /// Validate a frame size read off the wire before allocating for it.
    public static func isValidFrameSize(_ size: Int) -> Bool {
        size > 0 && size <= Proto.maxFrameBytes
    }
}
