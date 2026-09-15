# AGENTS.md

This repository holds two packages and the things that measure and document
them. **The guidance you want is almost certainly in a package, not here.**

```
packages/xote/          the library — ReScript, fine-grained reactivity, SSR
packages/xote-native/   rendering Xote to native mobile views (iOS, Android)
benchmarks/             a keyed-list benchmark against React, Vue and SolidJS
docs-website/           the documentation site
docs/                   CHANGELOG and the technical overview
```

| If you are working on | Read |
|---|---|
| The library itself — architecture, the reactivity model, module APIs, patterns | [`packages/xote/AGENTS.md`](./packages/xote/AGENTS.md) |
| Native rendering, the bridge protocol, the iOS or Android host | [`packages/xote-native/README.md`](./packages/xote-native/README.md), and [`REPORT.md`](./packages/xote-native/REPORT.md) for why it is shaped the way it is |
| Benchmarks | [`benchmarks/README.md`](./benchmarks/README.md) |

## Workspaces

The root is an npm workspaces root and is not itself publishable. `npm install`
at the root installs both packages and links `node_modules/xote` and
`node_modules/xote-native` at them, which is how `xote-native` resolves `xote` —
by package name, exactly as a downstream consumer would.

`benchmarks/` is deliberately **not** a workspace. Its lockfile isolates React,
Vue, Solid and Playwright from the library's own install, so it keeps its own
`npm --prefix benchmarks install` and depends on `xote` through
`file:../packages/xote`.

Every script has a delegating alias at the root, so a command reads the same
from anywhere:

```sh
npm run res:build      # → npm -w xote run res:build
npm test               # → npm -w xote test
npm run native:test    # → npm -w xote-native test
```

Run a package's own scripts with `npm -w xote …` / `npm -w xote-native …`, or
from inside the package directory.

## Conventions that apply everywhere

- **Comments explain *why*, never *what*.** A comment that restates the code is
  noise; one that records a decision, a constraint or a trap is the reason the
  next person does not repeat a day of work. The code in both packages is
  written to that standard — match it.
- **Tests assert behaviour, not implementation.** Where something cannot be
  tested directly — Swift and Kotlin have no toolchain here — there is a static
  check that reads the source as text. See
  `packages/xote-native/test/surface_test.mjs`.
- **Public API is defined by `.resi` files** in `packages/xote/src/`, and
  `npm run test:exports` and `npm run test:boundary` are what keep it honest.
