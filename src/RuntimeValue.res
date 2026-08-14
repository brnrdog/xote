let isNullish = (value: 'value): bool => {
  ignore(value)
  %raw(`value == null`)
}

let isObject = (value: 'value): bool => {
  ignore(value)
  %raw(`value !== null && typeof value === "object"`)
}

let objectHasTag = (obj: {..}, tag: string): bool => {
  let dict: Dict.t<string> = Obj.magic(obj)
  dict->Dict.get("TAG") == Some(tag)
}

/* Detects a `MaybeSignal.t` at runtime by its variant tag. Used where JSX hands
 us untyped values that may be raw, a signal, a function, or a `MaybeSignal.t`. */
let isMaybeSignal = (value: 'value): bool => {
  if isObject(value) {
    let obj: {..} = Obj.magic(value)
    obj->objectHasTag("Static") || obj->objectHasTag("Reactive")
  } else {
    false
  }
}

/* Variant tag of a value, when it is a tagged variant at all. Used to tell one
 runtime-shaped variant from another where JSX hands us untyped values. */
let getTag = (value: 'value): option<string> =>
  if isObject(value) {
    let dict: Dict.t<string> = Obj.magic(value)
    dict->Dict.get("TAG")
  } else {
    None
  }

let isFunction = (value: 'value): bool => {
  ignore(value)
  %raw(`typeof value === "function"`)
}

/* Detects a `Signal.t` by its shape. Structural rather than "any object", so a
 plain record handed to an untyped prop is treated as a value instead of being
 silently read as a signal. */
let isSignalLike = (value: 'value): bool =>
  if isObject(value) {
    let dict: Dict.t<Obj.t> = Obj.magic(value)
    dict->Dict.get("subs")->Option.isSome &&
    dict->Dict.get("value")->Option.isSome &&
    switch dict->Dict.get("equals") {
    | Some(equals) => isFunction(equals)
    | None => false
    }
  } else {
    false
  }

let getField = (props: 'props, key: string): option<'value> => {
  let dict: Dict.t<'value> = Obj.magic(props)
  dict->Dict.get(key)
}
