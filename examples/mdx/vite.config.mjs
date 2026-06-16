import mdx from "@mdx-js/rollup";
import remarkGfm from "remark-gfm";
import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  plugins: [
    mdx({
      jsxImportSource: "xote",
      jsxRuntime: "automatic",
      remarkPlugins: [remarkGfm],
    }),
  ],
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
