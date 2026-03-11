// Utility types and functions for handling both regular values and signals

type reactive<'a> =
  | Value('a)
  | SignalValue(Signals.Signal.t<'a>)

let getValue = (reactive: reactive<'a>): 'a => {
  switch reactive {
  | Value(v) => v
  | SignalValue(s) => Signals.Signal.get(s)
  }
}

let makeReactive = (value: 'a): reactive<'a> => Value(value)
let makeReactiveFromSignal = (signal: Signals.Signal.t<'a>): reactive<'a> => SignalValue(signal)
