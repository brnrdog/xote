// Local devtools test bed for this site.
//
// server.mjs injects this script ahead of the app only when the dev server is
// started with XOTE_DEVTOOLS=1 (`npm run dev:devtools`). index.html and the
// production build never reference it. It runs before EntryClient, so
// devtools are installed before the site creates its first signal; the panel
// mounts once hydration has run.

import * as Devtools from 'xote/src/Devtools.res.mjs'
import * as DevtoolsPanel from 'xote/src/DevtoolsPanel.res.mjs'

const status = Devtools.install(true, undefined)

if (!status.signals) {
  console.warn(
    '[xote devtools] the loaded rescript-signals has no debug hooks, so the reactive graph is not visible. ' +
      'Run `npm run devtools:link` (see DEVTOOLS.md) and restart the dev server.',
  )
}

/* For poking at from the browser console: xoteDevtools.snapshot(), .why(id), .leaks() */
window.xoteDevtools = Devtools

document.addEventListener('DOMContentLoaded', () => {
  DevtoolsPanel.mount(undefined, false, undefined)
})
