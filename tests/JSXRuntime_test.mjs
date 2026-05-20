import assert from "node:assert/strict";
import "./setup.mjs";
import * as SSR from "../src/SSR.res.mjs";
import * as Signal from "../src/Signal.res.mjs";
import * as View from "../src/View.res.mjs";
import { Fragment, jsx, jsxs } from "../src/jsx-runtime.mjs";
import { jsxDEV } from "../src/jsx-dev-runtime.mjs";

function renderToString(node) {
  return SSR.renderToString(() => node);
}

function MDXContent(props = {}) {
  const components = {
    a: "a",
    code: "code",
    h1: "h1",
    p: "p",
    ...props.components,
  };

  return jsxs(Fragment, {
    children: [
      jsx(components.h1, { children: "Hello MDX" }),
      "\n",
      jsxs(components.p, {
        children: [
          "A ",
          jsx(components.a, { href: "/docs", children: "link" }),
          " and ",
          jsx(components.code, { children: "code" }),
        ],
      }),
    ],
  });
}

assert.equal(
  renderToString(MDXContent()),
  '<h1>Hello MDX</h1>\n<p>A <a href="/docs">link</a> and <code>code</code></p>',
);

function LeadParagraph(props) {
  return jsx("p", { ...props, className: "lead" });
}

assert.equal(
  renderToString(MDXContent({ components: { p: LeadParagraph } })),
  '<h1>Hello MDX</h1>\n<!--lc--><p class="lead">A <a href="/docs">link</a> and <code>code</code></p><!--/lc-->',
);

const status = Signal.make("ready");
assert.equal(
  renderToString(
    jsx("div", {
      className: status,
      dataState: () => Signal.get(status),
      children: "ok",
    }),
  ),
  '<div class="ready" data-state="ready">ok</div>',
);

const container = document.createElement("div");
let clicked = 0;
View.mount(
  jsxDEV("button", {
    className: "primary",
    disabled: false,
    onClick: () => {
      clicked += 1;
    },
    children: "Click",
  }),
  container,
);

const button = container.querySelector("button");
assert.equal(button.textContent, "Click");
assert.equal(button.getAttribute("class"), "primary");
assert.equal(button.hasAttribute("disabled"), false);

button.dispatchEvent(new MouseEvent("click", { bubbles: true }));
assert.equal(clicked, 1);

console.log("JSX runtime tests passed");
