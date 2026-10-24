// What `@xote.component` did to a module: every decision in the ppx's site
// map, joined with the source line it was made on.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const DESCRIPTIONS = {
  component: (e) => `@xote.component ${e.name}`,
  child: (e) => (e.reactive === "true" ? "reactive child: re-runs when the signals it reads change" : "static child: rendered once"),
  "thunked-attr": (e) => `reactive attribute ${e.attr}: thunked into a computed attribute`,
  "thunked-value": () => "reactive value: thunked, re-runs when its signals change",
  tracked: () => "View.tracked: rebuilds this branch when the condition's signals change",
  probe: (e) => `View.probe: ${e.role === "condition" ? "condition" : "value"} checked at runtime for hidden signal reads`,
  "one-shot-prop": (e) => `one-shot prop ${e.prop} of <${e.component}>: read once, never updates`,
};

const describe = (entry) => ({ ...entry, description: DESCRIPTIONS[entry.kind]?.(entry) ?? entry.kind });

/* The site map of `module` joined with its source lines. */
export function expand(root, module) {
  const mapFile = join(root, "lib", "xote-sitemap", `${module}.json`);
  if (!existsSync(mapFile)) {
    throw new Error(
      `no site map for ${module}: it has no @xote.component, or the ppx runs without "-sitemap" ("ppx-flags": [["xote/ppx/ppx", "-sitemap"]]), or the project is not built`,
    );
  }
  const map = JSON.parse(readFileSync(mapFile, "utf8"));
  const byLine = new Map();
  for (const entry of map.sites) {
    const [, line, column] = entry.site.split(":").map(Number);
    if (!byLine.has(line)) byLine.set(line, []);
    byLine.get(line).push(describe({ ...entry, line, column }));
  }
  const lines = readFileSync(join(root, map.file), "utf8")
    .split("\n")
    .map((text, index) => ({ line: index + 1, text, sites: byLine.get(index + 1) ?? [] }));
  return { module: map.module, file: map.file, sites: map.sites.map(describe), lines };
}
