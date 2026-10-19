/***
A value that is either a plain value (`Static`) or a reactive signal
(`Reactive`).

The general "static or reactive" wrapper used across Xote. It is not tied to
component props — use it anywhere an API should accept both a plain value and a
signal. See `MaybeSignal.res` for when JSX needs the wrapper and when it does
not.

## Examples

```rescript
// An API that accepts either shape.
let describe = (label: MaybeSignal.t<string>) => "label: " ++ MaybeSignal.get(label)

describe(MaybeSignal.static("hello")) == "label: hello"

let title = Signal.make("hello")
describe(MaybeSignal.reactive(title)) == "label: hello"
```
*/

/**
Either a plain value or a signal carrying one.

The constructors are public, so `switch` gives exhaustiveness checking. Prefer
the `static` and `reactive` helpers when constructing.
*/
type t<'a> = Reactive(Signal.t<'a>) | Static('a)

/* ---------------------------------------------------------------- construct */

/**
Wraps a plain value. It never changes, so reading it registers no dependency.

## Examples

```rescript
let label = MaybeSignal.static("Submit")
MaybeSignal.get(label) == "Submit"
MaybeSignal.isStatic(label) == true
```
*/
let static: 'a => t<'a>

/**
Wraps a signal. Reading it registers a dependency on that signal.

## Examples

```rescript
let count = Signal.make(0)
let value = MaybeSignal.reactive(count)

MaybeSignal.get(value) == 0
Signal.set(count, 3)
MaybeSignal.get(value) == 3
```
*/
let reactive: Signal.t<'a> => t<'a>

/**
Derives a reactive value from a computation, so callers do not have to spell
out `reactive(Computed.make(fn))`. `fn` runs once immediately.

## Examples

```rescript
let count = Signal.make(2)
let doubled = MaybeSignal.computed(() => Signal.get(count) * 2)

MaybeSignal.get(doubled) == 4
Signal.set(count, 5)
MaybeSignal.get(doubled) == 10
```
*/
let computed: (unit => 'a) => t<'a>

/* ------------------------------------------------------------------- branch */

/**
The total branch over the two cases, and how `get` and `peek` are built.

The two callbacks are the inverses of the `static` and `reactive` constructors,
so `~reactive` receives the `Signal.t` rather than its value.

`switch` on the constructors is equally idiomatic and gives you exhaustiveness
checking; reach for `fold` when it reads better in a pipe.

## Examples

```rescript
// Lift either case into a signal you own.
let toOwnSignal = (value: MaybeSignal.t<'a>) =>
  MaybeSignal.fold(value, ~static=v => Signal.make(v), ~reactive=s => s)

let fromStatic = toOwnSignal(MaybeSignal.static(1))
Signal.get(fromStatic) == 1

// Describing the case without reading the value.
let kind = value => MaybeSignal.fold(value, ~static=_ => "static", ~reactive=_ => "reactive")
kind(MaybeSignal.static(1)) == "static"
```
*/
let fold: (t<'a>, ~static: 'a => 'b, ~reactive: Signal.t<'a> => 'b) => 'b

/* --------------------------------------------------------------------- read */

/**
Reads the current value, registering a dependency when `Reactive`.

This is what an API should call when it wants the value to drive an update:
`Static` reads once, `Reactive` subscribes the surrounding observer.

## Examples

```rescript
MaybeSignal.get(MaybeSignal.static(7)) == 7

let count = Signal.make(7)
MaybeSignal.get(MaybeSignal.reactive(count)) == 7
```
*/
let get: t<'a> => 'a

/**
Reads the current value without registering a dependency.

The `MaybeSignal` counterpart of `Signal.peek`.

## Examples

```rescript
let count = Signal.make(1)
let value = MaybeSignal.reactive(count)

Effect.run(() => {
  // Reads the latest value but does not re-run when `count` changes.
  Console.log(MaybeSignal.peek(value))
  None
})
```
*/
let peek: t<'a> => 'a

/**
True when the value is `Reactive`.

## Examples

```rescript
MaybeSignal.isReactive(MaybeSignal.reactive(Signal.make(0))) == true
MaybeSignal.isReactive(MaybeSignal.static(0)) == false
```
*/
let isReactive: t<'a> => bool

/**
True when the value is `Static`. The complement of `isReactive`.

## Examples

```rescript
MaybeSignal.isStatic(MaybeSignal.static(0)) == true
MaybeSignal.isStatic(MaybeSignal.reactive(Signal.make(0))) == false
```
*/
let isStatic: t<'a> => bool

/* ---------------------------------------------------------------- transform */

/**
Transforms the wrapped value, preserving staticness.

A `Static` input maps eagerly and stays `Static`. A `Reactive` result is backed
by a `Computed` that stays subscribed until `Computed.dispose`.

## Examples

```rescript
let shout = MaybeSignal.map(MaybeSignal.static("hi"), s => String.toUpperCase(s))
MaybeSignal.get(shout) == "HI"
MaybeSignal.isStatic(shout) == true

let count = Signal.make(2)
let label = MaybeSignal.map(MaybeSignal.reactive(count), n => Int.toString(n))
MaybeSignal.get(label) == "2"
MaybeSignal.isReactive(label) == true
```
*/
let map: (t<'a>, 'a => 'b) => t<'b>

/**
The underlying signal, when there is one.

Returns the source signal for `Reactive` and `None` for `Static`, because a
plain value has no signal. To lift a `Static` value into one explicitly, write
`fold(value, ~static=v => Signal.make(v), ~reactive=s => s)`.

## Examples

```rescript
let count = Signal.make(0)
MaybeSignal.toSignal(MaybeSignal.reactive(count)) == Some(count)
MaybeSignal.toSignal(MaybeSignal.static(0)) == None
```
*/
let toSignal: t<'a> => option<Signal.t<'a>>

/**
Normalizes an untyped value into a `t`.

Accepts a raw value, a `Signal.t`, a `unit => 'a` thunk, or an already-wrapped
`t`. This is the coercion the JSX runtimes apply to props. Deliberately
unchecked: in typed code prefer `static`, `reactive` or `computed`.

## Examples

```rescript
// A raw value becomes `Static`.
let fromRaw: MaybeSignal.t<int> = MaybeSignal.ofUnknown(1)
MaybeSignal.isStatic(fromRaw) == true

// A signal becomes `Reactive`.
let count = Signal.make(1)
let fromSignal: MaybeSignal.t<int> = MaybeSignal.ofUnknown(count)
MaybeSignal.isReactive(fromSignal) == true

// A thunk becomes `Reactive`, backed by a computed.
let fromThunk: MaybeSignal.t<int> = MaybeSignal.ofUnknown(() => Signal.get(count) * 2)
MaybeSignal.get(fromThunk) == 2
```
*/
let ofUnknown: 'input => t<'a>
