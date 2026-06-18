# Bundle size reduction analysis

Date: 2026-06-18.

## Baseline constraints

- The repository has no configured Git remote, so `git fetch origin main` failed with `fatal: 'origin' does not appear to be a git repository`. This analysis is therefore based on the checked-out `work` branch at commit `ffe27da` rather than a freshly fetched `origin/main`.
- The installed dependencies were missing. `npm run res:build` failed because the `rescript` binary was not available, and `npm install` failed with a registry `403` while fetching `npm-11.17.0.tgz`. As a result, this report focuses on static API/code analysis and package entry-point review instead of measured Rollup chunk output.

## High-confidence reduction opportunities

### 1. Stop shipping the aggregated legacy entry by default

`src/index.mjs` re-exports every public module into one library entry, including routing, SSR, hydration, MDX, JSX runtime support, and signal shims. Vite uses that file as the only library entry, so the generated `dist/xote.*` artifacts are inherently all-inclusive even though `package.json` also exposes per-module subpath exports.

Recommendation:

- Keep subpath exports as the primary supported import style.
- Consider removing the root `.` export in a breaking release, or replacing it with a deliberately tiny client-only entry.
- If root import compatibility is required, build multiple explicit library entries so consumers and CDN users can choose `xote/view`, `xote/router`, `xote/ssr`, etc. without downloading the full stack.

Expected impact: very high for users importing from `xote`, because it avoids pulling unrelated SSR, hydration, MDX, and router code into the root bundle.

### 2. Remove duplicated `Node`/`View` public surfaces

`src/View.res` contains the implementation, while `src/Node.res` is just `include View`. Both `./view` and `./node` are exported, documented, and treated as public API names. This keeps a compatibility alias but doubles the number of module entry points and encourages carrying deprecated `Node.*` examples forward.

Recommendation:

- Pick `View` as the canonical public module.
- Deprecate `Node` in docs now and remove `./node` plus `src/Node.res` in the next breaking release.
- In the interim, avoid exporting both `Node` and `View` from the root aggregate.

Expected impact: low-to-medium in bytes, high in API simplification. It also improves tree-shaking clarity because there is one canonical UI primitive module.

### 3. Split optional SSR and hydration features out of the core package entry

`SSR.res`, `SSRState.res`, and `Hydration.res` are substantial compared with most modules and are not needed by purely client-rendered applications. They are already subpath exports, but the aggregate entry imports all of them.

Recommendation:

- Treat SSR/hydration as opt-in subpaths only.
- Build and document a client entry containing `View`, `Html`, `XoteJSX`, `Prop`, and the signal shims, with router as a separate optional entry.
- In a breaking release, remove SSR/hydration from the root entry entirely.

Expected impact: high for client-only users of the root entry.

### 4. Make MDX integration optional or move it to a separate package

`Mdx.res` is included in `rescript.json`, exported from `package.json`, and re-exported from the root aggregate. The MDX example uses it, but it is not part of the core rendering/runtime path.

Recommendation:

- Move MDX support behind an optional subpath-only entry, or to `@xote/mdx`.
- Remove `Mdx` from the root aggregate.
- Consider excluding MDX from `sources.public` if the public ReScript API should remain minimal.

Expected impact: medium for root import users; also removes an experimental integration from the stable core API surface.

### 5. Audit JSX convenience components added to `View`

`View.res` now includes JSX-oriented modules such as `For`, `KeyedFor`, `Show`, `Maybe`, `Value`, and scalar child components (`Text`, `Int`, `Float`, `Bool`). These are ergonomic but overlap with the function API (`each`, `keyedList`, `signalText`, `text`, etc.). The README states the older function names remain supported, so both layers are public.

Recommendation:

- Keep only one canonical list API: either `For` with optional `by`, or separate `For`/`KeyedFor`, not both.
- Consider making scalar JSX components the only preferred JSX path and marking `signalText`/`signalInt`/`signalFloat` as legacy aliases.
- If backwards compatibility permits, remove deprecated function aliases (`list`, `keyedList`, `computedText`, etc.) after a deprecation period.

Expected impact: medium in `View` module size and public API complexity.

### 6. Reduce `Html.res` to either a generated full tag set or no tag helpers

`Html.res` currently provides a small curated set of element helpers (`div`, `span`, `button`, `input`, `h1`, `h2`, `h3`, `p`, `ul`, `li`, `a`) while all other tags require `View.element` or JSX. This partial abstraction is convenient but redundant with JSX lowercase tags and `View.element`.

Recommendation:

- For smallest core, deprecate `Html` and prefer JSX or `View.element`.
- Alternatively, generate the helper module so users do not need bespoke additions, but keep it out of the root aggregate.

Expected impact: low in bytes, medium in API cleanup.

## Medium-confidence internal cleanup opportunities

### 7. Collapse duplicate boolean/SVG/HTML metadata tables if measured output confirms duplication

Boolean attribute names live in `RuntimeAttr.res`, void element names live in `RuntimeHtml.res`, and SVG tag names live in `RuntimeDom.res`. They serve different call sites, but the metadata table pattern is a place to check for avoidable duplication after a measured build is available.

Recommendation:

- Measure minified output first.
- If the tables are visible in multiple chunks or bundles, consider sharing a compact representation or moving rarely used SVG detection behind JSX/SVG-specific entry points.

Expected impact: low-to-medium.

### 8. Revisit router scroll restoration in the core router entry

`Router.res` includes route matching, link rendering, base path handling, history integration, scroll restoration, hash scrolling, and a JSX `Link` component. Not every user needs scroll restoration or JSX link helpers.

Recommendation:

- Keep route matching in `Route.res`.
- Consider a smaller navigation-only router plus an optional scroll restoration helper if measured size warrants it.
- Alternatively, make scroll restoration configurable so dead-code elimination can drop it from a separate entry.

Expected impact: medium if users import router but do not need the full browser behavior.

## Measurement plan once dependencies/remotes are available

1. Fetch the true baseline: `git fetch origin main && git checkout -B bundle-size-audit origin/main`.
2. Install reproducibly: `npm ci`.
3. Compile and build: `npm run res:build && npm run build`.
4. Record bytes and gzip/brotli sizes for `dist/xote.mjs`, `dist/xote.cjs`, and `dist/xote.umd.js`.
5. Build subpath entry probes for common use cases:
   - View-only client render.
   - JSX-only client render.
   - Router app.
   - SSR render-only.
   - Hydration app.
   - MDX app.
6. Compare bundle output after each removal/deprecation candidate, not only source line counts.

## Suggested breaking-release roadmap

1. Patch/minor release: document `View` and subpath imports as preferred; document `Node`, root aggregate, and older aliases as compatibility APIs.
2. Minor release: add smaller explicit entries (`./client`, `./ssr`, `./hydration`, `./router`) and update docs/examples.
3. Major release: remove root aggregate or make it minimal; remove `Node` alias; remove MDX from core/root; remove deprecated duplicate aliases after migration notes.
