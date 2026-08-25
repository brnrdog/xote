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
 * A host under test installs the same stub; see `native/conformance/`.
 */

import { OP } from "./protocol.mjs";
import { layout } from "./layout.mjs";

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

export class ReferenceHost {
  /**
   * @param {{width: number, height: number}} viewport
   * @param {(text: string, availableWidth?: number, widthMode?: number) => {width: number, height: number}} [measure]
   */
  constructor(viewport, measure = stubMeasure) {
    this.viewport = viewport;
    this.measureText = measure;
    this.nodes = new Map();
    this.root = null;
    this.events = new Map();
  }

  node(id) {
    const found = this.nodes.get(id);
    if (found === undefined) throw new Error(`Xote: host has no node ${id}`);
    return found;
  }

  apply(batch) {
    for (const [op, ...args] of batch) {
      switch (op) {
        case OP.CREATE: {
          const [id, type] = args;
          const node = { id, type, style: {}, children: [], parent: 0, text: null };
          this.nodes.set(id, node);
          if (type === "root") this.root = node;
          break;
        }
        case OP.CREATE_TEXT: {
          const [id, text] = args;
          this.nodes.set(id, {
            id,
            type: "#text",
            style: {},
            children: [],
            parent: 0,
            text,
          });
          break;
        }
        case OP.SET_PROP: {
          const [id, key, value] = args;
          const node = this.node(id);
          if (key === "style") node.style = value ?? {};
          else if (value === null) delete node[key];
          else node[key] = value;
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
          const existing = parent.children.indexOf(child);
          if (existing >= 0) parent.children.splice(existing, 1);
          parent.children.splice(Math.min(index, parent.children.length), 0, child);
          child.parent = parentId;
          break;
        }
        case OP.REMOVE: {
          const [parentId, childId] = args;
          const parent = this.node(parentId);
          const at = parent.children.findIndex((c) => c.id === childId);
          if (at >= 0) parent.children.splice(at, 1);
          this.node(childId).parent = 0;
          break;
        }
        case OP.DESTROY: {
          this.nodes.delete(args[0]);
          break;
        }
        case OP.LISTEN: {
          const [id, event] = args;
          if (!this.events.has(id)) this.events.set(id, new Set());
          this.events.get(id).add(event);
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
