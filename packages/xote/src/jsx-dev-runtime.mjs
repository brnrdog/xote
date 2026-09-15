import { jsx } from "./jsx-runtime.mjs";

export { Fragment, jsx, jsxs } from "./jsx-runtime.mjs";

export function jsxDEV(type, props, key) {
  return jsx(type, props, key);
}
