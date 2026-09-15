/**
 * The reference host, in about eighty lines.
 *
 * It applies the protocol into a plain JavaScript tree and nothing else — no
 * layout, no pixels. Its purpose is to be the executable spec: a Swift or
 * Kotlin host is this file with `UIView`/`android.view.View` in place of the
 * objects, and the tests assert against the tree it builds.
 */

import { OP, formatBatch } from "./protocol.mjs";

export class HeadlessHost {
  constructor() {
    this.views = new Map();
    this.log = [];
    this.destroyed = [];
  }

  apply(batch) {
    for (const command of batch) this.log.push(command);
    for (const [op, ...args] of batch) {
      switch (op) {
        case OP.CREATE: {
          const [id, type] = args;
          this.views.set(id, { id, type, props: {}, children: [], events: new Set(), parent: 0 });
          break;
        }
        case OP.CREATE_TEXT: {
          const [id, text] = args;
          this.views.set(id, { id, type: "#text", text, children: [], parent: 0 });
          break;
        }
        case OP.SET_PROP: {
          const [id, key, value] = args;
          const view = this.expect(id);
          if (value === null) delete view.props[key];
          else view.props[key] = value;
          break;
        }
        case OP.SET_TEXT: {
          const [id, text] = args;
          this.expect(id).text = text;
          break;
        }
        case OP.INSERT: {
          const [parentId, childId, index] = args;
          const parent = this.expect(parentId);
          const child = this.expect(childId);
          parent.children.splice(index, 0, child);
          child.parent = parentId;
          break;
        }
        case OP.REMOVE: {
          const [parentId, childId] = args;
          const parent = this.expect(parentId);
          const at = parent.children.findIndex((c) => c.id === childId);
          if (at >= 0) parent.children.splice(at, 1);
          this.expect(childId).parent = 0;
          break;
        }
        case OP.DESTROY: {
          const [id] = args;
          this.destroyed.push(id);
          this.views.delete(id);
          break;
        }
        case OP.LISTEN: {
          const [id, event] = args;
          this.expect(id).events.add(event);
          break;
        }
        default:
          throw new Error(`Xote Native: unknown opcode ${op}`);
      }
    }
  }

  expect(id) {
    const view = this.views.get(id);
    if (view === undefined) throw new Error(`Xote Native: host has no view ${id}`);
    return view;
  }

  /** Indented dump of a subtree — the shape assertions in the tests read against this. */
  dump(id = 1, depth = 0) {
    const view = this.views.get(id);
    if (view === undefined) return "";
    const pad = "  ".repeat(depth);
    if (view.type === "#text") return `${pad}${JSON.stringify(view.text)}\n`;
    const props = Object.keys(view.props).length
      ? " " +
        Object.entries(view.props)
          .map(([k, v]) => `${k}=${JSON.stringify(v)}`)
          .join(" ")
      : "";
    const events = view.events && view.events.size ? ` @${[...view.events].join(",")}` : "";
    let out = `${pad}<${view.type}${props}${events}>\n`;
    for (const child of view.children) out += this.dump(child.id, depth + 1);
    return out;
  }

  formattedLog() {
    return formatBatch(this.log);
  }

  clearLog() {
    this.log = [];
  }
}
