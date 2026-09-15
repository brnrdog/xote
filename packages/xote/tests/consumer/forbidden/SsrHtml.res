/* expect-error: Html
   Mechanism: a `module X = RuntimeY` alias inside a public module. An alias
   republishes the internal unless the `.resi` omits it.
   Also covers SSR.Markers and the former View.DOM / View.Core. */
let leak = Xote.SSR.Html.escape
