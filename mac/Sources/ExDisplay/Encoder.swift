import Foundation
import VideoToolbox
import CoreMedia
import CoreVideo

// (annexBData, isKeyframe)
typealias EncodedFrameHandler = (Data, Bool) -> Void

final class Encoder {
    private var session: VTCompressionSession?
    private let onEncoded: EncodedFrameHandler

    init(width: Int, height: Int, bitrate: Int, onEncoded: @escaping EncodedFrameHandler) throws {
        self.onEncoded = onEncoded

        var sess: VTCompressionSession?
        let st = VTCompressionSessionCreate(
            allocator: nil,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &sess
        )
        guard st == noErr, let s = sess else { throw EncoderError.sessionCreateFailed(st) }

        let props: [(CFString, Any)] = [
            (kVTCompressionPropertyKey_RealTime,              true),
            (kVTCompressionPropertyKey_ProfileLevel,          kVTProfileLevel_H264_Main_AutoLevel),
            (kVTCompressionPropertyKey_AllowFrameReordering,  false),
            (kVTCompressionPropertyKey_MaxKeyFrameInterval,   60),
            (kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, 1.0 as CFNumber),
            (kVTCompressionPropertyKey_AverageBitRate,        bitrate),
            (kVTCompressionPropertyKey_MaxFrameDelayCount,    0),
        ]
        for (k, v) in props {
            VTSessionSetProperty(s, key: k, value: v as CFTypeRef)
        }
        VTCompressionSessionPrepareToEncodeFrames(s)
        self.session = s
        log("[Encoder] H.264 session ready. \(width)×\(height), \(bitrate / 1_000_000) Mbps, GOP=60")
    }

    func encode(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) {
        guard let s = session else { return }
        var flags = VTEncodeInfoFlags()
        VTCompressionSessionEncodeFrame(
            s,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentationTime,
            duration: .invalid,
            frameProperties: nil,
            infoFlagsOut: &flags
        ) { [weak self] status, _, sampleBuffer in
            guard let self, status == noErr, let sb = sampleBuffer else { return }
            self.emit(sb)
        }
    }

    private func emit(_ sb: CMSampleBuffer) {
        // Detect keyframe via NotSync attachment (absent on IDR = is a keyframe)
        let notSync = (CMSampleBufferGetSampleAttachmentsArray(sb, createIfNecessary: false)
            as? [[CFString: Any]])?.first?[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
        let isKeyframe = !notSync

        guard let dataBuffer = sb.dataBuffer else { return }

        var annexB = Data()

        // Prepend SPS + PPS on every keyframe so the decoder can always init
        if isKeyframe, let fmt = sb.formatDescription {
            annexB.append(h264ParamSets(fmt))
        }

        // Convert AVCC (4-byte big-endian length prefix) → Annex-B (00 00 00 01 start code)
        var totalLen = 0
        var rawPtr: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0,
                                          lengthAtOffsetOut: nil,
                                          totalLengthOut: &totalLen,
                                          dataPointerOut: &rawPtr) == kCMBlockBufferNoErr,
              let ptr = rawPtr else { return }

        let start: [UInt8] = [0, 0, 0, 1]
        var offset = 0
        while offset + 4 <= totalLen {
            let b0 = UInt8(bitPattern: ptr[offset])
            let b1 = UInt8(bitPattern: ptr[offset + 1])
            let b2 = UInt8(bitPattern: ptr[offset + 2])
            let b3 = UInt8(bitPattern: ptr[offset + 3])
            let nalLen = Int(b0) << 24 | Int(b1) << 16 | Int(b2) << 8 | Int(b3)
            offset += 4
            guard offset + nalLen <= totalLen else { break }
            annexB.append(contentsOf: start)
            ptr.advanced(by: offset).withMemoryRebound(to: UInt8.self, capacity: nalLen) { p in
                annexB.append(p, count: nalLen)
            }
            offset += nalLen
        }

        onEncoded(annexB, isKeyframe)
    }

    private func h264ParamSets(_ desc: CMFormatDescription) -> Data {
        var data = Data()
        let start: [UInt8] = [0, 0, 0, 1]
        var count = 0
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            desc, parameterSetIndex: 0,
            parameterSetPointerOut: nil, parameterSetSizeOut: nil,
            parameterSetCountOut: &count, nalUnitHeaderLengthOut: nil)
        for i in 0..<count {
            var p: UnsafePointer<UInt8>?
            var sz = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                desc, parameterSetIndex: i,
                parameterSetPointerOut: &p, parameterSetSizeOut: &sz,
                parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil)
            if let p { data.append(contentsOf: start); data.append(p, count: sz) }
        }
        return data
    }

    /// Live bitrate change — no session rebuild needed, so the display is not disrupted.
    func setBitrate(_ bitsPerSecond: Int) {
        guard let s = session else { return }
        VTSessionSetProperty(s, key: kVTCompressionPropertyKey_AverageBitRate, value: bitsPerSecond as CFNumber)
        log("[Encoder] Bitrate → \(bitsPerSecond / 1_000_000) Mbps (live)")
    }

    func stop() {
        guard let s = session else { return }
        VTCompressionSessionCompleteFrames(s, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(s)
        session = nil
    }
}

enum EncoderError: Error {
    case sessionCreateFailed(OSStatus)
}
