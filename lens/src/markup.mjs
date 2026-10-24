// Comparing server markup with what the client renders, for hydration.
//
// Server HTML carries hydration markers (`<!--$-->`, `<!--kl-->`, `<!--k:a-->`
// …) and the client wraps signal fragments in `display: contents` divs; both
// are bookkeeping, not content. The comparison walks both trees with those
// removed and reports where they first disagree, as a path into the tree.

import { JSDOM } from "jsdom";

const parse = (html) => JSDOM.fragment(`<div>${html}</div>`).firstChild;

const isFragmentWrapper = (node) =>
  node.nodeType === 1 && node.tagName === "DIV" && node.getAttribute("style") === "display: contents" && node.attributes.length === 1;

/* Children with markers, empty text and fragment wrappers flattened away. */
function contentChildren(node) {
  const out = [];
  for (const child of node.childNodes) {
    if (child.nodeType === 8) continue;
    if (child.nodeType === 3) {
      if (child.data.trim() === "") continue;
      /* Adjacent text nodes are one run of text however they were split. */
      const last = out[out.length - 1];
      if (last && last.nodeType === 3) {
        out[out.length - 1] = { nodeType: 3, data: last.data + child.data };
        continue;
      }
      out.push(child);
    } else if (isFragmentWrapper(child)) {
      out.push(...contentChildren(child));
    } else out.push(child);
  }
  return out;
}

function label(node) {
  if (node.nodeType === 3) return "#text";
  const id = node.getAttribute("id");
  return node.tagName.toLowerCase() + (id ? `#${id}` : "");
}

function attributes(node) {
  const out = {};
  for (const attr of node.attributes) {
    if (attr.name === "style" && attr.value === "display: contents") continue;
    out[attr.name] = attr.value;
  }
  return out;
}

function compare(server, client, path, out) {
  if (out.length >= 10) return;
  const a = contentChildren(server);
  const b = contentChildren(client);
  const n = Math.max(a.length, b.length);
  for (let i = 0; i < n && out.length < 10; i++) {
    const s = a[i];
    const c = b[i];
    const here = [...path, s ? label(s) : label(c)];
    if (!s || !c) {
      out.push({ path: here.join(" > "), server: s ? describe(s) : "(nothing)", client: c ? describe(c) : "(nothing)" });
      continue;
    }
    if (s.nodeType !== c.nodeType || (s.nodeType === 1 && s.tagName !== c.tagName)) {
      out.push({ path: here.join(" > "), server: describe(s), client: describe(c) });
      continue;
    }
    if (s.nodeType === 3) {
      if (s.data.trim() !== c.data.trim()) out.push({ path: here.join(" > "), server: JSON.stringify(s.data), client: JSON.stringify(c.data) });
      continue;
    }
    const sa = attributes(s);
    const ca = attributes(c);
    for (const name of new Set([...Object.keys(sa), ...Object.keys(ca)])) {
      if (sa[name] !== ca[name]) {
        out.push({
          path: `${here.join(" > ")} [${name}]`,
          server: sa[name] === undefined ? "(absent)" : JSON.stringify(sa[name]),
          client: ca[name] === undefined ? "(absent)" : JSON.stringify(ca[name]),
        });
      }
    }
    compare(s, c, here, out);
  }
}

function describe(node) {
  if (node.nodeType === 3) return JSON.stringify(node.data.length > 40 ? node.data.slice(0, 37) + "..." : node.data);
  const html = node.outerHTML;
  return html.length > 80 ? html.slice(0, 77) + "..." : html;
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
  if (!match) return {};
  try {
    return JSON.parse(match[1].replaceAll("<\\/script>", "</script>").replaceAll("<\\!--", "<!--"));
  } catch {
    return {};
  }
}

const MARKERS = {
  $: "reactive text",
  "#": "reactive fragment (tracked block, Show, Switch, …)",
  kl: "keyed list",
  lc: "component",
};

/* Server markup as an indented outline, with each hydration marker named:
   what the client's hydration walker will look for, and where. */
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
          const meaning = data.startsWith("k:") ? `keyed row "${data.slice(2)}"` : MARKERS[data] ?? "comment";
          lines.push(`${pad}<!--${data}-->  ${meaning}`);
          depth++;
        }
      } else if (child.nodeType === 3) {
        if (child.data.trim()) lines.push(`${pad}${JSON.stringify(child.data.length > 60 ? child.data.slice(0, 57) + "..." : child.data)}`);
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
