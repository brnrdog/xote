// What `@xote.component` did to a module, shown against its source: every
// decision in the ppx's site map, under the line it was made on.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const describe = (entry) => {
  switch (entry.kind) {
    case "component":
      return `@xote.component ${entry.name}`;
    case "child":
      return entry.reactive === "true"
        ? "reactive child: re-runs when the signals it reads change"
        : "static child: rendered once";
    case "thunked-attr":
      return `reactive attribute ${entry.attr}: thunked into a computed attribute`;
    case "thunked-value":
      return "reactive value: thunked, re-runs when its signals change";
    case "tracked":
      return "View.tracked: rebuilds this branch when the condition's signals change";
    case "probe":
      return `View.probe: ${entry.role === "condition" ? "condition" : "value"} checked at runtime for hidden signal reads`;
    case "one-shot-prop":
      return `one-shot prop ${entry.prop} of <${entry.component}>: read once, never updates`;
    default:
      return entry.kind;
  }
};

/* The site map of `module` joined with its source lines. */
export function expand(root, module) {
  const mapFile = join(root, "lib", "xote-sitemap", `${module}.json`);
  if (!existsSync(mapFile)) {
    throw new Error(
      `no site map for ${module}: it has no @xote.component, or the ppx runs without "-sitemap" ("ppx-flags": [["xote/ppx/ppx", "-sitemap"]]), or the project is not built`,
    );
  }
  const map = JSON.parse(readFileSync(mapFile, "utf8"));
  const source = readFileSync(join(root, map.file), "utf8").split("\n");
  const byLine = new Map();
  for (const entry of map.sites) {
    const [, line, column] = entry.site.split(":").map(Number);
    if (!byLine.has(line)) byLine.set(line, []);
    byLine.get(line).push({ ...entry, line, column, description: describe(entry) });
  }
  const lines = source.map((text, index) => ({ line: index + 1, text, sites: byLine.get(index + 1) ?? [] }));
  return { module: map.module, file: map.file, sites: map.sites.map((e) => ({ ...e, description: describe(e) })), lines };
}

/* Source with each decision under its line, carets at the column. Only lines
   with decisions are shown, with `context` lines around them. */
export function formatExpand(result, { context = 1 } = {}) {
  const show = new Set();
  result.lines.forEach((l, i) => {
    if (l.sites.length) for (let d = -context; d <= context; d++) show.add(i + d);
  });
  const width = String(result.lines.length).length;
  const out = [result.file];
  let last = -2;
  result.lines.forEach((l, i) => {
    if (!show.has(i)) return;
    if (i !== last + 1) out.push(`${" ".repeat(width)} ┆`);
    last = i;
    out.push(`${String(l.line).padStart(width)} │ ${l.text}`);
    for (const site of [...l.sites].sort((a, b) => a.column - b.column)) {
      out.push(`${" ".repeat(width)} │ ${" ".repeat(Math.max(0, site.column - 1))}^ ${site.description}`);
    }
  });
  return out.join("\n");
}
