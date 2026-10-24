// Assertions on the site map the ppx writes with `-sitemap` (see this
// project's rescript.json). Devtools explain a component from this file, so
// each kind of decision is checked at a known source position, and so is what
// the map must leave out.

import { readFileSync } from "node:fs";

const read = (module) =>
  JSON.parse(readFileSync(new URL(`./lib/xote-sitemap/${module}.json`, import.meta.url), "utf8"));

let passed = 0;
let failed = 0;
const check = (name, ok, detail) => {
  if (ok) {
    passed++;
    console.log(`  ✓ ${name}`);
  } else {
    failed++;
    console.log(`  ✗ ${name}${detail ? `\n      ${detail}` : ""}`);
  }
};

const demo = read("Demo");
const at = (site) => demo.sites.filter((entry) => entry.site === site);
const has = (site, fields) =>
  at(site).some((entry) => Object.entries(fields).every(([k, v]) => entry[k] === v));

console.log("site map");
check("names the module and its source file", demo.module === "Demo" && demo.file === "src/Demo.res");
check("records each component by name", has("Demo.res:21:3", { kind: "component", name: "Card" }));
check("records a thunked attribute with its name", has("Demo.res:23:17", { kind: "thunked-attr", attr: "class" }));
check("records a value-primitive child that was thunked", has("Demo.res:25:20", { kind: "thunked-value" }));
check("records a static bare child as not reactive", has("Demo.res:24:36", { kind: "child", reactive: "false" }));
check("records control flow lowered to View.tracked", has("Demo.res:35:8", { kind: "tracked" }));
check(
  "records a user-component prop left as a one-shot read",
  has("Demo.res:342:14", { kind: "one-shot-prop", component: "TitleCard", prop: "label" }),
);
check("records a probed leaf", has("Demo.res:357:34", { kind: "probe", role: "leaf" }));
check(
  "leaves out nodes the compiler synthesised",
  demo.sites.every((entry) => /^Demo\.res:\d+:\d+$/.test(entry.site)),
  demo.sites.find((entry) => !/^Demo\.res:\d+:\d+$/.test(entry.site))?.site,
);
const lines = demo.sites.map((entry) => Number(entry.site.split(":")[1]));
check("lists sites in source order", lines.every((line, i) => i === 0 || lines[i - 1] <= line));

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
