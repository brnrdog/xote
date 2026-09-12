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
import { dirname, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));

/**
 * Directories a build step produces, which are therefore not in the
 * repository and not there on a clean checkout.
 *
 * A path into one of these cannot be checked by looking for the file — CI
 * runs `npm test` without having run `npm run native:bundle`, and the first
 * version of this test failed there for exactly that reason. What *can* be
 * checked is the part that is committed: `bundle/` exists, so a host that
 * counted its `../` wrong still lands somewhere that is not it.
 */
const BUILD_OUTPUTS = ["bundle/dist"];

/** The committed directory a build output lives in — `bundle/` for `bundle/dist`. */
function committedAncestor(relativeToRoot) {
  const output = BUILD_OUTPUTS.find(
    (dir) => relativeToRoot === dir || relativeToRoot.startsWith(dir + "/"),
  );
  return output === undefined ? null : dirname(output);
}

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

  for (const declared of paths) {
    const target = resolve(base, declared);
    const fromRoot = relative(root, target).split(sep).join("/");
    const ancestor = committedAncestor(fromRoot);

    if (ancestor !== null) {
      // A build output. The file is only there after `npm run native:bundle`,
      // so what is checked is the committed directory it is produced into.
      assert.ok(
        existsSync(resolve(root, ancestor)),
        `${file} (${what}) points at ${declared}, whose ${ancestor}/ is not at ` +
          `${resolve(root, ancestor)} — the path is wrong, not merely unbuilt`,
      );
    } else {
      assert.ok(
        existsSync(target),
        `${file} (${what}) points at ${declared}, which resolves to ${target} and is not there`,
      );
    }
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

/* ---- and the iOS Info.plist says what the spec says --------------------- */

/* There are two of these and only one of them is read.
 *
 * XcodeGen *writes* `App/Info.plist` from `project.yml`'s `info.properties`,
 * so on the generated route the committed file is output. It is committed for
 * the build-it-by-hand route in `hosts/ios/README.md`, where it is the only
 * one — and a key that reached only the spec is then a key that build does not
 * have. That is not a compile error in either direction: `NSAppTransportSecurity`
 * went into the spec alone, and the hand-built app would have failed to reach
 * the dev server with no message saying why, because App Transport Security
 * blocks silently.
 */
const plist = readFileSync(resolve(root, "hosts/ios/App/Info.plist"), "utf8");
const properties = spec.match(/^ {6}properties:\n((?: {8}\S.*\n| {9,}.*\n|\n)*)/m);
assert.ok(properties, "project.yml still declares info.properties");

const declared = [...properties[1].matchAll(/^ {8}([A-Za-z][A-Za-z0-9]*):/gm)].map(([, key]) => key);
assert.ok(declared.length > 3, "and the keys under it are still being found");

for (const key of declared) {
  assert.ok(
    plist.includes(`<key>${key}</key>`),
    `project.yml declares ${key}, which App/Info.plist does not — the two are ` +
      `two spellings of one file and the hand-built app only gets the second`,
  );
}

console.log(
  `host build tests passed — ${checked} paths in ${BUILD_FILES.length} build files resolve, ` +
    `and ${declared.length} Info.plist keys are in both spellings of it`,
);
