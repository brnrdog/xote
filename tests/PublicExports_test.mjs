/**
 * Snapshots the JavaScript export list of every public module.
 *
 * The `.resi` files decide what ReScript consumers can reach; this asserts the
 * same narrowing landed in the emitted JS, so an accidentally widened surface
 * shows up as a reviewable diff instead of shipping silently.
 *
 * Regenerate with `UPDATE_SNAPSHOTS=1 node tests/PublicExports_test.mjs`.
 */

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const snapshotPath = join(repoRoot, "tests", "__snapshots__", "public-exports.json");

/* The documented public modules, in the order they appear in AGENTS.md. */
const PUBLIC_MODULES = [
  "View",
  "Html",
  "XoteJSX",
  "MaybeSignal",
  "Prop",
  "Route",
  "Router",
  "SSR",
  "SSRContext",
  "SSRState",
  "Hydration",
  "Mdx",
  "Signal",
  "Computed",
  "Effect",
];

function exportedNames(module) {
  const source = readFileSync(join(repoRoot, "src", `${module}.res.mjs`), "utf8");
  const names = new Set();

  for (const [, body] of source.matchAll(/export\s*\{([^}]*)\}/g)) {
    for (const entry of body.split(",")) {
      const name = entry.trim().split(/\s+as\s+/).pop();
      if (name) names.add(name);
    }
  }

  return [...names].sort();
}

const actual = Object.fromEntries(PUBLIC_MODULES.map((m) => [m, exportedNames(m)]));

/**
 * ReScript emits cross-package imports as `xote/src/<Module>.res.mjs`, so the
 * `exports` map has to name every module a consumer may reach - and only those.
 * A catch-all `./src/*` would make every internal module a supported entry point.
 */
function checkSubpathExports() {
  const pkg = JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8"));
  const subpaths = Object.keys(pkg.exports).filter((k) => k.startsWith("./src/"));

  const expected = new Set([
    ...PUBLIC_MODULES.map((m) => `./src/${m}.res.mjs`),
    "./src/jsx-runtime.mjs",
    "./src/jsx-dev-runtime.mjs",
  ]);

  const problems = [];
  for (const subpath of subpaths) {
    if (subpath.includes("*")) {
      problems.push(`  + ${subpath} (wildcard exports every internal module)`);
    } else if (!expected.has(subpath)) {
      problems.push(`  + ${subpath} (not a public module)`);
    }
  }
  for (const subpath of expected) {
    if (!subpaths.includes(subpath)) {
      problems.push(`  - ${subpath} (public module is not importable)`);
    }
  }
  return problems;
}

const subpathProblems = checkSubpathExports();
if (subpathProblems.length > 0) {
  console.error('package.json "exports" does not match the public module list:\n');
  console.error(subpathProblems.join("\n"));
  process.exit(1);
}

if (process.env.UPDATE_SNAPSHOTS) {
  writeFileSync(snapshotPath, `${JSON.stringify(actual, null, 2)}\n`);
  console.log(`Updated ${snapshotPath}`);
  process.exit(0);
}

const expected = JSON.parse(readFileSync(snapshotPath, "utf8"));
const failures = [];

for (const module of PUBLIC_MODULES) {
  const before = expected[module] ?? [];
  const after = actual[module];

  const added = after.filter((n) => !before.includes(n));
  const removed = before.filter((n) => !after.includes(n));

  if (added.length > 0 || removed.length > 0) {
    failures.push(
      `  ${module}:${added.map((n) => `\n    + ${n}`).join("")}${removed
        .map((n) => `\n    - ${n}`)
        .join("")}`,
    );
  }
}

if (failures.length > 0) {
  console.error("Public JS export surface changed:\n");
  console.error(failures.join("\n"));
  console.error(
    "\nIf this is intentional, review it as an API change and re-run with UPDATE_SNAPSHOTS=1.",
  );
  process.exit(1);
}

console.log(`Public export surface matches the snapshot (${PUBLIC_MODULES.length} modules)`);
