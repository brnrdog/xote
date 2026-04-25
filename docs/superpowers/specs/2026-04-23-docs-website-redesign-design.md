# Docs Website Redesign — Design Spec

**Date**: 2026-04-23
**Branch**: `brnrdog/docs-redesign-v2`
**Goal**: Redesign the documentation site (`docs-website/`) around simplicity, neutral colors, and high contrast. Replace the current green-accented, card-heavy look with an editorial-reference aesthetic — technical journal / monograph.

## 1. Aesthetic Direction

**Editorial Reference.** The site reads like a well-typeset software monograph: narrow reading column, serif display type, hairline rules for structure, numbered figures, and pure-neutral color. Distinction comes from typographic restraint and precision, not from color or ornament.

## 2. Typography

| Role | Family | Source | Notes |
|---|---|---|---|
| Display / headings | Domine | Google Fonts | Used at 22px+ in Regular and Italic |
| Body / UI | DM Sans | Google Fonts | Used 11–18px |
| Code / mono | DM Mono | Google Fonts | Used 12–16px, italic for inline code |

**Scale** (modular, ~1.25 ratio):

```
xs    12px    captions, eyebrows, metadata
sm    14px    UI labels, sidebar, footnotes
base  16px    body prose (up from current 15)
lg    18px    lead paragraphs, intro text
xl    22px    h4 (sans bold)
2xl   28px    h3 (serif regular)
3xl   40px    h2 (serif italic)
4xl   60px    h1 (serif regular, tight tracking)
display 96px  homepage hero only (serif), caps at 48px on mobile
```

**Line-height**: `1.65` for body prose, `1.15` for display headings, `1.45` for UI.

**Weight rules**:
- Body only uses Regular (400).
- Bold (600) reserved for UI emphasis.
- Serif headings are all Regular — hierarchy is carried by size, not weight.

**Distinctive moves**:
- **h2 renders in Domine *italic*** — every section opener has the magazine-article voice without color.
- **Inline code** renders in `DM Mono italic` at `0.9em` with `border-bottom: 1px solid var(--border)` — a manuscript-footnote ruler, no pill background.
- **Optical tracking** on headings: h1 at `-0.02em`, h2 at `-0.015em`, body at `0`.

## 3. Color & Surfaces

Pure neutrals, two themes, no accent hue. Links are underlined body text; active-nav is a filled-square (`■`) glyph prefix.

### Dark mode (default)

```
--bg          #0a0a0a   near-black paper
--surface     #111111   sidebar / card bg
--elevated    #171717   hover / search modal bg
--border      #242424   hairline dividers
--border-soft #1a1a1a   secondary dividers
--text        #f5f5f4   primary prose (warm off-white)
--text-muted  #a3a3a3   metadata, captions
--text-faint  #525252   inactive nav, code comments
--accent      #f5f5f4   same as text
--mark        #fafaf7   active nav square
```

### Light mode

```
--bg          #fafaf7   warm paper white
--surface     #ffffff
--elevated    #f5f5f2
--border      #e5e5e2
--border-soft #ededea
--text        #0a0a0a
--text-muted  #525252
--text-faint  #a3a3a3
--accent      #0a0a0a
--mark        #0a0a0a
```

**Rules**:
- **No accent hue.** Zero color on links, buttons, badges, or callouts.
- **Borders are hairlines** (`1px solid var(--border)`). Layout containers have `0` radius. Cards max `4px`. Buttons max `2px`.
- **Warm whites, warm blacks**: slight yellow cast (`#fafaf7`, `#f5f5f4`) to feel like paper; `#0a0a0a` instead of pure black to reduce OLED glare.
- **No shadows.** Depth is created by rules and whitespace. Header gets a single hairline bottom border.

### Syntax highlighting

Monochrome — weight and italic only. No hue variation.

| Token | Style |
|---|---|
| keyword | `text-muted`, italic |
| type | `text`, bold |
| string | `text`, regular |
| number | `text`, underlined |
| comment | `text-faint`, italic |
| punct | `text-muted` |

## 4. Layout & Spatial System

### Page frame

```
┌─────────────────────────────────────────────────────────────┐
│ HEADER (56px, hairline bottom)                              │
├──────────────┬──────────────────────────────────┬───────────┤
│   SIDEBAR    │          MAIN (prose)            │    TOC    │
│   240px      │          max-width 680px         │   200px   │
│   sticky     │          centered                │   sticky  │
└──────────────┴──────────────────────────────────┴───────────┘
```

- **Total content width** ~1180px. On wider screens, margins grow; the reading column stays fixed at 680px.
- **No full-width layouts.**

### Spacing scale (8px base)

```
0    0       hairline rules
1    4px     tight stacking (label → value)
2    8px     inline elements
3    12px    UI spacing
4    16px    paragraph internal
5    24px    paragraph spacing, between <p>
6    32px    between content blocks, before <h3>
8    48px    between section groups, before <h2>
10   64px    major section breaks
12   80px    page-level breathing room
```

Prose rhythm: `24px` after `<p>`, `48px` before `<h2>`, `32px` before `<h3>`, `24px` before `<h4>`. Lists inherit paragraph spacing.

### Breakpoints

| Range | Layout |
|---|---|
| `>1200px` | 3-col (sidebar + main + toc) |
| `1024–1200px` | 2-col (sidebar + main); TOC hidden |
| `768–1024px` | 1-col with collapsible sidebar drawer |
| `<768px` | Single column, drawer sidebar, no TOC; hero caps at 48px |

### Header

```
[ Xote ] v6.1.1                           Docs  GitHub  ⌘K  ☾
```

- Wordmark in DM Sans Medium 16px, no logo icon.
- Version badge: DM Mono 12px, `text-faint`, inline sibling.
- Nav items: plain links, `text-muted`, hover → `text` + underline.
- Theme toggle: single glyph (`☀` / `☾`), no border.
- `⌘K` rendered as plain text, not a pill.
- Hairline bottom border only.

### Sidebar

- Group labels: DM Sans 11px uppercase, `0.08em` letter-spacing, `text-faint`.
- Items: 14px Regular, `text-muted`.
- **Active item**: `text`, prefixed with `■` (filled square).
- No icons. Indentation carries hierarchy. All items always visible (no expand/collapse).

### TOC (right rail)

- Heading "CONTENTS" in 11px uppercase.
- Links in 13px `text-muted`, hover → `text`.
- Active section: prefixed with `—` (em dash).
- No scroll-indicator bar.

## 5. Component Patterns

### Code blocks

- Filename caption above, DM Mono italic, `text-muted`.
- Hairline top and bottom; no background tint.
- Line numbers right-aligned, `text-faint`.
- Copy action outside the block, bottom-right, as text only (no button chrome).
- Monochrome syntax as defined in §3.

### Inline code

- DM Mono italic, `0.9em`.
- `border-bottom: 1px solid var(--border)` with `2px` underline-offset.
- No background tint, no rounded corners.

### Callouts (editorial margin-notes)

```
│ NOTE
│ Body text...
```

- `4px` left border rule, `text-muted`.
- Label in 11px uppercase DM Sans.
- Body in 15px Regular.
- Types differ **only by label**: `NOTE`, `TIP`, `WARNING`, `DEPRECATED`.
- `DEPRECATED` uses a `2px` top rule instead of left.
- No icons, no color.

### Buttons

Two variants:

- **Primary**: solid `text` background, `bg` foreground, `2px` radius, `12px/20px` padding, DM Sans 14 Medium. Hover: 90% opacity.
- **Ghost**: transparent, `1px` border, same dimensions. Hover: `elevated` background.

No gradients, no shadows. Focus: `1px` offset outline in text color.

### Cards (homepage features)

- Numbered editorial-style: `01`, `02`, `03`, `04` in DM Mono 11px `text-faint`.
- Title in Domine 22px Regular, then a short hairline rule.
- Description in DM Sans 14px `text-muted`.
- "Read more →" link at bottom.
- Hairline border, `4px` radius max.
- Hover: border → `text`. No lift, no glow.

### Nav links

- Default: `text-muted`, no decoration.
- Hover: `text` + underline (`underline-offset: 4px`, `decoration-thickness: 1px`).
- Active: `text`, no underline, prefixed with `■` (sidebar) or `—` (TOC).

### Search modal

- Centered, 600px wide, `elevated` bg, `1px` border, `4px` radius.
- Input with no border — hairline underline only. Placeholder in Domine 20px italic.
- Results grouped by section, 11px uppercase section labels.
- Shortcut footer in plain text: `↑↓ navigate   ↵ select   esc close`.

### Footer

Three columns, hairline separators, same `bg` as page:

```
───────────────────────────────────────────────────────────
Xote                      DOCS              COMMUNITY
A lightweight UI          Introduction      GitHub ↗
library for ReScript      Core Concepts     Discussions ↗
with fine-grained         API Reference     Issues ↗
reactivity.

© 2026 · MIT License                        v6.1.1
───────────────────────────────────────────────────────────
```

- External link arrow (`↗`) is the only icon in the footer.
- Version number bottom-right in DM Mono.

## 6. Homepage

Two screens tall maximum. Reads like the opening spread of a software monograph.

### Hero

```
Xote                                                  v6.1.1

─────────────────────────────────────────────────────────────

A lightweight UI library
for ReScript, with
fine-grained reactivity.         ← Domine 96px, 3 lines, left

Build reactive interfaces with signals, computeds,
and effects. Server-render, hydrate, compile.
                                  ← DM Sans 18px, text-muted

[ Get started ]   Read the docs →

─────────────────────────────────────────────────────────────
EST. 2025 · BY BERNARDO GURGEL · MIT LICENSED
```

- No gradient blobs, orbs, or noise overlays.
- Hairline rules top and bottom frame the hero like a masthead.
- `EST. 2025` imprint line is the signature editorial move.
- Two CTAs: solid primary + plain text link.

### Features — 2×3 grid (4 core features)

Heading: `§ Features` in Domine 40px italic, followed by a hairline rule.

Four cards, 2 columns × 2 rows. Keep content focused — no exaggeration.

1. **Fine-grained reactivity** — Signals, computeds, and effects recompute only what changed. No virtual DOM diff.
2. **Isomorphic rendering** — Render on the server, hydrate on the client. Same code, both sides.
3. **JSX or function API** — Write components in JSX or plain ReScript. Both compile to the same lightweight nodes.
4. **Minimal footprint** — One runtime dependency. Tree-shakeable per module. No hidden complexity.

### Code demo

A single curated example (counter: signal + effect + JSX). Full-width code-block treatment. Heading `§ A brief example` in Domine italic. Caption below in DM Mono italic: *counter.res — signals and effects*.

No tabs, no "try it live" — that's reserved for inline demos inside docs pages.

### Community close

Centered three-line statement followed by a single ghost button:

```
Open source on GitHub.
Built with ReScript.
Published under MIT.

[ View on GitHub ↗ ]
```

Flows into the footer with no hard break.

## 7. Docs Page Structure

### Routes (after removal)

**Kept:**

- `/` — Home
- `/docs` — Introduction
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
- `*` — 404

**Removed:**

- `/docs/demos` — the demos index page
- `/docs/demos/counter`
- `/docs/demos/todo`
- `/docs/demos/color-mixer`
- `/docs/demos/reaction-game`
- `/docs/demos/solitaire`
- `/docs/demos/memory-match`
- `/docs/demos/snake`

### Sidebar groups (after removal)

```
GETTING STARTED
■ Introduction

CORE CONCEPTS
  Signals
  Computeds
  Effects

COMPONENTS
  Overview

ROUTER
  Overview

API REFERENCE
  Signals API

COMPARISONS
  React
  SolidJS

ADVANCED
  SSR
  Batching
  Technical Overview
```

The "DEMOS" group is gone. Demo content moves inline into relevant concept pages as in-prose figures.

### Header nav (after removal)

```
[ Xote ] v6.1.1             Docs  GitHub  ⌘K  ☾
```

"Demos" is removed from the header nav.

## 8. Inline Demos (new pattern)

When a tutorial or concept page needs a runnable example, the demo renders inline **inside the 680px reading column** as an in-prose figure.

```
...when a signal changes, all dependent observers
are scheduled and run synchronously. You can see
this in the counter below:

┌────────────────────────────────────────┐
│                                        │
│   Count: 0                             │
│                                        │
│   [ decrement ]  [ increment ]         │
│                                        │
└────────────────────────────────────────┘
  fig. 1 — a counter, synchronously reactive

The code that drives this:

[ code block: counter.res ]

Notice that Signal.set only notifies...
```

Rules:

- Demo stays inside the 680px column. It's a figure, not a feature.
- Hairline frame, no shadow, no background tint.
- Caption below in DM Mono italic, `text-muted`: `fig. N — short description`.
- Code block follows the demo by convention ("see, then read").
- No "Try it live" banners, no reset buttons (unless the demo inherently needs them).
- Reuse the existing demo ReScript modules (`CounterDemo`, `TodoDemo`, etc.) as embedded figures — the modules themselves aren't removed, only their standalone routes and index page.

## 9. Removed scope

- All `/docs/demos/*` routes and the `DemosPage` wrapper component.
- The "Demos" entry in the header nav.
- The "Demos" sidebar group.
- Any DemoPage layout wrapper that is only used by demo routes.

Note: the demo modules themselves under `src/demos/*.res` are kept — they will be reused as inline figures in concept pages.

## 10. Implementation Surface

Files expected to change or be created:

| File | Change |
|---|---|
| `docs-website/src/styles.css` | Replace almost entirely — new tokens, components, spacing |
| `docs-website/index.html` | Swap Google Fonts imports (Domine, DM Sans, DM Mono) |
| `docs-website/src/Layout.res` | Update header, footer, search modal to new patterns |
| `docs-website/src/Website.res` | Remove demo routes, update sidebar groups, update header nav |
| `docs-website/src/HomePage.res` | Full rewrite for new hero, features grid, code demo, close |
| `docs-website/src/SyntaxHighlight.res` | Adjust token classes to match new monochrome palette |
| `docs-website/src/DemoPage.res` | Remove (no longer routed to) |
| `docs-website/src/DemosPage.res` | Remove |
| `docs-website/src/docs/*.res` | Embed inline demos where appropriate using figure pattern |
| `docs-website/src/components/InlineDemo.res` | New — figure wrapper for inline demos |

## 11. Out of scope

- No MDX / markdown rewrite — content authoring model stays as generated ReScript files.
- No changes to Xote core itself (signals, router, SSR, etc.).
- No changes to the build / SSR pipeline.
- No changes to the demo modules' own visual styling (playing cards, snake game board, color-mixer sliders) — they keep their in-demo look; the surrounding page frame is redesigned.

## 12. Success criteria

- Running `npm run dev` shows the redesigned site.
- All `/docs/*` routes (minus removed demo routes) render in the new style in both light and dark mode.
- The home page renders the new hero, 4-card features grid, code example, and community close.
- Inline demos render in-prose inside at least one concept page with figure captions.
- Zero brand/accent hue anywhere in the default CSS — only neutrals (browser-native selection and focus-ring colors are acceptable if unmodified).
- WCAG contrast ratio ≥ 7:1 for body text against background in both modes.
- No broken routes (a navigation to `/docs/demos/*` either 404s cleanly or redirects — 404 is acceptable).
- The sidebar, header nav, and footer no longer reference demos.
