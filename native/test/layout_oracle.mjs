/**
 * The oracle: lays every case out in Chromium with real CSS flexbox, records
 * the frames, and reports where `host/layout.mjs` disagrees.
 *
 *   node native/test/layout_oracle.mjs           # compare, report, do not write
 *   node native/test/layout_oracle.mjs --write   # also refresh the fixture
 *
 * Needs Playwright, which this repository does not depend on — install it
 * alongside (`npm i -D playwright`) or run from `benchmarks/`, which already
 * has it. The recorded fixture is committed, so the ordinary test suite checks
 * the engine against these numbers without a browser.
 *
 * Browser defaults are not Yoga's, so the page resets the ones that differ:
 * a flex container is a column, an item does not shrink, sizes are border-box,
 * and `min-width`/`min-height` are 0 rather than `auto`.
 */

import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cases, walk } from "./layout-cases.mjs";
import { layout } from "../host/layout.mjs";

const CHROMIUM = process.env.XOTE_CHROMIUM ?? "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const FIXTURE = fileURLToPath(new URL("./__fixtures__/layout-expected.json", import.meta.url));
const TOLERANCE = 0.5;

let chromium;
try {
  ({ chromium } = await import("playwright"));
} catch {
  console.log("layout oracle skipped — playwright is not installed");
  process.exit(0);
}

const UNITLESS = new Set(["flex", "flexGrow", "flexShrink", "aspectRatio", "zIndex", "opacity"]);

/* `paddingHorizontal` and friends are ours, not CSS's. Expand them to
 longhands in the same precedence order the engine reads them — shorthand
 first, longhand last — so the browser is told exactly what the engine
 computed from. */
function expand(style) {
  const out = {};
  for (const [key, value] of Object.entries(style)) {
    const match = /^(margin|padding)(Horizontal|Vertical)?$/.exec(key);
    if (!match) continue;
    const [, prefix, axis] = match;
    const sides =
      axis === "Horizontal"
        ? ["Left", "Right"]
        : axis === "Vertical"
          ? ["Top", "Bottom"]
          : ["Top", "Right", "Bottom", "Left"];
    for (const side of sides) out[prefix + side] = value;
  }
  for (const [key, value] of Object.entries(style)) {
    if (/^(margin|padding)(Horizontal|Vertical)?$/.test(key)) continue;
    out[key] = value;
  }
  // Longhands last, so they win over anything expanded above.
  for (const [key, value] of Object.entries(style)) {
    if (/^(margin|padding)(Top|Right|Bottom|Left)$/.test(key)) out[key] = value;
  }
  return out;
}

const css = (style) =>
  Object.entries(expand(style))
    .map(([key, value]) => {
      const name = key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);
      const text =
        typeof value === "number" && !UNITLESS.has(key) ? `${value}px` : String(value);
      return `${name}:${text}`;
    })
    .join(";");

const html = (node, path = "0") =>
  `<div data-path="${path}" style="${css(node.style || {})}">` +
  (node.children || []).map((child, i) => html(child, `${path}.${i}`)).join("") +
  "</div>";

const browser = await chromium.launch({ executablePath: CHROMIUM });
const page = await browser.newPage({ viewport: { width: 1200, height: 1400 } });

await page.setContent(`<!doctype html><html><head><style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { width: 1200px; }
  /* The stage is a plain block, so a case root is never a flex item — a root
     carrying flex:1 would otherwise get flex-basis:0 and be sized by the stage
     instead of by the frame the test is asking about. */
  #stage { display: block; }
  div {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    flex-shrink: 0;
    flex-basis: auto;
    position: relative;
    min-width: 0;
    min-height: 0;
    border-style: solid;
    border-width: 0;
    border-color: transparent;
  }
</style></head><body><div id="stage"></div></body></html>`);

const expected = {};
for (const { name, tree } of cases) {
  expected[name] = await page.evaluate((markup) => {
    const stage = document.getElementById("stage");
    stage.innerHTML = markup;
    const frames = {};
    const nodes = stage.querySelectorAll("[data-path]");
    const rects = new Map();
    for (const el of nodes) rects.set(el.dataset.path, el.getBoundingClientRect());
    for (const el of nodes) {
      const path = el.dataset.path;
      const rect = rects.get(path);
      const parentPath = path.includes(".") ? path.slice(0, path.lastIndexOf(".")) : null;
      const parent = parentPath === null ? null : rects.get(parentPath);
      frames[path] = {
        left: Math.round(((parent ? rect.left - parent.left : 0) + Number.EPSILON) * 100) / 100,
        top: Math.round(((parent ? rect.top - parent.top : 0) + Number.EPSILON) * 100) / 100,
        width: Math.round((rect.width + Number.EPSILON) * 100) / 100,
        height: Math.round((rect.height + Number.EPSILON) * 100) / 100,
      };
    }
    return frames;
  }, html(tree));
}

await browser.close();

/* ---- compare ------------------------------------------------------------- */

let checked = 0;
const failures = [];
for (const { name, tree } of cases) {
  layout(tree, tree.style.width, tree.style.height);
  for (const { path, node } of walk(tree)) {
    const want = expected[name][path];
    const got = node.layout;
    checked += 1;
    for (const key of ["left", "top", "width", "height"]) {
      if (Math.abs(want[key] - got[key]) > TOLERANCE) {
        failures.push({ name, path, key, want: want[key], got: Math.round(got[key] * 100) / 100 });
      }
    }
  }
}

const byCase = new Map();
for (const failure of failures) {
  if (!byCase.has(failure.name)) byCase.set(failure.name, []);
  byCase.get(failure.name).push(failure);
}

const only = process.argv.find((arg) => arg.startsWith("--case="))?.slice("--case=".length);
if (only !== undefined) {
  const found = cases.find((c) => c.name === only);
  for (const { path, node } of walk(found.tree)) {
    const want = expected[only][path];
    const got = node.layout;
    const mark = ["left", "top", "width", "height"].some(
      (k) => Math.abs(want[k] - got[k]) > TOLERANCE,
    )
      ? "✗"
      : " ";
    const round = (v) => Math.round(v * 100) / 100;
    console.log(
      `${mark} ${path.padEnd(10)} ${JSON.stringify(node.style)}\n` +
        `      chromium ${JSON.stringify(want)}\n` +
        `      engine   ${JSON.stringify({
          left: round(got.left),
          top: round(got.top),
          width: round(got.width),
          height: round(got.height),
        })}`,
    );
  }
  process.exit(0);
}

console.log(`${checked} boxes across ${cases.length} cases, ${failures.length} disagreements`);
for (const [name, list] of [...byCase].slice(0, 12)) {
  console.log(`\n  ${name}`);
  for (const f of list.slice(0, 6)) {
    console.log(`    ${f.path} ${f.key}: chromium ${f.want}, engine ${f.got}`);
  }
  if (list.length > 6) console.log(`    …and ${list.length - 6} more`);
}
if (byCase.size > 12) console.log(`\n…and ${byCase.size - 12} more cases`);

if (process.argv.includes("--write")) {
  if (failures.length > 0) {
    console.error("\nrefusing to write the fixture while the engine disagrees with the browser");
    process.exit(1);
  }
  writeFileSync(FIXTURE, JSON.stringify(expected, null, 1) + "\n");
  console.log(`\nwrote ${FIXTURE}`);
}

process.exit(failures.length === 0 ? 0 : 1);
