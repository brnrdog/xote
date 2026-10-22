/**
 * The docs page registry: the single source of truth for the docs sidebar,
 * routes, table of contents, search index, pre-rendered pages, Markdown
 * copies and redirects from older URLs.
 *
 * `scripts/generate-docs-index.mjs` turns this into `src/DocsIndex.res`
 * (run by `npm run res:build`), and `scripts/prerender.mjs` imports it
 * directly. To add a page: write `src/docs/<File>.mdx`, add an entry here,
 * and rebuild.
 *
 * Page fields:
 *   title      sidebar label and page title
 *   pageTitle  optional page heading when it differs from the sidebar label
 *   path       URL
 *   file       MDX file in src/docs (without extension), or null for pages
 *              rendered by custom code (the changelog)
 *   lead       one sentence under the title, also the meta description
 *   aliases    older URLs that redirect here
 *   agentOnly  listed in the sidebar only in the agent layer
 *   agent      facts shown in the agent layer: module, boundary (.resi),
 *              entry (import path) and api (an API reference MDX file
 *              appended to the page in the agent layer)
 */

const signalFacts = { module: 'Xote.Signal', boundary: 'src/Signal.resi', entry: 'xote · xote/signal' }
const computedFacts = { module: 'Xote.Computed', boundary: 'src/Computed.resi', entry: 'xote · xote/computed' }
const effectFacts = { module: 'Xote.Effect', boundary: 'src/Effect.resi', entry: 'xote · xote/effect' }
const viewFacts = { module: 'Xote.View', boundary: 'src/View.resi', entry: 'xote · xote/view' }

export const sections = [
  {
    label: 'Get started',
    pages: [
      {
        title: 'Introduction',
        path: '/docs',
        file: 'IntroDoc',
        lead: 'What Xote is, what it feels like to use, and where to go next.',
      },
      {
        title: 'Quick start',
        path: '/docs/quick-start',
        file: 'QuickStartDoc',
        lead: 'Install Xote, turn on its JSX transform, and render your first component.',
      },
      {
        title: 'Thinking in signals',
        path: '/docs/thinking-in-signals',
        file: 'ThinkingInSignalsDoc',
        lead: 'Components run once; only the parts that read a signal update. Everything else follows from that.',
      },
      {
        title: 'Tutorial',
        pageTitle: 'Tutorial: temperature converter',
        path: '/docs/tutorial',
        file: 'TutorialDoc',
        lead: 'Build a small temperature converter step by step, and meet signals, computeds and effects along the way.',
      },
      {
        title: 'Learning ReScript',
        path: '/docs/learning-rescript',
        file: 'LearningReScriptDoc',
        lead: 'A quick tour of ReScript syntax, with examples and links to the official docs for deeper study.',
        aliases: ['/docs/getting-started/rescript'],
      },
      {
        title: 'Using from JavaScript',
        path: '/docs/javascript',
        file: 'JavaScriptTypeScriptDoc',
        lead: "Use Xote's compiled runtime from JavaScript projects without ReScript JSX.",
        aliases: ['/docs/getting-started/javascript-typescript'],
      },
    ],
  },
  {
    label: 'Learn',
    pages: [
      {
        title: 'Signals',
        path: '/docs/learn/signals',
        file: 'SignalsDoc',
        lead: 'Hold a value, read it, change it, and let everything that depends on it follow.',
        aliases: ['/docs/core-concepts/signals'],
        agent: { ...signalFacts, api: 'ApiSignalDoc' },
      },
      {
        title: 'Computeds',
        path: '/docs/learn/computeds',
        file: 'ComputedDoc',
        lead: 'Derive values from signals and keep them in sync without writing the syncing yourself.',
        aliases: ['/docs/core-concepts/computed'],
        agent: { ...computedFacts, api: 'ApiComputedDoc' },
      },
      {
        title: 'Effects',
        path: '/docs/learn/effects',
        file: 'EffectsDoc',
        lead: 'Run code outside the signal graph, like timers, storage or logging, whenever its inputs change.',
        aliases: ['/docs/core-concepts/effects'],
        agent: { ...effectFacts, api: 'ApiEffectDoc' },
      },
      {
        title: 'Components',
        path: '/docs/learn/components',
        file: 'ComponentsDoc',
        lead: 'Write components with JSX, pass them props and children, and mount your app.',
        aliases: ['/docs/view/overview', '/docs/components/overview'],
        agent: { ...viewFacts, api: 'ApiViewDoc' },
      },
      {
        title: 'Rendering',
        path: '/docs/learn/rendering',
        file: 'RenderingDoc',
        lead: 'Show changing text, set attributes, handle events, and render conditions and lists.',
        agent: { ...viewFacts, api: 'ApiViewDoc' },
      },
      {
        title: 'Refs and lifecycle',
        path: '/docs/learn/lifecycle',
        file: 'LifecycleDoc',
        lead: 'Reach the real DOM, run code on mount and cleanup, render elsewhere, and recover from errors.',
        agent: { ...viewFacts, api: 'ApiViewDoc' },
      },
      {
        title: 'Context',
        path: '/docs/learn/context',
        file: 'ContextDoc',
        lead: 'Make a value available to everything a component renders, scoped to that component.',
        aliases: ['/docs/core-concepts/context'],
        agent: { module: 'Xote.Context', boundary: 'src/Context.resi', entry: 'xote · xote/context' },
      },
      {
        title: 'Async data',
        path: '/docs/learn/async-data',
        file: 'ResourcesDoc',
        lead: 'Turn asynchronous work into signals, and show a fallback while it loads.',
        aliases: ['/docs/core-concepts/resources'],
        agent: { module: 'Xote.Resource', boundary: 'src/Resource.resi', entry: 'xote/resource' },
      },
      {
        title: 'Routing',
        path: '/docs/learn/routing',
        file: 'RouterDoc',
        lead: 'Match URLs to views, read the current location, and navigate with links.',
        aliases: ['/docs/router/overview'],
        agent: { module: 'Xote.Router, Xote.Route', boundary: 'src/Router.resi', entry: 'xote/router' },
      },
    ],
  },
  {
    label: 'Guides',
    pages: [
      {
        title: 'Forms and inputs',
        path: '/docs/guides/forms',
        file: 'GuideFormsDoc',
        lead: 'Bind inputs, checkboxes and selects to signals, validate with computeds, and handle submit without reloading the page.',
      },
      {
        title: 'Fetching data',
        path: '/docs/guides/fetching-data',
        file: 'GuideFetchingDataDoc',
        lead: 'Load data, show loading and error states, refetch when inputs change, and search as people type.',
      },
      {
        title: 'Styling',
        path: '/docs/guides/styling',
        file: 'GuideStylingDoc',
        lead: 'Style Xote apps with plain CSS, and let classes, inline styles and data attributes follow your signals.',
      },
      {
        title: 'Project structure',
        path: '/docs/guides/project-structure',
        file: 'GuideProjectStructureDoc',
        lead: 'Set up rescript.json, the entry file and a folder layout, and decide where each piece of state should live.',
      },
      {
        title: 'Testing',
        path: '/docs/guides/testing',
        file: 'GuideTestingDoc',
        lead: 'Test signals, components, server-rendered HTML and resources with the same tools Xote uses for its own tests.',
      },
      {
        title: 'Deploying',
        path: '/docs/guides/deploying',
        file: 'GuideDeployingDoc',
        lead: 'Build for production, host as a static site or under a subpath, and prerender pages to HTML.',
      },
    ],
  },
  {
    label: 'Advanced',
    pages: [
      {
        title: 'Server rendering',
        path: '/docs/advanced/ssr',
        file: 'SSRDoc',
        lead: 'Render on the server, transfer state explicitly, and hydrate without re-rendering.',
        agent: { module: 'Xote.SSR, Xote.Hydration', boundary: 'src/SSR.resi', entry: 'xote/ssr · xote/hydration' },
      },
      {
        title: 'Batching',
        path: '/docs/advanced/batching',
        file: 'BatchingDoc',
        lead: 'Group several signal updates so dependents run once.',
        agent: { module: 'Xote.Signal.batch', boundary: 'src/Signal.resi', entry: 'xote' },
      },
      {
        title: 'MDX',
        path: '/docs/advanced/mdx-support',
        file: 'MdxDoc',
        lead: 'Write Markdown pages that compile to Xote views and embed Xote components.',
        agent: { module: 'Xote.Mdx', boundary: 'src/Mdx.resi', entry: 'xote/mdx' },
      },
      {
        title: 'Technical overview',
        path: '/docs/technical-overview',
        file: 'TechnicalOverviewDoc',
        lead: "A lower-level view of Xote's modules, runtime behavior, and rendering model.",
        agentOnly: true,
      },
    ],
  },
  {
    label: 'Reference',
    pages: [
      {
        title: 'Signal API',
        path: '/docs/api/signal',
        file: 'ApiSignalDoc',
        lead: 'Reference for writable reactive state.',
        aliases: ['/docs/api/signals'],
        agent: signalFacts,
      },
      {
        title: 'Computed API',
        path: '/docs/api/computed',
        file: 'ApiComputedDoc',
        lead: 'Reference for derived reactive values.',
        agent: computedFacts,
      },
      {
        title: 'Effect API',
        path: '/docs/api/effect',
        file: 'ApiEffectDoc',
        lead: 'Reference for reactive side effects and disposal.',
        agent: effectFacts,
      },
      {
        title: 'View API',
        path: '/docs/api/view',
        file: 'ApiViewDoc',
        lead: 'Reference for UI nodes, JSX primitives, lists, attributes, and mounting.',
        agent: viewFacts,
      },
      {
        title: 'Glossary',
        path: '/docs/glossary',
        file: 'GlossaryDoc',
        lead: 'The terms the docs use for reactivity, ownership and rendering, defined precisely.',
        agentOnly: true,
      },
    ],
  },
  {
    label: 'Why Xote',
    pages: [
      {
        title: 'Compared to React',
        path: '/docs/comparisons/react',
        file: 'ReactComparisonDoc',
        lead: 'How Xote differs from React in rendering, effects, routing, SSR, and team tradeoffs.',
      },
      {
        title: 'Compared to SolidJS',
        path: '/docs/comparisons/solidjs',
        file: 'SolidJSComparisonDoc',
        lead: 'How Xote compares to SolidJS, especially where they share the same reactive model.',
      },
    ],
  },
  {
    label: 'Project',
    pages: [
      {
        title: 'Changelog',
        pageTitle: 'Release notes',
        path: '/docs/changelog',
        file: 'ChangelogDoc',
        lead: 'What changed in each Xote release.',
        customToc: true,
      },
    ],
  },
]

export const pages = sections.flatMap(section =>
  section.pages.map(page => ({ ...page, section: section.label })),
)

// Older URL -> current URL.
export const redirects = Object.fromEntries(
  pages.flatMap(page => (page.aliases ?? []).map(alias => [alias, page.path])),
)
