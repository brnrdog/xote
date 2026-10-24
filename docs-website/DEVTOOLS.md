# Testing the devtools on this site

The docs site is a real Xote app (SSR, hydration, routing, keyed lists, resources, effects), so it doubles as a local test bed for `Xote.Devtools`, the in-page panel and `xote-lens`. Nothing here ships: the panel is injected only by the dev server when asked, and the production build never references it.

## 1. Link the debug hooks

The reactive graph comes from `Signals.Debug`, which is not in a `rescript-signals` release yet. Check out the branch that has it next to this repository:

```sh
git clone -b brnrdog/nice-pascal-9c7ixn https://github.com/brnrdog/rescript-signals
#   ./rescript-signals
#   ./xote
```

Then, from `xote/docs-website`:

```sh
npm install                 # once, for the root package and this site
(cd .. && npm install)
npm run devtools:link       # or RESCRIPT_SIGNALS=/path/to/rescript-signals npm run devtools:link
```

`devtools:link` symlinks the checkout into both `node_modules` (no change to `package.json` or any lockfile), then rebuilds Xote and the site. A plain `npm install` in either directory puts the published release back. Building needs `ocamlopt` for the ppx, as always for this site.

Without the link everything still runs, but only scopes, DOM writes, keyed passes and hydration are visible, and the panel and `xote-lens` say the graph is not visible.

## 2. The panel, in the running site

```sh
npm run dev:devtools        # http://localhost:4242
```

This is `npm run dev` with `XOTE_DEVTOOLS=1`. The dev server injects `src/devtools.js` ahead of the app. It installs devtools before the site creates its first signal and mounts the panel after hydration. Open the **◎ xote** launcher at the bottom right, or press **Ctrl+Shift+X**.

Pages worth poking at:

| Page | What to try |
|---|---|
| `/docs/core-concepts/signals` | The counter demo: click and watch Timeline; pick the number with ⌖ and read why it changed |
| `/docs/view/overview` | The todo list: add and delete rows, then see Scopes (row created and released) and the keyed passes |
| `/docs/core-concepts/computed` | The order summary: a chain of computeds; select one in Graph to see its sources and observers |
| `/docs/core-concepts/effects` | The auto-save effect: effect runs, cleanups and the timer |
| Any page | Navigate around: router passes, scopes released per page, and Issues for leaks |

`window.xoteDevtools` is the `Devtools` module, for the browser console: `xoteDevtools.snapshot()`, `xoteDevtools.why(12)`, `xoteDevtools.leaks()`.

## 3. xote-lens, against the site's components

`npm run lens -- <command>` runs the CLI from `../lens` with this site as the project. The demos in `src/demos` render on their own; the pages themselves import `.mdx`, which Node cannot load, so drive the demos:

```sh
npm run lens -- render CounterDemo --act "click .counter-demo-btn:last-child" --why ".counter-demo-value"
npm run lens -- render TodoListDemo --act "input .todo-demo-input Ship it" --act "click .demo-btn-primary" --act "click .todo-demo-delete-btn"
npm run lens -- render ComputedOrderDemo --graph
npm run lens -- render EffectAutosaveDemo --act "input #effect-autosave-input hello" --settle 1200
npm run lens -- render TodoListDemo --hydrate --markers
npm run lens -- check                    # build, then compiler + ppx site map + %raw findings
npm run lens -- expand CounterDemo       # what @xote.component did, line by line
npm run lens -- api View.tracked
```

`TutorialDemos` holds several demos as nested modules: render one with `TutorialDemos.<Module>` (the error message lists them). Add `--json` to any command to see what an agent gets.

The ppx runs with `-sitemap` here, so `check` and `expand` have its site map (`lib/xote-sitemap/`). It is a side output only; the emitted JavaScript is unchanged.

## 4. As an agent would

To let Claude Code drive the site through the MCP server, add this to `.mcp.json` at the repository root:

```json
{
  "mcpServers": {
    "xote-lens": {
      "command": "node",
      "args": ["lens/bin/xote-lens.mjs", "mcp", "--root", "docs-website"]
    }
  }
}
```

Then ask it to, say, render `TodoListDemo`, add a row, and explain which scopes changed.
