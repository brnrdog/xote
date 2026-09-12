/**
 * Every path a host's build files reach for actually exists.
 *
 * Neither host can be compiled here, so their build configuration is the one
 * part of them that *can* be checked — and it is the part that has broken
 * most. The two hosts reach out of their own directories for two things they
 * share with everyone else: the bundle, built once by `npm run native:bundle`,
 * and the conformance suite. Those are the paths that quietly stop resolving
 * when a directory moves, and a wrong one is not a compile error in any
 * language — it is XcodeGen refusing to generate a project, or Gradle shipping
 * an APK with no assets in it.
 *
 * Moving this package under `packages/` broke three of them, one at a time,
 * each found by someone running into it. This is the check that would have
 * found all three at once.
 */

import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));

/**
 * Every relative path a build file names, with the directory it is relative
 * to. Parsed rather than listed, so a path added to a host is checked without
 * anyone remembering to add it here.
 *
 * The patterns are deliberately narrow — one per build system, matching the
 * syntax that declares a source or resource — because a regex loose enough to
 * catch everything also catches the `../` inside a comment.
 */
const BUILD_FILES = [
  {
    file: "hosts/ios/project.yml",
    what: "XcodeGen",
    // `- path: <something>` under a target's `sources:`.
    pattern: /^\s*-\s*path:\s*(\S+)\s*$/gm,
  },
  {
    file: "hosts/android/app/build.gradle.kts",
    what: "Gradle",
    // `assets.srcDirs("a", "b")` and the other `srcDirs` families.
    pattern: /srcDirs?\(([^)]*)\)/g,
  },
];

let checked = 0;

for (const { file, what, pattern } of BUILD_FILES) {
  const absolute = resolve(root, file);
  assert.ok(existsSync(absolute), `${file} is where the tests think it is`);
  const source = readFileSync(absolute, "utf8");
  const base = dirname(absolute);

  const paths = [];
  for (const [, captured] of source.matchAll(pattern)) {
    // Gradle takes a list of quoted strings; XcodeGen takes one bare path.
    const found = captured.includes('"')
      ? [...captured.matchAll(/"([^"]+)"/g)].map(([, value]) => value)
      : [captured];
    paths.push(...found);
  }

  assert.ok(paths.length > 0, `${file}: found no paths, so the ${what} pattern has gone stale`);

  for (const relative of paths) {
    const target = resolve(base, relative);
    assert.ok(
      existsSync(target),
      `${file} (${what}) points at ${relative}, which resolves to ${target} and is not there`,
    );
    checked += 1;
  }
}

/* The two that cross out of `hosts/` are the ones that break, so they are named
 rather than merely counted: a pattern that silently stopped matching would
 otherwise pass this file with nothing to show for it. */
const spec = readFileSync(resolve(root, "hosts/ios/project.yml"), "utf8");
assert.match(spec, /path:\s*\.\.\/\.\.\/conformance\/suite\.json/, "iOS reaches the suite");
assert.match(spec, /path:\s*\.\.\/\.\.\/bundle\/dist\/xote-app\.js/, "iOS reaches the bundle");

const gradle = readFileSync(resolve(root, "hosts/android/app/build.gradle.kts"), "utf8");
assert.match(gradle, /srcDirs\("\.\.\/\.\.\/\.\.\/conformance"\)/, "Android reaches the suite");
assert.match(gradle, /srcDirs\("\.\.\/\.\.\/\.\.\/bundle\/dist"\)/, "Android reaches the bundle");

console.log(`host build tests passed — ${checked} paths in ${BUILD_FILES.length} build files resolve`);
