/**
 * Flexbox layout — the reference implementation.
 *
 * The roadmap said "embed Yoga", and for a shipping host that is still the
 * right answer. This exists because of a constraint of *this* repository: it is
 * developed on Linux, where there is no way to compile, run or test a line of
 * Swift, so an unverifiable C++ dependency integration plus an unverifiable
 * Swift bridge is two unknowns stacked on each other.
 *
 * A layout engine in JavaScript can be held to a much higher standard than
 * that: `native/test/layout_test.mjs` lays out the same trees in Chromium with
 * real CSS flexbox and asserts the frames match. So the algorithm below is
 * checked against the actual specification, by the actual implementation, and
 * the Swift port in `native/hosts/ios/.../XoteLayout.swift` is a transliteration of
 * something known to be right — leaving only Swift syntax unverified instead of
 * the semantics too. It also means the Android host is a second transliteration
 * rather than a second integration.
 *
 * What it covers: the single-line subset `NativeStyle` can express — direction
 * (including reverse), `justifyContent`, `alignItems`/`alignSelf`, grow/shrink/
 * basis, min/max, points and percentages, margin, padding, border width, gaps,
 * `aspectRatio`, absolute positioning, and measured leaves for text.
 *
 * What it does not: `flexWrap` (every container is one line), baseline
 * alignment, `alignContent`, and percentage margins and paddings. Each is a
 * deliberate omission rather than an oversight — see `ROADMAP.md`. Reaching one
 * of them is the signal to swap this for Yoga behind `XoteLayoutEngine`.
 */

/** How much the parent is telling a child about the space it has. */
export const UNDEFINED = 0; // as much as it wants
export const EXACTLY = 1; // this much, no argument
export const AT_MOST = 2; // no more than this

const isRowAxis = (direction) => direction === "row" || direction === "row-reverse";
const isReverse = (direction) =>
  direction === "row-reverse" || direction === "column-reverse";

/** Points, `"50%"`, or nothing. `"auto"` and `undefined` both mean nothing. */
function resolve(value, base) {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.endsWith("%")) {
    if (base === undefined) return undefined;
    return (parseFloat(value) / 100) * base;
  }
  return undefined;
}

function clamp(value, min, max) {
  let out = value;
  if (max !== undefined && out > max) out = max;
  if (min !== undefined && out < min) out = min;
  return out;
}

/** One edge of `margin` / `padding`, with the shorthands folded in. */
function edge(style, prefix, side) {
  const longhand = style[prefix + side];
  if (typeof longhand === "number") return longhand;
  const axis = side === "Left" || side === "Right" ? "Horizontal" : "Vertical";
  const shorthand = style[prefix + axis];
  if (typeof shorthand === "number") return shorthand;
  return typeof style[prefix] === "number" ? style[prefix] : 0;
}

const border = (style) => (typeof style.borderWidth === "number" ? style.borderWidth : 0);

function edges(style, prefix) {
  return {
    left: edge(style, prefix, "Left"),
    right: edge(style, prefix, "Right"),
    top: edge(style, prefix, "Top"),
    bottom: edge(style, prefix, "Bottom"),
  };
}

/** Padding plus border — the inset from a node's box to its content. */
function inset(style) {
  const padding = edges(style, "padding");
  const b = border(style);
  return {
    left: padding.left + b,
    right: padding.right + b,
    top: padding.top + b,
    bottom: padding.bottom + b,
  };
}

const gapFor = (style, isRow) => {
  const specific = isRow ? style.columnGap : style.rowGap;
  if (typeof specific === "number") return specific;
  return typeof style.gap === "number" ? style.gap : 0;
};

/** `flex: n` is `flexGrow: n, flexShrink: 1, flexBasis: 0`, as in CSS and RN. */
function flexOf(style) {
  const shorthand = typeof style.flex === "number" ? style.flex : undefined;
  const grow =
    typeof style.flexGrow === "number"
      ? style.flexGrow
      : shorthand !== undefined && shorthand > 0
        ? shorthand
        : 0;
  const shrink =
    typeof style.flexShrink === "number" ? style.flexShrink : shorthand !== undefined ? 1 : 0;
  const basis =
    style.flexBasis !== undefined && style.flexBasis !== "auto"
      ? style.flexBasis
      : shorthand !== undefined && shorthand > 0
        ? 0
        : undefined;
  return { grow, shrink, basis };
}

const isAbsolute = (node) => node.style.position === "absolute";

/**
 * Does anything in this subtree measure itself — that is, is there text?
 *
 * It decides whether an automatic size is capped by the space available.
 * `fit-content` is `clamp(min-content, available, max-content)`, and for a
 * subtree of plain boxes min-content and max-content are the same number: there
 * is nothing that can be made narrower by giving it less room, so capping would
 * shrink a box below content that is going to overflow anyway. Text is the
 * exception — it genuinely gets taller as it gets narrower — so a subtree
 * containing any is capped, and one without is not.
 */
function hasMeasuredLeaf(node) {
  if (node._measured !== undefined) return node._measured;
  let found = typeof node.measure === "function";
  for (const child of node.children || []) {
    if (found) break;
    found = hasMeasuredLeaf(child);
  }
  node._measured = found;
  return found;
}


/**
 * CSS's "resolve flexible lengths", which is a loop rather than a division.
 *
 * Distributing free space in one pass and then clamping loses whatever the
 * clamp took away — an item pinned to its `maxWidth` leaves space that its
 * siblings should have received. So each round freezes the items that hit a
 * bound and runs again with the rest, until nothing is violated.
 */
function resolveFlexibleLengths(flow, mainAvail, totalGap, usedHypothetical) {
  const growing = mainAvail - usedHypothetical > 0;
  const frozen = new Set();

  for (const child of flow) {
    const { grow, shrink } = flexOf(child.style || {});
    const factor = growing ? grow : shrink;
    if (factor === 0) {
      child._main = clamp(child._base, child._min, child._max);
      frozen.add(child);
    }
  }

  for (let round = 0; round < flow.length + 1; round++) {
    const unfrozen = flow.filter((child) => !frozen.has(child));
    if (unfrozen.length === 0) return;

    let free = mainAvail - totalGap;
    for (const child of flow) {
      free -= child._marginMain;
      if (frozen.has(child)) free -= child._main;
      else free -= child._base;
    }

    const totalFactor = unfrozen.reduce((sum, child) => {
      const { grow, shrink } = flexOf(child.style || {});
      // Shrinking is weighted by the base size, so a large item gives up more
      // than a small one with the same factor.
      return sum + (growing ? grow : shrink * child._base);
    }, 0);

    let violation = 0;
    for (const child of unfrozen) {
      const { grow, shrink } = flexOf(child.style || {});
      const weight = growing ? grow : shrink * child._base;
      const share = totalFactor > 0 ? (free * weight) / totalFactor : 0;
      const unclamped = child._base + share;
      const clamped = clamp(unclamped, child._min, child._max);
      child._main = clamped;
      child._violation = clamped - unclamped;
      violation += child._violation;
    }

    if (Math.abs(violation) < 0.0001) return;
    for (const child of unfrozen) {
      if (violation > 0 ? child._violation > 0 : child._violation < 0) frozen.add(child);
    }
  }
}


/**
 * Lay out `root` inside a box of `width` × `height`, and write a
 * `{ left, top, width, height }` onto every node. Positions are relative to the
 * parent's border box, which is what a host wants for `frame`.
 */
export function layout(root, width, height) {
  computeLayout(
    root,
    width,
    width === undefined ? UNDEFINED : EXACTLY,
    height,
    height === undefined ? UNDEFINED : EXACTLY,
    width,
    height,
  );
  root.layout.left = 0;
  root.layout.top = 0;
  return root;
}


function computeLayout(
  node,
  availableWidth,
  widthMode,
  availableHeight,
  heightMode,
  ownerWidth,
  ownerHeight,
) {
  const style = node.style || {};
  if (node.layout === undefined) node.layout = { left: 0, top: 0, width: 0, height: 0 };

  const minWidth = resolve(style.minWidth, ownerWidth);
  const maxWidth = resolve(style.maxWidth, ownerWidth);
  const minHeight = resolve(style.minHeight, ownerHeight);
  const maxHeight = resolve(style.maxHeight, ownerHeight);

  let width = widthMode === EXACTLY ? availableWidth : resolve(style.width, ownerWidth);
  let height = heightMode === EXACTLY ? availableHeight : resolve(style.height, ownerHeight);

  if (typeof style.aspectRatio === "number" && style.aspectRatio > 0) {
    if (width !== undefined && height === undefined) height = width / style.aspectRatio;
    else if (height !== undefined && width === undefined) width = height * style.aspectRatio;
  }

  if (width !== undefined) width = clamp(width, minWidth, maxWidth);
  if (height !== undefined) height = clamp(height, minHeight, maxHeight);

  const pad = inset(style);
  const padH = pad.left + pad.right;
  const padV = pad.top + pad.bottom;

  const children = (node.children || []).filter((child) => child.style?.display !== "none");
  const flow = children.filter((child) => !isAbsolute(child));

  /* ---- a measured leaf (text) ------------------------------------------- */

  if (typeof node.measure === "function" && flow.length === 0) {
    let innerAvailW = width !== undefined ? width - padH : undefined;
    if (innerAvailW === undefined && availableWidth !== undefined) {
      innerAvailW = clamp(availableWidth, minWidth, maxWidth) - padH;
    }
    let innerAvailH = height !== undefined ? height - padV : undefined;
    if (innerAvailH === undefined && availableHeight !== undefined) {
      innerAvailH = clamp(availableHeight, minHeight, maxHeight) - padV;
    }

    if (width === undefined || height === undefined) {
      const measured = node.measure(
        innerAvailW,
        width !== undefined ? EXACTLY : widthMode === EXACTLY ? AT_MOST : widthMode,
        innerAvailH,
        height !== undefined ? EXACTLY : heightMode === EXACTLY ? AT_MOST : heightMode,
      );
      if (width === undefined) width = clamp(measured.width + padH, minWidth, maxWidth);
      if (height === undefined) height = clamp(measured.height + padV, minHeight, maxHeight);
    }

    node.layout.width = Math.max(width ?? 0, padH);
    node.layout.height = Math.max(height ?? 0, padV);
    return;
  }

  /* ---- a container ------------------------------------------------------ */

  const direction = style.flexDirection || "column";
  const row = isRowAxis(direction);
  const reverse = isReverse(direction);
  const gap = gapFor(style, row);
  const totalGap = flow.length > 1 ? gap * (flow.length - 1) : 0;

  const availInnerW =
    width !== undefined
      ? width - padH
      : availableWidth !== undefined
        ? clamp(availableWidth, minWidth, maxWidth) - padH
        : undefined;
  const availInnerH =
    height !== undefined
      ? height - padV
      : availableHeight !== undefined
        ? clamp(availableHeight, minHeight, maxHeight) - padV
        : undefined;

  // "Definite" and "available" are not the same thing. A node under AT_MOST has
  // space available but no size of its own, so its content — not the space —
  // decides how big it is, and a `stretch` child has nothing to stretch to
  // until the line's own cross size is known.
  const definiteCross = row ? height !== undefined : width !== undefined;
  const crossAvail = definiteCross ? (row ? availInnerH : availInnerW) : undefined;

  /**
   * Each child's flex base size and hypothetical main size.
   *
   * `honourBasis` is the difference between the two questions this gets asked.
   * Laying out, a `flex: 1` child starts from a basis of zero and grows into
   * whatever the container has. *Measuring* an auto-sized container, that same
   * basis is meaningless — the container has no size yet, and a row of flexible
   * children would measure as nothing at all — so the child's max-content size
   * stands in for it.
   */
  const measureChildren = (honourBasis, mainAvail) => {
    let used = totalGap;
    for (const child of flow) {
      const cs = child.style || {};
      const { basis } = flexOf(cs);
      const basisPoints = honourBasis ? resolve(basis, mainAvail) : undefined;
      const styleMain = resolve(row ? cs.width : cs.height, row ? availInnerW : availInnerH);

      let hypothetical;
      if (basisPoints !== undefined) {
        hypothetical = basisPoints;
      } else if (styleMain !== undefined) {
        hypothetical = styleMain;
      } else {
        // The flex base size is the child's *max-content* size: unconstrained
        // along the main axis, and only shrunk later by the flex loop. Passing
        // the available main size here instead would cap the child at its
        // container before flexing had a say.
        const childCrossAvail = row ? availInnerH : availInnerW;
        const crossMode = childCrossAvail === undefined ? UNDEFINED : AT_MOST;
        computeLayout(
          child,
          row ? undefined : childCrossAvail,
          row ? UNDEFINED : crossMode,
          row ? childCrossAvail : undefined,
          row ? crossMode : UNDEFINED,
          availInnerW,
          availInnerH,
        );
        hypothetical = row ? child.layout.width : child.layout.height;
      }

      const min = resolve(row ? cs.minWidth : cs.minHeight, mainAvail);
      const max = resolve(row ? cs.maxWidth : cs.maxHeight, mainAvail);
      // A child can never be smaller than its own padding and border. Sizes are
      // border-box but `flexBasis` is content-box, so a basis of zero still
      // occupies that much — and the flex loop has to know, or it hands out
      // space the child then refuses to give back.
      const childInset = inset(cs);
      const floor = row
        ? childInset.left + childInset.right
        : childInset.top + childInset.bottom;

      child._min = min === undefined ? (floor > 0 ? floor : undefined) : Math.max(min, floor);
      child._max = max;
      child._base = Math.max(hypothetical, floor);
      child._main = clamp(child._base, child._min, child._max);
      const m = edges(cs, "margin");
      child._margin = m;
      child._marginMain = row ? m.left + m.right : m.top + m.bottom;
      used += child._main + child._marginMain;
    }
    return used;
  };

  /* 1. Resolve the node's own main size, measuring the content if it has none. */
  const statedMain = row ? width : height;
  if (statedMain === undefined) {
    const used = measureChildren(false, undefined);
    const content = used + (row ? padH : padV);
    const mode = row ? widthMode : heightMode;
    const available = row ? availableWidth : availableHeight;
    const fitted =
      mode === AT_MOST && available !== undefined && hasMeasuredLeaf(node)
        ? Math.min(content, available)
        : content;
    if (row) width = clamp(fitted, minWidth, maxWidth);
    else height = clamp(fitted, minHeight, maxHeight);
  }

  const innerMain = Math.max(0, (row ? width - padH : height - padV) || 0);

  /* 2. Flex the children into it. This runs against a definite main size in
   *    every case, because step 1 just made one. */
  // `flex: 1` is `flex-basis: 0%`, and a percentage of an *indefinite* size is
  // not zero — it is `auto`, the child's own content. So a column that is only
  // as tall as its content does not then redistribute that height among the
  // children it just measured from.
  //
  // A row is the exception, and it is the same asymmetry as everywhere else:
  // an automatic width resolves to a number before the children are laid out,
  // so it is definite by the time the basis is read. An automatic height is
  // not known until afterwards.
  const usedHypothetical = measureChildren(statedMain !== undefined || row, innerMain);
  resolveFlexibleLengths(flow, innerMain, totalGap, usedHypothetical);

  /* 3. Lay each child out at its resolved main size. `stretch` needs the line's
   *    cross size, which is the tallest item when the container has no cross
   *    size of its own — so that case takes a sizing pass and a stretching pass. */
  const layoutChild = (child, crossSize, crossMode) => {
    if (row) {
      computeLayout(child, child._main, EXACTLY, crossSize, crossMode, availInnerW, availInnerH);
    } else {
      computeLayout(child, crossSize, crossMode, child._main, EXACTLY, availInnerW, availInnerH);
    }
    // A child may come back larger than it was told to be — it cannot shrink
    // below its own padding. Positioning has to use what it actually became.
    child._main = row ? child.layout.width : child.layout.height;
  };

  const crossOf = (child) => (row ? child.layout.height : child.layout.width);
  const alignOf = (child) => (child.style || {}).alignSelf || style.alignItems || "stretch";

  for (const child of flow) {
    const cs = child.style || {};
    const m = child._margin;
    const marginCross = row ? m.top + m.bottom : m.left + m.right;
    const stated = resolve(row ? cs.height : cs.width, row ? availInnerH : availInnerW);

    if (stated !== undefined) {
      layoutChild(child, stated, EXACTLY);
    } else if (alignOf(child) === "stretch" && crossAvail !== undefined) {
      layoutChild(child, Math.max(0, crossAvail - marginCross), EXACTLY);
    } else if (row) {
      // An automatic size behaves differently per axis, and flexbox inherits
      // that: an automatic *width* is fit-content, so it is capped by the space
      // available, while an automatic *height* is the content's height and is
      // free to overflow.
      layoutChild(child, undefined, UNDEFINED);
    } else {
      layoutChild(
        child,
        crossAvail === undefined ? undefined : Math.max(0, crossAvail - marginCross),
        crossAvail === undefined ? UNDEFINED : AT_MOST,
      );
    }
  }

  let lineCross = 0;
  for (const child of flow) {
    const m = child._margin;
    lineCross = Math.max(lineCross, crossOf(child) + (row ? m.top + m.bottom : m.left + m.right));
  }

  if (crossAvail === undefined) {
    for (const child of flow) {
      const cs = child.style || {};
      if (resolve(row ? cs.height : cs.width, undefined) !== undefined) continue;
      if (alignOf(child) !== "stretch") continue;
      const m = child._margin;
      const marginCross = row ? m.top + m.bottom : m.left + m.right;
      const target = Math.max(0, lineCross - marginCross);
      if (Math.abs(crossOf(child) - target) > 0.01) layoutChild(child, target, EXACTLY);
    }
  }

  /* 4. The node's cross size, where it was not stated. */
  const statedCross = row ? height : width;
  if (statedCross === undefined) {
    const content = lineCross + (row ? padV : padH);
    const mode = row ? heightMode : widthMode;
    const available = row ? availableHeight : availableWidth;
    const fitted =
      mode === AT_MOST && available !== undefined && hasMeasuredLeaf(node)
        ? Math.min(content, available)
        : content;
    if (row) height = clamp(fitted, minHeight, maxHeight);
    else width = clamp(fitted, minWidth, maxWidth);
  }

  // Sizes are border-box, and a border box is never smaller than the padding
  // and border it contains.
  node.layout.width = Math.max(width, padH);
  node.layout.height = Math.max(height, padV);
  width = node.layout.width;
  height = node.layout.height;

  /* 5. Place the children. */
  const placeMain = Math.max(0, (row ? width - padH : height - padV) || 0);
  const placeCross = Math.max(0, (row ? height - padV : width - padH) || 0);
  let contentMain = totalGap;
  for (const child of flow) contentMain += child._main + child._marginMain;
  const freeMain = placeMain - contentMain;

  // Alignment still applies when the free space is negative: `center` and
  // `flex-end` let the content overflow away from the edge they aligned to,
  // rather than collapsing to the start. The spacing values have nothing to
  // distribute, and fall back differently: `space-between` becomes
  // `flex-start`, which is flow-relative, so in a reverse direction its
  // overflow spills backwards; `space-around` and `space-evenly` become a
  // *safe* centre, packing against the physical start so the overflow stays
  // somewhere reachable — which in a reverse direction is the end of the flow.
  const justify = style.justifyContent || "flex-start";
  const spread = Math.max(freeMain, 0);
  const safeStart = reverse && freeMain < 0 ? freeMain : 0;
  let cursor = 0;
  let between = gap;
  switch (justify) {
    case "center":
      cursor = freeMain / 2;
      break;
    case "flex-end":
      cursor = freeMain;
      break;
    case "space-between":
      if (flow.length > 1) between = gap + spread / (flow.length - 1);
      break;
    case "space-around":
      cursor = safeStart;
      if (flow.length > 0) {
        const around = spread / flow.length;
        cursor += around / 2;
        between = gap + around;
      }
      break;
    case "space-evenly":
      cursor = safeStart;
      if (flow.length > 0) {
        const evenly = spread / (flow.length + 1);
        cursor += evenly;
        between = gap + evenly;
      }
      break;
    default:
      break;
  }

  // A reverse direction is the same placement mirrored, not the children in the
  // opposite order: `flex-start` still means the start of the flow, which is now
  // the right (or bottom) edge. Margins stay physical, so the leading margin in
  // flow order is the trailing one on screen.
  for (let i = 0; i < flow.length; i++) {
    const child = flow[i];
    const m = child._margin;
    const physicalLead = row ? m.left : m.top;
    const physicalTrail = row ? m.right : m.bottom;
    const leadMain = reverse ? physicalTrail : physicalLead;
    const trailMain = reverse ? physicalLead : physicalTrail;
    const leadCross = row ? m.top : m.left;
    const trailCross = row ? m.bottom : m.right;

    const flowStart = cursor + leadMain;
    const mainStart = reverse ? placeMain - flowStart - child._main : flowStart;

    const childCross = crossOf(child);
    const align = alignOf(child);
    let crossStart = leadCross;
    if (align === "center") {
      crossStart = (placeCross - childCross - leadCross - trailCross) / 2 + leadCross;
    } else if (align === "flex-end") {
      crossStart = placeCross - childCross - trailCross;
    }

    if (row) {
      child.layout.left = pad.left + mainStart;
      child.layout.top = pad.top + crossStart;
    } else {
      child.layout.left = pad.left + crossStart;
      child.layout.top = pad.top + mainStart;
    }

    cursor = flowStart + child._main + trailMain;
    if (i < flow.length - 1) cursor += between;
  }

  /* 6. Absolutely positioned children.
   *
   * Their containing block is the *padding box* — inset by the border, not by
   * the padding. `left: 0` on an absolute child of a padded box sits against
   * the padding, not inside it. */
  const b = border(style);
  for (const child of children.filter(isAbsolute)) {
    layoutAbsolute(child, { left: b, right: b, top: b, bottom: b }, width, height);
  }
}

function layoutAbsolute(child, pad, parentWidth, parentHeight) {
  const cs = child.style || {};
  const boxW = parentWidth - pad.left - pad.right;
  const boxH = parentHeight - pad.top - pad.bottom;

  const left = resolve(cs.left, boxW);
  const right = resolve(cs.right, boxW);
  const top = resolve(cs.top, boxH);
  const bottom = resolve(cs.bottom, boxH);

  let width = resolve(cs.width, boxW);
  let height = resolve(cs.height, boxH);
  if (width === undefined && left !== undefined && right !== undefined) {
    width = Math.max(0, boxW - left - right);
  }
  if (height === undefined && top !== undefined && bottom !== undefined) {
    height = Math.max(0, boxH - top - bottom);
  }

  computeLayout(
    child,
    width,
    width === undefined ? AT_MOST : EXACTLY,
    height,
    height === undefined ? AT_MOST : EXACTLY,
    boxW,
    boxH,
  );

  const resolvedW = child.layout.width;
  const resolvedH = child.layout.height;
  child.layout.left =
    pad.left + (left !== undefined ? left : right !== undefined ? boxW - right - resolvedW : 0);
  child.layout.top =
    pad.top + (top !== undefined ? top : bottom !== undefined ? boxH - bottom - resolvedH : 0);
}
