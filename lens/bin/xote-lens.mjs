#!/usr/bin/env node
// xote-lens: devtools for Xote apps, for people and for agents.

import { writeFileSync } from "node:fs";
import { loadApi, query, digest } from "../src/api.mjs";
import { check } from "../src/check.mjs";
import { expand, formatExpand } from "../src/expand.mjs";
import { formatAct, formatApi, formatCheck, formatGraph, formatRender, formatWhy } from "../src/format.mjs";
import { serveStdio } from "../src/mcp.mjs";
import { findRoot, xoteRoot } from "../src/project.mjs";
import { createSession } from "../src/session.mjs";

const USAGE = `xote-lens — devtools for Xote apps

usage:
  xote-lens api [Module[.name]]            the public API, from Xote's .resi files
  xote-lens api --digest [--out file]      the whole public API as compact Markdown
  xote-lens check [--no-build]             build, then report compiler and Xote-specific findings
  xote-lens expand <Module>                what @xote.component did to a module, by source line
  xote-lens render <target> [options]      render headlessly and report markup, graph and diagnostics
  xote-lens why <target> <selector|id>     render (and --act), then explain the last update
  xote-lens graph <target> [--around id]   render (and --act), then print the reactive graph
  xote-lens mcp                            serve all of the above as MCP tools over stdio

render options:
  --ssr | --hydrate                        server-render only, or server-render then hydrate
  --act "<action> <selector> [value]"      interact after rendering (repeatable): click, input,
                                           change, submit, keydown, keyup, focus, blur
  --why <selector|id>                      explain an element's or node's last update (repeatable)
  --graph                                  print the reactive graph at the end
  --around <id> --depth <n>                limit --graph to one node's neighbourhood
  --settle <ms>                            keep recording after each --act, for async work
  --html                                   print full markup

global options:
  --root <dir>                             the project (default: nearest rescript.json upwards)
  --json                                   machine-readable output
  --no-stacks                              do not capture creation and write sites (faster)

A <target> is a compiled module name, optionally with an export path:
  Counter        Counter.res's make        App.Header   the nested module Header's make
  App.view       the export view (a component or a node)`;

function parseArgs(argv) {
  const options = { _: [], act: [], why: [] };
  const flags = new Set(["json", "ssr", "hydrate", "graph", "html", "digest", "no-build", "no-stacks", "help"]);
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "-h") options.help = true;
    else if (arg.startsWith("--")) {
      const name = arg.slice(2);
      if (flags.has(name)) options[name] = true;
      else {
        const value = argv[++i];
        if (value === undefined) throw new Error(`--${name} needs a value`);
        if (name === "act" || name === "why") options[name].push(value);
        else options[name] = value;
      }
    } else options._.push(arg);
  }
  return options;
}

function parseAct(spec) {
  const [action, selector, ...rest] = spec.trim().split(/\s+/);
  if (!selector) throw new Error(`--act "${spec}": expected "<action> <selector> [value]"`);
  return { action, selector, ...(rest.length ? { value: rest.join(" ") } : {}) };
}

/* A bare number is a node id; anything else is a selector. */
const whyRequest = (spec) => (/^\d+$/.test(spec) ? { id: Number(spec) } : { selector: spec });

const print = (options, value, format) => console.log(options.json ? JSON.stringify(value, null, 2) : format(value));

async function runSession(options, target, extra = {}) {
  const root = options.root ? findRoot(options.root) : findRoot();
  const session = await createSession({ root, captureStacks: !options["no-stacks"] });
  const report = { render: null, acts: [], why: [], graph: null };
  let failed = false;
  try {
    const mode = options.hydrate ? "hydrate" : options.ssr ? "ssr" : "client";
    report.render = await session.render({ target, mode });
    if (!options.json) print(options, report.render, (r) => formatRender(r, { html: options.html }));
    for (const spec of options.act) {
      const act = await session.act({ ...parseAct(spec), settle: Number(options.settle ?? 0) });
      report.acts.push(act);
      if (!options.json) print(options, act, (a) => formatAct(a, { html: options.html }));
    }
    for (const spec of [...options.why, ...(extra.why ?? [])]) {
      const why = session.why(whyRequest(spec));
      report.why.push(why);
      if (!options.json) print(options, why, formatWhy);
    }
    if (options.graph || extra.graph) {
      report.graph = session.graph({ around: options.around, depth: Number(options.depth ?? 2) });
      if (!options.json) print(options, report.graph, formatGraph);
    }
    failed = [report.render, ...report.acts].some((r) => r.diagnostics.some((d) => d.severity === "error"));
  } finally {
    session.close();
  }
  if (options.json) console.log(JSON.stringify(report, null, 2));
  return failed ? 1 : 0;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const [command, ...args] = options._;
  if (options.help || !command) {
    console.log(USAGE);
    return command ? 0 : options.help ? 0 : 2;
  }
  const root = () => (options.root ? findRoot(options.root) : findRoot());
  switch (command) {
    case "api": {
      const api = loadApi(xoteRoot(root()));
      if (options.digest) {
        const text = digest(api);
        if (options.out) writeFileSync(options.out, text);
        else console.log(text);
        return 0;
      }
      const result = query(api, args[0]);
      print(options, result, formatApi);
      return result.kind === "error" ? 1 : 0;
    }
    case "check": {
      const result = await check(root(), { skipBuild: options["no-build"] });
      print(options, result, formatCheck);
      return result.ok ? 0 : 1;
    }
    case "expand": {
      if (!args[0]) throw new Error("expand needs a module name");
      print(options, expand(root(), args[0]), (r) => formatExpand(r));
      return 0;
    }
    case "render":
      if (!args[0]) throw new Error("render needs a target");
      return runSession(options, args[0]);
    case "why":
      if (args.length < 2) throw new Error("why needs a target and a selector or node id");
      return runSession(options, args[0], { why: [args[1]] });
    case "graph":
      if (!args[0]) throw new Error("graph needs a target");
      return runSession(options, args[0], { graph: true });
    case "mcp":
      serveStdio({ root: root() });
      return null;
    default:
      throw new Error(`unknown command ${command}\n\n${USAGE}`);
  }
}

main().then(
  (code) => {
    if (code !== null) process.exitCode = code;
  },
  (error) => {
    console.error(`xote-lens: ${error?.message ?? error}`);
    process.exitCode = 2;
  },
);
