/**
 * The shadow document.
 *
 * Xote's renderer talks to exactly eighteen DOM operations (see `RuntimeDom`
 * and the `%raw` walks in `RuntimeRender`). This module implements that subset
 * over a plain JavaScript tree and projects every mutation onto the flat
 * command stream in `protocol.mjs`, so a native host never sees a DOM at all.
 *
 * Two node kinds exist in the shadow tree but never reach the host:
 *
 *   - **Comments.** The keyed-list reconciler brackets its rows with two
 *     comment anchors so it can find them again. They carry no pixels.
 *   - **Transparent elements.** `SignalFragment` renders its children into a
 *     `<div style="display: contents">` — a grouping box the web flattens away
 *     at layout time. Native layout has no such escape, so the projection
 *     flattens it here instead: a transparent element's children are spliced
 *     into its nearest rendered ancestor.
 *
 * Flattening is why insertion carries an index rather than a "before" sibling:
 * the shadow position and the native position are different numbers, and only
 * this module knows both.
 */

import { OP } from "./protocol.mjs";

const ELEMENT_NODE = 1;
const TEXT_NODE = 3;
const COMMENT_NODE = 8;
const DOCUMENT_FRAGMENT_NODE = 11;

/** A grouping box is marked as one when it is created, not recognised later. */
const GROUP_TAG = "#group";

const isProjected = (node) =>
  node.nodeType === TEXT_NODE || (node.nodeType === ELEMENT_NODE && node.tag !== GROUP_TAG);

class ShadowNode {
  constructor(doc, nodeType, tag, text) {
    this.doc = doc;
    this.nodeType = nodeType;
    this.tag = tag;
    this.text = text;

    // The renderer walks these directly, and its loops test `!== null`, so
    // every node — leaves included — must carry all five as real nulls.
    this.parentNode = null;
    this.firstChild = null;
    this.lastChild = null;
    this.nextSibling = null;
    this.previousSibling = null;

    this.listeners = null;
    this.id = 0;
    this.projected = isProjected(this);
    if (this.projected) {
      this.id = doc.claimId(this);
    }
  }

  get childNodes() {
    const out = [];
    for (let child = this.firstChild; child !== null; child = child.nextSibling) out.push(child);
    return out;
  }

  /* ---- tree mutation ---- */

  insertBefore(child, reference) {
    if (child.nodeType === DOCUMENT_FRAGMENT_NODE) {
      // A fragment is spliced, not parented — appending one in the DOM moves
      // its children and leaves it empty. The renderer relies on that.
      let next = child.firstChild;
      while (next !== null) {
        const moving = next;
        next = next.nextSibling;
        child.unlink(moving);
        this.insertBefore(moving, reference);
      }
      return child;
    }

    if (child.parentNode !== null) child.parentNode.removeChild(child);

    this.link(child, reference ?? null);

    const host = this.renderedAncestor();
    if (host !== null) {
      let index = this.doc.nativeIndexOf(host, child);
      for (const root of renderedRoots(child)) {
        this.doc.emit([OP.INSERT, host.id, root.id, index++]);
        this.doc.adopt(root);
      }
    }
    return child;
  }

  appendChild(child) {
    return this.insertBefore(child, null);
  }

  removeChild(child) {
    if (child.parentNode !== this) return child;

    const host = this.renderedAncestor();
    if (host !== null) {
      for (const root of renderedRoots(child)) {
        this.doc.emit([OP.REMOVE, host.id, root.id]);
      }
    }
    this.unlink(child);
    this.doc.orphan(child);
    return child;
  }

  replaceChild(next, previous) {
    const reference = previous.nextSibling;
    this.removeChild(previous);
    this.insertBefore(next, reference);
    return previous;
  }

  remove() {
    if (this.parentNode !== null) this.parentNode.removeChild(this);
  }

  /* ---- props, text, events ---- */

  setAttribute(key, value) {
    if (!this.projected) return;
    this.doc.emit([OP.SET_PROP, this.id, key, value === undefined ? null : value]);
  }

  removeAttribute(key) {
    if (!this.projected) return;
    this.doc.emit([OP.SET_PROP, this.id, key, null]);
  }

  addEventListener(name, handler) {
    if (this.listeners === null) this.listeners = new Map();
    const existing = this.listeners.get(name);
    if (existing === undefined) {
      this.listeners.set(name, [handler]);
      if (this.projected) this.doc.emit([OP.LISTEN, this.id, name]);
    } else {
      existing.push(handler);
    }
  }

  set textContent(value) {
    if (this.nodeType === TEXT_NODE || this.nodeType === COMMENT_NODE) {
      this.text = String(value);
      if (this.projected) this.doc.emit([OP.SET_TEXT, this.id, this.text]);
      return;
    }
    this.clearChildren();
    if (value !== "" && value != null) this.appendChild(this.doc.createTextNode(String(value)));
  }

  get textContent() {
    if (this.nodeType === TEXT_NODE || this.nodeType === COMMENT_NODE) return this.text;
    let out = "";
    for (let child = this.firstChild; child !== null; child = child.nextSibling) {
      out += child.textContent;
    }
    return out;
  }

  /**
   * `innerHTML = ""` is how the renderer empties a reactive region. Nothing
   * else is ever assigned, and a native host has no HTML parser, so anything
   * else is a bug worth surfacing loudly rather than half-supporting.
   */
  set innerHTML(value) {
    if (value !== "") {
      throw new Error("Xote Native: innerHTML is only supported as a way to clear a node");
    }
    this.clearChildren();
  }

  // `value`, `checked` and `disabled` are properties, not attributes, in the
  // DOM — `RuntimeDom.setAttrOrProp` special-cases them. On the native side
  // they are ordinary props.
  set value(v) {
    this.setAttribute("value", v);
  }
  set checked(v) {
    this.setAttribute("checked", v);
  }
  set disabled(v) {
    this.setAttribute("disabled", v);
  }

  /* ---- internals ---- */

  clearChildren() {
    let child = this.firstChild;
    while (child !== null) {
      const next = child.nextSibling;
      this.removeChild(child);
      child = next;
    }
  }

  link(child, reference) {
    child.parentNode = this;
    child.nextSibling = reference;
    if (reference === null) {
      child.previousSibling = this.lastChild;
      if (this.lastChild !== null) this.lastChild.nextSibling = child;
      this.lastChild = child;
      if (this.firstChild === null) this.firstChild = child;
    } else {
      child.previousSibling = reference.previousSibling;
      if (reference.previousSibling !== null) reference.previousSibling.nextSibling = child;
      else this.firstChild = child;
      reference.previousSibling = child;
    }
  }

  unlink(child) {
    if (child.previousSibling !== null) child.previousSibling.nextSibling = child.nextSibling;
    else this.firstChild = child.nextSibling;
    if (child.nextSibling !== null) child.nextSibling.previousSibling = child.previousSibling;
    else this.lastChild = child.previousSibling;
    child.parentNode = null;
    child.nextSibling = null;
    child.previousSibling = null;
  }

  /** Nearest ancestor-or-self that the host actually knows about. */
  renderedAncestor() {
    let node = this;
    while (node !== null && !node.projected) node = node.parentNode;
    return node;
  }
}

/**
 * The rendered nodes at the top of `node`'s subtree — `node` itself when it is
 * rendered, otherwise the frontier just below the transparent nodes covering
 * it. Inserting or removing a transparent node means doing so for each of
 * these, in order.
 */
function renderedRoots(node, out = []) {
  if (node.projected) {
    out.push(node);
    return out;
  }
  for (let child = node.firstChild; child !== null; child = child.nextSibling) {
    renderedRoots(child, out);
  }
  return out;
}

export class ShadowDocument {
  constructor() {
    this.batch = [];
    this.nodes = new Map();
    this.roots = new Map();
    this.orphans = new Set();
    this.nextId = 1;
    this.onFlush = null;
    /** Called with anything that went wrong instead of being thrown onward. */
    this.onError = null;
  }

  /**
   * Run `fn`, and treat a failure as damage to contain rather than propagate.
   *
   * The app is one long-lived process with a screen on it. An exception in one
   * event handler must not stop the other handlers on the same node, abandon a
   * half-built batch on this side of the bridge, or take the app down — the
   * tree is still consistent, because every mutation is applied whole.
   */
  guard(what, fn) {
    try {
      return fn();
    } catch (error) {
      if (this.onError !== null) this.onError(what, error);
      else console.error(`Xote Native: ${what}`, error);
      return undefined;
    }
  }

  claimId(node) {
    const id = this.nextId++;
    this.nodes.set(id, node);
    this.emit([
      node.nodeType === TEXT_NODE ? OP.CREATE_TEXT : OP.CREATE,
      id,
      node.nodeType === TEXT_NODE ? node.text : node.tag,
    ]);
    return id;
  }

  emit(command) {
    this.batch.push(command);
  }

  /* ---- document API the renderer binds to ---- */

  createElement(tag) {
    return new ShadowNode(this, ELEMENT_NODE, tag, "");
  }

  /**
   * The renderer's hook for "make me an element of this tag".
   *
   * Implementing it takes the DOM's SVG namespace table out of the decision —
   * `text`, `image`, `line`, `mask` and `filter` are SVG on the web and
   * ordinary view names here.
   */
  createXoteElement(tag) {
    return this.createElement(tag);
  }

  /**
   * The renderer's hook for "make me a box to group a reactive region in".
   *
   * On the web this is a `<div style="display: contents">`. Here it is a node
   * that never reaches the host at all: its children are spliced into its
   * nearest rendered ancestor, because native layout has no such escape and a
   * stray box in a flex column is a visible bug. Getting told is much better
   * than the tag-sniffing this replaced.
   */
  createXoteGroup() {
    return new ShadowNode(this, ELEMENT_NODE, GROUP_TAG, "");
  }

  // Namespaces are a web concept. Xote routes a fixed list of tag names —
  // `text`, `image`, `line`, `mask`, `filter`, `use` among them — through
  // `createElementNS` because they are SVG on the web. Several are perfectly
  // ordinary native view names, so the namespace is simply dropped.
  createElementNS(_namespace, tag) {
    return this.createElement(tag);
  }

  createTextNode(text) {
    return new ShadowNode(this, TEXT_NODE, "#text", String(text));
  }

  createComment(text) {
    return new ShadowNode(this, COMMENT_NODE, "#comment", String(text));
  }

  createDocumentFragment() {
    return new ShadowNode(this, DOCUMENT_FRAGMENT_NODE, "#fragment", "");
  }

  getElementById(id) {
    return this.roots.get(id) ?? null;
  }

  /* ---- roots ---- */

  /**
   * A mount point. The host is told about it like any other node, and the app
   * is mounted into it with `View.mount`.
   */
  createRoot(name = "root") {
    const root = this.createElement("root");
    this.roots.set(name, root);
    return root;
  }

  /* ---- projection ---- */

  /**
   * Position `node` will occupy among `host`'s children on the native side:
   * the number of rendered nodes that precede it, counting through — but not
   * into — the transparent nodes between them.
   *
   * This walks the region on every insert, which is fine at prototype scale and
   * is the obvious thing to make incremental later (cache a rendered-child
   * count per transparent node and the walk becomes a sibling scan).
   */
  nativeIndexOf(host, node) {
    let count = 0;
    const walk = (parent) => {
      for (let child = parent.firstChild; child !== null; child = child.nextSibling) {
        if (child === node) return true;
        if (child.projected) count++;
        else if (walk(child)) return true;
      }
      return false;
    };
    walk(host);
    return count;
  }

  /** A node that came back into the tree is no longer garbage. */
  adopt(node) {
    this.orphans.delete(node);
  }

  orphan(node) {
    this.orphans.add(node);
  }

  /**
   * Reclaim what the batch detached and did not put back. Deferring this to the
   * flush is what makes a move free: the keyed reconciler detaches a row and
   * re-inserts it in the same pass, and a host that destroyed on REMOVE would
   * have thrown the view away in between.
   */
  sweep() {
    if (this.orphans.size === 0) return;
    for (const node of this.orphans) {
      if (node.parentNode !== null) continue;
      for (const dead of subtree(node)) {
        if (!dead.projected) continue;
        this.emit([OP.DESTROY, dead.id]);
        this.nodes.delete(dead.id);
      }
    }
    this.orphans.clear();
  }

  /** Take everything queued since the last flush. */
  flush() {
    this.guard("sweeping detached nodes", () => this.sweep());
    if (this.batch.length === 0) return [];
    const batch = this.batch;
    // Cleared before the host sees it: a host that throws must not be handed
    // the same batch again on the next flush.
    this.batch = [];
    if (this.onFlush !== null) this.guard("applying a batch", () => this.onFlush(batch));
    return batch;
  }

  /** Deliver an event the host reported back into the app. */
  dispatchEvent(id, name, payload) {
    const node = this.nodes.get(id);
    if (node === undefined || node.listeners === null) return;
    const handlers = node.listeners.get(name);
    if (handlers === undefined) return;
    const event = { type: name, target: node, ...payload };
    // One handler per `guard`: a listener that throws must not silence the
    // ones registered after it.
    for (const handler of handlers.slice()) {
      this.guard(`handling ${name}`, () => handler(event));
    }
  }
}

function subtree(node, out = []) {
  out.push(node);
  for (let child = node.firstChild; child !== null; child = child.nextSibling) subtree(child, out);
  return out;
}
