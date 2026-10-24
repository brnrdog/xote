/* An in-page devtools panel for Xote apps, reachable through the
   `xote/devtools` entry and built with Xote itself.

   It shows the reactive graph (each node's value, sources, observers, scope,
   creation site, and why it last ran), a timeline of writes, runs, DOM writes
   and keyed passes, the scope tree, and issues: leaks, hidden reads, failures
   an error boundary caught and hydration warnings. The ⌖ button picks an
   element on the page and explains its last update.

   Install `Devtools` from the entry module, before anything reactive is
   created; `mount` installs it if that has not happened, but nodes created
   before then are not shown. Everything the panel creates is hidden from
   devtools, so it never appears in what it displays. Ctrl+Shift+X toggles it.

   ## Examples

   ```rescript
   let _ = Devtools.install()
   /* ... create signals, mount the app ... */
   let unmount = DevtoolsPanel.mount()
   ```
*/

/* Mount the panel into `target` (default: `document.body`), collapsed to a
   launcher unless `expanded`. Returns the function that removes it and
   releases its reactive state. */
let mount: (~target: Dom.element=?, ~expanded: bool=?, unit) => unit => unit
