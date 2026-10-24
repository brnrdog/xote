/**
 * Node adapter for the fullstack example.
 *
 * The app itself is a web-standard `Request => Promise<Response>` handler
 * (`app/NotesServer.res`). This file only serves the built assets and turns
 * Node's request/response pair into that shape. On Bun it would be:
 *
 *   Bun.serve({ fetch: handler })
 *
 * Run: npm run fullstack:build && npm run fullstack:start
 */
import http from 'node:http'
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { handler } from './app/NotesServer.res.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const PORT = Number(process.env.PORT ?? 3000)

const assets = {
  '/assets/client.js': [path.join(here, 'dist/client.js'), 'text/javascript'],
  '/assets/styles.css': [path.join(here, 'public/styles.css'), 'text/css'],
}

async function toRequest(req) {
  const chunks = []
  for await (const chunk of req) chunks.push(chunk)
  const body = chunks.length > 0 ? Buffer.concat(chunks) : undefined
  return new Request(`http://${req.headers.host ?? 'localhost'}${req.url}`, {
    method: req.method,
    headers: req.headers,
    body: req.method === 'GET' || req.method === 'HEAD' ? undefined : body,
  })
}

async function send(res, response) {
  res.writeHead(response.status, Object.fromEntries(response.headers))
  res.end(Buffer.from(await response.arrayBuffer()))
}

const server = http.createServer(async (req, res) => {
  try {
    const asset = assets[req.url.split('?')[0]]
    if (asset) {
      const [file, type] = asset
      res.writeHead(200, { 'content-type': type })
      res.end(await fs.readFile(file))
      return
    }
    await send(res, await handler(await toRequest(req)))
  } catch (error) {
    console.error(error)
    res.writeHead(500)
    res.end('Internal error')
  }
})

server.listen(PORT, () => {
  console.log(`xote fullstack example on http://localhost:${PORT}`)
})
