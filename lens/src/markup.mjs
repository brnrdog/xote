// Server markup against what the client renders, for hydration. Hydration
// markers (`<!--$-->`, `<!--kl-->`, `<!--k:a-->` …) and the client's
// `display: contents` fragment wrappers are bookkeeping, not content: the
// comparison walks both trees without them and reports where they disagree.

import { JSDOM } from "jsdom";

const parse = (html) => JSDOM.fragment(`<div>${html}</div>`).firstChild;
const clip = (text, max) => (text.length > max ? text.slice(0, max - 3) + "..." : text);
const WRAPPER_STYLE = "display: contents";

const isFragmentWrapper = (node) =>
  node.nodeType === 1 && node.tagName === "DIV" && node.getAttribute("style") === WRAPPER_STYLE && node.attributes.length === 1;

/* Children with markers, empty text and fragment wrappers flattened away;
   adjacent text nodes are one run of text however they were split. */
function contentChildren(node) {
  const out = [];
  for (const child of node.childNodes) {
    const last = out[out.length - 1];
    if (child.nodeType === 8 || (child.nodeType === 3 && child.data.trim() === "")) continue;
    if (child.nodeType === 3 && last?.nodeType === 3) out[out.length - 1] = { nodeType: 3, data: last.data + child.data };
    else if (isFragmentWrapper(child)) out.push(...contentChildren(child));
    else out.push(child);
  }
  return out;
}

const firstClass = (node) => (node.getAttribute("class") ?? "").trim().split(/\s+/)[0];

/* A step of a mismatch path: the id, or the first class when both sides
   agree on it (a differing class is itself the mismatch being reported). */
function label(node, other) {
  if (node.nodeType === 3) return "#text";
  const tag = node.tagName.toLowerCase();
  if (node.getAttribute("id")) return `${tag}#${node.getAttribute("id")}`;
  const cls = firstClass(node);
  return cls && (!other || (other.nodeType === 1 && firstClass(other) === cls)) ? `${tag}.${cls}` : tag;
}

const attributes = (node) =>
  Object.fromEntries([...node.attributes].filter((a) => !(a.name === "style" && a.value === WRAPPER_STYLE)).map((a) => [a.name, a.value]));

const describe = (node) => (node.nodeType === 3 ? JSON.stringify(clip(node.data, 40)) : clip(node.outerHTML, 80));
const quoted = (value) => (value === undefined ? "(absent)" : JSON.stringify(value));

function compare(server, client, path, out) {
  const a = contentChildren(server);
  const b = contentChildren(client);
  for (let i = 0; i < Math.max(a.length, b.length) && out.length < 10; i++) {
    const [s, c] = [a[i], b[i]];
    const here = [...path, s ? label(s, c) : label(c)];
    const at = here.join(" > ");
    if (!s || !c) out.push({ path: at, server: s ? describe(s) : "(nothing)", client: c ? describe(c) : "(nothing)" });
    else if (s.nodeType !== c.nodeType || (s.nodeType === 1 && s.tagName !== c.tagName)) out.push({ path: at, server: describe(s), client: describe(c) });
    else if (s.nodeType === 3) {
      if (s.data.trim() !== c.data.trim()) out.push({ path: at, server: JSON.stringify(s.data), client: JSON.stringify(c.data) });
    } else {
      const [sa, ca] = [attributes(s), attributes(c)];
      for (const name of new Set([...Object.keys(sa), ...Object.keys(ca)])) {
        if (sa[name] !== ca[name]) out.push({ path: `${at} [${name}]`, server: quoted(sa[name]), client: quoted(ca[name]) });
      }
      compare(s, c, here, out);
    }
  }
}

/* The client renderer writes `value`, `checked`, `selected` and `disabled` as
   DOM properties, which serialised markup does not show. Copy them back onto
   attributes, as the server writes them, before comparing. */
export function reflectProperties(root) {
  for (const el of root.querySelectorAll("input, textarea, select, option, button, fieldset")) {
    if ("value" in el && el.tagName !== "BUTTON" && el.tagName !== "FIELDSET" && el.type !== "checkbox" && el.type !== "radio") {
      el.setAttribute("value", el.value);
    }
    for (const flag of ["checked", "selected", "disabled"]) {
      if (!(flag in el)) continue;
      if (el[flag]) el.setAttribute(flag, "");
      else el.removeAttribute(flag);
    }
  }
  return root;
}

/* Up to ten places where `serverHtml` and `clientHtml` differ in content. */
export function compareMarkup(serverHtml, clientHtml) {
  const out = [];
  compare(parse(serverHtml), parse(clientHtml), [], out);
  return out;
}

/* The JSON inside SSRState.generateScript's `<script>`. */
export function parseStateScript(script) {
  const match = /window\.__XOTE_STATE__=([\s\S]*);<\/script>/.exec(script ?? "");
  try {
    return match ? JSON.parse(match[1].replaceAll("<\\/script>", "</script>").replaceAll("<\\!--", "<!--")) : {};
  } catch {
    return {};
  }
}

const MARKERS = { $: "reactive text", "#": "reactive fragment (tracked block, Show, Switch, …)", kl: "keyed list", lc: "component" };

/* Server markup as an indented outline naming each hydration marker: what
   the client's hydration walker will look for, and where. */
export function markerOutline(html, { limit = 200 } = {}) {
  const lines = [];
  const walk = (node, depth) => {
    for (const child of node.childNodes) {
      if (lines.length >= limit) return;
      const pad = "  ".repeat(depth);
      if (child.nodeType === 8) {
        const data = child.data;
        if (data.startsWith("/")) {
          depth = Math.max(0, depth - 1);
          lines.push(`${"  ".repeat(depth)}<!--${data}-->`);
        } else {
          lines.push(`${pad}<!--${data}-->  ${data.startsWith("k:") ? `keyed row "${data.slice(2)}"` : MARKERS[data] ?? "comment"}`);
          depth++;
        }
      } else if (child.nodeType === 3) {
        if (child.data.trim()) lines.push(`${pad}${JSON.stringify(clip(child.data, 60))}`);
      } else if (child.nodeType === 1) {
        const id = child.getAttribute("id");
        const cls = child.getAttribute("class");
        lines.push(`${pad}<${child.tagName.toLowerCase()}${id ? `#${id}` : ""}${cls ? `.${cls.split(/\s+/).join(".")}` : ""}>`);
        walk(child, depth + 1);
      }
    }
  };
  walk(parse(html), 0);
  if (lines.length >= limit) lines.push("…");
  return lines;
}
