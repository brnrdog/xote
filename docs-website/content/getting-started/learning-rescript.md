ReScript is a strongly-typed language with full type inference, derived from OCaml, that compiles to readable JavaScript. It runs in any JavaScript host — browser, Node, Bun, edge runtimes — consumes npm packages directly, and slots into the bundlers and test runners you already use. The compiler is fast, typically sub-second on incremental builds, and refuses to emit programs whose types do not line up. A successful build is a real guarantee rather than a hint. What it changes is how precisely you can model data and program behavior before the code ships.

## Why It Matters Now

The case for a strongly-typed language is no longer only about catching bugs while you type. Code is increasingly read and written by AI agents alongside humans, and both work better when a codebase's rules are mechanical instead of implicit.

- For humans, types act as compressed documentation. A signature tells you which shapes a function accepts, what it returns, and which cases the caller has to handle — without scrolling through the implementation.
- For AI, types are a tight feedback loop. An agent that proposes a change can run the compiler, get a precise error pointing at the mismatched value, and correct itself before the code ever runs. Inference grounded in types is far more reliable than guesses pulled from naming conventions.
- For both, exhaustive `switch` and explicit `option` types collapse the surface area of unwritten assumptions. Less context has to live in someone's head — or someone's prompt — for the program to stay correct.

The compiler ends up doing the boring parts of code review: did you cover every variant, did you handle the missing value, did the field you renamed get updated everywhere it was used.

## A First Look

The point of ReScript is not just that types are nice. It gives you a way to model real program states so the compiler can enforce rules you would otherwise keep in your head.

In many codebases, a value like this ends up spread across string values, nullable fields, and defensive checks. It works until one branch is forgotten during a refactor. ReScript pushes that information into the type itself:

```rescript
type user =
  | Guest
  | SignedIn(string)
  | Banned(string)

let greeting = user =>
  switch user {
  | Guest => "Welcome, stranger"
  | SignedIn(name) => `Hello, ${name}`
  | Banned(reason) => `Access denied: ${reason}`
  }
```

A few things matter here:

- `type user` declares a *variant* — a closed set of cases. The compiler knows every value `user` can hold.
- `switch` matches each case directly. Add a new case to `user` later (say, `Suspended`), and the compiler points out every `switch` that no longer covers the type.
- The function reads like straightforward application code, but the guarantees are stronger: there is no ambiguity about what shape can arrive at runtime.
- Types are inferred, so `greeting` does not need an annotation. You get compiler help without turning the example into a wall of type syntax.

This is the practical case for ReScript: instead of relying on conventions, comments, or discipline to keep state handling correct, you encode the valid cases once and let the compiler enforce them everywhere.

Exhaustiveness checking is on by default. You cannot ship a `switch` with a missing case, which removes a whole class of forgotten-state bugs before the code runs.

## Let Bindings and Functions

Most values are declared with `let`. Functions take their arguments in parentheses.

```rescript
let count = 1
let add = (a, b) => a + b

let total = add(count, 41)
```

Bindings are immutable by default. That usually makes code easier to follow because values do not quietly change underneath you.

## Records

Records are object-like data with known fields:

```rescript
type user = {
  name: string,
  admin: bool,
}

let currentUser = {name: "Ada", admin: true}
```

Records pattern-match the same way variants do, with the same exhaustiveness guarantees.

## Matching on Multiple Values

[A First Look](#a-first-look) covered the basic variant + `switch` pair. The same construct also matches tuples, so you can branch on combinations of state in one place:

```rescript
type role =
  | Guest
  | Member
  | Admin

type page =
  | Home
  | Settings

let canView = (role, page) =>
  switch (role, page) {
  | (Guest, Home) => true
  | (Guest, Settings) => false
  | (Member, _) => true
  | (Admin, _) => true
  }
```

The `_` wildcard ignores cases you do not need to spell out, while the compiler still checks that every meaningful combination is covered.

## Options Instead of null

Missing values use `option<'a>`, with two cases: `Some(value)` and `None`.

```rescript
let maybeName: option<string> = Some("Ada")
let missingName: option<string> = None

let displayName = name =>
  switch name {
  | Some(value) => value
  | None => "Anonymous"
  }
```

This changes day-to-day code in a few practical ways:

- Missing values are explicit in the type, so you can see right away which values need handling.
- You cannot accidentally read through `undefined` at runtime. The compiler makes you handle `None` first.
- There is one absence model instead of juggling `null`, `undefined`, and missing keys.

You will see this often in optional arguments, lookups, and decoded data.

## Modules and Files

Each file becomes a module. A file named `Counter.res` exposes its values under `Counter`.

```rescript
/* Counter.res */
let initial = 0
let increment = count => count + 1

/* App.res */
let next = Counter.increment(Counter.initial)
```

You get namespacing by default, which keeps larger codebases from turning into import and naming sprawl.

## Why It's Worth It

Once the syntax clicks, the benefits are mostly about reducing ambiguity in the code:

- You model state directly instead of spreading it across booleans, strings, and nullable fields.
- Refactors are safer because the compiler shows you every affected branch.
- `option` removes a large class of `null` and `undefined` bugs.
- Types are inferred, so the code stays compact.
- The output still fits naturally into existing JavaScript tooling.

The payoff gets bigger as the codebase grows. The more branches, edge cases, and moving parts you have, the more valuable those guarantees become.

## Adding ReScript Incrementally

You do not need a rewrite to try it:

- A JS or TS app can import modules compiled from ReScript.
- ReScript targets the same runtime, bundler, and npm packages as the rest of your app.
- You can adopt it one module, feature, or library at a time.

That makes it easy to start with one bounded part of a codebase and expand only if it proves useful.

## Keep Learning

The official ReScript site covers the full language and toolchain:

- [Introduction](https://rescript-lang.org/docs/manual/v12.0.0/introduction)
- [Overview](https://rescript-lang.org/docs/manual/overview)
- [Pattern Matching / Destructuring](https://rescript-lang.org/docs/manual/pattern-matching-destructuring/)
- [Modules](https://rescript-lang.org/docs/manual/module/)
- [API Reference](https://rescript-lang.org/docs/manual/api/)

Once this page feels familiar, the next step inside Xote's docs is [Signals](/docs/core-concepts/signals), then [View](/docs/view/overview).
