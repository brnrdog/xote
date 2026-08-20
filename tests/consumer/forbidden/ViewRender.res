/* expect-error: Render
   Mechanism: a nested module inside a public module, omitted from its `.resi`.
   Also covers Hydration.DOMWalker and View.Reactivity. */
let leak = Xote.View.Render.disposeElement
