import { defineConfig } from 'vite';
import path from 'node:path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.join(__dirname, '../..');

export default defineConfig({
  root: __dirname,
  resolve: {
    alias: {
      // Map xote source files
      'xote': path.join(projectRoot, 'src/Xote.res.mjs'),
    }
  },
  server: {
    port: 3000,
  },
  optimizeDeps: {
    include: ['rescript-signals']
  }
});
