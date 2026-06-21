import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const srcDir = join(root, "src");
const outDir = join(root, "dist", "types", "src");

const modules = [
  { source: "TypeScriptSignal", output: "Signal" },
  { source: "TypeScriptComputed", output: "Computed" },
  { source: "TypeScriptEffect", output: "Effect" },
  { source: "TypeScriptProp", output: "Prop" },
  { source: "TypeScriptView", output: "View" },
  { source: "TypeScriptHtml", output: "Html" },
  { source: "TypeScriptRoute", output: "Route" },
  { source: "TypeScriptRouter", output: "Router" },
  { source: "TypeScriptSSR", output: "SSR" },
  { source: "TypeScriptSSRContext", output: "SSRContext" },
  { source: "TypeScriptHydration", output: "Hydration" },
  { source: "TypeScriptMdx", output: "Mdx" },
];

const readGenType = (moduleName) => {
  const path = join(srcDir, `${moduleName}.gen.tsx`);
  try {
    return readFileSync(path, "utf8");
  } catch {
    throw new Error(
      `Missing ${path}. Run \`npm run res:build\` before generating TypeScript declarations.`,
    );
  }
};

const write = (path, content) => {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
};

const normalizeImports = (source, moduleName) => {
  let domAliases = "";
  let normalized = source
    .replace(/import \* as .*? from '\.\/.*?\.res\.mjs';\n\n/g, "")
    .replace(/import type \{t as Signal_t\} from '\.\/Signal\.gen\.js';/g, "import type { t as Signal_t } from './Signal.js';")
    .replace(/import type \{t as TypeScriptSignal_t\} from '\.\/TypeScriptSignal\.gen\.js';/g, "import type { t as Signal_t } from './Signal.js';")
    .replace(/import type \{attrValue as View_attrValue\} from '\.\/View\.gen\.js';/g, "import type { attrValue as View_attrValue } from './View.js';")
    .replace(/import type \{node as View_node\} from '\.\/View\.gen\.js';/g, "import type { node as View_node } from './View.js';")
    .replace(/import type \{attrValue as TypeScriptView_attrValue\} from '\.\/TypeScriptView\.gen\.js';/g, "import type { attrValue as View_attrValue } from './View.js';")
    .replace(/import type \{node as TypeScriptView_node\} from '\.\/TypeScriptView\.gen\.js';/g, "import type { node as View_node } from './View.js';")
    .replace(/import type \{params as TypeScriptRoute_params\} from '\.\/TypeScriptRoute\.gen\.js';/g, "import type { params as Route_params } from './Route.js';")
    .replace(/import type \{element as Dom_element\} from '\.\/Dom\.gen\.js';\n\n/g, () => {
      domAliases += "type Dom_element = Element;\n";
      return "";
    })
    .replace(/import type \{event as Dom_event\} from '\.\/Dom\.gen\.js';\n\n/g, () => {
      domAliases += "type Dom_event = Event;\n";
      return "";
    })
    .replace(/import type \{t as Obj_t\} from '\.\/Obj\.gen\.js';\n\n/g, () => {
      return "";
    });

  if (domAliases !== "") {
    normalized = normalized.replace(
      "/* tslint:disable */\n\n",
      `/* tslint:disable */\n\n${domAliases}\n`,
    );
  }

  return normalized
    .replaceAll("TypeScriptSignal_t", "Signal_t")
    .replaceAll("TypeScriptView_attrValue", "View_attrValue")
    .replaceAll("TypeScriptView_node", "View_node")
    .replaceAll("TypeScriptRoute_params", "Route_params")
    .replaceAll("Obj_t", "unknown");
};

const normalizeDeclarations = (source, moduleName) => {
  let normalized = normalizeImports(source, moduleName)
    .replace(/\/\* TypeScript file generated from (.*?) by genType\. \*\//, "/* TypeScript declarations generated from $1 via genType. */")
    .replace(/export abstract class t<([^>]+)> \{ protected opaque!: ([^}]+) \};/g, "export abstract class t<$1> { protected opaque: $2; }")
    .replace(/export abstract class ([A-Za-z0-9_$]+) \{ protected opaque!: any \};/g, "export abstract class $1 { protected opaque: any; }")
    .replace(/^(export const [A-Za-z0-9_$]+: .*) = [^;]+ as any;$/gm, "$1;");

  if (moduleName === "Signal") {
    normalized = normalized
      .replace(
        /export const make: <a>\(initialValue:a, name:\(undefined \| string\), equals:\(undefined \| \(\(\(_1:a, _2:a\) => boolean\)\)\)\) => t<a>;/,
        "export const make: <a>(initialValue: a, name?: string, equals?: (_1: a, _2: a) => boolean) => t<a>;",
      )
      .replace(
        /export const makeForComputed: <a>\(initialValue:a, name:\(undefined \| string\)\) => t<a>;/,
        "export const makeForComputed: <a>(initialValue: a, name?: string) => t<a>;",
      );
  }

  if (moduleName === "Computed") {
    normalized = normalized
      .replace(
        /export const makeWithoutEquals: <a>\(compute:\(\(\) => a\), name:\(undefined \| string\)\) => Signal_t<a>;/,
        "export const makeWithoutEquals: <a>(compute: () => a, name?: string) => Signal_t<a>;",
      )
      .replace(
        /export const makeWithEquals: <a>\(compute:\(\(\) => a\), equalsFn:\(\(_1:a, _2:a\) => boolean\), name:\(undefined \| string\)\) => Signal_t<a>;/,
        "export const makeWithEquals: <a>(compute: () => a, equalsFn: (_1: a, _2: a) => boolean, name?: string) => Signal_t<a>;",
      )
      .replace(
        /export const make: <a>\(compute:\(\(\) => a\), name:\(undefined \| string\), equals:\(undefined \| \(\(\(_1:a, _2:a\) => boolean\)\)\)\) => Signal_t<a>;/,
        "export const make: <a>(compute: () => a, name?: string, equals?: (_1: a, _2: a) => boolean) => Signal_t<a>;",
      );
  }

  if (moduleName === "Effect") {
    normalized = normalized
      .replace(
        /export const runWithDisposer: \(fn:\(\(\) => \(undefined \| \(\(\(\) => void\)\)\)\), name:\(undefined \| string\)\) => disposer;/,
        "export const runWithDisposer: (fn: () => undefined | (() => void), name?: string) => disposer;",
      )
      .replace(
        /export const run: \(fn:\(\(\) => \(undefined \| \(\(\(\) => void\)\)\)\), name:\(undefined \| string\)\) => void;/,
        "export const run: (fn: () => undefined | (() => void), name?: string) => void;",
      );
  }

  if (moduleName === "View") {
    normalized = normalized
      .replace(
        /export const element: \(tag:string, attrs:\(undefined \| Array<\[string, attrValue\]>\), events:\(undefined \| Array<\[string, \(\(_1:Dom_event\) => void\)\]>\), children:\(undefined \| node\[\]\), _5:void\) => node;/,
        "export const element: (tag: string, attrs?: Array<[string, attrValue]>, events?: Array<[string, (_1: Dom_event) => void]>, children?: node[]) => node;",
      )
      .replace(
        /export const element: \(tag:string, attrs:\(undefined \| Array<\[string, attrValue\]>\), events:\(undefined \| Array<\[string, eventHandler\]>\), children:\(undefined \| node\[\]\), _5:void\) => node;/,
        "export const element: (tag: string, attrs?: Array<[string, attrValue]>, events?: Array<[string, eventHandler]>, children?: node[]) => node;",
      )
      .replace(/export const null: \(\) => node;/, () => "export const $$null: () => node;");
  }

  if (moduleName === "Router") {
    normalized = normalized
      .replace(
        /export const init: \(basePath:\(undefined \| string\)\) => void;/,
        "export const init: (basePath?: string) => void;",
      )
      .replace(
        /export const initSSR: \(basePath:\(undefined \| string\), pathname:\(undefined \| string\), search:\(undefined \| string\), hash:\(undefined \| string\)\) => void;/,
        "export const initSSR: (basePath?: string, pathname?: string, search?: string, hash?: string) => void;",
      )
      .replace(
        /export const push: \(pathname:string, search:\(undefined \| string\), hash:\(undefined \| string\)\) => void;/,
        "export const push: (pathname: string, search?: string, hash?: string) => void;",
      )
      .replace(
        /export const replace: \(pathname:string, search:\(undefined \| string\), hash:\(undefined \| string\)\) => void;/,
        "export const replace: (pathname: string, search?: string, hash?: string) => void;",
      )
      .replace(
        /export const link: \(to:string, attrs:\(undefined \| Array<\[string, View_attrValue\]>\), children:\(undefined \| View_node\[\]\)\) => View_node;/,
        "export const link: (to: string, attrs?: Array<[string, View_attrValue]>, children?: View_node[]) => View_node;",
      );
  }

  if (moduleName === "SSR") {
    normalized = normalized
      .replace(
        /export const renderToString: \(component:\(\(\) => View_node\), options:\(undefined \| renderOptions\)\) => string;/,
        "export const renderToString: (component: () => View_node, options?: renderOptions) => string;",
      )
      .replace(
        /export const renderToStringWithRoot: \(component:\(\(\) => View_node\), rootId:\(undefined \| string\), options:\(undefined \| renderOptions\)\) => string;/,
        "export const renderToStringWithRoot: (component: () => View_node, rootId?: string, options?: renderOptions) => string;",
      )
      .replace(
        /export const generateHydrationScript: \(nonce:\(undefined \| string\)\) => string;/,
        "export const generateHydrationScript: (nonce?: string) => string;",
      )
      .replace(
        /export const renderDocument: \(component:\(\(\) => View_node\), head:\(undefined \| string\), bodyAttrs:\(undefined \| string\), scripts:\(undefined \| string\[\]\), styles:\(undefined \| string\[\]\), stateScript:\(undefined \| string\), nonce:\(undefined \| string\)\) => string;/,
        "export const renderDocument: (head: string | undefined, bodyAttrs: string | undefined, scripts: string[] | undefined, styles: string[] | undefined, stateScript: string | undefined, nonce: string | undefined, component: () => View_node) => string;",
      );
  }

  if (moduleName === "Hydration") {
    normalized = normalized
      .replace(
        /export const hydrate: \(component:\(\(\) => View_node\), container:Dom_element, options:\(undefined \| hydrateOptions\)\) => void;/,
        "export const hydrate: (component: () => View_node, container: Dom_element, options?: hydrateOptions) => void;",
      )
      .replace(
        /export const hydrateById: \(component:\(\(\) => View_node\), containerId:string, options:\(undefined \| hydrateOptions\)\) => void;/,
        "export const hydrateById: (component: () => View_node, containerId: string, options?: hydrateOptions) => void;",
      );
  }

  if (moduleName === "Mdx") {
    normalized = normalized
      .replace(
        /export const render: \(document:document, components:\(undefined \| components\)\) => View_node;/,
        "export const render: (document: document, components?: components) => View_node;",
      );
  }

  if (moduleName === "Html") {
    normalized = normalized
      .replaceAll(
        "(attrs:(undefined | attrs), events:(undefined | events), children:(undefined | children), _4:void) => View_node",
        "(attrs?: attrs, events?: events, children?: children) => View_node",
      )
      .replaceAll(
        "(attrs:(undefined | attrs), events:(undefined | events), _3:void) => View_node",
        "(attrs?: attrs, events?: events) => View_node",
      )
      .replaceAll(
        "(attrs:(undefined | Array<[string, View_attrValue]>), events:(undefined | Array<[string, ((_1:Dom_event) => void)]>), children:(undefined | View_node[]), param:void) => View_node",
        "(attrs?: Array<[string, View_attrValue]>, events?: Array<[string, (_1: Dom_event) => void]>, children?: View_node[]) => View_node",
      )
      .replaceAll(
        "(attrs:(undefined | Array<[string, View_attrValue]>), events:(undefined | Array<[string, ((_1:Dom_event) => void)]>), param:void) => View_node",
        "(attrs?: Array<[string, View_attrValue]>, events?: Array<[string, (_1: Dom_event) => void]>) => View_node",
      );
  }

  return normalized;
};

rmSync(join(root, "dist", "types"), { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

for (const { source, output } of modules) {
  write(join(outDir, `${output}.d.ts`), normalizeDeclarations(readGenType(source), output));
}

const ssrStateTypes = `import type { t as Signal_t } from "./Signal.js";

export type Json = unknown;
export type Codec_t<a> = {
  readonly encode: (value: a) => Json;
  readonly decode: (json: Json) => undefined | a;
};

export const Codec: {
  readonly int: Codec_t<number>;
  readonly float: Codec_t<number>;
  readonly string: Codec_t<string>;
  readonly bool: Codec_t<boolean>;
  readonly array: <a>(itemCodec: Codec_t<a>) => Codec_t<a[]>;
  readonly option: <a>(itemCodec: Codec_t<a>) => Codec_t<a | undefined>;
  readonly tuple2: <a, b>(codec1: Codec_t<a>, codec2: Codec_t<b>) => Codec_t<[a, b]>;
  readonly tuple3: <a, b, c>(codec1: Codec_t<a>, codec2: Codec_t<b>, codec3: Codec_t<c>) => Codec_t<[a, b, c]>;
  readonly dict: <a>(valueCodec: Codec_t<a>) => Codec_t<Record<string, a>>;
  readonly make: <a>(encode: (value: a) => Json, decode: (json: Json) => undefined | a) => Codec_t<a>;
};

export const register: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const clear: () => void;
export const generateScript: (nonce?: string) => string;
export const getClientState: () => Record<string, Json>;
export const restore: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const sync: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const make: <a>(id: string, initial: a, codec: Codec_t<a>) => Signal_t<a>;
export const signal: typeof make;
export const syncSignal: typeof sync;
`;

write(join(outDir, "SSRState.d.ts"), ssrStateTypes);

const clientEntry = `export * as View from "./types/src/View.js";
export * as Html from "./types/src/Html.js";
export * as Prop from "./types/src/Prop.js";
export * as Signal from "./types/src/Signal.js";
export * as Computed from "./types/src/Computed.js";
export * as Effect from "./types/src/Effect.js";
export const XoteJSX: unknown;
`;

write(join(root, "dist", "client.d.ts"), clientEntry);
write(join(root, "dist", "xote.d.ts"), clientEntry);

write(
  join(root, "dist", "router.d.ts"),
  `export * from "./types/src/Router.js";
export * as Router from "./types/src/Router.js";
export * as Route from "./types/src/Route.js";
`,
);

write(
  join(root, "dist", "ssr.d.ts"),
  `export * from "./types/src/SSR.js";
export * as SSR from "./types/src/SSR.js";
export * as SSRContext from "./types/src/SSRContext.js";
export * as SSRState from "./types/src/SSRState.js";
`,
);

write(
  join(root, "dist", "hydration.d.ts"),
  `export * from "./types/src/Hydration.js";
export * as Hydration from "./types/src/Hydration.js";
`,
);

write(
  join(root, "dist", "mdx.d.ts"),
  `export * from "./types/src/Mdx.js";
export * as Mdx from "./types/src/Mdx.js";
`,
);

write(join(root, "dist", "jsx.d.ts"), "export const XoteJSX: unknown;\n");
write(
  join(root, "dist", "jsx-runtime.d.ts"),
  `import type { node as View_node } from "./types/src/View.js";

export const Fragment: symbol;
export const jsx: (type: unknown, props: Record<string, unknown> | null, key?: unknown) => View_node;
export const jsxs: typeof jsx;
`,
);
write(
  join(root, "dist", "jsx-dev-runtime.d.ts"),
  `import { jsx } from "./jsx-runtime.js";

export { Fragment, jsx, jsxs } from "./jsx-runtime.js";
export const jsxDEV: typeof jsx;
`,
);

const subpaths = {
  view: "View",
  node: "View",
  html: "Html",
  prop: "Prop",
  "reactive-prop": "Prop",
  signal: "Signal",
  computed: "Computed",
  effect: "Effect",
  route: "Route",
  "ssr-context": "SSRContext",
  "ssr-state": "SSRState",
};

for (const [subpath, moduleName] of Object.entries(subpaths)) {
  write(join(root, "dist", `${subpath}.d.ts`), `export * from "./types/src/${moduleName}.js";\n`);
}

console.log(`Generated TypeScript declarations for ${modules.map(({ output }) => output).join(", ")}.`);
