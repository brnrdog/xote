/* expect-error: defaultEquals
   Mechanism: a value that reaches Xote only because the module re-exports
   `rescript-signals`. The explicit shim plus `.resi` stops upstream additions
   becoming Xote public API.
   Also covers Signal.makeForComputed and Computed.makeWithEquals. */
let leak = Xote.Signal.defaultEquals
