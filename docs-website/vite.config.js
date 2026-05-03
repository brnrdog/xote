import { defineConfig } from 'vite'
import mdx from '@mdx-js/rollup'

export default defineConfig({
  base: '/',
  plugins: [
    mdx({
      jsxImportSource: 'xote',
      jsxRuntime: 'automatic',
    }),
  ],
  server: {
    port: 3000,
  },
  build: {
    outDir: 'build/client',
  },
  resolve: {
    preserveSymlinks: true,
  },
  ssr: {
    noExternal: ['xote', 'rescript-signals', 'basefn'],
  },
})
