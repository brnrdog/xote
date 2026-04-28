# Inline demos

Runnable examples live inside concept and tutorial pages as in-prose figures or
combined code-and-demo panels, never as standalone routes. Inside a
documentation page, prefer `DocsExamplePanel` so readers can switch between the
source and the live result without leaving the flow.

~~~rescript
<DocsExamplePanel
  filename="Counter.res"
  code={`open Xote

let count = Signal.make(0)
...`}
>
  <CounterDemo />
</DocsExamplePanel>
~~~

Guidelines:

- Keep the stage inside the 680px reading column (no breakout).
- Default to the `Code` tab so the reader sees the implementation first.
- Keep the tab labels short and literal: `Code`, `Demo`.
- Demo modules live under `docs-website/src/demos/`. Import the module at
  the top of the doc file before use.
- Reserve `InlineDemo` for standalone demo figures that do not need an adjacent
  source listing.

If a doc file is regenerated from markdown by a script, add the inline demo
invocation to the generator rather than hand-editing the output.
