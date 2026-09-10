/**
 * Records what a correct host ends up with, for every case in `cases.mjs`.
 *
 *   node xote-native/conformance/generate.mjs
 *
 * The answers come from the reference host, whose layout is itself checked
 * against Chromium — so this is recording a verified result, not blessing
 * whatever the code happens to do today. Re-run it when a case changes, and
 * read the diff: an unexplained change to a frame is the point of the file.
 */

import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cases } from "./cases.mjs";
import { ReferenceHost } from "../src/host/reference.mjs";

/**
 * A step is one thing that happens to a host, and not all of them are batches.
 *
 * `{batch}` is the app talking. `{platformPop}` is the platform talking — a
 * back swipe on iOS, the back button on Android — which is the one change a
 * host makes on its own, and therefore the one worth checking hardest that
 * every host makes the same way. A case writes a bare array for a batch and the
 * builder's `pop()` for the other; both are normalised here so the JSON has one
 * shape and each host has one decoder.
 */
const asStep = (step) => (Array.isArray(step) ? { batch: step } : step);

const suite = cases.map(({ name, viewport, steps }) => {
  const host = new ReferenceHost(viewport);
  const normalised = steps.map(asStep);
  const expected = normalised.map((step) => {
    if (step.batch !== undefined) host.apply(step.batch);
    else if (step.platformPop !== undefined) host.platformPop(step.platformPop);
    return {
      structure: host.structure(),
      frames: host.frames(),
      texts: host.texts(),
      views: host.nativeTree(),
    };
  });
  return { name, viewport, steps: normalised, expected };
});

const path = fileURLToPath(new URL("./suite.json", import.meta.url));
writeFileSync(path, JSON.stringify(suite, null, 1) + "\n");

const boxes = suite.reduce(
  (sum, c) => sum + c.expected.reduce((s, e) => s + Object.keys(e.frames).length, 0),
  0,
);
console.log(`wrote ${path} — ${suite.length} cases, ${boxes} frames`);
