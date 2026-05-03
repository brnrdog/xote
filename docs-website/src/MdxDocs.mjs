import { jsx } from "xote/jsx-runtime";
import * as Router from "xote/router";
import * as View from "xote/view";
import * as SyntaxHighlight from "./SyntaxHighlight.res.mjs";
import { make as DocsExamplePanel } from "./DocsExamplePanel.res.mjs";
import { make as CounterDemo } from "./demos/CounterDemo.res.mjs";
import { make as ComputedOrderDemo } from "./demos/ComputedOrderDemo.res.mjs";
import { make as EffectAutosaveDemo } from "./demos/EffectAutosaveDemo.res.mjs";
import { make as TodoListDemo } from "./demos/TodoListDemo.res.mjs";
import IntroDoc from "./docs/IntroDoc.mdx";
import LearningReScriptDoc from "./docs/LearningReScriptDoc.mdx";
import SignalsDoc from "./docs/SignalsDoc.mdx";
import ComputedDoc from "./docs/ComputedDoc.mdx";
import EffectsDoc from "./docs/EffectsDoc.mdx";
import BatchingDoc from "./docs/BatchingDoc.mdx";
import ViewsDoc from "./docs/ViewsDoc.mdx";
import RouterDoc from "./docs/RouterDoc.mdx";
import ApiSignalsDoc from "./docs/ApiSignalsDoc.mdx";
import ReactComparisonDoc from "./docs/ReactComparisonDoc.mdx";
import SolidJSComparisonDoc from "./docs/SolidJSComparisonDoc.mdx";
import TechnicalOverviewDoc from "./docs/TechnicalOverviewDoc.mdx";
import SSRDoc from "./docs/SSRDoc.mdx";
import ChangelogDoc from "./docs/ChangelogDoc.mdx";

const nodeTags = new Set([
  "Element",
  "Text",
  "SignalText",
  "Fragment",
  "SignalFragment",
  "Keyed",
  "LazyComponent",
  "KeyedList",
]);

function isXoteNode(value) {
  return value && typeof value === "object" && nodeTags.has(value.TAG);
}

function normalizeChildren(children) {
  if (children === null || children === undefined || typeof children === "boolean") {
    return [];
  }

  if (Array.isArray(children)) {
    return children.flatMap(normalizeChildren);
  }

  if (isXoteNode(children)) {
    return [children];
  }

  return [View.text(String(children))];
}

function childrenToText(children) {
  if (children === null || children === undefined || typeof children === "boolean") {
    return "";
  }

  if (typeof children === "string" || typeof children === "number") {
    return String(children);
  }

  if (Array.isArray(children)) {
    return children.map(childrenToText).join("");
  }

  if (isXoteNode(children)) {
    switch (children.TAG) {
      case "Text":
        return children._0;
      case "Fragment":
        return children._0.map(childrenToText).join("");
      default:
        return "";
    }
  }

  return "";
}

function Link(props) {
  const href = props.href ?? "";

  if (href.startsWith("/")) {
    const attrs = [];
    if (props.className) {
      attrs.push(View.attr("class", props.className));
    }
    if (props.title) {
      attrs.push(View.attr("title", props.title));
    }
    return Router.link(href, attrs, normalizeChildren(props.children), undefined);
  }

  return jsx("a", {
    ...props,
    target: props.target ?? "_blank",
    rel: props.rel ?? "noreferrer",
  });
}

function Pre(props) {
  return jsx("pre", {
    ...props,
    className: ["docs-code-pre", props.className].filter(Boolean).join(" "),
  });
}

function Code(props) {
  const isBlock = props.className?.startsWith("language-");
  if (!isBlock) {
    return jsx("code", props);
  }

  const code = childrenToText(props.children).replace(/\n$/, "");
  return jsx("code", {
    children: SyntaxHighlight.highlight(code),
  });
}

const components = {
  a: Link,
  code: Code,
  pre: Pre,
  DocsExamplePanel,
  CounterDemo,
  ComputedOrderDemo,
  EffectAutosaveDemo,
  TodoListDemo,
};

function render(Component) {
  return jsx(Component, { components });
}

export const intro = () => render(IntroDoc);
export const learningReScript = () => render(LearningReScriptDoc);
export const signals = () => render(SignalsDoc);
export const computed = () => render(ComputedDoc);
export const effects = () => render(EffectsDoc);
export const batching = () => render(BatchingDoc);
export const views = () => render(ViewsDoc);
export const router = () => render(RouterDoc);
export const apiSignals = () => render(ApiSignalsDoc);
export const reactComparison = () => render(ReactComparisonDoc);
export const solidComparison = () => render(SolidJSComparisonDoc);
export const technicalOverview = () => render(TechnicalOverviewDoc);
export const ssr = () => render(SSRDoc);
export const changelog = () => render(ChangelogDoc);
