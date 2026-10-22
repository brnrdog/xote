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
import { pages as docsPages, redirects } from '../docs.pages.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const buildDir = path.join(__dirname, '..', 'build', 'client')
const siteUrl = normalizeSiteUrl(process.env.SITE_URL || 'https://xote.dev')
const siteName = 'xote'
const defaultDescription =
  'A small UI library for ReScript with fine-grained reactivity. Signals, computeds, and effects recompute only what changed.'

// A registered page whose MDX file is not written yet is left out (the docs
// index generator skips it too).
function pageIsWritten(page) {
  return !page.file || fs.existsSync(path.join(__dirname, '..', 'src', 'docs', `${page.file}.mdx`))
}

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
  // Every docs page, from the registry in docs.pages.mjs.
  ...docsPages.filter(pageIsWritten).map(page => ({
    path: page.path,
    title: `xote Docs - ${page.pageTitle ?? page.title}`,
    description: page.lead,
    section: page.section,
    priority: page.path === '/docs' ? '0.9' : page.path === '/docs/changelog' ? '0.6' : '0.7',
    page,
  })),
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

  writeRedirects()
  writeSitemap()
  writeRobots()
  writeMarkdown()

  console.log('\nPre-rendering complete!')
}

// Older docs URLs get a small page that forwards to the current one, keeping
// any #anchor, with a canonical link and a no-script fallback.
function writeRedirects() {
  for (const [from, to] of Object.entries(redirects)) {
    const target = escapeHtml(to)
    const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Moved to ${target}</title>
<link rel="canonical" href="${escapeHtml(routeUrl(to))}">
<meta name="robots" content="noindex">
<meta http-equiv="refresh" content="0; url=${target}">
<script>location.replace(${JSON.stringify(to)} + location.hash)</script>
</head>
<body><p>This page moved to <a href="${target}">${target}</a>.</p></body>
</html>
`
    const filePath = path.join(buildDir, from, 'index.html')
    fs.mkdirSync(path.dirname(filePath), { recursive: true })
    fs.writeFileSync(filePath, html)
  }
  console.log(`  ${Object.keys(redirects).length} redirects`)
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

// The MDX sources that make up a page's agent layer: the page's agent version
// (src/docs/agent/<File>.mdx) when it has one, else the page itself, then its
// API reference where one exists. Paths are relative to src/docs.
function markdownSources(route) {
  const page = route.page
  if (!page?.file || page.customToc) return undefined
  const agentVersion = path.join('agent', page.file)
  const main = fs.existsSync(path.join(docsDir, `${agentVersion}.mdx`)) ? agentVersion : page.file
  return page.agent?.api ? [main, page.agent.api] : [main]
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
    const sources = markdownSources(route)
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

Every docs page is available as plain Markdown at the same path with a \`.md\` suffix (\`/docs\` is \`/docs/index.md\`). These are the agent versions of the pages, written for coding agents rather than copied from the human pages: most follow the same outline (Summary, Availability, Rules, API, Patterns, Anti-patterns, Edge cases, SSR and hydration, Verify, Related), and pages about a module end with its full API reference. Terms such as "tracking scope", "reactive leaf" and "owner" are defined in the [Glossary](${siteUrl}/docs/glossary.md).

Current stable release: ${latestVersion()}. Features marked "pre-release: 7.2.0-beta" in a page's Availability section are not in the stable release.

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
