import { defineConfig } from 'vite'
import mdx from '@mdx-js/rollup'
import remarkGfm from 'remark-gfm'
import rehypeSlug from 'rehype-slug'

export default defineConfig({
  base: '/',
  plugins: [
    mdx({
      jsxImportSource: 'xote',
      jsxRuntime: 'automatic',
      remarkPlugins: [remarkGfm],
      rehypePlugins: [rehypeSlug],
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
