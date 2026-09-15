import { defineConfig } from "vite";
import { fileURLToPath } from "node:url";

/* One classic script, no imports, no `export`.
 *
 * That is what an embedded JavaScript engine can evaluate, and it is the same
 * requirement on both platforms — JavaScriptCore on iOS and QuickJS or Hermes
 * on Android all want a single script with no module loader. So there is **one
 * bundle**, built here, and each host points its own resource pipeline at it.
 * Nothing in the bundle knows which platform it is going to.
 *
 * Minification is off so the bundle stays readable in a device debugger; a
 * shipping app would turn it on. */
const app = process.env.XOTE_APP ?? "tracker";

export default defineConfig({
  root: fileURLToPath(new URL(".", import.meta.url)),
  define: { __XOTE_APP__: JSON.stringify(app) },
  build: {
    outDir: "dist",
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
