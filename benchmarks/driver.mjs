/*
 * Benchmark driver.
 *
 * Serves the built apps over loopback, drives them with Chromium and records
 * per-operation timings, memory and payload size. Every framework runs the
 * same DOM, the same data and the same click sequence, so the only variable
 * is the framework doing the work.
 *
 * Usage:
 *   node driver.mjs [--iterations N] [--warmup N] [--apps xote,react]
 *                   [--out <dir>] [--headed]
 */

import { createReadStream, existsSync } from "node:fs";
import { readdir, readFile, mkdir, writeFile, stat } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { brotliCompressSync, gzipSync } from "node:zlib";
import { chromium } from "playwright";

const here = path.dirname(fileURLToPath(import.meta.url));
const distDir = path.join(here, "dist");

/*
 * Chromium: an explicit override wins, then the browser this dev environment
 * ships, and otherwise Playwright resolves the one it installed (which is how
 * CI runs it).
 */
export function resolveChromePath() {
  if (process.env.BENCH_CHROME_PATH) return process.env.BENCH_CHROME_PATH;

  const preinstalled = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
  return existsSync(preinstalled) ? preinstalled : undefined;
}

const CHROME_ARGS = [
  "--no-sandbox",
  "--disable-dev-shm-usage",
  "--enable-precise-memory-info",
  "--js-flags=--expose-gc",
  "--disable-background-timer-throttling",
  "--disable-backgrounding-occluded-windows",
  "--disable-renderer-backgrounding",
  "--disable-extensions",
  "--disable-translate",
  "--disable-features=Translate,BackForwardCache,CalculateNativeWinOcclusion",
  "--force-device-scale-factor=1",
  "--hide-scrollbars",
  "--window-size=1280,1024",
];

const ALL_APPS = ["xote", "react", "vue", "solid"];

const APP_LABELS = {
  xote: "Xote",
  react: "React",
  vue: "Vue",
  solid: "Solid",
};

/* CI adds variants like `xote-base`, which have no entry above. */
const labelFor = (app) => APP_LABELS[app] ?? app;

/*
 * Benchmark definitions.
 *
 * Every iteration starts from an empty list (`#clear`), replays `setup`
 * unmeasured, then measures a single click on `target`. `expect` is asserted
 * after the measurement so a framework that defers work cannot post a fast
 * time for an unfinished update.
 */
const BENCHMARKS = [
  {
    id: "create-1k",
    name: "Create 1,000 rows",
    setup: [],
    target: "#run",
    expect: { rows: 1000 },
  },
  {
    id: "replace-1k",
    name: "Replace 1,000 rows",
    setup: ["#run"],
    target: "#run",
    expect: { rows: 1000 },
  },
  {
    id: "update-10th",
    name: "Update every 10th row",
    setup: ["#run"],
    target: "#update",
    expect: { rows: 1000, suffixed: 100 },
  },
  {
    id: "select-row",
    name: "Select a row",
    setup: ["#run"],
    target: "#tbody tr:nth-child(5) .lbl",
    expect: { rows: 1000, selected: 1 },
  },
  {
    id: "swap-rows",
    name: "Swap two rows",
    setup: ["#run"],
    target: "#swaprows",
    expect: { rows: 1000 },
  },
  {
    id: "remove-row",
    name: "Remove a row",
    setup: ["#run"],
    target: "#tbody tr:nth-child(5) .remove",
    expect: { rows: 999 },
  },
  {
    id: "create-10k",
    name: "Create 10,000 rows",
    setup: [],
    target: "#runlots",
    expect: { rows: 10000 },
  },
  {
    id: "append-1k",
    name: "Append 1,000 to 10,000 rows",
    setup: ["#runlots"],
    target: "#add",
    expect: { rows: 11000 },
  },
  {
    id: "clear-10k",
    name: "Clear 10,000 rows",
    setup: ["#runlots"],
    target: "#clear",
    expect: { rows: 0 },
  },
];

/* ------------------------------------------------------------------ */
/* In-page harness                                                     */
/* ------------------------------------------------------------------ */

/*
 * Installed into every page before the app loads. Kept as a source string so
 * the exact same helpers exist in each app's realm.
 */
const HARNESS = `
window.__bench = (() => {
  const nextTask = () =>
    new Promise((resolve) => {
      const channel = new MessageChannel();
      channel.port1.onmessage = () => resolve();
      channel.port2.postMessage(0);
    });

  const afterPaint = () =>
    new Promise((resolve) =>
      requestAnimationFrame(() => setTimeout(resolve, 0)),
    );

  /* Forces style + layout so DOM work cannot hide behind a lazy relayout. */
  const layout = () => document.getElementById("tbody").offsetHeight;

  const state = () => {
    const rows = document.querySelectorAll("#tbody tr");
    let suffixed = 0;
    for (const row of rows) {
      const label = row.querySelector(".lbl");
      if (label && label.textContent.endsWith(" !!!")) suffixed++;
    }
    return {
      rows: rows.length,
      selected: document.querySelectorAll("#tbody tr.danger").length,
      suffixed,
    };
  };

  const click = async (selector) => {
    const el = document.querySelector(selector);
    if (!el) throw new Error("missing element: " + selector);
    el.click();
    await nextTask();
    layout();
    await afterPaint();
  };

  const measure = async (selector) => {
    const el = document.querySelector(selector);
    if (!el) throw new Error("missing element: " + selector);

    /* Start on a fresh frame so a pending frame is not billed to us. */
    await afterPaint();
    await nextTask();

    const start = performance.now();
    el.click();
    /* Drains microtasks and any scheduler task (React posts one). */
    await nextTask();
    layout();
    const commit = performance.now() - start;

    await afterPaint();
    const painted = performance.now() - start;

    return { commit, painted, state: state() };
  };

  return { click, measure, state, nextTask, afterPaint };
})();
`;

/* ------------------------------------------------------------------ */
/* Static server                                                       */
/* ------------------------------------------------------------------ */

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
};

function startServer(root) {
  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, "http://127.0.0.1");
    let filePath = path.join(root, decodeURIComponent(url.pathname));

    try {
      const info = await stat(filePath);
      if (info.isDirectory()) filePath = path.join(filePath, "index.html");
    } catch {
      res.writeHead(404).end("not found");
      return;
    }

    res.writeHead(200, {
      "content-type": MIME[path.extname(filePath)] ?? "application/octet-stream",
      "cache-control": "no-store",
    });
    createReadStream(filePath).pipe(res);
  });

  return new Promise((resolve) => {
    server.listen(0, "127.0.0.1", () =>
      resolve({ server, port: server.address().port }),
    );
  });
}

/* ------------------------------------------------------------------ */
/* Statistics                                                          */
/* ------------------------------------------------------------------ */

const median = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = sorted.length >> 1;
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};

const mean = (values) => values.reduce((a, b) => a + b, 0) / values.length;

const stdev = (values) => {
  if (values.length < 2) return 0;
  const m = mean(values);
  return Math.sqrt(
    values.reduce((acc, v) => acc + (v - m) ** 2, 0) / (values.length - 1),
  );
};

/* ------------------------------------------------------------------ */
/* Measurement passes                                                  */
/* ------------------------------------------------------------------ */

function assertState(actual, expected, context) {
  for (const [key, want] of Object.entries(expected)) {
    if (actual[key] !== want) {
      throw new Error(
        `${context}: expected ${key}=${want} but the DOM reported ${actual[key]}`,
      );
    }
  }
}

async function newPage(browser, url) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 1024 } });
  await page.addInitScript(HARNESS);
  /* A framework that throws would otherwise post a suspiciously good time. */
  page.on("pageerror", (error) => {
    console.error(`\npage error on ${url}: ${error.message}`);
    process.exitCode = 1;
  });
  await page.goto(url, { waitUntil: "load" });
  await page.waitForFunction(() => window.__BENCH_READY__ === true);
  return page;
}

async function runIteration(page, benchmark) {
  /* A backgrounded tab gets its rAF throttled, which would wreck the timing. */
  await page.bringToFront();

  await page.evaluate(async () => {
    await window.__bench.click("#clear");
  });

  for (const selector of benchmark.setup) {
    await page.evaluate(async (sel) => await window.__bench.click(sel), selector);
  }

  return await page.evaluate(
    async (sel) => await window.__bench.measure(sel),
    benchmark.target,
  );
}

/*
 * Runs one benchmark across every app, interleaved iteration by iteration.
 *
 * Position within a round costs far more than any difference between the apps:
 * on a shared runner the app measured first pays up to 2.5x on the
 * allocation-heavy benchmarks. Alternating the order every iteration spreads
 * that penalty evenly instead of charging it to whichever app is listed first.
 */
async function runBenchmark(browser, apps, urlFor, benchmark, options) {
  const pages = new Map();
  const samples = new Map();

  for (const app of apps) {
    pages.set(app, await newPage(browser, urlFor(app)));
    samples.set(app, { commit: [], painted: [] });
  }

  try {
    for (let i = 0; i < options.warmup + options.iterations; i++) {
      const order = i % 2 === 0 ? apps : [...apps].reverse();

      for (const app of order) {
        const result = await runIteration(pages.get(app), benchmark);
        assertState(result.state, benchmark.expect, `${app} ${benchmark.id}`);

        if (i >= options.warmup) {
          samples.get(app).commit.push(result.commit);
          samples.get(app).painted.push(result.painted);
        }
      }
    }
  } finally {
    for (const page of pages.values()) await page.close();
  }

  return new Map(
    [...samples].map(([app, taken]) => [
      app,
      {
        commit: summarize(taken.commit),
        painted: summarize(taken.painted),
        samples: taken,
      },
    ]),
  );
}

function summarize(values) {
  return {
    median: median(values),
    mean: mean(values),
    stdev: stdev(values),
    min: Math.min(...values),
    max: Math.max(...values),
  };
}

async function measureStartup(browser, url, options) {
  const samples = [];

  for (let i = 0; i < options.warmup + options.iterations; i++) {
    const page = await newPage(browser, url);
    const ready = await page.evaluate(() => window.__BENCH_READY_AT__);
    await page.close();
    if (i >= options.warmup) samples.push(ready);
  }

  return summarize(samples);
}

async function measureMemory(browser, url) {
  const page = await newPage(browser, url);
  const cdp = await page.context().newCDPSession(page);

  const read = async () => {
    await cdp.send("HeapProfiler.collectGarbage");
    await page.evaluate(async () => await window.__bench.nextTask());
    return await page.evaluate(() => performance.memory.usedJSHeapSize);
  };

  const ready = await read();

  await page.evaluate(async () => await window.__bench.click("#run"));
  const rows1k = await read();

  await page.evaluate(async () => await window.__bench.click("#clear"));
  await page.evaluate(async () => await window.__bench.click("#runlots"));
  const rows10k = await read();

  await page.evaluate(async () => await window.__bench.click("#clear"));
  const cleared = await read();

  await page.close();

  return { ready, rows1k, rows10k, cleared };
}

async function measurePayload(app) {
  const assets = path.join(distDir, app, "assets");
  const files = await readdir(assets);
  const result = { js: { raw: 0, gzip: 0, brotli: 0 }, css: { raw: 0, gzip: 0, brotli: 0 } };

  for (const file of files) {
    const kind = file.endsWith(".css") ? "css" : file.endsWith(".js") ? "js" : null;
    if (!kind) continue;
    const bytes = await readFile(path.join(assets, file));
    result[kind].raw += bytes.length;
    result[kind].gzip += gzipSync(bytes).length;
    result[kind].brotli += brotliCompressSync(bytes).length;
  }

  return result;
}

/* ------------------------------------------------------------------ */
/* Reporting                                                           */
/* ------------------------------------------------------------------ */

const ms = (value) => value.toFixed(1);
const kb = (bytes) => (bytes / 1024).toFixed(1);

function relativeRow(apps, values) {
  const best = Math.min(...apps.map((app) => values[app]));
  return apps.map((app) => {
    const value = values[app];
    const factor = value / best;
    const marker = value === best ? "**" : "";
    return `${marker}${ms(value)}${marker} (${factor.toFixed(2)}x)`;
  });
}

function renderMarkdown(report) {
  const apps = report.apps;
  const head = `| Benchmark | ${apps.map((a) => labelFor(a)).join(" | ")} |`;
  const rule = `| --- | ${apps.map(() => "---").join(" | ")} |`;
  const lines = [];

  lines.push(`# Xote vs React / Vue / Solid`);
  lines.push("");
  lines.push(
    `Chromium ${report.environment.chromium}, ${report.environment.cpus}x ${report.environment.cpuModel}, Node ${report.environment.node}.`,
  );
  lines.push(
    `${report.options.iterations} measured iterations per benchmark (${report.options.warmup} warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.`,
  );
  lines.push("");
  lines.push(`Framework versions: ${apps.map((a) => `${labelFor(a)} ${report.versions[a]}`).join(", ")}.`);
  lines.push("");

  lines.push(`## Operations — commit time (ms)`);
  lines.push("");
  lines.push(
    "Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.",
  );
  lines.push("");
  lines.push(head, rule);

  for (const benchmark of report.benchmarks) {
    const values = Object.fromEntries(
      apps.map((app) => [app, report.results[app][benchmark.id].commit.median]),
    );
    lines.push(`| ${benchmark.name} | ${relativeRow(apps, values).join(" | ")} |`);
  }

  lines.push("");
  lines.push(`## Operations — time to paint (ms)`);
  lines.push("");
  lines.push("The same clicks measured through to the frame that paints the result.");
  lines.push("");
  lines.push(head, rule);

  for (const benchmark of report.benchmarks) {
    const values = Object.fromEntries(
      apps.map((app) => [app, report.results[app][benchmark.id].painted.median]),
    );
    lines.push(`| ${benchmark.name} | ${relativeRow(apps, values).join(" | ")} |`);
  }

  lines.push("");
  lines.push(`## Startup and payload`);
  lines.push("");
  lines.push(head, rule);
  lines.push(
    `| Time to first render (ms) | ${relativeRow(
      apps,
      Object.fromEntries(apps.map((a) => [a, report.startup[a].median])),
    ).join(" | ")} |`,
  );
  lines.push(
    `| JS bundle, minified (KB) | ${apps
      .map((a) => kb(report.payload[a].js.raw))
      .join(" | ")} |`,
  );
  lines.push(
    `| JS bundle, gzipped (KB) | ${apps
      .map((a) => kb(report.payload[a].js.gzip))
      .join(" | ")} |`,
  );
  lines.push(
    `| JS bundle, brotli (KB) | ${apps
      .map((a) => kb(report.payload[a].js.brotli))
      .join(" | ")} |`,
  );

  lines.push("");
  lines.push(`## Memory (MB of used JS heap, after forced GC)`);
  lines.push("");
  lines.push(head, rule);
  const memRows = [
    ["After load, empty list", "ready"],
    ["1,000 rows", "rows1k"],
    ["10,000 rows", "rows10k"],
    ["After clearing 10,000 rows", "cleared"],
  ];
  for (const [name, key] of memRows) {
    lines.push(
      `| ${name} | ${apps
        .map((a) => (report.memory[a][key] / 1024 / 1024).toFixed(1))
        .join(" | ")} |`,
    );
  }

  lines.push("");
  return lines.join("\n");
}

/* ------------------------------------------------------------------ */
/* Entry point                                                         */
/* ------------------------------------------------------------------ */

function parseArgs(argv) {
  const options = {
    iterations: 15,
    warmup: 3,
    apps: ALL_APPS,
    headed: false,
    out: path.join(here, "results"),
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--iterations") options.iterations = Number(argv[++i]);
    else if (arg === "--warmup") options.warmup = Number(argv[++i]);
    else if (arg === "--apps") options.apps = argv[++i].split(",");
    else if (arg === "--out") options.out = path.resolve(argv[++i]);
    else if (arg === "--headed") options.headed = true;
    else throw new Error(`Unknown option: ${arg}`);
  }

  return options;
}

async function readVersions(apps) {
  const versions = {};
  const dep = async (name) =>
    JSON.parse(await readFile(path.join(here, "node_modules", name, "package.json"), "utf8"))
      .version;

  const xoteVersion = async () => {
    const pkg = JSON.parse(await readFile(path.join(here, "..", "package.json"), "utf8"));
    return `${pkg.version} (this checkout)`;
  };

  for (const app of apps) {
    if (app === "react") versions[app] = await dep("react-dom");
    else if (app === "vue") versions[app] = await dep("vue");
    else if (app === "solid") versions[app] = await dep("solid-js");
    else if (app === "xote") versions[app] = await xoteVersion();
    /* CI variants (`xote-base`) are built elsewhere; the runner labels them. */
    else versions[app] = process.env[`BENCH_VERSION_${app.replaceAll("-", "_")}`] ?? "unknown";
  }

  return versions;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const { server, port } = await startServer(distDir);
  const os = await import("node:os");

  const executablePath = resolveChromePath();
  const browser = await chromium.launch({
    ...(executablePath ? { executablePath } : {}),
    headless: !options.headed,
    args: CHROME_ARGS,
  });

  const report = {
    generatedAt: new Date().toISOString(),
    options,
    apps: options.apps,
    benchmarks: BENCHMARKS.map(({ id, name }) => ({ id, name })),
    environment: {
      chromium: browser.version(),
      node: process.version,
      cpus: os.cpus().length,
      cpuModel: os.cpus()[0].model.trim(),
      platform: `${os.type()} ${os.release()}`,
    },
    versions: await readVersions(options.apps),
    results: {},
    startup: {},
    memory: {},
    payload: {},
  };

  const urlFor = (app) => `http://127.0.0.1:${port}/${app}/index.html`;
  const pad = Math.max(...options.apps.map((app) => app.length));

  try {
    for (const app of options.apps) report.results[app] = {};

    for (const benchmark of BENCHMARKS) {
      const perApp = await runBenchmark(browser, options.apps, urlFor, benchmark, options);

      for (const [app, result] of perApp) {
        report.results[app][benchmark.id] = result;
        console.log(
          `${app.padEnd(pad)} ${benchmark.id.padEnd(16)} commit ${ms(
            result.commit.median,
          )}ms  painted ${ms(result.painted.median)}ms`,
        );
      }
    }

    for (const app of options.apps) {
      process.stdout.write(`${app.padEnd(pad)} startup          `);
      report.startup[app] = await measureStartup(browser, urlFor(app), {
        ...options,
        iterations: Math.min(options.iterations, 8),
        warmup: 1,
      });
      console.log(`${ms(report.startup[app].median)}ms`);

      process.stdout.write(`${app.padEnd(pad)} memory           `);
      report.memory[app] = await measureMemory(browser, urlFor(app));
      console.log(`${kb(report.memory[app].rows1k)}KB @1k rows`);

      report.payload[app] = await measurePayload(app);
    }
  } finally {
    await browser.close();
    server.close();
  }

  await mkdir(options.out, { recursive: true });
  await writeFile(
    path.join(options.out, "results.json"),
    JSON.stringify(report, null, 2),
  );

  const markdown = renderMarkdown(report);
  await writeFile(path.join(options.out, "RESULTS.md"), markdown);

  console.log(`\n${markdown}`);
  console.log(`Written to ${path.relative(process.cwd(), options.out) || options.out}/`);
}

/* `dom-ops.mjs` imports resolveChromePath from here, so only run as an entry. */
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
