/**
 * What happens when something goes wrong.
 *
 * A native app is one long-lived process with a screen on it, so the failure
 * mode that matters is not "the error was reported" but "everything that had
 * nothing to do with the error kept working". These assert exactly that.
 */

import assert from "node:assert/strict";
import { install } from "../src/host/runtime.mjs";
import { HeadlessHost } from "../src/host/headless.mjs";
import { OP_NAME } from "../src/host/protocol.mjs";

const host = new HeadlessHost();
const errors = [];
const runtime = install(host, {
  autoFlush: false,
  onError: (what, error) => errors.push(`${what}: ${error.message}`),
});

const NativeApp = await import("../src/NativeApp.res.mjs");
const View = await import("xote/src/View.res.mjs");
const Signal = await import("xote/src/Signal.res.mjs");

/* ---- a handler that throws does not take its siblings with it ------------ */

const label = Signal.make("before");
let secondRan = false;
let thirdRan = false;

const button = View.element(
  "pressable",
  [],
  [
    ["press", () => { throw new Error("first handler is broken"); }],
    ["press", () => {
      secondRan = true;
      Signal.set(label, "after");
    }],
    ["press", () => {
      thirdRan = true;
    }],
  ],
  [View.element("text", [], [], [View.signalText(() => Signal.get(label))], undefined)],
  undefined,
);

NativeApp.mount(button, "root");
runtime.flush();

const findText = () => {
  for (const view of host.views.values()) {
    if (view.type === "#text" && view.text !== undefined) return view;
  }
  return null;
};
assert.equal(findText().text, "before");

const pressable = [...host.views.values()].find((v) => v.type === "pressable");
host.clearLog();
runtime.dispatchEvent(pressable.id, "press", {});

assert.equal(errors.length, 1, "the failure was reported once");
assert.match(errors[0], /handling press: first handler is broken/);
assert.ok(secondRan, "the handler after the broken one still ran");
assert.ok(thirdRan, "and so did the one after that");
assert.deepEqual(
  host.log.map((command) => OP_NAME[command[0]]),
  ["setText"],
  "and the work the surviving handlers did still crossed the bridge",
);
assert.equal(findText().text, "after");

/* ---- a host that throws does not wedge the bridge ------------------------ */

const received = [];
const flakyErrors = [];
let failNext = true;
const flakyRuntime = install(
  {
    apply: (batch) => {
      if (failNext) {
        failNext = false;
        throw new Error("host is unhappy");
      }
      received.push(batch);
    },
  },
  { autoFlush: false, onError: (what, error) => flakyErrors.push(`${what}: ${error.message}`) },
);

const counter = Signal.make(0);
NativeApp.mount(
  View.element(
    "view",
    [],
    [],
    [View.signalText(() => String(Signal.get(counter)))],
    undefined,
  ),
  "second",
);
flakyRuntime.flush();

assert.equal(flakyErrors.length, 1, "the host's failure was reported");
assert.match(flakyErrors[0], /applying a batch: host is unhappy/);
assert.equal(received.length, 0, "and that batch was lost, as a lost batch is");

// The next update still reaches the host: a batch is cleared before the host
// sees it, so a failing host is never handed the same one twice and the
// bridge is not left permanently jammed behind it.
Signal.set(counter, 7);
flakyRuntime.flush();

assert.equal(received.length, 1, "the bridge kept delivering");
assert.equal(flakyErrors.length, 1, "with no further failures");
assert.deepEqual(
  received[0].map((command) => OP_NAME[command[0]]),
  ["setText"],
  "and delivered exactly the update that followed",
);

console.log("resilience tests passed");
