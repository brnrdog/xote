/**
 * The conformance suite, against the reference host.
 *
 * Replaying it here does two things: it stops the reference host drifting from
 * the answers it recorded, and it means a case that is wrong fails in
 * JavaScript — where it can be debugged — rather than only in Xcode.
 *
 * `xote-native/hosts/ios/XoteNativeTests/XoteConformanceTests.swift` replays the same
 * JSON against the UIKit host.
 */

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { ReferenceHost } from "../src/host/reference.mjs";

const suite = JSON.parse(
  readFileSync(fileURLToPath(new URL("../conformance/suite.json", import.meta.url))),
);

const TOLERANCE = 0.5;
let frames = 0;

for (const { name, viewport, steps, expected } of suite) {
  const host = new ReferenceHost(viewport);
  steps.forEach((given, index) => {
    // `{batch}` is the app talking; `{platformPop}` is the platform. See
    // `conformance/generate.mjs`.
    if (given.batch !== undefined) host.apply(given.batch);
    else if (given.platformPop !== undefined) host.platformPop(given.platformPop);
    const want = expected[index];
    const step = `${name} step ${index}`;

    assert.deepEqual(host.structure(), want.structure, `${step}: tree`);
    assert.deepEqual(host.texts(), want.texts, `${step}: text`);
    // The *view* tree, which is not the node tree: a layout-only box is in one
    // and not the other. Two hosts that flatten differently draw the same
    // content into different surfaces, with different clipping and different
    // hit testing, and every frame still agrees — so this is the only place a
    // flattening disagreement shows up.
    assert.deepEqual(host.nativeTree(), want.views, `${step}: views`);

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

const views = suite.reduce(
  (sum, c) => sum + c.expected.reduce((s, e) => s + Object.keys(e.views).length, 0),
  0,
);

console.log(
  `conformance tests passed — ${suite.length} cases, ${frames} frames, ${views} views`,
);
