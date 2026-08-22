/*
 * DOM mutation profiler.
 *
 * Counts the DOM calls each framework makes per operation. Timings say which
 * framework is slower; this says why — a reconciler doing 997 node moves for a
 * two-row swap shows up here long before it shows up in a flame chart.
 *
 * Unlike the timings, these counts are deterministic — the same build always
 * makes the same calls — which is what makes them usable as a CI signal.
 *
 * Usage: node dom-ops.mjs [--apps xote,xote-base] [--json <path>]
 *        (run `node build.mjs` first)
 */

import { createReadStream } from "node:fs";
import { mkdir, stat, writeFile } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import { resolveChromePath } from "./driver.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const distDir = path.join(here, "dist");

function parseArgs(argv) {
  const options = { apps: ["xote", "react", "vue", "solid"], jsonPath: null };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--apps") options.apps = argv[++i].split(",");
    else if (arg === "--json") options.jsonPath = path.resolve(argv[++i]);
    else throw new Error(`Unknown option: ${arg}`);
  }

  return options;
}

const { apps: APPS, jsonPath } = parseArgs(process.argv.slice(2));

const OPERATIONS = [
  { name: "create 1k", setup: ["#clear"], target: "#run" },
  { name: "swap rows", setup: ["#clear", "#run"], target: "#swaprows" },
  { name: "update 10th", setup: ["#clear", "#run"], target: "#update" },
  { name: "remove row", setup: ["#clear", "#run"], target: "#tbody tr:nth-child(5) .remove" },
  { name: "clear 1k", setup: ["#clear", "#run"], target: "#clear" },
];

const COUNTED = ["insertBefore", "appendChild", "removeChild", "replaceChild"];

const PROBE = `
window.__ops = {};
const bump = (name) => { window.__ops[name] = (window.__ops[name] ?? 0) + 1; };

for (const name of ${JSON.stringify(COUNTED)}) {
  const original = Node.prototype[name];
  Node.prototype[name] = function (...args) { bump(name); return original.apply(this, args); };
}

const remove = Element.prototype.remove;
Element.prototype.remove = function () { bump("remove"); return remove.call(this); };

const createElement = Document.prototype.createElement;
Document.prototype.createElement = function (...args) { bump("createElement"); return createElement.apply(this, args); };

const createElementNS = Document.prototype.createElementNS;
Document.prototype.createElementNS = function (...args) { bump("createElement"); return createElementNS.apply(this, args); };

const cloneNode = Node.prototype.cloneNode;
Node.prototype.cloneNode = function (...args) { bump("cloneNode"); return cloneNode.apply(this, args); };

const createTextNode = Document.prototype.createTextNode;
Document.prototype.createTextNode = function (...args) { bump("createTextNode"); return createTextNode.apply(this, args); };

window.__resetOps = () => { window.__ops = {}; };
window.__settle = () => new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0)));
window.__clickAndCount = async (selector) => {
  window.__resetOps();
  document.querySelector(selector).click();
  await window.__settle();
  return { ...window.__ops };
};
`;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
};

async function startServer(root) {
  const server = http.createServer(async (req, res) => {
    let file = path.join(root, new URL(req.url, "http://127.0.0.1").pathname);
    try {
      if ((await stat(file)).isDirectory()) file = path.join(file, "index.html");
    } catch {
      res.writeHead(404).end("not found");
      return;
    }
    res.writeHead(200, { "content-type": MIME[path.extname(file)] ?? "text/plain" });
    createReadStream(file).pipe(res);
  });

  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  return { server, port: server.address().port };
}

const { server, port } = await startServer(distDir);

const executablePath = resolveChromePath();
const browser = await chromium.launch({
  ...(executablePath ? { executablePath } : {}),
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});

const table = {};

for (const app of APPS) {
  const page = await browser.newPage();
  await page.addInitScript(PROBE);
  await page.goto(`http://127.0.0.1:${port}/${app}/index.html`);
  await page.waitForFunction(() => window.__BENCH_READY__ === true);

  for (const operation of OPERATIONS) {
    for (const selector of operation.setup) {
      await page.evaluate(async (sel) => await window.__clickAndCount(sel), selector);
    }

    const ops = await page.evaluate(
      async (sel) => await window.__clickAndCount(sel),
      operation.target,
    );

    table[operation.name] ??= {};
    table[operation.name][app] = ops;
  }

  await page.close();
}

await browser.close();
server.close();

const pad = Math.max(...APPS.map((app) => app.length));

for (const [operation, perApp] of Object.entries(table)) {
  console.log(`\n${operation}`);
  for (const app of APPS) {
    const ops = perApp[app];
    const total = Object.values(ops).reduce((a, b) => a + b, 0);
    const detail = Object.entries(ops)
      .sort((a, b) => b[1] - a[1])
      .map(([name, count]) => `${name}=${count}`)
      .join(" ");
    console.log(`  ${app.padEnd(pad)} ${String(total).padStart(6)} calls   ${detail}`);
  }
}

if (jsonPath) {
  await mkdir(path.dirname(jsonPath), { recursive: true });
  await writeFile(
    jsonPath,
    `${JSON.stringify({ apps: APPS, operations: table }, null, 2)}\n`,
  );
  console.log(`\nWritten to ${path.relative(process.cwd(), jsonPath) || jsonPath}`);
}
