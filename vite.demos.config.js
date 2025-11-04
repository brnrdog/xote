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
        counter: resolve(__dirname, 'demos/counter.html'),
        todo: resolve(__dirname, 'demos/todo.html'),
        color: resolve(__dirname, 'demos/color.html'),
        reaction: resolve(__dirname, 'demos/reaction.html'),
        solitaire: resolve(__dirname, 'demos/solitaire.html'),
        match: resolve(__dirname, 'demos/match.html'),
        bookstore: resolve(__dirname, 'demos/bookstore.html'),
      }
    }
  }
});
