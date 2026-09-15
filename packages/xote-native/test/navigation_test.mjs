/**
 * Navigation: a stack of screens, and the one case where the host moves first.
 *
 * The interesting assertions are not "a push shows a screen" — they are about
 * the window between a back gesture and the app finding out about it. During
 * that window the node tree and the view tree genuinely disagree, on purpose,
 * and everything here is about that disagreement being bounded: the right
 * screens on the stack, the right frames, the right indices for anything pushed
 * next, and nothing leaked when the app finally catches up.
 *
 * See `src/host/navigation.mjs` for the design these assert.
 */

import assert from "node:assert/strict";
import { ReferenceHost } from "../src/host/reference.mjs";
import { OP } from "../src/host/protocol.mjs";
import { STACK_CHANGE } from "../src/host/navigation.mjs";

const VIEWPORT = { width: 320, height: 640 };

/* Ids are assigned by the app, so the tests assign them the same way: 1 is the
 root, 2 is the stack, and screens count up from there. */
const ROOT = 1;
const STACK = 2;

/** A host with a root and an empty stack filling it, ready to be pushed to. */
function mounted({ listening = true } = {}) {
  const host = new ReferenceHost(VIEWPORT);
  const batch = [
    [OP.CREATE, ROOT, "root"],
    [OP.CREATE, STACK, "stack"],
    [OP.SET_PROP, STACK, "style", { flex: 1 }],
    [OP.INSERT, ROOT, STACK, 0],
  ];
  if (listening) batch.push([OP.LISTEN, STACK, STACK_CHANGE]);
  host.apply(batch);
  return host;
}

/** Push a screen carrying one text node, so it has something to measure. */
function push(host, id, label, index) {
  host.apply([
    [OP.CREATE, id, "screen"],
    [OP.SET_PROP, id, "style", { backgroundColor: "#ffffff" }],
    [OP.CREATE, id + 100, "text"],
    [OP.CREATE_TEXT, id + 200, label],
    [OP.INSERT, id + 100, id + 200, 0],
    [OP.INSERT, id, id + 100, 0],
    [OP.INSERT, STACK, id, index],
  ]);
}

/** What the app does when it hears `stackChange`: truncate, remove, destroy. */
function truncate(host, screens, depth) {
  const dropped = screens.slice(depth);
  const batch = [];
  for (const id of dropped) {
    batch.push([OP.REMOVE, STACK, id]);
    batch.push([OP.DESTROY, id + 200]);
    batch.push([OP.DESTROY, id + 100]);
    batch.push([OP.DESTROY, id]);
  }
  host.apply(batch);
  return screens.slice(0, depth);
}

const ids = (host) => host.screensOf(STACK).map((screen) => screen.id);

/* ---- pushing and popping, app-driven -------------------------------------- */

{
  const host = mounted();
  push(host, 3, "one", 0);
  assert.deepEqual(ids(host), [3], "the first screen is the root of the stack");
  assert.deepEqual(
    host.frames()[3],
    [0, 0, 320, 640],
    "and it fills the stack rather than flowing inside it",
  );

  push(host, 4, "two", 1);
  assert.deepEqual(ids(host), [3, 4], "a push appends");
  assert.deepEqual(
    host.frames()[4],
    [0, 0, 320, 640],
    "the pushed screen fills the stack too — both are laid out, so a transition has two frames to animate between",
  );
  assert.deepEqual(
    host.nativeTree()[STACK],
    [3, 4],
    "and the view tree holds both, bottom to top, the way `viewControllers` does",
  );

  truncate(host, [3, 4], 1);
  assert.deepEqual(ids(host), [3], "an app-driven pop removes the top screen");
  assert.deepEqual(host.nativeTree()[STACK], [3], "and takes its view with it");
  assert.equal(host.nodes.has(4), false, "the destroyed screen is gone from the node tree");
}

/* ---- a screen's own style, and the parts of it that do not survive --------- */

{
  const host = mounted();
  host.apply([
    [OP.CREATE, 3, "screen"],
    // Padding is the app's business; position and insets are not. A screen that
    // could be positioned would be a screen that could be positioned wrong.
    [OP.SET_PROP, 3, "style", { padding: 20, position: "relative", left: 40, width: 100 }],
    [OP.CREATE, 103, "view"],
    [OP.SET_PROP, 103, "style", { flex: 1, backgroundColor: "#ff0000" }],
    [OP.INSERT, 3, 103, 0],
    [OP.INSERT, STACK, 3, 0],
  ]);
  assert.deepEqual(host.frames()[3], [0, 0, 320, 640], "the screen still fills its stack");
  assert.deepEqual(
    host.frames()[103],
    [20, 20, 280, 600],
    "and its padding still applies to what is inside it",
  );
}

/* ---- the platform pops first ---------------------------------------------- */

{
  const host = mounted();
  push(host, 3, "one", 0);
  push(host, 4, "two", 1);

  const event = host.platformPop(STACK);
  assert.deepEqual(
    event,
    { id: STACK, name: STACK_CHANGE, payload: { depth: 1 } },
    "the host reports the depth it is now at, on the stack node",
  );

  // The window. The node tree still has the screen the app has not heard about
  // yet; the view tree does not.
  assert.deepEqual(ids(host), [3], "the stack is showing one screen");
  assert.deepEqual(host.nativeTree()[STACK], [3], "and holds one view");
  assert.equal(host.nodes.has(4), true, "but the node is untouched — the host never destroys one");
  assert.equal(host.node(4).view != null, true, "and so is its view, which the app still owns");
  assert.equal(
    host.nativeTree()[4],
    undefined,
    "the popped screen's subtree is out of the stack, not reparented into it",
  );

  // The app catches up. This is the same batch it would have sent for a pop it
  // initiated itself, which is the property that makes the design work.
  truncate(host, [3, 4], 1);
  assert.deepEqual(ids(host), [3], "the stack is where it already was");
  assert.deepEqual(host.nativeTree()[STACK], [3], "with no view left over");
  assert.equal(host.popped.size, 0, "and no bookkeeping left behind");
  assert.equal(host.nodes.has(4), false, "the app destroyed the node, as it always does");
}

/* ---- pushing during the window -------------------------------------------- */

{
  // The awkward one: a back gesture completes, and the app pushes a new screen
  // before it has processed `stackChange`. The new screen has to land on top of
  // the screen that is actually showing, not on top of the one that was popped.
  const host = mounted();
  push(host, 3, "one", 0);
  push(host, 4, "two", 1);
  host.platformPop(STACK);

  push(host, 5, "three", 2);
  assert.deepEqual(ids(host), [3, 5], "the new screen sits on the one still showing");
  assert.deepEqual(
    host.nativeTree()[STACK],
    [3, 5],
    "and takes the popped screen's place in the view tree rather than a slot after it",
  );

  truncate(host, [3, 4, 5], 3);
  assert.deepEqual(ids(host), [3, 5], "removing nothing changes nothing");
  host.apply([[OP.REMOVE, STACK, 4], [OP.DESTROY, 4]]);
  assert.deepEqual(ids(host), [3, 5], "and the late catch-up for screen 4 is a no-op");
  assert.deepEqual(host.nativeTree()[STACK], [3, 5], "with the view tree undisturbed");
}

/* ---- the app overrules the platform --------------------------------------- */

{
  // Re-inserting a screen the platform popped puts it back. This is the rule
  // that keeps the app the authority on the tree even here: without it, a node
  // could sit in the stack's children and not on the stack, with nothing to say
  // which of the two was meant.
  const host = mounted();
  push(host, 3, "one", 0);
  push(host, 4, "two", 1);
  host.platformPop(STACK);
  assert.deepEqual(ids(host), [3], "the platform popped it");

  host.apply([[OP.INSERT, STACK, 4, 1]]);
  assert.deepEqual(ids(host), [3, 4], "and the app put it back");
  assert.deepEqual(host.nativeTree()[STACK], [3, 4], "view tree included");
  assert.equal(host.popped.size, 0, "with nothing still marked popped");
  assert.deepEqual(host.frames()[4], [0, 0, 320, 640], "and it fills the stack again");
}

/* ---- what the platform is not allowed to do ------------------------------- */

{
  const host = mounted();
  push(host, 3, "one", 0);
  assert.equal(
    host.platformPop(STACK),
    null,
    "the platform cannot pop the last screen out from under the app",
  );
}

{
  // No listener, no platform pop — so an app that has not opted in is still one
  // where nothing but the app moves the tree.
  const host = mounted({ listening: false });
  push(host, 3, "one", 0);
  push(host, 4, "two", 1);
  assert.equal(host.platformPop(STACK), null, "the gesture is not enabled without a listener");
  assert.deepEqual(ids(host), [3, 4], "and the stack is untouched");
}

/* ---- a deep reset --------------------------------------------------------- */

{
  // Not every stack change is a push or a pop. A deep link replaces the whole
  // stack at once, and the host has to end up showing the last screen of the
  // new one rather than animating its way there.
  const host = mounted();
  push(host, 3, "one", 0);
  push(host, 4, "two", 1);
  push(host, 5, "three", 2);
  assert.deepEqual(ids(host), [3, 4, 5]);

  host.apply([
    [OP.REMOVE, STACK, 4],
    [OP.REMOVE, STACK, 5],
    [OP.DESTROY, 204],
    [OP.DESTROY, 104],
    [OP.DESTROY, 4],
    [OP.DESTROY, 205],
    [OP.DESTROY, 105],
    [OP.DESTROY, 5],
  ]);
  push(host, 6, "deep", 1);
  assert.deepEqual(ids(host), [3, 6], "the stack is whatever the app last said it was");
  assert.deepEqual(host.nativeTree()[STACK], [3, 6]);
}

/* ---- the pool ------------------------------------------------------------- */

{
  // A screen is a view like any other, so pushing and popping the same screen
  // repeatedly must stop allocating rather than churn.
  const host = mounted();
  push(host, 3, "one", 0);
  for (let i = 0; i < 8; i++) {
    push(host, 4, "two", 1);
    truncate(host, [3, 4], 1);
  }
  const stats = host.stats();
  assert.ok(
    stats.reused >= 8,
    `pushing the same screen eight times reuses views (${stats.reused} reused, ${stats.created} created)`,
  );
}

/* ---- the ReScript surface, through the real renderer ----------------------
 *
 * Everything above drives the host with hand-written commands. This drives it
 * with an app: `NativeNav` and `example/NavApp.res` through Xote's renderer and
 * the shadow document, which is the only way to find out whether the keying
 * does what it is there for.
 */

const { install } = await import("../src/host/runtime.mjs");
const NativeApp = await import("../src/NativeApp.res.mjs");
const NativeNav = await import("../src/NativeNav.res.mjs");
const NavApp = await import("../example/NavApp.res.mjs");
const Signal = await import("xote/src/Signal.res.mjs");

{
  const host = new ReferenceHost(VIEWPORT);
  const runtime = install(host, { autoFlush: false });
  NativeApp.mount(NavApp.make(), "root");
  runtime.flush();

  const stackNode = [...host.nodes.values()].find((node) => node.type === "stack");
  assert.ok(stackNode, "the app rendered a stack");
  assert.equal(
    host.screensOf(stackNode.id).length,
    1,
    "one screen, and no grouping node from the keyed list reached the host",
  );
  assert.deepEqual(
    Object.keys(host.structure()[stackNode.id] ?? []).length,
    1,
    "the stack's children are screens and nothing else — the keyed list's comment anchors are never projected",
  );

  /** The `pressable` whose label contains `label`, anywhere in the tree. */
  const button = (label) => {
    const texts = host.texts();
    return [...host.nodes.values()].find(
      (node) =>
        node.type === "pressable" &&
        node.children.some((child) => (texts[child.id] ?? "").includes(label)),
    );
  };

  const tapCounts = () =>
    Object.values(host.texts()).filter((text) => text.startsWith("tapped "));

  // Tap the counter on the first screen, so there is state worth preserving.
  const tap = button("tapped");
  assert.ok(tap, "the counter button is on screen");
  runtime.dispatchEvent(tap.id, "press", {});
  runtime.flush();
  assert.deepEqual(tapCounts(), ["tapped 1×"], "the first screen counted a tap");

  // Push. The screen underneath must not be rebuilt — if it were, its counter
  // would be back at zero, which is exactly the bug keying exists to prevent.
  NativeNav.push(NavApp.nav, { title: "Two", level: 2 });
  runtime.flush();
  assert.equal(host.screensOf(stackNode.id).length, 2, "two screens on the stack");
  assert.deepEqual(
    tapCounts().sort(),
    ["tapped 0×", "tapped 1×"],
    "the pushed screen starts at zero and the one underneath kept its count",
  );

  const frames = host.frames();
  const [below, above] = host.screensOf(stackNode.id);
  assert.deepEqual(frames[below.id], [0, 0, 320, 640], "both screens fill the stack");
  assert.deepEqual(frames[above.id], [0, 0, 320, 640], "so a transition has two frames to work with");

  // The back gesture. The host pops, the app hears about it, and the state on
  // the screen that was underneath is still there.
  const event = host.platformPop(stackNode.id);
  assert.ok(event, "the app registered `stackChange`, so the gesture is enabled");
  runtime.dispatchEvent(event.id, event.name, event.payload);
  runtime.flush();

  assert.equal(host.screensOf(stackNode.id).length, 1, "back to one screen");
  assert.equal(host.popped.size, 0, "the app caught up, so nothing is half-popped");
  assert.deepEqual(tapCounts(), ["tapped 1×"], "and the screen it went back to is the same one");
  assert.equal(Signal.peek(NavApp.nav.depth), 1, "the app's own idea of the depth agrees");
  assert.equal(Signal.peek(NavApp.nav.canGoBack), false, "and there is nothing to go back to");
}

console.log(
  "navigation tests passed — push, pop, a platform pop the app has not heard about," +
    " and a screen that keeps its state underneath one",
);
