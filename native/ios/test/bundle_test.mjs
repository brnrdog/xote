/**
 * Runs the shipped bundle the way JavaScriptCore will.
 *
 * The Swift host cannot be compiled here, but the half that usually breaks can
 * be: a `vm` context is a fresh realm with the ECMAScript built-ins and nothing
 * else — no DOM, no `console`, no `setTimeout`, no module loader — which is
 * what an embedded `JSContext` looks like before Swift injects anything. If the
 * bundle runs here against nothing but `XoteHost`, it runs there.
 */

import assert from "node:assert/strict";
import vm from "node:vm";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const bundle = readFileSync(
  fileURLToPath(new URL("../XoteNative/Resources/xote-app.js", import.meta.url)),
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

assert.ok(
  mount.filter(([op]) => op === 8).length >= 3,
  "the host was asked to report presses",
);

// The counter's pressable: walk up from the text "Tap me" through the inserts.
const created = new Map(mount.filter(([op]) => op === 1 || op === 2).map(([, id, v]) => [id, v]));
const parents = new Map();
for (const [op, parent, child] of mount) if (op === 5) parents.set(child, parent);
let pressableId = parents.get([...created].find(([, value]) => value === "Tap me")[0]);
while (created.get(pressableId) !== "pressable") pressableId = parents.get(pressableId);

batches.length = 0;
const payload = JSON.stringify(JSON.stringify({ pageX: 4, pageY: 8 }));
vm.runInContext(`xoteDispatchEvent(${pressableId}, "press", ${payload})`, context);

assert.equal(batches.length, 1, "the press flushed before the call returned");
assert.deepEqual(
  batches[0].map(([op]) => op),
  [4],
  "and cost one setText",
);
assert.equal(batches[0][0][2], "Tapped 1x");

console.log(`iOS bundle tests passed — mount is ${mount.length} commands`);
