open Signals

/* ============================================================================
 * SSR State Serialization
 *
 * Transfers signal values from server to client so hydration starts with
 * correct state. Signals are registered with string IDs, serialized to JSON
 * on the server, and restored on the client before hydration.
 * ============================================================================ */

/* ============================================================================
 * Built-in Codecs
 * ============================================================================ */

module Codec = {
  type t<'a> = {
    encode: 'a => JSON.t,
    decode: JSON.t => option<'a>,
  }

  /* Primitive codecs */

  let int: t<int> = {
    encode: v => JSON.Encode.int(v),
    decode: json => {
      switch JSON.Decode.float(json) {
      | Some(n) => Some(Float.toInt(n))
      | None => None
      }
    },
  }

  let float: t<float> = {
    encode: v => JSON.Encode.float(v),
    decode: json => JSON.Decode.float(json),
  }

  let string: t<string> = {
    encode: v => JSON.Encode.string(v),
    decode: json => JSON.Decode.string(json),
  }

  let bool: t<bool> = {
    encode: v => JSON.Encode.bool(v),
    decode: json => JSON.Decode.bool(json),
  }

  /* Collection codecs */

  let array = (itemCodec: t<'a>): t<array<'a>> => {
    encode: arr => arr->Array.map(itemCodec.encode)->JSON.Encode.array,
    decode: json => {
      switch JSON.Decode.array(json) {
      | Some(arr) => {
          let decoded = arr->Array.filterMap(itemCodec.decode)
          if Array.length(decoded) == Array.length(arr) {
            Some(decoded)
          } else {
            None
          }
        }
      | None => None
      }
    },
  }

  let option = (itemCodec: t<'a>): t<option<'a>> => {
    encode: opt => {
      switch opt {
      | Some(v) => itemCodec.encode(v)
      | None => JSON.Encode.null
      }
    },
    decode: json => {
      if JSON.Decode.null(json)->Option.isSome {
        Some(None)
      } else {
        itemCodec.decode(json)->Option.map(v => Some(v))
      }
    },
  }

  /* Tuple codecs */

  let tuple2 = (codec1: t<'a>, codec2: t<'b>): t<('a, 'b)> => {
    encode: ((a, b)) => JSON.Encode.array([codec1.encode(a), codec2.encode(b)]),
    decode: json => {
      let arr: option<array<JSON.t>> = %raw(`Array.isArray(json) ? json : undefined`)
      switch arr {
      | Some([j1, j2]) =>
        switch (codec1.decode(j1), codec2.decode(j2)) {
        | (Some(a), Some(b)) => Some((a, b))
        | _ => None
        }
      | _ => None
      }
    },
  }

  let tuple3 = (codec1: t<'a>, codec2: t<'b>, codec3: t<'c>): t<('a, 'b, 'c)> => {
    encode: ((a, b, c)) =>
      JSON.Encode.array([codec1.encode(a), codec2.encode(b), codec3.encode(c)]),
    decode: json => {
      let arr: option<array<JSON.t>> = %raw(`Array.isArray(json) ? json : undefined`)
      switch arr {
      | Some([j1, j2, j3]) =>
        switch (codec1.decode(j1), codec2.decode(j2), codec3.decode(j3)) {
        | (Some(a), Some(b), Some(c)) => Some((a, b, c))
        | _ => None
        }
      | _ => None
      }
    },
  }

  /* Dict codec */

  let dict = (valueCodec: t<'a>): t<Dict.t<'a>> => {
    encode: d => {
      let obj = Dict.make()
      d
      ->Dict.toArray
      ->Array.forEach(((k, v)) => {
        obj->Dict.set(k, valueCodec.encode(v))
      })
      JSON.Encode.object(obj)
    },
    decode: json => {
      switch JSON.Decode.object(json) {
      | Some(obj) => {
          let result = Dict.make()
          let success = ref(true)
          obj
          ->Dict.toArray
          ->Array.forEach(((k, v)) => {
            switch valueCodec.decode(v) {
            | Some(decoded) => result->Dict.set(k, decoded)
            | None => success := false
            }
          })
          if success.contents {
            Some(result)
          } else {
            None
          }
        }
      | None => None
      }
    },
  }

  /* Custom codec constructor */

  let make = (~encode: 'a => JSON.t, ~decode: JSON.t => option<'a>): t<'a> => {
    encode,
    decode,
  }
}

/* ============================================================================
 * State Registry (Server-side)
 * ============================================================================ */

let registry: Dict.t<JSON.t> = Dict.make()

/* Register a signal for serialization (server only) */
let register = (id: string, signal: Signal.t<'a>, codec: Codec.t<'a>): unit => {
  if Xote__SSRContext.isServer {
    registry->Dict.set(id, codec.encode(Signal.peek(signal)))
  }
}

/* Clear the registry (useful for multiple renders) */
let clear = (): unit => {
  registry->Dict.keysToArray->Array.forEach(key => {
    registry->Dict.delete(key)->ignore
  })
}

/* ============================================================================
 * Script Generation (Server-side)
 * ============================================================================ */

/* Escape string for safe embedding in script tag */
let escapeForScript = (str: string): string => {
  str
  ->String.replaceAll("</script>", "<\\/script>")
  ->String.replaceAll("<!--", "<\\!--")
}

/* Generate script tag with serialized state */
let generateScript = (~nonce: option<string>=?): string => {
  let json = JSON.stringifyAny(registry)->Option.getOr("{}")
  let escapedJson = escapeForScript(json)
  let nonceAttr = switch nonce {
  | Some(n) => ` nonce="${Xote__SSR.Html.escape(n)}"`
  | None => ""
  }
  `<script${nonceAttr}>window.__XOTE_STATE__=${escapedJson};</script>`
}

/* ============================================================================
 * State Restoration (Client-side)
 * ============================================================================ */

/* Get the serialized state from window */
let getClientState = (): Dict.t<JSON.t> => {
  if Xote__SSRContext.isClient {
    %raw(`window.__XOTE_STATE__ || {}`)
  } else {
    Dict.make()
  }
}

/* Restore a signal from serialized state (client only) */
let restore = (id: string, signal: Signal.t<'a>, codec: Codec.t<'a>): unit => {
  if Xote__SSRContext.isClient {
    let state = getClientState()
    switch state->Dict.get(id) {
    | Some(json) =>
      switch codec.decode(json) {
      | Some(value) => Signal.set(signal, value)
      | None => () /* Silent fallback to default */
      }
    | None => () /* Silent fallback to default */
    }
  }
}

/* ============================================================================
 * Unified API
 * ============================================================================ */

/* Sync a signal: register on server, restore on client */
let sync = (id: string, signal: Signal.t<'a>, codec: Codec.t<'a>): unit => {
  Xote__SSRContext.match(
    ~server=() => register(id, signal, codec),
    ~client=() => restore(id, signal, codec),
  )
}

/* Create and sync a signal in one call */
let make = (id: string, initial: 'a, codec: Codec.t<'a>): Signal.t<'a> => {
  let signal = Signal.make(initial)
  sync(id, signal, codec)
  signal
}
