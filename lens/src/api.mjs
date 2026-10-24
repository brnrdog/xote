// The public API, read from Xote's `.resi` files — the same boundary the
// repository's `test:exports` and `test:boundary` guardrails enforce — so what
// an agent is told it may use cannot drift from what actually compiles.

import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const KEYWORDS = /^(let|type|module|external|exception)\b/;

/* Brace depth change of one line, ignoring braces inside strings, template
   literals and comments. `state` carries an open block comment across lines. */
function scanLine(line, state) {
  let delta = 0;
  let i = 0;
  while (i < line.length) {
    const c = line[i];
    const next = line[i + 1];
    if (state.comment > 0) {
      if (c === "*" && next === "/") {
        state.comment--;
        i += 2;
      } else if (c === "/" && next === "*") {
        state.comment++;
        i += 2;
      } else i++;
      continue;
    }
    if (c === "/" && next === "*") {
      state.comment++;
      i += 2;
    } else if (c === "/" && next === "/") {
      break;
    } else if (c === '"' || c === "`") {
      const quote = c;
      i++;
      while (i < line.length && line[i] !== quote) i += line[i] === "\\" ? 2 : 1;
      i++;
    } else {
      if (c === "{") delta++;
      if (c === "}") delta--;
      i++;
    }
  }
  return delta;
}

/* Strip comment markers and common indentation from a doc comment. */
function cleanDoc(lines) {
  const text = lines
    .join("\n")
    .replace(/^\s*\/\*\*?/, "")
    .replace(/\*\/\s*$/, "");
  const body = text.split("\n");
  const indents = body.filter((l) => l.trim()).map((l) => l.match(/^\s*/)[0].length);
  const cut = indents.length ? Math.min(...indents) : 0;
  return body
    .map((l) => l.slice(cut))
    .join("\n")
    .trim();
}

function nameOf(declaration) {
  const m = declaration.match(/^(?:let|type|module|external|exception)\s+(?:rec\s+|type\s+)?([A-Za-z_][\w']*)/);
  return m ? m[1] : "?";
}

/* Parse one `.resi` into its header doc and its declarations, nested modules
   flattened with dotted names (`Show.make`). */
export function parseResi(source, moduleName) {
  const lines = source.split("\n");
  const items = [];
  const state = { comment: 0 };
  const stack = [{ prefix: "", depth: 0 }];
  let depth = 0;
  let pendingDoc = null;
  let docLines = null;
  let current = null;
  let header = null;
  let seenDeclaration = false;

  const close = () => {
    if (current) {
      current.signature = current.lines.join("\n").replace(/\s+$/, "");
      delete current.lines;
      items.push(current);
      current = null;
    }
  };

  for (const line of lines) {
    const trimmed = line.trim();
    const startDepth = depth;
    const wasInComment = state.comment > 0;

    if (!wasInComment && trimmed.startsWith("/*")) {
      docLines = [line];
    } else if (docLines) {
      docLines.push(line);
    }
    const delta = scanLine(line, state);
    depth += delta;

    if (docLines && state.comment === 0) {
      const doc = cleanDoc(docLines);
      docLines = null;
      if (!seenDeclaration && header === null) header = doc;
      else pendingDoc = doc;
      continue;
    }
    if (docLines || wasInComment) continue;

    const frame = stack[stack.length - 1];
    if (startDepth === frame.depth && KEYWORDS.test(trimmed)) {
      close();
      seenDeclaration = true;
      const declaration = trimmed;
      const name = nameOf(declaration);
      const kind = declaration.split(/\s/)[0];
      current = {
        kind,
        name: frame.prefix + name,
        doc: pendingDoc ?? "",
        deprecated: /@deprecated/.test(pendingDoc ?? ""),
        lines: [line.slice(line.indexOf(trimmed[0]))],
      };
      pendingDoc = null;
      if (kind === "module" && delta > 0) {
        current.signature = declaration;
        delete current.lines;
        items.push(current);
        current = null;
        stack.push({ prefix: frame.prefix + name + ".", depth: depth });
      }
      continue;
    }
    if (/^@deprecated/.test(trimmed) && startDepth === frame.depth) {
      close();
      pendingDoc = (pendingDoc ? pendingDoc + "\n" : "") + trimmed;
      continue;
    }
    if (depth < frame.depth && stack.length > 1) {
      close();
      stack.pop();
      continue;
    }
    if (current) {
      if (trimmed === "") close();
      else current.lines.push(line.replace(new RegExp(`^ {0,${2 * (stack.length - 1)}}`), ""));
    }
  }
  close();
  for (const item of items) {
    if (/@deprecated/.test(item.signature ?? "")) item.deprecated = true;
  }
  return { module: moduleName, doc: header ?? "", items };
}

/* Every public module of the Xote package at `xoteRoot`, parsed. A module is
   public exactly when it has a `.resi` (plus `XoteJSX`, which has none). */
export function loadApi(xoteRoot) {
  const src = join(xoteRoot, "src");
  return readdirSync(src)
    .filter((file) => file.endsWith(".resi"))
    .sort()
    .map((file) => parseResi(readFileSync(join(src, file), "utf8"), file.replace(/\.resi$/, "")));
}

const firstSentence = (doc) => {
  const text = doc.replace(/\s+/g, " ").trim();
  const m = text.match(/^(.*?[.!?])(\s|$)/);
  return m ? m[1] : text;
};

/* Look up `View`, `View.tracked` or `View.Show.make`. */
export function query(api, path) {
  if (!path) {
    return {
      kind: "modules",
      modules: api.map((m) => ({ module: m.module, summary: firstSentence(m.doc), items: m.items.length })),
    };
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
  return {
    kind: "error",
    message: `${moduleName} has no public ${name}. It is either internal or does not exist; ${moduleName} exports: ${module.items
      .filter((i) => !i.name.includes("."))
      .map((i) => i.name)
      .join(", ")}`,
  };
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
