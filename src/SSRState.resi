/* Signal state transfer between server and client.

   Signals are registered under string ids, serialized into the HTML on the
   server, and restored on the client before hydration runs. */

module Codec: {
  type t<'a> = {
    encode: 'a => JSON.t,
    decode: JSON.t => option<'a>,
  }

  let int: t<int>
  let float: t<float>
  let string: t<string>
  let bool: t<bool>

  let array: t<'a> => t<array<'a>>
  let option: t<'a> => t<option<'a>>
  let tuple2: (t<'a>, t<'b>) => t<('a, 'b)>
  let tuple3: (t<'a>, t<'b>, t<'c>) => t<('a, 'b, 'c)>
  let dict: t<'a> => t<Dict.t<'a>>

  let make: (~encode: 'a => JSON.t, ~decode: JSON.t => option<'a>) => t<'a>
}

/* Register a signal for serialization (server only) */
let register: (string, Signal.t<'a>, Codec.t<'a>) => unit

/* Reset the registry - call between renders on the server */
let clear: unit => unit

/* `<script>` tag carrying the serialized state as `window.__XOTE_STATE__` */
let generateScript: (~nonce: string=?) => string

/* Read the serialized state written by `generateScript` (client only) */
let getClientState: unit => Dict.t<JSON.t>

/* Restore a signal from the serialized state (client only) */
let restore: (string, Signal.t<'a>, Codec.t<'a>) => unit

/* Register on the server, restore on the client */
let sync: (string, Signal.t<'a>, Codec.t<'a>) => unit

/* Create a signal and sync it in one call */
let signal: (string, 'a, Codec.t<'a>) => Signal.t<'a>
