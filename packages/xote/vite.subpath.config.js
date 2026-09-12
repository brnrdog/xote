import { defineConfig } from "vite";
import { readFileSync } from "node:fs";

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
      entry: {
        client: "entries/client.mjs",
        router: "entries/router.mjs",
        ssr: "entries/ssr.mjs",
        hydration: "entries/hydration.mjs",
        mdx: "entries/mdx.mjs",
      },
      formats: ["es", "cjs"],
      fileName: (format, entryName) =>
        format === "es" ? `${entryName}.mjs` : `${entryName}.cjs`,
    },
    rollupOptions: {
      external: externals,
    },
    emptyOutDir: false,
  },
}));
