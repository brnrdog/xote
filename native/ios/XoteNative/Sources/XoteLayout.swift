import CoreGraphics
import Foundation

/// Flexbox layout.
///
/// A line-for-line transliteration of `native/host/layout.mjs`, which is
/// checked frame-for-frame against Chromium's own flexbox by
/// `native/test/layout_test.mjs`. Keep the two in step: a change here that is
/// not also a change there is a change nothing tests.
///
/// Covered: direction including reverse, `justifyContent`, `alignItems` and
/// `alignSelf`, grow/shrink/basis, min and max, points and percentages, margin,
/// padding, border width, gaps, `aspectRatio`, absolute positioning, and
/// measured leaves for text. Not covered, deliberately: `flexWrap`, baseline
/// alignment, `alignContent`, and percentage margins and paddings. Reaching one
/// of those is the signal to swap this out for Yoga.
enum XoteMeasureMode {
  /// As much as it wants.
  case undefined
  /// This much, no argument.
  case exactly
  /// No more than this.
  case atMost
}

struct XoteSize {
  var width: CGFloat
  var height: CGFloat
}

struct XoteEdges {
  var left: CGFloat = 0
  var right: CGFloat = 0
  var top: CGFloat = 0
  var bottom: CGFloat = 0
}

struct XoteFrame {
  var left: CGFloat = 0
  var top: CGFloat = 0
  var width: CGFloat = 0
  var height: CGFloat = 0
}

/// The layout tree, which shadows the view tree one-for-one.
final class XoteLayoutNode {
  var style = XoteStyle(nil)
  var children: [XoteLayoutNode] = []
  var frame = XoteFrame()

  /// The `UIView` this box positions, when there is one — and there is not
  /// always one. A scroll view's inner content box has none, and neither does a
  /// box that was flattened away (`XoteFlatten`): both arrange their children
  /// without occupying a coordinate space, so the children are placed relative
  /// to them by the caller instead.
  weak var view: AnyObject?

  /// Set on a text node. Given the space available, how big does it want to be?
  var measure: ((CGFloat?, XoteMeasureMode, CGFloat?, XoteMeasureMode) -> XoteSize)?

  // Scratch space for one layout pass.
  fileprivate var base: CGFloat = 0
  fileprivate var main: CGFloat = 0
  fileprivate var minMain: CGFloat?
  fileprivate var maxMain: CGFloat?
  fileprivate var margin = XoteEdges()
  fileprivate var marginMain: CGFloat = 0
  fileprivate var violation: CGFloat = 0
  fileprivate var measuredSubtree: Bool?
}

enum XoteLayout {
  /// Lay `root` out in a box of `width` × `height`, writing a frame onto every
  /// node. Positions are relative to the parent's border box — a `frame`.
  static func layout(_ root: XoteLayoutNode, width: CGFloat?, height: CGFloat?) {
    compute(
      root,
      availableWidth: width,
      widthMode: width == nil ? .undefined : .exactly,
      availableHeight: height,
      heightMode: height == nil ? .undefined : .exactly,
      ownerWidth: width,
      ownerHeight: height
    )
    root.frame.left = 0
    root.frame.top = 0
  }

  // MARK: - Helpers

  private static func clamp(_ value: CGFloat, _ min: CGFloat?, _ max: CGFloat?) -> CGFloat {
    var out = value
    if let max = max, out > max { out = max }
    if let min = min, out < min { out = min }
    return out
  }

  /// Is there text anywhere in this subtree?
  ///
  /// It decides whether an automatic size is capped by the space available.
  /// `fit-content` is `clamp(min-content, available, max-content)`, and for a
  /// subtree of plain boxes those last two are the same number — nothing gets
  /// narrower by being given less room — so capping would shrink a box below
  /// content that is going to overflow anyway. Text is the exception.
  private static func hasMeasuredLeaf(_ node: XoteLayoutNode) -> Bool {
    if let cached = node.measuredSubtree { return cached }
    var found = node.measure != nil
    for child in node.children where !found {
      found = hasMeasuredLeaf(child)
    }
    node.measuredSubtree = found
    return found
  }

  /// CSS's "resolve flexible lengths", which is a loop rather than a division:
  /// distributing in one pass and clamping afterwards loses whatever the clamp
  /// took away, so each round freezes the items that hit a bound and runs again.
  private static func resolveFlexibleLengths(
    _ flow: [XoteLayoutNode],
    mainAvail: CGFloat,
    totalGap: CGFloat,
    usedHypothetical: CGFloat
  ) {
    let growing = mainAvail - usedHypothetical > 0
    var frozen = Set<ObjectIdentifier>()

    for child in flow {
      let factor = growing ? child.style.flexGrow : child.style.flexShrink
      if factor == 0 {
        child.main = clamp(child.base, child.minMain, child.maxMain)
        frozen.insert(ObjectIdentifier(child))
      }
    }

    for _ in 0...flow.count {
      let unfrozen = flow.filter { !frozen.contains(ObjectIdentifier($0)) }
      if unfrozen.isEmpty { return }

      var free = mainAvail - totalGap
      for child in flow {
        free -= child.marginMain
        free -= frozen.contains(ObjectIdentifier(child)) ? child.main : child.base
      }

      // Shrinking is weighted by the base size, so a large item gives up more
      // than a small one with the same factor.
      let totalFactor = unfrozen.reduce(CGFloat(0)) { sum, child in
        sum + (growing ? child.style.flexGrow : child.style.flexShrink * child.base)
      }

      var violation: CGFloat = 0
      for child in unfrozen {
        let weight = growing ? child.style.flexGrow : child.style.flexShrink * child.base
        let share = totalFactor > 0 ? (free * weight) / totalFactor : 0
        let unclamped = child.base + share
        let clamped = clamp(unclamped, child.minMain, child.maxMain)
        child.main = clamped
        child.violation = clamped - unclamped
        violation += child.violation
      }

      if abs(violation) < 0.0001 { return }
      for child in unfrozen where violation > 0 ? child.violation > 0 : child.violation < 0 {
        frozen.insert(ObjectIdentifier(child))
      }
    }
  }

  // MARK: - The pass

  private static func compute(
    _ node: XoteLayoutNode,
    availableWidth: CGFloat?,
    widthMode: XoteMeasureMode,
    availableHeight: CGFloat?,
    heightMode: XoteMeasureMode,
    ownerWidth: CGFloat?,
    ownerHeight: CGFloat?
  ) {
    let style = node.style

    let minWidth = style.dimension("minWidth").resolve(ownerWidth)
    let maxWidth = style.dimension("maxWidth").resolve(ownerWidth)
    let minHeight = style.dimension("minHeight").resolve(ownerHeight)
    let maxHeight = style.dimension("maxHeight").resolve(ownerHeight)

    var width = widthMode == .exactly ? availableWidth : style.dimension("width").resolve(ownerWidth)
    var height =
      heightMode == .exactly ? availableHeight : style.dimension("height").resolve(ownerHeight)

    if let ratio = style.number("aspectRatio"), ratio > 0 {
      if let w = width, height == nil { height = w / ratio } else if let h = height, width == nil {
        width = h * ratio
      }
    }

    if let w = width { width = clamp(w, minWidth, maxWidth) }
    if let h = height { height = clamp(h, minHeight, maxHeight) }

    let pad = style.inset
    let padH = pad.left + pad.right
    let padV = pad.top + pad.bottom

    let children = node.children.filter { $0.style.string("display") != "none" }
    let flow = children.filter { $0.style.string("position") != "absolute" }

    // MARK: a measured leaf

    if let measure = node.measure, flow.isEmpty {
      var innerAvailW = width.map { $0 - padH }
      if innerAvailW == nil, let available = availableWidth {
        innerAvailW = clamp(available, minWidth, maxWidth) - padH
      }
      var innerAvailH = height.map { $0 - padV }
      if innerAvailH == nil, let available = availableHeight {
        innerAvailH = clamp(available, minHeight, maxHeight) - padV
      }

      if width == nil || height == nil {
        let measured = measure(
          innerAvailW,
          width != nil ? .exactly : (widthMode == .exactly ? .atMost : widthMode),
          innerAvailH,
          height != nil ? .exactly : (heightMode == .exactly ? .atMost : heightMode)
        )
        if width == nil { width = clamp(measured.width + padH, minWidth, maxWidth) }
        if height == nil { height = clamp(measured.height + padV, minHeight, maxHeight) }
      }

      node.frame.width = max(width ?? 0, padH)
      node.frame.height = max(height ?? 0, padV)
      return
    }

    // MARK: a container

    let direction = style.string("flexDirection") ?? "column"
    let row = direction == "row" || direction == "row-reverse"
    let reverse = direction == "row-reverse" || direction == "column-reverse"
    let gap = style.gap(isRow: row)
    let totalGap = flow.count > 1 ? gap * CGFloat(flow.count - 1) : 0

    var availInnerW: CGFloat?
    if let w = width {
      availInnerW = w - padH
    } else if let available = availableWidth {
      availInnerW = clamp(available, minWidth, maxWidth) - padH
    }
    var availInnerH: CGFloat?
    if let h = height {
      availInnerH = h - padV
    } else if let available = availableHeight {
      availInnerH = clamp(available, minHeight, maxHeight) - padV
    }

    // "Definite" and "available" are not the same thing: a node under `atMost`
    // has space but no size of its own, and `stretch` has nothing to stretch to
    // until the line's own cross size is known.
    let definiteCross = row ? height != nil : width != nil
    let crossAvail: CGFloat? = definiteCross ? (row ? availInnerH : availInnerW) : nil

    /// Each child's flex base size and hypothetical main size.
    ///
    /// `honourBasis` separates the two questions this answers. Laying out, a
    /// `flex: 1` child starts from a basis of zero and grows into the
    /// container. *Measuring* an auto-sized container, that basis is
    /// meaningless — there is no size yet, and a row of flexible children would
    /// measure as nothing — so the child's max-content size stands in.
    func measureChildren(honourBasis: Bool, mainAvail: CGFloat?) -> CGFloat {
      var used = totalGap
      for child in flow {
        let cs = child.style
        let basis = honourBasis ? cs.flexBasis.resolve(mainAvail) : nil
        let styleMain =
          cs.dimension(row ? "width" : "height").resolve(row ? availInnerW : availInnerH)

        var hypothetical: CGFloat
        if let basis = basis {
          hypothetical = basis
        } else if let stated = styleMain {
          hypothetical = stated
        } else {
          // The flex base size is the child's max-content size: unconstrained
          // on the main axis, and only shrunk later by the flex loop.
          let childCrossAvail = row ? availInnerH : availInnerW
          let crossMode: XoteMeasureMode = childCrossAvail == nil ? .undefined : .atMost
          compute(
            child,
            availableWidth: row ? nil : childCrossAvail,
            widthMode: row ? .undefined : crossMode,
            availableHeight: row ? childCrossAvail : nil,
            heightMode: row ? crossMode : .undefined,
            ownerWidth: availInnerW,
            ownerHeight: availInnerH
          )
          hypothetical = row ? child.frame.width : child.frame.height
        }

        let min = cs.dimension(row ? "minWidth" : "minHeight").resolve(mainAvail)
        let max = cs.dimension(row ? "maxWidth" : "maxHeight").resolve(mainAvail)
        // A child is never smaller than its own padding and border. Sizes are
        // border-box but `flexBasis` is content-box, so a basis of zero still
        // occupies that much — and the flex loop has to know, or it hands out
        // space the child then refuses to give back.
        let childInset = cs.inset
        let floor = row
          ? childInset.left + childInset.right
          : childInset.top + childInset.bottom

        child.minMain = min == nil ? (floor > 0 ? floor : nil) : Swift.max(min!, floor)
        child.maxMain = max
        child.base = Swift.max(hypothetical, floor)
        child.main = clamp(child.base, child.minMain, child.maxMain)
        let m = cs.edges("margin")
        child.margin = m
        child.marginMain = row ? m.left + m.right : m.top + m.bottom
        used += child.main + child.marginMain
      }
      return used
    }

    // 1. The node's own main size, measuring the content if it has none.
    let statedMain = row ? width : height
    if statedMain == nil {
      let used = measureChildren(honourBasis: false, mainAvail: nil)
      let content = used + (row ? padH : padV)
      let mode = row ? widthMode : heightMode
      let available = row ? availableWidth : availableHeight
      var fitted = content
      if mode == .atMost, let available = available, hasMeasuredLeaf(node) {
        fitted = min(content, available)
      }
      if row { width = clamp(fitted, minWidth, maxWidth) } else {
        height = clamp(fitted, minHeight, maxHeight)
      }
    }

    let innerMain = max(0, (row ? (width ?? 0) - padH : (height ?? 0) - padV))

    // 2. Flex the children into it.
    //
    // `flex: 1` is `flex-basis: 0%`, and a percentage of an *indefinite* size
    // is `auto` — the child's own content. So a column only as tall as its
    // content does not redistribute that height among the children it measured
    // from. A row is the exception, and it is the usual asymmetry: an automatic
    // width resolves to a number before the children are laid out.
    let used = measureChildren(honourBasis: statedMain != nil || row, mainAvail: innerMain)
    resolveFlexibleLengths(flow, mainAvail: innerMain, totalGap: totalGap, usedHypothetical: used)

    // 3. Lay each child out at its resolved main size.
    func layoutChild(_ child: XoteLayoutNode, crossSize: CGFloat?, crossMode: XoteMeasureMode) {
      if row {
        compute(
          child,
          availableWidth: child.main, widthMode: .exactly,
          availableHeight: crossSize, heightMode: crossMode,
          ownerWidth: availInnerW, ownerHeight: availInnerH
        )
      } else {
        compute(
          child,
          availableWidth: crossSize, widthMode: crossMode,
          availableHeight: child.main, heightMode: .exactly,
          ownerWidth: availInnerW, ownerHeight: availInnerH
        )
      }
      // A child may come back larger than it was told to be — it cannot shrink
      // below its own padding — and positioning has to use what it became.
      child.main = row ? child.frame.width : child.frame.height
    }

    func crossOf(_ child: XoteLayoutNode) -> CGFloat {
      row ? child.frame.height : child.frame.width
    }
    func alignOf(_ child: XoteLayoutNode) -> String {
      child.style.string("alignSelf") ?? style.string("alignItems") ?? "stretch"
    }

    for child in flow {
      let m = child.margin
      let marginCross = row ? m.top + m.bottom : m.left + m.right
      let stated =
        child.style.dimension(row ? "height" : "width").resolve(row ? availInnerH : availInnerW)

      if let stated = stated {
        layoutChild(child, crossSize: stated, crossMode: .exactly)
      } else if alignOf(child) == "stretch", let crossAvail = crossAvail {
        layoutChild(child, crossSize: max(0, crossAvail - marginCross), crossMode: .exactly)
      } else if row {
        // An automatic width is fit-content and is capped by the space
        // available; an automatic height is the content's and may overflow.
        layoutChild(child, crossSize: nil, crossMode: .undefined)
      } else if let crossAvail = crossAvail {
        layoutChild(child, crossSize: max(0, crossAvail - marginCross), crossMode: .atMost)
      } else {
        layoutChild(child, crossSize: nil, crossMode: .undefined)
      }
    }

    var lineCross: CGFloat = 0
    for child in flow {
      let m = child.margin
      lineCross = max(lineCross, crossOf(child) + (row ? m.top + m.bottom : m.left + m.right))
    }

    if crossAvail == nil {
      // Now the line's cross size is known, stretch whatever asked to stretch.
      for child in flow {
        if child.style.dimension(row ? "height" : "width").isDefinite { continue }
        if alignOf(child) != "stretch" { continue }
        let m = child.margin
        let marginCross = row ? m.top + m.bottom : m.left + m.right
        let target = max(0, lineCross - marginCross)
        if abs(crossOf(child) - target) > 0.01 {
          layoutChild(child, crossSize: target, crossMode: .exactly)
        }
      }
    }

    // 4. The node's cross size, where it was not stated.
    let statedCross = row ? height : width
    if statedCross == nil {
      let content = lineCross + (row ? padV : padH)
      let mode = row ? heightMode : widthMode
      let available = row ? availableHeight : availableWidth
      var fitted = content
      if mode == .atMost, let available = available, hasMeasuredLeaf(node) {
        fitted = min(content, available)
      }
      if row { height = clamp(fitted, minHeight, maxHeight) } else {
        width = clamp(fitted, minWidth, maxWidth)
      }
    }

    // Sizes are border-box, and a border box is never smaller than the padding
    // and border it contains.
    node.frame.width = max(width ?? 0, padH)
    node.frame.height = max(height ?? 0, padV)

    // 5. Place the children.
    let placeMain = max(0, row ? node.frame.width - padH : node.frame.height - padV)
    let placeCross = max(0, row ? node.frame.height - padV : node.frame.width - padH)
    var contentMain = totalGap
    for child in flow { contentMain += child.main + child.marginMain }
    let freeMain = placeMain - contentMain

    // Alignment still applies when the free space is negative: `center` and
    // `flex-end` let the content overflow away from the edge they aligned to.
    // The spacing values have nothing to distribute and fall back differently —
    // `space-between` to `flex-start`, which is flow-relative, and the other
    // two to a *safe* centre, which packs against the physical start so the
    // overflow stays reachable. In a reverse direction those are opposite ends.
    let justify = style.string("justifyContent") ?? "flex-start"
    let spread = max(freeMain, 0)
    let safeStart = (reverse && freeMain < 0) ? freeMain : 0
    var cursor: CGFloat = 0
    var between = gap
    switch justify {
    case "center":
      cursor = freeMain / 2
    case "flex-end":
      cursor = freeMain
    case "space-between":
      if flow.count > 1 { between = gap + spread / CGFloat(flow.count - 1) }
    case "space-around":
      cursor = safeStart
      if !flow.isEmpty {
        let around = spread / CGFloat(flow.count)
        cursor += around / 2
        between = gap + around
      }
    case "space-evenly":
      cursor = safeStart
      if !flow.isEmpty {
        let evenly = spread / CGFloat(flow.count + 1)
        cursor += evenly
        between = gap + evenly
      }
    default:
      break
    }

    // A reverse direction is the same placement mirrored, not the children in
    // the opposite order: `flex-start` still means the start of the flow, which
    // is now the far edge. Margins stay physical through the mirror.
    for (index, child) in flow.enumerated() {
      let m = child.margin
      let physicalLead = row ? m.left : m.top
      let physicalTrail = row ? m.right : m.bottom
      let leadMain = reverse ? physicalTrail : physicalLead
      let trailMain = reverse ? physicalLead : physicalTrail
      let leadCross = row ? m.top : m.left
      let trailCross = row ? m.bottom : m.right

      let flowStart = cursor + leadMain
      let mainStart = reverse ? placeMain - flowStart - child.main : flowStart

      let childCross = crossOf(child)
      var crossStart = leadCross
      switch alignOf(child) {
      case "center":
        crossStart = (placeCross - childCross - leadCross - trailCross) / 2 + leadCross
      case "flex-end":
        crossStart = placeCross - childCross - trailCross
      default:
        break
      }

      if row {
        child.frame.left = pad.left + mainStart
        child.frame.top = pad.top + crossStart
      } else {
        child.frame.left = pad.left + crossStart
        child.frame.top = pad.top + mainStart
      }

      cursor = flowStart + child.main + trailMain
      if index < flow.count - 1 { cursor += between }
    }

    // 6. Absolutely positioned children. Their containing block is the padding
    // box — inset by the border, not by the padding.
    let b = style.number("borderWidth") ?? 0
    for child in children where child.style.string("position") == "absolute" {
      layoutAbsolute(
        child,
        pad: XoteEdges(left: b, right: b, top: b, bottom: b),
        parentWidth: node.frame.width,
        parentHeight: node.frame.height
      )
    }
  }

  private static func layoutAbsolute(
    _ child: XoteLayoutNode,
    pad: XoteEdges,
    parentWidth: CGFloat,
    parentHeight: CGFloat
  ) {
    let cs = child.style
    let boxW = parentWidth - pad.left - pad.right
    let boxH = parentHeight - pad.top - pad.bottom

    let left = cs.dimension("left").resolve(boxW)
    let right = cs.dimension("right").resolve(boxW)
    let top = cs.dimension("top").resolve(boxH)
    let bottom = cs.dimension("bottom").resolve(boxH)

    var width = cs.dimension("width").resolve(boxW)
    var height = cs.dimension("height").resolve(boxH)
    if width == nil, let left = left, let right = right { width = max(0, boxW - left - right) }
    if height == nil, let top = top, let bottom = bottom { height = max(0, boxH - top - bottom) }

    compute(
      child,
      availableWidth: width, widthMode: width == nil ? .atMost : .exactly,
      availableHeight: height, heightMode: height == nil ? .atMost : .exactly,
      ownerWidth: boxW, ownerHeight: boxH
    )

    if let left = left {
      child.frame.left = pad.left + left
    } else if let right = right {
      child.frame.left = pad.left + boxW - right - child.frame.width
    } else {
      child.frame.left = pad.left
    }

    if let top = top {
      child.frame.top = pad.top + top
    } else if let bottom = bottom {
      child.frame.top = pad.top + boxH - bottom - child.frame.height
    } else {
      child.frame.top = pad.top
    }
  }
}
