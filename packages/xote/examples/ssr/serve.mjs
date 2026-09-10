/**
 * Simple development server for testing SSR + hydration
 * Run with: node examples/ssr/serve.mjs
 */
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = 3000;

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
};

// Root of the project
const projectRoot = path.join(__dirname, '../..');

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  let filePath = urlPath === '/' ? '/index.html' : urlPath;

  // Handle source map requests
  if (filePath.endsWith('.map')) {
    res.writeHead(404);
    res.end();
    return;
  }

  // Resolve file path - the browser will request paths relative to the HTML location
  // e.g., client.res.mjs imports "../../src/Xote.res.mjs"
  // Browser requests: /src/Xote.res.mjs (after resolving from /client.res.mjs)
  let fullPath;

  // First, try the ssr directory (for local files like client.res.mjs, App.res.mjs)
  fullPath = path.join(__dirname, filePath);

  // If not found, try from project root (for paths like /src/... or /node_modules/...)
  if (!fs.existsSync(fullPath)) {
    fullPath = path.join(projectRoot, filePath);
  }

  // Handle relative parent paths that got normalized by the browser
  // Browser sees ../../src/Xote.res.mjs from /client.res.mjs → requests /src/Xote.res.mjs
  if (!fs.existsSync(fullPath) && filePath.startsWith('/src/')) {
    fullPath = path.join(projectRoot, filePath);
  }

  // Handle node_modules
  if (!fs.existsSync(fullPath) && filePath.startsWith('/node_modules/')) {
    fullPath = path.join(projectRoot, filePath);
  }

  // Check if file exists
  if (!fs.existsSync(fullPath)) {
    console.log(`404: ${filePath}`);
    res.writeHead(404);
    res.end(`Not found: ${filePath}`);
    return;
  }

  const ext = path.extname(fullPath);
  const contentType = MIME_TYPES[ext] || 'text/plain';

  fs.readFile(fullPath, (err, data) => {
    if (err) {
      console.error(`Error reading ${fullPath}:`, err);
      res.writeHead(500);
      res.end('Server error');
      return;
    }

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════╗
║           Xote SSR Demo Server                     ║
╠════════════════════════════════════════════════════╣
║  Open: http://localhost:${PORT}                       ║
║                                                    ║
║  • Page loads with server-rendered HTML            ║
║  • Click buttons to test hydration                 ║
║  • Check console for hydration messages            ║
╚════════════════════════════════════════════════════╝
`);
});
