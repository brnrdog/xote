/**
 * The Xote Native bridge protocol.
 *
 * Every mutation the renderer performs is encoded as one flat array whose first
 * slot is an opcode. A batch is an array of those arrays. That is the entire
 * contract between the JavaScript side and a host — Swift, Kotlin, or the
 * JavaScript hosts in this directory. A host that can apply these eight
 * commands can render a Xote app.
 *
 * Node ids are integers assigned by the shadow document. Id 0 is never used, so
 * it doubles as "no node".
 *
 * ## Versioning
 *
 * The two halves of this bridge ship separately. A JavaScript bundle can be
 * updated without the binary around it — that is most of the point of shipping
 * JavaScript — so "which opcodes does this host speak" is a real question as
 * soon as a host lives in someone else's app.
 *
 * **Opcodes are append-only.** A new capability is a new opcode and a bump of
 * `PROTOCOL_VERSION`. Changing what an existing opcode *means*, or the arity or
 * order of its arguments, is not a bump — it is a different protocol, because an
 * old host will apply it silently and wrongly, which is the one failure mode
 * nothing downstream can detect. There is no mechanism here that prevents that;
 * the rule is the mechanism, and it is cheap to adopt now and impossible to
 * adopt later.
 *
 * Given that rule, a host older than the bundle is survivable: it skips the
 * opcodes it does not know (`XoteCommand.decodeBatch` already does, and reports
 * each one) and everything it does know still applies. A host *newer* than the
 * bundle is trivially fine. The only unsurvivable case is a host that has
 * dropped support for a protocol this old, which is why the range below has a
 * floor as well as a ceiling.
 */

/**
 * The protocol this build of the JavaScript side emits.
 *
 * 1 — the eight opcodes below.
 */
export const PROTOCOL_VERSION = 1;

/**
 * What a host declares it can apply, as `{min, max}` bundle protocol versions.
 * A host that declares nothing is assumed to speak version 1, which is what
 * every host written before this existed does.
 */
export const DEFAULT_HOST_PROTOCOL = Object.freeze({ min: 1, max: 1 });

/**
 * Compare a bundle against a host.
 *
 * Returns `{ok, degraded, reason}`. `degraded` means the host is older than the
 * bundle: it will skip opcodes it does not know and the screen may be missing
 * something, which is worth reporting and is not worth refusing. `ok: false`
 * means the host has dropped support for this bundle's protocol entirely, and
 * continuing would render a silently wrong screen.
 */
export function checkProtocol(host, bundle = PROTOCOL_VERSION) {
  const { min, max } = { ...DEFAULT_HOST_PROTOCOL, ...(host ?? {}) };
  if (bundle < min) {
    return {
      ok: false,
      degraded: false,
      reason:
        `this host speaks protocol ${min}–${max} and the bundle emits ${bundle}: ` +
        "the host has dropped support for it, so nothing here would render correctly",
    };
  }
  if (bundle > max) {
    return {
      ok: true,
      degraded: true,
      reason:
        `this host speaks protocol ${min}–${max} and the bundle emits ${bundle}: ` +
        "commands it does not know will be skipped and reported",
    };
  }
  return { ok: true, degraded: false, reason: null };
}

export const OP = Object.freeze({
  /** [CREATE, id, type] — allocate a view of `type`, detached. */
  CREATE: 1,
  /** [CREATE_TEXT, id, text] — allocate a raw text node, detached. */
  CREATE_TEXT: 2,
  /** [SET_PROP, id, key, value] — `null` clears the prop. */
  SET_PROP: 3,
  /** [SET_TEXT, id, text] — replace a text node's contents. */
  SET_TEXT: 4,
  /** [INSERT, parentId, childId, index] — insert at `index` among the parent's children. */
  INSERT: 5,
  /** [REMOVE, parentId, childId] — detach, but keep the node alive (a move is REMOVE then INSERT). */
  REMOVE: 6,
  /** [DESTROY, id] — the node will never be referenced again; release it. */
  DESTROY: 7,
  /** [LISTEN, id, event] — start delivering `event` on this node back to JavaScript. */
  LISTEN: 8,
});

export const OP_NAME = Object.freeze({
  [OP.CREATE]: "create",
  [OP.CREATE_TEXT]: "createText",
  [OP.SET_PROP]: "setProp",
  [OP.SET_TEXT]: "setText",
  [OP.INSERT]: "insert",
  [OP.REMOVE]: "remove",
  [OP.DESTROY]: "destroy",
  [OP.LISTEN]: "listen",
});

/** Human-readable rendering of a batch. Used by tests and by the preview host's log. */
export const formatBatch = (batch) =>
  batch.map(([op, ...args]) => `${OP_NAME[op]}(${args.map((a) => JSON.stringify(a)).join(", ")})`);
