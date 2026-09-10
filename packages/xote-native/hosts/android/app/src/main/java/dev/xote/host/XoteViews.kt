package dev.xote.host

import android.content.Context
import android.text.Editable
import android.text.TextWatcher
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * A box.
 *
 * Every frame in the tree is computed by [XoteLayout] and written onto the view
 * directly, so this arranges nothing: `onLayout` is empty on purpose. That is
 * the Android equivalent of the iOS host's "no Auto Layout anywhere" — flexbox
 * and a platform layout system are two constraint systems with different
 * answers, and asking one to imitate the other is what the first version of the
 * iOS host did.
 *
 * `UIView` can hold subviews and `View` cannot, which is the one structural
 * difference between the two hosts: on Android a box has to be a `ViewGroup`.
 */
open class XoteBox(context: Context) : ViewGroup(context) {
  init {
    // The frames are absolute within the parent; nothing here should reflow
    // when a child changes, because the app decides when layout happens.
    isClickable = false
    clipChildren = false
  }

  override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
    // Deliberately empty. `XoteHost.applyFrames` has already measured and laid
    // out every child; re-arranging them here would undo it.
  }

  override fun onMeasure(widthSpec: Int, heightSpec: Int) {
    // The size is dictated, never negotiated.
    setMeasuredDimension(
      MeasureSpec.getSize(widthSpec),
      MeasureSpec.getSize(heightSpec),
    )
  }
}

/**
 * A box whose content may be larger than it is, and which can be dragged.
 *
 * Not `ScrollView`: that is vertical-only and takes exactly one child, while a
 * `scroll` here mirrors `UIScrollView` — one view, either axis, whichever the
 * content overflows. So this scrolls itself.
 *
 * **This is the least-tested code in either host.** It handles a drag and
 * clamps to the content; it has no fling, no over-scroll, no scrollbars and no
 * nested-scrolling participation. A shipping host would want `NestedScrollView`
 * or `RecyclerView` machinery underneath. It is enough to drive a windowed list
 * and report `scroll`, which is what the protocol needs from it.
 */
class XoteScrollView(context: Context) : XoteBox(context) {
  /** The content box's size, set by the host after every layout pass. */
  var contentWidth: Int = 0
  var contentHeight: Int = 0

  var onScrolled: ((Int, Int) -> Unit)? = null

  private var lastX = 0f
  private var lastY = 0f
  private val slop = android.view.ViewConfiguration.get(context).scaledTouchSlop

  init {
    // Content larger than the frame is the definition of this view, and the
    // parts scrolled out of sight are still drawn — over whatever is above it —
    // unless it clips. This is the bug that, on iOS, looked like two versions of
    // a label being rendered at once.
    clipChildren = true
    clipToPadding = true
    isClickable = true
  }

  private fun maxScrollX() = max(0, contentWidth - width)

  private fun maxScrollY() = max(0, contentHeight - height)

  override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
    // Let a child have the touch until the finger has actually travelled: a tap
    // on a row must reach the row, and a drag must not.
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        lastX = event.x
        lastY = event.y
      }
      MotionEvent.ACTION_MOVE -> {
        if (abs(event.x - lastX) > slop || abs(event.y - lastY) > slop) return true
      }
    }
    return false
  }

  override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        lastX = event.x
        lastY = event.y
        return true
      }
      MotionEvent.ACTION_MOVE -> {
        val dx = (lastX - event.x).toInt()
        val dy = (lastY - event.y).toInt()
        lastX = event.x
        lastY = event.y
        val x = min(max(scrollX + dx, 0), maxScrollX())
        val y = min(max(scrollY + dy, 0), maxScrollY())
        if (x != scrollX || y != scrollY) {
          scrollTo(x, y)
        }
        return true
      }
      MotionEvent.ACTION_UP,
      MotionEvent.ACTION_CANCEL -> return true
    }
    return super.onTouchEvent(event)
  }

  override fun onScrollChanged(x: Int, y: Int, oldX: Int, oldY: Int) {
    super.onScrollChanged(x, y, oldX, oldY)
    onScrolled?.invoke(x, y)
  }
}

/**
 * The `TextWatcher`s this host added to an `EditText`, so they can be taken off
 * again.
 *
 * Android has no `removeTarget(nil, …)`, so a recycled field would keep every
 * watcher every row ever gave it — the Android shape of the leak the iOS host
 * had when gesture targets were appended to an array that was never emptied.
 */
object XoteTextWatchers {
  private val attached = HashMap<EditText, MutableList<TextWatcher>>()

  fun add(field: EditText, watcher: TextWatcher) {
    attached.getOrPut(field) { mutableListOf() }.add(watcher)
    field.addTextChangedListener(watcher)
  }

  fun clear(field: EditText) {
    attached.remove(field)?.forEach { field.removeTextChangedListener(it) }
  }
}

/** A `TextWatcher` that only cares that the text changed. */
class XoteTextChanged(private val report: (String) -> Unit) : TextWatcher {
  override fun afterTextChanged(s: Editable?) = report(s?.toString() ?: "")

  override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit

  override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
}

/** Rounds a layout point onto a pixel edge. See `XoteHost.applyFrames`. */
internal fun View.placeAt(left: Int, top: Int, right: Int, bottom: Int) {
  measure(
    View.MeasureSpec.makeMeasureSpec(right - left, View.MeasureSpec.EXACTLY),
    View.MeasureSpec.makeMeasureSpec(bottom - top, View.MeasureSpec.EXACTLY),
  )
  layout(left, top, right, bottom)
}
