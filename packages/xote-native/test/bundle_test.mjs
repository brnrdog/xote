/**
 * Runs the shipped bundle the way an embedded engine will.
 *
 * Neither host can be compiled here, but the half that usually breaks can be: a
 * `vm` context is a fresh realm with the ECMAScript built-ins and nothing else
 * — no DOM, no `console`, no `setTimeout`, no module loader — which is what an
 * embedded JavaScriptCore, QuickJS or Hermes looks like before the platform
 * injects anything. If the bundle runs here against nothing but `XoteHost`, it
 * runs there.
 *
 * There is one bundle for both platforms, so this is one test for both.
 */

import assert from "node:assert/strict";
import vm from "node:vm";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const bundle = readFileSync(
  fileURLToPath(new URL("../bundle/dist/xote-app.js", import.meta.url)),
  "utf8",
);

const batches = [];
const context = vm.createContext({
  // The single host object Swift installs. Nothing else exists.
  XoteHost: { apply: (json) => batches.push(JSON.parse(json)) },
});

// A `vm` realm still gets Node's `console` and timers. Strip them, so a
// dependency creeping in fails here rather than in Xcode.
vm.runInContext(
  "delete globalThis.console; delete globalThis.setTimeout; delete globalThis.setInterval; delete globalThis.queueMicrotask;",
  context,
);
for (const absent of ["console", "setTimeout", "queueMicrotask", "process", "document"]) {
  assert.equal(vm.runInContext(`typeof ${absent}`, context), "undefined", `${absent} is absent`);
}

vm.runInContext(bundle, context, { filename: "xote-app.js" });

assert.equal(vm.runInContext("typeof xoteStart", context), "function");
assert.equal(vm.runInContext("typeof xoteDispatchEvent", context), "function");
assert.equal(batches.length, 0, "nothing crosses the bridge before start");

vm.runInContext("xoteStart()", context);

assert.equal(batches.length, 1, "start produces exactly one batch");
const mount = batches[0];
assert.ok(mount.length > 50, `the screen mounted in ${mount.length} commands`);
assert.deepEqual(mount[0], [1, 1, "root"], "the root is the first thing the host hears about");

// Commands have to survive JSON round-tripping — this is the real wire format,
// and a style must arrive as an object, not a stringified one.
const styles = mount.filter(([op, , key]) => op === 3 && key === "style");
assert.ok(styles.length > 0, "styles crossed");
assert.equal(typeof styles[0][3], "object");
assert.equal(styles[0][3].flex, 1);

// Every command is a flat array with the opcode first, which is what keeps the
// Swift decoder a dozen lines instead of a parser.
for (const command of mount) {
  assert.ok(Array.isArray(command), "a command is an array");
  assert.equal(typeof command[0], "number", "opcode first");
}

/* ---- an event comes back the same way ------------------------------------ */

// Deliberately app-agnostic: this file is about the bundle running in a bare
// realm and the two globals working, not about which example was built into
// it. `XOTE_APP` chooses that at build time.
const listens = mount.filter(([op]) => op === 8);
assert.ok(listens.length > 0, "the app asked the host to report at least one event");

// A press needs no payload; a scroll does, and sending it an empty one is a
// test bug rather than an interesting case.
const press = listens.find(([, , name]) => name === "press") ?? listens[0];
const [, listenerId, eventName] = press;
batches.length = 0;
vm.runInContext(`xoteDispatchEvent(${listenerId}, ${JSON.stringify(eventName)}, "{}")`, context);

assert.ok(batches.length <= 1, "an event produces at most one batch");
if (batches.length === 1) {
  assert.ok(batches[0].length > 0, "and the batch it produced is not empty");
  for (const command of batches[0]) {
    assert.ok(Array.isArray(command) && typeof command[0] === "number");
  }
}

/* ---- a realm that already has a DOM ---------------------------------------
 *
 * The other kind of engine. Android has none in the platform API, so the host
 * ships `WebViewRuntime`, which evaluates in a page realm — and there
 * `Window.document` is unforgeable, so the shadow document cannot be installed
 * by assigning the global and the app would never start.
 *
 * `XoteBridge.start` wraps the bundle in a scope that shadows `document`
 * instead. The wrapper is lifted out of the Kotlin rather than restated here,
 * because a copy would be free to drift from the one that actually runs.
 */

const QUOTES = '"'.repeat(3);

function kotlinRawString(source, name) {
  const start = source.indexOf(`val ${name} = `);
  assert.notEqual(start, -1, `${name} is declared in XoteBridge.kt`);
  const open = source.indexOf(QUOTES, start);
  if (open === -1 || open > source.indexOf("\n", start)) {
    // A plain one-line literal: `val NAME = "…"`.
    const line = source.slice(start).split("\n")[0];
    return JSON.parse(line.slice(line.indexOf('"')));
  }
  const body = source.slice(open + 3, source.indexOf(QUOTES, open + 3));
  // Kotlin's `trimIndent`: drop a blank first and last line, then take off the
  // indent the rest have in common.
  const lines = body.split("\n");
  if (lines[0].trim() === "") lines.shift();
  if (lines.length > 0 && lines[lines.length - 1].trim() === "") lines.pop();
  const indent = Math.min(
    ...lines.filter((l) => l.trim() !== "").map((l) => l.length - l.trimStart().length),
  );
  return lines.map((l) => l.slice(indent)).join("\n");
}

const bridgeKt = readFileSync(
  fileURLToPath(
    new URL("../hosts/android/app/src/main/java/dev/xote/host/XoteBridge.kt", import.meta.url),
  ),
  "utf8",
);
const prologue = kotlinRawString(bridgeKt, "SHADOW_PROLOGUE") + "\n";
const epilogue = kotlinRawString(bridgeKt, "SHADOW_EPILOGUE");

assert.match(prologue, /xoteBindDocument/, "the prologue is the one that binds the document");
assert.ok(
  bridgeKt.includes("SHADOW_PROLOGUE + bundle + SHADOW_EPILOGUE"),
  "and it is what `start` actually evaluates",
);

/** A realm whose `document` is an own getter that cannot be redefined, which
 is all of a browser window that matters here. */
function pageRealm() {
  const batches = [];
  const context = vm.createContext({
    XoteHost: { apply: (json) => batches.push(JSON.parse(json)) },
  });
  vm.runInContext(
    "delete globalThis.console; delete globalThis.setTimeout; delete globalThis.setInterval;" +
      " delete globalThis.queueMicrotask;" +
      " const pageDocument = { nodeType: 9 };" +
      " Object.defineProperty(globalThis, 'document', {" +
      "   get: () => pageDocument, configurable: false });",
    context,
  );
  return { context, batches };
}

{
  const { context } = pageRealm();
  vm.runInContext("globalThis.document = { nodeType: 1 }", context);
  assert.equal(
    vm.runInContext("document.nodeType", context),
    9,
    "the realm's `document` really cannot be replaced by assigning the global",
  );
}

{
  // Unwrapped, the bundle has no way to install its shadow document here, and
  // it says so rather than rendering into a DOM that is not the one it thinks.
  // `install` runs as the bundle evaluates, so this is where it gives up —
  // before `xoteStart` is ever defined.
  const { context, batches } = pageRealm();
  assert.throws(
    () => vm.runInContext(bundle, context, { filename: "xote-app.js" }),
    /shadow document/,
    "the bundle refuses to install into a realm whose `document` is unforgeable",
  );
  assert.equal(vm.runInContext("typeof xoteStart", context), "undefined");
  assert.equal(batches.length, 0, "and nothing crossed the bridge");
}

const { context: page, batches: pageBatches } = pageRealm();
vm.runInContext(prologue + bundle + epilogue, page, { filename: "xote-app.js" });
assert.equal(vm.runInContext("typeof xoteStart", page), "function", "the wrapper keeps the globals");
assert.equal(vm.runInContext("typeof xoteDispatchEvent", page), "function");

vm.runInContext("xoteStart()", page);
assert.equal(pageBatches.length, 1, "the app started in a realm that already had a document");
assert.deepEqual(pageBatches[0][0], [1, 1, "root"]);
assert.equal(
  vm.runInContext("document.nodeType", page),
  9,
  "and the realm's own `document` was shadowed, not replaced",
);

console.log(
  `bundle tests passed — mount is ${mount.length} commands, ${listens.length} listeners,` +
    ` and the shadowing wrapper starts the same app in a realm that has a DOM`,
);
