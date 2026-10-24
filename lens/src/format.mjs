// Human-readable rendering of the JSON every command produces. The JSON is the
// contract (it is what `--json` and the MCP server return); this is a view.

const plural = (n, word, many = `${word}s`) => `${n} ${n === 1 ? word : many}`;

const truncate = (text, max) => (text.length > max ? `${text.slice(0, max - 1)}…` : text);

export function nodeLabel(node) {
  if (!node) return "?";
  const name = node.name ? ` "${node.name}"` : ` #${node.id}`;
  const binding = node.binding ? ` (${node.binding.what} → ${node.binding.target})` : "";
  return `${node.kind ?? "node"}${name}${binding}`;
}

export function formatDiagnostics(diagnostics) {
  if (!diagnostics?.length) return [];
  const out = ["diagnostics:"];
  for (const d of diagnostics) {
    const where = d.site ? ` ${d.site}` : d.path ? ` ${d.path}` : "";
    out.push(`  ${d.severity} ${d.rule}${where}`);
    for (const line of d.message.split("\n")) out.push(`    ${line}`);
    if (d.fix) out.push(`    fix: ${d.fix}`);
  }
  return out;
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

export function formatRender(r, { html = false } = {}) {
  const out = [];
  const how = { client: "rendered client-side", ssr: "rendered on the server", hydrate: "server-rendered and hydrated" }[r.mode];
  out.push(`${r.target} (${r.file}) ${how}`);
  if (r.summary) {
    const n = r.summary.nodes;
    const scopes = Object.entries(r.summary.liveScopes)
      .map(([k, v]) => `${k} ${v}`)
      .join(", ");
    out.push(
      `  graph: ${plural(n.signal, "signal")}, ${plural(n.computed, "computed")}, ${plural(n.effect, "effect")} (${plural(r.summary.bindings, "binding")})${scopes ? `; live scopes: ${scopes}` : ""}`,
    );
  }
  if (!r.status?.signals) out.push("  graph: not visible (rescript-signals without debug hooks)");
  const markup = r.html ?? r.serverHtml ?? "";
  out.push(`  html: ${html ? markup : truncate(markup, 400)}`);
  if (r.mode !== "client" && r.serverHtml && r.html !== undefined && html) out.push(`  server html: ${r.serverHtml}`);
  if (r.mismatches?.length) {
    out.push(`  hydration: ${plural(r.mismatches.length, "mismatch", "mismatches")}`);
    for (const m of r.mismatches) out.push(`    ${m.path}: server ${m.server}, client ${m.client}`);
  } else if (r.mode === "hydrate") out.push("  hydration: server and client markup agree");
  out.push(...formatDiagnostics(r.diagnostics));
  return out.join("\n");
}

export function formatAct(a, { html = false } = {}) {
  const out = [`${a.action} ${a.selector}${a.value !== undefined ? ` ${JSON.stringify(a.value)}` : ""}`];
  out.push(`  ${formatCounts(a.counts)}`);
  for (const w of a.writes) out.push(`  wrote ${nodeLabel(w)}${w.value !== undefined ? ` = ${w.value}` : ""}${w.site ? `  (${w.site})` : ""}`);
  for (const r of a.ran) out.push(`  ran   ${nodeLabel(r)}${r.site && !r.binding ? `  (${r.site})` : ""}`);
  for (const p of a.reconciled) {
    out.push(`  keyed pass: kept ${p.kept}, created ${p.created}, removed ${p.removed}, moved ${p.moved}, rebuilt ${p.rebuilt}`);
  }
  if (html) out.push(`  html: ${a.html}`);
  out.push(...formatDiagnostics(a.diagnostics));
  return out.join("\n");
}

function formatCause(cause, prefix, last, out, root) {
  const verb = { written: "written", recomputed: "recomputed", ran: "ran", created: "ran for the first time (created)" }[cause.action];
  const where = cause.site ? `  (${cause.site})` : "";
  out.push(`${prefix}${root ? "" : last ? "└─ " : "├─ "}${nodeLabel(cause)} ${verb}${where}`);
  const childPrefix = root ? prefix : prefix + (last ? "   " : "│  ");
  cause.causes.forEach((c, i) => formatCause(c, childPrefix, i === cause.causes.length - 1, out, false));
}

export function formatWhy(w) {
  const out = [];
  if (w.cause !== undefined) {
    out.push(`why #${w.id}`);
    if (w.cause) formatCause(w.cause, "  ", true, out, true);
    else out.push("  no run of this node is in the history");
    return out.join("\n");
  }
  out.push(`why ${w.selector}`);
  if (!w.writers.length) out.push(`  ${w.note}`);
  for (const writer of w.writers) {
    if (writer.cause) formatCause(writer.cause, "  ", true, out, true);
    else out.push(`  ${nodeLabel(writer)}: no run in the history`);
  }
  return out.join("\n");
}

export function formatGraph(g) {
  const out = [];
  for (const node of g.nodes) {
    const value = node.value !== undefined ? ` = ${truncate(node.value, 60)}` : "";
    const edges = [
      node.sources.length ? `reads ${node.sources.map((s) => `#${s}`).join(" ")}` : "",
      node.observers.length ? `read by ${node.observers.map((s) => `#${s}`).join(" ")}` : "",
    ]
      .filter(Boolean)
      .join("; ");
    const flags = [node.disposed ? "disposed" : "", node.scope !== undefined ? `scope ${node.scope}` : ""].filter(Boolean).join(", ");
    out.push(`#${node.id} ${nodeLabel(node)}${value}${edges ? `  ${edges}` : ""}${flags ? `  [${flags}]` : ""}${node.site ? `  ${node.site}` : ""}`);
  }
  if (g.scopes.length) {
    out.push("scopes:");
    for (const scope of g.scopes) {
      out.push(
        `  ${scope.id} ${scope.kind}${scope.key !== undefined ? ` "${scope.key}"` : ""}${scope.parent !== undefined ? ` in ${scope.parent}` : ""}${scope.disposed ? " (released)" : ""}`,
      );
    }
  }
  return out.join("\n");
}

export function formatCheck(c) {
  const out = [c.ok ? "check: ok" : `check: failed${c.buildExitCode ? " (build failed)" : ""}`];
  const counts = { error: 0, warning: 0, info: 0 };
  for (const d of c.diagnostics) counts[d.severity]++;
  out.push(`  ${plural(counts.error, "error")}, ${plural(counts.warning, "warning")}, ${counts.info} info`);
  out.push(...formatDiagnostics(c.diagnostics));
  return out.join("\n");
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
        `${q.module}`,
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
