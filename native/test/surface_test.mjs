/**
 * The types may not promise more than the hosts deliver.
 *
 * This is a static check, and it exists because of a specific failure that is
 * invisible to every other test in this directory. `NativeStyle` declared
 * `flexWrap`; the layout engine puts every container on one line. It declared
 * `letterSpacing`, `textTransform` and `fontStyle`; nothing read any of them.
 * `NativeJSX` declared `onPressIn`, `onSubmit` and `keyboardType`; the iOS host
 * had never heard of them. In each case the app author writes the prop, the
 * compiler agrees, and the screen is unchanged with nothing to read that says
 * why — which is worse than the prop not existing, because a missing prop is a
 * compile error and a five-minute answer.
 *
 * Nothing that renders can catch this: a style key nobody reads produces a
 * correct screen for the app it was not written for. So this reads the ReScript
 * source, the layout engine and the Swift host as text, and asserts they agree
 * about what exists.
 *
 * It also covers the Swift, which is the only kind of check this repository can
 * run against it — there is no Swift toolchain here (see `ios/README.md`). A
 * name in `capabilities.mjs` that is not a `case` in `XoteHost.swift` fails
 * here rather than on a device.
 */

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import {
  EVENTS,
  LAYOUT_EDGE_PREFIXES,
  LAYOUT_STYLE,
  PAINT_STYLE,
  PROPS,
  STYLE,
} from "../host/capabilities.mjs";

const read = (path) => readFileSync(fileURLToPath(new URL(`../${path}`, import.meta.url)), "utf8");

const NativeStyle = read("NativeStyle.res");
const NativeJSX = read("NativeJSX.res");
const layoutEngine = read("host/layout.mjs");
const swiftLayout = read("ios/XoteNative/Sources/XoteLayout.swift");
const swiftHost = read("ios/XoteNative/Sources/XoteHost.swift");
const swiftStyle = read("ios/XoteNative/Sources/XoteStyle.swift");

/**
 * The fields of a ReScript record, given the source and how the type is
 * declared. Brace-matched rather than indentation-matched, because
 * `NativeJSX`'s props record lives inside a module and its type parameters
 * span twenty lines before the body even opens.
 */
const recordFields = (source, declaration) => {
  const start = source.indexOf(declaration);
  assert.ok(start >= 0, `${declaration} is not in the source any more`);
  const open = source.indexOf("{", start);
  assert.ok(open >= 0, `${declaration} has no record body`);
  let depth = 0;
  let close = open;
  for (; close < source.length; close += 1) {
    if (source[close] === "{") depth += 1;
    else if (source[close] === "}" && (depth -= 1) === 0) break;
  }
  const body = source.slice(open + 1, close);
  return [...body.matchAll(/^\s+([a-zA-Z][a-zA-Z0-9]*)\??:/gm)].map((match) => match[1]);
};

/* ---- style ---------------------------------------------------------------- */

const declaredStyle = recordFields(NativeStyle, "type t = {");
assert.ok(declaredStyle.length > 20, "NativeStyle.t did not parse");

const undeliverable = declaredStyle.filter((key) => !STYLE.includes(key));
assert.deepEqual(
  undeliverable,
  [],
  `NativeStyle declares ${undeliverable.join(", ")}, which no host implements. ` +
    "Either implement it and add it to host/capabilities.mjs, or take it out of the type.",
);

const undeclared = STYLE.filter((key) => !declaredStyle.includes(key));
assert.deepEqual(
  undeclared,
  [],
  `host/capabilities.mjs claims ${undeclared.join(", ")}, which NativeStyle does not declare`,
);

// Every alignment the type offers has to be one the engine handles. `baseline`
// was the one that did not: it fell through to the default and silently
// stretched, which looks like a layout bug rather than a missing feature.
const alignments = new Set(
  [...NativeStyle.matchAll(/align(?:Items|Self)\??: \[([^\]]+)\]/g)]
    .flatMap((match) => [...match[1].matchAll(/#(?:"([^"]+)"|([a-zA-Z-]+))/g)])
    .map((match) => match[1] ?? match[2]),
);
for (const alignment of alignments) {
  if (alignment === "auto") continue; // `alignSelf: auto` means "ask the parent"
  assert.ok(
    layoutEngine.includes(`"${alignment}"`),
    `NativeStyle offers alignment ${alignment}, which layout.mjs does not handle`,
  );
  assert.ok(
    swiftLayout.includes(`"${alignment}"`),
    `NativeStyle offers alignment ${alignment}, which XoteLayout.swift does not handle`,
  );
}

/* ---- the two layout engines agree about what they read --------------------- */

// The Swift splits what JavaScript keeps in one file: `XoteStyle` is the reader
// and `XoteLayout` is the algorithm, so a key can legitimately be named in
// either. Searching both is the honest translation of "the engine reads it".
const swiftEngine = swiftLayout + swiftStyle;

for (const key of LAYOUT_STYLE) {
  assert.ok(layoutEngine.includes(`.${key}`), `layout.mjs does not read ${key}`);
  assert.ok(swiftEngine.includes(`"${key}"`), `no Swift engine source reads ${key}`);
}
for (const prefix of LAYOUT_EDGE_PREFIXES) {
  assert.ok(layoutEngine.includes(`"${prefix}"`), `layout.mjs does not read ${prefix}`);
  assert.ok(swiftEngine.includes(`"${prefix}"`), `no Swift engine source reads ${prefix}`);
}
for (const key of PAINT_STYLE) {
  assert.ok(
    swiftHost.includes(`"${key}"`) || swiftStyle.includes(`"${key}"`),
    `no Swift source paints ${key}`,
  );
}

/* ---- props and events ------------------------------------------------------ */

const declaredProps = recordFields(NativeJSX, "type props<");
assert.ok(declaredProps.length > 5, "NativeJSX props did not parse");

// `style`, the escape hatch and the children are not props a host looks up by
// name, and the handlers are events rather than props.
const structural = new Set(["style", "attrs", "children"]);
const propNames = declaredProps.filter((key) => !structural.has(key) && !key.startsWith("on"));
const eventNames = declaredProps
  .filter((key) => key.startsWith("on") && key.length > 2)
  .map((key) => key[2].toLowerCase() + key.slice(3));

const unheld = propNames.filter((key) => !PROPS.includes(key));
assert.deepEqual(
  unheld,
  [],
  `NativeJSX declares ${unheld.join(", ")}, which no host applies. ` +
    "Either implement it and add it to host/capabilities.mjs, or take it out of the type.",
);

const unraised = eventNames.filter((name) => !EVENTS.includes(name));
assert.deepEqual(
  unraised,
  [],
  `NativeJSX declares handlers for ${unraised.join(", ")}, which no host raises`,
);

for (const key of PROPS) {
  assert.ok(swiftHost.includes(`case "${key}"`), `XoteHost.swift has no case for prop ${key}`);
  assert.ok(
    declaredProps.includes(key),
    `host/capabilities.mjs claims prop ${key}, which NativeJSX does not declare`,
  );
}
for (const name of EVENTS) {
  assert.ok(swiftHost.includes(`case "${name}"`), `XoteHost.swift has no case for event ${name}`);
  const handler = `on${name[0].toUpperCase()}${name.slice(1)}`;
  assert.ok(
    declaredProps.includes(handler),
    `host/capabilities.mjs claims event ${name}, which NativeJSX does not expose as ${handler}`,
  );
}

console.log(
  `surface tests passed — ${declaredStyle.length} style keys, ${propNames.length} props and ` +
    `${eventNames.length} events, every one of them implemented`,
);
