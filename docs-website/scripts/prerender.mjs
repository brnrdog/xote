/**
 * Pre-render all docs website routes to static HTML files.
 *
 * This script runs after `vite build` (client + server bundles) and uses
 * the SSR server entry to render each route into its own index.html file,
 * making the site compatible with static hosting (e.g., GitHub Pages).
 *
 * Usage: node scripts/prerender.mjs
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const buildDir = path.join(__dirname, '..', 'build', 'client')
const siteUrl = normalizeSiteUrl(process.env.SITE_URL || 'https://xote.dev')
const siteName = 'xote'
const defaultDescription =
  'A small UI library for ReScript with fine-grained reactivity. Signals, computeds, and effects recompute only what changed.'

// All routes to pre-render (app-relative paths, without base path)
const routes = [
  {
    path: '/',
    title: 'xote - A ReScript Library for Building User Interfaces',
    description:
      'Build small ReScript interfaces with fine-grained signals, JSX views, routing, server-side rendering, and hydration.',
    type: 'website',
    priority: '1.0',
  },
  {
    path: '/docs',
    title: 'xote Docs - Introduction',
    description:
      'Get started with xote, a ReScript UI library for fine-grained reactive interfaces.',
    section: 'Getting Started',
    priority: '0.9',
  },
  {
    path: '/docs/getting-started/rescript',
    title: 'Learning ReScript - xote Docs',
    description:
      'A practical tour of ReScript syntax, data modeling, pattern matching, and incremental adoption for xote users.',
    section: 'Getting Started',
    priority: '0.8',
  },
  {
    path: '/docs/getting-started/javascript-typescript',
    title: 'JavaScript Runtime - xote Docs',
    description:
      'Use xote from JavaScript projects with focused package entries and runtime view constructors.',
    section: 'Getting Started',
    priority: '0.8',
  },
  {
    path: '/docs/core-concepts/signals',
    title: 'Signals - xote Reactive State',
    description:
      'Create, read, update, and compose xote signals for precise reactive state updates in ReScript applications.',
    section: 'Core Concepts',
  },
  {
    path: '/docs/core-concepts/computed',
    title: 'Computeds - xote Derived Signals',
    description:
      'Use xote computeds to derive reactive state that updates automatically when signal dependencies change.',
    section: 'Core Concepts',
  },
  {
    path: '/docs/core-concepts/effects',
    title: 'Effects - xote Reactive Side Effects',
    description:
      'Run side effects from signal dependencies with cleanup callbacks, disposal, and practical ReScript examples.',
    section: 'Core Concepts',
  },
  {
    path: '/docs/advanced/ssr',
    title: 'Server-Side Rendering - xote SSR and Hydration',
    description:
      'Render xote views on the server, transfer state, and hydrate reactive ReScript apps on the client.',
    section: 'Advanced',
  },
  {
    path: '/docs/advanced/mdx-support',
    title: 'MDX Support - xote Docs',
    description:
      'Configure MDX with the xote JSX runtime, render MDX from ReScript, and customize Markdown components.',
    section: 'Advanced',
  },
  {
    path: '/docs/advanced/batching',
    title: 'Batching - xote Signal Updates',
    description:
      'Group multiple xote signal updates to reduce repeated observer work and keep reactive interfaces efficient.',
    section: 'Advanced',
  },
  {
    path: '/docs/view/overview',
    title: 'View - xote DOM and JSX APIs',
    description:
      'Build xote views with JSX, reactive DOM nodes, attributes, event handlers, lists, and mounting APIs.',
    section: 'Core Modules',
  },
  {
    path: '/docs/components/overview',
    title: 'Components - xote View Components',
    description:
      'Build reusable xote components with ReScript JSX, typed props, reactive views, and component composition.',
    section: 'Core Modules',
  },
  {
    path: '/docs/core-concepts/context',
    title: 'Context - xote Scoped Values',
    description:
      'Provide values to a xote component subtree with Context, scoped per instance and safe for server rendering.',
    section: 'Core Modules',
  },
  {
    path: '/docs/core-concepts/resources',
    title: 'Resources - xote Async Data and Suspense',
    description:
      'Load asynchronous data as xote signals with Resource, and show a fallback with View.Suspense while it loads.',
    section: 'Core Modules',
  },
  {
    path: '/docs/router/overview',
    title: 'Router - xote Signal-Based Routing',
    description:
      'Use the xote router for client-side navigation, route patterns, dynamic params, links, and location signals.',
    section: 'Router',
  },
  {
    path: '/docs/api/signal',
    title: 'Signal API - xote Reference',
    description:
      'Reference the xote Signal API including make, get, peek, set, update, batch, and untrack.',
    section: 'API Reference',
  },
  {
    path: '/docs/api/signals',
    title: 'Signal API - xote Reference',
    description:
      'Reference the xote Signal API including make, get, peek, set, update, batch, and untrack.',
    section: 'API Reference',
  },
  {
    path: '/docs/api/computed',
    title: 'Computed API - xote Reference',
    description:
      'Reference the xote Computed API for derived signals, lazy recomputation, equality, and disposal.',
    section: 'API Reference',
  },
  {
    path: '/docs/api/effect',
    title: 'Effect API - xote Reference',
    description:
      'Reference the xote Effect API for reactive side effects, cleanup callbacks, and manual disposal.',
    section: 'API Reference',
  },
  {
    path: '/docs/api/view',
    title: 'View API - xote Reference',
    description:
      'Reference the xote View API for UI nodes, JSX primitives, lists, attributes, and mounting.',
    section: 'API Reference',
  },
  {
    path: '/docs/comparisons/react',
    title: 'xote vs React - ReScript UI Framework Comparison',
    description:
      'Compare xote and React across reactivity, effects, lifecycle, SSR, routing, bundle size, type safety, and ecosystem tradeoffs.',
    section: 'Comparisons',
  },
  {
    path: '/docs/comparisons/solidjs',
    title: 'xote vs SolidJS - Signal Framework Comparison',
    description:
      'Compare xote and SolidJS across signals, components, list rendering, SSR, routing, bundle size, type safety, and ecosystem fit.',
    section: 'Comparisons',
  },
  {
    path: '/docs/technical-overview',
    title: 'Technical Overview - xote Architecture',
    description:
      'Dive into xote internals including scheduling, reactive graph behavior, view rendering, hydration markers, and router architecture.',
    section: 'Advanced',
  },
  {
    path: '/docs/changelog',
    title: 'Changelog - xote Releases',
    description:
      'Review xote release notes, API changes, compatibility updates, and migration notes.',
    section: 'Project',
    priority: '0.6',
  },
]

// Suppress expected SSR errors from client-only code that defers DOM access.
process.on('uncaughtException', (err) => {
  if (err.message?.includes('document is not defined') ||
      err.message?.includes('window is not defined')) {
    return
  }
  console.error('Uncaught exception:', err)
  process.exit(1)
})

async function prerender() {
  // Read the built index.html template (produced by vite build)
  const template = fs.readFileSync(path.join(buildDir, 'index.html'), 'utf-8')

  // Load the SSR server entry (built by vite build --ssr)
  const { render } = await import('../build/server/EntryServer.res.js')

  console.log(`Pre-rendering ${routes.length} routes for ${siteUrl}...\n`)

  for (const route of routes) {
    // Render the app HTML for this route
    const appHtml = render(route.path)

    // Inject into the template
    const html = injectSeoHead(
      template.replace('<!--ssr-outlet-->', appHtml),
      route
    )

    // Write to the correct directory structure
    // e.g., "/" -> build/client/index.html (already exists, overwrite)
    //        "/docs" -> build/client/docs/index.html
    const filePath = route.path === '/'
      ? path.join(buildDir, 'index.html')
      : path.join(buildDir, route.path, 'index.html')

    // Ensure directory exists
    const dir = path.dirname(filePath)
    fs.mkdirSync(dir, { recursive: true })

    fs.writeFileSync(filePath, html)
    console.log(`  ${route.path} -> ${path.relative(buildDir, filePath)}`)
  }

  writeSitemap()
  writeRobots()
  writeMarkdown()

  console.log('\nPre-rendering complete!')
}

function normalizeSiteUrl(value) {
  return value.replace(/\/+$/, '')
}

function routeUrl(routePath) {
  return `${siteUrl}${routePath === '/' ? '/' : routePath}`
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function injectSeoHead(html, route) {
  const canonical = routeUrl(route.path)
  const title = route.title || 'xote - A ReScript Library for Building User Interfaces'
  const description = route.description || defaultDescription
  const structuredData = makeStructuredData(route, canonical, title, description)
  const tags = `
  <link rel="canonical" href="${escapeHtml(canonical)}">
  <meta property="og:site_name" content="${siteName}">
  <meta property="og:type" content="${route.type || 'article'}">
  <meta property="og:url" content="${escapeHtml(canonical)}">
  <meta property="og:title" content="${escapeHtml(title)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta name="twitter:card" content="summary">
  <meta name="twitter:title" content="${escapeHtml(title)}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <script type="application/ld+json">${JSON.stringify(structuredData)}</script>`

  return html
    .replace(/<title>.*?<\/title>/s, `<title>${escapeHtml(title)}</title>`)
    .replace(
      /<meta name="description" content=".*?">/s,
      `<meta name="description" content="${escapeHtml(description)}">`
    )
    .replace('</head>', `${tags}\n</head>`)
}

function makeStructuredData(route, canonical, title, description) {
  const base = {
    '@context': 'https://schema.org',
    '@type': route.type === 'website' ? 'WebPage' : 'TechArticle',
    name: title,
    headline: title,
    description,
    url: canonical,
    isPartOf: {
      '@type': 'WebSite',
      name: siteName,
      url: `${siteUrl}/`,
    },
  }

  if (route.section) {
    base.articleSection = route.section
  }

  if (route.path === '/') {
    return {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: siteName,
      description,
      url: canonical,
      potentialAction: {
        '@type': 'SearchAction',
        target: `${siteUrl}/docs?query={search_term_string}`,
        'query-input': 'required name=search_term_string',
      },
    }
  }

  return base
}

function writeSitemap() {
  const now = new Date().toISOString().slice(0, 10)
  const entries = routes.map((route) => `  <url>
    <loc>${escapeHtml(routeUrl(route.path))}</loc>
    <lastmod>${now}</lastmod>
    <changefreq>${route.path === '/' ? 'weekly' : 'monthly'}</changefreq>
    <priority>${route.priority || '0.7'}</priority>
  </url>`).join('\n')
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${entries}
</urlset>
`

  fs.writeFileSync(path.join(buildDir, 'sitemap.xml'), sitemap)
  console.log('  sitemap.xml')
}

function writeRobots() {
  const robots = `User-agent: *
Allow: /

Sitemap: ${siteUrl}/sitemap.xml
`

  fs.writeFileSync(path.join(buildDir, 'robots.txt'), robots)
  console.log('  robots.txt')
}

// ---- Agent layer: plain-Markdown copies of every docs page + llms.txt ----

const docsDir = path.join(__dirname, '..', 'src', 'docs')

// Each docs route and the MDX sources that make up its agent layer (the page,
// then its API reference where one exists).
const markdownSources = {
  '/docs': ['IntroDoc'],
  '/docs/getting-started/rescript': ['LearningReScriptDoc'],
  '/docs/getting-started/javascript-typescript': ['JavaScriptTypeScriptDoc'],
  '/docs/core-concepts/signals': ['SignalsDoc', 'ApiSignalDoc'],
  '/docs/core-concepts/computed': ['ComputedDoc', 'ApiComputedDoc'],
  '/docs/core-concepts/effects': ['EffectsDoc', 'ApiEffectDoc'],
  '/docs/core-concepts/context': ['ContextDoc'],
  '/docs/core-concepts/resources': ['ResourcesDoc'],
  '/docs/view/overview': ['ViewsDoc', 'ApiViewDoc'],
  '/docs/components/overview': ['ViewsDoc', 'ApiViewDoc'],
  '/docs/router/overview': ['RouterDoc'],
  '/docs/advanced/ssr': ['SSRDoc'],
  '/docs/advanced/mdx-support': ['MdxDoc'],
  '/docs/advanced/batching': ['BatchingDoc'],
  '/docs/api/signal': ['ApiSignalDoc'],
  '/docs/api/signals': ['ApiSignalDoc'],
  '/docs/api/computed': ['ApiComputedDoc'],
  '/docs/api/effect': ['ApiEffectDoc'],
  '/docs/api/view': ['ApiViewDoc'],
  '/docs/comparisons/react': ['ReactComparisonDoc'],
  '/docs/comparisons/solidjs': ['SolidJSComparisonDoc'],
  '/docs/technical-overview': ['TechnicalOverviewDoc'],
}

function markdownPath(routePath) {
  return routePath === '/docs' ? '/docs/index.md' : `${routePath}.md`
}

function pageTitle(route) {
  const [first, second] = route.title.split(/ [-—] /)
  return first === 'xote Docs' && second ? second : first
}

// MDX to plain Markdown: keep prose and code fences, turn example panels into
// fenced code, and drop imports, exports and other top-level JSX.
function mdxToMarkdown(source) {
  const out = []
  const lines = source.split('\n')
  let inFence = false
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (/^\s*```/.test(line)) {
      inFence = !inFence
      out.push(line)
      continue
    }
    if (inFence) {
      out.push(line)
      continue
    }
    if (/^\s*<DocsExamplePanel/.test(line)) {
      let block = line
      while (!/<\/DocsExamplePanel>/.test(block) && i < lines.length - 1) {
        i++
        block += '\n' + lines[i]
      }
      const filename = /filename="([^"]+)"/.exec(block)
      const code = /code=\{`([\s\S]*?)`\}/.exec(block)
      if (code) {
        if (filename) out.push(`\`${filename[1]}\`:`, '')
        out.push('```rescript', code[1].replace(/\\`/g, '`'), '```')
      }
      continue
    }
    if (/^(import|export) /.test(line) || /^\s*<[A-Z][\w.]*[^>]*\/>\s*$/.test(line)) continue
    out.push(line)
  }
  return out.join('\n').replace(/\n{3,}/g, '\n\n').trim()
}

function writeMarkdown() {
  const entries = []
  for (const route of routes) {
    const sources = markdownSources[route.path]
    const title = pageTitle(route)
    let body
    if (sources) {
      body = sources
        .map((name, index) => {
          const md = mdxToMarkdown(fs.readFileSync(path.join(docsDir, `${name}.mdx`), 'utf-8'))
          return index === 0 ? md : `## API reference\n\n${md.replace(/^(#{1,5}) /gm, '#$1 ')}`
        })
        .join('\n\n')
    } else if (route.path === '/docs/changelog') {
      body = `Release notes for every version are published at https://github.com/brnrdog/xote/releases.`
    } else {
      continue
    }
    const markdown = `# ${title}\n\n> ${route.description}\n\nSource: ${routeUrl(route.path)} · Xote ${latestVersion()}\n\n${body}\n`
    const filePath = path.join(buildDir, markdownPath(route.path))
    fs.mkdirSync(path.dirname(filePath), { recursive: true })
    fs.writeFileSync(filePath, markdown)
    entries.push({ route, title })
  }
  console.log(`  ${entries.length} Markdown pages`)

  const sections = new Map()
  for (const { route, title } of entries) {
    const section = route.section || 'Docs'
    if (!sections.has(section)) sections.set(section, [])
    sections.get(section).push(`- [${title}](${siteUrl}${markdownPath(route.path)}): ${route.description}`)
  }
  const llms = `# Xote

> Xote is a small UI library for ReScript with fine-grained reactivity: signals, computeds and effects, declarative views with JSX, a router, server-side rendering and hydration.

Every docs page is available as plain Markdown at the same path with a \`.md\` suffix (\`/docs\` is \`/docs/index.md\`). Pages about a module include its API reference.

${[...sections].map(([name, items]) => `## ${name}\n\n${items.join('\n')}`).join('\n\n')}
`
  fs.writeFileSync(path.join(buildDir, 'llms.txt'), llms)
  console.log('  llms.txt')
}

function latestVersion() {
  const repoData = fs.readFileSync(path.join(__dirname, '..', 'src', 'RepoData.res'), 'utf-8')
  const match = /let latestVersion = "([^"]+)"/.exec(repoData)
  return match ? match[1] : ''
}

prerender()
