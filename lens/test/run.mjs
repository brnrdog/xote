// xote-lens tests, against the fixture app in ./fixture (built through the
// repo's own ppx and Xote by fixture/setup.sh). Session tests drive the CLI
// with --json, one process per render, as an agent would.

import assert from "node:assert/strict";
import { execFile, spawn } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline";
import { describe, test } from "node:test";
import { fileURLToPath } from "node:url";
import { JSDOM } from "jsdom";
import { digest, loadApi, query } from "../src/api.mjs";
import { check, parseCompilerOutput, rawDiagnostics } from "../src/check.mjs";
import { expand } from "../src/expand.mjs";
import { compareMarkup, reflectProperties } from "../src/markup.mjs";
import { build } from "../src/project.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = join(here, "fixture");
const repo = join(here, "..", "..");
const cli = join(here, "..", "bin", "xote-lens.mjs");

/* The graph comes from rescript-signals' debug hooks. Without them, tests
   that need it are skipped rather than passing vacuously. */
const Devtools = await import(join(repo, "src", "Devtools.res.mjs"));
const graphVisible = Devtools.install(false, undefined).signals;
Devtools.uninstall();
const graphTest = (name, fn) => test(name, { skip: !graphVisible && "rescript-signals has no debug hooks" }, fn);

const lens = (args) =>
  new Promise((resolve) =>
    execFile(process.execPath, [cli, ...args], { cwd: fixture, maxBuffer: 64 * 1024 * 1024 }, (error, stdout, stderr) =>
      resolve({ code: error ? error.code : 0, stdout, stderr }),
    ),
  );

async function lensJson(args) {
  const { code, stdout, stderr } = await lens([...args, "--json"]);
  try {
    return { code, json: JSON.parse(stdout) };
  } catch {
    throw new Error(`not JSON (exit ${code}): ${stdout.slice(0, 300)} ${stderr.slice(0, 300)}`);
  }
}

const built = await build(fixture);
if (built.code !== 0) throw new Error(`the fixture does not build:\n${built.output}`);

describe("cli", () => {
  test("--help prints the usage and every command", async () => {
    const { code, stdout } = await lens(["--help"]);
    assert.equal(code, 0);
    for (const command of ["api", "check", "expand", "render", "why", "graph", "mcp"]) assert.match(stdout, new RegExp(`xote-lens ${command}`));
  });
  test("api, check and expand print JSON with --json", async () => {
    assert.equal((await lensJson(["api", "View.tracked"])).json.items[0].name, "tracked");
    const checked = await lensJson(["check", "--no-build"]);
    assert.deepEqual([checked.code, checked.json.ok], [0, true]);
    assert.equal((await lensJson(["expand", "Counter"])).json.module, "Counter");
    assert.match((await lens(["api", "--digest"])).stdout, /^# Xote public API/);
  });
});

describe("api", () => {
  const api = loadApi(repo);
  test("lists every public module, and only those", () => {
    const modules = api.map((m) => m.module);
    assert.ok(modules.includes("View") && modules.includes("Devtools"));
    assert.ok(!modules.some((m) => m.startsWith("Runtime")), "no Runtime* internal is listed");
  });
  test("shows a declaration with its signature and doc", () => {
    const [item] = query(api, "View.tracked").items;
    assert.equal(item.signature, "let tracked: (unit => node) => node");
    assert.match(item.doc, /Auto-tracked/);
  });
  test("shows a nested module with its members", () => {
    assert.deepEqual(query(api, "Devtools.Budget").items.map((i) => i.name), ["Budget", "Budget.check"]);
  });
  test("says an internal is not public, and lists what is", () => {
    const result = query(api, "View.renderToDom");
    assert.equal(result.kind, "error");
    assert.match(result.message, /tracked/);
  });
  test("digests the whole surface", () => {
    const text = digest(api);
    assert.ok(text.includes("## Devtools") && text.includes("let why: int => option<cause>"));
  });
});

describe("check", () => {
  test("reports a one-shot user-component prop at its source line", async () => {
    const result = await check(fixture, { skipBuild: true });
    assert.deepEqual(result.diagnostics.filter((d) => d.rule === "one-shot-prop").map((d) => d.site), ["src/Counter.res:17:18"]);
    assert.equal(result.ok, true);
  });
  test("turns an effect returning unit into a fix", async () => {
    const broken = join(fixture, "src", "Broken.res");
    writeFileSync(broken, 'let () = Effect.run(() => Console.log("tick"))\n');
    try {
      const result = await check(fixture);
      const finding = result.diagnostics.find((d) => d.rule === "effect-returns-unit");
      assert.ok(finding, `no effect-returns-unit in ${JSON.stringify(result.diagnostics).slice(0, 400)}`);
      assert.match(finding.site, /^src\/Broken\.res:1:/);
      assert.match(finding.fix, /None/);
      assert.equal(result.ok, false);
    } finally {
      rmSync(broken, { force: true });
      rmSync(join(fixture, "src", "Broken.res.mjs"), { force: true });
      await build(fixture);
    }
  });
  test("parses compiler warnings with their location", () => {
    const output = ["  Warning number 26", `  ${fixture}/src/Counter.res:3:7-11`, "", "  1 │ let x = 1", "", "  unused variable x."].join("\n");
    const [d] = parseCompilerOutput(output, fixture);
    assert.deepEqual([d.rule, d.severity, d.site, d.message], ["compiler-warning-26", "warning", "src/Counter.res:3:7", "unused variable x."]);
  });
  test("flags %raw that names a surrounding binding, not one it declares", () => {
    const dir = mkdtempSync(join(tmpdir(), "lens-raw-"));
    try {
      const source = `let limit = 10
let bad: int => bool = %raw(\`function (n) { return n > limit }\`)
let good: int => bool = %raw(\`function (limit) { return limit > 0 }\`)`;
      writeFileSync(join(dir, "Raw.res"), source);
      assert.deepEqual(rawDiagnostics(dir).map((d) => [d.rule, d.site]), [["raw-captures-binding", "Raw.res:2:1"]]);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});

test("expand shows each decision under its source line", () => {
  const { lines } = expand(fixture, "Counter");
  assert.deepEqual(lines[16].sites.map((s) => s.description), ["one-shot prop text of <Label>: read once, never updates"]);
  assert.match(lines[13].sites[0].description, /^reactive child/);
});

describe("render and act", () => {
  graphTest("a click costs one write, two bindings and two DOM writes", async () => {
    const { code, json } = await lensJson(["render", "Counter", "--act", "click #inc"]);
    assert.equal(code, 0);
    assert.match(json.render.html, /<p id="value">0<\/p>/);
    const { counts, writes, html } = json.acts[0];
    assert.deepEqual([counts.writes, counts.bindings, counts.domWrites, counts.scopesCreated], [1, 2, 2, 0]);
    assert.deepEqual(writes.map((w) => [w.name, w.value]), [["count", "1"]]);
    assert.match(writes[0].site, /^src\/Counter\.res\.mjs:/);
    assert.match(html, /<p id="value">1<\/p>/);
  });
  graphTest("why walks from the DOM back to the write", async () => {
    const { json } = await lensJson(["why", "Counter", "#doubled", "--act", "click #inc"]);
    const chain = [];
    for (let cause = json.why[0].writers[0].cause; cause; cause = cause.causes[0]) chain.push(`${cause.name ?? cause.kind}:${cause.action}`);
    assert.deepEqual(chain, ["effect:ran", "computed:recomputed", "doubled:recomputed", "count:written"]);
  });
  graphTest("a static element says why it never updates", async () => {
    const { json } = await lensJson(["why", "Counter", "#label", "--act", "click #inc"]);
    assert.deepEqual(json.why[0].writers, []);
    assert.match(json.why[0].note, /one-shot prop/);
  });
  graphTest("graph lists nodes with values, edges and sites, or one node's neighbourhood", async () => {
    const { json } = await lensJson(["graph", "Counter"]);
    const count = json.graph.nodes.find((n) => n.name === "count");
    assert.deepEqual([count.value, count.observers.length], ["0", 2]);
    assert.match(json.graph.nodes.find((n) => n.name === "doubled").site, /^src\/Counter\.res\.mjs:/);
    const around = await lensJson(["graph", "Counter", "--around", String(count.id), "--depth", "1"]);
    assert.equal(around.json.graph.nodes.length, 3, "count and its two observers");
  });
  test("a keyed reorder moves one row and creates none", async () => {
    const { json } = await lensJson(["render", "Todos", "--act", "click #reverse"]);
    const [pass] = json.acts[0].reconciled;
    assert.deepEqual([pass.kept, pass.created, pass.removed, pass.moved], [2, 0, 0, 1]);
  });
  graphTest("typing and adding creates one row scope", async () => {
    const { json } = await lensJson(["render", "Todos", "--act", "input #draft Ship", "--act", "click #add"]);
    assert.deepEqual(json.acts[0].writes.map((w) => w.name), ["draft"]);
    assert.equal(json.acts[1].counts.scopesCreated, 1);
    assert.match(json.acts[1].html, /<li>Ship<\/li>/);
  });
  graphTest("an effect writing a signal it reads is reported", async () => {
    const { json } = await lensJson(["render", "Todos"]);
    const finding = json.render.diagnostics.find((d) => d.rule === "get-in-effect");
    assert.ok(finding?.message.includes('"syncCount"') && finding.message.includes('"todoCount"'), finding?.message);
  });
  graphTest("an effect left running by a removed row is reported", async () => {
    const { json } = await lensJson(["render", "Leaky", "--act", "click #remove"]);
    assert.equal(json.render.diagnostics.filter((d) => d.rule === "leaked-effect").length, 0, "nothing leaked before");
    assert.match(json.acts[0].diagnostics.find((d) => d.rule === "leaked-effect")?.message ?? "", /"rowTicker"/);
  });
  test("an unknown selector names the elements that exist", async () => {
    const { code, stderr } = await lens(["render", "Counter", "--act", "click #nope"]);
    assert.equal(code, 2);
    assert.match(stderr, /#inc/);
  });
});

describe("server rendering and hydration", () => {
  test("ssr renders on a DOM-less server", async () => {
    assert.match((await lensJson(["render", "Greeting", "--ssr"])).json.render.serverHtml, /class="server"/);
  });
  test("hydrate reports where server and client markup differ", async () => {
    const { code, json } = await lensJson(["render", "Greeting", "--hydrate"]);
    assert.equal(code, 1, "a mismatch is an error");
    assert.deepEqual(json.render.mismatches.map((m) => m.path), ["div#greeting > p [class]", "div#greeting > p > #text"]);
    assert.equal(json.render.diagnostics.filter((d) => d.rule === "hydration-mismatch").length, 2);
  });
  test("hydrate reports each server state key and what the client did with it", async () => {
    const { json } = await lensJson(["render", "Stateful", "--hydrate"]);
    const state = Object.fromEntries(json.render.state.map((e) => [e.key, e]));
    assert.deepEqual([state.visits.server, state.visits.restored, state.visits.decoded], [42, true, true]);
    assert.deepEqual([state.theme.server, state.theme.decoded], ["dark", false]);
    assert.deepEqual([state.cart.inPayload, state.cart.restored], [false, true]);
    assert.deepEqual([state.orphan.inPayload, state.orphan.restored], [true, false]);
    const rules = json.render.diagnostics.map((d) => d.rule).filter((rule) => rule.startsWith("ssr-state"));
    assert.deepEqual(rules, ["ssr-state-decode-failed", "ssr-state-unrestored", "ssr-state-missing"]);
    assert.match(json.render.html, />42</, "the restored value renders");
  });
  graphTest("server state keys name the client signal they restored into", async () => {
    const { json } = await lensJson(["render", "Stateful", "--hydrate"]);
    const nodeOf = (key) => json.render.state.find((e) => e.key === key).node?.name;
    assert.deepEqual([nodeOf("visits"), nodeOf("cart")], ["visits", "cart"]);
  });
  test("the server markup outline names each hydration marker", async () => {
    const outline = (await lensJson(["render", "Stateful", "--ssr"])).json.render.outline.join("\n");
    for (const marker of ["<!--lc-->  component", "<!--$-->  reactive text", "<!--kl-->  keyed list", '<!--k:a-->  keyed row "a"']) {
      assert.ok(outline.includes(marker), `missing ${marker} in\n${outline}`);
    }
  });
  test("form state the client sets as properties is compared as attributes", () => {
    const client = new JSDOM("").window.document.createElement("div");
    client.innerHTML = '<input type="checkbox"><input class="draft">';
    client.firstChild.checked = true;
    client.lastChild.value = "Ship";
    const server = '<input type="checkbox" checked=""><input class="draft" value="Ship">';
    assert.deepEqual(compareMarkup(server, reflectProperties(client).innerHTML), []);
    client.lastChild.value = "Other";
    assert.deepEqual(compareMarkup(server, reflectProperties(client).innerHTML).map((m) => m.path), ["input.draft [value]"]);
  });
  test("markup comparison ignores hydration markers and fragment wrappers", () => {
    const server = "<!--$--><p>a</p><!--kl--><!--k:x--><li>x</li><!--/kl-->";
    assert.deepEqual(compareMarkup(server, '<div style="display: contents"><p>a</p></div><li>x</li>'), []);
  });
});

test("mcp serves every tool over stdio and keeps a session across calls", async () => {
  const child = spawn(process.execPath, [cli, "mcp"], { cwd: fixture, stdio: ["pipe", "pipe", "inherit"] });
  const waiters = new Map();
  createInterface({ input: child.stdout }).on("line", (line) => {
    const message = JSON.parse(line);
    waiters.get(message.id)?.(message);
  });
  let next = 0;
  const send = (message) => child.stdin.write(JSON.stringify({ jsonrpc: "2.0", ...message }) + "\n");
  const call = (method, params) =>
    new Promise((resolve) => {
      waiters.set(++next, resolve);
      send({ id: next, method, params });
    });
  const tool = async (name, args = {}) => (await call("tools/call", { name, arguments: args })).result;
  const content = async (name, args) => {
    const result = await tool(name, args);
    if (result.isError) throw new Error(`${name}: ${result.content[0].text}`);
    return result.structuredContent;
  };
  try {
    const init = await call("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "0" } });
    assert.equal(init.result.serverInfo.name, "xote-lens");
    send({ method: "notifications/initialized" });
    const names = (await call("tools/list", {})).result.tools.map((t) => t.name);
    const tools = ["api", "check", "expand", "render", "act", "why", "graph", "inspect", "html", "diagnostics"].map((t) => `xote_${t}`);
    assert.deepEqual(names, tools);
    assert.equal((await tool("xote_act", { selector: "#inc" })).isError, true, "acting before rendering is an error");
    assert.match((await content("xote_api", { path: "Signal.peek" })).items[0].signature, /^let peek/);
    assert.match((await content("xote_api", { digest: true })).digest, /^# Xote public API/);
    assert.equal((await content("xote_check", { build: false })).ok, true);
    assert.equal((await content("xote_expand", { module: "Counter" })).file, "src/Counter.res");
    const rendered = await content("xote_render", { target: "Counter" });
    assert.match(rendered.html, /id="inc"/);
    const act = await content("xote_act", { selector: "#inc" });
    assert.match(act.html, /<p id="value">1<\/p>/, "act updates the page");
    assert.deepEqual(await content("xote_html", { selector: "#value" }), { result: '<p id="value">1</p>' });
    assert.ok(Array.isArray((await content("xote_diagnostics")).diagnostics));
    const { nodes } = await content("xote_graph");
    if (graphVisible) {
      assert.equal(rendered.summary.nodes.signal, 1);
      assert.equal(act.counts.domWrites, 2);
      assert.equal((await content("xote_why", { selector: "#value" })).writers[0].cause.causes[0].causes[0].name, "count");
      const count = nodes.find((n) => n.name === "count");
      assert.equal((await content("xote_inspect", { id: count.id })).value, "1");
      assert.equal((await content("xote_graph", { around: count.id, depth: 1 })).nodes.length, 3);
    }
  } finally {
    child.stdin.end();
    child.kill();
  }
});
