module Computed = Xote__Computed
module Core = Xote__Core
module Effect = Xote__Effect
module Signal = Xote__Signal

/**----- DEMO-----**/
let count = Signal.make(0)
let double = Computed.make(() => Signal.get(count) * 2)

let eff = Effect.run(() => {
  Js.log2("count:", Signal.get(count))
  Js.log2("double:", Signal.get(double))
})

Signal.set(count, 1) /* triggers effect */
Signal.update(count, n => n + 1)

Core.untrack(() => Js.log2("peek double (no track)", Signal.peek(double)))

Core.batch(() => {
  Signal.set(count, 10)
  Signal.set(count, 11)
})
