/**
 * Which nodes need a view of their own.
 *
 * A screen with 400 nodes and 150 real drawing surfaces scrolls very
 * differently from one with 400. Most of the difference is boxes that exist
 * only to arrange their children: a column with a gap, a row with padding, a
 * wrapper that carries `flex: 1` and nothing else. They have to be in the
 * layout tree, because they *do* arrange things. They do not have to be on
 * screen, because they draw nothing.
 *
 * So a host keeps two trees — the layout nodes and the views — and a
 * layout-only node stays in the first and vanishes from the second. Its
 * children attach to the nearest ancestor that does have a view, offset by
 * where it ended up. React Native does exactly this, and calls it view
 * flattening.
 *
 * **This is a host concern, not a protocol one.** The command stream is
 * unchanged; the app never learns that a box it wrote did not become a view.
 * It is also only available to a host whose layout tree and view tree are
 * separate objects, which rules out the DOM preview host — CSS has no way to
 * express a box with no element. `reference.mjs` and the UIKit host both
 * qualify.
 *
 * The policy lives here, alone and pure, for the same reason the layout engine
 * lives in one file: it has to be transliterated, and two hosts that disagree
 * about which nodes are flattened have two different screens.
 * `native/conformance/` pins it across languages.
 */

/**
 * The only type that is ever flattened.
 *
 * Stated as an allow-list rather than a deny-list, deliberately. Everything
 * else either paints something itself (`text`, `image`), owns platform
 * behaviour (`input`, `scroll`), receives touches as its whole reason to exist
 * (`pressable`), is the mount point (`root`), or is a primitive this host has
 * never heard of — and guessing that someone else's primitive draws nothing is
 * not a guess worth making. A deny-list would have to be right about every tag
 * that has not been invented yet.
 */
const FLATTENABLE = new Set(["view"]);

/**
 * Props that need something on screen to hang off, even when nothing is
 * painted: an accessibility element is a view, and so is a hit-test target.
 */
const RENDERING_PROPS = ["testID", "accessibilityLabel", "accessible", "pointerEvents"];

/**
 * Events that need a view to be delivered from.
 *
 * `layout` is the exception that matters: it reports a node's frame, and a
 * frame comes from the layout tree, which a flattened node is still in. A list
 * that measures its own viewport therefore costs no view — which is the case
 * `NativeList` hits on every screen that has one.
 */
const RENDERING_EVENTS = new Set([
  "press",
  "longPress",
  "pressIn",
  "pressOut",
  "focus",
  "blur",
  "changeText",
  "scroll",
]);

/** Does anything in this style paint? */
function stylePaints(style) {
  if (style === undefined || style === null) return false;
  if (style.backgroundColor !== undefined && style.backgroundColor !== null) return true;
  if (typeof style.borderWidth === "number" && style.borderWidth > 0) return true;
  if (typeof style.borderRadius === "number" && style.borderRadius > 0) return true;
  // Only a *reduced* opacity is a reason to exist. `opacity: 1` is the default
  // written down.
  if (typeof style.opacity === "number" && style.opacity < 1) return true;
  // Clipping is drawing: it decides what the children look like.
  if (style.overflow === "hidden" || style.overflow === "scroll") return true;
  return false;
}

/**
 * @param {{type: string, style?: object, props?: object, events?: Iterable<string>}} node
 * @returns {boolean} whether this node needs a view of its own
 */
export function needsView(node) {
  if (!FLATTENABLE.has(node.type)) return true;
  if (stylePaints(node.style)) return true;

  const props = node.props;
  if (props !== undefined && props !== null) {
    for (const key of RENDERING_PROPS) {
      if (props[key] !== undefined && props[key] !== null) return true;
    }
  }

  if (node.events !== undefined && node.events !== null) {
    for (const event of node.events) {
      if (RENDERING_EVENTS.has(event)) return true;
    }
  }

  return false;
}

/** The inverse, for reading at call sites where that is the natural phrasing. */
export const isLayoutOnly = (node) => !needsView(node);

export const RENDERING = Object.freeze({
  FLATTENABLE,
  RENDERING_PROPS,
  RENDERING_EVENTS,
});
