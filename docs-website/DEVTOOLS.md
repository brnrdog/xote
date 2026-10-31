# Testing the devtools on this site

The docs site is a real Xote app (SSR, hydration, routing, keyed lists, effects), so it doubles as a local test bed for `Xote.Devtools`, the panel and `xote-lens`. Nothing here ships: only the dev server injects the panel, and only when asked.

Run `npm install` here and in the repository root. The reactive graph needs `rescript-signals` 3.2.0 or later; building needs `ocamlopt` for the ppx.

## The panel

```sh
npm run dev:devtools        # http://localhost:4242
```

This is `npm run dev` with `XOTE_DEVTOOLS=1`: the server injects `src/devtools.js`, which installs devtools before the first signal and mounts the panel after hydration. Open the **◎ xote** launcher or press **Ctrl+Shift+X**. In the console, `window.xoteDevtools` is the `Devtools` module.

| Page | What to try |
|---|---|
| `/docs/core-concepts/signals` | Click the counter, watch Timeline, pick the number with ⌖ to see why it changed |
| `/docs/view/overview` | Add and delete todos, then check Scopes and the keyed passes |
| `/docs/core-concepts/computed` | Select a computed in Graph to see its sources and observers |
| `/docs/core-concepts/effects` | Effect runs, cleanups and the timer |

## xote-lens

`npm run lens -- <command>` runs the CLI with this site as the project. Pages import `.mdx`, which Node can't load, so drive the demos in `src/demos`:

```sh
npm run lens -- render CounterDemo --act "click .counter-demo-btn:last-child" --why ".counter-demo-value"
npm run lens -- render TodoListDemo --hydrate --markers
npm run lens -- check
npm run lens -- expand CounterDemo
```

Nested demos render as `TutorialDemos.<Module>`. Add `--json` to see what an agent gets. The ppx runs with `-sitemap` here, so `check` and `expand` have the site map.

To let an agent drive the site, add this to `.mcp.json` at the repository root:

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
