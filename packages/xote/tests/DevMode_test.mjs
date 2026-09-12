/* The development-only diagnostics in View — the hidden-read probe and the
 * unrenderable-child warning — are gated on a flag that is read once and cached
 * for the process. That cache is why this lives in its own file rather than in
 * the main suite: `Tests.res.mjs` exercises both diagnostics, so by the time it
 * finishes the flag is already resolved to "development" and the production
 * path can no longer be observed in that process.
 *
 * Run with __XOTE_DEV__ = false and assert the quiet path: no console output,
 * and — the part that actually matters — the same rendered node either way. A
 * gate that silenced the warning by also changing what renders would be a much
 * worse bug than the noise it was meant to remove. */
import assert from "node:assert/strict";

globalThis.__XOTE_DEV__ = false;

const View = await import("../src/View.res.mjs");
const Signal = await import("../src/Signal.res.mjs");

const warnings = [];
const realWarn = console.warn;
console.warn = (...args) => warnings.push(args.join(" "));

/* Unrenderable child: a record is neither node, signal, array, thunk nor
   scalar, so it is stringified. In production that happens silently. */
const unrenderable = View.child({ name: "Ada" });

/* Hidden read: a call the ppx could not resolve that does read a signal. In
   development View.probe reports it; in production it must not even allocate
   the throwaway computed used to detect it. */
const hidden = Signal.make("tone-a");
const probed = View.probe("DevMode_test.mjs:0:0", () => Signal.get(hidden));

console.warn = realWarn;

assert.deepEqual(warnings, [], `expected no console output in production, got:\n${warnings.join("\n")}`);

/* Behaviour is identical to development — only the diagnostics are gone. */
assert.equal(unrenderable.TAG, "Text");
assert.equal(unrenderable._0, "[object Object]");
assert.equal(probed, "tone-a");

console.log("dev-mode gating tests passed");
