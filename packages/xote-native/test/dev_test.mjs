/**
 * The dev loop, driven the way a device drives it.
 *
 * This connects to a real dev server over real HTTP and plays the part of the
 * phone: read newline-delimited JSON, apply the batches to a `ReferenceHost`,
 * POST an event back. The host is the same one the conformance suite compares
 * real hosts against, so "the screen is right" means the same thing here as it
 * does there.
 *
 * The assertions worth having are the two ends of the loop: **an event I send
 * changes the screen I am shown**, and **a saved file gets me a new app with
 * the screen rebuilt from nothing**. Everything else about a dev server is
 * plumbing that fails loudly.
 */

import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { ReferenceHost } from "../src/host/reference.mjs";

const packageRoot = fileURLToPath(new URL("..", import.meta.url));
const serverPath = fileURLToPath(new URL("../dev/server.mjs", import.meta.url));
const PORT = 8123;
const BASE = `http://127.0.0.1:${PORT}`;

/** The file the reload test edits, and its contents, to be put back. */
const TOUCHED = fileURLToPath(new URL("../example/CounterApp.res.mjs", import.meta.url));
const ORIGINAL = readFileSync(TOUCHED, "utf8");

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Wait until `predicate()` holds, or give up with something readable.
 *
 * The result is awaited, because half these predicates are `fetch` calls and a
 * pending promise is truthy — a version of this that did not await passed
 * instantly and then read from a response that had not arrived. */
async function until(predicate, what, timeout = 15000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (await predicate()) return;
    await sleep(25);
  }
  assert.fail(`timed out waiting for ${what}`);
}

const server = spawn(process.execPath, [serverPath], {
  cwd: packageRoot,
  stdio: ["ignore", "ignore", "inherit"],
  env: { ...process.env, XOTE_APP: "counter", XOTE_DEV_PORT: String(PORT) },
});

let host = new ReferenceHost({ width: 320, height: 640 });
let resets = 0;
let batches = 0;
/** Set before the server is killed, so the stream ending is not a failure. */
let stopping = false;

/** Read the stream forever, exactly as `XoteDevClient` does.
 *
 * The chunks are bytes, and appending a `Uint8Array` to a string gives its
 * digits with commas between them — no newline ever appears in that, so the
 * lines never form and the screen never arrives. Decode. */
async function drain(body) {
  const decoder = new TextDecoder();
  let partial = "";
  try {
    for await (const chunk of body) {
      partial += decoder.decode(chunk, { stream: true });
      let newline;
      while ((newline = partial.indexOf("\n")) >= 0) {
        const line = partial.slice(0, newline);
        partial = partial.slice(newline + 1);
        if (line.length === 0) continue;
        const message = JSON.parse(line);
        if (message.type === "reset") {
          resets += 1;
          host = new ReferenceHost({ width: 320, height: 640 });
        } else if (message.type === "batch") {
          batches += 1;
          host.apply(message.commands);
        }
      }
    }
  } catch (error) {
    // Killing the server at the end of the test aborts this read, which is the
    // stream doing what it is told rather than anything to report.
    if (!stopping) throw error;
  }
}

/** Every string on screen, which is how this test recognises the app. */
const texts = () => Object.values(host.texts()).join(" ");

/** The first node matching, by type and by the text under it. */
function find(type, contains) {
  for (const node of host.nodes.values()) {
    if (node.type !== type) continue;
    const own = host.texts();
    const label = node.children.map((child) => own[child.id] ?? "").join("");
    if (label.includes(contains)) return node;
  }
  return undefined;
}

try {
  /* ---- the device connects --------------------------------------------- */

  let response;
  await until(
    async () => {
      try {
        response = await fetch(`${BASE}/stream`);
        return response.ok;
      } catch {
        return false;
      }
    },
    "the dev server to accept a connection",
  );
  drain(response.body);

  await until(() => batches > 0, "the first batch");
  assert.equal(resets, 1, "a connection starts with a reset, so nothing is assumed about the screen");
  assert.ok(host.root !== null, "the app mounted");
  assert.match(texts(), /Tapped 0/, `the counter app is on screen — got "${texts()}"`);

  const frames = host.frames();
  assert.ok(Object.keys(frames).length > 3, "and it is laid out, not merely built");

  /* ---- an event changes the screen -------------------------------------- */

  // This is the half that cannot be faked: the handler runs in a process on
  // the other side of a socket, and its effect has to come back as commands.
  const button = find("pressable", "Tap me");
  assert.ok(button, `found a button to press — screen reads "${texts()}"`);

  const before = texts();
  const seen = batches;
  await fetch(`${BASE}/event`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ id: button.id, name: "press", payload: {} }),
  });

  await until(() => batches > seen, "a batch caused by the press");
  assert.notEqual(texts(), before, `the press changed the screen: "${before}" → "${texts()}"`);

  /* ---- a save reloads ---------------------------------------------------- */

  const wasReset = resets;
  const marker = "xote dev reload marker";
  writeFileSync(TOUCHED, ORIGINAL + `\nglobalThis.__xoteDevMarker = ${JSON.stringify(marker)};\n`);

  await until(() => resets > wasReset, "a reset after the file changed", 20000);
  await until(() => host.root !== null && batches > seen + 1, "the app to be rebuilt");

  assert.match(texts(), /Tapped 0/, "the app came back, and came back from zero rather than " +
    "keeping the count from the process that was replaced");
  assert.ok(host.root !== null, "with a root the new process numbered from 1");

  console.log(
    `dev loop tests passed — connected, pressed a button on a screen running in another` +
      ` process, and reloaded on a save (${resets} resets, ${batches} batches)`,
  );
} finally {
  stopping = true;
  writeFileSync(TOUCHED, ORIGINAL);
  server.kill();
}
