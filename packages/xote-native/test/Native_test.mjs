/**
 * End-to-end: a ReScript app, Xote's renderer, the shadow document, and a host.
 *
 * The assertions are mostly about *how much* crosses the bridge, because that
 * is the claim this prototype is making — not that a tree can be built, but
 * that a signal change costs the mutations it implies and nothing else.
 */

import assert from "node:assert/strict";
import { install } from "../src/host/runtime.mjs";
import { HeadlessHost } from "../src/host/headless.mjs";
import { OP, OP_NAME } from "../src/host/protocol.mjs";

const host = new HeadlessHost();
// Manual flushing keeps every assertion about one interaction, rather than
// whatever the microtask queue happened to coalesce.
const runtime = install(host, { autoFlush: false });

const NativeApp = await import("../src/NativeApp.res.mjs");
const CounterApp = await import("../example/CounterApp.res.mjs");

NativeApp.mount(CounterApp.make(), "root");
runtime.flush();

const view = (id) => host.views.get(id);

const textOf = (node) =>
  node.type === "#text" ? node.text : node.children.map((child) => textOf(view(child.id))).join("");

const findAll = (predicate, id = 1, out = []) => {
  const node = view(id);
  if (node === undefined) return out;
  if (predicate(node)) out.push(node);
  for (const child of node.children) findAll(predicate, child.id, out);
  return out;
};

const find = (predicate) => {
  const [first] = findAll(predicate);
  assert.ok(first, "no view matched");
  return first;
};

const opsSince = () => host.log.map((command) => OP_NAME[command[0]]);

/* ---- the tree the host actually built ----------------------------------- */

const root = view(1);
assert.equal(root.type, "root");
assert.equal(root.children.length, 1, "the app mounts as a single view");
assert.equal(root.children[0].type, "view");

// Nothing web-shaped reaches the host. Xote wraps every reactive region in a
// `<div style="display: contents">` and brackets keyed lists with comment
// anchors; the projection flattens the first and never emits the second, so
// the native view tree has no nodes that exist only to group.
assert.equal(
  findAll((v) => v.type === "div" || v.type === "#comment").length,
  0,
  "no DOM grouping nodes are projected",
);

const heading = find((v) => v.type === "text" && textOf(v) === "Xote Native");
assert.equal(heading.props.style.fontWeight, "bold", "styles cross the bridge as objects");
assert.equal(heading.props.style.fontSize, 28);
assert.equal(view(1).children[0].props.style.paddingHorizontal, 20, "`pt` is a plain number");

const tapButton = find((v) => v.type === "pressable" && textOf(v) === "Tap me");
assert.ok(tapButton.events.has("press"), "the host was told to report presses");

const counterLabel = find((v) => v.type === "text" && textOf(v).startsWith("Tapped"));
assert.equal(textOf(counterLabel), "Tapped 0x");
assert.equal(textOf(find((v) => v.type === "text" && textOf(v).endsWith("left"))), "2 left");
assert.equal(findAll((v) => v.type === "pressable").length, 5, "three rows plus two buttons");

/* ---- one press costs one command ---------------------------------------- */

host.clearLog();
runtime.dispatchEvent(tapButton.id, "press", { pageX: 10, pageY: 20 });
runtime.flush();

assert.deepEqual(host.formattedLog(), [`setText(${counterLabel.children[0].id}, "Tapped 1x")`]);

/* ---- a branch change costs the branch ----------------------------------- */

host.clearLog();
runtime.dispatchEvent(tapButton.id, "press", {});
assert.deepEqual(opsSince(), ["setText"], "the second tap does not touch the hint");

runtime.dispatchEvent(tapButton.id, "press", {});
runtime.flush();

// The third tap flips the `showHint` computed, so the tracked block swaps its
// contents: the empty placeholder out, the hint in. Everything else is untouched.
assert.deepEqual(
  opsSince().slice(1),
  [
    "setText", // the counter label
    "remove", // the empty placeholder leaves the screen
    "create", // <text>
    "setProp", // its style
    "createText", // the string inside it
    "insert", // the string into the <text>
    "insert", // the <text> into the screen, at the placeholder's index
    "destroy", // the placeholder is not coming back
  ],
  "the branch swap is eight commands and touches nothing else",
);
assert.ok(
  findAll((v) => v.type === "text" && textOf(v) === "You really like that button.").length === 1,
  "the hint is on screen",
);

/* ---- toggling one row touches one row ------------------------------------ */

const secondRow = find((v) => v.type === "pressable" && textOf(v).startsWith("Embed Yoga"));
host.clearLog();
runtime.dispatchEvent(secondRow.id, "press", {});
runtime.flush();

assert.deepEqual(
  host.formattedLog(),
  [
    `setProp(${secondRow.children[0].id}, "style", ${JSON.stringify({
      width: 18,
      height: 18,
      backgroundColor: "#7c5cff",
      borderRadius: 9,
      borderWidth: 2,
      borderColor: "#7c5cff",
    })})`,
    `setProp(${secondRow.children[1].id}, "style", ${JSON.stringify({
      color: "#8b8b9c",
      fontSize: 16,
    })})`,
    `setText(${find((v) => v.type === "text" && textOf(v).endsWith("left")).children[0].id}, "1 left")`,
  ],
  "a toggle is three commands: the checkbox, the label, the remaining count",
);
assert.equal(textOf(find((v) => v.type === "text" && textOf(v).endsWith("left"))), "1 left");

/* ---- adding a row adds a row --------------------------------------------- */

const addButton = find((v) => v.type === "pressable" && textOf(v) === "Add task");
const before = findAll((v) => v.type === "pressable").length;
host.clearLog();
runtime.dispatchEvent(addButton.id, "press", {});
runtime.flush();

assert.equal(findAll((v) => v.type === "pressable").length, before + 1, "one row was added");
assert.equal(
  host.log.filter((command) => command[0] === OP.CREATE && command[2] === "pressable").length,
  1,
  "only the new row was created",
);
assert.equal(
  host.log.filter((command) => command[0] === OP.DESTROY).length,
  0,
  "the keyed reconciler kept every existing row",
);
assert.equal(textOf(find((v) => v.type === "text" && textOf(v) === "Task 4")), "Task 4");

/* ---- nothing is left behind ---------------------------------------------- */

// Every view the host still holds is reachable from the root. A projection that
// leaked — a node detached without a DESTROY — would show up here as a view the
// walk never visits.
const reachable = new Set(findAll(() => true).map((v) => v.id));
assert.deepEqual(
  [...host.views.keys()].filter((id) => !reachable.has(id)),
  [],
  "no view outlives the tree that referenced it",
);

/* ---- the function-based surface builds the same thing --------------------- */

const NativeStyle = await import("../src/NativeStyle.res.mjs");
assert.deepEqual(
  NativeStyle.merge([{padding: 8, color: "#111"}, {color: "#fff"}]),
  {padding: 8, color: "#fff"},
  "later styles win, field by field",
);

const PanelApp = await import("../example/PanelApp.res.mjs");
NativeApp.mount(PanelApp.make(), "panel");
runtime.flush();

const panel = [...host.views.values()].find((v) => v.type === "root" && v.id !== 1);
const panelRoot = view(panel.children[0].id);
assert.equal(panelRoot.type, "view");
assert.deepEqual(panelRoot.props.style, {flex: 1, gap: 8});

const panelButton = view(panelRoot.children[1].id);
assert.deepEqual(panelButton.props.style, {
  paddingVertical: 10,
  borderRadius: 10,
  backgroundColor: "#7c5cff",
});

host.clearLog();
runtime.dispatchEvent(panelButton.id, "press", {});
runtime.flush();
assert.equal(textOf(view(panelRoot.children[0].id)), "pressed 1x");
assert.deepEqual(opsSince(), ["setText"], "a press through the function API costs one command too");

console.log("Xote Native tests passed");
