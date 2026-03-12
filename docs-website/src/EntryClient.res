open Xote

// Import modules to ensure they are included in the bundle
module Website = Website

// Initialize client-side router
Router.init(~basePath="/xote", ())

// Hydrate the server-rendered HTML
let _ = Hydration.hydrateById(
  () => <Website.App />,
  "app",
  ~options={
    onHydrated: () => {
      Console.log("[Xote] Hydration complete!")
    },
  },
)
