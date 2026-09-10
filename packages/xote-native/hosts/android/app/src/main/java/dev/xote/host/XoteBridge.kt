package dev.xote.host

import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import org.json.JSONObject

/**
 * A JavaScript engine, seen from the host.
 *
 * The interface exists because this is the one piece iOS gets for free and
 * Android does not: JavaScriptCore ships with iOS, and Android has no embedded
 * engine in the platform API. The realistic choices are QuickJS, Hermes or J2V8
 * — each a native dependency with its own build — and which one an app wants is
 * an app's decision, not this host's.
 *
 * So the host talks to *this*, and [WebViewRuntime] below is the implementation
 * that needs no dependency at all. Everything an engine has to do is here:
 * expose one object, and evaluate a string.
 */
interface XoteJsRuntime {
  /** Make `target`'s exported methods reachable from JavaScript as `name`. */
  fun expose(name: String, target: Any)

  /** Evaluate a script. Safe to call from any thread. */
  fun evaluate(source: String)

  fun release()
}

/**
 * The app thread, and the crossing to the UI thread.
 *
 * The same discipline as the iOS bridge: the app runs off the main thread, and
 * only finished batches cross to it. A slow update costs a late frame rather
 * than a frozen one.
 *
 * Batches arrive from the engine on whatever thread it runs on and are posted to
 * the main looper. Events go the other way. Both directions are ordered,
 * because a `Handler` queue is ordered and the engine's own calls are serial.
 */
class XoteBridge(private val host: XoteHost, private val runtime: XoteJsRuntime) {
  /**
   * Something went wrong that was contained rather than propagated: a JavaScript
   * exception, a batch the host could not apply, a malformed command. An app can
   * show something; by default it is logged.
   */
  var onError: ((String) -> Unit)? = null

  private val main = Handler(Looper.getMainLooper())

  /**
   * The object the bundle sees as `XoteBridge`. Only its exported methods are
   * reachable, and only strings cross — which is why the batch is JSON.
   */
  inner class Exported {
    @JavascriptInterface
    fun apply(json: String) {
      main.post {
        try {
          host.apply(json)
        } catch (error: Throwable) {
          report("batch could not be applied — ${error.message}")
        }
      }
    }

    /** What this host can apply. `install()` compares it against the bundle. */
    @JavascriptInterface
    fun protocolJson(): String =
      JSONObject()
        .put("min", XoteHost.PROTOCOL_MIN)
        .put("max", XoteHost.PROTOCOL_MAX)
        .toString()

    @JavascriptInterface
    fun log(message: String) {
      Log.d("Xote JS", message)
    }
  }

  init {
    runtime.expose("XoteBridge", Exported())

    host.onError = { message -> report(message) }
    host.onEvent = { id, name, payload -> dispatch(id, name, payload) }
  }

  /**
   * Load the bundle and mount the app.
   *
   * The prelude is the only platform-shaped JavaScript in the system, and it
   * exists so that `bundle/bootstrap.mjs` does not have to be. An exposed object
   * can only carry methods, and the bundle expects `XoteHost.protocol` to be a
   * value — so the prelude builds the shape the bundle expects out of the shape
   * the platform can provide. On iOS the same object is built in Swift.
   */
  fun start(bundle: String) {
    val prelude =
      """
      globalThis.XoteHost = {
        apply: function (json) { XoteBridge.apply(json) },
        protocol: JSON.parse(XoteBridge.protocolJson())
      };
      globalThis.console = {
        log: function () { XoteBridge.log(Array.prototype.join.call(arguments, " ")) },
        warn: function () { XoteBridge.log(Array.prototype.join.call(arguments, " ")) },
        error: function () { XoteBridge.log(Array.prototype.join.call(arguments, " ")) }
      };
      """
        .trimIndent()

    runtime.evaluate(prelude)
    runtime.evaluate(SHADOW_PROLOGUE + bundle + SHADOW_EPILOGUE)
    runtime.evaluate("xoteStart()")
  }

  companion object {
    /**
     * The bundle installs a shadow document as the ambient `document`, and in
     * an engine with no DOM it does that by assigning the global. [WebViewRuntime]
     * has a DOM: it evaluates in a page realm, where `Window.document` is
     * unforgeable and the assignment cannot land, so the app would never start.
     *
     * Evaluating the bundle inside a function whose parameter is named
     * `document` shadows the page's for every reference the bundle makes, and
     * `xoteBindDocument` is how the bundle writes to a binding it cannot reach
     * by name. It returns what it bound so the bundle can check the seam
     * actually took — see the note in `src/host/runtime.mjs`.
     *
     * This wraps whatever engine is behind [XoteJsRuntime], because it costs
     * one stack frame in an engine that does not need it and swapping in
     * QuickJS or Hermes should not change how the app is started. `xoteStart`
     * and `xoteDispatchEvent` are assigned to `globalThis` by the bundle, so
     * they stay reachable from outside the wrapper.
     */
    val SHADOW_PROLOGUE = """
      (function (document) {
      globalThis.xoteBindDocument = function (d) { return (document = d); };
    """.trimIndent() + "\n"

    val SHADOW_EPILOGUE = "\n})(undefined);"
  }

  /** A view reported something. Deliver it on the app thread, where the app is. */
  private fun dispatch(id: Int, name: String, payload: Map<String, Any>) {
    val json = JSONObject(payload).toString()
    runtime.evaluate(
      "xoteDispatchEvent(${id}, ${JSONObject.quote(name)}, ${JSONObject.quote(json)})"
    )
  }

  private fun report(message: String) {
    val handler = onError
    if (handler != null) main.post { handler(message) } else Log.e("Xote", message)
  }

  fun release() = runtime.release()
}

/**
 * A JavaScript engine with no dependency: the one inside `WebView`.
 *
 * **Read the caveats before shipping this.** It is here so the host runs out of
 * the box and so the seam above has a working implementation to be checked
 * against, not because it is the right engine for an app.
 *
 * - The page is `about:blank` and nothing is ever loaded over the network, but
 *   a `WebView` is still a large object to carry for a JavaScript engine.
 * - `evaluateJavascript` must be called from the UI thread, so [evaluate] posts.
 *   Script *execution* happens off it, and `@JavascriptInterface` methods arrive
 *   on a private binder thread — so the app really does run off the main thread,
 *   which is the property that matters.
 * - An interface added with `addJavascriptInterface` only appears to JavaScript
 *   on the *next* page load, and a fresh `WebView` has loaded nothing at all —
 *   so [expose] loads `about:blank` and [evaluate] queues until it has. Without
 *   that the bundle would evaluate against a `XoteBridge` that does not exist.
 * - `addJavascriptInterface` is a documented remote-code surface when a
 *   `WebView` loads untrusted content. This one loads none but `about:blank`:
 *   no network, JavaScript on and everything else off.
 * - It runs in a page realm, which already has a `document`. That is what
 *   [XoteBridge.SHADOW_PROLOGUE] is for.
 * - There is no bytecode cache, so startup pays for parsing the bundle every
 *   launch. QuickJS or Hermes is the answer to that, and swapping one in is
 *   this interface and about twenty lines.
 */
class WebViewRuntime(context: android.content.Context) : XoteJsRuntime {
  private val main = Handler(Looper.getMainLooper())
  private val webView = WebView(context)

  /** Scripts handed over before the blank page finished loading, in order. */
  private val pending = ArrayDeque<String>()
  private var loaded = false

  init {
    webView.settings.javaScriptEnabled = true
    webView.settings.domStorageEnabled = false
    webView.settings.allowFileAccess = false
    webView.settings.allowContentAccess = false
    webView.webViewClient =
      object : WebViewClient() {
        override fun onPageFinished(view: WebView, url: String) {
          loaded = true
          while (pending.isNotEmpty()) view.evaluateJavascript(pending.removeFirst(), null)
        }
      }
  }

  /**
   * Only ever called once, during bootstrap — a second call would reload the
   * page and take everything the first one evaluated with it.
   */
  override fun expose(name: String, target: Any) {
    main.post {
      webView.addJavascriptInterface(target, name)
      loaded = false
      webView.loadUrl("about:blank")
    }
  }

  override fun evaluate(source: String) {
    main.post { if (loaded) webView.evaluateJavascript(source, null) else pending.addLast(source) }
  }

  override fun release() {
    main.post {
      pending.clear()
      webView.destroy()
    }
  }
}
