/**
 * The handshake between a bundle and a host.
 *
 * The two halves of this bridge ship separately: a JavaScript bundle updates
 * without the binary around it, which is most of the point of shipping
 * JavaScript. So there are three cases, and the difference between them is the
 * difference between a warning and a wrong screen.
 */

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { PROTOCOL_VERSION, checkProtocol, OP, OP_NAME } from "../src/host/protocol.mjs";
import { HOSTS } from "../src/host/capabilities.mjs";
import { install } from "../src/host/runtime.mjs";

/* ---- the comparison itself ------------------------------------------------ */

assert.equal(typeof PROTOCOL_VERSION, "number");
assert.ok(PROTOCOL_VERSION >= 1, "a version is at least 1");

// A host that says nothing is a host written before any of this existed. Every
// one of them speaks version 1, and assuming otherwise would break all three.
assert.deepEqual(checkProtocol(undefined, 1), { ok: true, degraded: false, reason: null });
assert.deepEqual(checkProtocol(null, 1), { ok: true, degraded: false, reason: null });

// In range: nothing to say.
assert.deepEqual(checkProtocol({ min: 1, max: 3 }, 2), { ok: true, degraded: false, reason: null });

// The host is older than the bundle. It skips what it does not know and reports
// each one, so the app runs and the screen may be missing something. Worth
// saying; not worth refusing, because refusing turns a partly-drawn screen into
// no screen at all.
const behind = checkProtocol({ min: 1, max: 1 }, 2);
assert.equal(behind.ok, true);
assert.equal(behind.degraded, true);
assert.match(behind.reason, /skipped/);

// The host has dropped support for this bundle's protocol. There is no partial
// success available here: the commands would decode and mean something else.
const dropped = checkProtocol({ min: 3, max: 4 }, 1);
assert.equal(dropped.ok, false);
assert.equal(dropped.degraded, false);
assert.match(dropped.reason, /dropped support/);

/* ---- install refuses, warns, or says nothing ------------------------------ */

const hostThatApplies = (protocol) => ({ apply() {}, protocol });

assert.throws(
  () => install(hostThatApplies({ min: PROTOCOL_VERSION + 2, max: PROTOCOL_VERSION + 3 })),
  /incompatible host/,
  "install must refuse a host that cannot apply this bundle",
);

const reported = [];
const runtime = install(hostThatApplies({ min: 1, max: PROTOCOL_VERSION }), {
  autoFlush: false,
  onError: (what, error) => reported.push([what, error.message]),
});
assert.deepEqual(reported, [], "an agreeing host says nothing");
assert.equal(runtime.protocol.bundle, PROTOCOL_VERSION);
assert.deepEqual(runtime.protocol.host, { min: 1, max: PROTOCOL_VERSION });

// A host one version behind: installed, and reported through the same channel
// everything else contained goes through.
const behindReports = [];
install(hostThatApplies({ min: 1, max: PROTOCOL_VERSION - 1 }), {
  autoFlush: false,
  onError: (what, error) => behindReports.push([what, error.message]),
});
assert.equal(behindReports.length, 1, "a host behind the bundle is reported exactly once");
assert.equal(behindReports[0][0], "protocol");
assert.match(behindReports[0][1], /skipped/);

/* ---- the opcodes are append-only ------------------------------------------ */

// Not a rule this file can enforce, but it can pin the numbers so that changing
// one is a deliberate edit to a test rather than a quiet renumbering. An opcode
// that changes value is a different protocol wearing the same version.
assert.deepEqual(
  { ...OP },
  {
    CREATE: 1,
    CREATE_TEXT: 2,
    SET_PROP: 3,
    SET_TEXT: 4,
    INSERT: 5,
    REMOVE: 6,
    DESTROY: 7,
    LISTEN: 8,
  },
  "an opcode changed value — that is a new protocol, not a new version",
);

// Every opcode has a name, and every name a host might print resolves.
for (const [name, code] of Object.entries(OP)) {
  assert.equal(typeof OP_NAME[code], "string", `opcode ${name} has no name`);
}

/* ---- every host declares a range that includes this bundle ---------------- */

// There is no Swift toolchain here and no Android one, so this reads the
// sources. It is the only way this repository can find out that a binary and
// the bundle disagree about the protocol before a device does — and it has to
// cover every host, because a bundle that one platform can apply and the other
// cannot is a shipped app that works on half the phones.
assert.ok(HOSTS.length > 0, "there are no native hosts to check against");

const ranges = HOSTS.map((host) => {
  const source = readFileSync(
    fileURLToPath(new URL(`../${host.protocol.source}`, import.meta.url)),
    "utf8",
  );
  const declared = (name) => {
    const found = new RegExp(`${name}\\s*=\\s*(\\d+)`).exec(source);
    assert.ok(found, `the ${host.name} host no longer declares ${name}`);
    return Number(found[1]);
  };
  const min = declared(host.protocol.min);
  const max = declared(host.protocol.max);
  assert.ok(min <= max, `the ${host.name} host declares an empty protocol range ${min}–${max}`);
  assert.ok(
    min <= PROTOCOL_VERSION && PROTOCOL_VERSION <= max,
    `the bundle emits protocol ${PROTOCOL_VERSION} and the ${host.name} host speaks ${min}–${max}`,
  );
  return `${host.name} ${min}\u2013${max}`;
});

console.log(
  `protocol tests passed — bundle speaks version ${PROTOCOL_VERSION}, ` +
    `${Object.keys(OP).length} opcodes, hosts speak ${ranges.join(", ")}`,
);
