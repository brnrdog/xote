// Finding things in the project being inspected: its root, the Xote package it
// depends on, its compiled modules, and its build.

import { execFile } from "node:child_process";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, relative, resolve, sep } from "node:path";
import { pathToFileURL } from "node:url";

/* The nearest directory at or above `from` holding a rescript.json. */
export function findRoot(from = process.cwd()) {
  let dir = resolve(from);
  for (;;) {
    if (existsSync(join(dir, "rescript.json"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) {
      throw new Error(`no rescript.json found at or above ${from}`);
    }
    dir = parent;
  }
}

/* Resolve a module specifier the way the project itself would. */
export function resolveFromProject(root, specifier) {
  return createRequire(join(root, "package.json")).resolve(specifier);
}

/* The root of the Xote package the project uses — or the project itself, when
   it is the Xote repository. */
export function xoteRoot(root) {
  const own = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
  if (own.name === "xote") return root;
  return dirname(resolveFromProject(root, "xote/package.json"));
}

/* Import one of Xote's compiled modules from the project's copy, so it is the
   same module instance the project's own code imports. */
export async function importXote(root, module) {
  return import(pathToFileURL(join(xoteRoot(root), "src", `${module}.res.mjs`)).href);
}

const SKIP_DIRS = new Set(["node_modules", "lib", ".git", "dist"]);

/* Every file under `dir` whose name satisfies `test`, skipping dependencies
   and build output. */
export function walk(dir, test, out = []) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const entry of entries) {
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name) && !entry.name.startsWith(".")) walk(join(dir, entry.name), test, out);
    } else if (test(entry.name)) {
      out.push(join(dir, entry.name));
    }
  }
  return out;
}

/* The compiled `.res.mjs` of a module, by its module name (`Counter`) or by a
   path to its source or output. */
export function findCompiled(root, name) {
  const direct = resolve(root, name);
  if (existsSync(direct) && statSync(direct).isFile()) {
    return direct.endsWith(".res") ? direct + ".mjs" : direct;
  }
  const wanted = `${name}.res.mjs`;
  const matches = walk(root, (file) => file === wanted);
  if (matches.length === 0) {
    throw new Error(`no compiled module ${wanted} under ${root} (build the project first)`);
  }
  if (matches.length > 1) {
    throw new Error(
      `${wanted} is ambiguous: ${matches.map((m) => relative(root, m)).join(", ")}; pass a path instead`,
    );
  }
  return matches[0];
}

/* Split `Counter.App.make` into the module file and the export path inside it. */
export function parseTarget(target) {
  const [module, ...path] = target.split(".");
  return { module, path };
}

/* Run the project's ReScript build. Resolves with its combined output and
   exit code; never rejects on a failed build. */
export function build(root) {
  return new Promise((resolvePromise) => {
    let bin;
    try {
      bin = join(dirname(resolveFromProject(root, "rescript/package.json")), "cli", "rescript.js");
      if (!existsSync(bin)) bin = join(root, "node_modules", ".bin", "rescript");
    } catch {
      bin = join(root, "node_modules", ".bin", "rescript");
    }
    const command = bin.endsWith(".js") ? process.execPath : bin;
    const args = bin.endsWith(".js") ? [bin, "build"] : ["build"];
    execFile(command, args, { cwd: root, maxBuffer: 32 * 1024 * 1024, env: { ...process.env, NO_COLOR: "1", FORCE_COLOR: "0" } }, (error, stdout, stderr) => {
      resolvePromise({ code: error ? (typeof error.code === "number" ? error.code : 1) : 0, output: `${stdout}${stderr}` });
    });
  });
}

export const toPosix = (path) => path.split(sep).join("/");
