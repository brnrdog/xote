# Docs Website Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the docs-website visual layer around an editorial-reference aesthetic — Domine + DM Sans + DM Mono, pure-neutral palette, hairline rules, narrow reading column — and remove all standalone demo routes in favor of an inline-figure demo pattern.

**Architecture:** CSS-first redesign driven by a refreshed token system. ReScript files change only where structure is affected: routes are removed, sidebar/header navigation is pruned, `HomePage` is rewritten around the new hero/features/community blocks, and a new `InlineDemo` component wraps in-prose demos. Existing demo modules under `docs-website/src/demos/` are preserved and re-used as inline figures.

**Tech Stack:** ReScript 12, Xote (internal), Vite, Node SSR, Google Fonts (Domine / DM Sans / DM Mono). The existing Xote API (`Node.*`, `Html.*`, `Signal.*`, `Router.*`) is unchanged.

**Spec:** `docs/superpowers/specs/2026-04-23-docs-website-redesign-design.md`

**Working directory:** `docs-website/` (all file paths in this plan are relative to the repo root).

**Verification rhythm** — most tasks end with:
1. `cd docs-website && npm run res:build` — ensure ReScript compiles.
2. `cd docs-website && npm run dev` — manual visual check in a browser (Chrome/Safari), both `[data-theme="dark"]` and `[data-theme="light"]`.
3. Commit.

Since this work is almost entirely visual, traditional test-driven development doesn't apply cleanly. The verification commands above replace it. Each task should leave the site in a working (if incomplete) state.

---

## Phase 1 — Foundations

### Task 1: Swap Google Fonts and set base meta

**Files:**
- Modify: `docs-website/index.html`

- [ ] **Step 1: Replace the Google Fonts link**

Open `docs-website/index.html`. Replace the current `<link href="https://fonts.googleapis.com/css2?..." rel="stylesheet">` line (around line 26) with:

```html
<link href="https://fonts.googleapis.com/css2?family=Domine:wght@400;500;600;700&family=DM+Sans:ital,opsz,wght@0,9..40,400..700;1,9..40,400..700&family=DM+Mono:ital,wght@0,400;0,500;1,400;1,500&display=swap" rel="stylesheet">
```

Leave the `preconnect` lines above it untouched.

- [ ] **Step 2: Update the theme-color meta**

Replace `<meta name="theme-color" content="#0f1210">` with:

```html
<meta name="theme-color" content="#0a0a0a">
```

- [ ] **Step 3: Update page title**

Replace `<title>Xote - Reactive UI Library for ReScript</title>` with:

```html
<title>Xote — A lightweight UI library for ReScript</title>
```

- [ ] **Step 4: Verify no other typography is loaded**

Check the file does NOT reference Instrument Serif or Geist Mono anywhere. Grep to confirm:

```bash
grep -i "instrument\|geist" docs-website/index.html || echo "clean"
```

Expected output: `clean`.

- [ ] **Step 5: Commit**

```bash
git add docs-website/index.html
git commit -m "docs(website): swap Google Fonts to Domine, DM Sans, DM Mono"
```

---

### Task 2: Rewrite CSS variables / design tokens

**Files:**
- Modify: `docs-website/src/styles.css` — replace everything from the start of the file through the end of the `[data-theme="light"]` block.

- [ ] **Step 1: Replace the token header and dark-mode tokens**

Open `docs-website/src/styles.css`. Identify the block starting at line 1 and ending where `[data-theme="light"] {` closes (around line 131 — look for the `}` immediately before the next comment block). Replace the entire span with the block below.

```css
/* ============================================================
   Xote Documentation — Editorial Reference Design System
   Pure-neutral palette, hairline rules, narrow reading column.
   ============================================================ */

:root {
  /* Surfaces (dark mode default) */
  --bg:          #0a0a0a;
  --surface:     #111111;
  --elevated:    #171717;
  --border:      #242424;
  --border-soft: #1a1a1a;

  /* Text */
  --text:        #f5f5f4;
  --text-muted:  #a3a3a3;
  --text-faint:  #525252;

  /* Functional (monochrome — same as text / inverse of bg) */
  --accent:      #f5f5f4;
  --mark:        #fafaf7;

  /* Typography families */
  --font-display: "Domine", Georgia, serif;
  --font-body:    "DM Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --font-mono:    "DM Mono", "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace;

  /* Type scale */
  --fs-xs:      12px;
  --fs-sm:      14px;
  --fs-base:    16px;
  --fs-lg:      18px;
  --fs-xl:      22px;
  --fs-2xl:     28px;
  --fs-3xl:     40px;
  --fs-4xl:     60px;
  --fs-display: 96px;

  /* Line heights */
  --lh-tight:  1.15;
  --lh-ui:     1.45;
  --lh-prose:  1.65;

  /* Spacing scale (8px base) */
  --s-0:   0px;
  --s-1:   4px;
  --s-2:   8px;
  --s-3:   12px;
  --s-4:   16px;
  --s-5:   24px;
  --s-6:   32px;
  --s-8:   48px;
  --s-10:  64px;
  --s-12:  80px;

  /* Layout */
  --prose-width:   680px;
  --sidebar-width: 240px;
  --toc-width:     200px;
  --content-max:   1180px;
  --header-height: 56px;
}

[data-theme="light"] {
  --bg:          #fafaf7;
  --surface:     #ffffff;
  --elevated:    #f5f5f2;
  --border:      #e5e5e2;
  --border-soft: #ededea;

  --text:        #0a0a0a;
  --text-muted:  #525252;
  --text-faint:  #a3a3a3;

  --accent:      #0a0a0a;
  --mark:        #0a0a0a;
}
```

- [ ] **Step 2: Run the build to surface bad-variable references**

```bash
cd docs-website && npm run res:build
```

Expected: build succeeds (the variables are only referenced in CSS; ReScript doesn't read them).

- [ ] **Step 3: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): replace CSS tokens with pure-neutral editorial palette"
```

Note: the site will look broken between here and Task 5 because the rest of styles.css still references old variable names. That's expected — later tasks overwrite the dependent CSS wholesale.

---

### Task 3: Replace global reset and body typography

**Files:**
- Modify: `docs-website/src/styles.css` — the block from `/* ---- Global Reset ---- */` (or equivalent) through the point where the header styles begin.

- [ ] **Step 1: Locate the reset block**

Find the section immediately after `[data-theme="light"] { ... }`. It will contain `*, *::before, *::after { box-sizing: border-box; ... }`, `body { ... }`, heading resets, and link resets. Identify its end (the comment before the header or hero styles begin — likely around line 230-260).

- [ ] **Step 2: Replace the reset block**

Replace the identified span with:

```css
/* ---- Global reset ---- */
*, *::before, *::after {
  box-sizing: border-box;
}

html {
  -webkit-text-size-adjust: 100%;
  scroll-behavior: smooth;
  scroll-padding-top: calc(var(--header-height) + var(--s-5));
}

body {
  margin: 0;
  font-family: var(--font-body);
  font-size: var(--fs-base);
  line-height: var(--lh-prose);
  color: var(--text);
  background: var(--bg);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-feature-settings: "ss01", "cv11";
}

a {
  color: inherit;
  text-decoration: none;
}

img, svg, video {
  display: block;
  max-width: 100%;
}

button {
  font: inherit;
  color: inherit;
  background: transparent;
  border: 0;
  padding: 0;
  cursor: pointer;
}

input, textarea, select {
  font: inherit;
  color: inherit;
}

::selection {
  background: var(--text);
  color: var(--bg);
}

/* Skip-to-content link */
.skip-to-content {
  position: absolute;
  top: -100px;
  left: var(--s-4);
  padding: var(--s-2) var(--s-4);
  background: var(--text);
  color: var(--bg);
  font-size: var(--fs-sm);
  z-index: 1000;
}
.skip-to-content:focus {
  top: var(--s-4);
}

/* ---- Typography ---- */
h1, h2, h3, h4, h5, h6 {
  margin: 0;
  font-family: var(--font-display);
  font-weight: 400;
  line-height: var(--lh-tight);
  color: var(--text);
}

h1 {
  font-size: var(--fs-4xl);
  letter-spacing: -0.02em;
}

h2 {
  font-size: var(--fs-3xl);
  font-style: italic;
  letter-spacing: -0.015em;
}

h3 {
  font-size: var(--fs-2xl);
}

h4 {
  font-family: var(--font-body);
  font-size: var(--fs-xl);
  font-weight: 600;
  letter-spacing: -0.005em;
}

p {
  margin: 0 0 var(--s-5) 0;
  max-width: var(--prose-width);
}

strong {
  font-weight: 600;
}

em {
  font-style: italic;
}

code {
  font-family: var(--font-mono);
  font-size: 0.9em;
  font-style: italic;
  border-bottom: 1px solid var(--border);
  padding-bottom: 1px;
}

pre code {
  font-style: normal;
  border-bottom: 0;
  padding-bottom: 0;
}

hr {
  border: 0;
  border-top: 1px solid var(--border);
  margin: var(--s-6) 0;
}

ul, ol {
  margin: 0 0 var(--s-5) 0;
  padding-left: var(--s-5);
}

ul li, ol li {
  margin: var(--s-1) 0;
}

blockquote {
  margin: var(--s-5) 0;
  padding-left: var(--s-4);
  border-left: 4px solid var(--border);
  color: var(--text-muted);
}
```

- [ ] **Step 3: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): apply editorial global typography reset"
```

---

## Phase 2 — Chrome (header, sidebar, TOC, footer, search modal)

### Task 4: Rewrite the header styles

**Files:**
- Modify: `docs-website/src/styles.css` — the section containing `.site-header`, `.header-inner`, `.header-left`, `.header-right`, `.header-logo-link`, `.logo-text`, `.header-version`, `.header-nav`, `.header-nav-link`, `.search-trigger`, `.search-trigger-keys`, `.search-trigger-key`, `.gh-star-btn`, `.gh-star-label`, `.header-icon-btn`, `.mobile-menu-btn`.

- [ ] **Step 1: Replace the header CSS block**

Find the block beginning with a `.site-header` selector. Delete the entire block through the last header-related rule (stops where the sidebar or hero begins). Replace with:

```css
/* ---- Header ---- */
.site-header {
  position: sticky;
  top: 0;
  z-index: 100;
  height: var(--header-height);
  background: var(--bg);
  border-bottom: 1px solid var(--border);
}

.header-inner {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: 0 var(--s-5);
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--s-5);
}

.header-left {
  display: flex;
  align-items: baseline;
  gap: var(--s-4);
}

.header-logo-link {
  display: inline-flex;
  align-items: baseline;
  gap: var(--s-2);
  color: var(--text);
  font-family: var(--font-body);
  font-size: var(--fs-base);
  font-weight: 500;
  letter-spacing: -0.01em;
}

.header-logo-link .logo-text {
  display: inline;
}

.header-version {
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
}
.header-version:hover {
  color: var(--text-muted);
}

.header-nav {
  display: flex;
  align-items: center;
  gap: var(--s-5);
  margin-left: var(--s-5);
}

.header-nav-link {
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text-muted);
  text-decoration: none;
}
.header-nav-link:hover {
  color: var(--text);
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--s-4);
}

.search-trigger {
  display: inline-flex;
  align-items: center;
  gap: var(--s-2);
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text-muted);
  padding: 0;
}
.search-trigger:hover {
  color: var(--text);
}
.search-trigger > span {
  display: inline-block;
}

.search-trigger-keys {
  display: inline-flex;
  gap: 2px;
  margin-left: var(--s-2);
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
}
.search-trigger-key {
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
}

.header-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  color: var(--text-muted);
}
.header-icon-btn:hover {
  color: var(--text);
}

.gh-star-btn {
  display: none; /* editorial header drops the star button */
}

.mobile-menu-btn {
  display: none;
}

@media (max-width: 768px) {
  .header-nav,
  .search-trigger > span,
  .search-trigger-keys {
    display: none;
  }
  .mobile-menu-btn {
    display: inline-flex;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): rewrite header styles for editorial layout"
```

---

### Task 5: Simplify the header markup in Layout.res

**Files:**
- Modify: `docs-website/src/Layout.res:250-383`

- [ ] **Step 1: Replace the `Header` module**

Replace the `Header` module (lines 250-383) with:

```rescript
// ---- Header ----
module Header = {
  type props = {}

  let make = (_props: props) => {
    // Scroll listener (client-only)
    if SSRContext.isClient {
      Effect.run(() => {
        let handleScroll = () => {
          let scrollY: float = %raw(`window.scrollY`)
          Signal.set(isScrolled, scrollY > 10.0)
        }
        addEventListener("scroll", handleScroll)
        Some(() => removeEventListener("scroll", handleScroll))
      })
    }

    <header class="site-header">
      <div class="header-inner">
        <div class="header-left">
          {Router.link(
            ~to="/",
            ~attrs=[Node.attr("class", "header-logo-link")],
            ~children=[<span class="logo-text"> {Node.text("Xote")} </span>],
            (),
          )}
          <a
            href="https://www.npmjs.com/package/xote"
            target="_blank"
            class="header-version">
            {Node.text("v6.1.1")}
          </a>
          <nav class="header-nav">
            {Router.link(
              ~to="/docs",
              ~attrs=[Node.attr("class", "header-nav-link")],
              ~children=[Node.text("Docs")],
              (),
            )}
            <a
              href="https://github.com/brnrdog/xote"
              target="_blank"
              class="header-nav-link">
              {Node.text("GitHub")}
            </a>
          </nav>
        </div>
        <div class="header-right">
          {Node.element(
            "button",
            ~attrs=[Node.attr("class", "search-trigger")],
            ~events=[("click", _ => openSearch())],
            ~children=[
              <span> {Node.text("Search")} </span>,
              <div class="search-trigger-keys">
                <span class="search-trigger-key"> {Node.text("\u2318K")} </span>
              </div>,
            ],
            (),
          )}
          {Node.element(
            "button",
            ~attrs=[
              Node.attr("class", "header-icon-btn"),
              Node.attr("title", "Toggle theme"),
            ],
            ~events=[("click", _ => toggleTheme())],
            ~children=[
              Node.signalText(() =>
                Signal.get(theme) == "dark" ? "\u263E" : "\u2600"
              ),
            ],
            (),
          )}
          {Node.element(
            "button",
            ~attrs=[
              Node.attr("class", "header-icon-btn mobile-menu-btn"),
              Node.attr("title", "Menu"),
            ],
            ~events=[("click", _ => openSearch())],
            ~children=[Node.text("\u2261")],
            (),
          )}
        </div>
      </div>
    </header>
  }
}
```

Notes:
- The `isScrolled` signal is still declared and updated (other code still reads it — the CSS just no longer cares).
- `Basefn.Icon` and the `Logo` component are no longer used in the header. Leave them imported/declared — later tasks decide whether to remove.
- The glyph-only theme toggle uses `☾` / `☀` as spec'd.

- [ ] **Step 2: Build ReScript**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 3: Commit**

```bash
git add docs-website/src/Layout.res docs-website/src/Layout.res.mjs
git commit -m "docs(website): simplify header markup to editorial masthead"
```

---

### Task 6: Rewrite the sidebar styles and markup

**Files:**
- Modify: `docs-website/src/styles.css` — the section containing `.docs-sidebar`, `.sidebar-section`, `.sidebar-section-title`, `.sidebar-link`, `.sidebar-link.active`.
- Modify: `docs-website/src/DocsPage.res` — remove the `Demos` group from `docsNav` and tweak the `Sidebar` module to emit the editorial active-marker.

- [ ] **Step 1: Replace the sidebar CSS**

Find the `.docs-sidebar` block. Delete the entire contiguous block of sidebar rules. Replace with:

```css
/* ---- Sidebar ---- */
.docs-sidebar {
  width: var(--sidebar-width);
  flex-shrink: 0;
  padding: var(--s-8) var(--s-5) var(--s-10) 0;
  position: sticky;
  top: var(--header-height);
  max-height: calc(100vh - var(--header-height));
  overflow-y: auto;
}

.sidebar-section {
  margin-bottom: var(--s-6);
}

.sidebar-section-title {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin-bottom: var(--s-3);
}

.sidebar-link {
  display: block;
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  line-height: 1.5;
  color: var(--text-muted);
  padding: var(--s-1) 0;
  position: relative;
}
.sidebar-link:hover {
  color: var(--text);
}
.sidebar-link.active {
  color: var(--text);
}
.sidebar-link.active::before {
  content: "\25A0";
  position: absolute;
  left: -14px;
  top: var(--s-1);
  color: var(--mark);
  font-size: 10px;
  line-height: 1.5;
}

@media (max-width: 1024px) {
  .docs-sidebar {
    display: none;
  }
}
```

- [ ] **Step 2: Remove the Demos group from `docsNav`**

In `docs-website/src/DocsPage.res`, replace the entire `docsNav` array (lines 12-64) with:

```rescript
let docsNav: array<docCategory> = [
  {
    label: "Getting Started",
    items: [{title: "Introduction", path: "/docs"}],
  },
  {
    label: "Core Concepts",
    items: [
      {title: "Signals", path: "/docs/core-concepts/signals"},
      {title: "Computeds", path: "/docs/core-concepts/computed"},
      {title: "Effects", path: "/docs/core-concepts/effects"},
    ],
  },
  {
    label: "Components",
    items: [{title: "Overview", path: "/docs/components/overview"}],
  },
  {
    label: "Router",
    items: [{title: "Overview", path: "/docs/router/overview"}],
  },
  {
    label: "API Reference",
    items: [{title: "Signals", path: "/docs/api/signals"}],
  },
  {
    label: "Comparisons",
    items: [
      {title: "React", path: "/docs/comparisons/react"},
      {title: "SolidJS", path: "/docs/comparisons/solidjs"},
    ],
  },
  {
    label: "Advanced",
    items: [
      {title: "Server-Side Rendering", path: "/docs/advanced/ssr"},
      {title: "Batching", path: "/docs/advanced/batching"},
      {title: "Technical Overview", path: "/docs/technical-overview"},
    ],
  },
]
```

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/styles.css docs-website/src/DocsPage.res docs-website/src/DocsPage.res.mjs
git commit -m "docs(website): editorial sidebar, drop demos group"
```

---

### Task 7: Rewrite the TOC styles

**Files:**
- Modify: `docs-website/src/styles.css` — `.docs-toc`, `.toc-title`, `.toc-link`, `.toc-link.active`, `.toc-link-h3`.
- Modify: `docs-website/src/DocsPage.res:229-255` — the `TableOfContents` module.

- [ ] **Step 1: Replace the TOC CSS**

Find the `.docs-toc` block. Replace all TOC-related rules with:

```css
/* ---- TOC (right rail) ---- */
.docs-toc {
  width: var(--toc-width);
  flex-shrink: 0;
  padding: var(--s-8) 0 var(--s-10) var(--s-5);
  position: sticky;
  top: var(--header-height);
  max-height: calc(100vh - var(--header-height));
  overflow-y: auto;
}

.toc-title {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin-bottom: var(--s-3);
}

.toc-link {
  display: block;
  font-family: var(--font-body);
  font-size: 13px;
  line-height: 1.5;
  color: var(--text-muted);
  padding: var(--s-1) 0;
  text-decoration: none;
  position: relative;
}
.toc-link:hover {
  color: var(--text);
}
.toc-link.active {
  color: var(--text);
}
.toc-link.active::before {
  content: "\2014";
  position: absolute;
  left: -16px;
  color: var(--text);
}
.toc-link-h3 {
  padding-left: var(--s-3);
  font-size: var(--fs-xs);
}

@media (max-width: 1200px) {
  .docs-toc {
    display: none;
  }
}
```

- [ ] **Step 2: Update the TOC label in DocsPage.res**

In `docs-website/src/DocsPage.res`, replace the `"On this page"` string (in the `TableOfContents` module, around line 243) with `"Contents"`. The resulting block should read:

```rescript
let make = (props: props) => {
  if Array.length(props.items) == 0 {
    Node.fragment([])
  } else {
    <aside class="docs-toc">
      <div class="toc-title"> {Node.text("Contents")} </div>
      {Node.fragment(
        props.items->Array.map(item => {
          let className = "toc-link" ++ (item.level == 3 ? " toc-link-h3" : "")
          <a href={"#" ++ item.id} class={className}>
            {Node.text(item.text)}
          </a>
        }),
      )}
    </aside>
  }
}
```

- [ ] **Step 3: Build and commit**

```bash
cd docs-website && npm run res:build
git add docs-website/src/styles.css docs-website/src/DocsPage.res docs-website/src/DocsPage.res.mjs
git commit -m "docs(website): editorial table-of-contents"
```

---

### Task 8: Rewrite the docs layout (container / main / breadcrumb / prev-next / feedback)

**Files:**
- Modify: `docs-website/src/styles.css` — `.docs-layout`, `.docs-main`, `.docs-breadcrumb`, `.docs-breadcrumb-sep`, `.docs-breadcrumb-current`, `.docs-page-title`, `.docs-page-lead`, `.docs-content`, `.docs-prev-next`, `.docs-prev-next-link`, `.docs-prev-next-label`, `.docs-prev-next-title`, `.docs-feedback`, `.feedback-btn`, `.feedback-btn.selected`.

- [ ] **Step 1: Replace the docs-layout block**

Find the `.docs-layout` selector and replace the contiguous docs-layout block with:

```css
/* ---- Docs layout ---- */
.docs-layout {
  display: flex;
  gap: 0;
  max-width: var(--content-max);
  margin: 0 auto;
  padding: 0 var(--s-5);
  min-height: calc(100vh - var(--header-height));
  position: relative;
}

.docs-main {
  flex: 1;
  min-width: 0;
  padding: var(--s-8) var(--s-6) var(--s-12) var(--s-6);
  max-width: calc(var(--prose-width) + var(--s-12));
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  width: 100%;
}

.docs-main > * {
  max-width: var(--prose-width);
}

.docs-breadcrumb {
  font-family: var(--font-body);
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-bottom: var(--s-6);
  display: flex;
  align-items: center;
  gap: var(--s-2);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.docs-breadcrumb a {
  color: var(--text-muted);
  text-decoration: none;
}
.docs-breadcrumb a:hover {
  color: var(--text);
}
.docs-breadcrumb-sep {
  color: var(--text-faint);
}
.docs-breadcrumb-current {
  color: var(--text);
}

.docs-page-title {
  font-family: var(--font-display);
  font-size: var(--fs-4xl);
  letter-spacing: -0.02em;
  margin: 0 0 var(--s-4) 0;
  font-weight: 400;
}

.docs-page-lead {
  font-family: var(--font-body);
  font-size: var(--fs-lg);
  line-height: 1.55;
  color: var(--text-muted);
  margin: 0 0 var(--s-8) 0;
  max-width: var(--prose-width);
}

.docs-content {
  font-size: var(--fs-base);
  line-height: var(--lh-prose);
  max-width: var(--prose-width);
}

.docs-content h2 {
  margin-top: var(--s-8);
  margin-bottom: var(--s-4);
}

.docs-content h3 {
  margin-top: var(--s-6);
  margin-bottom: var(--s-3);
}

.docs-content h4 {
  margin-top: var(--s-5);
  margin-bottom: var(--s-2);
}

.docs-prev-next {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--s-4);
  margin-top: var(--s-10);
  padding-top: var(--s-6);
  border-top: 1px solid var(--border);
}

.docs-prev-next-link {
  display: flex;
  flex-direction: column;
  gap: var(--s-1);
  padding: var(--s-4) 0;
  color: var(--text-muted);
  text-decoration: none;
  border: 0;
}
.docs-prev-next-link:hover .docs-prev-next-title {
  color: var(--text);
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
}
.docs-prev-next-link.next {
  text-align: right;
  align-items: flex-end;
}

.docs-prev-next-label {
  font-family: var(--font-body);
  font-size: var(--fs-xs);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-faint);
}

.docs-prev-next-title {
  font-family: var(--font-display);
  font-size: var(--fs-xl);
  color: var(--text);
}

.docs-feedback {
  display: flex;
  align-items: center;
  gap: var(--s-3);
  margin-top: var(--s-8);
  padding-top: var(--s-5);
  border-top: 1px solid var(--border-soft);
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text-muted);
}
.feedback-btn {
  padding: var(--s-1) var(--s-3);
  border: 1px solid var(--border);
  border-radius: 2px;
  color: var(--text-muted);
  font-size: var(--fs-sm);
}
.feedback-btn:hover {
  color: var(--text);
  border-color: var(--text);
}
.feedback-btn.selected {
  color: var(--text);
  border-color: var(--text);
}
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): editorial docs layout, narrow reading column"
```

---

### Task 9: Rewrite the footer styles and markup

**Files:**
- Modify: `docs-website/src/styles.css` — `.site-footer`, `.footer-inner`, `.footer-grid`, `.footer-brand`, `.footer-brand-logo`, `.footer-col`, `.footer-bottom`, `.footer-bottom-right`.
- Modify: `docs-website/src/Layout.res:386-478` — the `Footer` module.

- [ ] **Step 1: Replace the footer CSS**

Find the `.site-footer` block and replace the contiguous footer rules with:

```css
/* ---- Footer ---- */
.site-footer {
  background: var(--bg);
  border-top: 1px solid var(--border);
  margin-top: var(--s-12);
}

.footer-inner {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--s-10) var(--s-5) var(--s-6) var(--s-5);
}

.footer-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: var(--s-8);
  padding-bottom: var(--s-6);
  border-bottom: 1px solid var(--border);
}

.footer-brand h4 {
  font-family: var(--font-display);
  font-size: var(--fs-xl);
  font-weight: 400;
  font-style: normal;
  margin: 0 0 var(--s-3) 0;
}

.footer-brand p {
  max-width: 32ch;
  color: var(--text-muted);
  font-size: var(--fs-sm);
  line-height: 1.55;
  margin: 0;
}

.footer-col h4 {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin: 0 0 var(--s-3) 0;
}

.footer-col ul {
  list-style: none;
  margin: 0;
  padding: 0;
}

.footer-col li {
  margin: var(--s-1) 0;
}

.footer-col a {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  text-decoration: none;
}
.footer-col a:hover {
  color: var(--text);
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
}

.footer-bottom {
  display: flex;
  justify-content: space-between;
  padding-top: var(--s-5);
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
}

@media (max-width: 768px) {
  .footer-grid {
    grid-template-columns: 1fr;
    gap: var(--s-6);
  }
}
```

- [ ] **Step 2: Rewrite the `Footer` module**

Open `docs-website/src/Layout.res`. Replace the `Footer` module (lines 386-478) with:

```rescript
// ---- Footer ----
module Footer = {
  type props = {}

  let make = (_props: props) => {
    let year = Date.now()->Date.fromTime->Date.getFullYear->Int.toString

    <footer class="site-footer">
      <div class="footer-inner">
        <div class="footer-grid">
          <div class="footer-brand">
            <h4> {Node.text("Xote")} </h4>
            <p>
              {Node.text(
                "A lightweight UI library for ReScript with fine-grained reactivity.",
              )}
            </p>
          </div>
          <div class="footer-col">
            <h4> {Node.text("Docs")} </h4>
            <ul>
              <li>
                {Router.link(~to="/docs", ~children=[Node.text("Introduction")], ())}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/core-concepts/signals",
                  ~children=[Node.text("Core Concepts")],
                  (),
                )}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/api/signals",
                  ~children=[Node.text("API Reference")],
                  (),
                )}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {Node.text("Community")} </h4>
            <ul>
              <li>
                <a href="https://github.com/brnrdog/xote" target="_blank">
                  {Node.text("GitHub \u2197")}
                </a>
              </li>
              <li>
                <a href="https://www.npmjs.com/package/xote" target="_blank">
                  {Node.text("npm \u2197")}
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/brnrdog/xote/issues"
                  target="_blank">
                  {Node.text("Issues \u2197")}
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div class="footer-bottom">
          <div>
            {Node.text(`\u00A9 ${year} Bernardo Gurgel \u00B7 MIT License`)}
          </div>
          <div> {Node.text("v6.1.1")} </div>
        </div>
      </div>
    </footer>
  }
}
```

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/styles.css docs-website/src/Layout.res docs-website/src/Layout.res.mjs
git commit -m "docs(website): editorial footer, drop demos link and logo mark"
```

---

### Task 10: Rewrite the search modal styles and trim the demo search items

**Files:**
- Modify: `docs-website/src/styles.css` — `.search-overlay`, `.search-modal`, `.search-input-wrapper`, `.search-input`, `.search-results`, `.search-group-label`, `.search-result-item`, `.search-result-title`, `.search-empty`, `.search-footer`.
- Modify: `docs-website/src/Layout.res:60-79` — the `searchItems` array.
- Modify: `docs-website/src/Layout.res:160-172` — the search input markup (remove the icon, update placeholder).

- [ ] **Step 1: Replace the search modal CSS**

Find the `.search-overlay` selector. Replace the contiguous search-related rules with:

```css
/* ---- Search modal ---- */
.search-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding-top: 10vh;
}

.search-modal {
  width: 600px;
  max-width: 92vw;
  background: var(--elevated);
  border: 1px solid var(--border);
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  max-height: 75vh;
  overflow: hidden;
}

.search-input-wrapper {
  display: flex;
  align-items: center;
  padding: var(--s-4) var(--s-5);
  border-bottom: 1px solid var(--border);
}

.search-input {
  flex: 1;
  border: 0;
  background: transparent;
  font-family: var(--font-display);
  font-style: italic;
  font-size: var(--fs-xl);
  color: var(--text);
  outline: none;
}
.search-input::placeholder {
  color: var(--text-faint);
  font-style: italic;
}

.search-results {
  flex: 1;
  overflow-y: auto;
  padding: var(--s-3) 0;
}

.search-group-label {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
  padding: var(--s-3) var(--s-5) var(--s-2) var(--s-5);
}

.search-result-item {
  padding: var(--s-2) var(--s-5);
  cursor: pointer;
}
.search-result-item:hover,
.search-result-item.active {
  background: var(--surface);
}

.search-result-title {
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text);
}

.search-empty {
  padding: var(--s-5);
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text-muted);
  text-align: center;
}

.search-footer {
  padding: var(--s-3) var(--s-5);
  border-top: 1px solid var(--border);
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
  display: flex;
  justify-content: center;
}
```

- [ ] **Step 2: Trim `searchItems`**

In `docs-website/src/Layout.res`, replace `searchItems` (lines 60-79) with:

```rescript
let searchItems: array<searchItem> = [
  {title: "Introduction", path: "/docs", section: "Getting Started"},
  {title: "Signals", path: "/docs/core-concepts/signals", section: "Core Concepts"},
  {title: "Computeds", path: "/docs/core-concepts/computed", section: "Core Concepts"},
  {title: "Effects", path: "/docs/core-concepts/effects", section: "Core Concepts"},
  {title: "Components Overview", path: "/docs/components/overview", section: "Components"},
  {title: "Router Overview", path: "/docs/router/overview", section: "Router"},
  {title: "Signals API", path: "/docs/api/signals", section: "API Reference"},
  {title: "React Comparison", path: "/docs/comparisons/react", section: "Comparisons"},
  {title: "SolidJS Comparison", path: "/docs/comparisons/solidjs", section: "Comparisons"},
  {title: "Server-Side Rendering", path: "/docs/advanced/ssr", section: "Advanced"},
  {title: "Batching", path: "/docs/advanced/batching", section: "Advanced"},
  {title: "Technical Overview", path: "/docs/technical-overview", section: "Advanced"},
]
```

- [ ] **Step 3: Simplify the search input markup**

In `docs-website/src/Layout.res`, find the `<div class="search-input-wrapper">` block inside `SearchModal` (around lines 161-173) and replace with:

```rescript
<div class="search-input-wrapper">
  {Html.input(
    ~attrs=[
      Node.attr("class", "search-input"),
      Node.attr("placeholder", "Search the docs..."),
      Node.attr("autofocus", "true"),
    ],
    ~events=[("input", handleInput), ("keydown", handleKeyDown)],
    (),
  )}
</div>
```

(Remove the `Basefn.Icon.make({name: Search, size: Sm})` icon and the `search-trigger-key` "esc" chip.)

- [ ] **Step 4: Update the search footer text**

Find the `<div class="search-footer">` block (around line 234). Replace the text with:

```rescript
<div class="search-footer">
  {Node.text("\u2191\u2193 navigate  \u21B5 select  esc close")}
</div>
```

- [ ] **Step 5: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 6: Commit**

```bash
git add docs-website/src/styles.css docs-website/src/Layout.res docs-website/src/Layout.res.mjs
git commit -m "docs(website): editorial search modal, drop demo search items"
```

---

## Phase 3 — Components (buttons, cards, code, callouts)

### Task 11: Rewrite button styles

**Files:**
- Modify: `docs-website/src/styles.css` — `.btn`, `.btn-primary`, `.btn-ghost`, and any `.btn-*` modifiers.

- [ ] **Step 1: Replace the button block**

Find the contiguous `.btn*` rules and replace with:

```css
/* ---- Buttons ---- */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--s-2);
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  font-weight: 500;
  line-height: 1;
  padding: var(--s-3) var(--s-5);
  border-radius: 2px;
  border: 1px solid transparent;
  text-decoration: none;
  cursor: pointer;
  transition: opacity 120ms linear, background-color 120ms linear;
}
.btn:focus-visible {
  outline: 1px solid var(--text);
  outline-offset: 2px;
}

.btn-primary {
  background: var(--text);
  color: var(--bg);
}
.btn-primary:hover {
  opacity: 0.9;
}

.btn-ghost {
  background: transparent;
  color: var(--text);
  border-color: var(--border);
}
.btn-ghost:hover {
  background: var(--elevated);
  border-color: var(--text);
}
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): two-variant editorial buttons"
```

---

### Task 12: Rewrite code block styles

**Files:**
- Modify: `docs-website/src/styles.css` — `pre`, `.syntax-line`, `.syntax-line-number`, `.syntax-line-content`, `.syntax-keyword`, `.syntax-type`, `.syntax-string`, `.syntax-number`, `.syntax-comment`, `.syntax-text`, and any existing code-block wrappers like `.code-block`, `.code-editor-pre`, `.code-filename`, `.code-caption`.

- [ ] **Step 1: Replace the code block CSS**

Find all existing code-block rules. Delete them. Replace with:

```css
/* ---- Code blocks ---- */
pre {
  font-family: var(--font-mono);
  font-size: 14px;
  line-height: 1.55;
  background: transparent;
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
  padding: var(--s-4) 0;
  margin: var(--s-5) 0;
  overflow-x: auto;
  color: var(--text);
}

.code-filename {
  font-family: var(--font-mono);
  font-style: italic;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: var(--s-5);
  margin-bottom: var(--s-2);
}

.code-caption {
  font-family: var(--font-mono);
  font-style: italic;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: var(--s-2);
}

.syntax-line {
  display: flex;
  padding: 0 var(--s-3);
}

.syntax-line-number {
  display: inline-block;
  width: 2.5em;
  color: var(--text-faint);
  font-variant-numeric: tabular-nums;
  text-align: right;
  margin-right: var(--s-3);
  user-select: none;
}

.syntax-line-content {
  flex: 1;
  white-space: pre;
}

/* Monochrome highlighting — weight + italic only */
.syntax-keyword { color: var(--text-muted); font-style: italic; }
.syntax-type    { color: var(--text);        font-weight: 600; }
.syntax-string  { color: var(--text); }
.syntax-number  { color: var(--text);        text-decoration: underline; text-underline-offset: 2px; text-decoration-thickness: 1px; }
.syntax-comment { color: var(--text-faint);  font-style: italic; }
.syntax-text    { color: var(--text); }
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): monochrome code blocks with figure captions"
```

---

### Task 13: Add callout styles

**Files:**
- Modify: `docs-website/src/styles.css` — add a `/* ---- Callouts ---- */` block (replace any existing `.callout*` rules if present).

- [ ] **Step 1: Replace/add the callout CSS**

Locate any existing `.callout*` block or, if none, insert after the code block section. Ensure the final CSS contains:

```css
/* ---- Callouts (margin-notes) ---- */
.callout {
  border-left: 4px solid var(--border);
  padding: var(--s-1) 0 var(--s-1) var(--s-4);
  margin: var(--s-5) 0;
  color: var(--text-muted);
  font-size: 15px;
  line-height: 1.55;
}

.callout-label {
  display: block;
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text);
  margin-bottom: var(--s-1);
}

.callout-deprecated {
  border-left: 0;
  border-top: 2px solid var(--border);
  padding: var(--s-3) 0 0 0;
}

.callout p:last-child {
  margin-bottom: 0;
}
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): editorial callouts as margin-notes"
```

---

### Task 14: Rewrite card/grid styles for the homepage

**Files:**
- Modify: `docs-website/src/styles.css` — `.feature-card`, `.feature-card-icon`, `.feature-card-link`, `.features-section`, `.features-inner`, `.features-heading`, `.features-grid`.

- [ ] **Step 1: Replace the features block**

Find the `.features-section` / `.feature-card` rules. Replace with:

```css
/* ---- Features (homepage) ---- */
.features-section {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--s-12) var(--s-5);
}

.features-heading {
  margin-bottom: var(--s-8);
  border-bottom: 1px solid var(--border);
  padding-bottom: var(--s-4);
}

.features-heading h2 {
  font-family: var(--font-display);
  font-size: var(--fs-3xl);
  font-style: italic;
  letter-spacing: -0.015em;
  margin: 0;
}

.features-heading h2::before {
  content: "\00A7 ";
  color: var(--text-muted);
  font-style: normal;
}

.features-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--s-8) var(--s-10);
}

.feature-card {
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: var(--s-6) var(--s-5);
  display: flex;
  flex-direction: column;
  background: var(--bg);
  transition: border-color 150ms linear;
}
.feature-card:hover {
  border-color: var(--text);
}

.feature-card-number {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-faint);
  margin-bottom: var(--s-5);
}

.feature-card h3 {
  font-family: var(--font-display);
  font-size: var(--fs-xl);
  font-weight: 400;
  font-style: normal;
  margin: 0 0 var(--s-3) 0;
}

.feature-card h3::after {
  content: "";
  display: block;
  width: 24px;
  border-top: 1px solid var(--border);
  margin-top: var(--s-3);
}

.feature-card p {
  font-size: var(--fs-sm);
  color: var(--text-muted);
  margin: 0 0 var(--s-5) 0;
  max-width: none;
  line-height: 1.55;
}

.feature-card-link {
  margin-top: auto;
  font-family: var(--font-body);
  font-size: 13px;
  color: var(--text);
  text-decoration: none;
}
.feature-card-link:hover {
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
}

@media (max-width: 768px) {
  .features-grid {
    grid-template-columns: 1fr;
    gap: var(--s-6);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): editorial feature cards with figure numbers"
```

---

## Phase 4 — Homepage rewrite

### Task 15: Rewrite `HomePage.res`

**Files:**
- Modify: `docs-website/src/HomePage.res`
- Modify: `docs-website/src/styles.css` — add the hero + community-close blocks.

- [ ] **Step 1: Add the hero + community CSS**

Append to `docs-website/src/styles.css` (or replace equivalent existing blocks):

```css
/* ---- Hero (homepage) ---- */
.hero {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--s-12) var(--s-5);
  border-bottom: 1px solid var(--border);
}

.hero-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding-bottom: var(--s-5);
  border-bottom: 1px solid var(--border);
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text-muted);
}

.hero-head .wordmark {
  font-family: var(--font-body);
  font-size: var(--fs-xl);
  font-weight: 500;
  color: var(--text);
  letter-spacing: -0.01em;
}

.hero-head .imprint {
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--text-faint);
}

.hero-display {
  font-family: var(--font-display);
  font-size: var(--fs-display);
  line-height: 1.05;
  letter-spacing: -0.025em;
  margin: var(--s-10) 0 var(--s-8) 0;
  max-width: 14ch;
  font-weight: 400;
}

.hero-lead {
  font-family: var(--font-body);
  font-size: var(--fs-lg);
  line-height: 1.5;
  color: var(--text-muted);
  max-width: 50ch;
  margin: 0 0 var(--s-8) 0;
}

.hero-ctas {
  display: flex;
  gap: var(--s-4);
  align-items: center;
  margin-bottom: var(--s-10);
}
.hero-ctas a.btn-secondary-link {
  font-family: var(--font-body);
  font-size: var(--fs-sm);
  color: var(--text);
  text-decoration: none;
}
.hero-ctas a.btn-secondary-link:hover {
  text-decoration: underline;
  text-underline-offset: 4px;
  text-decoration-thickness: 1px;
}

.hero-foot {
  padding-top: var(--s-5);
  border-top: 1px solid var(--border);
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
}

@media (max-width: 768px) {
  .hero-display {
    font-size: 48px;
    max-width: 18ch;
  }
  .hero-head .wordmark {
    font-size: var(--fs-base);
  }
}

/* ---- Code example block on the homepage ---- */
.code-example-section {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--s-10) var(--s-5);
}

.code-example-section h2 {
  font-family: var(--font-display);
  font-size: var(--fs-3xl);
  font-style: italic;
  letter-spacing: -0.015em;
  margin: 0 0 var(--s-5) 0;
}

.code-example-section h2::before {
  content: "\00A7 ";
  color: var(--text-muted);
  font-style: normal;
}

/* ---- Community close ---- */
.community-close {
  max-width: var(--content-max);
  margin: 0 auto;
  padding: var(--s-12) var(--s-5);
  text-align: center;
  border-top: 1px solid var(--border);
}

.community-close p {
  font-family: var(--font-display);
  font-size: var(--fs-2xl);
  color: var(--text);
  margin: 0 auto var(--s-6) auto;
  max-width: 32ch;
  line-height: 1.3;
}
```

- [ ] **Step 2: Rewrite `HomePage.res` end-to-end**

Open `docs-website/src/HomePage.res` and replace the entire file contents with:

```rescript
// ---- Feature data ----
type feature = {
  number: string,
  title: string,
  description: string,
  linkText: option<string>,
  linkTo: option<string>,
}

let features: array<feature> = [
  {
    number: "01",
    title: "Fine-grained reactivity",
    description: "Signals, computeds, and effects recompute only what changed. No virtual DOM diff.",
    linkText: Some("Learn about signals"),
    linkTo: Some("/docs/core-concepts/signals"),
  },
  {
    number: "02",
    title: "Isomorphic rendering",
    description: "Render on the server, hydrate on the client. Same code, both sides.",
    linkText: Some("SSR guide"),
    linkTo: Some("/docs/advanced/ssr"),
  },
  {
    number: "03",
    title: "JSX or function API",
    description: "Write components in JSX or plain ReScript. Both compile to the same lightweight nodes.",
    linkText: Some("Component docs"),
    linkTo: Some("/docs/components/overview"),
  },
  {
    number: "04",
    title: "Minimal footprint",
    description: "One runtime dependency. Tree-shakeable per module. No hidden complexity.",
    linkText: Some("Read the overview"),
    linkTo: Some("/docs/technical-overview"),
  },
]

module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature: f} = props
    <div class="feature-card">
      <div class="feature-card-number"> {Node.text(f.number)} </div>
      <h3> {Node.text(f.title)} </h3>
      <p> {Node.text(f.description)} </p>
      {switch (f.linkText, f.linkTo) {
      | (Some(text), Some(to)) =>
        Router.link(
          ~to,
          ~attrs=[Node.attr("class", "feature-card-link")],
          ~children=[Node.text(text ++ " \u2192")],
          (),
        )
      | _ => Node.fragment([])
      }}
    </div>
  }
}

module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="hero">
      <div class="hero-head">
        <span class="wordmark"> {Node.text("Xote")} </span>
        <span class="imprint"> {Node.text("v6.1.1")} </span>
      </div>
      <h1 class="hero-display">
        {Node.text("A lightweight UI library for ReScript, with fine-grained reactivity.")}
      </h1>
      <p class="hero-lead">
        {Node.text(
          "Build reactive interfaces with signals, computeds, and effects. Server-render, hydrate, compile.",
        )}
      </p>
      <div class="hero-ctas">
        {Router.link(
          ~to="/docs",
          ~attrs=[Node.attr("class", "btn btn-primary")],
          ~children=[Node.text("Get started")],
          (),
        )}
        {Router.link(
          ~to="/docs/core-concepts/signals",
          ~attrs=[Node.attr("class", "btn-secondary-link")],
          ~children=[Node.text("Read the docs \u2192")],
          (),
        )}
      </div>
      <div class="hero-foot">
        {Node.text("EST. 2025 \u00B7 BY BERNARDO GURGEL \u00B7 MIT LICENSED")}
      </div>
    </section>
  }
}

module Features = {
  type props = {}

  let make = (_props: props) => {
    <section class="features-section">
      <div class="features-heading">
        <h2> {Node.text("Features")} </h2>
      </div>
      <div class="features-grid">
        {Node.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
      </div>
    </section>
  }
}

module CodeExample = {
  type props = {}

  let counterCode = `open Xote

let make = () => {
  let count = Signal.make(0)

  let increment = (_evt) => Signal.update(count, n => n + 1)
  let decrement = (_evt) => Signal.update(count, n => n - 1)

  <div class="counter">
    <div> {Node.signalText(() => Signal.get(count)->Int.toString)} </div>
    <button onClick={decrement}> {Node.text("-")} </button>
    <button onClick={increment}> {Node.text("+")} </button>
  </div>
}`

  let make = (_props: props) => {
    <section class="code-example-section">
      <h2> {Node.text("A brief example")} </h2>
      <div class="code-filename"> {Node.text("counter.res")} </div>
      <pre>
        <code> {SyntaxHighlight.highlight(counterCode)} </code>
      </pre>
      <div class="code-caption">
        {Node.text("fig. 1 \u2014 signals and effects in 14 lines")}
      </div>
    </section>
  }
}

module CommunityClose = {
  type props = {}

  let make = (_props: props) => {
    <section class="community-close">
      <p>
        {Node.text("Open source on GitHub. Built with ReScript. Published under MIT.")}
      </p>
      <a href="https://github.com/brnrdog/xote" target="_blank" class="btn btn-ghost">
        {Node.text("View on GitHub \u2197")}
      </a>
    </section>
  }
}

type props = {}

let make = (_props: props) => {
  <Layout
    children={Node.fragment([
      <Hero />,
      <Features />,
      <CodeExample />,
      <CommunityClose />,
    ])}
  />
}
```

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 4: Visual check**

```bash
cd docs-website && npm run dev
```

Open the dev server URL, verify:
- Hero reads with the 96px Domine display in both themes.
- Features grid shows 4 cards in 2×2.
- Code example block shows the counter snippet with monochrome highlighting and a figure caption.
- Community close has a single ghost button.

Kill the dev server.

- [ ] **Step 5: Commit**

```bash
git add docs-website/src/HomePage.res docs-website/src/HomePage.res.mjs docs-website/src/styles.css
git commit -m "docs(website): rewrite homepage around editorial hero, 4-card features, code example"
```

---

## Phase 5 — Remove demo routes

### Task 16: Delete demo route handlers from `Website.res`

**Files:**
- Modify: `docs-website/src/Website.res`

- [ ] **Step 1: Remove demo module imports**

Replace lines 15-22 (`// Import demo content` block through `module SnakeGameDemo = SnakeGameDemo`) with a single comment:

```rescript
// Demo modules are still on disk under `src/demos/*.res` for reuse as
// inline figures, but no longer routed as standalone pages.
```

- [ ] **Step 2: Remove demo route entries**

In the routes array, delete lines that begin with the following patterns (everything from their opening `{` through the closing `},`):

- `pattern: "/demos"` (the `DemosPage` route)
- `pattern: "/docs/demos/counter"`
- `pattern: "/docs/demos/todo"`
- `pattern: "/docs/demos/color-mixer"`
- `pattern: "/docs/demos/reaction-game"`
- `pattern: "/docs/demos/solitaire"`
- `pattern: "/docs/demos/memory-match"`
- `pattern: "/docs/demos/snake"`

Leave the `pattern: "*"` fallback route intact. After the edit, the route array begins with `/` and ends with `*` and contains no demo-related entries.

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds. If the compiler complains that `DemoPage`, `DemosPage`, or any demo module is unused, that's fine — module imports in Xote's setup are unused-safe since top-level side effects aren't triggered just by the module existing.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/Website.res docs-website/src/Website.res.mjs
git commit -m "docs(website): remove /demos and /docs/demos/* routes"
```

---

### Task 17: Delete `DemoPage.res` and `DemosPage.res`

**Files:**
- Delete: `docs-website/src/DemoPage.res`
- Delete: `docs-website/src/DemoPage.res.mjs`
- Delete: `docs-website/src/DemosPage.res`
- Delete: `docs-website/src/DemosPage.res.mjs`

- [ ] **Step 1: Delete the files**

```bash
rm docs-website/src/DemoPage.res docs-website/src/DemoPage.res.mjs
rm docs-website/src/DemosPage.res docs-website/src/DemosPage.res.mjs
```

- [ ] **Step 2: Grep for lingering references**

```bash
grep -rn "DemoPage\|DemosPage" docs-website/src || echo "clean"
```

Expected output: `clean`. If matches exist in `.res.mjs` files, re-run `npm run res:build` (it regenerates them) then re-grep.

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 4: Commit**

```bash
git add -A docs-website/src
git commit -m "docs(website): delete DemoPage and DemosPage modules"
```

---

### Task 18: Delete unused demo-specific CSS

**Files:**
- Modify: `docs-website/src/styles.css`

- [ ] **Step 1: Identify demo-only selectors**

Search for these selectors (used only by removed demo pages) and delete their rules:
- `.demos-page`, `.demo-card`, `.demo-card-title`, `.demo-card-description`, `.demo-card-link`, `.demos-grid`, `.demos-hero`
- `.demo-page`, `.demo-breadcrumb`, `.demo-page-title`, `.demo-page-lead`, `.demo-container`, `.demo-source-link`
- Any `.counter-app`, `.counter-display`, `.counter-btn*` rules that were used by the old homepage code demo preview pane (they were only used by `HomePage.CodeDemo.CounterApp`, which is also removed — delete).
- Any `.temp-app`, `.temp-input*`, `.temp-results*`, `.timer-app`, `.timer-display`, `.timer-btn*` rules (same — old homepage code demo previews).
- Any `.code-editor-*`, `.code-preview-*`, `.browser-*` rules (old homepage split editor — removed by the HomePage rewrite).
- `.code-copy-btn` rule (old homepage copy button).
- `.hero-logo`, `.hero-logo-text`, `.hero-subtitle`, `.hero-inner`, `.hero-buttons`, `.features-inner` (replaced by new hero / features layout).
- `.code-demo-section`, `.code-demo-inner`, `.code-demo-heading`, `.code-demo-container` (old homepage).
- `.community-section`, `.community-inner`, `.community-links` (replaced by `.community-close`).

- [ ] **Step 2: Confirm no stragglers**

```bash
grep -nE "\\.code-editor|\\.code-preview|\\.browser-dot|\\.counter-app|\\.temp-app|\\.timer-app|\\.demo-card|\\.demos-page|\\.demo-page|\\.community-section|\\.hero-logo|\\.hero-subtitle" docs-website/src/styles.css || echo "clean"
```

Expected output: `clean`.

- [ ] **Step 3: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): remove CSS for deleted demo routes and old hero"
```

---

## Phase 6 — Inline demos

### Task 19: Create the `InlineDemo` component

**Files:**
- Create: `docs-website/src/InlineDemo.res`

- [ ] **Step 1: Add the file**

Create `docs-website/src/InlineDemo.res` with:

```rescript
type props = {
  caption: string,
  children: Node.node,
}

let make = (props: props) => {
  <figure class="inline-demo">
    <div class="inline-demo-stage"> {props.children} </div>
    <figcaption class="inline-demo-caption"> {Node.text(props.caption)} </figcaption>
  </figure>
}
```

- [ ] **Step 2: Add matching CSS**

Append to `docs-website/src/styles.css`:

```css
/* ---- Inline demos (in-prose figures) ---- */
.inline-demo {
  margin: var(--s-6) 0;
  padding: 0;
  max-width: var(--prose-width);
}

.inline-demo-stage {
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: var(--s-5);
  background: var(--surface);
}

.inline-demo-caption {
  font-family: var(--font-mono);
  font-style: italic;
  font-size: var(--fs-xs);
  color: var(--text-muted);
  margin-top: var(--s-2);
}
```

- [ ] **Step 3: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds. Notice `InlineDemo.res.mjs` now exists alongside.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/InlineDemo.res docs-website/src/InlineDemo.res.mjs docs-website/src/styles.css
git commit -m "docs(website): add InlineDemo component for in-prose figures"
```

---

### Task 20: Embed a counter figure in the Signals doc

**Files:**
- Modify: `docs-website/src/docs/SignalsDoc.res` — inject an inline demo after the "Example: Counter" section.

- [ ] **Step 1: Find the insertion point**

Open `docs-website/src/docs/SignalsDoc.res`. Locate the section with the id `example-counter` (search for `"example-counter"`). Just after that section's heading (inside the section's content, before any code block), insert the JSX:

```rescript
<InlineDemo caption="fig. 1 — a counter, synchronously reactive">
  <CounterDemo />
</InlineDemo>
```

If the file uses the function-based API instead of JSX for that section (likely — it's generated), add the inline demo using `Node.element` syntax where the existing example paragraph ends:

```rescript
Node.element(
  "figure",
  ~attrs=[Node.attr("class", "inline-demo")],
  ~children=[
    Node.element(
      "div",
      ~attrs=[Node.attr("class", "inline-demo-stage")],
      ~children=[<CounterDemo />],
      (),
    ),
    Node.element(
      "figcaption",
      ~attrs=[Node.attr("class", "inline-demo-caption")],
      ~children=[Node.text("fig. 1 \u2014 a counter, synchronously reactive")],
      (),
    ),
  ],
  (),
),
```

(Use whichever syntax matches the surrounding file. If the file is regenerated from markdown via a script, the generator may overwrite this — see Task 21 for the long-term plan. For now, an inline edit demonstrates the pattern.)

- [ ] **Step 2: Build**

```bash
cd docs-website && npm run res:build
```

Expected: succeeds.

- [ ] **Step 3: Visual check**

Run `cd docs-website && npm run dev`, navigate to `/docs/core-concepts/signals`, scroll to the Counter example. The embedded counter should render inside a hairline frame with the "fig. 1" caption.

Kill the dev server.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/docs/SignalsDoc.res docs-website/src/docs/SignalsDoc.res.mjs
git commit -m "docs(website): embed inline counter demo in signals doc"
```

---

### Task 21: Document the inline-demo authoring convention

**Files:**
- Create: `docs-website/src/docs/INLINE_DEMOS.md` (or add a section to an existing README under `docs-website/`).

- [ ] **Step 1: Write the convention note**

Create `docs-website/src/docs/INLINE_DEMOS.md` with:

```markdown
# Inline demos

Runnable examples live inside concept and tutorial pages as in-prose figures —
never as standalone routes. Use the `InlineDemo` component to wrap a demo
module with a figure caption.

```rescript
<InlineDemo caption="fig. 1 — a counter, synchronously reactive">
  <CounterDemo />
</InlineDemo>
```

Guidelines:

- Keep the stage inside the 680px reading column (no breakout).
- Caption in `DM Mono` italic: `fig. N — short description`.
- Place the code block *after* the demo: "see, then read."
- Demo modules live under `docs-website/src/demos/`. Import the module at
  the top of the doc file before use.

If a doc file is regenerated from markdown by a script, add the inline demo
invocation to the generator rather than hand-editing the output.
```

- [ ] **Step 2: Commit**

```bash
git add docs-website/src/docs/INLINE_DEMOS.md
git commit -m "docs(website): document inline-demo authoring convention"
```

---

## Phase 7 — Cleanup and verification

### Task 22: Remove any leftover styles and unused CSS

**Files:**
- Modify: `docs-website/src/styles.css`

- [ ] **Step 1: Grep for green-accent remnants**

```bash
grep -nE "--green-|--bg-base|--bg-surface|--bg-subtle|--text-accent|--callout-note|--callout-tip|--callout-warning|--callout-danger|--border-default|--border-subtle|--shadow-card|--shadow-elevated" docs-website/src/styles.css || echo "clean"
```

Delete any rules that still reference these old variables.

- [ ] **Step 2: Grep for accent-color uses**

```bash
grep -nE "#22a646|#1a8538|#3b82f6|#f59e0b|#ef4444" docs-website/src/styles.css || echo "clean"
```

Delete any rules that still reference these hex values.

- [ ] **Step 3: Sanity-check file size**

```bash
wc -l docs-website/src/styles.css
```

The new file should be considerably smaller than the original 3015 lines — expect roughly 900-1200 lines. If it's still above ~1500 lines, re-grep for leftover selectors that belong to removed features.

- [ ] **Step 4: Commit**

```bash
git add docs-website/src/styles.css
git commit -m "docs(website): remove leftover green-accent CSS"
```

---

### Task 23: Full-site smoke test across every route

- [ ] **Step 1: Start the dev server**

```bash
cd docs-website && npm run dev
```

- [ ] **Step 2: Visit each route and verify**

For each of these URLs, open in both dark and light mode (toggle via `☾` / `☀` glyph in the header). Note any visual bugs in a scratch list.

Kept routes:
- `/`
- `/docs`
- `/docs/core-concepts/signals`
- `/docs/core-concepts/computed`
- `/docs/core-concepts/effects`
- `/docs/components/overview`
- `/docs/router/overview`
- `/docs/api/signals`
- `/docs/comparisons/react`
- `/docs/comparisons/solidjs`
- `/docs/advanced/ssr`
- `/docs/advanced/batching`
- `/docs/technical-overview`

Removed routes — verify they now 404 cleanly:
- `/demos`
- `/docs/demos/counter`
- `/docs/demos/todo`
- `/docs/demos/color-mixer`
- `/docs/demos/reaction-game`
- `/docs/demos/solitaire`
- `/docs/demos/memory-match`
- `/docs/demos/snake`

- [ ] **Step 3: Verify keyboard interactions**

- `⌘K` opens the search modal.
- Arrow keys navigate results; Enter selects; Esc closes.
- Tab-order through header / sidebar / TOC is logical.
- Theme toggle works.

- [ ] **Step 4: Verify contrast**

In both modes, spot-check body text against `--bg`. Use the browser devtools' color picker contrast readout. Body text (`--text` on `--bg`) should exceed 7:1 (target: WCAG AAA).

- [ ] **Step 5: Kill the dev server, write any fixes, commit**

For any visual bugs found, make targeted fixes. Commit each fix separately with a descriptive message.

---

### Task 24: Production build verification

- [ ] **Step 1: Clean then build**

```bash
cd docs-website && npm run res:clean && npm run build
```

Expected: the build completes without errors. This runs `res:build`, `build:client`, `build:server`, and `build:prerender`.

- [ ] **Step 2: Preview the production build**

```bash
cd docs-website && npm run preview
```

Open the preview URL. Confirm:
- Initial HTML arrives with correct styles (server-rendered).
- Hydration succeeds (check devtools console for errors).
- `__XOTE_HYDRATED__` is `true` after page load.

Kill the preview.

- [ ] **Step 3: Run the root test suite**

```bash
npm test
```

Expected: all existing tests pass. (The redesign only affects `docs-website/`; the core library tests should be unaffected.)

- [ ] **Step 4: Commit anything outstanding**

```bash
git status
```

If clean, proceed. If there are uncommitted changes from Task 23 fixes, commit them with descriptive messages.

---

## Self-review coverage map

| Spec section | Implementing task(s) |
|---|---|
| §1 Editorial aesthetic direction | Task 2, 3 (tokens, body reset) |
| §2 Typography — Domine/DM Sans/DM Mono + scale + line heights + distinctive moves | Task 1 (fonts), Task 2 (scale tokens), Task 3 (heading/body/inline-code rules) |
| §3 Pure-neutral color + dark/light + monochrome syntax | Task 2 (tokens), Task 12 (syntax highlighter classes) |
| §4 Layout frame (240/680/200, 1180 max), spacing scale, breakpoints | Task 2 (tokens), Task 8 (docs layout) |
| §4 Header chrome | Task 4 (CSS), Task 5 (markup) |
| §4 Sidebar with `■` active marker | Task 6 |
| §4 TOC with em-dash active marker | Task 7 |
| §5 Code blocks with filename + figure caption + monochrome highlighting | Task 12 |
| §5 Inline code as italic underlined mono | Task 3 |
| §5 Callouts as margin-notes | Task 13 |
| §5 Two-variant buttons | Task 11 |
| §5 Cards with `01`/`02` numbering | Task 14 |
| §5 Nav link hover/active | Task 5 (header), Task 6 (sidebar), Task 7 (TOC) |
| §5 Search modal (Domine italic input, plain-text footer) | Task 10 |
| §5 Footer (three columns, `↗`, version mono) | Task 9 |
| §6 Homepage hero + features + code example + community close | Task 14 (features CSS), Task 15 (hero CSS + full HomePage rewrite) |
| §7 Kept routes, removed demo routes, sidebar groups | Task 6 (sidebar), Task 16 (routes), Task 10 (search items) |
| §7 Header nav (no Demos) | Task 5 |
| §8 Inline demos as in-prose figures | Task 19 (component + CSS), Task 20 (embed), Task 21 (convention doc) |
| §9 Removed scope | Task 16 (routes), Task 17 (modules), Task 18 (CSS cleanup) |
| §10 Implementation surface | All tasks touch the listed files |
| §11 Out of scope | Observed — no Xote core, build pipeline, or demo-internal styling is touched |
| §12 Success criteria | Task 23 (route smoke), Task 24 (production build) |
