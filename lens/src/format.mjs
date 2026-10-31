// Human-readable views of the JSON every command produces. The JSON is the
// contract (what `--json` and the MCP server return); this is only a view.

const plural = (n, word, many = `${word}s`) => `${n} ${n === 1 ? word : many}`;
const truncate = (text, max) => (text.length > max ? `${text.slice(0, max - 1)}…` : text);
const ids = (list) => list.map((id) => `#${id}`).join(" ");
const list = (parts, separator) => parts.filter(Boolean).join(separator);
const at = (site) => (site ? `  (${site})` : "");

export function nodeLabel(node) {
  if (!node) return "?";
  const binding = node.binding ? ` (${node.binding.what} → ${node.binding.target})` : "";
  return `${node.kind ?? "node"}${node.name ? ` "${node.name}"` : ` #${node.id}`}${binding}`;
}

export function formatDiagnostics(diagnostics = []) {
  if (!diagnostics.length) return [];
  return [
    "diagnostics:",
    ...diagnostics.flatMap((d) => [
      `  ${d.severity} ${d.rule}${d.site ? ` ${d.site}` : d.path ? ` ${d.path}` : ""}`,
      ...d.message.split("\n").map((line) => `    ${line}`),
      ...(d.fix ? [`    fix: ${d.fix}`] : []),
    ]),
  ];
}

export function formatCounts(c) {
  return [
    plural(c.writes, "write"),
    plural(c.computeds, "computed"),
    `${plural(c.effects, "effect")} (${plural(c.bindings, "binding")})`,
    plural(c.domWrites, "DOM write"),
    `scopes +${c.scopesCreated}/-${c.scopesDisposed}`,
    ...(c.reconciled ? [plural(c.reconciled, "keyed pass", "keyed passes")] : []),
  ].join(" · ");
}

function stateStatus(e) {
  if (!e.inPayload) return "restored, but the server never sent it";
  if (!e.restored) return "sent, never restored";
  return e.decoded ? "restored" : "could not be decoded";
}

export function formatRender(r, { html = false, markers = false } = {}) {
  const how = { client: "rendered client-side", ssr: "rendered on the server", hydrate: "server-rendered and hydrated" }[r.mode];
  const out = [`${r.target} (${r.file}) ${how}`];
  if (r.summary) {
    const { nodes: n, bindings, liveScopes } = r.summary;
    const scopes = Object.entries(liveScopes).map(([k, v]) => `${k} ${v}`).join(", ");
    out.push(
      `  graph: ${plural(n.signal, "signal")}, ${plural(n.computed, "computed")}, ${plural(n.effect, "effect")} (${plural(bindings, "binding")})${scopes ? `; live scopes: ${scopes}` : ""}`,
    );
  }
  if (!r.status?.signals) out.push("  graph: not visible (rescript-signals without debug hooks)");
  const markup = r.html ?? r.serverHtml ?? "";
  out.push(`  html: ${html ? markup : truncate(markup, 400)}`);
  if (html && r.mode !== "client" && r.serverHtml && r.html !== undefined) out.push(`  server html: ${r.serverHtml}`);
  if (r.state?.length) {
    out.push("  ssr state:");
    for (const e of r.state) {
      out.push(`    "${e.key}"${e.inPayload ? ` = ${JSON.stringify(e.server)}` : ""}: ${stateStatus(e)}${e.node ? ` → ${nodeLabel(e.node)}` : ""}`);
    }
  }
  if (r.outline && markers) out.push("  server markup:", ...r.outline.map((line) => `    ${line}`));
  if (r.mismatches?.length) {
    out.push(`  hydration: ${plural(r.mismatches.length, "mismatch", "mismatches")}`);
    for (const m of r.mismatches) out.push(`    ${m.path}: server ${m.server}, client ${m.client}`);
  } else if (r.mode === "hydrate") out.push("  hydration: server and client markup agree");
  return [...out, ...formatDiagnostics(r.diagnostics)].join("\n");
}

export function formatAct(a, { html = false } = {}) {
  return [
    `${a.action} ${a.selector}${a.value !== undefined ? ` ${JSON.stringify(a.value)}` : ""}`,
    `  ${formatCounts(a.counts)}`,
    ...a.writes.map((w) => `  wrote ${nodeLabel(w)}${w.value !== undefined ? ` = ${w.value}` : ""}${at(w.site)}`),
    ...a.ran.map((r) => `  ran   ${nodeLabel(r)}${at(r.binding ? undefined : r.site)}`),
    ...a.reconciled.map((p) => `  keyed pass: kept ${p.kept}, created ${p.created}, removed ${p.removed}, moved ${p.moved}, rebuilt ${p.rebuilt}`),
    ...(html ? [`  html: ${a.html}`] : []),
    ...formatDiagnostics(a.diagnostics),
  ].join("\n");
}

const VERBS = { written: "written", recomputed: "recomputed", ran: "ran", created: "ran for the first time (created)" };

/* A cause tree, drawn with box-drawing branches under a root line. */
function formatCause(cause, out, prefix = "  ", branch = "", childPrefix = prefix) {
  out.push(`${prefix}${branch}${nodeLabel(cause)} ${VERBS[cause.action]}${at(cause.site)}`);
  cause.causes.forEach((c, i) => {
    const last = i === cause.causes.length - 1;
    formatCause(c, out, childPrefix, last ? "└─ " : "├─ ", childPrefix + (last ? "   " : "│  "));
  });
  return out;
}

export function formatWhy(w) {
  if (w.cause !== undefined) {
    return [`why #${w.id}`, ...(w.cause ? formatCause(w.cause, []) : ["  no run of this node is in the history"])].join("\n");
  }
  const out = [`why ${w.selector}`];
  if (!w.writers.length) out.push(`  ${w.note}`);
  for (const writer of w.writers) {
    if (writer.cause) formatCause(writer.cause, out);
    else out.push(`  ${nodeLabel(writer)}: no run in the history`);
  }
  return out.join("\n");
}

export function formatGraph(g) {
  const out = g.nodes.map((node) => {
    const value = node.value !== undefined ? ` = ${truncate(node.value, 60)}` : "";
    const edges = list([node.sources.length ? `reads ${ids(node.sources)}` : "", node.observers.length ? `read by ${ids(node.observers)}` : ""], "; ");
    const flags = list([node.disposed ? "disposed" : "", node.scope !== undefined ? `scope ${node.scope}` : ""], ", ");
    return `#${node.id} ${nodeLabel(node)}${value}${edges ? `  ${edges}` : ""}${flags ? `  [${flags}]` : ""}${node.site ? `  ${node.site}` : ""}`;
  });
  if (g.scopes.length) {
    out.push("scopes:");
    for (const s of g.scopes) {
      out.push(`  ${s.id} ${s.kind}${s.key !== undefined ? ` "${s.key}"` : ""}${s.parent !== undefined ? ` in ${s.parent}` : ""}${s.disposed ? " (released)" : ""}`);
    }
  }
  return out.join("\n");
}

export function formatCheck(c) {
  const counts = { error: 0, warning: 0, info: 0 };
  for (const d of c.diagnostics) counts[d.severity]++;
  return [
    c.ok ? "check: ok" : `check: failed${c.buildExitCode ? " (build failed)" : ""}`,
    `  ${plural(counts.error, "error")}, ${plural(counts.warning, "warning")}, ${counts.info} info`,
    ...formatDiagnostics(c.diagnostics),
  ].join("\n");
}

export function formatApi(q) {
  switch (q.kind) {
    case "modules":
      return [
        "public modules:",
        ...q.modules.map((m) => `  ${m.module.padEnd(12)} ${truncate(m.summary, 100)}`),
        "",
        "`xote-lens api <Module>` lists a module; `xote-lens api <Module>.<name>` shows one declaration.",
      ].join("\n");
    case "module":
      return [
        q.module,
        ...(q.doc ? ["", q.doc, ""] : []),
        ...q.items.map((i) => `  ${i.signature.split("\n")[0]}${i.signature.includes("\n") ? " …" : ""}${i.deprecated ? "  (deprecated)" : ""}`),
      ].join("\n");
    case "items":
      return q.items.map((i) => [`${q.module}.${i.name}`, i.signature, ...(i.doc ? ["", i.doc] : [])].join("\n")).join("\n\n");
    case "error":
      return q.message;
    default:
      return JSON.stringify(q, null, 2);
  }
}

/* Source with each ppx decision under its line, a caret at its column. Only
   lines with decisions are shown, with `context` lines around them. */
export function formatExpand(result, { context = 1 } = {}) {
  const show = new Set();
  result.lines.forEach((l, i) => {
    if (l.sites.length) for (let d = -context; d <= context; d++) show.add(i + d);
  });
  const width = String(result.lines.length).length;
  const gutter = " ".repeat(width);
  const out = [result.file];
  let last = -2;
  result.lines.forEach((l, i) => {
    if (!show.has(i)) return;
    if (i !== last + 1) out.push(`${gutter} ┆`);
    last = i;
    out.push(`${String(l.line).padStart(width)} │ ${l.text}`);
    for (const site of [...l.sites].sort((a, b) => a.column - b.column)) {
      out.push(`${gutter} │ ${" ".repeat(Math.max(0, site.column - 1))}^ ${site.description}`);
    }
  });
  return out.join("\n");
}
