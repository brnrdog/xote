package dev.xote.host

import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView

/**
 * A pool of views, so a list that churns rows stops allocating.
 *
 * A transliteration of `native/host/pool.mjs`. **Keep the three in step.**
 *
 * `destroy` is the natural place to return a view: the protocol guarantees the
 * id will never be referenced again, which is exactly the guarantee a pool
 * needs. `create` is the natural place to take one back out.
 *
 * **A view is reset on release, not on acquire.** Releasing is already a
 * teardown; acquiring is on the path trying to be fast. It also means a parked
 * view never holds a reference — a string, a drawable, a listener — to the
 * screen that put it there, which is the leak this would otherwise introduce.
 */
class XoteViewPool(private val limit: Int = 64) {
  private val free = HashMap<String, MutableList<View>>()

  var created = 0
    private set

  var reused = 0
    private set

  var dropped = 0
    private set

  fun acquire(kind: String, make: () -> View): View {
    val available = free[kind]
    if (available != null && available.isNotEmpty()) {
      reused += 1
      return available.removeAt(available.size - 1)
    }
    created += 1
    return make()
  }

  /** Hand a view back. Returns whether it was kept. */
  fun release(kind: String, view: View): Boolean {
    val available = free.getOrPut(kind) { mutableListOf() }
    if (available.size >= limit) {
      dropped += 1
      return false
    }
    reset(view)
    available.add(view)
    return true
  }

  val pooled: Int
    get() = free.values.sumOf { it.size }

  fun clear() = free.clear()

  /**
   * Everything the host may have written onto a view, put back the way Android
   * hands one over. Anything missed here leaks into the next node to be handed
   * this view, which shows up as a row wearing the colour of a row that scrolled
   * away.
   */
  private fun reset(view: View) {
    (view.parent as? ViewGroup)?.removeView(view)
    view.visibility = View.VISIBLE
    view.alpha = 1f
    view.background = null
    view.setOnClickListener(null)
    view.setOnLongClickListener(null)
    view.contentDescription = null
    // `setOnClickListener` turns clickability on as a side effect, so it has to
    // be turned off explicitly or a recycled box swallows touches meant for
    // whatever is behind it.
    view.isClickable = false
    view.isLongClickable = false
    view.isFocusable = view is EditText
    view.clipToOutline = false
    view.outlineProvider = null
    view.tag = null

    if (view is TextView) {
      view.text = null
      view.maxLines = Int.MAX_VALUE
      view.setTextColor(android.graphics.Color.BLACK)
      view.gravity = android.view.Gravity.START
      view.typeface = android.graphics.Typeface.DEFAULT
    }
    if (view is ImageView) {
      view.setImageDrawable(null)
    }
    if (view is EditText) {
      view.hint = null
      view.setText("")
      // Watchers are the ones this host added for `changeText`; dropping the
      // list is the only way to be sure none survives into the next row.
      XoteTextWatchers.clear(view)
    }
    if (view is XoteScrollView) {
      view.scrollTo(0, 0)
      view.onScrolled = null
    }
  }
}
