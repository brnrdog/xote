/*
 * Benchmark driver.
 *
 * Serves the built apps over loopback, drives them with Chromium and records
 * per-operation timings, memory and payload size. Every framework runs the
 * same DOM, the same data and the same click sequence, so the only variable
 * is the framework doing the work.
 *
 * Usage:
 *   node driver.mjs [--iterations N] [--warmup N] [--apps xote,react] [--headed]
 */

import { createReadStream } from "node:fs";
import { readdir, readFile, mkdir, writeFile, stat } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { brotliCompressSync, gzipSync } from "node:zlib";
import { chromium } from "playwright-core";

const here = path.dirname(fileURLToPath(import.meta.url));
const distDir = path.join(here, "dist");
const resultsDir = path.join(here, "results");

/* Chromium shipped with the environment; Playwright's own download is skipped. */
const CHROME_PATH =
  process.env.BENCH_CHROME_PATH ??
  "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";

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

async function runBenchmark(browser, url, benchmark, options) {
  const page = await newPage(browser, url);
  const samples = { commit: [], painted: [] };

  try {
    for (let i = 0; i < options.warmup + options.iterations; i++) {
      await page.evaluate(async () => {
        await window.__bench.click("#clear");
      });

      for (const selector of benchmark.setup) {
        await page.evaluate(
          async (sel) => await window.__bench.click(sel),
          selector,
        );
      }

      const result = await page.evaluate(
        async (sel) => await window.__bench.measure(sel),
        benchmark.target,
      );

      assertState(result.state, benchmark.expect, `${benchmark.id}`);

      if (i >= options.warmup) {
        samples.commit.push(result.commit);
        samples.painted.push(result.painted);
      }
    }
  } finally {
    await page.close();
  }

  return {
    commit: summarize(samples.commit),
    painted: summarize(samples.painted),
    samples,
  };
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
  const head = `| Benchmark | ${apps.map((a) => APP_LABELS[a]).join(" | ")} |`;
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
  lines.push(`Framework versions: ${apps.map((a) => `${APP_LABELS[a]} ${report.versions[a]}`).join(", ")}.`);
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
  const options = { iterations: 15, warmup: 3, apps: ALL_APPS, headed: false };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--iterations") options.iterations = Number(argv[++i]);
    else if (arg === "--warmup") options.warmup = Number(argv[++i]);
    else if (arg === "--apps") options.apps = argv[++i].split(",");
    else if (arg === "--headed") options.headed = true;
  }

  return options;
}

async function readVersions(apps) {
  const versions = {};
  const dep = async (name) =>
    JSON.parse(await readFile(path.join(here, "node_modules", name, "package.json"), "utf8"))
      .version;

  for (const app of apps) {
    if (app === "react") versions[app] = await dep("react-dom");
    else if (app === "vue") versions[app] = await dep("vue");
    else if (app === "solid") versions[app] = await dep("solid-js");
    else if (app === "xote") {
      const pkg = JSON.parse(await readFile(path.join(here, "..", "package.json"), "utf8"));
      versions[app] = `${pkg.version} (this checkout)`;
    }
  }

  return versions;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const { server, port } = await startServer(distDir);
  const os = await import("node:os");

  const browser = await chromium.launch({
    executablePath: CHROME_PATH,
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

  try {
    for (const app of options.apps) {
      const url = `http://127.0.0.1:${port}/${app}/index.html`;
      report.results[app] = {};

      for (const benchmark of BENCHMARKS) {
        process.stdout.write(`${app.padEnd(6)} ${benchmark.id.padEnd(16)} `);
        const result = await runBenchmark(browser, url, benchmark, options);
        report.results[app][benchmark.id] = result;
        console.log(
          `commit ${ms(result.commit.median)}ms  painted ${ms(result.painted.median)}ms`,
        );
      }

      process.stdout.write(`${app.padEnd(6)} startup          `);
      report.startup[app] = await measureStartup(browser, url, {
        ...options,
        iterations: Math.min(options.iterations, 8),
        warmup: 1,
      });
      console.log(`${ms(report.startup[app].median)}ms`);

      process.stdout.write(`${app.padEnd(6)} memory           `);
      report.memory[app] = await measureMemory(browser, url);
      console.log(`${kb(report.memory[app].rows1k)}KB @1k rows`);

      report.payload[app] = await measurePayload(app);
    }
  } finally {
    await browser.close();
    server.close();
  }

  await mkdir(resultsDir, { recursive: true });
  await writeFile(
    path.join(resultsDir, "results.json"),
    JSON.stringify(report, null, 2),
  );

  const markdown = renderMarkdown(report);
  await writeFile(path.join(resultsDir, "RESULTS.md"), markdown);

  console.log(`\n${markdown}`);
  console.log(`Written to benchmarks/results/`);
}

await main();
