package dev.xote.host

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout

/**
 * Hosts one Xote app.
 *
 * The container it creates is the node the app knows as `"root"`, so mounting is
 * the same call a web app makes. It covers the whole window rather than the
 * insets, so the app's own padding decides where content starts — the same as on
 * iOS and in the web preview.
 */
class XoteActivity : Activity() {
  private lateinit var container: ViewGroup
  private var host: XoteHost? = null
  private var bridge: XoteBridge? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    container = XoteBox(this)
    container.setBackgroundColor(Color.BLACK)
    setContentView(
      container,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      ),
    )

    val host = XoteHost(container)
    this.host = host

    // The container has no size until it has been through a layout pass, so the
    // app is started once it does — and laid out again on every later pass, for
    // rotation and split-screen.
    container.viewTreeObserver.addOnGlobalLayoutListener { host.layoutNow() }
    container.post {
      val bundle = assets.open("xote-app.js").bufferedReader().use { it.readText() }
      val bridge = XoteBridge(host, WebViewRuntime(this))
      this.bridge = bridge
      bridge.start(bundle)
    }
  }

  override fun onDestroy() {
    bridge?.release()
    super.onDestroy()
  }
}
