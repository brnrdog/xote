import { defineConfig } from "vite";
import { readFileSync } from "node:fs";

// Read package.json to auto-externalize deps & name the UMD build
const pkg = JSON.parse(
  readFileSync(new URL("./package.json", import.meta.url), "utf-8")
);

const externals = [
  ...Object.keys(pkg.dependencies ?? {}),
  ...Object.keys(pkg.peerDependencies ?? {}),
];

export default defineConfig(() => ({
  plugins: [],
  build: {
    outDir: "dist",
    target: "es2020",
    sourcemap: false,
    lib: {
      entry: "entries/client.mjs",
      name: "xote",
      formats: ["es", "cjs", "umd"],
      fileName: (format) =>
        format === "es"
          ? "xote.mjs"
          : format === "cjs"
            ? "xote.cjs"
            : "xote.umd.js",
    },
    rollupOptions: {
      external: externals,
    },
    emptyOutDir: true,
  },
}));
