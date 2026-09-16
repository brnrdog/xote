# Proposal: automatic signal unwrapping in `@xote.component`

| | |
|---|---|
| **Status** | Explored and **not adopted**. Two mechanisms were built, tested and removed: type-directed inference from annotations, and a `%` mark. Neither ships; what the investigation did change is the runtime, where the one real gap was. This document is the record — the question, what was measured, and why the answer moved. |
| **Related** | [Auto-tracked view blocks](./tracked-blocks.md) — the design that produced `View.tracked` and `@xote.component`; [forum thread](https://forum.rescript-lang.org/t/introducing-xote-7-1/7558) where the question was raised. |

## Verdict

Neither mechanism was worth its weight, for one reason that only became clear
by measuring: **most of what they promised already worked**.

A signal handed straight to Xote — `class={theme}`, `{count}`, from any module
— is read by the *runtime*, which coerces the value where it receives it. That
was true in 7.1. Both mechanisms changed the emitted code for those positions
and not their behaviour.

What is left is the compound case, `class={[a, b]->Array.join(", ")}`, where
the value goes to `Array.join` rather than to Xote. Nothing can dispatch there,
because the consumer is ordinary ReScript that wants a string. So the read has
to be written, and `Signal.get(a)` is the honest way to write it — which the
ppx already turns into a fine-grained leaf.

The investigation did find one genuine hole and one genuine bug, both in the
runtime rather than the compiler:

- `View.child` rendered a `MaybeSignal.t` as `[object Object]`. An untyped
  attribute already read the wrapper; a child did not.
- The server's attribute escaper threw on a non-string value, so a bool signal
  in an `attrs` entry broke SSR.

Both are fixed. With those closed, the boundary is complete, and the ppx is
left doing the three things only it can: mixed bare children in one element
(ReScript collects an element's children into one array, so only a per-child
wrapper breaks the type), thunk-free compound leaves, and automatic
`View.tracked` around a conditional.

## What was tried

**Type-directed inference.** The ppx can see annotations (`~count:
Signal.t<int>`) and constructors it knows (`Signal.make`, `Computed.make`), so
a name it can tell holds a signal could be read automatically inside a leaf.
This worked, and cost about 400 lines: an evidence analysis deciding which
callee takes a signal and which takes a value, plus shadowing bookkeeping for
every binding form. It also could not see past the file, which is where a
store usually lives.

**A `%` mark.** `%theme`, `%Store.tone`, `%store.count`, `{switch %user {…}}`,
rewritten to `Signal.get(…)` before any other rule. One rule, no inference, and
it reached cross-module signals and record fields that inference structurally
cannot. The notation was picked by measuring the parser: `@theme` does not
parse (an attribute needs a name *and* a target), `@@theme` is the file-level
form, `@live theme` parses but sits beside the name and is silently dropped
when unconsumed, and `%theme` carries the name inside the mark, is the
character ReScript reserves for ppxes, and errors loudly if nothing expands it.

Both were dropped once it was clear they only bought the compound case, where
an explicit `Signal.get` reads fine and costs nothing to maintain.

## Why the compiler cannot simply know

A ppx runs on one file's syntax tree, before type checking, so "is this a
`Signal.t`?" is a question it cannot answer in general; only the type checker
can, and ReScript exposes no post-typing hook. Nor can the type system dispatch
on it: there is no overloading, and untagged variants reject `Signal.t` because
it is abstract and the compiler cannot categorise its runtime shape.

Reading the compiler's `.cmi` output would technically work and would couple
the ppx to the compiler's internal type representation on top of the parsetree
ABI it already vendors. A hand-maintained list of known signals is a second
source of truth. Neither is a plan.

What *can* dispatch is the runtime, because Xote owns the receiving end. That
is where this ended up, and it is why the useful changes are in `src/` rather
than in `ppx/`.
