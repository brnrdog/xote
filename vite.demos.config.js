import { defineConfig } from "vite";
import { resolve } from 'path';

export default defineConfig({
  root: '.',
  base: './',  // Relative paths so it works when copied to static folder
  build: {
    outDir: 'demos-dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        counter: resolve(__dirname, 'counter.html'),
        todo: resolve(__dirname, 'todo.html'),
        color: resolve(__dirname, 'color.html'),
        reaction: resolve(__dirname, 'reaction.html'),
        solitaire: resolve(__dirname, 'solitaire.html'),
      }
    }
  }
});
