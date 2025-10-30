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
  build: {
    outDir: "dist",
    sourcemap: true,
    lib: {
      // Default entry is src/index.ts; override with ENTRY env var
      entry: path.resolve(process.cwd(), entryFromEnv ?? "src/Xote.res.mjs"),
      // A safe global name for UMD; falls back to "Library"
      name:
        (pkg.name?.replace?.(/[^a-zA-Z0-9_$]/g, "_")) ||
        "xote",
      formats: ["es", "cjs", "umd"],
      fileName: (format) =>
        format === "es"
          ? "index.mjs"
          : format === "cjs"
          ? "index.cjs"
          : "index.umd.js",
    },
    rollupOptions: {
      external: [
        ...Object.keys(pkg.dependencies ?? {}),
        ...Object.keys(pkg.peerDependencies ?? {}),
      ],
      output: {
      },
    },
    // Tweak if you want smaller/faster builds
    minify: "esbuild",
    target: "es2019",
    emptyOutDir: true,
  },
}));
