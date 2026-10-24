// The MCP server: the CLI's commands as tools over stdio (newline-delimited
// JSON-RPC 2.0). Every tool returns the JSON the CLI prints with --json.
// Rendering happens in a forked worker (worker.mjs): `xote_render` starts a
// new one each time, so it sees freshly built modules; the other session tools
// act on the latest render.

import { fork } from "node:child_process";
import { readFileSync } from "node:fs";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import { loadApi, query, digest } from "./api.mjs";
import { check } from "./check.mjs";
import { expand } from "./expand.mjs";
import { xoteRoot } from "./project.mjs";

const VERSION = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf8")).version;
const SUPPORTED = ["2025-06-18", "2025-03-26", "2024-11-05"];

const schema = (properties = {}, required) => ({ type: "object", properties, ...(required ? { required } : {}) });
/* A tool that forwards its arguments to the latest render's session. */
const inSession = (method) => async (params, ctx) => (await ctx.session()).call(method, params);

/* Every tool: its description, input schema and implementation. The CLI runs
   the session-less ones (api, check, expand) through the same functions. */
export const tools = {
  xote_api: {
    description: "Look up Xote's public API, read from its .resi interface files: everything listed is public and nothing else is. No path lists the modules; `View` lists a module; `View.tracked` or `View.Show` shows declarations with their docs. `digest: true` returns the whole surface as compact Markdown.",
    inputSchema: schema({ path: { type: "string" }, digest: { type: "boolean" } }),
    run({ path, digest: wantDigest }, { root }) {
      const api = loadApi(xoteRoot(root));
      return wantDigest ? { digest: digest(api) } : query(api, path);
    },
  },
  xote_check: {
    description: "Build the project and report static findings: compiler errors and warnings (with fixes for known Xote mistakes), user-component props that are one-shot signal reads, View.probe sites, and %raw code that captures ReScript bindings. Run after every edit.",
    inputSchema: schema({ build: { type: "boolean", description: "Run the build first (default true)." } }),
    run: ({ build = true }, { root }) => check(root, { skipBuild: !build }),
  },
  xote_expand: {
    description: "Show what @xote.component did to a module: each thunked attribute, reactive or static child, tracked branch, probe and one-shot prop, at its source line. Needs the ppx's -sitemap flag.",
    inputSchema: schema({ module: { type: "string" } }, ["module"]),
    run: ({ module }, { root }) => expand(root, module),
  },
  xote_render: {
    description: "Render a component headlessly (jsdom) under devtools, in a fresh session, and report its markup, reactive graph summary and runtime diagnostics (leaks, hidden reads, effects that write what they read, console output). mode: client (default), ssr (server markup only, rendered without a DOM), or hydrate (server render, then hydrate, and compare the server's markup with the client's). Build first (xote_check).",
    inputSchema: schema(
      {
        target: {
          type: "string",
          description: "What to render: a compiled module name, optionally followed by an export path. `Counter` renders Counter.res's `make`; `App.Header` renders the nested module Header's `make`; `App.view` renders the export `view` (a component or a node).",
        },
        mode: { type: "string", enum: ["client", "ssr", "hydrate"] },
      },
      ["target"],
    ),
    run: async ({ target, mode = "client" }, ctx) => (await ctx.session(true)).call("render", { target, mode }),
  },
  xote_act: {
    description: "Dispatch an interaction against the last render and report everything it caused: signal writes (with the code location that wrote), computeds and effects that ran, DOM writes, scopes created and released, keyed-list passes, and new diagnostics. Use `counts` as a reactive budget: an update that should touch one text node should show 1 DOM write.",
    inputSchema: schema(
      {
        selector: { type: "string", description: "CSS selector of the element to act on." },
        action: { type: "string", enum: ["click", "input", "change", "submit", "keydown", "keyup", "focus", "blur"], description: "Default click." },
        value: { type: "string", description: "For input/change: the new value. For keydown/keyup: the key (default Enter)." },
        settle: { type: "number", description: "Milliseconds to keep recording after the event, for async work. Default 0." },
      },
      ["selector"],
    ),
    run: inSession("act"),
  },
  xote_why: {
    description: "Explain why a DOM element (by selector) or a reactive node (by id) last updated: a tree of causes from the binding that wrote the DOM, through the computeds that recomputed, down to the signal writes and where they happened.",
    inputSchema: schema({ selector: { type: "string" }, id: { type: "number" } }),
    run: inSession("why"),
  },
  xote_graph: {
    description: "The reactive graph of the last render: every signal, computed and effect with its value, sources, observers, scope and creation site, plus the scope tree. `around` and `depth` limit it to one node's neighbourhood.",
    inputSchema: schema({ around: { type: "number" }, depth: { type: "number" } }),
    run: inSession("graph"),
  },
  xote_inspect: {
    description: "One reactive node of the last render, by id.",
    inputSchema: schema({ id: { type: "number" } }, ["id"]),
    run: inSession("inspect"),
  },
  xote_html: {
    description: "The current markup of the last render, or of one element.",
    inputSchema: schema({ selector: { type: "string" } }),
    run: inSession("html"),
  },
  xote_diagnostics: {
    description: "Runtime diagnostics of the last render, re-evaluated now (after any interactions).",
    inputSchema: schema(),
    run: async (params, ctx) => ({ diagnostics: await inSession("diagnostics")({}, ctx) }),
  },
};

export const TOOLS = Object.entries(tools).map(([name, { description, inputSchema }]) => ({ name, description, inputSchema }));

export const INSTRUCTIONS = `xote-lens inspects a Xote (ReScript UI library) project. A good loop:
1. xote_api to check an API before using it (only what it lists is public).
2. Edit, then xote_check: it builds and reports compiler errors and Xote-specific findings.
3. xote_render the component, xote_act to interact; read counts (reactive budget), diagnostics, and xote_why for anything that updated (or did not) unexpectedly.
Sites are file:line:col of the compiled .res.mjs next to each .res source.`;

/* A forked session process, called like a function over IPC. */
function startWorker(root) {
  const child = fork(fileURLToPath(new URL("./worker.mjs", import.meta.url)), [], { stdio: ["ignore", "ignore", "pipe", "ipc"] });
  const pending = new Map();
  let next = 0;
  let stderr = "";
  let exited = false;
  child.stderr.on("data", (chunk) => (stderr = (stderr + chunk).slice(-4000)));
  child.on("message", ({ id, result, error }) => {
    const entry = pending.get(id);
    pending.delete(id);
    if (error) entry?.reject(new Error(error));
    else entry?.resolve(result);
  });
  child.on("exit", (code) => {
    exited = true;
    for (const entry of pending.values()) entry.reject(new Error(`session process exited (${code}): ${stderr.trim()}`));
    pending.clear();
  });
  const call = (method, params) => {
    if (exited) return Promise.reject(new Error("the session process has exited; render again"));
    return new Promise((resolve, reject) => {
      const id = ++next;
      pending.set(id, { resolve, reject });
      child.send({ id, method, params });
    });
  };
  return { call, ready: call("init", { root }), close: () => child.kill() };
}

export function createServer({ root, write = (line) => process.stdout.write(line + "\n") }) {
  let worker = null;
  const ctx = {
    root,
    /* The latest render's session process, or (`fresh`) a new one. */
    async session(fresh = false) {
      if (fresh) {
        worker?.close();
        worker = startWorker(root);
      }
      if (!worker) throw new Error("nothing rendered yet: call xote_render first");
      await worker.ready;
      return worker;
    },
  };

  async function handle({ id, method, params }) {
    const send = (body) => id !== undefined && write(JSON.stringify({ jsonrpc: "2.0", id, ...body }));
    const reply = (result) => send({ result });
    switch (method) {
      case "initialize":
        return reply({
          protocolVersion: SUPPORTED.includes(params?.protocolVersion) ? params.protocolVersion : SUPPORTED[0],
          capabilities: { tools: {} },
          serverInfo: { name: "xote-lens", version: VERSION },
          instructions: INSTRUCTIONS,
        });
      case "notifications/initialized": case "notifications/cancelled":
        return;
      case "ping":
        return reply({});
      case "tools/list":
        return reply({ tools: TOOLS });
      case "tools/call": {
        const tool = Object.hasOwn(tools, params?.name ?? "") && tools[params.name];
        if (!tool) return send({ error: { code: -32602, message: `unknown tool ${params?.name}` } });
        try {
          const result = await tool.run(params.arguments ?? {}, ctx);
          const structured = result && typeof result === "object" && !Array.isArray(result) ? result : { result };
          return reply({ content: [{ type: "text", text: JSON.stringify(result, null, 2) }], structuredContent: structured });
        } catch (error) {
          return reply({ content: [{ type: "text", text: error?.message ?? String(error) }], isError: true });
        }
      }
      default:
        return send({ error: { code: -32601, message: `method not found: ${method}` } });
    }
  }

  return { handle, close: () => worker?.close() };
}

export function serveStdio({ root }) {
  const server = createServer({ root });
  const rl = createInterface({ input: process.stdin });
  rl.on("line", (line) => {
    if (!line.trim()) return;
    let message;
    try {
      message = JSON.parse(line);
    } catch {
      return process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "parse error" } }) + "\n");
    }
    server.handle(message);
  });
  rl.on("close", () => {
    server.close();
    process.exit(0);
  });
}
