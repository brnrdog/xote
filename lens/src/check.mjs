// Static findings: the compiler's own diagnostics, the ppx's site map, and a
// scan of the sources for patterns AGENTS.md warns about.

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";
import { build, toPosix, walk } from "./project.mjs";

const stripAnsi = (text) => text.replace(/\x1b\[[0-9;]*m/g, "");

/* Parse ReScript's build output into diagnostics. Each finding opens with a
   headline ("We've found a bug for you!" / "Warning number N"), then a
   location line, a code excerpt, and the message. */
export function parseCompilerOutput(output, root) {
  const lines = stripAnsi(output).split("\n");
  const out = [];
  let current = null;
  const flush = () => {
    if (!current) return;
    const message = current.message.join("\n").trim().replace(/\n{3,}/g, "\n\n");
    const diagnostic = {
      rule: current.severity === "error" ? "compile-error" : `compiler-warning-${current.number}`,
      severity: current.severity,
      message,
      ...(current.site ? { site: current.site } : {}),
    };
    if (current.severity === "error" && /option<unit => unit>/.test(message)) {
      diagnostic.rule = "effect-returns-unit";
      diagnostic.fix =
        "An effect body must return option<unit => unit>: end it with None, or Some(cleanup) to run cleanup before the next run and on disposal.";
    }
    out.push(diagnostic);
    current = null;
  };
  for (const raw of lines) {
    const line = raw.replace(/\r$/, "");
    const trimmed = line.trim();
    const warning = trimmed.match(/^Warning number (\d+)/);
    if (/^We've found a bug for you!/.test(trimmed) || warning) {
      flush();
      current = { severity: warning ? "warning" : "error", number: warning?.[1], site: null, message: [], expectLocation: true };
      continue;
    }
    if (!current) continue;
    if (current.expectLocation && trimmed) {
      const m = trimmed.match(/^(.*?\.resi?):(\d+):(\d+)/);
      if (m) current.site = `${toPosix(relative(root, m[1]))}:${m[2]}:${m[3]}`;
      current.expectLocation = false;
      continue;
    }
    if (/^(Incremental build failed|Failed to Compile|Compiled \d+ modules|Parsed \d+ source files|Cleaned)/.test(trimmed)) {
      flush();
      continue;
    }
    /* Code excerpt lines carry a gutter: "  27 │ ..." or "     ┆ ...". */
    if (/^\s*\d*\s*[│┆.]\s/.test(line) || /^\s*\d+\s*[│┆]/.test(line)) continue;
    current.message.push(trimmed);
  }
  flush();
  return out;
}

/* Diagnostics from the site maps the ppx wrote with `-sitemap`. */
export function sitemapDiagnostics(root) {
  const dir = join(root, "lib", "xote-sitemap");
  if (!existsSync(dir)) return { found: false, diagnostics: [] };
  const out = [];
  for (const file of readdirSync(dir).filter((f) => f.endsWith(".json"))) {
    let map;
    try {
      map = JSON.parse(readFileSync(join(dir, file), "utf8"));
    } catch {
      continue;
    }
    const sourceDir = toPosix(map.file).split("/").slice(0, -1).join("/");
    const site = (s) => (sourceDir ? `${sourceDir}/${s}` : s);
    for (const entry of map.sites) {
      if (entry.kind === "one-shot-prop") {
        out.push({
          rule: "one-shot-prop",
          severity: "warning",
          message: `prop "${entry.prop}" of <${entry.component}> reads a signal eagerly, so it is read once, when the component renders, and never updates. If it should follow the signal, pass the signal itself (typed Signal.t or MaybeSignal.t in ${entry.component}); if a one-shot read is intended, use Signal.peek to say so.`,
          site: site(entry.site),
        });
      } else if (entry.kind === "probe") {
        out.push({
          rule: "possible-hidden-read",
          severity: "info",
          message: `this ${entry.role === "condition" ? "condition" : "value"} calls something @xote.component cannot see into; if that reads a signal, it renders once and never updates. \`xote-lens render\` reports it when it does (rule unresolved-read).`,
          site: site(entry.site),
        });
      }
    }
  }
  return { found: true, diagnostics: out };
}

const JS_GLOBALS = new Set(
  "arguments this undefined null true false NaN Infinity globalThis window document console Object Array String Number Boolean Symbol Math JSON Date RegExp Error Promise Map Set WeakMap WeakSet WeakRef Reflect Proxy parseInt parseFloat setTimeout clearTimeout setInterval clearInterval queueMicrotask requestAnimationFrame process require module exports new return typeof instanceof function var let const if else for while do switch case break continue default try catch finally throw in of delete void yield await async class extends super import export".split(
    " ",
  ),
);

/* `%raw` that refers to a surrounding ReScript binding by name works until the
   compiler renames or inlines that binding, then fails at runtime with a
   ReferenceError. Flags raw JavaScript naming a top-level `let` of the same
   file that the raw code does not declare itself. */
export function rawDiagnostics(root) {
  const out = [];
  for (const file of walk(root, (name) => name.endsWith(".res"))) {
    const source = readFileSync(file, "utf8");
    const bindings = new Set([...source.matchAll(/^let\s+(?:rec\s+)?([a-z_][\w']*)/gm)].map((m) => m[1]));
    for (const match of source.matchAll(/%raw\(\s*`([\s\S]*?)`\s*\)/g)) {
      const body = match[1];
      const declared = new Set(
        [...body.matchAll(/\b(?:var|let|const|function)\s+([A-Za-z_$][\w$]*)/g), ...body.matchAll(/function\s*[\w$]*\s*\(([^)]*)\)/g)]
          .flatMap((m) => m[1].split(","))
          .map((name) => name.trim().replace(/=.*$/, ""))
          .filter(Boolean),
      );
      const stripped = body.replace(/(["'])(?:\\.|(?!\1).)*\1/g, '""').replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, "");
      const captured = [...new Set([...stripped.matchAll(/(?<![.\w$])([A-Za-z_$][\w$]*)/g)].map((m) => m[1]))].filter(
        (name) => bindings.has(name) && !declared.has(name) && !JS_GLOBALS.has(name),
      );
      if (captured.length) {
        const line = source.slice(0, match.index).split("\n").length;
        out.push({
          rule: "raw-captures-binding",
          severity: "warning",
          message: `%raw refers to the ReScript binding${captured.length > 1 ? "s" : ""} ${captured.map((c) => `\`${c}\``).join(", ")} by name. The compiler may rename or inline ${captured.length > 1 ? "them" : "it"}, and the code then fails at runtime with a ReferenceError. Write the raw code as a self-contained function literal and pass the value in as an argument.`,
          site: `${toPosix(relative(root, file))}:${line}:1`,
        });
      }
    }
  }
  return out;
}

/* Build the project and gather every static finding. */
export async function check(root, { skipBuild = false } = {}) {
  const compiled = skipBuild ? { code: 0, output: "" } : await build(root);
  const compiler = parseCompilerOutput(compiled.output, root);
  const sitemap = sitemapDiagnostics(root);
  const diagnostics = [...compiler, ...sitemap.diagnostics, ...rawDiagnostics(root)];
  if (!sitemap.found) {
    diagnostics.push({
      rule: "no-sitemap",
      severity: "info",
      message:
        'no ppx site map found, so one-shot props and probe sites are not checked. Add "-sitemap" to the ppx flags: "ppx-flags": [["xote/ppx/ppx", "-sitemap"]].',
    });
  }
  return { ok: compiled.code === 0 && !diagnostics.some((d) => d.severity === "error"), buildExitCode: compiled.code, diagnostics };
}
