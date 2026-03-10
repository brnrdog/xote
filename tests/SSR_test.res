open Zekr
open Xote

let snapshotDir = "tests/__snapshots__"
let _ = setSnapshotDir(snapshotDir)

let suite = Zekr.suite(
  "SSR",
  [
    test("renders static text", () => {
      let html = SSR.renderToString(() => Component.text("hello"))
      assertMatchesSnapshot(html, ~name="ssr-static-text")
    }),
    test("renders element with class attribute", () => {
      let html = SSR.renderToString(() =>
        Component.div(
          ~attrs=[Component.attr("class", "box")],
          ~children=[Component.text("content")],
          (),
        )
      )
      assertMatchesSnapshot(html, ~name="ssr-element-with-class")
    }),
    test("renders nested elements", () => {
      let html = SSR.renderToString(() =>
        Component.div(~children=[
          Component.p(~children=[Component.text("nested")], ()),
        ], ())
      )
      assertMatchesSnapshot(html, ~name="ssr-nested-elements")
    }),
    test("renders void elements self-closing", () => {
      let html = SSR.renderToString(() =>
        Component.fragment([
          Component.input(~attrs=[Component.attr("type", "text")], ()),
          Component.element("br", ()),
        ])
      )
      assertMatchesSnapshot(html, ~name="ssr-void-elements")
    }),
    test("escapes HTML in text content", () => {
      let html = SSR.renderToString(() =>
        Component.text("<script>alert('xss')</script>")
      )
      combineResults([
        assertContains(html, "&lt;script&gt;"),
        assertContains(html, "&lt;/script&gt;"),
      ])
    }),
    test("wraps signal text with hydration markers", () => {
      let html = SSR.renderToString(() => {
        let sig = Signal.make("reactive")
        Component.SignalText(sig)
      })
      combineResults([
        assertContains(html, "<!--$-->"),
        assertContains(html, "reactive"),
        assertContains(html, "<!--/$-->"),
      ])
    }),
    test("wraps signal fragment with hydration markers", () => {
      let html = SSR.renderToString(() => {
        let sig = Signal.make([Component.text("child")])
        Component.signalFragment(sig)
      })
      combineResults([
        assertContains(html, "<!--#-->"),
        assertContains(html, "child"),
        assertContains(html, "<!--/#-->"),
      ])
    }),
    test("wraps keyed list items with key markers", () => {
      let html = SSR.renderToString(() => {
        let items = Signal.make(["a", "b"])
        Component.keyedList(items, item => item, item =>
          Component.span(~children=[Component.text(item)], ())
        )
      })
      combineResults([
        assertContains(html, "<!--kl-->"),
        assertContains(html, "<!--k:a-->"),
        assertContains(html, "<!--k:b-->"),
        assertContains(html, "<!--/k-->"),
        assertContains(html, "<!--/kl-->"),
      ])
    }),
    test("wraps lazy component with markers", () => {
      let html = SSR.renderToString(() =>
        LazyComponent(() => Component.text("lazy"))
      )
      combineResults([
        assertContains(html, "<!--lc-->"),
        assertContains(html, "lazy"),
        assertContains(html, "<!--/lc-->"),
      ])
    }),
    test("renderToStringWithRoot adds root markers", () => {
      let html = SSR.renderToStringWithRoot(() =>
        Component.text("root content")
      )
      combineResults([
        assertContains(html, "<!--xote-root:root-->"),
        assertContains(html, "root content"),
        assertContains(html, "<!--/xote-root-->"),
      ])
    }),
    test("renderDocument generates full HTML document", () => {
      let html = SSR.renderDocument(
        ~scripts=["/app.js"],
        ~styles=["/style.css"],
        () => Component.text("page"),
      )
      combineResults([
        assertContains(html, "<!DOCTYPE html>"),
        assertContains(html, "<html>"),
        assertContains(html, `<link rel="stylesheet" href="/style.css" />`),
        assertContains(html, `<script type="module" src="/app.js"></script>`),
        assertContains(html, `<div id="root">page</div>`),
        assertContains(html, "</html>"),
      ])
    }),
    test("renders boolean attributes without value", () => {
      let html = SSR.renderToString(() =>
        Component.input(
          ~attrs=[
            Component.attr("type", "text"),
            Component.attr("disabled", "true"),
          ],
          (),
        )
      )
      combineResults([
        assertContains(html, "disabled"),
        assertFalse(String.includes(html, `disabled="true"`)),
      ])
    }),
    test("escapes attribute values", () => {
      let html = SSR.renderToString(() =>
        Component.div(
          ~attrs=[Component.attr("title", `say "hello" & goodbye`)],
          (),
        )
      )
      combineResults([
        assertContains(html, "&quot;"),
        assertContains(html, "&amp;"),
      ])
    }),
  ],
)
