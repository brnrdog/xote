open! Zekr

let snapshotDir = "tests/__snapshots__"
let _ = Snapshot.setDir(snapshotDir)

let suite = Suite.make(
  "SSR",
  [
    Test.make("renders static text", () => {
      let html = SSR.renderToString(() => View.text("hello"))
      Snapshot.matches(html, ~name="ssr-static-text")
    }),
    Test.make("renders element with class attribute", () => {
      let html = SSR.renderToString(() =>
        Html.div(~attrs=[View.attr("class", "box")], ~children=[View.text("content")], ())
      )
      Snapshot.matches(html, ~name="ssr-element-with-class")
    }),
    Test.make("renders nested elements", () => {
      let html = SSR.renderToString(() =>
        Html.div(~children=[Html.p(~children=[View.text("nested")], ())], ())
      )
      Snapshot.matches(html, ~name="ssr-nested-elements")
    }),
    Test.make("renders void elements self-closing", () => {
      let html = SSR.renderToString(() =>
        View.fragment([Html.input(~attrs=[View.attr("type", "text")], ()), View.element("br", ())])
      )
      Snapshot.matches(html, ~name="ssr-void-elements")
    }),
    Test.make("escapes HTML in text content", () => {
      let html = SSR.renderToString(() => View.text("<script>alert('xss')</script>"))
      Assert.combineResults([
        Assert.contains(html, "&lt;script&gt;"),
        Assert.contains(html, "&lt;/script&gt;"),
      ])
    }),
    Test.make("wraps signal text with hydration markers", () => {
      let html = SSR.renderToString(() => {
        let sig = Signal.make("reactive")
        View.SignalText(sig)
      })
      Assert.combineResults([
        Assert.contains(html, "<!--$-->"),
        Assert.contains(html, "reactive"),
        Assert.contains(html, "<!--/$-->"),
      ])
    }),
    Test.make("wraps signal fragment with hydration markers", () => {
      let html = SSR.renderToString(() => {
        let sig = Signal.make([View.text("child")])
        View.signalFragment(sig)
      })
      Assert.combineResults([
        Assert.contains(html, "<!--#-->"),
        Assert.contains(html, "child"),
        Assert.contains(html, "<!--/#-->"),
      ])
    }),
    Test.make("wraps keyed list items with key markers", () => {
      let html = SSR.renderToString(() => {
        let items = Signal.make(["a", "b"])
        View.eachWithKey(items, item => item, item => Html.span(~children=[View.text(item)], ()))
      })
      Assert.combineResults([
        Assert.contains(html, "<!--kl-->"),
        Assert.contains(html, "<!--k:a-->"),
        Assert.contains(html, "<!--k:b-->"),
        Assert.contains(html, "<!--/k-->"),
        Assert.contains(html, "<!--/kl-->"),
      ])
    }),
    Test.make("wraps lazy component with markers", () => {
      let html = SSR.renderToString(() => LazyComponent(() => View.text("lazy")))
      Assert.combineResults([
        Assert.contains(html, "<!--lc-->"),
        Assert.contains(html, "lazy"),
        Assert.contains(html, "<!--/lc-->"),
      ])
    }),
    Test.make("renderToStringWithRoot adds root markers", () => {
      let html = SSR.renderToStringWithRoot(() => View.text("root content"))
      Assert.combineResults([
        Assert.contains(html, "<!--xote-root:root-->"),
        Assert.contains(html, "root content"),
        Assert.contains(html, "<!--/xote-root-->"),
      ])
    }),
    Test.make("renderDocument generates full HTML document", () => {
      let html = SSR.renderDocument(~scripts=["/app.js"], ~styles=["/style.css"], () =>
        View.text("page")
      )
      Assert.combineResults([
        Assert.contains(html, "<!DOCTYPE html>"),
        Assert.contains(html, "<html>"),
        Assert.contains(html, `<link rel="stylesheet" href="/style.css" />`),
        Assert.contains(html, `<script type="module" src="/app.js"></script>`),
        Assert.contains(html, `<div id="root">page</div>`),
        Assert.contains(html, "</html>"),
      ])
    }),
    Test.make("renders boolean attributes without value", () => {
      let html = SSR.renderToString(() =>
        Html.input(~attrs=[View.attr("type", "text"), View.attr("disabled", "true")], ())
      )
      Assert.combineResults([
        Assert.contains(html, "disabled"),
        Assert.isFalse(String.includes(html, `disabled="true"`)),
      ])
    }),
    Test.make("escapes attribute values", () => {
      let html = SSR.renderToString(() =>
        Html.div(~attrs=[View.attr("title", `say "hello" & goodbye`)], ())
      )
      Assert.combineResults([Assert.contains(html, "&quot;"), Assert.contains(html, "&amp;")])
    }),
  ],
)
