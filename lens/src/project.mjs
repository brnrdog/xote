// The project being inspected: its root, its Xote package, its compiled
// modules and its build.

import { execFile } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, relative, resolve, sep } from "node:path";
import { pathToFileURL } from "node:url";

export const toPosix = (path) => path.split(sep).join("/");
export const relPath = (root, file) => toPosix(relative(root, file));

/* The nearest directory at or above `from` holding a rescript.json. */
export function findRoot(from = process.cwd()) {
  for (let dir = resolve(from); ; dir = dirname(dir)) {
    if (existsSync(join(dir, "rescript.json"))) return dir;
    if (dirname(dir) === dir) throw new Error(`no rescript.json found at or above ${from}`);
  }
}

const resolveFromProject = (root, specifier) => createRequire(join(root, "package.json")).resolve(specifier);

/* The Xote package the project uses, or the project itself when it is Xote. */
export function xoteRoot(root) {
  if (JSON.parse(readFileSync(join(root, "package.json"), "utf8")).name === "xote") return root;
  return dirname(resolveFromProject(root, "xote/package.json"));
}

/* One of Xote's compiled modules, from the project's copy (the same instance
   the project's own code imports). */
export const importXote = (root, module) => import(pathToFileURL(join(xoteRoot(root), "src", `${module}.res.mjs`)).href);

const SKIP_DIRS = new Set(["node_modules", "lib", ".git", "dist"]);

/* Every file under `dir` whose name passes `test`, skipping dependencies and build output. */
export function walk(dir, test, out = []) {
  let entries = [];
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {}
  for (const entry of entries) {
    const path = join(dir, entry.name);
    if (!entry.isDirectory()) {
      if (test(entry.name)) out.push(path);
    } else if (!SKIP_DIRS.has(entry.name) && !entry.name.startsWith(".")) walk(path, test, out);
  }
  return out;
}

/* The compiled `.res.mjs` of a module, by name (`Counter`) or by a path to its source or output. */
export function findCompiled(root, name) {
  const direct = resolve(root, name);
  if (existsSync(direct) && statSync(direct).isFile()) return direct.endsWith(".res") ? direct + ".mjs" : direct;
  const wanted = `${name}.res.mjs`;
  const matches = walk(root, (file) => file === wanted);
  if (matches.length === 0) throw new Error(`no compiled module ${wanted} under ${root} (build the project first)`);
  if (matches.length > 1) {
    throw new Error(`${wanted} is ambiguous: ${matches.map((m) => relative(root, m)).join(", ")}; pass a path instead`);
  }
  return matches[0];
}

/* Split `Counter.App.make` into the module and the export path inside it. */
export function parseTarget(target) {
  const [module, ...path] = target.split(".");
  return { module, path };
}

const isNode = (value) => value !== null && typeof value === "object" && "TAG" in value;

/* Import a target's module and resolve its export: a component or a node. */
export async function loadTarget(root, target) {
  const { module, path } = parseTarget(target);
  const file = findCompiled(root, module);
  let value = await import(pathToFileURL(file).href);
  for (const part of path) {
    if (value == null || !(part in value)) {
      const available = value && typeof value === "object" ? Object.keys(value).join(", ") : "nothing";
      throw new Error(`no export ${path.join(".")} (at ${part}); available: ${available}`);
    }
    value = value[part];
  }
  if (value && typeof value === "object" && !isNode(value)) {
    if (typeof value.make === "function") value = value.make;
    else if ("app" in value) value = value.app;
    else if ("default" in value) value = value.default;
  }
  return { file, value };
}

export function toNode(XoteJSX, value) {
  if (typeof value === "function") return XoteJSX.jsx(value, {});
  if (isNode(value)) return value;
  throw new Error("the target is neither a component nor a node");
}

/* Route console.warn / console.error into `sink` instead of printing; returns the restore. */
export function captureConsole(sink, show = String) {
  const original = { warn: console.warn, error: console.error };
  for (const level of ["warn", "error"]) console[level] = (...args) => sink.push({ level, message: args.map(show).join(" ") });
  return () => Object.assign(console, original);
}

/* Run the project's ReScript build: resolves with its output and exit code, never rejects. */
export function build(root) {
  let bin = join(root, "node_modules", ".bin", "rescript");
  try {
    const js = join(dirname(resolveFromProject(root, "rescript/package.json")), "cli", "rescript.js");
    if (existsSync(js)) bin = js;
  } catch {}
  const [command, args] = bin.endsWith(".js") ? [process.execPath, [bin, "build"]] : [bin, ["build"]];
  const env = { ...process.env, NO_COLOR: "1", FORCE_COLOR: "0" };
  return new Promise((done) =>
    execFile(command, args, { cwd: root, maxBuffer: 32 * 1024 * 1024, env }, (error, stdout, stderr) =>
      done({ code: error ? (typeof error.code === "number" ? error.code : 1) : 0, output: `${stdout}${stderr}` }),
    ),
  );
}
