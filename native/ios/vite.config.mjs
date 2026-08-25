import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

/* One classic script, no imports, no `export` — what JavaScriptCore can
 * evaluate. Minification is off so the bundle stays readable in the Xcode
 * debugger; a shipping app would turn it on. */
export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  build: {
    outDir: "XoteNative/Resources",
    emptyOutDir: false,
    minify: false,
    lib: {
      entry: fileURLToPath(new URL("./bootstrap.mjs", import.meta.url)),
      formats: ["iife"],
      name: "XoteApp",
      fileName: () => "xote-app.js",
    },
  },
});
