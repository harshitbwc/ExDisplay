package io.github.harshitbwc.exdisplay

import android.media.MediaCodec
import android.media.MediaFormat
import android.os.Build
import android.util.Log
import android.view.Surface
import java.util.concurrent.ConcurrentLinkedQueue

private const val TAG = "Decoder"

class Decoder(private val surface: Surface) {

    private var codec: MediaCodec? = null
    private val frameQ  = ConcurrentLinkedQueue<ByteArray>()
    private val bufferQ = ConcurrentLinkedQueue<Int>()

    fun configure(width: Int, height: Int) {
        reset()   // always clean up before reconfiguring (handles reconnect)

        val c = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        c.setCallback(object : MediaCodec.Callback() {
            override fun onInputBufferAvailable(codec: MediaCodec, index: Int) {
                val frame = frameQ.poll()
                if (frame != null) submitFrame(codec, index, frame)
                else bufferQ.offer(index)
            }
            override fun onOutputBufferAvailable(codec: MediaCodec, index: Int, info: MediaCodec.BufferInfo) {
                codec.releaseOutputBuffer(index, true)
            }
            override fun onError(codec: MediaCodec, e: MediaCodec.CodecException) {
                Log.e(TAG, "Codec error: $e")
            }
            override fun onOutputFormatChanged(codec: MediaCodec, format: MediaFormat) {
                Log.d(TAG, "Output format: $format")
            }
        })

        var configured = false
        if (!configured) runCatching {
            c.configure(buildFormat(width, height, lowLatency = true, priority = true), surface, null, 0)
            Log.d(TAG, "Tier-1 (full low-latency)")
            configured = true
        }.onFailure { Log.w(TAG, "Tier-1 failed: $it") }

        if (!configured) runCatching {
            c.configure(buildFormat(width, height, lowLatency = false, priority = true), surface, null, 0)
            Log.d(TAG, "Tier-2 (no KEY_LOW_LATENCY)")
            configured = true
        }.onFailure { Log.w(TAG, "Tier-2 failed: $it") }

        if (!configured) {
            c.configure(buildFormat(width, height, lowLatency = false, priority = false), surface, null, 0)
            Log.d(TAG, "Tier-3 (minimal)")
        }

        c.start()
        codec = c
        Log.d(TAG, "Decoder started ${width}×${height}")
    }

    private fun buildFormat(width: Int, height: Int, lowLatency: Boolean, priority: Boolean): MediaFormat {
        val f = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) f.setInteger(MediaFormat.KEY_MAX_B_FRAMES, 0)
        if (priority) f.setInteger(MediaFormat.KEY_PRIORITY, 0)
        if (lowLatency && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) f.setInteger(MediaFormat.KEY_LOW_LATENCY, 1)
        return f
    }

    fun feedFrame(data: ByteArray) {
        val c = codec ?: return
        val idx = bufferQ.poll()
        if (idx != null) submitFrame(c, idx, data)
        else {
            frameQ.offer(data)
            while (frameQ.size > 3) frameQ.poll()   // drop oldest if falling behind
        }
    }

    private fun submitFrame(codec: MediaCodec, index: Int, data: ByteArray) {
        runCatching {
            val buf = codec.getInputBuffer(index) ?: return
            buf.clear()
            val len = minOf(data.size, buf.remaining())
            buf.put(data, 0, len)
            codec.queueInputBuffer(index, 0, len, System.nanoTime() / 1000L, 0)
        }.onFailure { Log.e(TAG, "submitFrame: $it") }
    }

    fun reset() {
        runCatching { codec?.stop() }
        runCatching { codec?.release() }
        codec = null
        frameQ.clear()
        bufferQ.clear()
        Log.d(TAG, "Decoder reset")
    }
}
