import { defineConfig } from "vite";
import path from "node:path";
import { readFileSync } from "node:fs";

// Read package.json to auto-externalize deps & name the UMD build
const pkg = JSON.parse(
  readFileSync(new URL("./package.json", import.meta.url), "utf-8")
);

// Allow overriding the entry with ENV: ENTRY=src/whatever.ts
const entryFromEnv = process.env.ENTRY;

export default defineConfig(() => ({
  plugins: [],
  build: {
    outDir: "dist",
    target: 'es2020',
    sourcemap: false,
    lib: {
      entry: 'src/Xote.res.mjs',
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
      external: [
        ...Object.keys(pkg.dependencies ?? {}),
        ...Object.keys(pkg.peerDependencies ?? {}),
      ],
      output: {
      },
    },
    emptyOutDir: true,
  },
}));
