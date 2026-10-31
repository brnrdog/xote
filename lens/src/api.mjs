// The public API, read from Xote's `.resi` files (the boundary the repo's
// `test:exports` and `test:boundary` guardrails enforce), so what an agent is
// told it may use cannot drift from what actually compiles.

import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const KEYWORDS = /^(let|type|module|external|exception)\b/;

/* Brace depth change of one line, ignoring braces inside strings, template
   literals and comments. `state.comment` carries open block comments across lines. */
function scanLine(line, state) {
  let delta = 0;
  for (let i = 0; i < line.length; i++) {
    const pair = line.slice(i, i + 2);
    if (pair === "/*") {
      state.comment++;
      i++;
    } else if (state.comment > 0) {
      if (pair === "*/") {
        state.comment--;
        i++;
      }
    } else if (pair === "//") break;
    else if (line[i] === '"' || line[i] === "`") {
      const quote = line[i++];
      while (i < line.length && line[i] !== quote) i += line[i] === "\\" ? 2 : 1;
    } else if (line[i] === "{") delta++;
    else if (line[i] === "}") delta--;
  }
  return delta;
}

/* Strip comment markers and common indentation from a doc comment. */
function cleanDoc(lines) {
  const body = lines.join("\n").replace(/^\s*\/\*\*?/, "").replace(/\*\/\s*$/, "").split("\n");
  const indents = body.filter((l) => l.trim()).map((l) => l.match(/^\s*/)[0].length);
  const cut = indents.length ? Math.min(...indents) : 0;
  return body.map((l) => l.slice(cut)).join("\n").trim();
}

function nameOf(declaration) {
  const m = declaration.match(/^(?:let|type|module|external|exception)\s+(?:rec\s+|type\s+)?([A-Za-z_][\w']*)/);
  return m ? m[1] : "?";
}

/* Parse one `.resi` into its header doc and its declarations, nested modules
   flattened with dotted names (`Show.make`). */
export function parseResi(source, moduleName) {
  const items = [];
  const state = { comment: 0 };
  const stack = [{ prefix: "", depth: 0 }];
  let depth = 0;
  let header = null;
  let seenDeclaration = false;
  let pendingDoc = null;
  let docLines = null;
  let current = null;

  const close = () => {
    if (current) {
      const { lines, ...item } = current;
      items.push({ ...item, signature: lines.join("\n").replace(/\s+$/, "") });
    }
    current = null;
  };

  for (const line of source.split("\n")) {
    const trimmed = line.trim();
    const startDepth = depth;
    const wasInComment = state.comment > 0;
    if (!wasInComment && trimmed.startsWith("/*")) docLines = [line];
    else docLines?.push(line);
    const delta = scanLine(line, state);
    depth += delta;

    if (docLines && state.comment === 0) {
      /* The first doc before any declaration is the module's own. */
      if (!seenDeclaration && header === null) header = cleanDoc(docLines);
      else pendingDoc = cleanDoc(docLines);
      docLines = null;
      continue;
    }
    if (docLines || wasInComment) continue;

    const frame = stack[stack.length - 1];
    if (startDepth === frame.depth && KEYWORDS.test(trimmed)) {
      close();
      seenDeclaration = true;
      const name = nameOf(trimmed);
      const kind = trimmed.split(/\s/)[0];
      const item = { kind, name: frame.prefix + name, doc: pendingDoc ?? "", deprecated: /@deprecated/.test(pendingDoc ?? "") };
      pendingDoc = null;
      if (kind === "module" && delta > 0) {
        items.push({ ...item, signature: trimmed });
        stack.push({ prefix: `${frame.prefix}${name}.`, depth });
      } else current = { ...item, lines: [line.slice(line.indexOf(trimmed[0]))] };
    } else if (/^@deprecated/.test(trimmed) && startDepth === frame.depth) {
      close();
      pendingDoc = (pendingDoc ? pendingDoc + "\n" : "") + trimmed;
    } else if (depth < frame.depth && stack.length > 1) {
      close();
      stack.pop();
    } else if (current) {
      if (trimmed === "") close();
      else current.lines.push(line.replace(new RegExp(`^ {0,${2 * (stack.length - 1)}}`), ""));
    }
  }
  close();
  for (const item of items) if (/@deprecated/.test(item.signature)) item.deprecated = true;
  return { module: moduleName, doc: header ?? "", items };
}

/* Every public module of the Xote package at `xoteRoot`, parsed. A module is
   public exactly when it has a `.resi`. */
export function loadApi(xoteRoot) {
  const src = join(xoteRoot, "src");
  return readdirSync(src)
    .filter((file) => file.endsWith(".resi"))
    .sort()
    .map((file) => parseResi(readFileSync(join(src, file), "utf8"), file.replace(/\.resi$/, "")));
}

const firstSentence = (doc) => {
  const text = doc.replace(/\s+/g, " ").trim();
  return text.match(/^(.*?[.!?])(\s|$)/)?.[1] ?? text;
};

/* Look up `View`, `View.tracked` or `View.Show.make`. */
export function query(api, path) {
  if (!path) {
    return { kind: "modules", modules: api.map((m) => ({ module: m.module, summary: firstSentence(m.doc), items: m.items.length })) };
  }
  const [moduleName, ...rest] = path.split(".");
  const module = api.find((m) => m.module === moduleName);
  if (!module) {
    return { kind: "error", message: `no public module ${moduleName}; public modules: ${api.map((m) => m.module).join(", ")}` };
  }
  if (rest.length === 0) return { kind: "module", ...module };
  const name = rest.join(".");
  /* A nested module comes with its members. */
  const matched = module.items.filter((item) => item.name === name || item.name.startsWith(name + "."));
  if (matched.length) return { kind: "items", module: module.module, items: matched };
  const exported = module.items.filter((i) => !i.name.includes(".")).map((i) => i.name);
  return { kind: "error", message: `${moduleName} has no public ${name}. It is either internal or does not exist; ${moduleName} exports: ${exported.join(", ")}` };
}

/* A compact Markdown digest of the whole public surface, for an agent's
   context: every declaration's signature and the first paragraph of its doc. */
export function digest(api) {
  const out = [
    "# Xote public API",
    "",
    "Generated from the `.resi` interface files: everything here is public, and nothing else is.",
    "Modules are reached as `Xote.<Module>` (or bare, with `-open Xote`).",
    "",
  ];
  for (const module of api) {
    out.push(`## ${module.module}`, "");
    if (module.doc) out.push(module.doc.split("\n\n")[0], "");
    out.push("```rescript");
    for (const item of module.items) {
      const para = item.doc.split("\n\n")[0].replace(/\s+/g, " ").trim();
      if (para) out.push(`/* ${para.length > 300 ? para.slice(0, 297) + "..." : para} */`);
      out.push(item.signature);
    }
    out.push("```", "");
  }
  return out.join("\n");
}
