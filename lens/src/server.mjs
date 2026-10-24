// Server rendering, in a DOM-less child process. Xote decides
// `SSRContext.isServer` once, at load, from whether `document` exists, so a
// server render inside the session's jsdom page would take the client branch
// of every check and hide the very mismatches hydration is about.
//
//   node server.mjs <project-root> <target>   → JSON on stdout

import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";
import { captureConsole, importXote, loadTarget, relPath, toNode } from "./project.mjs";

const self = fileURLToPath(import.meta.url);

/* Render `target` on a fresh, DOM-less server: { html, stateScript, file, log }. */
export function renderOnServer(root, target) {
  return new Promise((resolve, reject) => {
    execFile(process.execPath, [self, root, target], { maxBuffer: 64 * 1024 * 1024 }, (error, stdout, stderr) => {
      let result;
      try {
        result = JSON.parse(stdout);
      } catch {
        return reject(new Error(`server render failed: ${(stderr || error?.message || "no output").trim()}`));
      }
      if (result.error) reject(new Error(`server render failed: ${result.error}`));
      else resolve(result);
    });
  });
}

async function main([root, target]) {
  const log = [];
  captureConsole(log);
  try {
    const SSR = await importXote(root, "SSR");
    const SSRState = await importXote(root, "SSRState");
    const XoteJSX = await importXote(root, "XoteJSX");
    const { file, value } = await loadTarget(root, target);
    const html = SSR.renderToString(() => toNode(XoteJSX, value), undefined);
    const stateScript = SSRState.generateScript(undefined);
    process.stdout.write(JSON.stringify({ html, stateScript, file: relPath(root, file), log }));
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: error?.message ?? String(error), log }));
  }
}

if (process.argv[1] === self) main(process.argv.slice(2));
