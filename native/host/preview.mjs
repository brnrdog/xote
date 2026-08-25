/**
 * A host that draws the protocol with real DOM and flexbox.
 *
 * This is not how a phone renders a Xote app — it is how you look at one
 * without a phone. It exists for two reasons: it is a second implementation of
 * the protocol, which is the only way to find out whether the protocol is
 * really host-agnostic; and it is the shape a dev-time simulator would take.
 *
 * It also makes the point that the bridge is the whole contract. Nothing below
 * knows about signals, components or ReScript.
 */

import { OP } from "./protocol.mjs";

const UNITLESS = new Set([
  "flex",
  "flexGrow",
  "flexShrink",
  "opacity",
  "zIndex",
  "aspectRatio",
  "fontWeight",
]);

const EXPAND = {
  marginHorizontal: ["marginLeft", "marginRight"],
  marginVertical: ["marginTop", "marginBottom"],
  paddingHorizontal: ["paddingLeft", "paddingRight"],
  paddingVertical: ["paddingTop", "paddingBottom"],
};

const WEIGHT = {
  thin: 100,
  light: 300,
  regular: 400,
  medium: 500,
  semibold: 600,
  bold: 700,
  heavy: 900,
};

// React Native's defaults, which are not the web's: a view is a column flex
// container that does not shrink.
const BASE =
  "display:flex;flex-direction:column;align-items:stretch;flex-shrink:0;position:relative;min-width:0;min-height:0;box-sizing:border-box;";

const cssValue = (key, value) => {
  if (key === "fontWeight") return String(WEIGHT[value] ?? value);
  if (typeof value === "number" && !UNITLESS.has(key)) return `${value}px`;
  return String(value);
};

const cssKey = (key) => key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);

const toCss = (style) => {
  let out = "";
  for (const [key, value] of Object.entries(style ?? {})) {
    if (value === undefined || value === null) continue;
    // A border width means a border on a native host. CSS also wants a style,
    // or it draws nothing at all.
    if (key === "borderWidth") out += "border-style:solid;";
    const targets = EXPAND[key] ?? [key];
    for (const target of targets) out += `${cssKey(target)}:${cssValue(target, value)};`;
  }
  return out;
};

const EVENT_MAP = {
  press: "click",
  layout: null, // reported after a batch rather than by a DOM event

  pressIn: "pointerdown",
  pressOut: "pointerup",
  changeText: "input",
  focus: "focusin",
  blur: "focusout",
  scroll: "scroll",
};

/**
 * @param mount     a real DOM element to draw into
 * @param dispatch  `(nodeId, event, payload)` — how an event gets back to the
 *                  app, whether that is a direct call or a `postMessage`
 */
export function createPreviewHost(mount, { onBatch, dispatch } = {}) {
  const dom = mount.ownerDocument;
  const nodes = new Map();
  const layoutListeners = new Set();
  const reported = new Map();

  const element = (type) => {
    switch (type) {
      case "text":
        return dom.createElement("span");
      case "image":
        return dom.createElement("img");
      case "input":
        return dom.createElement("input");
      default:
        return dom.createElement("div");
    }
  };

  const applyStyle = (node) => {
    let css = BASE;
    if (node.type === "text") css = "display:block;white-space:pre-wrap;";
    if (node.type === "scroll") css += node.props.horizontal ? "overflow-x:auto;" : "overflow-y:auto;";
    if (node.type === "pressable") css += "cursor:pointer;user-select:none;";
    if (node.type === "image") css += "object-fit:cover;";
    node.el.setAttribute("style", css + toCss(node.props.style));
  };

  const setProp = (node, key, value) => {
    if (value === null) delete node.props[key];
    else node.props[key] = value;

    switch (key) {
      case "style":
      case "horizontal":
        applyStyle(node);
        break;
      case "source":
        node.el.src = typeof value === "string" ? value : (value?.uri ?? "");
        break;
      case "value":
        node.el.value = value ?? "";
        break;
      case "placeholder":
        node.el.placeholder = value ?? "";
        break;
      case "testID":
        node.el.dataset.testid = value ?? "";
        break;
      case "accessibilityLabel":
        node.el.setAttribute("aria-label", value ?? "");
        break;
      case "numberOfLines":
        // `-webkit-line-clamp` only does anything inside a `-webkit-box`.
        if (value) {
          node.el.style.display = "-webkit-box";
          node.el.style.webkitBoxOrient = "vertical";
          node.el.style.webkitLineClamp = String(value);
          node.el.style.overflow = "hidden";
        } else {
          node.el.style.webkitLineClamp = "";
        }
        break;
      default:
        break;
    }
  };

  const listen = (node, name) => {
    if (name === "layout") {
      layoutListeners.add(node);
      return;
    }
    const domEvent = EVENT_MAP[name];
    if (domEvent === undefined || domEvent === null) return;
    node.el.addEventListener(domEvent, (event) => {
      if (name === "press") event.stopPropagation();
      dispatch(node.id, name, payloadFor(name, event, node));
    });
  };

  const payloadFor = (name, event, node) => {
    if (name === "changeText") return { value: node.el.value };
    if (name === "scroll") return { x: node.el.scrollLeft, y: node.el.scrollTop };
    return { pageX: event.pageX ?? 0, pageY: event.pageY ?? 0 };
  };

  const host = {
    apply(batch) {
      for (const [op, ...args] of batch) {
        switch (op) {
          case OP.CREATE: {
            const [id, type] = args;
            const node = { id, type, props: {}, el: element(type) };
            if (type === "root") node.el.setAttribute("style", BASE + "flex:1;");
            else applyStyle(node);
            nodes.set(id, node);
            if (type === "root") mount.replaceChildren(node.el);
            break;
          }
          case OP.CREATE_TEXT: {
            const [id, text] = args;
            nodes.set(id, { id, type: "#text", props: {}, el: dom.createTextNode(text) });
            break;
          }
          case OP.SET_PROP: {
            const [id, key, value] = args;
            setProp(nodes.get(id), key, value);
            break;
          }
          case OP.SET_TEXT: {
            const [id, text] = args;
            nodes.get(id).el.data = text;
            break;
          }
          case OP.INSERT: {
            const [parentId, childId, index] = args;
            const parent = nodes.get(parentId).el;
            parent.insertBefore(nodes.get(childId).el, parent.childNodes[index] ?? null);
            break;
          }
          case OP.REMOVE: {
            const [, childId] = args;
            nodes.get(childId).el.remove();
            break;
          }
          case OP.DESTROY: {
            nodes.delete(args[0]);
            break;
          }
          case OP.LISTEN: {
            listen(nodes.get(args[0]), args[1]);
            break;
          }
          default:
            throw new Error(`Xote Native preview: unknown opcode ${op}`);
        }
      }
      // Nodes that asked where they ended up are told after the batch, and only
      // when it changed — a list driven by its own layout event would otherwise
      // never settle.
      for (const node of layoutListeners) {
        const box = node.el.getBoundingClientRect();
        const frame = `${box.width}x${box.height}`;
        if (reported.get(node.id) === frame) continue;
        reported.set(node.id, frame);
        dispatch(node.id, "layout", {
          x: node.el.offsetLeft,
          y: node.el.offsetTop,
          width: box.width,
          height: box.height,
        });
      }
      if (onBatch) onBatch(batch);
    },
  };

  return host;
}
