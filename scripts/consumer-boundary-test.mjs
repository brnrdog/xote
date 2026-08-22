#!/usr/bin/env node
/**
 * Compiles `tests/consumer` against a staged copy of the publishable package,
 * so the public API boundary is checked the way a downstream app sees it.
 *
 *   allowed/    must compile              - the documented API stays usable
 *   deprecated/ must compile, with a warning - API on its way out still works
 *   forbidden/  must NOT compile          - implementation details are unreachable
 *
 * Run with `npm run test:boundary`.
 */

import { execFileSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const fixtureRoot = join(repoRoot, "tests", "consumer");
const forbiddenDir = join(fixtureRoot, "forbidden");
const deprecatedDir = join(fixtureRoot, "deprecated");
const probeDir = join(fixtureRoot, "probe");
const rescriptBin = join(repoRoot, "node_modules", ".bin", "rescript");

/* `files` from the root package.json, minus `dist` - the fixture builds from
   source rather than from the bundled output. */
const PUBLISHED = ["src", "rescript.json", "package.json"];

/* Dependencies the staged package and the fixture both resolve against. */
const LINKED_DEPS = ["rescript", "rescript-signals"];

const green = (s) => `[32m${s}[0m`;
const red = (s) => `[31m${s}[0m`;
const dim = (s) => `[2m${s}[0m`;

function stagePackage() {
  const staging = mkdtempSync(join(tmpdir(), "xote-boundary-"));
  const pkgDir = join(staging, "node_modules", "xote");
  mkdirSync(pkgDir, { recursive: true });

  for (const entry of PUBLISHED) {
    cpSync(join(repoRoot, entry), join(pkgDir, entry), {
      recursive: true,
      /* Compiled output and lockfiles are not part of the published surface. */
      filter: (src) => !src.includes(`${"/"}lib${"/"}`) && !src.endsWith("/lib"),
    });
  }

  for (const dep of LINKED_DEPS) {
    const target = join(repoRoot, "node_modules", dep);
    if (!existsSync(target)) {
      throw new Error(`missing dependency ${dep} - run npm install first`);
    }
    const linkPath = join(staging, "node_modules", dep);
    mkdirSync(dirname(linkPath), { recursive: true });
    symlinkSync(target, linkPath);
  }

  return staging;
}

/**
 * Builds the fixture inside `staging`. The fixture is copied in rather than
 * built in place so the repo's own `lib/` is never touched.
 */
function build(staging) {
  const workDir = join(staging, "fixture");
  rmSync(workDir, { recursive: true, force: true });
  cpSync(fixtureRoot, workDir, { recursive: true });
  mkdirSync(join(workDir, "probe"), { recursive: true });
  symlinkSync(join(staging, "node_modules"), join(workDir, "node_modules"));

  try {
    const stdout = execFileSync(rescriptBin, ["build"], {
      cwd: workDir,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { ok: true, output: stdout };
  } catch (error) {
    return { ok: false, output: `${error.stdout ?? ""}${error.stderr ?? ""}` };
  }
}

function expectedSymbol(source, marker) {
  const match = source.match(new RegExp(`${marker}:\\s*(\\S+)`));
  if (!match) {
    throw new Error(`fixture is missing an \`${marker}:\` marker`);
  }
  return match[1];
}

/* Returns the number of failed probes. */
function runProbes(staging) {
  let failures = 0;

  rmSync(probeDir, { recursive: true, force: true });
  mkdirSync(probeDir, { recursive: true });

  process.stdout.write("\n[1mConsumer boundary[0m\n");
  process.stdout.write(dim("------------------\n"));

  /* The baseline gates everything else. If the fixture cannot build at all -
     a missing dependency, a broken staged package - every probe below fails for
     that one reason, and 18 red lines about the API boundary would be a lie. */
  const baseline = build(staging);
  if (!baseline.ok) {
    process.stdout.write(`   ${red("✗")} documented API compiles from a consumer package\n`);
    process.stdout.write(`${baseline.output}\n`);
    process.stdout.write(
      `  ${red("the fixture does not build, so no probe below would mean anything")}\n\n`,
    );
    return 1;
  }
  process.stdout.write(`   ${green("✓")} documented API compiles from a consumer package\n`);

  const deprecatedCases = readdirSync(deprecatedDir).filter((f) => f.endsWith(".res")).sort();
  for (const file of deprecatedCases) {
    const source = readFileSync(join(deprecatedDir, file), "utf8");
    const symbol = expectedSymbol(source, "expect-deprecated");

    writeFileSync(join(probeDir, "Probe.res"), source);
    const result = build(staging);
    rmSync(join(probeDir, "Probe.res"), { force: true });

    const name = file.replace(/\.res$/, "");
    if (!result.ok) {
      failures += 1;
      process.stdout.write(`   ${red("✗")} ${name} still compiles\n`);
      process.stdout.write(`     ${red("removing it is a breaking change - it must stay until the next major")}\n`);
      process.stdout.write(`${result.output}\n`);
    } else if (!result.output.includes("deprecated")) {
      failures += 1;
      process.stdout.write(`   ${red("✗")} ${name} still compiles\n`);
      process.stdout.write(`     ${red(`compiled, but ${symbol} never warned it is deprecated`)}\n`);
    } else {
      process.stdout.write(`   ${green("✓")} ${name} still compiles, with a deprecation warning\n`);
    }
  }

  const cases = readdirSync(forbiddenDir).filter((f) => f.endsWith(".res")).sort();
  for (const file of cases) {
    const source = readFileSync(join(forbiddenDir, file), "utf8");
    const symbol = expectedSymbol(source, "expect-error");

    writeFileSync(join(probeDir, "Probe.res"), source);
    const result = build(staging);
    rmSync(join(probeDir, "Probe.res"), { force: true });

    const name = file.replace(/\.res$/, "");
    if (result.ok) {
      failures += 1;
      process.stdout.write(`   ${red("✗")} ${name} is unreachable\n`);
      process.stdout.write(`     ${red(`compiled, but ${symbol} should not be reachable`)}\n`);
    } else if (!result.output.includes(symbol)) {
      failures += 1;
      process.stdout.write(`   ${red("✗")} ${name} is unreachable\n`);
      process.stdout.write(`     ${red(`failed, but the error never mentions ${symbol}`)}\n`);
      process.stdout.write(`${result.output}\n`);
    } else {
      process.stdout.write(`   ${green("✓")} ${name} is unreachable\n`);
    }
  }

  const total = cases.length + deprecatedCases.length + 1;
  const passed = total - failures;
  process.stdout.write(
    `  ${green(`${passed} passed`)}, ${failures > 0 ? red(`${failures} failed`) : "0 failed"}\n\n`,
  );

  return failures;
}

const staging = stagePackage();
let failures = 0;

try {
  failures = runProbes(staging);
} finally {
  rmSync(probeDir, { recursive: true, force: true });
  rmSync(staging, { recursive: true, force: true });
}

process.exit(failures > 0 ? 1 : 0);
