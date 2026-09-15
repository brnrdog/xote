import assert from "node:assert/strict";
import "./setup.mjs";
import * as SSR from "../src/SSR.res.mjs";
import * as Signal from "../src/Signal.res.mjs";
import * as View from "../src/View.res.mjs";

/**
 * `Opaque` attribute values: a payload the renderer assigns and never inspects.
 *
 * It exists for hosts whose props are not strings — a native view's style
 * object, a number, a record handed to a custom element — and for them the
 * HTML-attribute rules (boolean presence, `"true"`/`"false"`, stringification)
 * are all wrong. These pin what it does instead.
 */

const container = document.createElement("div");
document.body.appendChild(container);

/* ---- reactive opaque values ---------------------------------------------- */

const reactiveStyle = Signal.make({ flex: 1 });
container.replaceChildren();
View.mount(
  View.element(
    "section",
    [["data-config", { TAG: "OpaqueSignal", _0: reactiveStyle }]],
    undefined,
    undefined,
    undefined,
  ),
  container,
);

const section = container.querySelector("section");
assert.ok(section, "the element rendered");
// jsdom stringifies on `setAttribute`, so the round trip is what is checked:
// an object arrives as an object and only the DOM turns it into a string.
assert.equal(section.getAttribute("data-config"), "[object Object]");

Signal.set(reactiveStyle, { flex: 2 });
assert.equal(
  section.getAttribute("data-config"),
  "[object Object]",
  "a new object still propagates",
);

/* ---- clearing ------------------------------------------------------------ */

const clearable = Signal.make({ a: 1 });
container.replaceChildren();
View.mount(
  View.element(
    "aside",
    [["data-thing", { TAG: "OpaqueSignal", _0: clearable }]],
    undefined,
    undefined,
    undefined,
  ),
  container,
);
const aside = container.querySelector("aside");
assert.ok(aside.hasAttribute("data-thing"));
Signal.set(clearable, null);
assert.equal(aside.hasAttribute("data-thing"), false, "null removes it");

/* ---- server rendering ---------------------------------------------------- */

// A scalar has an obvious HTML spelling and gets one.
assert.equal(
  SSR.renderToString(() =>
    View.element("div", [["data-count", { TAG: "Opaque", _0: 42 }]], undefined, undefined, undefined),
  ),
  '<div data-count="42"></div>',
);

// An object does not, and guessing at `[object Object]` in the markup is worse
// than leaving it out — the client sets it on hydration either way.
assert.equal(
  SSR.renderToString(() =>
    View.element(
      "div",
      [["data-style", { TAG: "Opaque", _0: { flex: 1 } }]],
      undefined,
      undefined,
      undefined,
    ),
  ),
  "<div></div>",
);

assert.equal(
  SSR.renderToString(() =>
    View.element(
      "div",
      [["data-style", { TAG: "OpaqueCompute", _0: () => ({ flex: 1 }) }]],
      undefined,
      undefined,
      undefined,
    ),
  ),
  "<div></div>",
  "a computed opaque value is not read into the markup either",
);

/* ---- through the JSX `attrs` escape hatch --------------------------------- */

/**
 * `attrs` is the documented way to reach a prop the typed props do not name, so
 * an opaque value has to survive it — and it does not survive by accident. The
 * escape hatch re-coerces anything it does not recognise as a `View.attrValue`,
 * against a hand-maintained list of tags, and a list that has not kept up with
 * the type silently sends the value back through the HTML-attribute rules the
 * constructor exists to escape.
 *
 * This is asserted on the value the escape hatch returns rather than on the
 * rendered attribute, because a real DOM stringifies on `setAttribute` and both
 * paths land on `"[object Object]"` — the coercion is invisible downstream and
 * only the identity of the payload gives it away.
 */
const RuntimeJsxProp = await import("../src/RuntimeJsxProp.res.mjs");

const payload = { flex: 1, gap: 8 };
for (const tag of ["Opaque", "OpaqueSignal", "OpaqueCompute"]) {
  const value = { TAG: tag, _0: payload };
  const [key, out] = RuntimeJsxProp.toAttrEntry("data-config", value);
  assert.equal(key, "data-config");
  assert.equal(out, value, `${tag} passes through \`attrs\` untouched`);
}

// The tags the escape hatch recognises have to be exactly the constructors the
// type has, minus `Static` — which deliberately shares MaybeSignal's path. A
// constructor added to `View.attrValue` and not here is this bug again.
assert.deepEqual(
  [...RuntimeJsxProp.attrValueTags].sort(),
  [
    "Compute",
    "Opaque",
    "OpaqueCompute",
    "OpaqueSignal",
    "OptionalCompute",
    "OptionalSignalValue",
    "OptionalStatic",
    "SignalValue",
  ],
  "every attrValue constructor except Static is recognised by the escape hatch",
);

console.log("opaque attribute tests passed");
