import mdx from "@mdx-js/rollup";
import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  plugins: [
    mdx({
      jsxImportSource: "xote",
      jsxRuntime: "automatic",
    }),
  ],
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
