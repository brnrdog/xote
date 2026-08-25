/**
 * The measurement the roadmap ends on.
 *
 * The premise of the whole thing is that fine-grained reactivity makes the
 * bridge cheap: no diff, so a change costs the mutations it implies and nothing
 * else. That was demonstrated on a counter, which proves very little. This runs
 * the same measurements against a screen at real-app scale — five thousand
 * issues, a live search, filters, a windowed list and a second screen — and
 * asserts the numbers stay proportional to what actually changed.
 *
 * The assertions are deliberately loose bounds rather than exact counts: the
 * point is the order of magnitude, and an exact count would fail on every
 * cosmetic change to the example. The printed table is the real output.
 */

import assert from "node:assert/strict";
import { install } from "../host/runtime.mjs";
import { HeadlessHost } from "../host/headless.mjs";
import { OP } from "../host/protocol.mjs";

const host = new HeadlessHost();
const runtime = install(host, { autoFlush: false });

const NativeApp = await import("../NativeApp.res.mjs");
const TrackerApp = await import("../example/tracker/TrackerApp.res.mjs");

const VIEWPORT = 720;
const ROW_HEIGHT = 84;
const TOTAL = 5000;

const measurements = [];

const measure = (what, act) => {
  host.clearLog();
  act();
  runtime.flush();
  measurements.push({ what, commands: host.log.length, views: host.views.size });
  return host.log;
};

/* ---- mounting ------------------------------------------------------------ */

const mount = measure("mount the whole screen", () => NativeApp.mount(TrackerApp.make(), "root"));

const find = (predicate) => [...host.views.values()].filter(predicate);
const textOf = (node) =>
  node.type === "#text"
    ? node.text
    : node.children.map((child) => textOf(host.views.get(child.id) ?? child)).join("");

/* The search field lives in the screen's chrome and survives everything. The
 list does not: crossing into the empty state destroys it, and coming back
 builds a new one with a new id — so it is looked up, never remembered. */
const currentScroll = () => find((v) => v.type === "scroll")[0];
const input = find((v) => v.type === "input")[0];
assert.ok(currentScroll() && input, "the screen has a list and a search field");

/* Tell the list how tall it is. A freshly built one starts at zero and renders
 a couple of rows until the host reports a frame, which is the same round trip
 it makes on a device. */
const reportViewport = (label) => {
  const scroll = currentScroll();
  if (scroll === undefined) return;
  const send = () =>
    runtime.dispatchEvent(scroll.id, "layout", { x: 0, y: 0, width: 390, height: VIEWPORT });
  if (label === undefined) {
    send();
    runtime.flush();
  } else {
    measure(label, send);
  }
};

assert.ok(
  mount.filter((c) => c[0] === OP.CREATE).length < 400,
  `mounting created ${mount.filter((c) => c[0] === OP.CREATE).length} views for ${TOTAL} issues`,
);

// Mounting happens before the host knows how big the screen is, so the list
// renders a couple of rows and fills in once it is told — the same round trip
// it makes on a device, and worth seeing separately in the table.
reportViewport("...then learn the viewport");

const rows = () => find((v) => v.type === "pressable" && v.props.style?.height === ROW_HEIGHT);
const onScreen = Math.ceil(VIEWPORT / ROW_HEIGHT);
assert.ok(rows().length <= onScreen + 6, `${rows().length} rows rendered for ${TOTAL} issues`);
assert.ok(host.views.size < 400, `${host.views.size} views on a screen of ${TOTAL} issues`);

const subtitle = () => textOf(find((v) => v.type === "text" && textOf(v).includes(" of "))[0]);
assert.equal(subtitle(), `${TOTAL} of ${TOTAL}`);

/* ---- typing -------------------------------------------------------------- */

// A query that leaves the list full: the rows on screen change, nothing else.
measure("type a query matching many", () =>
  runtime.dispatchEvent(input.id, "changeText", { value: "the" }),
);
const many = Number(subtitle().split(" ")[0]);
assert.ok(many > 100 && many < TOTAL, `"the" matched ${many}`);

// A query that narrows the list hard. What matters is that the cost tracks the
// rows *on screen*, not the number of matches and certainly not the dataset.
const narrow = measure("type a query matching few", () =>
  runtime.dispatchEvent(input.id, "changeText", { value: "recycling on first paint" }),
);
const few = Number(subtitle().split(" ")[0]);
assert.ok(few > 0 && few < 200, `the narrow query matched ${few}`);
// Every visible row is now a different issue, so a screenful of rows really is
// rebuilt — about eleven nodes each. What does *not* happen is the other 4,986
// matches costing anything, or the 4,940 non-matches being visited.
const rebuilt = narrow.filter((c) => c[0] === OP.CREATE).length;
assert.ok(rebuilt < (onScreen + 6) * 14, `narrowing to ${few} matches created ${rebuilt} views`);
assert.ok(rebuilt > 0, "and it did rebuild the rows that changed");

// A query that matches nothing crosses into the empty state, which is the one
// place on this screen that really is a wholesale replacement.
const empty = measure("type a query matching nothing", () =>
  runtime.dispatchEvent(input.id, "changeText", { value: "zzzz" }),
);
assert.equal(subtitle(), `0 of ${TOTAL}`);
assert.ok(
  find((v) => v.type === "text" && textOf(v) === "Nothing matches").length === 1,
  "the empty state is on screen",
);
assert.ok(empty.length < 500, `the empty state cost ${empty.length} commands`);

measure("clear the query", () => runtime.dispatchEvent(input.id, "changeText", { value: "" }));
assert.equal(subtitle(), `${TOTAL} of ${TOTAL}`);
// A new list, so it needs telling how tall it is again.
reportViewport();

/* ---- filtering ----------------------------------------------------------- */

const chipFor = (label) =>
  find((v) => v.type === "pressable" && textOf(v) === label && v.props.style?.borderRadius === 999)[0];

const filter = measure("toggle a filter chip", () =>
  runtime.dispatchEvent(chipFor("Done").id, "press", {}),
);
assert.ok(Number(subtitle().split(" ")[0]) < TOTAL, "the filter narrowed the list");
// Three chips, each a box and a label, is six style writes. Everything else is
// the rows the filter changed.
assert.ok(
  filter.filter((c) => c[0] === OP.SET_PROP).length >= 6,
  "every chip restyled itself",
);

measure("clear the filter", () => runtime.dispatchEvent(chipFor("Done").id, "press", {}));

/* ---- scrolling ----------------------------------------------------------- */

const scroll = currentScroll();
const withinRow = measure("scroll within one row", () => {
  for (let y = 1; y < ROW_HEIGHT; y += 4) {
    runtime.dispatchEvent(scroll.id, "scroll", { x: 0, y });
  }
});
assert.equal(withinRow.length, 0, "a drag inside one row costs nothing");

const acrossRow = measure("scroll across one row", () =>
  runtime.dispatchEvent(scroll.id, "scroll", { x: 0, y: 3 * ROW_HEIGHT }),
);
// One row of this app is about eleven nodes — a dot, two labels, a title, up to
// three tags and a count — so one row entering and one leaving is that twice
// over, and nothing else.
assert.ok(acrossRow.length < 120, `crossing a row cost ${acrossRow.length} commands`);
assert.ok(acrossRow.length > 0, "and it did move the window");

measure("scroll to the middle of the list", () =>
  runtime.dispatchEvent(scroll.id, "scroll", { x: 0, y: 2500 * ROW_HEIGHT }),
);
assert.ok(host.views.size < 400, "and still holds a screenful");

/* ---- navigating ---------------------------------------------------------- */

measure("scroll back to the top", () =>
  runtime.dispatchEvent(scroll.id, "scroll", { x: 0, y: 0 }),
);

const row = rows()[0];
const open = measure("open an issue", () => runtime.dispatchEvent(row.id, "press", {}));
assert.ok(
  find((v) => v.type === "text" && textOf(v) === "← Issues").length === 1,
  "the detail screen is on screen",
);
assert.ok(open.length < 1200, `navigating cost ${open.length} commands`);

/* The claim, in one gesture: pressing a status button writes one signal that
 belongs to the issue, and only the things reading it change. */
const statusButton = find(
  (v) => v.type === "pressable" && textOf(v) === "In progress" && v.props.style?.flex === 1,
)[0];
const toggle = measure("change an issue's status", () =>
  runtime.dispatchEvent(statusButton.id, "press", {}),
);

assert.deepEqual(
  toggle.map((c) => c[0]).filter((op) => op !== OP.SET_PROP && op !== OP.SET_TEXT),
  [],
  "changing a status creates and destroys nothing",
);
assert.ok(
  toggle.length <= 12,
  `it cost ${toggle.length} commands: the three buttons, the dot, and the label`,
);

const back = measure("go back", () =>
  runtime.dispatchEvent(find((v) => v.type === "pressable" && textOf(v) === "← Issues")[0].id, "press", {}),
);
assert.equal(subtitle(), `${TOTAL} of ${TOTAL}`, "the list came back");
assert.ok(back.length < 1200, `going back cost ${back.length} commands`);

/* ---- the table ----------------------------------------------------------- */

const width = Math.max(...measurements.map((m) => m.what.length));
console.log(`\n  ${TOTAL} issues, a ${VIEWPORT}pt viewport\n`);
console.log(`  ${"".padEnd(width)}   commands   views`);
for (const { what, commands, views } of measurements) {
  console.log(`  ${what.padEnd(width)}   ${String(commands).padStart(8)}   ${String(views).padStart(5)}`);
}
console.log("\ntracker measurements passed");
