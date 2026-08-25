/**
 * A windowed list.
 *
 * The claim being tested is not "it renders" but "it costs a screenful": ten
 * thousand rows must not become ten thousand views, and dragging a finger must
 * not become ten thousand commands.
 */

import assert from "node:assert/strict";
import { install } from "../host/runtime.mjs";
import { HeadlessHost } from "../host/headless.mjs";
import { OP, OP_NAME } from "../host/protocol.mjs";

const host = new HeadlessHost();
const runtime = install(host, { autoFlush: false });

const NativeApp = await import("../NativeApp.res.mjs");
const NativeList = await import("../NativeList.res.mjs");
const Native = await import("../Native.res.mjs");
const View = await import("../../src/View.res.mjs");
const Signal = await import("../../src/Signal.res.mjs");

const ROW_HEIGHT = 40;
const VIEWPORT = 600;
const TOTAL = 10000;

const items = Signal.make(
  Array.from({ length: TOTAL }, (_, index) => ({ id: index, title: `Row ${index}` })),
);

const list = NativeList.make(
  items,
  ROW_HEIGHT,
  (item) => String(item.id),
  (item) =>
    Native.view(
      { height: ROW_HEIGHT },
      undefined,
      undefined,
      undefined,
      undefined,
      [Native.text(undefined, undefined, undefined, undefined, undefined, [View.text(item.title)], undefined)],
      undefined,
    ),
  undefined,
  undefined,
  undefined,
  undefined,
);

NativeApp.mount(list, "root");
runtime.flush();

const rows = () => [...host.views.values()].filter((v) => v.type === "view" && v.props.style?.height === ROW_HEIGHT);
const scrollId = [...host.views.values()].find((v) => v.type === "scroll").id;

/* ---- before the host has said how tall it is ----------------------------- */

assert.ok(rows().length > 0, "something rendered before the first layout event");
assert.ok(rows().length < 20, `and not the whole list — ${rows().length} rows`);

/* ---- once it has ---------------------------------------------------------- */

runtime.dispatchEvent(scrollId, "layout", { x: 0, y: 0, width: 320, height: VIEWPORT });
runtime.flush();

const onScreen = Math.ceil(VIEWPORT / ROW_HEIGHT);
const windowed = rows().length;
assert.ok(
  windowed >= onScreen && windowed <= onScreen + 6,
  `a ${VIEWPORT}pt viewport of ${ROW_HEIGHT}pt rows renders about ${onScreen}, got ${windowed}`,
);
assert.ok(host.views.size < 100, `and the host holds ${host.views.size} views, not ${TOTAL}`);

/* ---- the space the unrendered rows occupy is still there ------------------ */

const content = host.views.get(host.views.get(scrollId).children[0].id);
assert.equal(content.props.style.paddingTop, 0, "nothing above the first row");
assert.equal(
  content.props.style.paddingTop + content.props.style.paddingBottom + windowed * ROW_HEIGHT,
  TOTAL * ROW_HEIGHT,
  "the padding accounts for every row that is not rendered",
);

/* ---- scrolling within a row costs nothing -------------------------------- */

host.clearLog();
for (let y = 1; y < ROW_HEIGHT; y++) {
  runtime.dispatchEvent(scrollId, "scroll", { x: 0, y });
}
runtime.flush();
assert.equal(
  host.log.length,
  0,
  `${ROW_HEIGHT - 1} scroll events inside one row produced ${host.log.length} commands`,
);

/* ---- crossing a row boundary costs a row --------------------------------- */

// The window keeps `overscan` rows either side, so it only moves once the
// scroll has gone past them — which is the point of having them.
const OVERSCAN = 2;
host.clearLog();
runtime.dispatchEvent(scrollId, "scroll", { x: 0, y: (OVERSCAN + 1) * ROW_HEIGHT });
runtime.flush();

const created = host.log.filter((c) => c[0] === OP.CREATE && c[2] === "view").length;
const destroyed = host.log.filter((c) => c[0] === OP.DESTROY).length;
assert.equal(created, 1, "one row entered the window");
assert.ok(destroyed >= 1, "and one left it");
assert.ok(host.log.length < 20, `for ${host.log.length} commands in total`);
assert.deepEqual(
  [...new Set(host.log.map((c) => OP_NAME[c[0]]))].sort(),
  ["create", "createText", "destroy", "insert", "remove", "setProp"],
  "and nothing else happened",
);

/* ---- a long jump renders the destination, not the way there --------------- */

host.clearLog();
runtime.dispatchEvent(scrollId, "scroll", { x: 0, y: 5000 * ROW_HEIGHT });
runtime.flush();

assert.ok(
  host.log.filter((c) => c[0] === OP.CREATE && c[2] === "view").length <= windowed,
  "jumping 5000 rows creates at most a screenful",
);
assert.ok(rows().length <= onScreen + 6, "and leaves a screenful on screen");
const titles = [...host.views.values()]
  .filter((v) => v.type === "#text")
  .map((v) => v.text)
  .filter((text) => text.startsWith("Row "));
assert.ok(
  titles.every((title) => Number(title.slice(4)) > 4900),
  "showing rows from where it landed",
);

/* ---- the end of the list --------------------------------------------------*/

host.clearLog();
runtime.dispatchEvent(scrollId, "scroll", { x: 0, y: (TOTAL - onScreen) * ROW_HEIGHT });
runtime.flush();
const tail = host.views.get(host.views.get(scrollId).children[0].id);
assert.equal(tail.props.style.paddingBottom, 0, "nothing left below the last row");

console.log(
  `list tests passed — ${TOTAL} rows, ${host.views.size} views, a scroll across one row is a handful of commands`,
);
