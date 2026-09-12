/* Server-side rendering to HTML strings.

   The emitted markup carries comment markers (`<!--$-->`, `<!--#-->`,
   `<!--kl-->`, `<!--k:KEY-->`, `<!--lc-->`) that `Hydration` uses to find
   reactive boundaries without re-rendering. */

type renderOptions = {
  nonce?: string,
  renderId?: string,
}

/* Render a component to an HTML string */
let renderToString: (unit => View.node, ~options: renderOptions=?) => string

/* Render a component wrapped in a hydration root marker */
let renderToStringWithRoot: (
  unit => View.node,
  ~rootId: string=?,
  ~options: renderOptions=?,
) => string

/* `<script>` tag that sets `window.__XOTE_HYDRATED__` */
let generateHydrationScript: (~nonce: string=?) => string

/* Render a full HTML document around a component */
let renderDocument: (
  ~head: string=?,
  ~bodyAttrs: string=?,
  ~scripts: array<string>=?,
  ~styles: array<string>=?,
  ~stateScript: string=?,
  ~nonce: string=?,
  unit => View.node,
) => string
