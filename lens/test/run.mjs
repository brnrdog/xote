// xote-lens tests, against the fixture app in ./fixture (built through the
// repo's own ppx and Xote by fixture/setup.sh). Session tests drive the CLI
// with --json, one process per render, as an agent would.

import { execFile, spawn } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { digest, loadApi, query } from "../src/api.mjs";
import { check, parseCompilerOutput, rawDiagnostics } from "../src/check.mjs";
import { expand } from "../src/expand.mjs";
import { compareMarkup } from "../src/markup.mjs";
import { build } from "../src/project.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = join(here, "fixture");
const repo = join(here, "..", "..");
const cli = join(here, "..", "bin", "xote-lens.mjs");

let passed = 0;
let failed = 0;
let skipped = 0;
const failures = [];

/* The reactive graph comes from rescript-signals' debug hooks. Against a
   release without them, tests that need the graph report as skipped rather
   than passing vacuously. */
const graphVisible = await (async () => {
  const Devtools = await import(join(dirname(fileURLToPath(import.meta.url)), "..", "..", "src", "Devtools.res.mjs"));
  const visible = Devtools.install(false, undefined).signals;
  Devtools.uninstall();
  return visible;
})();

async function test(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed++;
    failures.push(name);
    console.log(`  ✗ ${name}\n      ${String(error?.stack ?? error).split("\n").slice(0, 4).join("\n      ")}`);
  }
}

async function graphTest(name, fn) {
  if (graphVisible) return test(name, fn);
  skipped++;
  console.log(`  ○ ${name} (skipped: rescript-signals has no debug hooks)`);
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function equal(actual, expected, label = "value") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${label}: expected ${e}, got ${a}`);
}

function lens(args, { cwd = fixture } = {}) {
  return new Promise((resolve) => {
    execFile(process.execPath, [cli, ...args], { cwd, maxBuffer: 64 * 1024 * 1024 }, (error, stdout, stderr) => {
      resolve({ code: error ? error.code : 0, stdout, stderr });
    });
  });
}

async function lensJson(args) {
  const { code, stdout, stderr } = await lens([...args, "--json"]);
  try {
    return { code, json: JSON.parse(stdout) };
  } catch {
    throw new Error(`not JSON (exit ${code}): ${stdout.slice(0, 300)} ${stderr.slice(0, 300)}`);
  }
}

const built = await build(fixture);
if (built.code !== 0) {
  console.log(built.output);
  throw new Error("the fixture does not build");
}

console.log("api");
const api = loadApi(repo);
await test("lists every public module, and only those", () => {
  const modules = api.map((m) => m.module);
  assert(modules.includes("View") && modules.includes("Devtools"), "View and Devtools are public");
  assert(!modules.some((m) => m.startsWith("Runtime")), "no Runtime* internal is listed");
});
await test("shows a declaration with its signature and doc", () => {
  const result = query(api, "View.tracked");
  equal(result.items[0].signature, "let tracked: (unit => node) => node", "signature");
  assert(result.items[0].doc.includes("Auto-tracked"), "the doc comment comes along");
});
await test("shows a nested module with its members", () => {
  equal(query(api, "Devtools.Budget").items.map((i) => i.name), ["Budget", "Budget.check"], "members");
});
await test("says an internal is not public, and lists what is", () => {
  const result = query(api, "View.renderToDom");
  equal(result.kind, "error", "kind");
  assert(result.message.includes("tracked"), "lists View's exports");
});
await test("digests the whole surface", () => {
  const text = digest(api);
  assert(text.includes("## Devtools") && text.includes("let why: int => option<cause>"), "Devtools is in the digest");
});

console.log("check");
await test("reports a one-shot user-component prop at its source line", async () => {
  const result = await check(fixture, { skipBuild: true });
  const oneShot = result.diagnostics.filter((d) => d.rule === "one-shot-prop");
  equal(oneShot.map((d) => d.site), ["src/Counter.res:17:18"], "sites");
  equal(result.ok, true, "ok");
});
await test("turns an effect returning unit into a fix", async () => {
  const broken = join(fixture, "src", "Broken.res");
  writeFileSync(broken, 'let () = Effect.run(() => Console.log("tick"))\n');
  try {
    const result = await check(fixture);
    const finding = result.diagnostics.find((d) => d.rule === "effect-returns-unit");
    assert(finding, `no effect-returns-unit in ${JSON.stringify(result.diagnostics).slice(0, 400)}`);
    assert(finding.site.startsWith("src/Broken.res:1:"), `site ${finding.site}`);
    assert(finding.fix.includes("None"), "the fix says how");
    equal(result.ok, false, "ok");
  } finally {
    rmSync(broken, { force: true });
    rmSync(join(fixture, "src", "Broken.res.mjs"), { force: true });
    await build(fixture);
  }
});
await test("parses compiler warnings with their location", () => {
  const output = [
    "  Warning number 26",
    `  ${fixture}/src/Counter.res:3:7-11`,
    "",
    "  1 │ let x = 1",
    "",
    "  unused variable x.",
  ].join("\n");
  const [d] = parseCompilerOutput(output, fixture);
  equal([d.rule, d.severity, d.site, d.message], ["compiler-warning-26", "warning", "src/Counter.res:3:7", "unused variable x."], "diagnostic");
});
await test("flags %raw that names a surrounding binding, not one it declares", () => {
  const dir = mkdtempSync(join(tmpdir(), "lens-raw-"));
  try {
    writeFileSync(
      join(dir, "Raw.res"),
      [
        "let limit = 10",
        "let bad: int => bool = %raw(`function (n) { return n > limit }`)",
        "let good: int => bool = %raw(`function (limit) { return limit > 0 }`)",
      ].join("\n"),
    );
    const found = rawDiagnostics(dir);
    equal(found.map((d) => [d.rule, d.site]), [["raw-captures-binding", "Raw.res:2:1"]], "findings");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

console.log("expand");
await test("shows each decision under its source line", () => {
  const result = expand(fixture, "Counter");
  const line17 = result.lines.find((l) => l.line === 17);
  equal(line17.sites.map((s) => s.description), ["one-shot prop text of <Label>: read once, never updates"], "line 17");
  const line14 = result.lines.find((l) => l.line === 14);
  assert(line14.sites[0].description.startsWith("reactive child"), "line 14 is a reactive child");
});

console.log("render and act");
await graphTest("a click costs one write, two bindings and two DOM writes", async () => {
  const { code, json } = await lensJson(["render", "Counter", "--act", "click #inc"]);
  equal(code, 0, "exit code");
  equal(json.render.html.includes('<p id="value">0</p>'), true, "initial markup");
  const act = json.acts[0];
  equal([act.counts.writes, act.counts.bindings, act.counts.domWrites, act.counts.scopesCreated], [1, 2, 2, 0], "counts");
  equal(act.writes.map((w) => [w.name, w.value]), [["count", "1"]], "writes");
  assert(act.writes[0].site.startsWith("src/Counter.res.mjs:"), `write site ${act.writes[0].site}`);
  assert(act.html.includes('<p id="value">1</p>'), "updated markup");
});
await graphTest("why walks from the DOM back to the write", async () => {
  const { json } = await lensJson(["why", "Counter", "#doubled", "--act", "click #inc"]);
  const chain = [];
  let cause = json.why[0].writers[0].cause;
  while (cause) {
    chain.push(`${cause.name ?? cause.kind}:${cause.action}`);
    cause = cause.causes[0];
  }
  equal(chain, ["effect:ran", "computed:recomputed", "doubled:recomputed", "count:written"], "chain");
});
await graphTest("a static element says why it never updates", async () => {
  const { json } = await lensJson(["why", "Counter", "#label", "--act", "click #inc"]);
  equal(json.why[0].writers, [], "writers");
  assert(json.why[0].note.includes("one-shot prop"), "points at one-shot props");
});
await graphTest("graph lists nodes with values, edges and sites", async () => {
  const { json } = await lensJson(["graph", "Counter"]);
  const count = json.graph.nodes.find((n) => n.name === "count");
  equal(count.value, "0", "value");
  assert(count.observers.length === 2, `count has two observers, got ${count.observers}`);
  assert(json.graph.nodes.find((n) => n.name === "doubled").site.startsWith("src/Counter.res.mjs:"), "site");
});
await test("a keyed reorder moves one row and creates none", async () => {
  const { json } = await lensJson(["render", "Todos", "--act", "click #reverse"]);
  const [pass] = json.acts[0].reconciled;
  equal([pass.kept, pass.created, pass.removed, pass.moved], [2, 0, 0, 1], "pass");
});
await graphTest("typing and adding creates one row scope", async () => {
  const { json } = await lensJson(["render", "Todos", "--act", "input #draft Ship", "--act", "click #add"]);
  equal(json.acts[0].writes.map((w) => w.name), ["draft"], "input writes the draft");
  equal(json.acts[1].counts.scopesCreated, 1, "one row scope");
  assert(json.acts[1].html.includes("<li>Ship</li>"), "the row renders");
});
await graphTest("an effect writing a signal it reads is reported", async () => {
  const { json } = await lensJson(["render", "Todos"]);
  const finding = json.render.diagnostics.find((d) => d.rule === "get-in-effect");
  assert(finding, "get-in-effect reported");
  assert(finding.message.includes('"syncCount"') && finding.message.includes('"todoCount"'), finding.message);
});
await graphTest("an effect left running by a removed row is reported", async () => {
  const { json } = await lensJson(["render", "Leaky", "--act", "click #remove"]);
  equal(json.render.diagnostics.filter((d) => d.rule === "leaked-effect").length, 0, "nothing leaked before");
  const leak = json.acts[0].diagnostics.find((d) => d.rule === "leaked-effect");
  assert(leak && leak.message.includes('"rowTicker"'), "leaked-effect after removal");
});
await test("an unknown selector names the elements that exist", async () => {
  const { code, stderr } = await lens(["render", "Counter", "--act", "click #nope"]);
  equal(code, 2, "exit code");
  assert(stderr.includes("#inc"), stderr);
});

console.log("server rendering and hydration");
await test("ssr renders on a DOM-less server", async () => {
  const { json } = await lensJson(["render", "Greeting", "--ssr"]);
  assert(json.render.serverHtml.includes('class="server"'), json.render.serverHtml);
});
await test("hydrate reports where server and client markup differ", async () => {
  const { code, json } = await lensJson(["render", "Greeting", "--hydrate"]);
  equal(code, 1, "exit code (a mismatch is an error)");
  equal(json.render.mismatches.map((m) => m.path), ["div#greeting > p [class]", "div#greeting > p > #text"], "paths");
  equal(json.render.diagnostics.filter((d) => d.rule === "hydration-mismatch").length, 2, "diagnostics");
});
await test("markup comparison ignores hydration markers and fragment wrappers", () => {
  equal(compareMarkup('<!--$--><p>a</p><!--kl--><!--k:x--><li>x</li><!--/kl-->', '<div style="display: contents"><p>a</p></div><li>x</li>'), [], "no differences");
});

console.log("mcp");
await test("serves the tools over stdio and keeps a session across calls", async () => {
  const child = spawn(process.execPath, [cli, "mcp"], { cwd: fixture, stdio: ["pipe", "pipe", "inherit"] });
  const responses = new Map();
  const waiters = new Map();
  let buffer = "";
  child.stdout.on("data", (chunk) => {
    buffer += chunk;
    let index;
    while ((index = buffer.indexOf("\n")) >= 0) {
      const message = JSON.parse(buffer.slice(0, index));
      buffer = buffer.slice(index + 1);
      responses.set(message.id, message);
      waiters.get(message.id)?.(message);
    }
  });
  let next = 0;
  const call = (method, params) =>
    new Promise((resolve) => {
      const id = ++next;
      waiters.set(id, resolve);
      child.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
    });
  const tool = async (name, args) => (await call("tools/call", { name, arguments: args })).result;
  try {
    const init = await call("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "0" } });
    equal(init.result.serverInfo.name, "xote-lens", "server name");
    child.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");
    const list = await call("tools/list", {});
    assert(list.result.tools.some((t) => t.name === "xote_act"), "xote_act is listed");
    const early = await tool("xote_act", { selector: "#inc" });
    equal(early.isError, true, "acting before rendering is an error");
    const rendered = await tool("xote_render", { target: "Counter" });
    assert(rendered.structuredContent.html.includes('id="inc"'), "render markup");
    const act = await tool("xote_act", { selector: "#inc" });
    assert(act.structuredContent.html.includes('<p id="value">1</p>'), "act updates the page");
    if (graphVisible) {
      equal(rendered.structuredContent.summary.nodes.signal, 1, "render summary");
      equal(act.structuredContent.counts.domWrites, 2, "act counts");
      const why = await tool("xote_why", { selector: "#value" });
      equal(why.structuredContent.writers[0].cause.causes[0].causes[0].name, "count", "why reaches the write");
    }
    const apiResult = await tool("xote_api", { path: "Signal.peek" });
    assert(apiResult.structuredContent.items[0].signature.startsWith("let peek"), "api");
  } finally {
    child.stdin.end();
    child.kill();
  }
});

console.log(`\n${passed} passed, ${failed} failed${skipped ? `, ${skipped} skipped` : ""}`);
if (failed) {
  console.log(failures.map((f) => `  ✗ ${f}`).join("\n"));
  process.exit(1);
}
