package io.github.harshitbwc.exdisplay

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.WindowManager
import android.widget.Button

class MainActivity : Activity(), SurfaceHolder.Callback {

    private lateinit var surfaceView: SurfaceView
    private lateinit var statusDot: View
    private lateinit var pauseButton: Button

    private var client: StreamClient? = null
    private var decoder: Decoder? = null
    private var decoderReady = false
    private var userPaused = false

    // Gesture state: 1 finger = cursor, 2 fingers = scroll, 3 fingers = swipe
    private var scrolling = false
    private var cursorDownSent = false
    private var lastFocusX = 0f
    private var lastFocusY = 0f
    private val scrollGain = 2.0f
    private val invertScrollX = false   // flip if horizontal scroll feels reversed
    private val invertScrollY = false   // flip if vertical scroll feels reversed

    // 3-finger swipe state
    private var swiping = false
    private var swipeFired = false
    private var swipeStartX = 0f
    private var swipeStartY = 0f
    private val invertSwipeX = false    // flip if Space switching feels reversed


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        setContentView(R.layout.activity_main)

        surfaceView  = findViewById(R.id.surfaceView)
        statusDot    = findViewById(R.id.statusDot)
        pauseButton  = findViewById(R.id.pauseButton)

        surfaceView.holder.addCallback(this)

        // Touch listener on SurfaceView — the Button above it in Z-order intercepts
        // its own touches; everything else on the surface reaches this listener.
        surfaceView.setOnTouchListener { v, e -> handleTouch(v, e) }

        pauseButton.setOnClickListener {
            if (userPaused) resumeStreaming() else pauseStreaming()
        }

        setDot(yellow)
    }

    // ── Streaming control ─────────────────────────────────────────────────────

    private fun pauseStreaming() {
        userPaused = true
        client?.stop()
        client = null
        decoder?.reset()
        decoderReady = false
        pauseButton.text = "▶"
        setDot(yellow)
    }

    private fun resumeStreaming() {
        userPaused = false
        pauseButton.text = "⏸"
        setDot(yellow)
        startClient()
    }

    private fun startClient() {
        val dec = decoder ?: return
        val cli = StreamClient(
            onConfig = { config ->
                decoderReady = false
                dec.reset()
                dec.configure(config.width, config.height)
                decoderReady = true
            },
            onFrame = { data ->
                if (decoderReady) dec.feedFrame(data)
            },
            onConnected = {
                runOnUiThread { setDot(green); pauseButton.text = "⏸" }
            },
            onDisconnected = {
                decoderReady = false
                if (!userPaused) runOnUiThread { setDot(yellow) }
            },
            onStatus = { /* dot handles status visually */ }
        )
        client = cli
        cli.start()
    }

    // ── Touch forwarding to Mac ───────────────────────────────────────────────

    private fun handleTouch(v: View, event: MotionEvent): Boolean {
        val c = client ?: return false
        if (userPaused) return false

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                scrolling = false
                sendCursor(c, v, event, 0)          // cursor down
                cursorDownSent = true
            }

            MotionEvent.ACTION_POINTER_DOWN -> {
                if (cursorDownSent) {
                    sendCursor(c, v, event, 2)       // cursor up — fingers took over
                    cursorDownSent = false
                }
                if (event.pointerCount >= 3) {
                    // Third finger → swipe mode (overrides scroll).
                    scrolling = false
                    swiping = true
                    swipeFired = false
                    val f = focus(event, -1)
                    swipeStartX = f[0]; swipeStartY = f[1]
                } else {
                    // Second finger → scroll mode.
                    scrolling = true
                    val f = focus(event, -1)
                    lastFocusX = f[0]; lastFocusY = f[1]
                }
            }

            MotionEvent.ACTION_MOVE -> {
                when {
                    swiping -> detectSwipe(c, v, event)
                    scrolling -> {
                        val f = focus(event, -1)
                        var dx = (f[0] - lastFocusX) * scrollGain
                        var dy = (f[1] - lastFocusY) * scrollGain
                        lastFocusX = f[0]; lastFocusY = f[1]
                        if (invertScrollX) dx = -dx
                        if (invertScrollY) dy = -dy
                        if (dx != 0f || dy != 0f) c.sendScroll(dx, dy)
                    }
                    else -> sendCursor(c, v, event, 1)   // cursor move / drag
                }
            }

            MotionEvent.ACTION_POINTER_UP -> {
                // A finger lifted. If dropping below 3, leave swipe mode. Recompute
                // centroid (excluding the lifting finger) so the gesture doesn't jump.
                if (event.pointerCount - 1 < 3) swiping = false
                val f = focus(event, event.actionIndex)
                lastFocusX = f[0]; lastFocusY = f[1]
            }

            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                if (!scrolling && !swiping && cursorDownSent) {
                    sendCursor(c, v, event, 2)       // cursor up
                }
                scrolling = false
                swiping = false
                cursorDownSent = false
            }
        }
        return true
    }

    // Fires one swipe per 3-finger gesture once the centroid passes a threshold.
    private fun detectSwipe(c: StreamClient, v: View, event: MotionEvent) {
        if (swipeFired) return
        val f = focus(event, -1)
        val dx = f[0] - swipeStartX
        val dy = f[1] - swipeStartY
        val threshX = v.width * 0.12f
        val threshY = v.height * 0.12f

        if (kotlin.math.abs(dx) > threshX && kotlin.math.abs(dx) > kotlin.math.abs(dy)) {
            var left = dx < 0
            if (invertSwipeX) left = !left
            c.sendSwipe(if (left) 0 else 1)          // 0=left, 1=right
            swipeFired = true
        } else if (kotlin.math.abs(dy) > threshY) {
            c.sendSwipe(if (dy < 0) 2 else 3)        // 2=up, 3=down
            swipeFired = true
        }
    }

    // Centroid of active pointers, optionally skipping one (used on POINTER_UP).
    private fun focus(e: MotionEvent, skipIndex: Int): FloatArray {
        var sx = 0f; var sy = 0f; var n = 0
        for (i in 0 until e.pointerCount) {
            if (i == skipIndex) continue
            sx += e.getX(i); sy += e.getY(i); n++
        }
        return if (n == 0) floatArrayOf(0f, 0f) else floatArrayOf(sx / n, sy / n)
    }

    private fun sendCursor(c: StreamClient, v: View, e: MotionEvent, action: Byte) {
        val nx = (e.getX(0) / v.width).coerceIn(0f, 1f)
        val ny = (e.getY(0) / v.height).coerceIn(0f, 1f)
        c.sendTouch(action, nx, ny)
    }

    // ── Status dot ───────────────────────────────────────────────────────────

    private val green  = Color.parseColor("#4CAF50")
    private val yellow = Color.parseColor("#FFCC00")

    private fun setDot(color: Int) {
        val d = (statusDot.background as? GradientDrawable) ?: run {
            val gd = GradientDrawable()
            gd.shape = GradientDrawable.OVAL
            statusDot.background = gd
            gd
        }
        d.setColor(color)
    }

    // ── SurfaceHolder.Callback ────────────────────────────────────────────────

    override fun surfaceCreated(holder: SurfaceHolder) {
        val dec = Decoder(holder.surface)
        decoder = dec
        decoderReady = false
        if (!userPaused) startClient()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, w: Int, h: Int) {}

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        client?.stop(); client = null
        decoder?.reset(); decoder = null
        decoderReady = false
    }

    // ── Immersive fullscreen ──────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            or View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        )
    }
}
