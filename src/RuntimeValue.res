module Core = RescriptCore

let objectHasTag = (obj: {..}, tag: string): bool =>
  switch obj->Core.Object.get("TAG") {
  | Some(value) => value == tag
  | None => false
  }

let isReactiveProp = (value: 'value): bool => {
  switch value->Core.Type.Classify.classify {
  | Object(obj) => {
      let obj: {..} = Obj.magic(obj)
      obj->Core.Object.hasOwnProperty("TAG") &&
        (obj->objectHasTag("Static") || obj->objectHasTag("Reactive"))
    }
  | _ => false
  }
}

let isFunction = (value: 'value): bool =>
  switch value->Core.Type.Classify.classify {
  | Function(_) => true
  | _ => false
  }

let isObject = (value: 'value): bool =>
  switch value->Core.Type.Classify.classify {
  | Object(_) => true
  | _ => false
  }

let getField = (props: 'props, key: string): option<'value> => {
  let props: {..} = Obj.magic(props)
  props->Core.Object.get(key)
}
