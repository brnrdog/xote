/**
 * The conformance suite, against the reference host.
 *
 * Replaying it here does two things: it stops the reference host drifting from
 * the answers it recorded, and it means a case that is wrong fails in
 * JavaScript — where it can be debugged — rather than only in Xcode.
 *
 * `native/ios/XoteNativeTests/XoteConformanceTests.swift` replays the same
 * JSON against the UIKit host.
 */

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { ReferenceHost } from "../host/reference.mjs";

const suite = JSON.parse(
  readFileSync(fileURLToPath(new URL("../conformance/suite.json", import.meta.url))),
);

const TOLERANCE = 0.5;
let frames = 0;

for (const { name, viewport, steps, expected } of suite) {
  const host = new ReferenceHost(viewport);
  steps.forEach((batch, index) => {
    host.apply(batch);
    const want = expected[index];
    const step = `${name} step ${index}`;

    assert.deepEqual(host.structure(), want.structure, `${step}: tree`);
    assert.deepEqual(host.texts(), want.texts, `${step}: text`);

    const got = host.frames();
    assert.deepEqual(Object.keys(got).sort(), Object.keys(want.frames).sort(), `${step}: boxes`);
    for (const [id, frame] of Object.entries(want.frames)) {
      frames += 1;
      for (let axis = 0; axis < 4; axis++) {
        assert.ok(
          Math.abs(got[id][axis] - frame[axis]) <= TOLERANCE,
          `${step}: node ${id} frame ${JSON.stringify(got[id])} should be ${JSON.stringify(frame)}`,
        );
      }
    }
  });
}

console.log(`conformance tests passed — ${suite.length} cases, ${frames} frames`);
