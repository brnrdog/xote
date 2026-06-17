let isReactiveProp = RuntimeValue.isReactiveProp

let toStringAttr = (key: string, value: 'a): (string, View.attrValue) => {
  if isReactiveProp(value) {
    let prop: Prop.t<string> = Obj.magic(value)
    switch prop {
    | Static(value) => View.attr(key, value)
    | Reactive(signal) => View.signalAttr(key, signal)
    }
  } else if value->RuntimeValue.isFunction {
    let compute: unit => string = Obj.magic(value)
    View.computedAttr(key, compute)
  } else if value->RuntimeValue.isObject {
    let signal: Signal.t<string> = Obj.magic(value)
    View.signalAttr(key, signal)
  } else {
    let value: string = Obj.magic(value)
    View.attr(key, value)
  }
}

let toBoolAttr = (key: string, value: 'a): (string, View.attrValue) => {
  if isReactiveProp(value) {
    let prop: Prop.t<bool> = Obj.magic(value)
    switch prop {
    | Static(value) => View.attr(key, RuntimeAttr.boolToString(value))
    | Reactive(signal) => {
        let stringSignal = Computed.make(() => RuntimeAttr.boolToString(Signal.get(signal)))
        View.signalAttr(key, stringSignal)
      }
    }
  } else if value->RuntimeValue.isFunction {
    let compute: unit => bool = Obj.magic(value)
    View.computedAttr(key, () => RuntimeAttr.boolToString(compute()))
  } else if value->RuntimeValue.isObject {
    let signal: Signal.t<bool> = Obj.magic(value)
    let stringSignal = Computed.make(() => RuntimeAttr.boolToString(Signal.get(signal)))
    View.signalAttr(key, stringSignal)
  } else {
    let value: bool = Obj.magic(value)
    View.attr(key, RuntimeAttr.boolToString(value))
  }
}
