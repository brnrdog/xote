package dev.xote.host

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Applies the bridge protocol to Android views.
 *
 * The same shape as the iOS host, deliberately, because the protocol is the
 * contract and a host that reads differently is a host that will drift. There
 * are two trees:
 *
 * The **layout tree** has a [XoteLayoutNode] for every node the app made. The
 * **view tree** has a `View` only for the nodes that need one: a box that exists
 * to arrange its children is in the first and absent from the second
 * ([XoteFlatten]), and its children attach to the nearest ancestor that does
 * have a view. Views are taken from and returned to a pool ([XoteViewPool]).
 *
 * Frames come from the layout tree, so neither of those can move anything —
 * the property `xote-native/conformance/` pins by comparing the frames and the view
 * tree separately.
 *
 * Everything here runs on the main thread; see [XoteBridge].
 *
 * ## Points and pixels
 *
 * The app writes one set of numbers and they mean the same thing on both
 * platforms: **density-independent points**. On iOS that is free, because a
 * `UIView` frame is already in points. On Android it is not — `View.layout`
 * takes pixels — so [applyFrames] multiplies by [density] on the way out and
 * text measurement divides by it on the way back in. The layout tree, and
 * therefore everything the conformance suite compares, stays in points.
 */
class XoteHost(private val rootView: ViewGroup) {
  /** Called when a view reports something. [XoteBridge] forwards it to the app. */
  var onEvent: ((Int, String, Map<String, Any>) -> Unit)? = null

  /** Called with anything that went wrong and was skipped rather than thrown. */
  var onError: ((String) -> Unit)? = null

  /** A view only for the nodes that need one. A missing entry is a flattened box. */
  private val views = HashMap<Int, View>()
  private val nodes = HashMap<Int, XoteLayoutNode>()

  /**
   * A `scroll` lays its children out in an inner box that is free to be taller
   * than the scroll view itself. That box is where its children go.
   */
  private val contentNodes = HashMap<Int, XoteLayoutNode>()
  private val runs = HashMap<Int, String>()
  private val runViews = HashMap<Int, TextView>()
  private val labelRuns = HashMap<Int, MutableList<Int>>()
  private val lineLimits = HashMap<Int, Int>()
  private val placeholderColors = HashMap<Int, Int>()

  /**
   * Nodes that asked to hear about their own frame, and what they were last
   * told, so a layout pass that changed nothing says nothing.
   */
  private val layoutListeners = HashSet<Int>()
  private val reportedFrames = HashMap<Int, List<Float>>()

  /** Every child of every node, runs included — the shape the suite compares. */
  private val childIds = HashMap<Int, MutableList<Int>>()

  /** The other direction, which flattening needs: finding the nearest ancestor. */
  private val parentIds = HashMap<Int, Int>()
  private val idsByNode = HashMap<XoteLayoutNode, Int>()
  private val idsByView = HashMap<View, Int>()

  private val types = HashMap<Int, String>()
  private val styles = HashMap<Int, XoteStyle>()
  private val props = HashMap<Int, MutableMap<String, Any?>>()
  private val eventNames = HashMap<Int, MutableSet<String>>()

  private val pool = XoteViewPool()
  private val context: Context = rootView.context
  private val rootNode = XoteLayoutNode()

  /** Points to pixels. One on iOS by construction; anything but one here. */
  var density: Float = context.resources.displayMetrics.density

  /** Replaces real font metrics while running the conformance suite. */
  var measureOverride: ((String, Float?, XoteMeasureMode) -> XoteSize)? = null

  init {
    rootNode.view = rootView
  }

  companion object {
    /**
     * The range of bundle protocol versions this host can apply.
     *
     * Declared to the JavaScript side through [XoteBridge], which is where the
     * handshake happens. The maximum must keep step with `PROTOCOL_VERSION` in
     * `xote-native/src/host/protocol.mjs`; `xote-native/test/protocol_test.mjs` reads both
     * hosts and fails if either drifts.
     */
    const val PROTOCOL_MIN = 1
    const val PROTOCOL_MAX = 1
  }

  // ---- applying a batch ---------------------------------------------------

  fun apply(json: String) {
    val batch = XoteCommand.decodeBatch(json)
    for (problem in batch.problems) onError?.invoke(problem)

    for (command in batch.commands) {
      when (command) {
        is XoteCommand.Create -> create(command.id, command.type)

        is XoteCommand.CreateText -> {
          runs[command.id] = command.text
          types[command.id] = "#text"
        }

        is XoteCommand.SetProp -> {
          record(command.key, command.value, command.id)
          // A style or a prop can be the reason a box is on screen at all, so
          // this comes before painting: there may be nothing to paint on yet.
          reconcileView(command.id)
          views[command.id]?.let { paint(command.key, command.value, it, command.id) }
        }

        is XoteCommand.SetText -> {
          runs[command.id] = command.text
          runViews[command.id]?.let {
            it.text = command.text
            it.visibility = if (command.text.isEmpty()) View.GONE else View.VISIBLE
          }
          renderLabelsContaining(command.id)
        }

        is XoteCommand.Insert -> insert(command.child, command.parent, command.index)

        is XoteCommand.Remove -> remove(command.child, command.parent)

        is XoteCommand.Destroy -> destroy(command.id)

        is XoteCommand.Listen -> {
          eventNames.getOrPut(command.id) { mutableSetOf() }.add(command.event)
          val hadView = views[command.id] != null
          // A touch needs something to land on. A `layout` listener does not —
          // a frame comes from the layout tree, which a flattened node is in.
          reconcileView(command.id)
          val view = views[command.id]
          if (hadView && view != null) {
            listen(view, command.id, command.event)
          } else if (view == null && command.event == "layout") {
            layoutListeners.add(command.id)
          }
          // The remaining case is a box that materialised *because* of this
          // listener. `materialize` replays everything in `eventNames`, so
          // registering here as well would deliver every press twice.
        }
      }
    }

    layoutNow()
  }

  /**
   * Lay the tree out and write every frame. Called at the end of each batch, and
   * again when the root's size changes.
   */
  fun layoutNow() {
    val width = rootView.width
    val height = rootView.height
    if (width <= 0 || height <= 0) return
    XoteLayout.layout(rootNode, width / density, height / density)
    applyFrames(rootNode, 0f, 0f)
    reportLayouts()
  }

  /**
   * Tell the nodes that asked where they ended up. Only when it changed: a list
   * driven by its own `layout` event would otherwise never settle.
   */
  private fun reportLayouts() {
    if (layoutListeners.isEmpty()) return
    val frames = conformanceSnapshot().frames
    for (id in layoutListeners) {
      val frame = frames[id] ?: continue
      if (reportedFrames[id] == frame) continue
      reportedFrames[id] = frame
      onEvent?.invoke(
        id,
        "layout",
        mapOf("x" to frame[0], "y" to frame[1], "width" to frame[2], "height" to frame[3]),
      )
    }
  }

  /**
   * Walk the layout tree and place the views.
   *
   * A box with no view of its own — a scroll's content box, or a flattened one —
   * does not consume a coordinate space, so its children are placed relative to
   * it instead.
   *
   * Frames are rounded at the **edges**, not by rounding position and size
   * separately: rounding a size independently of where it starts lets two boxes
   * that share an edge in the layout end up a pixel apart on screen — a seam
   * under one row, an overlap under the next.
   */
  private fun applyFrames(node: XoteLayoutNode, originX: Float, originY: Float) {
    var childX = 0f
    var childY = 0f
    val view = node.view
    if (view != null) {
      if (view !== rootView) {
        val left = (originX + node.frame.left) * density
        val top = (originY + node.frame.top) * density
        val l = left.roundToInt()
        val t = top.roundToInt()
        view.placeAt(l, t, (left + node.frame.width * density).roundToInt(),
          (top + node.frame.height * density).roundToInt())
      }
      if (view is XoteScrollView) {
        val content = node.children.firstOrNull()
        if (content != null) {
          view.contentWidth = (content.frame.width * density).roundToInt()
          view.contentHeight = (content.frame.height * density).roundToInt()
        }
      }
    } else {
      childX = originX + node.frame.left
      childY = originY + node.frame.top
    }
    for (child in node.children) applyFrames(child, childX, childY)
  }

  // ---- creating -----------------------------------------------------------

  private fun create(id: Int, type: String) {
    types[id] = type

    if (type == "root") {
      // The root already exists; the app is told about it like any other node.
      nodes[id] = rootNode
      views[id] = rootView
      idsByNode[rootNode] = id
      idsByView[rootView] = id
      return
    }

    val node = XoteLayoutNode()
    if (type == "text") {
      node.measure = XoteMeasure { availableWidth, widthMode, _, _ ->
        measureText(id, availableWidth, widthMode)
      }
    }
    if (type == "scroll") {
      val content = XoteLayoutNode()
      contentNodes[id] = content
      node.children = mutableListOf(content)
    }
    nodes[id] = node
    idsByNode[node] = id

    // A flattening candidate gets no view until something asks for one. Every
    // other type draws, or owns behaviour, and gets its view now.
    if (type !in XoteFlatten.flattenable) materialize(id, type, node)
  }

  /** The class each primitive maps to. */
  private fun makeView(type: String): View =
    when (type) {
      "text", "#text" -> TextView(context)
      "image" -> ImageView(context)
      "input" -> EditText(context)
      "scroll" -> XoteScrollView(context)
      // `view`, `pressable`, and any primitive this host does not know by name.
      // A box has to be a `ViewGroup` on Android — `View` cannot hold children.
      else -> XoteBox(context)
    }

  /**
   * Re-applied on every acquire, because a pooled view has been reset and a
   * fresh one has not been configured. Everything here is a property of the
   * primitive, not of the app's style.
   */
  private fun configure(view: View, type: String) {
    when (type) {
      "text", "#text" -> {
        (view as? TextView)?.let {
          it.maxLines = Int.MAX_VALUE
          it.includeFontPadding = false
          it.setPadding(0, 0, 0, 0)
        }
      }
      "image" -> (view as? ImageView)?.scaleType = ImageView.ScaleType.CENTER_CROP
      "input" -> (view as? EditText)?.let {
        it.background = null
        it.setPadding(0, 0, 0, 0)
      }
      else -> Unit
    }
  }

  private fun acquireView(id: Int, type: String): View {
    val view = pool.acquire(type) { makeView(type) }
    configure(view, type)
    idsByView[view] = id
    return view
  }

  // ---- the view tree ------------------------------------------------------

  /** The nearest ancestor holding a view, or null when this subtree is detached. */
  private fun nativeHost(id: Int): Int? {
    var current = parentIds[id]
    while (current != null) {
      if (views[current] != null) return current
      current = parentIds[current]
    }
    return null
  }

  /**
   * The views at the top of `id`'s subtree — its own if it has one, otherwise
   * the frontier just below the flattened boxes covering it.
   */
  private fun renderedRoots(id: Int, out: MutableList<View>) {
    val view = views[id]
    if (view != null) {
      out.add(view)
      return
    }
    for (child in childIds[id] ?: mutableListOf()) renderedRoots(child, out)
  }

  private fun renderedRoots(id: Int): List<View> {
    val out = mutableListOf<View>()
    renderedRoots(id, out)
    return out
  }

  /** How many views precede `id` inside `host` — its index among children. */
  private fun nativeIndex(id: Int, host: Int): Int {
    var count = 0
    fun walk(parent: Int): Boolean {
      for (child in childIds[parent] ?: mutableListOf()) {
        if (child == id) return true
        if (views[child] != null) count += 1 else if (walk(child)) return true
      }
      return false
    }
    walk(host)
    return count
  }

  private fun attachViews(id: Int) {
    val host = nativeHost(id) ?: return
    val hostView = views[host] as? ViewGroup ?: return
    var index = nativeIndex(id, host)
    for (view in renderedRoots(id)) {
      hostView.addView(view, minOf(index, hostView.childCount))
      index += 1
    }
  }

  private fun detachViews(id: Int) {
    for (view in renderedRoots(id)) (view.parent as? ViewGroup)?.removeView(view)
  }

  private fun materialize(id: Int, type: String, node: XoteLayoutNode) {
    val host = nativeHost(id)
    val index = if (host == null) 0 else nativeIndex(id, host)
    // Whatever was standing in for this node in its host moves inside the new
    // view, in the order it was standing in.
    val standingIn = renderedRoots(id)

    val view = acquireView(id, type)
    for (sub in standingIn) (sub.parent as? ViewGroup)?.removeView(sub)
    (view as? ViewGroup)?.let { group ->
      standingIn.forEachIndexed { at, sub -> group.addView(sub, at) }
    }

    views[id] = view
    node.view = view

    // Everything the app already said about this node, now that there is
    // somewhere to put it.
    styles[id]?.let { paint(it, view, id) }
    props[id]?.forEach { (key, value) -> paint(key, value, view, id) }
    eventNames[id]?.forEach { listen(view, id, it) }

    if (host != null) {
      (views[host] as? ViewGroup)?.let { it.addView(view, minOf(index, it.childCount)) }
    }
  }

  private fun dematerialize(id: Int, type: String, node: XoteLayoutNode) {
    val view = views[id] ?: return
    val host = nativeHost(id)
    val index = if (host == null) 0 else nativeIndex(id, host)

    // Its children take its place in the host, in its position.
    val inner = mutableListOf<View>()
    (view as? ViewGroup)?.let { group ->
      for (at in 0 until group.childCount) inner.add(group.getChildAt(at))
      group.removeAllViews()
    }
    (view.parent as? ViewGroup)?.removeView(view)

    views.remove(id)
    node.view = null
    idsByView.remove(view)
    pool.release(type, view)

    if (host != null) {
      (views[host] as? ViewGroup)?.let { group ->
        inner.forEachIndexed { at, sub -> group.addView(sub, minOf(index + at, group.childCount)) }
      }
    }
  }

  /**
   * Bring a node's view presence back in line with what it now needs.
   *
   * Both directions are rare — a box does not usually start painting halfway
   * through its life — and both have to be right, because getting one wrong
   * reorders a screen rather than merely slowing it down.
   */
  private fun reconcileView(id: Int) {
    val type = types[id] ?: return
    if (type !in XoteFlatten.flattenable) return
    val node = nodes[id] ?: return

    val want =
      XoteFlatten.needsView(
        type,
        styles[id] ?: XoteStyle(null),
        (props[id] ?: emptyMap()).keys,
        eventNames[id] ?: emptySet(),
      )
    val has = views[id] != null
    if (want == has) return

    if (want) materialize(id, type, node) else dematerialize(id, type, node)
  }

  // ---- tree ---------------------------------------------------------------

  /** Where a node's children go in the *layout* tree. */
  private fun layoutContainer(id: Int): XoteLayoutNode? = contentNodes[id] ?: nodes[id]

  private fun insert(child: Int, parent: Int, index: Int) {
    val text = runs[child]
    if (text != null) {
      if (views[parent] is TextView && views[parent] !is EditText) {
        // Inside a `text`, a run is a piece of the label's string.
        if (views[child] != null) releaseRunView(child)
        val ordered = labelRuns.getOrPut(parent) { mutableListOf() }
        ordered.add(minOf(index, ordered.size), child)
        parentIds[child]?.let { if (it != parent) childIds[it]?.remove(child) }
        parentIds[child] = parent
        record(child, parent, index)
        renderLabel(parent)
        return
      }

      // Anywhere else it is a node in its own right, and it has to occupy its
      // index whether or not it draws anything — the placeholder a reactive
      // region renders for an absent branch is an empty text node, and dropping
      // it would put every later sibling one slot out of step.
      if (nodes[child] == null) {
        parentIds[child]?.let { previous ->
          labelRuns[previous]?.remove(child)
          renderLabel(previous)
        }
        val label = acquireView(child, "#text") as TextView
        label.text = text
        label.visibility = if (text.isEmpty()) View.GONE else View.VISIBLE
        runViews[child] = label

        val node = XoteLayoutNode()
        node.view = label
        node.measure = XoteMeasure { availableWidth, widthMode, _, _ ->
          measureText(child, availableWidth, widthMode)
        }
        nodes[child] = node
        views[child] = label
        idsByNode[node] = child
      }
    }

    if (nodes[child] == null) return
    attach(child, parent, index)
  }

  /** Give a bare run's label back — it has become a piece of someone's string. */
  private fun releaseRunView(child: Int) {
    val view = views[child] ?: return
    (view.parent as? ViewGroup)?.removeView(view)
    idsByView.remove(view)
    nodes[child]?.let { node ->
      idsByNode.remove(node)
      parentIds[child]?.let { parent ->
        layoutContainer(parent)?.children?.remove(node)
      }
    }
    views.remove(child)
    nodes.remove(child)
    runViews.remove(child)
    pool.release("#text", view)
  }

  private fun attach(childId: Int, parent: Int, index: Int) {
    val parentNode = layoutContainer(parent) ?: return
    val childNode = nodes[childId] ?: return

    // Detach first, and while the old host is still reachable: an insert of an
    // already-parented node is a move, and the reconciler does exactly that when
    // a keyed row changes position.
    if (parentIds[childId] != null) detachViews(childId)
    parentIds[childId]?.let { childIds[it]?.remove(childId) }

    parentNode.children.remove(childNode)
    parentNode.children.add(minOf(index, parentNode.children.size), childNode)

    parentIds[childId] = parent
    record(childId, parent, index)
    attachViews(childId)
  }

  private fun record(child: Int, parent: Int, index: Int) {
    val ordered = childIds.getOrPut(parent) { mutableListOf() }
    ordered.remove(child)
    ordered.add(minOf(index, ordered.size), child)
  }

  private fun remove(child: Int, parent: Int) {
    detachViews(child)
    childIds[parent]?.remove(child)
    parentIds.remove(child)

    if (runs[child] != null && runViews[child] == null) {
      labelRuns[parent]?.remove(child)
      renderLabel(parent)
      return
    }
    val parentNode = layoutContainer(parent) ?: return
    nodes[child]?.let { parentNode.children.remove(it) }
  }

  private fun destroy(id: Int) {
    // A well-behaved bundle removes before it destroys. Detaching here anyway
    // means one that does not cannot leave a view in the tree pointing at an id
    // nothing owns.
    detachViews(id)

    val view = views[id]
    val type = types[id]
    if (view != null && type != null) {
      idsByView.remove(view)
      // The protocol guarantees the id is never referenced again, which is
      // exactly the guarantee a pool needs to take the view back.
      if (view !== rootView) pool.release(type, view)
    }

    nodes[id]?.let { idsByNode.remove(it) }
    parentIds[id]?.let { childIds[it]?.remove(id) }

    views.remove(id)
    nodes.remove(id)
    contentNodes.remove(id)
    runs.remove(id)
    runViews.remove(id)
    labelRuns.remove(id)
    lineLimits.remove(id)
    placeholderColors.remove(id)
    childIds.remove(id)
    parentIds.remove(id)
    types.remove(id)
    styles.remove(id)
    props.remove(id)
    eventNames.remove(id)
    layoutListeners.remove(id)
    reportedFrames.remove(id)
  }

  private fun renderLabel(id: Int) {
    val label = views[id] as? TextView ?: return
    label.text = (labelRuns[id] ?: mutableListOf()).mapNotNull { runs[it] }.joinToString("")
  }

  private fun renderLabelsContaining(run: Int) {
    for ((id, ordered) in labelRuns) if (run in ordered) renderLabel(id)
  }

  // ---- text measurement ---------------------------------------------------

  /**
   * The one thing the host knows and the layout engine cannot: how big a piece
   * of text is at a given width.
   *
   * In and out in **points**; `StaticLayout` works in pixels, so the width goes
   * in multiplied by [density] and the answer comes back divided by it.
   */
  private fun measureText(id: Int, availableWidth: Float?, widthMode: XoteMeasureMode): XoteSize {
    val view = views[id] as? TextView
    val text = view?.text?.toString() ?: ""
    measureOverride?.let { return it(text, availableWidth, widthMode) }
    if (text.isEmpty()) return XoteSize(0f, 0f)

    val paint: TextPaint = view?.paint ?: TextPaint()
    val natural = Layout.getDesiredWidth(text, paint)
    val constraintPx =
      if (widthMode == XoteMeasureMode.UNDEFINED || availableWidth == null) natural
      else availableWidth * density

    val width = max(1, ceil(minOf(constraintPx, max(natural, 1f))).toInt())
    val layout =
      StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
        .setAlignment(Layout.Alignment.ALIGN_NORMAL)
        .setIncludePad(false)
        .build()

    var heightPx = layout.height.toFloat()
    val limit = lineLimits[id] ?: 0
    if (limit > 0 && layout.lineCount > limit) {
      heightPx = layout.getLineBottom(limit - 1).toFloat()
    }

    return XoteSize(
      width =
        if (widthMode == XoteMeasureMode.EXACTLY) (availableWidth ?: 0f)
        else ceil(minOf(natural, constraintPx)) / density,
      height = ceil(heightPx) / density,
    )
  }

  // ---- props --------------------------------------------------------------

  /**
   * Remember what the app said, and give the layout tree the half it needs.
   *
   * Separate from painting because a flattened box has nothing to paint on and
   * still has to lay out — and because a box that later materialises has to be
   * able to paint what it was told while it had no view.
   */
  private fun record(key: String, value: Any?, id: Int) {
    if (key == "style") {
      @Suppress("UNCHECKED_CAST")
      val style = XoteStyle(value as? Map<String, Any?>)
      styles[id] = style
      val content = contentNodes[id]
      if (content != null) {
        // A scroll view is two boxes: the frame its parent positions, and the
        // content its children are arranged in, which is free to be longer. The
        // style is split between them accordingly.
        val split = splitScrollStyle(style.values)
        nodes[id]?.style = XoteStyle(split.first)
        content.style = XoteStyle(split.second)
      } else {
        nodes[id]?.style = style
      }
      return
    }
    if (key == "numberOfLines") lineLimits[id] = (value as? Number)?.toInt() ?: 0
    if (value != null) props.getOrPut(id) { mutableMapOf() }[key] = value
    else props[id]?.remove(key)
  }

  private fun paint(key: String, value: Any?, view: View, id: Int) {
    when (key) {
      "style" -> paint(styles[id] ?: XoteStyle(null), view, id)
      "value" -> (view as? EditText)?.setText(value as? String ?: "")
      "placeholder" -> {
        (view as? EditText)?.hint = value as? String
        refreshPlaceholder(view as? EditText, id)
      }
      "placeholderTextColor" -> {
        (value as? String)?.let { XoteStyle.colorFromHex(it) }?.let { placeholderColors[id] = it }
        refreshPlaceholder(view as? EditText, id)
      }
      "secureTextEntry" ->
        (view as? EditText)?.inputType =
          if (value == true) {
            android.text.InputType.TYPE_CLASS_TEXT or
              android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD
          } else {
            android.text.InputType.TYPE_CLASS_TEXT
          }
      "editable" -> (view as? EditText)?.isEnabled = value as? Boolean ?: true
      "numberOfLines" -> {
        val limit = (value as? Number)?.toInt() ?: 0
        (view as? TextView)?.maxLines = if (limit > 0) limit else Int.MAX_VALUE
      }
      "horizontal" -> Unit // The content box's `flexDirection` decides this.
      "source" -> loadImage(value, view as? ImageView)
      "testID" -> view.tag = value as? String
      "accessibilityLabel" -> view.contentDescription = value as? String
      else -> Unit
    }
  }

  /**
   * `hint` and its colour are two calls that have to agree, and either can
   * arrive first.
   */
  private fun refreshPlaceholder(field: EditText?, id: Int) {
    val color = placeholderColors[id] ?: return
    field?.setHintTextColor(color)
  }

  private fun paint(style: XoteStyle, view: View, id: Int) {
    // Layout reads the style off the node, which `record` has already done.
    // This only has to paint.
    view.alpha = style.number("opacity") ?: 1f

    val background = style.color("backgroundColor")
    val radius = (style.number("borderRadius") ?: 0f) * density
    val borderWidth = (style.number("borderWidth") ?: 0f) * density
    val borderColor = style.color("borderColor")

    if (background != null || radius > 0f || borderWidth > 0f) {
      val drawable = GradientDrawable()
      drawable.shape = GradientDrawable.RECTANGLE
      drawable.cornerRadius = radius
      if (background != null) drawable.setColor(background)
      if (borderWidth > 0f && borderColor != null) {
        drawable.setStroke(borderWidth.roundToInt(), borderColor)
      }
      view.background = drawable
    } else {
      view.background = null
    }

    // `overflow: visible` is the flexbox default and the right default for a
    // box — but a scroll view is not a box. It clips as a condition of working:
    // its content is larger than its frame by definition, and the parts that
    // have scrolled out are still drawn, over whatever is above it. Turning that
    // off is how a list ends up painted across the header.
    if (view is XoteScrollView) {
      view.clipChildren = true
    } else {
      val clip = radius > 0f || style.string("overflow") == "hidden"
      view.clipToOutline = clip
      view.outlineProvider = if (clip) ViewOutlineProvider.BACKGROUND else null
      (view as? ViewGroup)?.clipChildren = clip
    }

    if (view is TextView) {
      style.number("fontSize")?.let {
        view.setTextSize(android.util.TypedValue.COMPLEX_UNIT_DIP, it)
      }
      view.typeface = style.typeface
      view.gravity = style.gravity
      style.color("color")?.let { view.setTextColor(it) }
    }
  }

  /**
   * Everything about how children are arranged belongs to the content box;
   * everything about how big the scroll view is belongs to the frame.
   */
  private fun splitScrollStyle(
    values: Map<String, Any?>
  ): Pair<Map<String, Any?>, Map<String, Any?>> {
    val arrangement =
      listOf(
        "flexDirection", "justifyContent", "alignItems", "gap", "rowGap", "columnGap",
        "padding", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
        "paddingHorizontal", "paddingVertical",
      )
    val frame = values.toMutableMap()
    val content = mutableMapOf<String, Any?>()
    for (key in arrangement) {
      if (values[key] == null) continue
      content[key] = values[key]
      frame.remove(key)
    }
    return Pair(frame, content)
  }

  private fun loadImage(source: Any?, imageView: ImageView?) {
    if (imageView == null) return
    @Suppress("UNCHECKED_CAST")
    val uri = (source as? String) ?: ((source as? Map<String, Any?>)?.get("uri") as? String)
    if (uri == null) return
    // No cache, no decode budget, no placeholder — see `ROADMAP.md`. A shipping
    // host would hand this to an image library rather than a thread.
    Thread {
        try {
          val stream = java.net.URL(uri).openStream()
          val bitmap = android.graphics.BitmapFactory.decodeStream(stream)
          stream.close()
          if (bitmap != null) imageView.post { imageView.setImageBitmap(bitmap) }
        } catch (error: Exception) {
          onError?.invoke("image $uri — ${error.message}")
        }
      }
      .start()
  }

  // ---- events -------------------------------------------------------------

  private fun listen(view: View, id: Int, event: String) {
    when (event) {
      "press" -> {
        view.isClickable = true
        view.setOnClickListener { onEvent?.invoke(id, "press", emptyMap()) }
      }

      "longPress" -> {
        view.isLongClickable = true
        view.setOnLongClickListener {
          onEvent?.invoke(id, "longPress", emptyMap())
          true
        }
      }

      "scroll" -> {
        val scroll = view as? XoteScrollView ?: return
        scroll.onScrolled = { x, y ->
          onEvent?.invoke(id, "scroll", mapOf("x" to x / density, "y" to y / density))
        }
      }

      "layout" -> layoutListeners.add(id)

      // The four `EditText` events are the same shape with a different trigger.
      "changeText" -> {
        val field = view as? EditText ?: return
        XoteTextWatchers.add(
          field,
          XoteTextChanged { value -> onEvent?.invoke(id, "changeText", mapOf("value" to value)) },
        )
      }

      "submit" -> {
        val field = view as? EditText ?: return
        field.setOnEditorActionListener { _, _, _ ->
          onEvent?.invoke(id, "submit", mapOf("value" to field.text.toString()))
          false
        }
      }

      "focus" -> {
        val field = view as? EditText ?: return
        field.setOnFocusChangeListener { _, hasFocus ->
          val name = if (hasFocus) "focus" else "blur"
          if (name == "focus" || "blur" in (eventNames[id] ?: emptySet())) {
            onEvent?.invoke(id, name, mapOf("value" to field.text.toString()))
          }
        }
      }

      "blur" -> {
        val field = view as? EditText ?: return
        // Android has one focus-change callback for both directions, so
        // registering either event registers the same listener and the callback
        // decides which name to send. Registering twice is harmless — the
        // second `setOnFocusChangeListener` replaces the first.
        field.setOnFocusChangeListener { _, hasFocus ->
          val name = if (hasFocus) "focus" else "blur"
          if (name == "blur" || "focus" in (eventNames[id] ?: emptySet())) {
            onEvent?.invoke(id, name, mapOf("value" to field.text.toString()))
          }
        }
      }

      else -> {
        // An event this host does not raise yet. The app is never told, which is
        // indistinguishable from it not happening.
      }
    }
  }

  // ---- inspection ---------------------------------------------------------

  data class Snapshot(
    val structure: Map<Int, List<Int>>,
    val frames: Map<Int, List<Float>>,
    val texts: Map<Int, String>,
    val views: Map<Int, List<Int>>,
  )

  /**
   * What the conformance suite compares: the node tree, every frame in root
   * coordinates, the text as it would be shown, and — separately — the *view*
   * tree, which is the only place a flattening disagreement shows up.
   *
   * Frames are in **points**, straight off the layout tree, which is what makes
   * them comparable against a host with a different display density and against
   * the JavaScript reference. This is not the same walk as [applyFrames], which
   * writes pixels relative to a parent.
   */
  fun conformanceSnapshot(): Snapshot {
    val frames = HashMap<Int, List<Float>>()
    fun walk(node: XoteLayoutNode, originX: Float, originY: Float) {
      val left = originX + node.frame.left
      val top = originY + node.frame.top
      idsByNode[node]?.let { frames[it] = listOf(left, top, node.frame.width, node.frame.height) }
      // A scroll's content box has no id of its own and still contributes its
      // offset, which is why this is outside the `let`.
      for (child in node.children) walk(child, left, top)
    }
    walk(rootNode, 0f, 0f)

    val texts = HashMap<Int, String>()
    for ((id, view) in views) {
      if (view is TextView && view !is EditText && (runViews[id] == null || labelRuns[id] != null)) {
        texts[id] = view.text?.toString() ?: ""
      }
    }
    for ((id, label) in runViews) texts[id] = label.text?.toString() ?: ""

    val viewTree = HashMap<Int, List<Int>>()
    fun walkViews(view: View) {
      val id = idsByView[view] ?: return
      val group = view as? ViewGroup
      viewTree[id] =
        if (group == null) emptyList()
        else (0 until group.childCount).mapNotNull { idsByView[group.getChildAt(it)] }
      if (group != null) for (at in 0 until group.childCount) walkViews(group.getChildAt(at))
    }
    walkViews(rootView)

    return Snapshot(
      childIds.mapValues { it.value.toList() },
      frames,
      texts,
      viewTree,
    )
  }

  /** Allocation behaviour, for tests and for anyone measuring a real screen. */
  fun poolStats(): Map<String, Int> =
    mapOf(
      "created" to pool.created,
      "reused" to pool.reused,
      "dropped" to pool.dropped,
      "pooled" to pool.pooled,
    )
}
