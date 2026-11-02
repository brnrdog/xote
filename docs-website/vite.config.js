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

// Agent-layer pages (src/docs/agent/*.mdx) render on the same page as the
// human layer, so their heading ids get an "agent-" prefix to stay unique.
// generate-docs-index.mjs applies the same prefix to their tables of contents.
const prefixAgentIds = () => (tree, file) => {
  if (!file.path || !file.path.includes('/src/docs/agent/')) return
  const visit = node => {
    if (node.type === 'element' && node.properties && node.properties.id) {
      node.properties.id = `agent-${node.properties.id}`
    }
    if (node.children) node.children.forEach(visit)
  }
  visit(tree)
}

export default defineConfig({
  base: '/',
  plugins: [
    keepExampleCodeIndentation(),
    mdx({
      jsxImportSource: 'xote',
      jsxRuntime: 'automatic',
      remarkPlugins: [remarkGfm],
      rehypePlugins: [rehypeSlug, prefixAgentIds],
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
