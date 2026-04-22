// Aggregated entry point for the bundled distribution (UMD/CJS/ES single-file
// builds in dist/). ReScript consumers should import individual modules
// directly from `xote/src/<Module>.res.mjs` (or via `Xote.<Module>` after
// `open Xote`) so bundlers can tree-shake at module granularity. This file
// only exists to give Vite a single entry for the legacy library bundle.

export * as Node from "./Node.res.mjs";
export * as View from "./View.res.mjs";
export * as Html from "./Html.res.mjs";
export * as XoteJSX from "./XoteJSX.res.mjs";
export * as ReactiveProp from "./ReactiveProp.res.mjs";
export * as Prop from "./Prop.res.mjs";
export * as Route from "./Route.res.mjs";
export * as Router from "./Router.res.mjs";
export * as SSR from "./SSR.res.mjs";
export * as SSRContext from "./SSRContext.res.mjs";
export * as SSRState from "./SSRState.res.mjs";
export * as Hydration from "./Hydration.res.mjs";
export * as Signal from "./Signal.res.mjs";
export * as Computed from "./Computed.res.mjs";
export * as Effect from "./Effect.res.mjs";
