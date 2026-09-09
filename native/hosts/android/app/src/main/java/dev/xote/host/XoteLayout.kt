package dev.xote.host

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Flexbox layout.
 *
 * A line-for-line transliteration of `native/host/layout.mjs`, which is checked
 * frame-for-frame against Chromium's own flexbox by
 * `native/test/layout_test.mjs`. **Keep the three in step**: this is now the
 * same algorithm written three times — once in JavaScript, once in Swift, once
 * here — and a change to one that is not a change to the others is a change
 * nothing tests. `native/conformance/` is what makes that survivable, and
 * consolidating on Yoga is what would make it unnecessary.
 *
 * Covered: direction including reverse, `justifyContent`, `alignItems` and
 * `alignSelf`, grow/shrink/basis, min and max, points and percentages, margin,
 * padding, border width, gaps, `aspectRatio`, absolute positioning, and
 * measured leaves for text. Not covered, deliberately: `flexWrap`, baseline
 * alignment, `alignContent`, and percentage margins and paddings. None of those
 * is expressible in `NativeStyle` either — reaching for one is a compile error
 * rather than a silence, and it is the signal to swap this out for Yoga.
 */
enum class XoteMeasureMode {
  /** As much as it wants. */
  UNDEFINED,

  /** This much, no argument. */
  EXACTLY,

  /** No more than this. */
  AT_MOST,
}

data class XoteSize(val width: Float, val height: Float)

data class XoteEdges(
  val left: Float = 0f,
  val right: Float = 0f,
  val top: Float = 0f,
  val bottom: Float = 0f,
)

class XoteFrame {
  var left: Float = 0f
  var top: Float = 0f
  var width: Float = 0f
  var height: Float = 0f
}

/** Given the space available, how big does this text want to be? */
fun interface XoteMeasure {
  fun measure(
    availableWidth: Float?,
    widthMode: XoteMeasureMode,
    availableHeight: Float?,
    heightMode: XoteMeasureMode,
  ): XoteSize
}

/** The layout tree, which does *not* shadow the view tree one-for-one. */
class XoteLayoutNode {
  var style: XoteStyle = XoteStyle(null)
  var children: MutableList<XoteLayoutNode> = mutableListOf()
  var frame: XoteFrame = XoteFrame()

  /**
   * The `View` this box positions, when there is one — and there is not always
   * one. A scroll view's inner content box has none, and neither does a box that
   * was flattened away ([XoteFlatten]): both arrange their children without
   * occupying a coordinate space, so the children are placed relative to them by
   * the caller instead.
   */
  var view: android.view.View? = null

  /** Set on a text node. */
  var measure: XoteMeasure? = null

  // Scratch space for one layout pass.
  internal var base: Float = 0f
  internal var main: Float = 0f
  internal var minMain: Float? = null
  internal var maxMain: Float? = null
  internal var margin: XoteEdges = XoteEdges()
  internal var marginMain: Float = 0f
  internal var violation: Float = 0f
  internal var measuredSubtree: Boolean? = null
}

object XoteLayout {
  /**
   * Lay [root] out in a box of [width] × [height], writing a frame onto every
   * node. Positions are relative to the parent's border box.
   */
  fun layout(root: XoteLayoutNode, width: Float?, height: Float?) {
    compute(
      root,
      availableWidth = width,
      widthMode = if (width == null) XoteMeasureMode.UNDEFINED else XoteMeasureMode.EXACTLY,
      availableHeight = height,
      heightMode = if (height == null) XoteMeasureMode.UNDEFINED else XoteMeasureMode.EXACTLY,
      ownerWidth = width,
      ownerHeight = height,
    )
    root.frame.left = 0f
    root.frame.top = 0f
  }

  // ---- helpers ------------------------------------------------------------

  private fun clamp(value: Float, lower: Float?, upper: Float?): Float {
    var out = value
    if (upper != null && out > upper) out = upper
    if (lower != null && out < lower) out = lower
    return out
  }

  /**
   * Is there text anywhere in this subtree?
   *
   * It decides whether an automatic size is capped by the space available.
   * `fit-content` is `clamp(min-content, available, max-content)`, and for a
   * subtree of plain boxes those last two are the same number — nothing gets
   * narrower by being given less room — so capping would shrink a box below
   * content that is going to overflow anyway. Text is the exception.
   */
  private fun hasMeasuredLeaf(node: XoteLayoutNode): Boolean {
    node.measuredSubtree?.let { return it }
    var found = node.measure != null
    for (child in node.children) {
      if (found) break
      found = hasMeasuredLeaf(child)
    }
    node.measuredSubtree = found
    return found
  }

  /**
   * CSS's "resolve flexible lengths", which is a loop rather than a division:
   * distributing in one pass and clamping afterwards loses whatever the clamp
   * took away, so each round freezes the items that hit a bound and runs again.
   */
  private fun resolveFlexibleLengths(
    flow: List<XoteLayoutNode>,
    mainAvail: Float,
    totalGap: Float,
    usedHypothetical: Float,
  ) {
    val growing = mainAvail - usedHypothetical > 0
    // A plain `HashSet` of nodes is an identity set here: `XoteLayoutNode`
    // overrides neither `equals` nor `hashCode`, which is what makes two boxes
    // with the same style two different items.
    val frozen = HashSet<XoteLayoutNode>()

    for (child in flow) {
      val factor = if (growing) child.style.flexGrow else child.style.flexShrink
      if (factor == 0f) {
        child.main = clamp(child.base, child.minMain, child.maxMain)
        frozen.add(child)
      }
    }

    for (round in 0..flow.size) {
      val unfrozen = flow.filter { it !in frozen }
      if (unfrozen.isEmpty()) return

      var free = mainAvail - totalGap
      for (child in flow) {
        free -= child.marginMain
        free -= if (child in frozen) child.main else child.base
      }

      // Shrinking is weighted by the base size, so a large item gives up more
      // than a small one with the same factor.
      var totalFactor = 0f
      for (child in unfrozen) {
        totalFactor += if (growing) child.style.flexGrow else child.style.flexShrink * child.base
      }

      var violation = 0f
      for (child in unfrozen) {
        val weight =
          if (growing) child.style.flexGrow else child.style.flexShrink * child.base
        val share = if (totalFactor > 0f) (free * weight) / totalFactor else 0f
        val unclamped = child.base + share
        val clamped = clamp(unclamped, child.minMain, child.maxMain)
        child.main = clamped
        child.violation = clamped - unclamped
        violation += child.violation
      }

      if (abs(violation) < 0.0001f) return
      for (child in unfrozen) {
        val hit = if (violation > 0f) child.violation > 0f else child.violation < 0f
        if (hit) frozen.add(child)
      }
    }
  }

  // ---- the pass -----------------------------------------------------------

  private fun compute(
    node: XoteLayoutNode,
    availableWidth: Float?,
    widthMode: XoteMeasureMode,
    availableHeight: Float?,
    heightMode: XoteMeasureMode,
    ownerWidth: Float?,
    ownerHeight: Float?,
  ) {
    val style = node.style

    val minWidth = style.dimension("minWidth").resolve(ownerWidth)
    val maxWidth = style.dimension("maxWidth").resolve(ownerWidth)
    val minHeight = style.dimension("minHeight").resolve(ownerHeight)
    val maxHeight = style.dimension("maxHeight").resolve(ownerHeight)

    var width =
      if (widthMode == XoteMeasureMode.EXACTLY) availableWidth
      else style.dimension("width").resolve(ownerWidth)
    var height =
      if (heightMode == XoteMeasureMode.EXACTLY) availableHeight
      else style.dimension("height").resolve(ownerHeight)

    val ratio = style.number("aspectRatio")
    if (ratio != null && ratio > 0f) {
      val w = width
      val h = height
      if (w != null && h == null) height = w / ratio else if (h != null && w == null) {
        width = h * ratio
      }
    }

    width?.let { width = clamp(it, minWidth, maxWidth) }
    height?.let { height = clamp(it, minHeight, maxHeight) }

    val pad = style.inset
    val padH = pad.left + pad.right
    val padV = pad.top + pad.bottom

    val children = node.children.filter { it.style.string("display") != "none" }
    val flow = children.filter { it.style.string("position") != "absolute" }

    // ---- a measured leaf --------------------------------------------------

    val measure = node.measure
    if (measure != null && flow.isEmpty()) {
      var innerAvailW = width?.let { it - padH }
      if (innerAvailW == null && availableWidth != null) {
        innerAvailW = clamp(availableWidth, minWidth, maxWidth) - padH
      }
      var innerAvailH = height?.let { it - padV }
      if (innerAvailH == null && availableHeight != null) {
        innerAvailH = clamp(availableHeight, minHeight, maxHeight) - padV
      }

      if (width == null || height == null) {
        val measured =
          measure.measure(
            innerAvailW,
            if (width != null) XoteMeasureMode.EXACTLY
            else if (widthMode == XoteMeasureMode.EXACTLY) XoteMeasureMode.AT_MOST else widthMode,
            innerAvailH,
            if (height != null) XoteMeasureMode.EXACTLY
            else if (heightMode == XoteMeasureMode.EXACTLY) XoteMeasureMode.AT_MOST else heightMode,
          )
        if (width == null) width = clamp(measured.width + padH, minWidth, maxWidth)
        if (height == null) height = clamp(measured.height + padV, minHeight, maxHeight)
      }

      node.frame.width = max(width ?: 0f, padH)
      node.frame.height = max(height ?: 0f, padV)
      return
    }

    // ---- a container ------------------------------------------------------

    val direction = style.string("flexDirection") ?: "column"
    val row = direction == "row" || direction == "row-reverse"
    val reverse = direction == "row-reverse" || direction == "column-reverse"
    val gap = style.gap(row)
    val totalGap = if (flow.size > 1) gap * (flow.size - 1) else 0f

    var availInnerW: Float? = null
    val w0 = width
    if (w0 != null) {
      availInnerW = w0 - padH
    } else if (availableWidth != null) {
      availInnerW = clamp(availableWidth, minWidth, maxWidth) - padH
    }
    var availInnerH: Float? = null
    val h0 = height
    if (h0 != null) {
      availInnerH = h0 - padV
    } else if (availableHeight != null) {
      availInnerH = clamp(availableHeight, minHeight, maxHeight) - padV
    }

    // "Definite" and "available" are not the same thing: a node under `atMost`
    // has space but no size of its own, and `stretch` has nothing to stretch to
    // until the line's own cross size is known.
    val definiteCross = if (row) height != null else width != null
    val crossAvail: Float? = if (definiteCross) (if (row) availInnerH else availInnerW) else null

    /**
     * Each child's flex base size and hypothetical main size.
     *
     * `honourBasis` separates the two questions this answers. Laying out, a
     * `flex: 1` child starts from a basis of zero and grows into the container.
     * *Measuring* an auto-sized container, that basis is meaningless — there is
     * no size yet, and a row of flexible children would measure as nothing — so
     * the child's max-content size stands in.
     */
    fun measureChildren(honourBasis: Boolean, mainAvail: Float?): Float {
      var used = totalGap
      for (child in flow) {
        val cs = child.style
        val basis = if (honourBasis) cs.flexBasis.resolve(mainAvail) else null
        val styleMain =
          cs.dimension(if (row) "width" else "height")
            .resolve(if (row) availInnerW else availInnerH)

        val hypothetical: Float
        if (basis != null) {
          hypothetical = basis
        } else if (styleMain != null) {
          hypothetical = styleMain
        } else {
          // The flex base size is the child's max-content size: unconstrained on
          // the main axis, and only shrunk later by the flex loop.
          val childCrossAvail = if (row) availInnerH else availInnerW
          val crossMode =
            if (childCrossAvail == null) XoteMeasureMode.UNDEFINED else XoteMeasureMode.AT_MOST
          compute(
            child,
            availableWidth = if (row) null else childCrossAvail,
            widthMode = if (row) XoteMeasureMode.UNDEFINED else crossMode,
            availableHeight = if (row) childCrossAvail else null,
            heightMode = if (row) crossMode else XoteMeasureMode.UNDEFINED,
            ownerWidth = availInnerW,
            ownerHeight = availInnerH,
          )
          hypothetical = if (row) child.frame.width else child.frame.height
        }

        val lower = cs.dimension(if (row) "minWidth" else "minHeight").resolve(mainAvail)
        val upper = cs.dimension(if (row) "maxWidth" else "maxHeight").resolve(mainAvail)
        // A child is never smaller than its own padding and border. Sizes are
        // border-box but `flexBasis` is content-box, so a basis of zero still
        // occupies that much — and the flex loop has to know, or it hands out
        // space the child then refuses to give back.
        val childInset = cs.inset
        val floor =
          if (row) childInset.left + childInset.right else childInset.top + childInset.bottom

        child.minMain =
          if (lower == null) (if (floor > 0f) floor else null) else max(lower, floor)
        child.maxMain = upper
        child.base = max(hypothetical, floor)
        child.main = clamp(child.base, child.minMain, child.maxMain)
        val m = cs.edges("margin")
        child.margin = m
        child.marginMain = if (row) m.left + m.right else m.top + m.bottom
        used += child.main + child.marginMain
      }
      return used
    }

    // 1. The node's own main size, measuring the content if it has none.
    val statedMain = if (row) width else height
    if (statedMain == null) {
      val used = measureChildren(honourBasis = false, mainAvail = null)
      val content = used + (if (row) padH else padV)
      val mode = if (row) widthMode else heightMode
      val available = if (row) availableWidth else availableHeight
      var fitted = content
      if (mode == XoteMeasureMode.AT_MOST && available != null && hasMeasuredLeaf(node)) {
        fitted = min(content, available)
      }
      if (row) width = clamp(fitted, minWidth, maxWidth)
      else height = clamp(fitted, minHeight, maxHeight)
    }

    val innerMain = max(0f, if (row) (width ?: 0f) - padH else (height ?: 0f) - padV)

    // 2. Flex the children into it.
    //
    // `flex: 1` is `flex-basis: 0%`, and a percentage of an *indefinite* size is
    // `auto` — the child's own content. So a column only as tall as its content
    // does not redistribute that height among the children it measured from. A
    // row is the exception, and it is the usual asymmetry: an automatic width
    // resolves to a number before the children are laid out.
    val used = measureChildren(honourBasis = statedMain != null || row, mainAvail = innerMain)
    resolveFlexibleLengths(flow, innerMain, totalGap, used)

    // 3. Lay each child out at its resolved main size.
    fun layoutChild(child: XoteLayoutNode, crossSize: Float?, crossMode: XoteMeasureMode) {
      if (row) {
        compute(
          child,
          availableWidth = child.main,
          widthMode = XoteMeasureMode.EXACTLY,
          availableHeight = crossSize,
          heightMode = crossMode,
          ownerWidth = availInnerW,
          ownerHeight = availInnerH,
        )
      } else {
        compute(
          child,
          availableWidth = crossSize,
          widthMode = crossMode,
          availableHeight = child.main,
          heightMode = XoteMeasureMode.EXACTLY,
          ownerWidth = availInnerW,
          ownerHeight = availInnerH,
        )
      }
      // A child may come back larger than it was told to be — it cannot shrink
      // below its own padding — and positioning has to use what it became.
      child.main = if (row) child.frame.width else child.frame.height
    }

    fun crossOf(child: XoteLayoutNode): Float =
      if (row) child.frame.height else child.frame.width

    fun alignOf(child: XoteLayoutNode): String =
      child.style.string("alignSelf") ?: style.string("alignItems") ?: "stretch"

    for (child in flow) {
      val m = child.margin
      val marginCross = if (row) m.top + m.bottom else m.left + m.right
      val stated =
        child.style
          .dimension(if (row) "height" else "width")
          .resolve(if (row) availInnerH else availInnerW)

      if (stated != null) {
        layoutChild(child, stated, XoteMeasureMode.EXACTLY)
      } else if (alignOf(child) == "stretch" && crossAvail != null) {
        layoutChild(child, max(0f, crossAvail - marginCross), XoteMeasureMode.EXACTLY)
      } else if (row) {
        // An automatic width is fit-content and is capped by the space
        // available; an automatic height is the content's and may overflow.
        layoutChild(child, null, XoteMeasureMode.UNDEFINED)
      } else if (crossAvail != null) {
        layoutChild(child, max(0f, crossAvail - marginCross), XoteMeasureMode.AT_MOST)
      } else {
        layoutChild(child, null, XoteMeasureMode.UNDEFINED)
      }
    }

    var lineCross = 0f
    for (child in flow) {
      val m = child.margin
      lineCross =
        max(lineCross, crossOf(child) + (if (row) m.top + m.bottom else m.left + m.right))
    }

    if (crossAvail == null) {
      // Now the line's cross size is known, stretch whatever asked to stretch.
      for (child in flow) {
        if (child.style.dimension(if (row) "height" else "width").isDefinite) continue
        if (alignOf(child) != "stretch") continue
        val m = child.margin
        val marginCross = if (row) m.top + m.bottom else m.left + m.right
        val target = max(0f, lineCross - marginCross)
        if (abs(crossOf(child) - target) > 0.01f) {
          layoutChild(child, target, XoteMeasureMode.EXACTLY)
        }
      }
    }

    // 4. The node's cross size, where it was not stated.
    val statedCross = if (row) height else width
    if (statedCross == null) {
      val content = lineCross + (if (row) padV else padH)
      val mode = if (row) heightMode else widthMode
      val available = if (row) availableHeight else availableWidth
      var fitted = content
      if (mode == XoteMeasureMode.AT_MOST && available != null && hasMeasuredLeaf(node)) {
        fitted = min(content, available)
      }
      if (row) height = clamp(fitted, minHeight, maxHeight)
      else width = clamp(fitted, minWidth, maxWidth)
    }

    // Sizes are border-box, and a border box is never smaller than the padding
    // and border it contains.
    node.frame.width = max(width ?: 0f, padH)
    node.frame.height = max(height ?: 0f, padV)

    // 5. Place the children.
    val placeMain = max(0f, if (row) node.frame.width - padH else node.frame.height - padV)
    val placeCross = max(0f, if (row) node.frame.height - padV else node.frame.width - padH)
    var contentMain = totalGap
    for (child in flow) contentMain += child.main + child.marginMain
    val freeMain = placeMain - contentMain

    // Alignment still applies when the free space is negative: `center` and
    // `flex-end` let the content overflow away from the edge they aligned to.
    // The spacing values have nothing to distribute and fall back differently —
    // `space-between` to `flex-start`, which is flow-relative, and the other two
    // to a *safe* centre, which packs against the physical start so the overflow
    // stays reachable. In a reverse direction those are opposite ends.
    val justify = style.string("justifyContent") ?: "flex-start"
    val spread = max(freeMain, 0f)
    val safeStart = if (reverse && freeMain < 0f) freeMain else 0f
    var cursor = 0f
    var between = gap
    when (justify) {
      "center" -> cursor = freeMain / 2f
      "flex-end" -> cursor = freeMain
      "space-between" -> if (flow.size > 1) between = gap + spread / (flow.size - 1)
      "space-around" -> {
        cursor = safeStart
        if (flow.isNotEmpty()) {
          val around = spread / flow.size
          cursor += around / 2f
          between = gap + around
        }
      }
      "space-evenly" -> {
        cursor = safeStart
        if (flow.isNotEmpty()) {
          val evenly = spread / (flow.size + 1)
          cursor += evenly
          between = gap + evenly
        }
      }
    }

    // A reverse direction is the same placement mirrored, not the children in
    // the opposite order: `flex-start` still means the start of the flow, which
    // is now the far edge. Margins stay physical through the mirror.
    for ((index, child) in flow.withIndex()) {
      val m = child.margin
      val physicalLead = if (row) m.left else m.top
      val physicalTrail = if (row) m.right else m.bottom
      val leadMain = if (reverse) physicalTrail else physicalLead
      val trailMain = if (reverse) physicalLead else physicalTrail
      val leadCross = if (row) m.top else m.left
      val trailCross = if (row) m.bottom else m.right

      val flowStart = cursor + leadMain
      val mainStart = if (reverse) placeMain - flowStart - child.main else flowStart

      val childCross = crossOf(child)
      var crossStart = leadCross
      when (alignOf(child)) {
        "center" ->
          crossStart = (placeCross - childCross - leadCross - trailCross) / 2f + leadCross
        "flex-end" -> crossStart = placeCross - childCross - trailCross
      }

      if (row) {
        child.frame.left = pad.left + mainStart
        child.frame.top = pad.top + crossStart
      } else {
        child.frame.left = pad.left + crossStart
        child.frame.top = pad.top + mainStart
      }

      cursor = flowStart + child.main + trailMain
      if (index < flow.size - 1) cursor += between
    }

    // 6. Absolutely positioned children. Their containing block is the padding
    // box — inset by the border, not by the padding.
    val b = style.number("borderWidth") ?: 0f
    for (child in children) {
      if (child.style.string("position") != "absolute") continue
      layoutAbsolute(
        child,
        XoteEdges(left = b, right = b, top = b, bottom = b),
        node.frame.width,
        node.frame.height,
      )
    }
  }

  private fun layoutAbsolute(
    child: XoteLayoutNode,
    pad: XoteEdges,
    parentWidth: Float,
    parentHeight: Float,
  ) {
    val cs = child.style
    val boxW = parentWidth - pad.left - pad.right
    val boxH = parentHeight - pad.top - pad.bottom

    val left = cs.dimension("left").resolve(boxW)
    val right = cs.dimension("right").resolve(boxW)
    val top = cs.dimension("top").resolve(boxH)
    val bottom = cs.dimension("bottom").resolve(boxH)

    var width = cs.dimension("width").resolve(boxW)
    var height = cs.dimension("height").resolve(boxH)
    if (width == null && left != null && right != null) width = max(0f, boxW - left - right)
    if (height == null && top != null && bottom != null) height = max(0f, boxH - top - bottom)

    compute(
      child,
      availableWidth = width,
      widthMode = if (width == null) XoteMeasureMode.AT_MOST else XoteMeasureMode.EXACTLY,
      availableHeight = height,
      heightMode = if (height == null) XoteMeasureMode.AT_MOST else XoteMeasureMode.EXACTLY,
      ownerWidth = boxW,
      ownerHeight = boxH,
    )

    child.frame.left =
      when {
        left != null -> pad.left + left
        right != null -> pad.left + boxW - right - child.frame.width
        else -> pad.left
      }

    child.frame.top =
      when {
        top != null -> pad.top + top
        bottom != null -> pad.top + boxH - bottom - child.frame.height
        else -> pad.top
      }
  }
}
