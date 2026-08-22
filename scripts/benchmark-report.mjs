/*
 * Renders the benchmark comparison posted on pull requests.
 *
 * Consumes the JSON written by `benchmarks/driver.mjs` and `benchmarks/dom-ops.mjs`.
 * Both builds under comparison run inside a single driver invocation as two
 * apps (`xote` for the PR, `xote-base` for the merge base), so they share one
 * browser, one machine and one interleaved schedule.
 *
 * Timings on a shared CI runner are noisy, so a row is only called out when the
 * change clears the run-to-run spread — see `classify` below. The DOM operation
 * counts are deterministic and need no such hedging.
 */

import { appendFile, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

/* A change must clear the combined spread and this relative floor to count. */
const RELATIVE_THRESHOLD = 0.05;

function parseArgs(args) {
  const options = {
    resultsPath: "benchmarks/results/results.json",
    domOpsPath: null,
    reportPath: "benchmark-report.md",
    current: "xote",
    baseline: "xote-base",
    baselineLabel: "main",
    currentLabel: "PR",
  };

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    const [flag, inlineValue] = arg.split("=", 2);
    const value = inlineValue ?? args[index + 1];

    if (inlineValue === undefined && flag.startsWith("--")) {
      index += 1;
    }

    switch (flag) {
      case "--results":
        options.resultsPath = value;
        break;
      case "--dom-ops":
        options.domOpsPath = value;
        break;
      case "--markdown":
        options.reportPath = value;
        break;
      case "--current":
        options.current = value;
        break;
      case "--baseline":
        options.baseline = value;
        break;
      case "--baseline-label":
        options.baselineLabel = value;
        break;
      case "--current-label":
        options.currentLabel = value;
        break;
      default:
        throw new Error(`Unknown option: ${flag}`);
    }
  }

  return options;
}

async function readJson(filePath) {
  return JSON.parse(await readFile(path.resolve(filePath), "utf-8"));
}

const ms = (value) => `${value.toFixed(1)} ms`;
const kib = (bytes) => `${(bytes / 1024).toFixed(2)} KiB`;
const mib = (bytes) => `${(bytes / 1024 / 1024).toFixed(1)} MiB`;

function formatSignedPercent(ratio) {
  const percent = ratio * 100;
  const sign = percent > 0 ? "+" : "";
  return `${sign}${percent.toFixed(1)}%`;
}

/*
 * A regression is only reported when the median moved further than the two
 * runs' own scatter — a slower-by-2ms row whose samples already vary by 5ms
 * says nothing. `spread` carries the stdev when the caller has one.
 */
function classify(base, head, spread = 0) {
  const delta = head - base;
  const ratio = base === 0 ? 0 : delta / base;
  const beyondNoise = Math.abs(delta) > spread && Math.abs(ratio) >= RELATIVE_THRESHOLD;

  return { delta, ratio, significant: beyondNoise };
}

/*
 * `≈` marks a delta the run cannot distinguish from noise. The percentage is
 * still shown so nothing is hidden, but it carries no claim.
 */
function deltaCell(base, head, spread = 0) {
  if (base === undefined || base === null) return "new";

  const { ratio, significant } = classify(base, head, spread);

  if (!significant) return `≈ ${formatSignedPercent(ratio)}`;

  return `${ratio > 0 ? "⚠️" : "✅"} ${formatSignedPercent(ratio)}`;
}

function renderOperations({ results, benchmarks, current, baseline }) {
  return benchmarks.map((benchmark) => {
    const head = results[current][benchmark.id].commit;

    if (!baseline) return `| ${benchmark.name} | ${ms(head.median)} |`;

    const base = results[baseline][benchmark.id].commit;
    const spread = base.stdev + head.stdev;

    return `| ${benchmark.name} | ${ms(base.median)} | ${ms(head.median)} | ${deltaCell(
      base.median,
      head.median,
      spread,
    )} |`;
  });
}

function renderDomOps({ domOps, current, baseline, baselineLabel, currentLabel }) {
  if (!domOps) return [];

  const lines = [
    "",
    "### DOM operations",
    "",
    "Counts are deterministic, so any change here is real.",
    "",
    baseline
      ? `| Operation | ${baselineLabel} | ${currentLabel} | Δ |`
      : `| Operation | DOM calls |`,
    baseline ? "| --- | ---: | ---: | ---: |" : "| --- | ---: |",
  ];

  const total = (ops) => Object.values(ops ?? {}).reduce((sum, count) => sum + count, 0);

  for (const [operation, perApp] of Object.entries(domOps.operations)) {
    const head = total(perApp[current]);

    if (!baseline || perApp[baseline] === undefined) {
      lines.push(`| ${operation} | ${head} |`);
      continue;
    }

    const base = total(perApp[baseline]);
    const delta = head - base;
    const marker = delta === 0 ? "0" : `${delta > 0 ? "⚠️ +" : "✅ "}${delta}`;
    lines.push(`| ${operation} | ${base} | ${head} | ${marker} |`);
  }

  return lines;
}

function renderSecondary({ report, current, baseline, baselineLabel, currentLabel }) {
  const lines = [
    "",
    "### Startup, payload and memory",
    "",
    baseline ? `| Metric | ${baselineLabel} | ${currentLabel} | Δ |` : `| Metric | ${currentLabel} |`,
    baseline ? "| --- | ---: | ---: | ---: |" : "| --- | ---: |",
  ];

  const row = (name, headValue, baseValue, format, spread = 0) => {
    if (!baseline) {
      lines.push(`| ${name} | ${format(headValue)} |`);
      return;
    }
    lines.push(
      `| ${name} | ${format(baseValue)} | ${format(headValue)} | ${deltaCell(
        baseValue,
        headValue,
        spread,
      )} |`,
    );
  };

  const headStartup = report.startup[current];
  const baseStartup = baseline ? report.startup[baseline] : null;
  row(
    "Time to first render",
    headStartup.median,
    baseStartup?.median,
    ms,
    baseStartup ? baseStartup.stdev + headStartup.stdev : 0,
  );

  row(
    "App bundle (gzip)",
    report.payload[current].js.gzip,
    baseline ? report.payload[baseline].js.gzip : undefined,
    kib,
  );

  row(
    "Heap at 10,000 rows",
    report.memory[current].rows10k,
    baseline ? report.memory[baseline].rows10k : undefined,
    mib,
  );

  row(
    "Heap after clearing",
    report.memory[current].cleared,
    baseline ? report.memory[baseline].cleared : undefined,
    mib,
  );

  return lines;
}

function renderReport({ report, domOps, options }) {
  const { current, baselineLabel, currentLabel } = options;
  const baseline = report.results[options.baseline] ? options.baseline : null;

  const lines = ["## Benchmark", ""];

  if (baseline) {
    lines.push(
      `The keyed-list benchmark built from this PR against the same benchmark built from \`${baselineLabel}\`, both run in one interleaved Chromium session.`,
    );
  } else {
    lines.push(
      `No \`${baselineLabel}\` baseline was available, so these are the ${currentLabel} numbers on their own.`,
    );
  }

  lines.push("");
  lines.push("### Operations (commit time, median)");
  lines.push("");
  lines.push(
    baseline
      ? `| Operation | ${baselineLabel} | ${currentLabel} | Δ |`
      : `| Operation | ${currentLabel} |`,
  );
  lines.push(baseline ? "| --- | ---: | ---: | ---: |" : "| --- | ---: |");
  lines.push(
    ...renderOperations({
      results: report.results,
      benchmarks: report.benchmarks,
      current,
      baseline,
    }),
  );

  lines.push(...renderDomOps({ domOps, current, baseline, baselineLabel, currentLabel }));
  lines.push(...renderSecondary({ report, current, baseline, baselineLabel, currentLabel }));

  lines.push("");
  lines.push(
    `${report.options.iterations} measured iterations per operation (${report.options.warmup} warmup) on ${report.environment.cpus} vCPU, Chromium ${report.environment.chromium}.`,
  );

  if (baseline) {
    lines.push("");
    lines.push(
      `Only Xote differs between the two columns — React, Vue and SolidJS are pinned dependencies and are not re-run here. A timing change is flagged (⚠️/✅) only when it exceeds both the two runs' combined standard deviation and ${(
        RELATIVE_THRESHOLD * 100
      ).toFixed(0)}%; anything smaller is within CI noise. Cross-framework numbers live in \`benchmarks/results/RESULTS.md\`.`,
    );
  }

  const commit = process.env.GITHUB_SHA ? process.env.GITHUB_SHA.slice(0, 7) : null;

  if (commit) {
    lines.push("", `Commit: \`${commit}\``);
  }

  lines.push("");
  return lines.join("\n");
}

const options = parseArgs(process.argv.slice(2));
const report = await readJson(options.resultsPath);
const domOps = options.domOpsPath ? await readJson(options.domOpsPath) : null;

if (!report.results[options.current]) {
  throw new Error(`No results for app "${options.current}" in ${options.resultsPath}`);
}

const markdown = renderReport({ report, domOps, options });

await writeFile(path.resolve(options.reportPath), markdown);

if (process.env.GITHUB_STEP_SUMMARY) {
  await appendFile(process.env.GITHUB_STEP_SUMMARY, markdown);
}

console.log(markdown);
