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

const suite = cases.map(({ name, viewport, steps }) => {
  const host = new ReferenceHost(viewport);
  const expected = steps.map((batch) => {
    host.apply(batch);
    return {
      structure: host.structure(),
      frames: host.frames(),
      texts: host.texts(),
      views: host.nativeTree(),
    };
  });
  return { name, viewport, steps, expected };
});

const path = fileURLToPath(new URL("./suite.json", import.meta.url));
writeFileSync(path, JSON.stringify(suite, null, 1) + "\n");

const boxes = suite.reduce(
  (sum, c) => sum + c.expected.reduce((s, e) => s + Object.keys(e.frames).length, 0),
  0,
);
console.log(`wrote ${path} — ${suite.length} cases, ${boxes} frames`);
