// Server rendering, in a process of its own.
//
// A server has no DOM, and Xote decides `SSRContext.isServer` once, when it is
// first loaded, from whether `document` exists. Rendering the server half
// inside the session's jsdom page would therefore take the client branch of
// every `SSRContext` check and hide exactly the mismatches hydration is about.
// So the server half runs here, in a child process with no DOM, and hands its
// markup back.
//
//   node server.mjs <project-root> <target>   → JSON on stdout

import { execFile } from "node:child_process";
import { relative } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { findCompiled, importXote, parseTarget, toPosix } from "./project.mjs";

const self = fileURLToPath(import.meta.url);

/* Render `target` on a fresh, DOM-less server. */
export function renderOnServer(root, target) {
  return new Promise((resolve, reject) => {
    execFile(process.execPath, [self, root, target], { maxBuffer: 64 * 1024 * 1024 }, (error, stdout, stderr) => {
      let result;
      try {
        result = JSON.parse(stdout);
      } catch {
        reject(new Error(`server render failed: ${(stderr || error?.message || "no output").trim()}`));
        return;
      }
      if (result.error) reject(new Error(`server render failed: ${result.error}`));
      else resolve(result);
    });
  });
}

const isNode = (value) => value !== null && typeof value === "object" && "TAG" in value;

export function resolveExport(module, path) {
  let value = module;
  for (const part of path) {
    if (value == null || !(part in value)) {
      const available = value && typeof value === "object" ? Object.keys(value).join(", ") : "nothing";
      throw new Error(`no export ${path.join(".")} (at ${part}); available: ${available}`);
    }
    value = value[part];
  }
  if (value && typeof value === "object" && !isNode(value)) {
    if (typeof value.make === "function") return value.make;
    if ("app" in value) return value.app;
    if ("default" in value) return value.default;
  }
  return value;
}

export function toNode(XoteJSX, value) {
  if (typeof value === "function") return XoteJSX.jsx(value, {});
  if (isNode(value)) return value;
  throw new Error("the target is neither a component nor a node");
}

async function main([root, target]) {
  const log = [];
  for (const level of ["warn", "error"]) {
    console[level] = (...args) => log.push({ level, message: args.map(String).join(" ") });
  }
  try {
    const SSR = await importXote(root, "SSR");
    const SSRState = await importXote(root, "SSRState");
    const XoteJSX = await importXote(root, "XoteJSX");
    const { module: moduleName, path } = parseTarget(target);
    const file = findCompiled(root, moduleName);
    const module = await import(pathToFileURL(file).href);
    const value = resolveExport(module, path);
    const html = SSR.renderToString(() => toNode(XoteJSX, value), undefined);
    const stateScript = SSRState.generateScript(undefined);
    process.stdout.write(JSON.stringify({ html, stateScript, file: toPosix(relative(root, file)), log }));
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: error?.message ?? String(error), log }));
  }
}

if (process.argv[1] === self) main(process.argv.slice(2));
