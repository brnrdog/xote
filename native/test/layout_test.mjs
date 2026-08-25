/**
 * The layout engine against frames recorded from Chromium.
 *
 * `layout_oracle.mjs` produced `__fixtures__/layout-expected.json` by laying
 * every case out with real CSS flexbox; this replays it without a browser, so
 * the engine is checked against the specification on every run rather than
 * whenever someone remembers to install Playwright.
 *
 * Measured leaves are covered separately at the bottom — a browser cannot be
 * the oracle for those, because it would be measuring its own text metrics
 * rather than the host's.
 */

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cases, walk } from "./layout-cases.mjs";
import { layout, EXACTLY, UNDEFINED } from "../host/layout.mjs";

const expected = JSON.parse(
  readFileSync(fileURLToPath(new URL("./__fixtures__/layout-expected.json", import.meta.url))),
);

const TOLERANCE = 0.5;
let boxes = 0;

for (const { name, tree } of cases) {
  const want = expected[name];
  assert.ok(want, `${name} is missing from the fixture — re-record it with the oracle`);
  layout(tree, tree.style.width, tree.style.height);
  for (const { path, node } of walk(tree)) {
    boxes += 1;
    for (const key of ["left", "top", "width", "height"]) {
      const delta = Math.abs(want[path][key] - node.layout[key]);
      assert.ok(
        delta <= TOLERANCE,
        `${name} at ${path}: ${key} should be ${want[path][key]}, got ${node.layout[key]}`,
      );
    }
  }
}

/* ---- measured leaves ------------------------------------------------------
 *
 * Text is the one thing the host measures rather than the engine, so these
 * assert the contract between them: what the engine asks, and what it does
 * with the answer. The stand-in below wraps at whatever width it is given,
 * which is the behaviour that matters — a leaf that gets taller as it narrows.
 */

const wrapping = (chars, charWidth = 10, lineHeight = 16) => ({
  style: {},
  measure: (availableWidth, widthMode) => {
    const naturalWidth = chars * charWidth;
    if (widthMode === UNDEFINED || availableWidth === undefined) {
      return { width: naturalWidth, height: lineHeight };
    }
    const usable = widthMode === EXACTLY ? availableWidth : Math.min(availableWidth, naturalWidth);
    const perLine = Math.max(1, Math.floor(usable / charWidth));
    return { width: usable, height: Math.ceil(chars / perLine) * lineHeight };
  },
  children: [],
});

{
  // Unconstrained, a leaf is its natural size.
  const root = { style: { flexDirection: "row" }, children: [wrapping(10)] };
  layout(root, undefined, undefined);
  assert.equal(root.layout.width, 100, "an unconstrained leaf is its natural width");
  assert.equal(root.layout.height, 16, "and one line tall");
}

{
  // Narrower than its natural width, it wraps and the column grows to fit.
  const leaf = wrapping(10);
  const root = { style: { width: 50 }, children: [leaf] };
  layout(root, 50, undefined);
  assert.equal(leaf.layout.width, 50, "the leaf is asked to fit the column");
  assert.equal(leaf.layout.height, 32, "and answers with two lines");
  assert.equal(root.layout.height, 32, "which the auto-height column adopts");
}

{
  // Text does not shrink unless it is asked to: `flexShrink` defaults to 0, so
  // a leaf wider than its row overflows rather than reflowing. This is React
  // Native's default too, and it surprises people, so it is worth pinning.
  const leaf = wrapping(10);
  const root = {
    style: { flexDirection: "row", width: 80, alignItems: "flex-start" },
    children: [leaf, { style: { flex: 1 }, children: [] }],
  };
  layout(root, 80, undefined);
  assert.equal(leaf.layout.width, 100, "the leaf keeps its natural width and overflows");
  assert.equal(root.layout.height, 16, "so the row stays one line tall");
}

{
  // Given `flexShrink`, the same leaf is squeezed — and re-measured at the
  // width it ended up with, which is the whole point of a measure callback.
  const leaf = wrapping(10);
  leaf.style = { flexShrink: 1 };
  const root = {
    style: { flexDirection: "row", width: 50, alignItems: "flex-start" },
    children: [leaf],
  };
  layout(root, 50, undefined);
  assert.equal(leaf.layout.width, 50, "the leaf shrank to the row");
  assert.equal(leaf.layout.height, 32, "and was re-measured at that width");
  assert.equal(root.layout.height, 32, "so the row is two lines tall");
}

{
  // Padding is added around what the host measured, not taken out of it.
  const leaf = wrapping(4);
  leaf.style = { padding: 5 };
  const root = { style: {}, children: [leaf] };
  layout(root, undefined, undefined);
  assert.equal(leaf.layout.width, 50, "40 of text plus 5 either side");
  assert.equal(leaf.layout.height, 26, "16 of line plus 5 either side");
}

{
  // The ordinary case: a box stretched to a column of known width, with text
  // inside it. The width propagates down as a definite constraint, so the text
  // wraps and every box on the way back up grows to hold it.
  const leaf = wrapping(10);
  const box = { style: {}, children: [leaf] };
  const root = { style: { width: 60 }, children: [box] };
  layout(root, 60, undefined);
  assert.equal(box.layout.width, 60, "the box stretched to the column");
  assert.equal(leaf.layout.height, 32, "so the text wrapped to two lines");
  assert.equal(root.layout.height, 32, "and the column grew to hold it");
}

console.log(`layout tests passed — ${boxes} boxes against Chromium-recorded frames`);
