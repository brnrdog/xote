import { defineConfig } from 'vite'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))

// Bundles the browser entry. Server code (loaders, actions, NotesDb) is never
// imported from it, so it stays out of the bundle.
export default defineConfig({
  build: {
    outDir: path.join(here, 'dist'),
    emptyOutDir: true,
    lib: {
      entry: path.join(here, 'app/NotesClient.res.mjs'),
      formats: ['es'],
      fileName: () => 'client.js',
    },
  },
})
