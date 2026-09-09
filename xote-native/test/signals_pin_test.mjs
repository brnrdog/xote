/**
 * A pin on the one Tier-2 change that is not ours to make.
 *
 * `rescript-signals` marks dependents dirty before it knows whether a value
 * changed. A computed's `~equals` stops the *notification*, but the flag has
 * already propagated, so an intermediate computed downstream recomputes and —
 * having no cutoff of its own, and returning a fresh array — notifies anyway.
 *
 * On the web that re-renders a region for nothing. Here it tears down and
 * rebuilds real views and runs a layout pass, so app authors have to know the
 * workaround: materialise the condition into a `Signal`, because `Signal.set`
 * does not notify when the value is unchanged and the flag never propagates.
 * `xote-native/example/CounterApp.res` does exactly that.
 *
 * These assertions describe the bug, not the desired behaviour. **When the
 * first one starts failing, upstream has fixed it** — at which point the
 * workaround in the example, and this file, can go.
 */

import assert from "node:assert/strict";
import * as Signal from "../../src/Signal.res.mjs";
import * as Computed from "../../src/Computed.res.mjs";
import * as Effect from "../../src/Effect.res.mjs";

/* ---- the bug ------------------------------------------------------------- */

{
  const count = Signal.make(0);
  const flag = Computed.make(() => Signal.get(count) >= 3, undefined, (a, b) => a === b);
  // Stands in for what `View.tracked` builds: a computed over the branch, with
  // no equality cutoff of its own, returning a fresh array each time.
  const children = Computed.make(() => (Signal.get(flag) ? ["hint"] : []));

  let renders = 0;
  Effect.run(() => {
    Signal.get(children);
    renders += 1;
    return undefined;
  });

  assert.equal(renders, 1);
  Signal.set(count, 1);
  assert.equal(renders, 2, "the region re-rendered even though the branch did not change");
  Signal.set(count, 2);
  assert.equal(renders, 3, "and again");
}

/* ---- one level of computed is cut off correctly -------------------------- */

{
  const count = Signal.make(0);
  const flag = Computed.make(() => Signal.get(count) >= 3, undefined, (a, b) => a === b);

  let runs = 0;
  Effect.run(() => {
    Signal.get(flag);
    runs += 1;
    return undefined;
  });

  Signal.set(count, 1);
  Signal.set(count, 2);
  assert.equal(runs, 1, "an effect reading the computed directly is cut off");
  Signal.set(count, 3);
  assert.equal(runs, 2, "and runs when the value really changes");
}

/* ---- the workaround ------------------------------------------------------ */

{
  const count = Signal.make(0);
  const flag = Signal.make(false);
  Effect.run(() => {
    Signal.set(flag, Signal.get(count) >= 3);
    return undefined;
  });
  const children = Computed.make(() => (Signal.get(flag) ? ["hint"] : []));

  let renders = 0;
  Effect.run(() => {
    Signal.get(children);
    renders += 1;
    return undefined;
  });

  Signal.set(count, 1);
  Signal.set(count, 2);
  assert.equal(renders, 1, "materialising the condition keeps the region untouched");
  Signal.set(count, 3);
  assert.equal(renders, 2, "and rebuilds it exactly when the branch flips");
  Signal.set(count, 4);
  assert.equal(renders, 2, "once");
}

console.log("signals pin passed — the upstream dirty-flag behaviour is unchanged");
