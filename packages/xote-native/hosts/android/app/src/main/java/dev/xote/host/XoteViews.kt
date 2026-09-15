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
 * A `stack`: a box that shows one of its screens at a time.
 *
 * Android has no `UINavigationController`. The iOS host uses the real one and
 * gets the slide transition, the interactive edge swipe and the focus order
 * VoiceOver expects for free; there is no equivalent object here, because
 * Android's answer is `FragmentManager` and a fragment is not a view.
 *
 * **So this cut has no transition on Android.** A push and a pop are instant.
 * Faking a slide in a custom `ViewGroup` is the kind of thing that looks right
 * in a demo and wrong in an app — the timing curve is not the platform's, it
 * does not interrupt or reverse, and it has no interactive gesture behind it.
 * The honest options are a real `FragmentManager` host or `AndroidX Transition`,
 * and both are more than this file. `ROADMAP.md` records it.
 *
 * What *is* here is everything the protocol depends on: the right screens, in
 * the right order, with only the top one visible and taking touches, and the
 * system back reported as `stackChange` under the same rules the iOS host
 * follows — see `src/host/navigation.mjs`.
 */
class XoteStackView(context: Context) : XoteBox(context) {
  /** Called when the system back popped: the screen that left, and the depth. */
  var onPlatformPop: ((Int, Int) -> Unit)? = null

  /**
   * Whether the app registered `stackChange`. Without it the system back is
   * not this stack's to handle, and the activity finishes as it otherwise
   * would — an app that has not opted in is one where nothing but the app moves
   * the tree.
   */
  var platformPopEnabled = false

  private var screens: List<Pair<Int, View>> = emptyList()

  val screenIDs: List<Int>
    get() = screens.map { it.first }

  /** Bring the container to exactly `wanted`, bottom to top. */
  fun setScreens(wanted: List<Pair<Int, View>>) {
    for ((_, view) in screens) {
      if (wanted.none { it.second === view }) removeView(view)
    }
    for ((at, entry) in wanted.withIndex()) {
      val view = entry.second
      val current = indexOfChild(view)
      if (current == at) continue
      if (current >= 0) removeViewAt(current)
      addView(view, minOf(at, childCount))
    }
    screens = wanted
    // Only the top screen is visible, and only the top screen takes touches.
    // Drawing order alone would not do it: the screens under the top one are
    // the same size, and a box that is not clickable lets a touch through to
    // whatever is behind it.
    for ((at, entry) in wanted.withIndex()) {
      entry.second.visibility = if (at == wanted.size - 1) VISIBLE else GONE
    }
  }

  /**
   * The system back button. Returns whether this stack took it.
   *
   * The screen goes out of view immediately, exactly as UIKit pops before
   * anything else could have an opinion, and the app is told after the fact.
   * Its node and its id are untouched: they are the app's.
   */
  fun popFromPlatform(): Boolean {
    if (!platformPopEnabled || screens.size <= 1) return false
    val (poppedId, _) = screens.last()
    setScreens(screens.dropLast(1))
    onPlatformPop?.invoke(poppedId, screens.size)
    return true
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
  // Weak keys: this map is process-wide and `clear` is only reached from
  // `XoteViewPool.reset`, which `release` skips once a pool is full. A strong
  // key would then retain the `EditText` — and through it the whole Activity —
  // for the life of the process, which is the Android shape of the leak the
  // iOS host had when gesture targets were appended to an array nothing
  // emptied.
  private val attached = java.util.WeakHashMap<EditText, MutableList<TextWatcher>>()

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
