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

// All routes to pre-render (app-relative paths, without base path)
const routes = [
  '/',
  '/demos',
  '/docs',
  '/docs/core-concepts/signals',
  '/docs/core-concepts/computed',
  '/docs/core-concepts/effects',
  '/docs/advanced/ssr',
  '/docs/advanced/batching',
  '/docs/components/overview',
  '/docs/router/overview',
  '/docs/api/signals',
  '/docs/comparisons/react',
  '/docs/technical-overview',
  '/docs/demos/counter',
  '/docs/demos/todo',
  '/docs/demos/color-mixer',
  '/docs/demos/reaction-game',
  '/docs/demos/solitaire',
  '/docs/demos/memory-match',
  '/docs/demos/snake',
]

// Suppress expected SSR errors from client-only code (e.g., basefn Icon
// component deferring document.getElementById via setTimeout)
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

  console.log(`Pre-rendering ${routes.length} routes...\n`)

  for (const route of routes) {
    // Render the app HTML for this route
    const appHtml = render(route)

    // Inject into the template
    const html = template.replace('<!--ssr-outlet-->', appHtml)

    // Write to the correct directory structure
    // e.g., "/" → build/client/index.html (already exists, overwrite)
    //        "/docs" → build/client/docs/index.html
    const filePath = route === '/'
      ? path.join(buildDir, 'index.html')
      : path.join(buildDir, route, 'index.html')

    // Ensure directory exists
    const dir = path.dirname(filePath)
    fs.mkdirSync(dir, { recursive: true })

    fs.writeFileSync(filePath, html)
    console.log(`  ${route} → ${path.relative(buildDir, filePath)}`)
  }

  console.log('\nPre-rendering complete!')
}

prerender()
