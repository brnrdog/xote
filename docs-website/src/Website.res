// Import doc content
module IntroDoc = IntroDoc
module SignalsDoc = SignalsDoc
module ComputedDoc = ComputedDoc
module EffectsDoc = EffectsDoc
module BatchingDoc = BatchingDoc
module ComponentsDoc = ComponentsDoc
module RouterDoc = RouterDoc
module ApiSignalsDoc = ApiSignalsDoc
module ReactComparisonDoc = ReactComparisonDoc
module SolidJSComparisonDoc = SolidJSComparisonDoc
module TechnicalOverviewDoc = TechnicalOverviewDoc
module SSRDoc = SSRDoc
module ChangelogDoc = ChangelogDoc

// Demo modules are still on disk under `src/demos/*.res` for reuse as
// inline figures, but no longer routed as standalone pages.

// 404 Page component
module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <Layout
      children={
        <div class="not-found">
          <h1> {View.text("404")} </h1>
          <p> {View.text("The page you're looking for doesn't exist.")} </p>
          {Router.link(
            ~to="/",
            ~attrs=[View.attr("class", "btn btn-primary")],
            ~children=[View.text("Go Home")],
            (),
          )}
        </div>
      }
    />
  }
}

// Main app
module App = {
  type props = {}

  let visibleChangelogReleases =
    RepoData.releases->Array.slice(
      ~start=0,
      ~end=min(10, Array.length(RepoData.releases)),
    )

  let changelogTocItems: array<DocsPage.TableOfContents.tocItem> =
    visibleChangelogReleases->Array.map(release => {
      let item: DocsPage.TableOfContents.tocItem = {
        text: "v" ++ release.version ++ " (" ++ release.date ++ ")",
        id: release.id,
        level: 2,
      }
      item
    })

  let make = (_props: props) => {
    Router.routes(
      [
        {
          pattern: "/",
          render: _params => <HomePage />,
        },
        {
          pattern: "/docs",
          render: _params =>
            <DocsPage
              currentPath="/docs"
              pageTitle="Introduction"
              pageLead="Get oriented around Xote's reactive model, UI primitives, and setup."
              content={IntroDoc.content()}
              tocItems=[
                {text: "What is Xote?", id: "what-is-xote", level: 2},
                {text: "Start Here", id: "quick-example", level: 2},
                {text: "Using JSX Syntax", id: "using-jsx-syntax", level: 3},
                {text: "How the Docs Are Organized", id: "core-modules", level: 2},
                {text: "Installation", id: "installation", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
                {text: "Philosophy", id: "philosophy", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/",
          render: _params =>
            <DocsPage
              currentPath="/docs"
              pageTitle="Introduction"
              pageLead="Get oriented around Xote's reactive model, UI primitives, and setup."
              content={IntroDoc.content()}
              tocItems=[
                {text: "What is Xote?", id: "what-is-xote", level: 2},
                {text: "Start Here", id: "quick-example", level: 2},
                {text: "Using JSX Syntax", id: "using-jsx-syntax", level: 3},
                {text: "How the Docs Are Organized", id: "core-modules", level: 2},
                {text: "Installation", id: "installation", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
                {text: "Philosophy", id: "philosophy", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/signals",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/signals"
              pageTitle="Signals"
              pageLead="State containers that drive Xote's reactive graph."
              content={SignalsDoc.content()}
              tocItems=[
                {text: "Working with Signals", id: "working-with-signals", level: 2},
                {text: "Creating Signals", id: "creating-signals", level: 3},
                {text: "Reading Signal Values", id: "reading-signal-values", level: 3},
                {text: "Updating Signals", id: "updating-signals", level: 3},
                {text: "How Signals Decide to Update", id: "how-signals-decide-to-update", level: 2},
                {text: "Equality and Change Detection", id: "equality-and-change-detection", level: 3},
                {text: "Dependency Tracking", id: "dependency-tracking", level: 3},
                {text: "In Practice", id: "signals-in-practice", level: 2},
                {text: "Example: Counter", id: "example-counter", level: 3},
                {text: "Working Style", id: "signals-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/computed",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/computed"
              pageTitle="Computeds"
              pageLead="Derived signals that stay in sync with the values they read."
              content={ComputedDoc.content()}
              tocItems=[
                {text: "Working with Computeds", id: "working-with-computeds", level: 2},
                {text: "Creating Computed Values", id: "creating-computed-values", level: 3},
                {text: "Reading Computed Values", id: "reading-computed-values", level: 3},
                {text: "Lazy Recomputation", id: "lazy-recomputation", level: 3},
                {text: "Dynamic Dependencies", id: "dynamic-dependencies", level: 3},
                {text: "Lifecycle", id: "computed-lifecycle", level: 2},
                {text: "Disposal", id: "disposal", level: 3},
                {text: "Computed vs Manual Updates", id: "computed-vs-manual-updates", level: 3},
                {text: "Working Style", id: "computed-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/effects",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/effects"
              pageTitle="Effects"
              pageLead="Reactive side effects for work that happens outside the signal graph."
              content={EffectsDoc.content()}
              tocItems=[
                {text: "Working with Effects", id: "working-with-effects", level: 2},
                {text: "Creating Effects", id: "creating-effects", level: 3},
                {text: "Dependency Tracking", id: "dependency-tracking", level: 3},
                {text: "Cleanup Callbacks", id: "cleanup-callbacks", level: 3},
                {text: "Disposing Effects", id: "disposing-effects", level: 3},
                {text: "Avoiding Dependencies", id: "avoiding-dependencies", level: 3},
                {text: "Common Patterns", id: "effects-common-patterns", level: 2},
                {text: "Common Use Cases", id: "common-use-cases", level: 3},
                {text: "Example: Auto-save", id: "example-auto-save", level: 3},
                {text: "Effects vs Computed", id: "effects-vs-computed", level: 3},
                {text: "Working Style", id: "effects-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/advanced/ssr",
          render: _params =>
            <DocsPage
              currentPath="/docs/advanced/ssr"
              pageTitle="Server-Side Rendering"
              pageLead="Render on the server, transfer state explicitly, and hydrate without re-rendering."
              content={SSRDoc.content()}
              tocItems=[
                {text: "Rendering Model", id: "rendering-model", level: 2},
                {text: "Overview", id: "overview", level: 3},
                {text: "Render on the Server", id: "render-on-the-server", level: 3},
                {text: "Full Document Rendering", id: "full-document-rendering", level: 3},
                {text: "Environment Detection", id: "environment-detection", level: 3},
                {text: "State and Hydration", id: "state-and-hydration", level: 2},
                {text: "State Transfer", id: "state-transfer", level: 3},
                {text: "Creating Synced State", id: "creating-synced-state", level: 3},
                {text: "Syncing Existing Signals", id: "syncing-existing-signals", level: 3},
                {text: "Built-in Codecs", id: "built-in-codecs", level: 3},
                {text: "Client-Side Hydration", id: "hydration", level: 3},
                {text: "In Practice", id: "ssr-in-practice", level: 2},
                {text: "Complete Example", id: "complete-example", level: 3},
                {text: "Hydration Markers", id: "hydration-markers", level: 3},
                {text: "Working Style", id: "ssr-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/advanced/batching",
          render: _params =>
            <DocsPage
              currentPath="/docs/advanced/batching"
              pageTitle="Batching"
              pageLead="Group multiple signal updates to run observers only once."
              content={BatchingDoc.content()}
              tocItems=[
                {text: "Why and When to Batch", id: "why-and-when-to-batch", level: 2},
                {text: "Why Batch?", id: "why-batch", level: 3},
                {text: "When Not to Batch", id: "when-not-to-batch", level: 3},
                {text: "Using Batching", id: "using-batching", level: 2},
                {text: "Using Signal.batch()", id: "using-signal-batch", level: 3},
                {text: "How Batching Works", id: "how-batching-works", level: 3},
                {text: "Common Cases", id: "common-cases", level: 3},
                {text: "Nested Batches", id: "nested-batches", level: 3},
                {text: "Returning Values from Batches", id: "returning-values-from-batches", level: 3},
                {text: "Working Style", id: "batching-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/view/overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/view/overview"
              pageTitle="View"
              pageLead="How the View module and JSX components render once and stay reactive over time."
              content={ComponentsDoc.content()}
              tocItems=[
                {text: "View Module", id: "component-model", level: 2},
                {text: "Using View", id: "building-components", level: 2},
                {text: "JSX Configuration", id: "jsx-configuration", level: 3},
                {text: "Writing Components", id: "writing-components", level: 3},
                {text: "Recommended Pattern", id: "component-module-pattern", level: 3},
                {text: "Function API", id: "function-api", level: 3},
                {text: "Reactive Output", id: "reactive-output", level: 3},
                {text: "Attributes and Events", id: "attributes-and-events", level: 3},
                {text: "Lists", id: "lists", level: 3},
                {text: "Mounting", id: "mounting", level: 3},
                {text: "In Practice", id: "components-in-practice", level: 2},
                {text: "Example: Counter View", id: "example-counter-component", level: 3},
                {text: "Working Style", id: "components-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/components/overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/view/overview"
              pageTitle="View"
              pageLead="How the View module and JSX components render once and stay reactive over time."
              content={ComponentsDoc.content()}
              tocItems=[
                {text: "View Module", id: "component-model", level: 2},
                {text: "Using View", id: "building-components", level: 2},
                {text: "JSX Configuration", id: "jsx-configuration", level: 3},
                {text: "Writing Components", id: "writing-components", level: 3},
                {text: "Recommended Pattern", id: "component-module-pattern", level: 3},
                {text: "Function API", id: "function-api", level: 3},
                {text: "Reactive Output", id: "reactive-output", level: 3},
                {text: "Attributes and Events", id: "attributes-and-events", level: 3},
                {text: "Lists", id: "lists", level: 3},
                {text: "Mounting", id: "mounting", level: 3},
                {text: "In Practice", id: "components-in-practice", level: 2},
                {text: "Example: Counter View", id: "example-counter-component", level: 3},
                {text: "Working Style", id: "components-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/router/overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/router/overview"
              pageTitle="Router"
              pageLead="Signal-based navigation with route matching, links, and SSR-aware initialization."
              content={RouterDoc.content()}
              tocItems=[
                {text: "Getting Started", id: "getting-started-with-routing", level: 2},
                {text: "Quick Start", id: "quick-start", level: 3},
                {text: "Reading the Current Location", id: "reading-the-location", level: 3},
                {text: "Route Patterns", id: "route-patterns", level: 3},
                {text: "Navigation Methods", id: "navigation-methods", level: 3},
                {text: "Navigation Links", id: "navigation-links", level: 3},
                {text: "Server Rendering", id: "server-rendering", level: 3},
                {text: "In Practice", id: "routing-in-practice", level: 2},
                {text: "Complete Example", id: "complete-example", level: 3},
                {text: "Working Style", id: "router-working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/api/signals",
          render: _params =>
            <DocsPage
              currentPath="/docs/api/signals"
              pageTitle="Signals API"
              pageLead="Reference for the Signal module, plus the related Computed and Effect entry points."
              content={ApiSignalsDoc.content()}
              tocItems=[
                {text: "Signal", id: "signal-api", level: 2},
                {text: "Type", id: "type", level: 3},
                {text: "Functions", id: "functions", level: 3},
                {text: "Related APIs", id: "related-signal-apis", level: 2},
                {text: "Behavior Notes", id: "behavior-notes", level: 3},
                {text: "Companion Modules", id: "companion-modules", level: 3},
                {text: "In Practice", id: "signals-in-practice", level: 2},
                {text: "Examples", id: "examples", level: 3},
                {text: "Where to Go Next", id: "where-to-go-next", level: 2},
                {text: "See Also", id: "see-also", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/comparisons/react",
          render: _params =>
            <DocsPage
              currentPath="/docs/comparisons/react"
              pageTitle="React Comparison"
              pageLead="How Xote differs from React in rendering, effects, routing, SSR, and team tradeoffs."
              content={ReactComparisonDoc.content()}
              tocItems=[
                {text: "At a Glance", id: "at-a-glance", level: 2},
                {text: "Overview", id: "overview", level: 3},
                {text: "Runtime Model", id: "runtime-model", level: 2},
                {text: "Reactivity Model", id: "reactivity-model", level: 3},
                {text: "Effects and Derived State", id: "effects-and-derived-state", level: 3},
                {text: "Component Lifecycle", id: "component-lifecycle", level: 3},
                {text: "List Rendering", id: "list-rendering", level: 3},
                {text: "Platform Surface", id: "platform-surface", level: 2},
                {text: "Server-Side Rendering", id: "server-side-rendering", level: 3},
                {text: "Routing", id: "routing", level: 3},
                {text: "Runtime Footprint", id: "runtime-footprint", level: 3},
                {text: "Type Safety", id: "type-safety", level: 3},
                {text: "Ecosystem", id: "ecosystem", level: 3},
                {text: "Choosing Between Them", id: "choosing-between-them", level: 2},
                {text: "When to Choose React", id: "when-to-choose-react", level: 3},
                {text: "When to Choose Xote", id: "when-to-choose-xote", level: 3},
                {text: "Migration Considerations", id: "migration-considerations", level: 3},
                {text: "Further Reading", id: "further-reading", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/comparisons/solidjs",
          render: _params =>
            <DocsPage
              currentPath="/docs/comparisons/solidjs"
              pageTitle="SolidJS Comparison"
              pageLead="How Xote compares to SolidJS, especially where they share the same reactive model."
              content={SolidJSComparisonDoc.content()}
              tocItems=[
                {text: "At a Glance", id: "at-a-glance", level: 2},
                {text: "Overview", id: "overview", level: 3},
                {text: "Shared Ground", id: "shared-ground", level: 2},
                {text: "Shared Philosophy", id: "shared-philosophy", level: 3},
                {text: "Runtime Model", id: "runtime-model", level: 2},
                {text: "Signals and State", id: "signals-and-state", level: 3},
                {text: "Component Model", id: "component-model", level: 3},
                {text: "List Rendering", id: "list-rendering", level: 3},
                {text: "Platform Surface", id: "platform-surface", level: 2},
                {text: "Server-Side Rendering", id: "server-side-rendering", level: 3},
                {text: "Routing", id: "routing", level: 3},
                {text: "Runtime Footprint and Compilation", id: "runtime-footprint-and-compilation", level: 3},
                {text: "Type Safety", id: "type-safety", level: 3},
                {text: "Ecosystem", id: "ecosystem", level: 3},
                {text: "Choosing Between Them", id: "choosing-between-them", level: 2},
                {text: "When to Choose SolidJS", id: "when-to-choose-solidjs", level: 3},
                {text: "When to Choose Xote", id: "when-to-choose-xote", level: 3},
                {text: "Migration Considerations", id: "migration-considerations", level: 3},
                {text: "Further Reading", id: "further-reading", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/technical-overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/technical-overview"
              pageTitle="Technical Overview"
              pageLead="A lower-level view of Xote's modules, runtime behavior, and rendering model."
              content={TechnicalOverviewDoc.content()}
              tocItems=[
                {text: "System Shape", id: "system-shape", level: 2},
                {text: "Architecture Overview", id: "architecture-overview", level: 3},
                {text: "Module Structure", id: "module-structure", level: 3},
                {text: "Runtime Model", id: "runtime-model", level: 2},
                {text: "Reactivity Model", id: "reactivity-model", level: 3},
                {text: "View Rendering", id: "component-rendering", level: 3},
                {text: "Router Architecture", id: "router-architecture", level: 3},
                {text: "SSR and Hydration", id: "ssr-and-hydration", level: 3},
                {text: "Execution Characteristics", id: "execution-characteristics", level: 3},
                {text: "Reference Map", id: "reference-map", level: 2},
                {text: "API Summary", id: "api-summary", level: 3},
                {text: "Reactive Primitives", id: "reactive-primitives", level: 3},
                {text: "View Helpers", id: "component-helpers", level: 3},
                {text: "Router Helpers", id: "router-helpers", level: 3},
                {text: "Working Style", id: "working-style", level: 2},
                {text: "Best Practices", id: "best-practices", level: 3},
                {text: "Next Steps", id: "next-steps", level: 3},
              ]
            />,
        },
        {
          pattern: "/docs/changelog",
          render: _params =>
            <DocsPage
              currentPath="/docs/changelog"
              pageTitle="Changelog"
              content={ChangelogDoc.content()}
              tocItems=changelogTocItems
            />,
        },
        {
          pattern: "*",
          render: _params => <NotFoundPage />,
        },
      ],
    )
  }
}
