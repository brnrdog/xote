// The MCP server: the CLI's commands as tools, over stdio (newline-delimited
// JSON-RPC 2.0). Every tool returns the same JSON the CLI prints with --json.
//
// Rendering happens in a forked worker (see worker.mjs). `xote_render` starts
// a new one each time, so a render always sees freshly built modules; the
// other session tools act on the most recent render.

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

const target = {
  type: "string",
  description:
    "What to render: a compiled module name, optionally followed by an export path. `Counter` renders Counter.res's `make`; `App.Header` renders the nested module Header's `make`; `App.view` renders the export `view` (a component or a node).",
};

export const TOOLS = [
  {
    name: "xote_api",
    description:
      "Look up Xote's public API, read from its .resi interface files: everything listed is public and nothing else is. No path lists the modules; `View` lists a module; `View.tracked` or `View.Show` shows declarations with their docs. `digest: true` returns the whole surface as compact Markdown.",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" }, digest: { type: "boolean" } },
    },
  },
  {
    name: "xote_check",
    description:
      "Build the project and report static findings: compiler errors and warnings (with fixes for known Xote mistakes), user-component props that are one-shot signal reads, View.probe sites, and %raw code that captures ReScript bindings. Run after every edit.",
    inputSchema: { type: "object", properties: { build: { type: "boolean", description: "Run the build first (default true)." } } },
  },
  {
    name: "xote_expand",
    description:
      "Show what @xote.component did to a module: each thunked attribute, reactive or static child, tracked branch, probe and one-shot prop, at its source line. Needs the ppx's -sitemap flag.",
    inputSchema: { type: "object", properties: { module: { type: "string" } }, required: ["module"] },
  },
  {
    name: "xote_render",
    description:
      "Render a component headlessly (jsdom) under devtools, in a fresh session, and report its markup, reactive graph summary and runtime diagnostics (leaks, hidden reads, effects that write what they read, console output). mode: client (default), ssr (server markup only, rendered without a DOM), or hydrate (server render, then hydrate, and compare the server's markup with the client's). Build first (xote_check).",
    inputSchema: {
      type: "object",
      properties: { target, mode: { type: "string", enum: ["client", "ssr", "hydrate"] } },
      required: ["target"],
    },
  },
  {
    name: "xote_act",
    description:
      "Dispatch an interaction against the last render and report everything it caused: signal writes (with the code location that wrote), computeds and effects that ran, DOM writes, scopes created and released, keyed-list passes, and new diagnostics. Use `counts` as a reactive budget: an update that should touch one text node should show 1 DOM write.",
    inputSchema: {
      type: "object",
      properties: {
        selector: { type: "string", description: "CSS selector of the element to act on." },
        action: { type: "string", enum: ["click", "input", "change", "submit", "keydown", "keyup", "focus", "blur"], description: "Default click." },
        value: { type: "string", description: "For input/change: the new value. For keydown/keyup: the key (default Enter)." },
        settle: { type: "number", description: "Milliseconds to keep recording after the event, for async work. Default 0." },
      },
      required: ["selector"],
    },
  },
  {
    name: "xote_why",
    description:
      "Explain why a DOM element (by selector) or a reactive node (by id) last updated: a tree of causes from the binding that wrote the DOM, through the computeds that recomputed, down to the signal writes and where they happened.",
    inputSchema: { type: "object", properties: { selector: { type: "string" }, id: { type: "number" } } },
  },
  {
    name: "xote_graph",
    description:
      "The reactive graph of the last render: every signal, computed and effect with its value, sources, observers, scope and creation site, plus the scope tree. `around` and `depth` limit it to one node's neighbourhood.",
    inputSchema: { type: "object", properties: { around: { type: "number" }, depth: { type: "number" } } },
  },
  {
    name: "xote_inspect",
    description: "One reactive node of the last render, by id.",
    inputSchema: { type: "object", properties: { id: { type: "number" } }, required: ["id"] },
  },
  {
    name: "xote_html",
    description: "The current markup of the last render, or of one element.",
    inputSchema: { type: "object", properties: { selector: { type: "string" } } },
  },
  {
    name: "xote_diagnostics",
    description: "Runtime diagnostics of the last render, re-evaluated now (after any interactions).",
    inputSchema: { type: "object", properties: {} },
  },
];

export const INSTRUCTIONS = `xote-lens inspects a Xote (ReScript UI library) project. A good loop:
1. xote_api to check an API before using it (only what it lists is public).
2. Edit, then xote_check: it builds and reports compiler errors and Xote-specific findings.
3. xote_render the component, xote_act to interact; read counts (reactive budget), diagnostics, and xote_why for anything that updated (or did not) unexpectedly.
Sites are file:line:col of the compiled .res.mjs next to each .res source.`;

class Worker {
  constructor(root) {
    this.child = fork(fileURLToPath(new URL("./worker.mjs", import.meta.url)), [], { stdio: ["ignore", "ignore", "pipe", "ipc"] });
    this.pending = new Map();
    this.next = 0;
    this.stderr = "";
    this.child.stderr.on("data", (chunk) => (this.stderr = (this.stderr + chunk).slice(-4000)));
    this.child.on("message", ({ id, result, error }) => {
      const entry = this.pending.get(id);
      if (!entry) return;
      this.pending.delete(id);
      if (error) entry.reject(new Error(error));
      else entry.resolve(result);
    });
    this.child.on("exit", (code) => {
      for (const entry of this.pending.values()) entry.reject(new Error(`session process exited (${code}): ${this.stderr.trim()}`));
      this.pending.clear();
      this.exited = true;
    });
    this.ready = this.call("init", { root });
  }
  call(method, params) {
    if (this.exited) return Promise.reject(new Error("the session process has exited; render again"));
    return new Promise((resolve, reject) => {
      const id = ++this.next;
      this.pending.set(id, { resolve, reject });
      this.child.send({ id, method, params });
    });
  }
  close() {
    this.child.kill();
  }
}

export function createServer({ root, write = (line) => process.stdout.write(line + "\n") }) {
  let worker = null;
  let api = null;

  const session = async () => {
    if (!worker) throw new Error("nothing rendered yet: call xote_render first");
    await worker.ready;
    return worker;
  };

  const tools = {
    async xote_api({ path, digest: wantDigest }) {
      api ??= loadApi(xoteRoot(root));
      return wantDigest ? { digest: digest(api) } : query(api, path);
    },
    xote_check: ({ build = true }) => check(root, { skipBuild: !build }),
    xote_expand: ({ module }) => expand(root, module),
    async xote_render({ target: t, mode = "client" }) {
      worker?.close();
      worker = new Worker(root);
      await worker.ready;
      return worker.call("render", { target: t, mode });
    },
    xote_act: async (params) => (await session()).call("act", params),
    xote_why: async (params) => (await session()).call("why", params),
    xote_graph: async (params) => (await session()).call("graph", params),
    xote_inspect: async (params) => (await session()).call("inspect", params),
    xote_html: async (params) => (await session()).call("html", params),
    xote_diagnostics: async () => ({ diagnostics: await (await session()).call("diagnostics", {}) }),
  };

  async function handle(message) {
    const { id, method, params } = message;
    const reply = (result) => id !== undefined && write(JSON.stringify({ jsonrpc: "2.0", id, result }));
    const fail = (code, text) => id !== undefined && write(JSON.stringify({ jsonrpc: "2.0", id, error: { code, message: text } }));
    switch (method) {
      case "initialize": {
        const requested = params?.protocolVersion;
        return reply({
          protocolVersion: SUPPORTED.includes(requested) ? requested : SUPPORTED[0],
          capabilities: { tools: {} },
          serverInfo: { name: "xote-lens", version: VERSION },
          instructions: INSTRUCTIONS,
        });
      }
      case "notifications/initialized":
      case "notifications/cancelled":
        return;
      case "ping":
        return reply({});
      case "tools/list":
        return reply({ tools: TOOLS });
      case "tools/call": {
        const tool = tools[params?.name];
        if (!tool) return fail(-32602, `unknown tool ${params?.name}`);
        try {
          const result = await tool(params.arguments ?? {});
          const structured = result && typeof result === "object" && !Array.isArray(result) ? result : { result };
          return reply({ content: [{ type: "text", text: JSON.stringify(result, null, 2) }], structuredContent: structured });
        } catch (error) {
          return reply({ content: [{ type: "text", text: error?.message ?? String(error) }], isError: true });
        }
      }
      default:
        if (id !== undefined) return fail(-32601, `method not found: ${method}`);
    }
  }

  return {
    handle,
    close: () => worker?.close(),
  };
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
      process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "parse error" } }) + "\n");
      return;
    }
    server.handle(message);
  });
  rl.on("close", () => {
    server.close();
    process.exit(0);
  });
}
