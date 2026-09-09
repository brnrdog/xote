#!/usr/bin/env node
/**
 * Can `xote-native` be its own package?
 *
 * `native/` compiles today as a dev source directory of `xote`, which means its
 * modules are namespaced `$Xote` and import `../src/View.res.mjs` by relative
 * path. Neither of those survives an extraction, and neither of them is
 * exercised by any other test here — the question "would this work as a
 * separate package" has, until now, only had an argument for an answer.
 *
 * So this stages both packages into a temporary `node_modules` and compiles a
 * downstream app against them:
 *
 *   node_modules/xote            the publishable files, exactly as `files` lists them
 *   node_modules/xote-native     the modules from `native/`, with a rescript.json
 *                                naming `xote` as a dependency
 *   fixture/                     a native screen that imports from both
 *
 * It is the same machinery as `scripts/consumer-boundary-test.mjs`, which
 * already proves the one-package version of this arrangement. What is new is
 * the second package, and the three things that only go wrong with two:
 * the namespace changes, the imports become bare specifiers, and the JSX module
 * has to resolve across a package boundary.
 *
 * **Nothing is moved.** `native/` stays where it is; this copies. The point is
 * to find the problems before the extraction, not to perform it.
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

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const nativeRoot = join(repoRoot, "native");
const rescriptBin = join(repoRoot, "node_modules", ".bin", "rescript");

/* The seven modules that would move. Listed rather than globbed, so adding an
   eighth is a deliberate act that shows up in this file. */
const MODULES = [
  "NativeStyle",
  "NativeProp",
  "NativeEvent",
  "NativeJSX",
  "Native",
  "NativeList",
  "NativeApp",
];

const LINKED_DEPS = ["rescript", "rescript-signals", "@rescript"];

/* ---- staging -------------------------------------------------------------- */

const staging = mkdtempSync(join(tmpdir(), "xote-native-package-"));
const modules = join(staging, "node_modules");

function stageXote() {
  const dir = join(modules, "xote");
  mkdirSync(dir, { recursive: true });
  for (const entry of ["src", "rescript.json", "package.json"]) {
    cpSync(join(repoRoot, entry), join(dir, entry), {
      recursive: true,
      filter: (src) => !src.includes(`${"/"}lib${"/"}`) && !src.endsWith("/lib"),
    });
  }
}

/**
 * `xote-native`, assembled from `native/` with no edits to any source file.
 *
 * The layout matters and is the first real finding: `NativeApp.res` reaches the
 * runtime through `@module("./host/runtime.mjs")`, a path relative to the
 * emitted `.res.mjs`. Keeping `host/` *inside* the source directory rather than
 * beside it means that external is already correct and no source has to change.
 * Put `host/` at the package root instead and every one of those externals
 * needs an extra `../`.
 */
function stageXoteNative() {
  const dir = join(modules, "xote-native");
  const src = join(dir, "src");
  mkdirSync(src, { recursive: true });

  for (const name of MODULES) {
    cpSync(join(nativeRoot, `${name}.res`), join(src, `${name}.res`));
  }
  cpSync(join(nativeRoot, "host"), join(src, "host"), { recursive: true });

  writeFileSync(
    join(dir, "rescript.json"),
    JSON.stringify(
      {
        name: "xote-native",
        namespace: true,
        sources: [{ dir: "src", subdirs: false }],
        "package-specs": { module: "esmodule", "in-source": true },
        suffix: ".res.mjs",
        // `xote` is a dependency, not a peer, as far as ReScript is concerned:
        // it has to be able to find and compile it.
        dependencies: ["rescript-signals", "xote"],
        // The second real finding, and the reason this test exists. Inside
        // `xote`, `native/` is a dev source directory, so the namespace puts
        // `View`, `Signal`, `Computed`, `Effect`, `XoteJSX` and `MaybeSignal`
        // directly in scope and every one of the seven modules refers to them
        // unqualified. From its own package they are `Xote.View` and so on, and
        // the build fails on the first line of `NativeProp`.
        //
        // `-open Xote` fixes it with no source changes, and it is what
        // `tests/consumer` already does. The alternative — qualifying several
        // hundred references — buys nothing.
        "compiler-flags": ["-open Xote"],
      },
      null,
      2,
    ) + "\n",
  );

  writeFileSync(
    join(dir, "package.json"),
    JSON.stringify(
      {
        name: "xote-native",
        version: "0.0.0",
        type: "module",
        peerDependencies: { xote: "*" },
        files: ["src", "rescript.json", "package.json"],
        exports: {
          "./package.json": "./package.json",
          "./rescript.json": "./rescript.json",
          ...Object.fromEntries(
            MODULES.map((name) => [`./src/${name}.res.mjs`, `./src/${name}.res.mjs`]),
          ),
          "./host/*": "./src/host/*",
        },
      },
      null,
      2,
    ) + "\n",
  );

  return dir;
}

function stageFixture() {
  const dir = join(staging, "fixture");
  mkdirSync(join(dir, "src"), { recursive: true });
  cpSync(
    join(nativeRoot, "test", "__fixtures__", "package", "NativeFixture.res"),
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
        // `tests/consumer` uses for `XoteJSX` and `Xote`.
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

function linkDeps() {
  for (const dep of LINKED_DEPS) {
    const target = join(repoRoot, "node_modules", dep);
    if (!existsSync(target)) throw new Error(`missing dependency ${dep} — run npm install first`);
    const link = join(modules, dep);
    mkdirSync(dirname(link), { recursive: true });
    symlinkSync(target, link);
  }
}

mkdirSync(modules, { recursive: true });
stageXote();
const nativePackage = stageXoteNative();
const fixture = stageFixture();
linkDeps();

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
  assert.fail("a downstream app could not compile against xote and xote-native as two packages");
}

/* ---- what the build proves ------------------------------------------------ */

const emitted = readFileSync(join(fixture, "src", "NativeFixture.res.mjs"), "utf8");

// The namespace really does change. Today these modules compile as
// `NativeJSX$Xote`; out of their own package they are `NativeJSX$XoteNative`,
// and every import in the app follows.
assert.match(emitted, /NativeJSX\$XoteNative/, "the fixture does not use the native JSX module");
assert.match(emitted, /NativeList\$XoteNative/, "the fixture does not use the native list");

// `NativeStyle` is deliberately absent from the emitted code, and that is worth
// asserting rather than merely tolerating: `make` and `pt` are `%identity`, so a
// style is an object literal at the call site and the module disappears at
// compile time. A style costs nothing at runtime and crosses the bridge as the
// object the app wrote.
assert.doesNotMatch(emitted, /NativeStyle\$XoteNative/, "NativeStyle stopped being erased");
assert.match(emitted, /style: \{\s*flex: 1/, "a style did not survive as an object literal");

// And the imports become bare specifiers into `xote`, which is what the
// `exports` map in `package.json` already serves. This is the assertion that
// says no change to `xote` is needed.
const specifiers = [...emitted.matchAll(/from "([^"]+)"/g)].map((match) => match[1]);
const intoXote = specifiers.filter((s) => s.startsWith("xote/"));
const intoNative = specifiers.filter((s) => s.startsWith("xote-native/"));
assert.ok(intoXote.length > 0, `nothing imported from xote — specifiers were ${specifiers}`);
assert.ok(intoNative.length > 0, `nothing imported from xote-native — specifiers were ${specifiers}`);
for (const specifier of specifiers) {
  assert.ok(
    !specifier.startsWith("."),
    `a relative import survived into a downstream app: ${specifier}`,
  );
}

// Every path the emitted code reaches into `xote` for has to be one the
// published `exports` map actually serves, or the app resolves at compile time
// and fails at run time.
const xotePackage = JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8"));
for (const specifier of intoXote) {
  const subpath = "." + specifier.slice("xote".length);
  assert.ok(
    xotePackage.exports[subpath] !== undefined,
    `the fixture imports ${specifier}, which xote's package.json exports map does not serve`,
  );
}

// The same for `xote-native`'s own emitted output: its modules import `xote` by
// bare specifier too, and those are the ones that matter most, because they are
// in the published package rather than in the app.
const nativeSrc = join(nativePackage, "src");
const nativeSpecifiers = new Set();
for (const file of readdirSync(nativeSrc).filter((f) => f.endsWith(".res.mjs"))) {
  for (const match of readFileSync(join(nativeSrc, file), "utf8").matchAll(/from "([^"]+)"/g)) {
    nativeSpecifiers.add(match[1]);
  }
}
const nativeIntoXote = [...nativeSpecifiers].filter((s) => s.startsWith("xote/"));
assert.ok(nativeIntoXote.length > 0, "xote-native compiled without importing xote at all");
for (const specifier of nativeIntoXote) {
  const subpath = "." + specifier.slice("xote".length);
  assert.ok(
    xotePackage.exports[subpath] !== undefined,
    `xote-native imports ${specifier}, which xote's package.json exports map does not serve`,
  );
}

// `@module("./host/runtime.mjs")` has to still point at something. This is the
// layout finding: `host/` travels inside `src/`, so the external is unchanged.
assert.ok(
  existsSync(join(nativeSrc, "host", "runtime.mjs")),
  "the host runtime is not where the emitted externals look for it",
);
const nativeApp = readFileSync(join(nativeSrc, "NativeApp.res.mjs"), "utf8");
assert.match(nativeApp, /from "\.\/host\/runtime\.mjs"/, "NativeApp lost its runtime import");

const served = new Set([...intoXote, ...nativeIntoXote].map((s) => s.slice("xote/".length)));

rmSync(staging, { recursive: true, force: true });

console.log(
  `package tests passed — a downstream app compiled against xote and xote-native as two ` +
    `packages, reaching ${served.size} modules of xote through its exports map ` +
    `(${[...served].sort().join(", ")})`,
);
