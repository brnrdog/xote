/**
 * Navigation: a stack of screens the platform owns.
 *
 * Two node types. A `stack` is a box that holds `screen` children and nothing
 * else; a `screen` is one entry in it. Push and pop are not new opcodes — they
 * are `INSERT` and `REMOVE` of a `screen` in a `stack`, which the host reads as
 * "push this" and "pop that". The protocol did not have to grow, because a
 * stack of screens is a list of children and the protocol already says how a
 * list of children changes.
 *
 * ## The one place the host writes first
 *
 * Everywhere else in this system the app is the only writer of the tree: a
 * signal changes, the renderer mutates, the host applies. Navigation is the
 * exception, and it is not an oversight in the design — it is what native
 * navigation *is*. When someone swipes back from the left edge, UIKit has
 * already popped the screen by the time anything else could have an opinion,
 * and a framework that insists on being asked first either fights the gesture
 * or drops it.
 *
 * So the host may pop, and then it says so:
 *
 *   1. the platform pops, and the host takes that screen out of its view stack
 *      — but *not* out of the node tree, and it never destroys the node;
 *   2. the host raises `stackChange` on the stack, carrying the new depth;
 *   3. the app truncates its own stack, which emits the `REMOVE` and `DESTROY`
 *      that were always going to come;
 *   4. the host sees a `REMOVE` for a screen it has already popped, and does
 *      nothing — the state the app is asking for is the state it is in.
 *
 * Step 4 is why the host must never destroy a node it popped. Ids belong to the
 * app; a host that freed one would be guessing about a lifetime it does not
 * own, and the pool would hand the view out again while the app still had the
 * id.
 *
 * ## No listener, no platform pop
 *
 * A host enables platform-initiated popping — the back gesture, the back button
 * — only when the app has registered `stackChange` on the stack. It is a small
 * rule and it buys the property that makes the rest safe to reason about: an
 * app that has not opted in is still one where nothing but the app moves the
 * tree, so there is no divergence to reconcile and no way to be surprised by
 * one.
 *
 * This file is the policy, alone, for the same reason `flatten.mjs` is: it has
 * to be transliterated into Swift and Kotlin, and two hosts that disagree about
 * where a screen sits or which screens are on the stack have two different
 * apps. `conformance/` pins it across languages.
 */

/** The container, and the entries in it. Neither is ever flattened away. */
export const STACK = "stack";
export const SCREEN = "screen";

/**
 * A screen fills its stack, and the app does not get a say.
 *
 * Being absolutely positioned is what puts every screen in the same place
 * rather than in a column, and it costs no new layout code: an absolute child
 * pinned on all four edges resolves to its containing block, which for a stack
 * with no padding is the whole box. Screens under the top one are laid out too,
 * because a push animates two screens at once and the one sliding away needs a
 * frame to slide from.
 *
 * The app's own style is kept for everything that is not geometry — a
 * background colour, padding for the content inside — and the six keys that
 * would move a screen somewhere other than over its stack are replaced rather
 * than merged. A screen that could be positioned would be a screen that could
 * be positioned wrong, and there is no reading of "this screen is 40 points
 * from the left of the navigation controller" that an app means on purpose.
 */
export function screenStyle(style) {
  return {
    ...style,
    position: "absolute",
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
    width: undefined,
    height: undefined,
  };
}

/** The event a host raises when the platform, not the app, changed the stack. */
export const STACK_CHANGE = "stackChange";

/**
 * The screens a stack is showing, in order, bottom to top.
 *
 * The node's `screen` children minus the ones the platform has already popped —
 * which is the whole of the divergence between the two trees, and it lasts from
 * the gesture until the app's `REMOVE` arrives. Anything asking "what is on
 * screen" asks this, not the node's children: the view tree, the index a new
 * screen is inserted at, and the depth `stackChange` reports.
 *
 * @param {{children: Array<{id: number, type: string}>}} stack
 * @param {Set<number>} popped ids the platform has taken off this stack
 */
export function stackScreens(stack, popped) {
  return stack.children.filter((child) => child.type === SCREEN && !popped.has(child.id));
}

/**
 * May the platform pop this stack on its own?
 *
 * Two conditions, and both are load-bearing. The app has to have asked to hear
 * about it, per the rule above. And there has to be something to go back to:
 * popping the last screen would leave a navigation controller with no root,
 * which UIKit treats as a programming error and which no app means.
 */
export function canPopFromPlatform(stack, popped, listeners) {
  if (listeners === undefined || !listeners.has(STACK_CHANGE)) return false;
  return stackScreens(stack, popped).length > 1;
}
