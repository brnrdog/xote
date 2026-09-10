/* Client-side hydration of server-rendered markup.

   Walks the existing DOM produced by `SSR`, attaches effects and event
   listeners and sets up keyed-list reconciliation without re-rendering. */

type hydrateOptions = {
  renderId?: string,
  onHydrated?: unit => unit,
}

/* Hydrate a component into an existing container element */
let hydrate: (unit => View.node, Dom.element, ~options: hydrateOptions=?) => unit

/* Hydrate a component into the element with the given id */
let hydrateById: (unit => View.node, string, ~options: hydrateOptions=?) => unit
