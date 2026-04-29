import { jsx } from "xote/jsx-runtime";
import * as View from "xote/view";
import Article from "./article.mdx";
import "./styles.css";

const components = {
  a: props => jsx("a", { ...props, target: "_blank", rel: "noreferrer" }),
  h1: props => jsx("h1", { ...props, className: "article-title" }),
  p: props => jsx("p", { ...props, className: "article-copy" }),
};

View.mount(jsx(Article, { components }), document.getElementById("root"));
