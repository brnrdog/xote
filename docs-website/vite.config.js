import { defineConfig } from 'vite'
import mdx from '@mdx-js/rollup'
import remarkGfm from 'remark-gfm'
import rehypeSlug from 'rehype-slug'

// MDX removes up to two leading spaces from every line of an expression, which
// flattens the indentation of the code shown in <DocsExamplePanel code={`...`}>.
// Add them back before MDX parses the file, so the panel shows the code as
// written.
const keepExampleCodeIndentation = () => ({
  name: 'keep-example-code-indentation',
  enforce: 'pre',
  transform(source, id) {
    if (!id.endsWith('.mdx')) return null
    return source.replace(/code=\{`([\s\S]*?)(?<!\\)`\}/g, (_, code) =>
      `code={\`${code.replace(/\n(?=[ \t])/g, '\n  ')}\`}`,
    )
  },
})

export default defineConfig({
  base: '/',
  plugins: [
    keepExampleCodeIndentation(),
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
  optimizeDeps: {
    exclude: ['xote'],
  },
  resolve: {
    preserveSymlinks: true,
  },
  ssr: {
    noExternal: ['xote', 'rescript-signals', 'basefn'],
  },
})
