import { appendFile, readdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { brotliCompressSync, gzipSync } from "node:zlib";

const artifactMetadata = {
  "xote.mjs": {
    format: "ESM",
    consumer: "`import` / `module`",
  },
  "xote.cjs": {
    format: "CommonJS",
    consumer: "`require` / `main`",
  },
  "xote.umd.js": {
    format: "UMD",
    consumer: "Browser global",
  },
  "client.mjs": {
    format: "ESM",
    consumer: "`xote/client` import",
  },
  "client.cjs": {
    format: "CommonJS",
    consumer: "`xote/client` require",
  },
  "router.mjs": {
    format: "ESM",
    consumer: "`xote/router` import",
  },
  "router.cjs": {
    format: "CommonJS",
    consumer: "`xote/router` require",
  },
  "ssr.mjs": {
    format: "ESM",
    consumer: "`xote/ssr` import",
  },
  "ssr.cjs": {
    format: "CommonJS",
    consumer: "`xote/ssr` require",
  },
  "hydration.mjs": {
    format: "ESM",
    consumer: "`xote/hydration` import",
  },
  "hydration.cjs": {
    format: "CommonJS",
    consumer: "`xote/hydration` require",
  },
  "mdx.mjs": {
    format: "ESM",
    consumer: "`xote/mdx` import",
  },
  "mdx.cjs": {
    format: "CommonJS",
    consumer: "`xote/mdx` require",
  },
};

function parseArgs(args) {
  const options = {
    distDir: "dist",
    packageJsonPath: "package.json",
    reportPath: "bundle-size-report.md",
    jsonPath: null,
    baselinePath: null,
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
      case "--dist":
        options.distDir = value;
        break;
      case "--package":
        options.packageJsonPath = value;
        break;
      case "--markdown":
        options.reportPath = value;
        break;
      case "--json":
        options.jsonPath = value;
        break;
      case "--baseline":
        options.baselinePath = value;
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

async function listFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    entries.map(async (entry) => {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        return listFiles(fullPath);
      }

      if (entry.isFile()) {
        return [fullPath];
      }

      return [];
    })
  );

  return files.flat();
}

function formatBytes(bytes) {
  if (bytes < 1024) {
    return `${bytes} B`;
  }

  return `${(bytes / 1024).toFixed(2)} KiB`;
}

function formatDelta(bytes) {
  if (bytes === 0) {
    return "0 B";
  }

  const sign = bytes > 0 ? "+" : "-";
  return `${sign}${formatBytes(Math.abs(bytes))}`;
}

function escapeMarkdownCell(value) {
  return value.replaceAll("|", "\\|");
}

function compareArtifacts(left, right) {
  const order = [
    "xote.mjs",
    "xote.cjs",
    "xote.umd.js",
    "client.mjs",
    "client.cjs",
    "router.mjs",
    "router.cjs",
    "ssr.mjs",
    "ssr.cjs",
    "hydration.mjs",
    "hydration.cjs",
    "mdx.mjs",
    "mdx.cjs",
  ];
  const leftIndex = order.indexOf(left.name);
  const rightIndex = order.indexOf(right.name);

  if (leftIndex !== -1 || rightIndex !== -1) {
    return (
      (leftIndex === -1 ? order.length : leftIndex) -
      (rightIndex === -1 ? order.length : rightIndex)
    );
  }

  return left.name.localeCompare(right.name);
}

async function makeSnapshot({ distDir, packageJsonPath }) {
  const resolvedDistDir = path.resolve(distDir);
  const resolvedPackageJsonPath = path.resolve(packageJsonPath);
  const files = (await listFiles(resolvedDistDir)).sort((a, b) => a.localeCompare(b));

  if (files.length === 0) {
    throw new Error(`No files found in ${resolvedDistDir}`);
  }

  const packageJson = JSON.parse(await readFile(resolvedPackageJsonPath, "utf-8"));
  const rows = await Promise.all(
    files.map(async (filePath) => {
      const contents = await readFile(filePath);
      const fileStat = await stat(filePath);
      const name = path.relative(resolvedDistDir, filePath);
      const isPublicArtifact = Object.prototype.hasOwnProperty.call(artifactMetadata, name);
      const metadata = artifactMetadata[name] ?? {
        format: path.extname(name).slice(1).toUpperCase() || "File",
        consumer: "Additional artifact",
      };

      return {
        name,
        isPublicArtifact,
        ...metadata,
        raw: fileStat.size,
        gzip: gzipSync(contents, { level: 9 }).length,
        brotli: brotliCompressSync(contents).length,
      };
    })
  );

  rows.sort(compareArtifacts);

  return {
    packageName: packageJson.name,
    module: packageJson.module ?? null,
    main: packageJson.main ?? null,
    files: rows,
  };
}

function summarizeSharedChunks(files) {
  const sharedChunks = files.filter((row) => !row.isPublicArtifact);

  if (sharedChunks.length === 0) {
    return null;
  }

  return {
    name: `shared chunks (${sharedChunks.length} files)`,
    isPublicArtifact: false,
    format: "Rollup chunks",
    consumer: "Shared internal output",
    raw: sharedChunks.reduce((total, row) => total + row.raw, 0),
    gzip: sharedChunks.reduce((total, row) => total + row.gzip, 0),
    brotli: sharedChunks.reduce((total, row) => total + row.brotli, 0),
  };
}

function getReportRows(snapshot) {
  const publicRows = snapshot.files.filter((row) => row.isPublicArtifact);
  const sharedSummary = summarizeSharedChunks(snapshot.files);
  const rows = sharedSummary ? [...publicRows, sharedSummary] : publicRows;

  return rows.sort(compareArtifacts);
}

function renderCurrentTable(snapshot) {
  const rows = getReportRows(snapshot);

  return [
    "| Artifact | Format | Consumer | Raw | Gzip | Brotli |",
    "| --- | --- | --- | ---: | ---: | ---: |",
    ...rows.map(
      (row) =>
        `| \`${escapeMarkdownCell(row.name)}\` | ${escapeMarkdownCell(row.format)} | ${row.consumer} | ${formatBytes(
          row.raw
        )} | ${formatBytes(row.gzip)} | ${formatBytes(row.brotli)} |`
    ),
  ];
}

function renderComparisonTable({ baseline, current, baselineLabel, currentLabel }) {
  const rowsByName = new Map();

  for (const row of getReportRows(baseline)) {
    rowsByName.set(row.name, { baseline: row, current: null });
  }

  for (const row of getReportRows(current)) {
    const existing = rowsByName.get(row.name) ?? { baseline: null, current: null };
    existing.current = row;
    rowsByName.set(row.name, existing);
  }

  const rows = Array.from(rowsByName.entries())
    .map(([name, values]) => ({
      name,
      format: values.current?.format ?? values.baseline?.format ?? "",
      consumer: values.current?.consumer ?? values.baseline?.consumer ?? "",
      ...values,
    }))
    .sort(compareArtifacts);

  return [
    `| Artifact | Format | Consumer | Raw (${baselineLabel}) | Raw (${currentLabel}) | Δ Raw | Gzip (${baselineLabel}) | Gzip (${currentLabel}) | Δ Gzip | Brotli (${baselineLabel}) | Brotli (${currentLabel}) | Δ Brotli |`,
    "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ...rows.map(({ name, format, consumer, baseline: base, current: head }) => {
      const rawDelta = base && head ? formatDelta(head.raw - base.raw) : head ? "new" : "removed";
      const gzipDelta = base && head ? formatDelta(head.gzip - base.gzip) : head ? "new" : "removed";
      const brotliDelta = base && head ? formatDelta(head.brotli - base.brotli) : head ? "new" : "removed";

      return `| \`${escapeMarkdownCell(name)}\` | ${escapeMarkdownCell(format)} | ${consumer} | ${
        base ? formatBytes(base.raw) : "-"
      } | ${head ? formatBytes(head.raw) : "-"} | ${rawDelta} | ${
        base ? formatBytes(base.gzip) : "-"
      } | ${head ? formatBytes(head.gzip) : "-"} | ${gzipDelta} | ${
        base ? formatBytes(base.brotli) : "-"
      } | ${head ? formatBytes(head.brotli) : "-"} | ${brotliDelta} |`;
    }),
  ];
}

function renderReport({ current, baseline, baselineLabel, currentLabel }) {
  const lines = baseline
    ? ["## Bundle Size", "", ...renderComparisonTable({ baseline, current, baselineLabel, currentLabel })]
    : ["## Bundle Size", "", ...renderCurrentTable(current)];

  const commit = process.env.GITHUB_SHA ? process.env.GITHUB_SHA.slice(0, 7) : null;

  if (commit) {
    lines.push("", `Commit: \`${commit}\``);
  }

  lines.push("");
  return lines.join("\n");
}

const options = parseArgs(process.argv.slice(2));
const current = await makeSnapshot(options);
const baseline = options.baselinePath
  ? JSON.parse(await readFile(path.resolve(options.baselinePath), "utf-8"))
  : null;
const report = renderReport({
  current,
  baseline,
  baselineLabel: options.baselineLabel,
  currentLabel: options.currentLabel,
});

await writeFile(path.resolve(options.reportPath), report);

if (options.jsonPath) {
  await writeFile(path.resolve(options.jsonPath), `${JSON.stringify(current, null, 2)}\n`);
}

if (process.env.GITHUB_STEP_SUMMARY) {
  await appendFile(process.env.GITHUB_STEP_SUMMARY, report);
}

console.log(report);
