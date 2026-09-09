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

console.log(
  `bundle tests passed — mount is ${mount.length} commands, ${listens.length} listeners`,
);
