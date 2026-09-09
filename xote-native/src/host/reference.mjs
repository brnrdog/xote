/**
 * The reference host: the protocol *and* layout, with nothing to draw on.
 *
 * `headless.mjs` answers "did the right commands arrive". This answers "does a
 * host that applies them correctly end up with the right screen" — the view
 * tree, and every box's position and size. It is the thing the conformance
 * suite compares real hosts against, and the closest thing to an executable
 * specification of what a host has to do.
 *
 * Text is measured by a stub rather than by real font metrics, because the
 * whole point is that two hosts agree, and `UILabel` and Chromium never will.
 * A host under test installs the same stub; see `xote-native/conformance/`.
 *
 * It keeps **two trees**, as a real host must: the layout nodes, and the views.
 * They are not the same shape — a layout-only box has a layout node and no view
 * (`flatten.mjs`), and a view is taken from and returned to a pool
 * (`pool.mjs`). Frames come from the first tree and are unaffected by either;
 * that invariant is what `test/flatten_test.mjs` asserts and it is the reason
 * both are safe to turn on.
 */

import { OP } from "./protocol.mjs";
import { layout } from "./layout.mjs";
import { needsView } from "./flatten.mjs";
import { ViewPool } from "./pool.mjs";

/**
 * The measure function every host uses while running the conformance suite:
 * a fixed-width font, wrapping on whole characters.
 *
 * It is not meant to be realistic. It is meant to be reproducible in Swift,
 * Kotlin and JavaScript from the same description.
 */
export const STUB_CHAR_WIDTH = 7;
export const STUB_LINE_HEIGHT = 16;

export function stubMeasure(text, availableWidth, widthMode) {
  if (text.length === 0) return { width: 0, height: 0 };
  const natural = text.length * STUB_CHAR_WIDTH;
  if (widthMode === 0 || availableWidth === undefined) {
    return { width: natural, height: STUB_LINE_HEIGHT };
  }
  const usable = widthMode === 1 ? availableWidth : Math.min(availableWidth, natural);
  const perLine = Math.max(1, Math.floor(usable / STUB_CHAR_WIDTH));
  return {
    width: widthMode === 1 ? availableWidth : Math.min(natural, usable),
    height: Math.ceil(text.length / perLine) * STUB_LINE_HEIGHT,
  };
}

/**
 * A view in the reference host. It draws nothing — what matters is that it has
 * identity, a kind that decides which pool it belongs to, and children, so the
 * shape of the view tree is a thing that can be compared and got wrong.
 */
class ReferenceView {
  constructor(kind) {
    this.kind = kind;
    this.children = [];
    this.owner = 0;
  }
}

export class ReferenceHost {
  /**
   * @param {{width: number, height: number}} viewport
   * @param {(text: string, availableWidth?: number, widthMode?: number) => {width: number, height: number}} [measure]
   * @param {{flatten?: boolean, recycle?: boolean, poolLimit?: number}} [options]
   *   Both default to on. Turning them off is how the tests get a baseline to
   *   compare against — the frames must come out identical either way.
   */
  constructor(viewport, measure = stubMeasure, options = {}) {
    const { flatten = true, recycle = true, poolLimit = 64 } = options;
    this.viewport = viewport;
    this.measureText = measure;
    this.nodes = new Map();
    this.root = null;
    this.events = new Map();

    this.flatten = flatten;
    this.pool = new ViewPool({
      // A pool with no room keeps nothing, so every acquire allocates — which
      // is exactly "recycling off", without a second code path to get wrong.
      limit: recycle ? poolLimit : 0,
      reset: (_kind, view) => {
        view.children.length = 0;
        view.owner = 0;
      },
    });
  }

  node(id) {
    const found = this.nodes.get(id);
    if (found === undefined) throw new Error(`Xote: host has no node ${id}`);
    return found;
  }

  // MARK: - The view tree
  //
  // Kept incrementally, the way a real host has to keep it: there is no pass at
  // the end of a batch that rebuilds it from the layout tree. `nativeTree()`
  // therefore means something — a splice bug shows up as a wrong tree rather
  // than being tidied away.

  /**
   * Does this node get a view of its own?
   *
   * Two rules, and only the first is the flattening policy. The second is
   * context: a run inside a `text` is a piece of that label's string, not a box
   * on screen, which is true on every host and has nothing to do with
   * flattening.
   */
  wantsView(node) {
    if (node.type === "#text") {
      const parent = this.nodes.get(node.parent);
      return parent === undefined || parent.type !== "text";
    }
    if (!this.flatten) return true;
    return needsView({
      type: node.type,
      style: node.style,
      props: node.props,
      events: this.events.get(node.id),
    });
  }

  acquireView(node) {
    const view = this.pool.acquire(node.type, () => new ReferenceView(node.type));
    view.owner = node.id;
    return view;
  }

  releaseView(node) {
    const view = node.view;
    if (view === undefined || view === null) return;
    node.view = null;
    this.pool.release(view.kind, view);
  }

  /** The nearest ancestor holding a view, or null when this subtree is detached. */
  nativeHost(node) {
    let current = this.nodes.get(node.parent);
    while (current !== undefined) {
      if (current.view != null) return current;
      current = this.nodes.get(current.parent);
    }
    return null;
  }

  /**
   * The views at the top of `node`'s subtree — `node`'s own if it has one,
   * otherwise the frontier just below the flattened boxes covering it. Attaching
   * or detaching a flattened node means doing so for each of these, in order.
   */
  renderedRoots(node, out = []) {
    if (node.view != null) {
      out.push(node);
      return out;
    }
    for (const child of node.children) this.renderedRoots(child, out);
    return out;
  }

  /** How many views precede `node` inside `host` — its index among subviews. */
  nativeIndexOf(host, node) {
    let count = 0;
    const walk = (parent) => {
      for (const child of parent.children) {
        if (child === node) return true;
        if (child.view != null) count += 1;
        else if (walk(child)) return true;
      }
      return false;
    };
    walk(host);
    return count;
  }

  insertView(parentView, childView, index) {
    const existing = parentView.children.indexOf(childView);
    if (existing >= 0) parentView.children.splice(existing, 1);
    parentView.children.splice(Math.min(index, parentView.children.length), 0, childView);
  }

  removeView(parentView, childView) {
    const at = parentView.children.indexOf(childView);
    if (at >= 0) parentView.children.splice(at, 1);
  }

  attachNative(node) {
    const host = this.nativeHost(node);
    if (host === null) return;
    let index = this.nativeIndexOf(host, node);
    for (const root of this.renderedRoots(node)) {
      this.insertView(host.view, root.view, index);
      index += 1;
    }
  }

  /** `host` is passed in because the caller has it from before the unlink. */
  detachNative(node, host) {
    if (host === null) return;
    for (const root of this.renderedRoots(node)) this.removeView(host.view, root.view);
  }

  /**
   * Bring a node's view presence back in line with what it now needs — a style
   * that gained a background, a `press` listener on a box that had none.
   *
   * The two directions are mirror images. Materialising takes whatever was
   * standing in for the node in its host and moves it inside a new view.
   * Dematerialising lifts the view's children into its place and gives the view
   * back. Both are rare — a box does not usually start painting halfway through
   * its life — and both have to be right, because getting them wrong reorders a
   * screen rather than merely slowing it down.
   */
  reconcileView(node) {
    if (node.type === "#text") return;
    const want = this.wantsView(node);
    const has = node.view != null;
    if (want === has) return;

    const host = this.nativeHost(node);
    const index = host === null ? 0 : this.nativeIndexOf(host, node);

    if (want) {
      const standingIn = this.renderedRoots(node);
      if (host !== null) {
        for (const root of standingIn) this.removeView(host.view, root.view);
      }
      node.view = this.acquireView(node);
      standingIn.forEach((root, at) => this.insertView(node.view, root.view, at));
      if (host !== null) this.insertView(host.view, node.view, index);
    } else {
      const inner = node.view.children.slice();
      for (const view of inner) this.removeView(node.view, view);
      if (host !== null) this.removeView(host.view, node.view);
      this.releaseView(node);
      if (host !== null) {
        inner.forEach((view, at) => this.insertView(host.view, view, index + at));
      }
    }
  }

  /**
   * A run's view presence depends on where it landed, so it is decided on
   * insert rather than at creation. It has no children, which is what makes
   * this a plain swap rather than the splice `reconcileView` has to do.
   */
  settleRun(node) {
    if (node.type !== "#text") return;
    const want = this.wantsView(node);
    if (want === (node.view != null)) return;
    if (want) node.view = this.acquireView(node);
    else this.releaseView(node);
  }

  apply(batch) {
    for (const [op, ...args] of batch) {
      switch (op) {
        case OP.CREATE: {
          const [id, type] = args;
          const node = { id, type, style: {}, props: {}, children: [], parent: 0, text: null, view: null };
          this.nodes.set(id, node);
          if (type === "root") {
            this.root = node;
            // The mount point exists before the app does, so it is never pooled
            // and never flattened.
            node.view = new ReferenceView("root");
            node.view.owner = id;
          }
          break;
        }
        case OP.CREATE_TEXT: {
          const [id, text] = args;
          this.nodes.set(id, {
            id,
            type: "#text",
            style: {},
            props: {},
            children: [],
            parent: 0,
            text,
            view: null,
          });
          break;
        }
        case OP.SET_PROP: {
          const [id, key, value] = args;
          const node = this.node(id);
          if (key === "style") node.style = value ?? {};
          else if (value === null) delete node.props[key];
          else node.props[key] = value;
          // A style or a prop can be the reason a box exists on screen at all.
          this.reconcileView(node);
          break;
        }
        case OP.SET_TEXT: {
          const [id, text] = args;
          this.node(id).text = text;
          break;
        }
        case OP.INSERT: {
          const [parentId, childId, index] = args;
          const parent = this.node(parentId);
          const child = this.node(childId);
          // Detach from wherever it was first, and do it while the old host is
          // still reachable — an insert of an already-parented node is a move,
          // and the keyed reconciler does exactly that.
          if (child.parent !== 0) this.detachNative(child, this.nativeHost(child));
          const existing = parent.children.indexOf(child);
          if (existing >= 0) parent.children.splice(existing, 1);
          parent.children.splice(Math.min(index, parent.children.length), 0, child);
          child.parent = parentId;
          // Whether a run gets a view depends on what it landed in, so it is
          // settled here rather than at creation.
          this.settleRun(child);
          if (child.view == null && this.wantsView(child)) this.reconcileView(child);
          this.attachNative(child);
          break;
        }
        case OP.REMOVE: {
          const [parentId, childId] = args;
          const parent = this.node(parentId);
          const child = this.node(childId);
          this.detachNative(child, this.nativeHost(child));
          const at = parent.children.findIndex((c) => c.id === childId);
          if (at >= 0) parent.children.splice(at, 1);
          child.parent = 0;
          break;
        }
        case OP.DESTROY: {
          const [id] = args;
          const node = this.nodes.get(id);
          // The protocol guarantees the id is never referenced again, which is
          // exactly the guarantee a pool needs to take the view back.
          if (node !== undefined) {
            // A well-behaved bundle removes before it destroys. Detaching here
            // anyway means one that does not cannot leave a view in the tree
            // pointing at an id nothing owns.
            if (node.view != null) {
              const host = this.nativeHost(node);
              if (host !== null) this.removeView(host.view, node.view);
            }
            this.releaseView(node);
          }
          this.nodes.delete(id);
          this.events.delete(id);
          break;
        }
        case OP.LISTEN: {
          const [id, event] = args;
          if (!this.events.has(id)) this.events.set(id, new Set());
          this.events.get(id).add(event);
          // A touch needs something to land on.
          this.reconcileView(this.node(id));
          break;
        }
        default:
          throw new Error(`Xote: unknown opcode ${op}`);
      }
    }
    this.layout();
  }

  /** Build the layout tree and run one pass, exactly as a real host does. */
  layout() {
    if (this.root === null) return;
    const build = (node) => {
      // A `text` owns its runs: they are pieces of one string on one line, not
      // boxes stacked under it. So the runs inside a `text` get no box of their
      // own, and the `text` measures the whole concatenation.
      if (node.type === "text") {
        const text = node.children
          .filter((child) => child.type === "#text")
          .map((child) => child.text ?? "")
          .join("");
        const box = {
          style: node.style,
          children: [],
          node,
          measure: (availableWidth, widthMode) =>
            this.measureText(text, availableWidth, widthMode),
        };
        for (const child of node.children) child.box = undefined;
        node.box = box;
        return box;
      }

      // A run anywhere else is a node in its own right — the placeholder an
      // absent reactive branch renders is exactly this — and it measures itself.
      if (node.type === "#text") {
        const box = {
          style: node.style,
          children: [],
          node,
          measure: (availableWidth, widthMode) =>
            this.measureText(node.text ?? "", availableWidth, widthMode),
        };
        node.box = box;
        return box;
      }

      const box = { style: node.style, children: node.children.map(build), node };
      node.box = box;
      return box;
    };
    const tree = build(this.root);
    layout(tree, this.viewport.width, this.viewport.height);
  }

  /** Every live node's frame in root coordinates — the comparable form. */
  frames() {
    const out = {};
    const walk = (node, offsetX, offsetY) => {
      const box = node.box;
      // A run inside a `text` is part of a string, not a box on screen.
      if (box === undefined || box.layout === undefined) return;
      const left = offsetX + box.layout.left;
      const top = offsetY + box.layout.top;
      out[node.id] = [
        Math.round(left * 100) / 100,
        Math.round(top * 100) / 100,
        Math.round(box.layout.width * 100) / 100,
        Math.round(box.layout.height * 100) / 100,
      ];
      for (const child of node.children) walk(child, left, top);
    };
    if (this.root !== null) walk(this.root, 0, 0);
    return out;
  }

  /** Parent-to-children, so a structural mistake fails before a numeric one. */
  structure() {
    const out = {};
    const walk = (node) => {
      out[node.id] = node.children.map((child) => child.id);
      for (const child of node.children) walk(child);
    };
    if (this.root !== null) walk(this.root);
    return out;
  }

  /**
   * The **view** tree: which views exist, and which view holds which. Keyed by
   * the node id each view belongs to, so it is comparable across hosts.
   *
   * This is the thing flattening changes and `structure()` does not. A host
   * that flattens differently has a different screen — the same content in
   * different drawing surfaces, with different clipping and different hit
   * testing — so the conformance suite compares it.
   */
  nativeTree() {
    const out = {};
    if (this.root === null || this.root.view == null) return out;
    const walk = (view) => {
      out[view.owner] = view.children.map((child) => child.owner);
      for (const child of view.children) walk(child);
    };
    walk(this.root.view);
    return out;
  }

  /** How many views are on screen, against how many nodes there are. */
  viewCount() {
    let views = 0;
    for (const node of this.nodes.values()) if (node.view != null) views += 1;
    return views;
  }

  /** Allocation behaviour, so a test can assert that churn stops allocating. */
  stats() {
    return { ...this.pool.stats(), views: this.viewCount(), nodes: this.nodes.size };
  }

  /** Text as it would be shown, so a host that loses or reorders a run is
   caught even where the runs have no frames of their own. */
  texts() {
    const out = {};
    for (const node of this.nodes.values()) {
      if (node.type === "text") {
        out[node.id] = node.children
          .filter((child) => child.type === "#text")
          .map((child) => child.text ?? "")
          .join("");
      } else if (node.type === "#text" && node.parent !== 0) {
        const parent = this.nodes.get(node.parent);
        if (parent !== undefined && parent.type !== "text") out[node.id] = node.text ?? "";
      }
    }
    return out;
  }
}
