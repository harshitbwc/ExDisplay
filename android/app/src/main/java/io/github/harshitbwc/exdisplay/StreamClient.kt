package io.github.harshitbwc.exdisplay

import android.util.Log
import java.io.DataInputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder

private const val TAG = "StreamClient"
private const val RETRY_DELAY_MS = 3000L
private const val CONNECT_TIMEOUT_MS = 5000
private const val READ_TIMEOUT_MS = 10000

// Must match mac/Sources/ExDisplayCore/Protocol.swift
private const val PROTOCOL_VERSION = 3
private const val MAX_FRAME_BYTES = 8 * 1024 * 1024
private const val TYPE_VIDEO = 0
private const val TYPE_CONFIG = 1
private const val TYPE_TOUCH: Byte = 2
private const val TYPE_SCROLL: Byte = 3
private const val TYPE_SWIPE: Byte = 4

data class DisplayConfig(val width: Int, val height: Int, val rotation: Int)

class StreamClient(
    private val host: String = "127.0.0.1",
    private val port: Int = 8888,
    private val onConfig: (DisplayConfig) -> Unit,
    private val onFrame: (ByteArray) -> Unit,
    private val onConnected: () -> Unit = {},
    private val onDisconnected: () -> Unit = {},
    private val onStatus: (String) -> Unit = {}
) {
    @Volatile private var running = false
    @Volatile private var output: OutputStream? = null
    private var socket: Socket? = null

    fun start() {
        if (running) return
        running = true
        Thread({
            while (running) {
                try {
                    onStatus("Connecting…")
                    connectAndStream()
                } catch (e: ProtocolException) {
                    // Version/format mismatch — retrying won't help until the Mac app updates.
                    Log.e(TAG, "Protocol error: ${e.message}")
                    cleanup()
                    onDisconnected()
                    onStatus("Incompatible Mac app: ${e.message}")
                    break
                } catch (e: Exception) {
                    if (!running) break
                    Log.w(TAG, "Disconnected: ${e.message}")
                    cleanup()
                    onDisconnected()
                    onStatus("Disconnected — retrying in 3 s…")
                    try { Thread.sleep(RETRY_DELAY_MS) } catch (_: InterruptedException) { break }
                }
            }
            Log.d(TAG, "Reader loop exited")
        }, "exdisplay-reader").apply { isDaemon = true; start() }
    }

    private class ProtocolException(message: String) : Exception(message)

    private fun connectAndStream() {
        val sock = Socket()
        sock.tcpNoDelay = true
        sock.soTimeout = READ_TIMEOUT_MS
        sock.connect(InetSocketAddress(host, port), CONNECT_TIMEOUT_MS)
        socket = sock
        output = sock.getOutputStream()
        onConnected()
        onStatus("Connected")

        DataInputStream(sock.getInputStream().buffered(65536)).use { input ->
            while (running) {
                when (val type = input.read()) {
                    -1 -> return@use
                    TYPE_CONFIG -> {
                        val version = input.read()
                        if (version != PROTOCOL_VERSION) {
                            throw ProtocolException("protocol v$version, app expects v$PROTOCOL_VERSION")
                        }
                        val w = input.readInt()
                        val h = input.readInt()
                        val r = input.readInt()
                        if (w !in 1..16384 || h !in 1..16384) {
                            throw ProtocolException("bad dimensions ${w}x${h}")
                        }
                        Log.d(TAG, "Config: ${w}x${h} (proto v$version)")
                        onConfig(DisplayConfig(w, h, r))
                    }
                    TYPE_VIDEO -> {
                        val size = input.readInt()
                        if (size !in 1..MAX_FRAME_BYTES) {
                            // Desynced or hostile peer — drop and reconnect rather than OOM.
                            throw IllegalStateException("frame size $size out of range")
                        }
                        val buf = ByteArray(size)
                        input.readFully(buf)
                        onFrame(buf)
                    }
                    else -> throw IllegalStateException("unknown message type $type")
                }
            }
        }
        cleanup()
        if (running) { onDisconnected(); onStatus("Disconnected") }
    }

    private fun cleanup() {
        output = null
        try { socket?.close() } catch (_: Exception) {}
        socket = null
    }

    // Spawns a tiny high-priority thread so the UI thread never blocks on write
    fun sendTouch(action: Byte, x: Float, y: Float) {
        val out = output ?: return
        Thread({
            try {
                val buf = ByteBuffer.allocate(10).order(ByteOrder.BIG_ENDIAN)
                buf.put(TYPE_TOUCH)
                buf.put(action)
                buf.putFloat(x)
                buf.putFloat(y)
                out.write(buf.array())
                out.flush()
            } catch (e: Exception) {
                Log.e(TAG, "Touch send error: ${e.message}")
            }
        }, "exdisplay-touch").apply { priority = Thread.MAX_PRIORITY; isDaemon = true; start() }
    }

    // Two-finger scroll: pixel deltas. 9-byte message: type + dx(f32) + dy(f32).
    fun sendScroll(dx: Float, dy: Float) {
        val out = output ?: return
        Thread({
            try {
                val buf = ByteBuffer.allocate(9).order(ByteOrder.BIG_ENDIAN)
                buf.put(TYPE_SCROLL)
                buf.putFloat(dx)
                buf.putFloat(dy)
                out.write(buf.array())
                out.flush()
            } catch (e: Exception) {
                Log.e(TAG, "Scroll send error: ${e.message}")
            }
        }, "exdisplay-scroll").apply { priority = Thread.MAX_PRIORITY; isDaemon = true; start() }
    }

    // Three-finger swipe: 2-byte message: type + direction (0=L 1=R 2=U 3=D).
    fun sendSwipe(direction: Byte) {
        val out = output ?: return
        Thread({
            try {
                out.write(byteArrayOf(TYPE_SWIPE, direction))
                out.flush()
            } catch (e: Exception) {
                Log.e(TAG, "Swipe send error: ${e.message}")
            }
        }, "exdisplay-swipe").apply { priority = Thread.MAX_PRIORITY; isDaemon = true; start() }
    }

    fun stop() {
        running = false
        cleanup()
    }
}
