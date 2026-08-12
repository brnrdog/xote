module Core = RescriptCore

let objectHasTag = (obj: {..}, tag: string): bool =>
  switch obj->Core.Object.get("TAG") {
  | Some(value) => value == tag
  | None => false
  }

/* Detects a `MaybeSignal.t` at runtime by its variant tag. Used where JSX hands
 us untyped values that may be raw, a signal, a function, or a `MaybeSignal.t`. */
let isMaybeSignal = (value: 'value): bool => {
  switch value->Core.Type.Classify.classify {
  | Object(obj) => {
      let obj: {..} = Obj.magic(obj)
      obj->Core.Object.hasOwnProperty("TAG") &&
        (obj->objectHasTag("Static") || obj->objectHasTag("Reactive"))
    }
  | _ => false
  }
}

/* Variant tag of a value, when it is a tagged variant at all. Used to tell one
 runtime-shaped variant from another where JSX hands us untyped values. */
let getTag = (value: 'value): option<string> =>
  switch value->Core.Type.Classify.classify {
  | Object(obj) => {
      let obj: {..} = Obj.magic(obj)
      obj->Core.Object.get("TAG")
    }
  | _ => None
  }

let isFunction = (value: 'value): bool =>
  switch value->Core.Type.Classify.classify {
  | Function(_) => true
  | _ => false
  }

/* Detects a `Signal.t` by its shape. Structural rather than "any object", so a
 plain record handed to an untyped prop is treated as a value instead of being
 silently read as a signal. */
let isSignalLike = (value: 'value): bool =>
  switch value->Core.Type.Classify.classify {
  | Object(obj) => {
      let obj: {..} = Obj.magic(obj)
      obj->Core.Object.hasOwnProperty("subs") &&
      obj->Core.Object.hasOwnProperty("value") &&
      switch obj->Core.Object.get("equals") {
      | Some(equals) => isFunction(equals)
      | None => false
      }
    }
  | _ => false
  }

let getField = (props: 'props, key: string): option<'value> => {
  let props: {..} = Obj.magic(props)
  props->Core.Object.get(key)
}
