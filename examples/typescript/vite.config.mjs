import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  server: {
    port: 3001,
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
