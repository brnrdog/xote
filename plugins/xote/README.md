# xote plugin for Claude Code

Agent skills for building applications **with** xote. They teach the parts of
the library that a type checker cannot enforce — chiefly that reactivity
follows the expression written in JSX position, so an eagerly-read value
compiles cleanly and then never updates.

| Skill | What it does |
|---|---|
| `xote` | Writing and editing xote code: the reactivity model, `@xote.component`, control flow, lists, attributes, routing, SSR, and the full public API. Loads automatically when a task touches xote. |
| `xote-review` | Audits a diff for the reactivity defects that compile: one-shot reads, unthunked component props, unkeyed lists, oversized tracked blocks, unowned effects, hydration mismatches. |

The `xote` skill keeps its detail in `skills/xote/references/`, loaded only when
a task needs it, so having the skill installed costs a couple of hundred tokens
until it is actually used.

## Install as a plugin

```
/plugin marketplace add brnrdog/xote
/plugin install xote@xote
```

Then `/xote:xote` and `/xote:xote-review` invoke the skills directly; Claude
also loads them on its own when a task touches xote code.

## Install from the npm package

The skills ship inside the `xote` package, so a project that depends on xote
already has them on disk. Link the one you want into the project's skills
directory:

```bash
mkdir -p .claude/skills
ln -s ../../node_modules/xote/plugins/xote/skills/xote .claude/skills/xote
ln -s ../../node_modules/xote/plugins/xote/skills/xote-review .claude/skills/xote-review
```

They then invoke as `/xote` and `/xote-review`. A symlink tracks the installed
version, so upgrading xote upgrades the skills; copy the directories instead if
you would rather pin them and review the diff on upgrade.

## For contributors

These files are checked by `npm run test:skills`, which runs as part of
`npm test`. It validates the frontmatter and the manifests, and — the part that
matters — asserts that every `Module.value` the skills mention is declared in
the matching `.resi` interface file. Change the public API and the skills fail
with the rest of the suite, rather than quietly teaching an API that no longer
exists.

Keep prose accurate to the interfaces, keep each `SKILL.md` short enough to be
worth loading, and put anything long in `references/`.
