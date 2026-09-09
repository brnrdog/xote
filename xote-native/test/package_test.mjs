#!/usr/bin/env node
/**
 * `xote-native` as a package someone else installs.
 *
 * Compiling inside this repository proves less than it looks like it does: the
 * `xote` next door is reachable by a symlink this repository created, and a
 * downstream app has no such arrangement. So this stages both packages into a
 * temporary `node_modules` exactly as `npm install` would lay them out, and
 * compiles an app against them:
 *
 *   node_modules/xote            the publishable files, as `files` lists them
 *   node_modules/xote-native     the same, from this package
 *   fixture/                     a native screen that imports from both
 *
 * It is the same machinery as `scripts/consumer-boundary-test.mjs` in `xote`,
 * which proves the one-package version of this arrangement. What is new is the
 * second package, and the three things that only go wrong with two: the
 * namespace changes, the imports become bare specifiers, and the JSX module has
 * to resolve across a package boundary.
 *
 * This file used to *synthesise* `xote-native` from a directory inside `xote`,
 * because there was no such package. There is now, so it stages the real one —
 * which means what it checks is what would ship.
 */

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(packageRoot, "..");
const rescriptBin = join(repoRoot, "node_modules", ".bin", "rescript");

/** Dependencies both staged packages and the fixture resolve against. */
const LINKED_DEPS = ["rescript", "rescript-signals", "@rescript"];

/** Compiled output and lockfiles are not part of a published surface. */
const withoutBuildOutput = (src) =>
  !src.includes(`${"/"}lib${"/"}`) &&
  !src.endsWith("/lib") &&
  !src.includes("node_modules");

const staging = mkdtempSync(join(tmpdir(), "xote-native-package-"));
const modules = join(staging, "node_modules");

function stage(name, from, entries) {
  const dir = join(modules, name);
  mkdirSync(dir, { recursive: true });
  for (const entry of entries) {
    cpSync(join(from, entry), join(dir, entry), {
      recursive: true,
      filter: withoutBuildOutput,
    });
  }
  return dir;
}

function stageFixture() {
  const dir = join(staging, "fixture");
  mkdirSync(join(dir, "src"), { recursive: true });
  cpSync(
    join(packageRoot, "test", "__fixtures__", "package", "NativeFixture.res"),
    join(dir, "src", "NativeFixture.res"),
  );
  writeFileSync(
    join(dir, "rescript.json"),
    JSON.stringify(
      {
        name: "xote-native-fixture",
        sources: [{ dir: "src", subdirs: false }],
        "package-specs": { module: "esmodule", "in-source": true },
        suffix: ".res.mjs",
        dependencies: ["rescript-signals", "xote", "xote-native"],
        // The JSX module switch, across a package boundary. `NativeJSX` is
        // reachable because `XoteNative` is opened below — the same arrangement
        // `xote`'s own `tests/consumer` uses for `XoteJSX` and `Xote`.
        jsx: { version: 4, module: "NativeJSX" },
        "compiler-flags": ["-open Xote", "-open XoteNative"],
      },
      null,
      2,
    ) + "\n",
  );
  symlinkSync(modules, join(dir, "node_modules"));
  return dir;
}

mkdirSync(modules, { recursive: true });
stage("xote", repoRoot, ["src", "rescript.json", "package.json"]);
const nativePackage = stage("xote-native", packageRoot, [
  "src",
  "rescript.json",
  "package.json",
]);
const fixture = stageFixture();

for (const dep of LINKED_DEPS) {
  const target = join(repoRoot, "node_modules", dep);
  if (!existsSync(target)) throw new Error(`missing dependency ${dep} — run npm install first`);
  const link = join(modules, dep);
  mkdirSync(dirname(link), { recursive: true });
  symlinkSync(target, link);
}

/* ---- the arrangement the package commits to ------------------------------- */

const nativeConfig = JSON.parse(readFileSync(join(nativePackage, "rescript.json"), "utf8"));

// Every module in this package refers to `View`, `Signal`, `Computed`, `Effect`,
// `XoteJSX` and `MaybeSignal` unqualified. Inside `xote` the namespace put them
// in scope; from here they are `Xote.View`, and without this flag the build
// fails on the first line of `NativeProp`.
assert.ok(
  (nativeConfig["compiler-flags"] ?? []).includes("-open Xote"),
  "xote-native must compile with -open Xote, or none of its modules resolve",
);

// `NativeApp.res` reaches the runtime through `@module("./host/runtime.mjs")`,
// a path relative to the emitted `.res.mjs`. `host/` therefore has to live
// *inside* the source directory; at the package root it would need an extra
// `../` on every such external.
assert.ok(
  existsSync(join(nativePackage, "src", "host", "runtime.mjs")),
  "the host runtime is not where the emitted externals look for it",
);

/* ---- build ---------------------------------------------------------------- */

let output = "";
let built = true;
try {
  output = execFileSync(rescriptBin, ["build"], {
    cwd: fixture,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
} catch (error) {
  built = false;
  output = `${error.stdout ?? ""}${error.stderr ?? ""}`;
}

if (!built) {
  process.stdout.write(output + "\n");
  rmSync(staging, { recursive: true, force: true });
  assert.fail("a downstream app could not compile against xote and xote-native");
}

/* ---- what the build proves ------------------------------------------------ */

const emitted = readFileSync(join(fixture, "src", "NativeFixture.res.mjs"), "utf8");

assert.match(emitted, /NativeJSX\$XoteNative/, "the fixture does not use the native JSX module");
assert.match(emitted, /NativeList\$XoteNative/, "the fixture does not use the native list");

// `NativeStyle` is deliberately absent from the emitted code, and that is worth
// asserting rather than merely tolerating: `make` and `pt` are `%identity`, so a
// style is an object literal at the call site and the module disappears at
// compile time. A style costs nothing at runtime and crosses the bridge as the
// object the app wrote.
assert.doesNotMatch(emitted, /NativeStyle\$XoteNative/, "NativeStyle stopped being erased");
assert.match(emitted, /style: \{\s*flex: 1/, "a style did not survive as an object literal");

const specifiers = [...emitted.matchAll(/from "([^"]+)"/g)].map((match) => match[1]);
const intoXote = specifiers.filter((s) => s.startsWith("xote/"));
const intoNative = specifiers.filter((s) => s.startsWith("xote-native/"));
assert.ok(intoXote.length > 0, `nothing imported from xote — specifiers were ${specifiers}`);
assert.ok(intoNative.length > 0, `nothing imported from xote-native — ${specifiers}`);
for (const specifier of specifiers) {
  assert.ok(!specifier.startsWith("."), `a relative import survived into an app: ${specifier}`);
}

/**
 * Every path either package reaches into the other for has to be one the
 * published `exports` map actually serves, or the app resolves at compile time
 * and fails at run time.
 */
const servedBy = (pkgDir, specifier, name) => {
  const map = JSON.parse(readFileSync(join(pkgDir, "package.json"), "utf8")).exports;
  const subpath = "." + specifier.slice(name.length);
  assert.ok(
    map[subpath] !== undefined,
    `${specifier} is imported, and ${name}'s exports map does not serve ${subpath}`,
  );
};

for (const specifier of intoXote) servedBy(join(modules, "xote"), specifier, "xote");
for (const specifier of intoNative) servedBy(nativePackage, specifier, "xote-native");

// The same for `xote-native`'s own emitted output: its modules import `xote` by
// bare specifier too, and those matter most, because they are in the published
// package rather than in the app.
const nativeSrc = join(nativePackage, "src");
const nativeSpecifiers = new Set();
for (const file of readdirSync(nativeSrc).filter((f) => f.endsWith(".res.mjs"))) {
  for (const match of readFileSync(join(nativeSrc, file), "utf8").matchAll(/from "([^"]+)"/g)) {
    nativeSpecifiers.add(match[1]);
  }
}
const nativeIntoXote = [...nativeSpecifiers].filter((s) => s.startsWith("xote/"));
assert.ok(nativeIntoXote.length > 0, "xote-native compiled without importing xote at all");
for (const specifier of nativeIntoXote) servedBy(join(modules, "xote"), specifier, "xote");

const reached = new Set([...intoXote, ...nativeIntoXote].map((s) => s.slice("xote/".length)));

rmSync(staging, { recursive: true, force: true });

console.log(
  `package tests passed — a downstream app compiled against xote and xote-native as two ` +
    `installed packages, reaching ${reached.size} modules of xote through its exports map ` +
    `(${[...reached].sort().join(", ")})`,
);
