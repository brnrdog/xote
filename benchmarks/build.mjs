/*
 * Builds every benchmark app into `dist/<app>` with production settings.
 *
 * Each app is built with the same Vite version, target and minifier so the
 * bundle-size comparison only reflects framework payload.
 */

import { rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "vite";

const here = path.dirname(fileURLToPath(import.meta.url));

const TARGET = "es2022";

async function pluginsFor(app) {
  switch (app) {
    case "react": {
      const { default: react } = await import("@vitejs/plugin-react");
      return [react()];
    }
    case "vue": {
      const { default: vue } = await import("@vitejs/plugin-vue");
      return [vue()];
    }
    case "solid": {
      const { default: solid } = await import("vite-plugin-solid");
      return [solid()];
    }
    default:
      return [];
  }
}

export const APPS = ["xote", "react", "vue", "solid"];

async function buildApp(app) {
  const root = path.join(here, "apps", app);
  const outDir = path.join(here, "dist", app);

  await rm(outDir, { recursive: true, force: true });

  await build({
    root,
    base: "./",
    logLevel: "warn",
    plugins: await pluginsFor(app),
    define: { "process.env.NODE_ENV": '"production"' },
    build: {
      outDir,
      emptyOutDir: true,
      target: TARGET,
      minify: "esbuild",
      sourcemap: false,
      modulePreload: { polyfill: false },
      reportCompressedSize: false,
      rollupOptions: {
        output: {
          entryFileNames: "assets/[name].js",
          chunkFileNames: "assets/[name].js",
          assetFileNames: "assets/[name][extname]",
        },
      },
    },
  });

  console.log(`built ${app}`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  for (const app of APPS) {
    await buildApp(app);
  }
  console.log("\nAll apps built into benchmarks/dist/");
}

export { buildApp };
