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
    .replace(/import type \{element as Dom_element\} from '\.\/Dom\.gen\.js';\n\n/g, () => {
      domAliases += "type Dom_element = Element;\n";
      return "";
    })
    .replace(/import type \{event as Dom_event\} from '\.\/Dom\.gen\.js';\n\n/g, () => {
      domAliases += "type Dom_event = Event;\n";
      return "";
    })
    .replace(/import type \{t as Obj_t\} from '\.\/Obj\.gen\.js';\n\n/g, () => {
      domAliases += "type Obj_t = unknown;\n";
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
    .replaceAll("TypeScriptView_node", "View_node");
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

const subpaths = {
  view: "View",
  node: "View",
  html: "Html",
  prop: "Prop",
  "reactive-prop": "Prop",
  signal: "Signal",
  computed: "Computed",
  effect: "Effect",
};

for (const [subpath, moduleName] of Object.entries(subpaths)) {
  write(join(root, "dist", `${subpath}.d.ts`), `export * from "./types/src/${moduleName}.js";\n`);
}

console.log(`Generated TypeScript declarations for ${modules.map(({ output }) => output).join(", ")}.`);
