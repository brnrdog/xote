# Proposal: Signal-typed values as reactive leaves

| | |
|---|---|
| **Status** | Explored and **not kept**. The inference described below was built, tested and then removed; what shipped instead is the `%` mark ([`ppx/README.md`](../../ppx/README.md#the--signal-mark-poc)), which needs no type knowledge and reaches further. This document is the design record: the question, what was measured, and why the answer moved. |
| **Related** | [Auto-tracked view blocks](./tracked-blocks.md) — the design that produced `View.tracked` and `@xote.component`; `ppx/README.md` "Not settled yet". |

## Verdict

The inference worked, and was removed anyway. Three measurements decided it.

**Most of what it bought was already there.** A signal handed straight to Xote
— `class={theme}`, `{count}`, from any module — is read by the *runtime*,
which coerces the value where it receives it. That was true in 7.1, before any
of this. The inference changed the emitted code for those positions and not
their behaviour.

**What remained was the compound case**, `class={[a, b]->Array.join(", ")}`,
where the value goes to `Array.join` rather than to Xote. No dispatch can help
there, so something has to say "read this" — and the `%` mark says it in one
character, with no type knowledge, reaching cross-module signals and record
fields that inference structurally cannot.

**The cost was concentrated in the delicate part.** The inference needed an
evidence analysis for which callee takes a signal and which takes a value, plus
shadowing bookkeeping for every binding form — about 400 lines, and the part
most likely to break on code nobody wrote yet. The mark needs none of it.

So the ppx keeps the three things only it can do: mixed bare children in one
element (ReScript collects an element's children into one array, so only a
per-child wrapper breaks the type), thunk-free compound leaves, and automatic
`View.tracked` around a conditional. Everything else about a signal in JSX
position belongs to the runtime.

## The question

`@xote.component` decomposes JSX into fine-grained leaves by finding *reads* —
a `Signal.get(x)` written in a leaf. What would it take for the annotation to
also understand *signals*: a prop or binding whose type is `Signal.t`, used
without an explicit read? Concretely, could this compile and behave as the
comments say:

```rescript
@xote.component
let make = (~propA: Signal.t<string>, ~propB: string, ~propC: Signal.t<bool>) =>
  <>
    <div
      class={propB}              /* static: a plain string */
      data-hidden={propC}>       /* updates with propC, renders "true"/"false" */
      {propA}                    /* updates with propA */
    </div>
    <div class={[propA, propB]->Array.join(", ")}>  /* updates with propA */
      {propB}                    /* static, rendered once */
    </div>
  </>
```

## What already worked, and what did not

Three of the five lines worked before this change, for a reason worth
knowing: **the runtime duck-types a bare signal**. `class={propB}` is a static
attribute. `hidden={propC}` reaches `RuntimeJsxProp.toBoolAttr`, which calls
`MaybeSignal.ofUnknown` and recognises the signal by shape. `{propA}` is
emitted as `View.child(propA)` (an identifier is "inert": not thunked, not
probed) and `View.child` recognises the signal by shape too. None of that
involves the ppx, and none of it is type-checked — a `MaybeSignal.t` prop in
the same position renders `[object Object]`, because the wrapper's shape is
not a signal's.

Two lines did not work:

- `class={[propA, propB]->Array.join(", ")}` is a **type error**
  (`array<Signal.t<string>>` against `string`). Even if it typed, no
  `Signal.get` is visible, so the ppx would leave it static. This is the real
  gap: an expression that *uses* a signal-typed name.
- `data-hidden={propC}` fails because `XoteJSX.Elements.props` has no such
  field. ReScript 12 does parse hyphenated JSX attributes — the error is a
  record-field lookup, not a syntax error — which means the ppx, running
  before the JSX transform, sees the attribute as an ordinary labelled
  argument and can move it.

## The mechanism

The ppx is syntactic and has no type checker. It does have two sources of type
information it was not using: **annotations** (`~count: Signal.t<int>`,
`let x: Signal.t<int> = …`) and **constructors it knows** (`Signal.make`,
`Computed.make`, `SSRState.signal`, `MaybeSignal.reactive/static/computed`).
The POC threads a *signal environment* through the existing traversal —
scoped exactly like the alias environment that already tracks `let g =
Signal.get` and `module S = Signal` — and adds one rewrite:

> Inside a value leaf, an eager occurrence of a signal-typed name is replaced
> by `<path>.get(name)`, carrying the identifier's source location.

Then nothing else changes. The leaf now visibly reads a signal, so the rules
that already exist thunk it into `View.computedAttr` or reactive text, and a
condition that reads one gets `View.tracked`. The emitted code for the example
above is exactly what a user would have written by hand:

```js
Elements.jsx("div", {
  class: propB,
  attrs: [["data-hidden", () => Signal.get(propC)]],
  children: View.child(() => Signal.get(propA)),
});
Elements.jsx("div", {
  class: () => [Signal.get(propA), propB].join(", "),
  children: View.child(propB),
});
```

Three design decisions fell out of making that rewrite safe:

1. **Where it applies.** Only in the positions the ppx already treats as value
   leaves (intrinsic attributes, bare children, `View.Text/…` children) and in
   control-flow conditions in node position. Not in lambdas (deferred code is
   the user's), not in event handlers / `attrs` / `data` (never leaves), not in
   user-component props (never rewritten — passing the signal is how a prop
   becomes reactive), and not outside JSX at all.
2. **Which callees get the value.** `Signal.peek(count)` must stay
   `Signal.peek(count)`, and — the constraint an adversarial review of the
   first draft added — nothing that compiles today may stop compiling. So a
   name is read only where the ppx can justify it: a bare leaf, a condition,
   a structural position, an operand, a callback, a stdlib argument. The bare
   arguments of a signal-aware callee keep the signal; so does anything under
   a `(count: Signal.t<_>)` constraint. A *local* function is read by what its
   body says about the parameter (annotated `Signal.t` or handed to a read →
   the signal; annotated otherwise or used as a value → read; no evidence →
   left alone), and a function from another module is opaque: its argument is
   left as written and the call is probed, exactly as before. The pipe
   reaches the ppx as an operator application (`APPLY(|.)[count, Signal.get]`),
   so `x->f` is given the same treatment as `f(x)`.
3. **Shadowing.** `name`, `count`, `items` are common names for signals *and*
   for rows. A lambda parameter, a `switch` payload, a local `let`, a tuple or
   record pattern all remove the name; the traversal's binding forms
   (`Pexp_fun`, `Pexp_match`, `Pexp_let`) thread that through, including
   inside the render-callback and node-shaped walks that previously did not
   carry environment.

Hyphenated attributes are a separate, smaller piece: on an intrinsic element,
a labelled argument whose name contains `-` is appended to the `attrs` array
(created if absent, extended if present), with its value passed through the
same leaf rules and then `Obj.magic`, because every `attrs` entry shares one
type and the runtime coercion accepts any shape anyway.

## Alternatives considered

- **Leave it to the runtime.** Bare signals already work by shape detection.
  This does nothing for derived expressions, which are the actual request,
  and it is invisible in the emitted code and unchecked by the compiler.
  Rejected as the whole answer; the POC keeps the runtime path as a fallback
  for code the ppx cannot see.
- **A typed `data-*` / `aria-*` surface in `Elements.props`.** A record cannot
  have wildcard fields, and `Elements.props` already carries ~100 type
  parameters. The `attrs` escape hatch exists precisely for this; routing
  into it costs one `Obj.magic` per relocated entry.
- **A per-prop marker (`@signal` on the parameter) instead of reading the type.**
  Explicit, but redundant with the annotation the user already wrote, and it
  would not cover `let x = Signal.make(…)` in a body. The type annotation *is*
  the marker.
- **Rewriting everywhere, not just in leaves.** `let s = [propA, propB]->…`
  above the JSX would then also read. This changes the meaning of ordinary
  ReScript, makes a component body's evaluation order depend on the ppx, and
  contradicts "component bodies run once, untracked". Rejected; the boundary
  is the same one the README already teaches for hoisted reads.
- **Reading the argument of every unknown callee** (the first draft). It
  makes `format(count)` work for a value-taking helper from another module,
  but it breaks `Store.wrap(count)` — a helper written against the signal,
  which compiles today via the probe — with a type error that contradicts
  the source, and the documented `() => …` escape hatch does not help a
  helper that returns a wrapper (the thunk then yields the wrapper, which
  renders as `[object Object]`). Rejected after review in favour of the
  evidence rules above: a stdlib call and a local function with a
  value-shaped parameter are read, anything opaque is left alone.
- **Stopping at every lambda** (also the first draft). `xs->Array.map(x =>
  x ++ suffix)` is the most ordinary way to build a class string, and the
  callback runs while the leaf is evaluated; treating it as deferred made
  the natural spelling a type error. Only `() => …` is deferred now.

## What the POC establishes

- The user's example compiles verbatim (with a fragment root) and behaves as
  annotated, with every element keeping its identity across updates.
- Zero regressions: all previously-existing `example/` cases, the docs site
  (a real consumer with top-level `Signal.make` bindings and many components)
  and the library test suite compile and pass unchanged. A component that
  never annotates a prop as `Signal.t` and never binds a signal in a body is
  untouched by construction.
- `MaybeSignal.t` props become usable bare, which was a silent runtime failure
  before.

## The other end: a mark instead of inference

Everything above infers. The complement is to let the author say it, which is
what the `%` mark does (`ppx/README.md`, "The `%` signal mark"): `%theme` is
rewritten to `Signal.get(theme)` before any other rule runs, and the existing
machinery takes it from there.

The notation was chosen by measuring the parser rather than picking a
character. `@theme` does not parse — an attribute needs a name *and* a target —
and `@@theme` is the file-level attribute form. `@live theme` parses and binds
to the identifier alone, but puts the mark beside the name instead of on it,
and an attribute nobody consumes is **silently dropped** by ReScript, which is
the failure mode this project keeps designing away. `%theme` parses everywhere
the mark is wanted (attribute, child, scrutinee, interpolation, array element,
pipe), carries the name inside the mark, is the character the language reserves
for ppxes, and an extension nobody expands is a compile error.

What the mark buys over inference is not ergonomics — it is reach. It needs no
type knowledge at all, so it crosses the boundary above: `%Store.waiting`,
`%store.count`, a signal behind a path or an alias. It is also one rule instead
of a page of them.

The two agree where they overlap, since a marked name is already a read by the
time inference looks. The open question is whether the mark should replace the
inference rules rather than sit beside them — most of this document's
complexity exists to make inference safe, and the mark needs none of it.

## Still open

- **Opaque callees.** A value-taking helper from another module
  (`Store.format(count)`) is left alone, so it needs an explicit
  `Signal.get(count)` — the ppx cannot tell it from `Store.wrap(count)`. A
  per-function hint (an annotation on the helper, or interface-file
  knowledge) would close that gap; the runtime probe still reports the
  frozen-leaf case as before.
- **Two things surfaced by the review and fixed on the way.** The server
  renderer threw on any non-string attribute value (`replaceAll` on a
  boolean) — a pre-existing hole for hand-written `attrs` entries that the
  hyphenated-attribute route would have made the default; it now stringifies
  as the client does. And the same-file module collector derived a module's
  names by set difference against the outer scope, which dropped
  `Store.count` whenever a top-level `count` existed (and, before this
  change, `Store.helper()` whenever a top-level `helper` did).
- **Cross-module signals are a boundary, not a gap.** `Store.waiting`
  defined in another file is unknown to the ppx, which runs on one file's
  syntax tree before type checking; only the type checker knows what it is,
  and ReScript exposes no post-typing hook to external ppxes. Reading the
  compiler's `.cmi` for `Store` from the build directory is technically
  possible but would couple the ppx to the compiler's internal type
  representation and the build layout on top of the parsetree ABI it
  already vendors — a maintenance liability, not a plan. Reading `.resi`
  files is worse (an interface is optional, and the common store module has
  none), and a hand-maintained list of known signals is a second source of
  truth. So the design owns the boundary: the ppx's type knowledge is
  file-local by construction — props, locals, same-file stores, which is
  where most signal use in a component lives — and a cross-module signal
  follows the rule the ppx already has for hidden reads: bare use works
  through the runtime, a derived expression writes `Signal.get(Store.waiting)`
  (a visible read, so the leaf is reactive), and forgetting it is an
  immediate type error rather than a stale leaf. Example case 44 pins this.
- **Type aliases and structure.** `type counter = Signal.t<int>`, a signal
  inside a record field (`store.count`), or one returned by a function are
  invisible for the same reason; they keep working by the runtime path when
  bare, and stay a type error when derived. Following a `type` alias declared
  in the same file is the one cheap extension.
- **User-component props.** `<View.Show when_={open_}>` could become
  `when_={MaybeSignal.reactive(open_)}` under the same knowledge. Left out
  because the target prop type is unknown to the ppx and the current rule
  ("never touch user-component props") is a documented contract.
- **`Obj.magic` in relocated attributes.** Correct at runtime and still
  type-checks the inner expression, but it is a cast in generated code. A
  typed alternative would need `attrs` to accept a heterogeneous entry type,
  which is a library API change.
- **The boundary itself.** "Reactive inside JSX, a type error one line above
  it" is predictable once learned, and consistent with the hoisting rule, but
  it is the part most likely to surprise. Worth watching in real code before
  freezing.
