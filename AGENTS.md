# AGENTS.md

Instructions for AI coding agents working on this repository. This file complements `CLAUDE.md`, which contains the comprehensive project reference (architecture, APIs, patterns, and examples). **Read `CLAUDE.md` first** - this file adds agent-specific workflow guidance.

## Quick Reference

- **Language**: ReScript (`.res` files) compiled to JavaScript (`.res.mjs` files)
- **Reactivity**: [rescript-signals](https://github.com/brnrdog/rescript-signals) - `Signal`, `Computed`, `Effect`
- **Build**: `npm run res:build` (ReScript) then `npm run build` (Vite)
- **Watch**: `npm run res:dev` for ReScript watch mode
- **Public API**: Only `Xote` module is exported; internal modules use `Xote__` prefix

## Before Making Changes

1. **Read `CLAUDE.md`** for full architecture, module descriptions, API surface, and code patterns
2. **Compile first**: Always run `npm run res:build` before testing or building
3. **Understand the module boundary**: Only `src/Xote.res` is the public API. Internal modules (`Xote__Component`, `Xote__JSX`, etc.) are implementation details

## Development Workflow

### Making Changes
1. Edit `.res` source files in `src/`
2. Run `npm run res:build` to compile
3. Check for compiler errors - ReScript has a strict type system
4. Run `npm run dev` to test in browser if needed

### Key Files
| File | Purpose |
|------|---------|
| `src/Xote.res` | Public API - re-exports all modules |
| `src/Xote__Component.res` | Core rendering, virtual DOM, reconciliation |
| `src/Xote__JSX.res` | JSX v4 transform and Elements module |
| `src/Xote__Router.res` | Client-side routing |
| `src/Xote__SSR.res` | Server-side rendering |
| `src/Xote__Hydration.res` | Client-side hydration |
| `src/Xote__SSRState.res` | Server-client state transfer |
| `src/Xote__ReactiveProp.res` | Static/Reactive prop wrapper |
| `rescript.json` | ReScript compiler configuration |
| `vite.config.js` | Library build configuration |

### Common Pitfalls
- **Forgetting to compile**: `.res.mjs` files are generated - edit `.res` files, not `.res.mjs`
- **Effect return type**: Effects must return `option<unit => unit>`, not `unit`. Return `None` when no cleanup is needed.
- **Signal reads in effects**: Use `Signal.get` (creates dependency) vs `Signal.peek` (no dependency). Using `get` inside an effect will re-run the effect when the signal changes.
- **Owner disposal**: When removing DOM elements with reactive state, ensure the owner system cleans up (handled automatically by `Render.disposeElement`)
- **Router init**: `Router.init()` must be called before any routing functions. Forgetting this will log warnings.
- **Boolean attributes**: Use string `"true"`/`"false"` - the `setAttrOrProp` function handles the conversion to proper DOM behavior

## Code Style

- Follow existing patterns in the codebase
- Use `/* */` comments (ReScript style), not `//` for documentation comments
- Internal modules: `Xote__ModuleName` naming convention
- Keep the public API minimal - expose through `Xote.res` only
- Prefer structural types over nominal when possible in ReScript

## Testing Changes

There is no test suite currently. Verify changes by:
1. Successful ReScript compilation (`npm run res:build`)
2. Successful Vite build (`npm run build`)
3. Manual testing with demo apps (`npm run dev`)
4. For SSR changes, check the `examples/ssr/` setup
