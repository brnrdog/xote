/*
 * Client-side hydration entry point
 * This script hydrates the server-rendered HTML
 */
open Xote

/* Create fresh state for the client */
let (count, items, inputValue) = App.makeAppState()
let appComponent = App.app(count, items, inputValue)

/* Hydrate the server-rendered content */
let _ = Hydration.hydrateById(
  appComponent,
  "root",
  ~options={
    onHydrated: () => {
      Console.log("[Xote] Hydration complete!")
    },
  },
)
