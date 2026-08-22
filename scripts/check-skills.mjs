#!/usr/bin/env node
/*
 * Guardrail for the agent skills shipped in `plugins/`.
 *
 * The skills document the public API from outside the compiler, so nothing
 * would otherwise notice when a `.resi` renames or drops a value they teach.
 * This checks three things:
 *
 *   1. every SKILL.md has the frontmatter Claude Code needs, and only keys it
 *      accepts;
 *   2. every reference file a SKILL.md points at exists;
 *   3. every `Module.name` the skills mention, for a public Xote module, is
 *      declared in that module's interface file.
 *
 * (3) is the one that catches drift: the skills are the only consumer-facing
 * docs that name the API this densely, and a stale one teaches an agent to
 * write code that no longer compiles.
 */

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const pluginsDir = join(root, "plugins");
const srcDir = join(root, "src");

const errors = [];
const fail = (file, message) => errors.push(`${relative(root, file)}: ${message}`);

/* Frontmatter keys Claude Code accepts in a SKILL.md. An unexpected key is a
   load-time error there, so it has to be a failure here. */
const ALLOWED_KEYS = new Set([
  "name",
  "description",
  "when_to_use",
  "disable-model-invocation",
  "allowed-tools",
  "disallowed-tools",
  "context",
  "paths",
  "tags",
  "metadata",
  "license",
  "compatibility",
]);

/* `description` and `when_to_use` share a 1536-character budget in the skill
   listing; leave room rather than getting truncated mid-sentence. */
const DESCRIPTION_BUDGET = 1200;
const SKILL_BODY_MAX_LINES = 500;

const walk = dir =>
  readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });

/* ------------------------------------------------------ public API surface */

/* module name -> set of names its .resi declares */
const publicApi = new Map();
for (const file of readdirSync(srcDir).filter(f => f.endsWith(".resi"))) {
  const module = file.slice(0, -".resi".length);
  const source = readFileSync(join(srcDir, file), "utf8");
  const names = new Set();
  const declaration = /^\s*(?:let|external|module|and|type(?:\s+rec)?)\s+([A-Za-z_][A-Za-z0-9_']*)/gm;
  for (const match of source.matchAll(declaration)) {
    names.add(match[1]);
  }
  publicApi.set(module, names);
}

if (publicApi.size === 0) {
  fail(srcDir, "no .resi interface files found - is the checkout complete?");
}

/* Names that read like `Module.value` but are not: JS/ReScript stdlib and the
   package's own JS entry points. Only modules in `publicApi` are checked, so
   this list stays short. */
const IGNORED_REFERENCES = new Set([
  "Signal.t<'a>", // generic spelling, handled by stripping type args below
]);

/* ------------------------------------------------------------ skill checks */

const skillFiles = existsSync(pluginsDir)
  ? walk(pluginsDir).filter(f => f.endsWith("SKILL.md"))
  : [];

if (skillFiles.length === 0) {
  fail(pluginsDir, "no SKILL.md files found");
}

for (const file of skillFiles) {
  const raw = readFileSync(file, "utf8");
  const frontmatter = raw.match(/^---\n([\s\S]*?)\n---\n/);

  if (!frontmatter) {
    fail(file, "missing YAML frontmatter");
    continue;
  }

  /* Frontmatter here is flat `key: value` with folded multi-line values; a
     YAML parser would be overkill for what Claude Code itself accepts. */
  const fields = new Map();
  let current = null;
  for (const line of frontmatter[1].split("\n")) {
    const start = line.match(/^([A-Za-z_][A-Za-z0-9_-]*):\s?(.*)$/);
    if (start) {
      current = start[1];
      fields.set(current, start[2]);
    } else if (current && line.trim()) {
      fields.set(current, `${fields.get(current)} ${line.trim()}`);
    }
  }

  for (const key of fields.keys()) {
    if (!ALLOWED_KEYS.has(key)) {
      fail(file, `unexpected frontmatter key '${key}'`);
    }
  }

  const name = fields.get("name");
  const directory = dirname(file).split("/").pop();
  if (!name) {
    fail(file, "frontmatter is missing 'name'");
  } else if (name !== directory) {
    fail(file, `frontmatter name '${name}' does not match directory '${directory}'`);
  }

  const description = fields.get("description");
  if (!description) {
    fail(file, "frontmatter is missing 'description' - it is how Claude decides to load the skill");
  } else {
    const budget = description.length + (fields.get("when_to_use")?.length ?? 0);
    if (budget > DESCRIPTION_BUDGET) {
      fail(file, `description (+ when_to_use) is ${budget} characters; keep it under ${DESCRIPTION_BUDGET}`);
    }
  }

  const body = raw.slice(frontmatter[0].length);
  const lines = body.split("\n").length;
  if (lines > SKILL_BODY_MAX_LINES) {
    fail(file, `body is ${lines} lines; move detail into references/ (limit ${SKILL_BODY_MAX_LINES})`);
  }

  /* Referenced files must exist - a broken pointer costs an agent a tool call
     and then silently degrades the answer. */
  for (const match of body.matchAll(/`(references\/[A-Za-z0-9._/-]+\.md)`/g)) {
    const target = join(dirname(file), match[1]);
    if (!existsSync(target)) {
      fail(file, `points at '${match[1]}', which does not exist`);
    }
  }
}

/* -------------------------------------------------- API references in prose */

const skillDocs = existsSync(pluginsDir)
  ? walk(pluginsDir).filter(f => f.endsWith(".md"))
  : [];

for (const file of skillDocs) {
  const text = readFileSync(file, "utf8");
  const seen = new Set();

  for (const match of text.matchAll(/\b([A-Z][A-Za-z0-9]*)\.([a-zA-Z_][A-Za-z0-9_']*)/g)) {
    const [reference, module, member] = match;
    if (!publicApi.has(module)) continue;
    if (seen.has(reference) || IGNORED_REFERENCES.has(reference)) continue;
    seen.add(reference);

    if (!publicApi.get(module).has(member)) {
      fail(file, `references '${reference}', which ${module}.resi does not declare`);
    }
  }
}

/* ------------------------------------------------------ plugin/marketplace */

const readJson = file => {
  try {
    return JSON.parse(readFileSync(file, "utf8"));
  } catch (error) {
    fail(file, `is not valid JSON: ${error.message}`);
    return null;
  }
};

const marketplaceFile = join(root, ".claude-plugin", "marketplace.json");
if (!existsSync(marketplaceFile)) {
  fail(marketplaceFile, "is missing");
} else {
  const marketplace = readJson(marketplaceFile);
  if (marketplace) {
    if (!marketplace.name) fail(marketplaceFile, "is missing 'name'");
    if (!marketplace.owner?.name) fail(marketplaceFile, "is missing 'owner.name'");

    for (const entry of marketplace.plugins ?? []) {
      const source = typeof entry.source === "string" ? entry.source : null;
      if (!entry.name || !source) {
        fail(marketplaceFile, `plugin entry ${JSON.stringify(entry)} needs 'name' and a string 'source'`);
        continue;
      }
      if (source.startsWith("../")) {
        fail(marketplaceFile, `plugin '${entry.name}' points outside the marketplace root`);
        continue;
      }

      const pluginDir = join(root, source);
      const manifest = join(pluginDir, ".claude-plugin", "plugin.json");
      if (!existsSync(pluginDir) || !statSync(pluginDir).isDirectory()) {
        fail(marketplaceFile, `plugin '${entry.name}' points at '${source}', which does not exist`);
      } else if (!existsSync(manifest)) {
        fail(manifest, `is missing (required by plugin '${entry.name}')`);
      } else {
        const plugin = readJson(manifest);
        if (plugin && plugin.name !== entry.name) {
          fail(manifest, `declares name '${plugin.name}' but the marketplace lists '${entry.name}'`);
        }
      }
    }
  }
}

/* ----------------------------------------------------------------- results */

if (errors.length > 0) {
  console.error("Skill checks failed:\n");
  for (const error of errors) console.error(`  ${error}`);
  console.error(`\n${errors.length} problem(s).`);
  process.exit(1);
}

console.log(`Skill checks passed (${skillFiles.length} skills, ${skillDocs.length} documents).`);
