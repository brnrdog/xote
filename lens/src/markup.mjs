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
