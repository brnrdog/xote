import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createServer as createViteServer } from 'vite'
import http from 'node:http'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const isProduction = process.env.NODE_ENV === 'production'
const port = process.env.PORT || 3000
const base = '/xote/'

// Handle async errors from SSR-rendered code that defers DOM access
// (e.g., basefn Icon component uses setTimeout + document.getElementById)
process.on('uncaughtException', (err) => {
  if (err.message?.includes('document is not defined') ||
      err.message?.includes('window is not defined')) {
    // Expected during SSR: client-only code deferring DOM operations
    return
  }
  console.error('Uncaught exception:', err)
  process.exit(1)
})

async function createServer() {
  let vite

  if (!isProduction) {
    // Development: create Vite dev server in middleware mode
    vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'custom',
    })
  }

  const server = http.createServer(async (req, res) => {
    const url = req.url

    // Skip non-page requests in production
    if (isProduction) {
      // Serve static files from build/client
      const staticPath = path.join(__dirname, 'build/client', url)
      if (fs.existsSync(staticPath) && fs.statSync(staticPath).isFile()) {
        const ext = path.extname(staticPath)
        const mimeTypes = {
          '.js': 'text/javascript',
          '.mjs': 'text/javascript',
          '.css': 'text/css',
          '.html': 'text/html',
          '.json': 'application/json',
          '.png': 'image/png',
          '.jpg': 'image/jpeg',
          '.svg': 'image/svg+xml',
          '.ico': 'image/x-icon',
          '.woff': 'font/woff',
          '.woff2': 'font/woff2',
        }
        res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' })
        fs.createReadStream(staticPath).pipe(res)
        return
      }
    }

    try {
      // Strip base path to get the app-relative URL
      let appUrl = url
      if (appUrl.startsWith(base)) {
        appUrl = url.slice(base.length - 1) || '/'
      } else if (appUrl === base.slice(0, -1)) {
        appUrl = '/'
      }

      // 1. Read the index.html template
      let template
      if (isProduction) {
        template = fs.readFileSync(
          path.join(__dirname, 'build/client/index.html'),
          'utf-8'
        )
      } else {
        template = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf-8')
        // Apply Vite HTML transforms (injects HMR client, etc.)
        template = await vite.transformIndexHtml(url, template)
      }

      // 2. Load the server entry module
      let render
      if (isProduction) {
        const serverModule = await import('./build/server/EntryServer.res.mjs')
        render = serverModule.render
      } else {
        const serverModule = await vite.ssrLoadModule('/src/EntryServer.res.mjs')
        render = serverModule.render
      }

      // 3. Render the app HTML
      const appHtml = render(appUrl)

      // 4. Inject the rendered HTML into the template
      const html = template.replace('<!--ssr-outlet-->', appHtml)

      // 5. Send the response
      res.writeHead(200, { 'Content-Type': 'text/html' })
      res.end(html)
    } catch (e) {
      // Fix stack traces in development
      if (!isProduction && vite) {
        vite.ssrFixStacktrace(e)
      }
      console.error(e)
      res.writeHead(500, { 'Content-Type': 'text/plain' })
      res.end(e.message)
    }
  })

  // In development, use Vite's connect middleware for static files and HMR
  if (!isProduction && vite) {
    const originalHandler = server.listeners('request')[0]
    server.removeAllListeners('request')
    server.on('request', (req, res) => {
      // Let Vite handle static assets and HMR
      vite.middlewares(req, res, () => {
        originalHandler(req, res)
      })
    })
  }

  server.listen(port, () => {
    console.log(`SSR server running at http://localhost:${port}${base}`)
  })
}

createServer()
