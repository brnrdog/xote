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
 */

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
