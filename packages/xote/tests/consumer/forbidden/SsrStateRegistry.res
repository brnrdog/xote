/* expect-error: registry
   Mechanism: a plain `let` in a public module, omitted from its `.resi`.
   Also covers Router.normalizeBasePath, Mdx.isXoteNode, View.childrenToArray. */
let leak = Xote.SSRState.registry
