import { defineConfig } from 'vite'

export default defineConfig({
  base: '/xote/',
  server: {
    port: 3000,
  },
  build: {
    outDir: 'build',
  },
})
