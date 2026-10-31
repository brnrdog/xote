#!/usr/bin/env node
// xote-lens: devtools for Xote apps, for people and for agents.

import { writeFileSync } from "node:fs";
import { formatAct, formatApi, formatCheck, formatExpand, formatGraph, formatRender, formatWhy } from "../src/format.mjs";
import { serveStdio, tools } from "../src/mcp.mjs";
import { findRoot } from "../src/project.mjs";
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
  --markers                                with --ssr/--hydrate: outline the server markup,
                                           naming each hydration marker

global options:
  --root <dir>                             the project (default: nearest rescript.json upwards)
  --json                                   machine-readable output
  --no-stacks                              do not capture creation and write sites (faster)

A <target> is a compiled module name, optionally with an export path:
  Counter        Counter.res's make        App.Header   the nested module Header's make
  App.view       the export view (a component or a node)`;

const FLAGS = new Set(["json", "ssr", "hydrate", "graph", "html", "markers", "digest", "no-build", "no-stacks", "help"]);

function parseArgs(argv) {
  const options = { _: [], act: [], why: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const name = arg.slice(2);
    if (arg === "-h") options.help = true;
    else if (!arg.startsWith("--")) options._.push(arg);
    else if (FLAGS.has(name)) options[name] = true;
    else if (argv[i + 1] === undefined) throw new Error(`--${name} needs a value`);
    else if (name === "act" || name === "why") options[name].push(argv[++i]);
    else options[name] = argv[++i];
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

function need(value, message) {
  if (!value) throw new Error(message);
  return value;
}

const rootOf = (options) => findRoot(options.root);
const print = (options, value, format) => console.log(options.json ? JSON.stringify(value, null, 2) : format(value));
/* The session-less commands run the MCP tools' own implementations. */
const runTool = (options, name, args) => tools[name].run(args, { root: rootOf(options) });

/* Render, act, explain and graph in one session: text is printed as it goes, JSON at the end. */
async function runSession(options, target, extra = {}) {
  const session = await createSession({ root: rootOf(options), captureStacks: !options["no-stacks"] });
  const report = { render: null, acts: [], why: [], graph: null };
  const show = (value, format) => {
    if (!options.json) console.log(format(value));
    return value;
  };
  try {
    const mode = options.hydrate ? "hydrate" : options.ssr ? "ssr" : "client";
    report.render = show(await session.render({ target, mode }), (r) => formatRender(r, options));
    for (const spec of options.act) {
      const act = await session.act({ ...parseAct(spec), settle: Number(options.settle ?? 0) });
      report.acts.push(show(act, (a) => formatAct(a, options)));
    }
    for (const spec of [...options.why, ...(extra.why ?? [])]) report.why.push(show(session.why(whyRequest(spec)), formatWhy));
    if (options.graph || extra.graph) {
      report.graph = show(session.graph({ around: options.around, depth: Number(options.depth ?? 2) }), formatGraph);
    }
  } finally {
    session.close();
  }
  if (options.json) console.log(JSON.stringify(report, null, 2));
  return [report.render, ...report.acts].some((r) => r.diagnostics.some((d) => d.severity === "error")) ? 1 : 0;
}

/* Each command returns its exit code (null keeps the process running). */
const COMMANDS = {
  api(options, [path]) {
    const result = runTool(options, "xote_api", { path, digest: options.digest });
    if (!options.digest) print(options, result, formatApi);
    else if (options.out) writeFileSync(options.out, result.digest);
    else console.log(result.digest);
    return result.kind === "error" ? 1 : 0;
  },
  async check(options) {
    const result = await runTool(options, "xote_check", { build: !options["no-build"] });
    print(options, result, formatCheck);
    return result.ok ? 0 : 1;
  },
  expand(options, [module]) {
    print(options, runTool(options, "xote_expand", { module: need(module, "expand needs a module name") }), formatExpand);
    return 0;
  },
  render: (options, [target]) => runSession(options, need(target, "render needs a target")),
  why: (options, [target, spec]) => runSession(options, need(spec && target, "why needs a target and a selector or node id"), { why: [spec] }),
  graph: (options, [target]) => runSession(options, need(target, "graph needs a target"), { graph: true }),
  mcp(options) {
    serveStdio({ root: rootOf(options) });
    return null;
  },
};

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const [command, ...args] = options._;
  if (options.help || !command) {
    console.log(USAGE);
    return options.help ? 0 : 2;
  }
  if (!Object.hasOwn(COMMANDS, command)) throw new Error(`unknown command ${command}\n\n${USAGE}`);
  return COMMANDS[command](options, args);
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
