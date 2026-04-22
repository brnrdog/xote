# Inline demos

Runnable examples live inside concept and tutorial pages as in-prose figures —
never as standalone routes. Use the `InlineDemo` component to wrap a demo
module with a figure caption.

~~~rescript
<InlineDemo caption="fig. 1 — a counter, synchronously reactive">
  <CounterDemo />
</InlineDemo>
~~~

Guidelines:

- Keep the stage inside the 680px reading column (no breakout).
- Caption in `DM Mono` italic: `fig. N — short description`.
- Place the code block *after* the demo: "see, then read."
- Demo modules live under `docs-website/src/demos/`. Import the module at
  the top of the doc file before use.

If a doc file is regenerated from markdown by a script, add the inline demo
invocation to the generator rather than hand-editing the output.
