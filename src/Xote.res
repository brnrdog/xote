module DevTools = {
  include Xote__DevTools
}

module Signal = {
  include Signals.Signal

  let make = (initialValue: 'a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?): t<
    'a,
  > => {
    let signal = Signals.Signal.make(initialValue, ~name?, ~equals?)
    DevTools.registerSignal(signal.id, name, Obj.magic(signal), #Signal)
    signal
  }
}

module Computed = {
  include Signals.Computed

  let make = (compute: unit => 'a, ~name: option<string>=?): Signal.t<'a> => {
    let signal = Signals.Computed.make(compute, ~name?)
    DevTools.registerSignal(signal.id, name, Obj.magic(signal), #Computed)
    signal
  }
}

module Effect = {
  include Signals.Effect

  let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
    let disposer = Signals.Effect.run(fn, ~name?)
    let id: int = %raw(`
      (function() {
        var _id = (globalThis.__xote_devtools_effect_id__ || 0) + 1;
        globalThis.__xote_devtools_effect_id__ = _id;
        return _id;
      })()
    `)
    DevTools.registerEffect(id, name, disposer)
    let originalDispose = disposer.dispose
    {
      dispose: () => {
        DevTools.unregisterEffect(id)
        originalDispose()
      },
    }
  }
}

module Component = {
  include Xote__Component
}

module Route = {
  include Xote__Route
}

module Router = {
  include Xote__Router
}

module ReactiveProp = {
  include Xote__ReactiveProp
}

module SSR = {
  include Xote__SSR
}

module SSRContext = {
  include Xote__SSRContext
}

module SSRState = {
  include Xote__SSRState
}

module Hydration = {
  include Xote__Hydration
}
