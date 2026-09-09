#!/usr/bin/env node
/**
 * Point this package at the `xote` next door.
 *
 * `xote-native` depends on `xote`, and in a published checkout that is an
 * ordinary `npm install`. In *this* repository the two live side by side — the
 * root directory is the `xote` package — so there is no `node_modules/xote` for
 * ReScript or Node to resolve, and nothing to install.
 *
 * So this makes the link the arrangement implies: `node_modules/xote` pointing
 * at the repository root. It is idempotent, it needs no network, and it is the
 * whole of what "two packages in one repository" costs. Everything else —
 * `rescript`, `rescript-signals`, `@rescript/runtime` — resolves by walking up
 * to the root's own `node_modules`, which is what Node does anyway.
 */

import { existsSync, lstatSync, mkdirSync, readlinkSync, rmSync, symlinkSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(here, "..");
const modules = join(here, "node_modules");
const link = join(modules, "xote");

mkdirSync(modules, { recursive: true });

if (existsSync(link) || lstatSync(link, { throwIfNoEntry: false }) !== undefined) {
  const current = lstatSync(link);
  if (current.isSymbolicLink() && resolve(modules, readlinkSync(link)) === repoRoot) {
    process.exit(0);
  }
  rmSync(link, { recursive: true, force: true });
}

// Relative, so a checkout that is moved or mounted somewhere else still works —
// and relative to the *link's* directory, which is `node_modules`, so it takes
// two steps to get back to the repository root rather than one.
symlinkSync(join("..", ".."), link, "junction");
console.log(`linked ${link} -> ${repoRoot}`);
