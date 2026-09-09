/**
 * View flattening and view recycling, against a real screen.
 *
 * Both are optimizations, and an optimization that changes what is on screen is
 * a bug. So the shape of this file is: drive the tracker, record every batch,
 * then replay the same command stream into two hosts — one flattening and
 * recycling, one doing neither — and assert that **every frame, every node and
 * every string comes out identical**. Whatever else flattening does, it may not
 * move anything.
 *
 * Replaying rather than mounting twice is deliberate. The command stream is
 * host-agnostic by construction, which is the whole premise of the protocol;
 * running one app into two hosts tests that premise as a side effect.
 */

import assert from "node:assert/strict";
import { install } from "../host/runtime.mjs";
import { ReferenceHost, stubMeasure } from "../host/reference.mjs";
import { OP } from "../host/protocol.mjs";

const VIEWPORT = { width: 390, height: 720 };
const ROW_HEIGHT = 84;

/* ---- drive the app, recording everything that crossed --------------------- */

const batches = [];
const live = new ReferenceHost(VIEWPORT, stubMeasure);
const runtime = install(
  {
    apply(batch) {
      batches.push(batch.map((command) => command.slice()));
      live.apply(batch);
    },
  },
  { autoFlush: false },
);

const NativeApp = await import("../NativeApp.res.mjs");
const TrackerApp = await import("../example/tracker/TrackerApp.res.mjs");

NativeApp.mount(TrackerApp.make(), "root");
runtime.flush();

const find = (predicate) => [...live.nodes.values()].filter(predicate);
const scroll = () => find((node) => node.type === "scroll")[0];
assert.ok(scroll() !== undefined, "the screen has a list");

// The list starts at zero height and fills in once the host reports a frame —
// the same round trip it makes on a device.
runtime.dispatchEvent(scroll().id, "layout", {
  x: 0,
  y: 0,
  width: VIEWPORT.width,
  height: VIEWPORT.height,
});
runtime.flush();

// Everything up to here builds a full list screen. It is the state worth
// counting views in — after the sweep below the app is somewhere else.
const FULL_AT = batches.length;

// A sweep down the list and back, so rows are created and destroyed in bulk.
for (let row = 0; row < 40; row += 1) {
  runtime.dispatchEvent(scroll().id, "scroll", { x: 0, y: row * ROW_HEIGHT });
  runtime.flush();
}

const press = (node) => {
  runtime.dispatchEvent(node.id, "press", {});
  runtime.flush();
};
const textOf = (node) =>
  node.type === "#text" ? (node.text ?? "") : node.children.map(textOf).join("");

// A filter toggle, so a style that already had a background changes to another
// one; and a navigation, so a whole screen is torn down and a new one built.
const chip = find(
  (node) => node.type === "pressable" && textOf(node) === "Done" && node.style?.borderRadius === 999,
)[0];
assert.ok(chip !== undefined, "the filter chips are on screen");
press(chip);
press(chip);

const row = find((node) => node.type === "pressable" && node.style?.height === ROW_HEIGHT)[0];
assert.ok(row !== undefined, "there are rows to open");
press(row);
const back = find((node) => node.type === "pressable" && textOf(node) === "← Issues")[0];
assert.ok(back !== undefined, "the detail screen opened");
press(back);

const commands = batches.reduce((total, batch) => total + batch.length, 0);
assert.ok(batches.length > 40, `only ${batches.length} batches were recorded`);

/* ---- replay into two hosts and compare ------------------------------------ */

const replay = (options, count = batches.length) => {
  const host = new ReferenceHost(VIEWPORT, stubMeasure, options);
  for (const batch of batches.slice(0, count)) host.apply(batch);
  return host;
};

const flattened = replay({ flatten: true, recycle: true });
const plain = replay({ flatten: false, recycle: false });

// The same comparison at the point the list screen is full, which is where the
// view counts mean something.
const full = {
  flattened: replay({ flatten: true, recycle: true }, FULL_AT),
  plain: replay({ flatten: false, recycle: false }, FULL_AT),
};
const fullSaved = full.plain.viewCount() - full.flattened.viewCount();
assert.deepEqual(full.flattened.frames(), full.plain.frames(), "flattening moved something");
assert.deepEqual(full.flattened.texts(), full.plain.texts(), "flattening changed the text");

assert.deepEqual(flattened.frames(), plain.frames(), "flattening moved something");
assert.deepEqual(flattened.structure(), plain.structure(), "flattening changed the node tree");
assert.deepEqual(flattened.texts(), plain.texts(), "flattening changed the text");

// And against the host the app actually ran through, which took the same stream
// interleaved with real events rather than all at once.
assert.deepEqual(flattened.frames(), live.frames(), "replay diverged from the live host");

/* ---- the view tree is what changed ---------------------------------------- */

/**
 * The native tree derived from scratch, to check the incrementally maintained
 * one. A host cannot rebuild its view tree at the end of every batch — that
 * would cost more than flattening saves — so it splices, and a splice is a
 * thing to get wrong. This is the assertion that catches it.
 */
const derive = (host) => {
  const out = {};
  const walk = (node, container) => {
    let inner = container;
    if (node.view != null) {
      (out[container] ??= []).push(node.id);
      out[node.id] ??= [];
      inner = node.id;
    }
    for (const child of node.children) walk(child, inner);
  };
  out[host.root.id] = [];
  for (const child of host.root.children) walk(child, host.root.id);
  return out;
};

assert.deepEqual(flattened.nativeTree(), derive(flattened), "the flattened view tree drifted");
assert.deepEqual(plain.nativeTree(), derive(plain), "the unflattened view tree drifted");

// The unflattened host is the definition of "one view per node", runs inside a
// label excepted — they are pieces of a string, not boxes, on every host.
const runsInsideLabels = [...plain.nodes.values()].filter(
  (node) => node.type === "#text" && plain.nodes.get(node.parent)?.type === "text",
).length;
assert.equal(
  plain.viewCount() + runsInsideLabels,
  plain.nodes.size,
  "unflattened, every node that is not a run is a view",
);

assert.ok(fullSaved > 0, "flattening saved no views at all");
assert.ok(
  full.flattened.viewCount() < full.plain.viewCount() * 0.85,
  `flattening saved only ${fullSaved} of ${full.plain.viewCount()} views`,
);
assert.deepEqual(
  full.flattened.nativeTree(),
  derive(full.flattened),
  "the full screen's view tree drifted",
);

/* ---- flattening is not unconditional -------------------------------------- */

// A box that paints, or that can be touched, keeps its view. If this ever
// stops being true the screen is wrong in a way frames cannot show.
const painted = [...flattened.nodes.values()].filter(
  (node) => node.type === "view" && node.style?.backgroundColor !== undefined,
);
assert.ok(painted.length > 0, "the screen has painted boxes to check");
for (const node of painted) {
  assert.ok(node.view != null, `a box with a background was flattened (node ${node.id})`);
}
for (const node of flattened.nodes.values()) {
  if (node.type === "pressable" || node.type === "text" || node.type === "scroll") {
    assert.ok(node.view != null, `a ${node.type} was flattened (node ${node.id})`);
  }
}

/* ---- recycling ------------------------------------------------------------ */

// Scrolling a windowed list is the churn this exists for: rows leave the window
// and are destroyed, new ones arrive and are created. Recycling is what stops
// that being an allocation each time.
const unpooled = replay({ flatten: true, recycle: false });

const creates = batches.reduce(
  (total, batch) => total + batch.filter(([op]) => op === OP.CREATE || op === OP.CREATE_TEXT).length,
  0,
);

assert.equal(unpooled.pool.reused, 0, "recycling off still reused a view");
assert.ok(flattened.pool.reused > 0, "recycling on never reused a view");
assert.ok(
  flattened.pool.created < unpooled.pool.created,
  "pooling did not reduce the number of views allocated",
);
assert.equal(
  flattened.pool.created + flattened.pool.reused,
  unpooled.pool.created,
  "the two hosts asked for a different number of views, which is a different screen",
);

// The pool is bounded, so a screen that destroys thousands of rows does not
// hold thousands of views waiting for rows that never come.
for (const [kind, parked] of flattened.pool.free) {
  assert.ok(parked.length <= 64, `the ${kind} pool grew to ${parked.length} views`);
}

const reuseRate = flattened.pool.reused / (flattened.pool.created + flattened.pool.reused);

/* ---- the table ------------------------------------------------------------ */

const byType = (host) => {
  const counts = new Map();
  for (const node of host.nodes.values()) {
    if (node.type === "#text" && host.nodes.get(node.parent)?.type === "text") continue;
    const seen = counts.get(node.type) ?? { nodes: 0, views: 0 };
    seen.nodes += 1;
    if (node.view != null) seen.views += 1;
    counts.set(node.type, seen);
  }
  return counts;
};

// Runs inside a label are left out: they are pieces of a string on every host,
// flattened or not, so counting them would flatter the total.
const rows = [...byType(full.flattened)].sort();
const totalNodes = rows.reduce((sum, [, { nodes }]) => sum + nodes, 0);

console.log(`\n  the list screen, full — ${full.plain.nodes.size} nodes, ${totalNodes} of them boxes\n`);
console.log("                            boxes   views   flattened");
for (const [type, { nodes, views }] of rows) {
  console.log(
    `  ${type.padEnd(24)}${String(nodes).padStart(6)}${String(views).padStart(8)}` +
      `${String(nodes - views).padStart(12)}`,
  );
}
console.log(
  `  ${"".padEnd(24)}${String(totalNodes).padStart(6)}` +
    `${String(full.flattened.viewCount()).padStart(8)}${String(fullSaved).padStart(12)}`,
);

console.log(`
  ${batches.length} batches, ${commands} commands, ${creates} nodes created

  views allocated, one per node            ${String(unpooled.pool.created).padStart(6)}
  views allocated, pooled                  ${String(flattened.pool.created).padStart(6)}
`);

console.log(
  `flatten tests passed — ${fullSaved} of ${full.plain.viewCount()} views flattened away on a ` +
    `full list, ${Math.round(reuseRate * 100)}% of view acquisitions served from the pool`,
);
