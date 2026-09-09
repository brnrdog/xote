import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  server: { port: 3100 },
  optimizeDeps: { include: ["rescript-signals"] },
  build: { outDir: "dist", emptyOutDir: true, rollupOptions: { input: ["preview.html", "tracker.html"] } },
});
