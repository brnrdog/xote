import { defineConfig } from 'vite'

export default defineConfig({
  base: '/',
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
