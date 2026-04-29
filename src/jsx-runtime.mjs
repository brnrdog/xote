import * as Computed from "./Computed.res.mjs";
import * as Signal from "./Signal.res.mjs";
import * as View from "./View.res.mjs";

export const Fragment = Symbol.for("xote.fragment");

const nodeTags = new Set([
  "Element",
  "Text",
  "SignalText",
  "Fragment",
  "SignalFragment",
  "Keyed",
  "LazyComponent",
  "KeyedList",
]);

const eventAliases = {
  onChange: "change",
  onClick: "click",
  onContextMenu: "contextmenu",
  onDoubleClick: "dblclick",
  onInput: "input",
  onSubmit: "submit",
  onFocus: "focus",
  onBlur: "blur",
  onKeyDown: "keydown",
  onKeyUp: "keyup",
  onMouseDown: "mousedown",
  onMouseEnter: "mouseenter",
  onMouseLeave: "mouseleave",
  onMouseMove: "mousemove",
  onMouseUp: "mouseup",
  onDrag: "drag",
  onDragStart: "dragstart",
  onDragEnd: "dragend",
  onDragOver: "dragover",
  onDragEnter: "dragenter",
  onDragLeave: "dragleave",
  onDrop: "drop",
};

const attrAliases = {
  acceptCharset: "accept-charset",
  autoFocus: "autofocus",
  className: "class",
  contentEditable: "contenteditable",
  htmlFor: "for",
  httpEquiv: "http-equiv",
  maxLength: "maxlength",
  minLength: "minlength",
  preserveAspectRatio: "preserveAspectRatio",
  readOnly: "readonly",
  spellCheck: "spellcheck",
  srcSet: "srcset",
  strokeDasharray: "stroke-dasharray",
  strokeDashoffset: "stroke-dashoffset",
  strokeLinecap: "stroke-linecap",
  strokeLinejoin: "stroke-linejoin",
  strokeMiterlimit: "stroke-miterlimit",
  strokeWidth: "stroke-width",
  tabIndex: "tabindex",
  viewBox: "viewBox",
  xlinkHref: "xlink:href",
};

const internalProps = new Set([
  "children",
  "components",
  "key",
  "mdxType",
  "originalType",
  "parentName",
  "ref",
]);

function isXoteNode(value) {
  return value && typeof value === "object" && nodeTags.has(value.TAG);
}

function isReactiveProp(value) {
  return (
    value &&
    typeof value === "object" &&
    (value.TAG === "Static" || value.TAG === "Reactive")
  );
}

function isSignal(value) {
  return (
    value &&
    typeof value === "object" &&
    "subs" in value &&
    "value" in value &&
    typeof value.equals === "function"
  );
}

function toKebab(name) {
  return name.replace(/[A-Z]/g, char => `-${char.toLowerCase()}`);
}

function normalizeAttrName(name) {
  if (attrAliases[name]) {
    return attrAliases[name];
  }

  if (/^(aria|data)[A-Z]/.test(name)) {
    return toKebab(name);
  }

  return name.toLowerCase();
}

function normalizeStyle(style) {
  if (typeof style === "string") {
    return style;
  }

  if (!style || typeof style !== "object") {
    return String(style ?? "");
  }

  return Object.entries(style)
    .filter(([, value]) => value !== null && value !== undefined && value !== false)
    .map(([key, value]) => `${toKebab(key)}:${String(value)}`)
    .join(";");
}

function stringifyAttrValue(name, value) {
  if (name === "style") {
    return normalizeStyle(value);
  }

  return String(value);
}

function attrFromValue(name, value) {
  if (isReactiveProp(value)) {
    if (value.TAG === "Static") {
      return View.attr(name, stringifyAttrValue(name, value._0));
    }

    const signal = value._0;
    return View.signalAttr(
      name,
      Computed.make(() => stringifyAttrValue(name, Signal.get(signal)), undefined, undefined),
    );
  }

  if (isSignal(value)) {
    return View.signalAttr(
      name,
      Computed.make(() => stringifyAttrValue(name, Signal.get(value)), undefined, undefined),
    );
  }

  if (typeof value === "function") {
    return View.computedAttr(name, () => stringifyAttrValue(name, value()));
  }

  return View.attr(name, stringifyAttrValue(name, value));
}

function eventNameFromProp(name, value) {
  if (typeof value !== "function" || !/^on[A-Z]/.test(name)) {
    return null;
  }

  return eventAliases[name] ?? name.slice(2).toLowerCase();
}

function normalizeChildren(children) {
  if (children === null || children === undefined || typeof children === "boolean") {
    return [];
  }

  if (Array.isArray(children)) {
    return children.flatMap(normalizeChildren);
  }

  if (isXoteNode(children)) {
    return [children];
  }

  return [View.text(String(children))];
}

function normalizeNode(value) {
  if (isXoteNode(value)) {
    return value;
  }

  return View.fragment(normalizeChildren(value));
}

function buildElement(tag, props = {}) {
  const attrs = [];
  const events = [];

  for (const [rawName, value] of Object.entries(props)) {
    if (internalProps.has(rawName) || value === null || value === undefined) {
      continue;
    }

    const eventName = eventNameFromProp(rawName, value);
    if (eventName) {
      events.push([eventName, value]);
      continue;
    }

    if (value === false) {
      continue;
    }

    const attrName = normalizeAttrName(rawName);
    attrs.push(attrFromValue(attrName, value));
  }

  return View.element(tag, attrs, events, normalizeChildren(props.children), undefined);
}

function withKey(node, key, props) {
  if (key === undefined || key === null) {
    return node;
  }

  return {
    TAG: "Keyed",
    key: String(key),
    identity: props ?? {},
    child: node,
  };
}

export function jsx(type, props, key) {
  const nextProps = props ?? {};

  if (type === Fragment) {
    return withKey(View.fragment(normalizeChildren(nextProps.children)), key, nextProps);
  }

  if (typeof type === "string") {
    return withKey(buildElement(type, nextProps), key, nextProps);
  }

  if (typeof type === "function") {
    return withKey(
      {
        TAG: "LazyComponent",
        _0: () => normalizeNode(type(nextProps)),
      },
      key,
      nextProps,
    );
  }

  throw new TypeError(`Unsupported Xote JSX element type: ${String(type)}`);
}

export const jsxs = jsx;
