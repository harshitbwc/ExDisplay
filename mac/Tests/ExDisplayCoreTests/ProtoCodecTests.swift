import XCTest
@testable import ExDisplayCore

final class ProtoCodecTests: XCTestCase {

    // MARK: u32 round-trip

    func testU32BERoundTrip() {
        for v: UInt32 in [0, 1, 255, 256, 65535, 1_340, 0x12345678, .max] {
            let bytes = ProtoCodec.u32be(v)
            XCTAssertEqual(bytes.count, 4)
            XCTAssertEqual(ProtoCodec.readU32BE(bytes, at: 0), v)
        }
    }

    func testReadU32BEBoundsSafe() {
        XCTAssertNil(ProtoCodec.readU32BE([1, 2, 3], at: 0))
        XCTAssertNil(ProtoCodec.readU32BE([1, 2, 3, 4], at: 1))
        XCTAssertNil(ProtoCodec.readU32BE([1, 2, 3, 4], at: -1))
        XCTAssertEqual(ProtoCodec.readU32BE([0, 0, 0, 0, 0, 1], at: 2), 1)
    }

    // MARK: config / frame encoding

    func testEncodeConfigLayout() {
        let b = ProtoCodec.encodeConfig(width: 1340, height: 800, rotation: 0)
        XCTAssertEqual(b[0], Proto.typeConfig)
        XCTAssertEqual(b[1], Proto.version)
        XCTAssertEqual(ProtoCodec.readU32BE(b, at: 2), 1340)
        XCTAssertEqual(ProtoCodec.readU32BE(b, at: 6), 800)
        XCTAssertEqual(ProtoCodec.readU32BE(b, at: 10), 0)
        XCTAssertEqual(b.count, 14)
    }

    func testEncodeFrameHeader() {
        let h = ProtoCodec.encodeFrameHeader(payloadCount: 12345)
        XCTAssertEqual(h[0], Proto.typeVideo)
        XCTAssertEqual(ProtoCodec.readU32BE(h, at: 1), 12345)
    }

    // MARK: message builders (mirror the Android encoders)

    private func touchBytes(_ action: UInt8, _ x: Float, _ y: Float) -> [UInt8] {
        [Proto.typeTouch, action] + ProtoCodec.u32be(x.bitPattern) + ProtoCodec.u32be(y.bitPattern)
    }
    private func scrollBytes(_ dx: Float, _ dy: Float) -> [UInt8] {
        [Proto.typeScroll] + ProtoCodec.u32be(dx.bitPattern) + ProtoCodec.u32be(dy.bitPattern)
    }
    private func swipeBytes(_ dir: UInt8) -> [UInt8] {
        [Proto.typeSwipe, dir]
    }

    // MARK: touch parsing

    func testParseSingleTouch() {
        var buf = touchBytes(0, 0.25, 0.75)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.touch(action: 0, x: 0.25, y: 0.75)])
        XCTAssertTrue(buf.isEmpty)
    }

    func testParseMultipleTouches() {
        var buf = touchBytes(0, 0.1, 0.1) + touchBytes(1, 0.2, 0.2) + touchBytes(2, 0.3, 0.3)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms.count, 3)
        XCTAssertEqual(ms[1], .touch(action: 1, x: 0.2, y: 0.2))
        XCTAssertTrue(buf.isEmpty)
    }

    func testParsePartialTouchRetained() {
        var buf = touchBytes(0, 0.5, 0.5) + [Proto.typeTouch, 1, 0x3e]
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms.count, 1)
        XCTAssertEqual(buf, [Proto.typeTouch, 1, 0x3e])
    }

    // MARK: scroll parsing

    func testParseSingleScroll() {
        var buf = scrollBytes(-3.0, 12.5)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.scroll(dx: -3.0, dy: 12.5)])
        XCTAssertTrue(buf.isEmpty)
    }

    func testParseMixedTouchAndScroll() {
        var buf = touchBytes(0, 0.1, 0.2) + scrollBytes(0, 10) + touchBytes(2, 0.1, 0.2)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.touch(action: 0, x: 0.1, y: 0.2),
                            .scroll(dx: 0, dy: 10),
                            .touch(action: 2, x: 0.1, y: 0.2)])
        XCTAssertTrue(buf.isEmpty)
    }

    func testParsePartialScrollRetained() {
        var buf = scrollBytes(1, 1) + [Proto.typeScroll, 0x00, 0x00]  // 1 whole + 3 leftover
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms.count, 1)
        XCTAssertEqual(buf, [Proto.typeScroll, 0x00, 0x00])
    }

    // MARK: swipe parsing

    func testParseSingleSwipe() {
        var buf = swipeBytes(Proto.swipeLeft)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.swipe(direction: Proto.swipeLeft)])
        XCTAssertTrue(buf.isEmpty)
    }

    func testParseMixedAllTypes() {
        var buf = touchBytes(0, 0.1, 0.2) + swipeBytes(Proto.swipeUp) + scrollBytes(0, 10) + swipeBytes(Proto.swipeRight)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.touch(action: 0, x: 0.1, y: 0.2),
                            .swipe(direction: Proto.swipeUp),
                            .scroll(dx: 0, dy: 10),
                            .swipe(direction: Proto.swipeRight)])
        XCTAssertTrue(buf.isEmpty)
    }

    func testParsePartialSwipeRetained() {
        var buf = swipeBytes(Proto.swipeDown) + [Proto.typeSwipe]   // 1 whole + 1 leftover (type only)
        guard case .ok(let ms) = ProtoCodec.parseInbound(&buf) else { return XCTFail("desync") }
        XCTAssertEqual(ms, [.swipe(direction: Proto.swipeDown)])
        XCTAssertEqual(buf, [Proto.typeSwipe])
    }

    // MARK: desync / empties

    func testParseDesyncOnBadType() {
        var buf: [UInt8] = [0x99, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        XCTAssertEqual(ProtoCodec.parseInbound(&buf), .desync)
    }

    func testParseEmptyAndShort() {
        var empty = [UInt8]()
        XCTAssertEqual(ProtoCodec.parseInbound(&empty), .ok([]))
        var shortTouch: [UInt8] = [Proto.typeTouch, 0, 0]
        XCTAssertEqual(ProtoCodec.parseInbound(&shortTouch), .ok([]))
        XCTAssertEqual(shortTouch.count, 3)
    }

    // MARK: fuzz — must never crash or hang

    func testParseFuzzNeverCrashes() {
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func next() -> UInt8 {
            seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
            return UInt8(truncatingIfNeeded: seed)
        }
        for _ in 0..<5000 {
            let n = Int(next()) % 64
            var buf = (0..<n).map { _ in next() }
            _ = ProtoCodec.parseInbound(&buf)
        }
    }

    func testFrameSizeValidation() {
        XCTAssertFalse(ProtoCodec.isValidFrameSize(0))
        XCTAssertFalse(ProtoCodec.isValidFrameSize(-1))
        XCTAssertFalse(ProtoCodec.isValidFrameSize(Proto.maxFrameBytes + 1))
        XCTAssertTrue(ProtoCodec.isValidFrameSize(1))
        XCTAssertTrue(ProtoCodec.isValidFrameSize(Proto.maxFrameBytes))
    }
}
