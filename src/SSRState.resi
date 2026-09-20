/***
Signal state transfer between server and client.

Signals are registered under string ids, serialized into the HTML on the
server, and restored on the client before hydration runs — so the browser
starts from the state the server rendered instead of a default.

`sync` and `signal` are the everyday entry points: both do the right thing on
either side of the wire, so shared code needs no environment branch.

## Examples

```rescript
// Shared between server and client.
let count = SSRState.signal("counter", 0, SSRState.Codec.int)

// Server: after rendering, embed the state.
let stateScript = SSRState.generateScript()

// Client: `count` already holds the server's value by the time hydration runs.
```
*/

/**
Encoders and decoders for the values carried across the wire.

`decode` returns an `option`, so malformed or missing payloads leave a signal
at its default rather than throwing. Combinators compose, so container types
are built from the primitives.

## Examples

```rescript
let ints: SSRState.Codec.t<array<int>> = SSRState.Codec.array(SSRState.Codec.int)
let maybeName: SSRState.Codec.t<option<string>> = SSRState.Codec.option(SSRState.Codec.string)
let pair: SSRState.Codec.t<(int, string)> =
  SSRState.Codec.tuple2(SSRState.Codec.int, SSRState.Codec.string)
```
*/
module Codec: {
  /**
  A pair of functions converting a value to and from JSON.

  `decode` returns `None` when the JSON does not have the expected shape.
  */
  type t<'a> = {
    encode: 'a => JSON.t,
    decode: JSON.t => option<'a>,
  }

  /** Codec for `int`. */
  let int: t<int>

  /** Codec for `float`. */
  let float: t<float>

  /** Codec for `string`. */
  let string: t<string>

  /** Codec for `bool`. */
  let bool: t<bool>

  /**
  Lifts a codec to arrays. Decoding fails, returning `None`, if any element
  fails to decode.

  ## Examples

  ```rescript
  let codec = SSRState.Codec.array(SSRState.Codec.string)
  let tags = SSRState.signal("tags", ["a", "b"], codec)
  ```
  */
  let array: t<'a> => t<array<'a>>

  /**
  Lifts a codec to options, encoding `None` as JSON null.

  ## Examples

  ```rescript
  let codec = SSRState.Codec.option(SSRState.Codec.int)
  let selected = SSRState.signal("selected", None, codec)
  ```
  */
  let option: t<'a> => t<option<'a>>

  /**
  Lifts two codecs to a pair, encoded as a two-element JSON array.

  ## Examples

  ```rescript
  let codec = SSRState.Codec.tuple2(SSRState.Codec.string, SSRState.Codec.int)
  let entry = SSRState.signal("entry", ("a", 1), codec)
  ```
  */
  let tuple2: (t<'a>, t<'b>) => t<('a, 'b)>

  /**
  Lifts three codecs to a triple, encoded as a three-element JSON array.

  ## Examples

  ```rescript
  let codec = SSRState.Codec.tuple3(
    SSRState.Codec.string,
    SSRState.Codec.int,
    SSRState.Codec.bool,
  )
  let row = SSRState.signal("row", ("a", 1, true), codec)
  ```
  */
  let tuple3: (t<'a>, t<'b>, t<'c>) => t<('a, 'b, 'c)>

  /**
  Lifts a codec to a string-keyed dict, encoded as a JSON object.

  ## Examples

  ```rescript
  let codec = SSRState.Codec.dict(SSRState.Codec.int)
  let scores = SSRState.signal("scores", Dict.fromArray([("ada", 1)]), codec)
  ```
  */
  let dict: t<'a> => t<Dict.t<'a>>

  /**
  Builds a codec for a type the combinators do not cover, such as a record or
  a variant.

  ## Examples

  ```rescript
  type status = Draft | Published

  let statusCodec = SSRState.Codec.make(
    ~encode=status => JSON.String(
      switch status {
      | Draft => "draft"
      | Published => "published"
      },
    ),
    ~decode=json =>
      switch json {
      | JSON.String("draft") => Some(Draft)
      | JSON.String("published") => Some(Published)
      | _ => None
      },
  )
  ```
  */
  let make: (~encode: 'a => JSON.t, ~decode: JSON.t => option<'a>) => t<'a>
}

/**
Registers a signal for serialization. Server only; a no-op in the browser.

The `id` is the key the client restores from, so it must match the one passed
to `restore`. Prefer `sync`, which pairs the two automatically.

## Examples

```rescript
let count = Signal.make(3)
SSRState.register("counter", count, SSRState.Codec.int)
```
*/
let register: (string, Signal.t<'a>, Codec.t<'a>) => unit

/**
Resets the registry. Call between renders on the server.

Without this, a long-lived server process leaks state from one request's
signals into the next response.

## Examples

```rescript
let handleRequest = app => {
  SSRState.clear()
  SSR.renderToString(app)
}
```
*/
let clear: unit => unit

/**
A `<script>` tag carrying the serialized state as `window.__XOTE_STATE__`.

Emit it into the document — typically as `SSR.renderDocument`'s `~stateScript`
— after rendering, so every signal registered during the render is included.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

let html = SSR.renderDocument(~stateScript=SSRState.generateScript(), app)
let withNonce = SSRState.generateScript(~nonce="r4nd0m")
```
*/
let generateScript: (~nonce: string=?) => string

/**
Reads the serialized state written by `generateScript`. Client only.

Returns the raw JSON payload keyed by id, before decoding; an empty dict when
the page carries no state. Rarely needed directly — `restore` and `sync` read
it for you.

## Examples

```rescript
let state = SSRState.getClientState()
let raw = Dict.get(state, "counter")
```
*/
let getClientState: unit => Dict.t<JSON.t>

/**
Restores a signal from the serialized state. Client only; a no-op on the
server.

The signal keeps its current value when the id is absent or the payload fails
to decode, so a missing key degrades to the default rather than throwing.

## Examples

```rescript
let count = Signal.make(0)
SSRState.restore("counter", count, SSRState.Codec.int)
// If the server registered "counter" as 3, `count` now holds 3.
```
*/
let restore: (string, Signal.t<'a>, Codec.t<'a>) => unit

/**
Registers on the server, restores on the client.

The environment-agnostic pairing of `register` and `restore`, so shared code
calls one function regardless of where it runs.

## Examples

```rescript
let count = Signal.make(0)
SSRState.sync("counter", count, SSRState.Codec.int)
```
*/
let sync: (string, Signal.t<'a>, Codec.t<'a>) => unit

/**
Creates a signal and syncs it in one call.

`Signal.make` followed by `sync`, and the most convenient way to declare a
piece of state that must survive the trip from server to client.

## Examples

```rescript
let count = SSRState.signal("counter", 0, SSRState.Codec.int)
let tags = SSRState.signal("tags", [], SSRState.Codec.array(SSRState.Codec.string))

// The server's value on a hydrated page, 0 otherwise.
let current = Signal.get(count)
```
*/
let signal: (string, 'a, Codec.t<'a>) => Signal.t<'a>
