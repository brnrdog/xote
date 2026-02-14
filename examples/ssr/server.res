/*
 * Server-side rendering entry point
 * Run with: node examples/ssr/server.res.mjs
 */
open Xote

/* Create state and app component */
let (count, items, inputValue) = App.makeAppState()
let appComponent = App.app(count, items, inputValue)

/* CSS styles for the demo */
let styles = `
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, sans-serif; padding: 2rem; background: #f5f5f5; }
  .app { max-width: 600px; margin: 0 auto; background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  h1 { margin-bottom: 1.5rem; color: #333; }
  h2 { margin: 1.5rem 0 1rem; color: #555; font-size: 1.2rem; }
  .counter-section, .list-section, .status-section { margin-bottom: 1.5rem; padding-bottom: 1.5rem; border-bottom: 1px solid #eee; }
  .button-group { display: flex; gap: 0.5rem; }
  .btn { padding: 0.5rem 1rem; border: none; background: #007bff; color: white; border-radius: 4px; cursor: pointer; font-size: 1rem; }
  .btn:hover { background: #0056b3; }
  .input-group { display: flex; gap: 0.5rem; margin-bottom: 1rem; }
  input[type="text"] { flex: 1; padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; font-size: 1rem; }
  .item-list { list-style: none; }
  .item-list li { padding: 0.5rem; background: #f9f9f9; margin-bottom: 0.25rem; border-radius: 4px; }
  .status { padding: 1rem; border-radius: 4px; text-align: center; font-weight: bold; }
  .status.normal { background: #e3f2fd; color: #1976d2; }
  .status.high { background: #ffebee; color: #c62828; }
  .status.low { background: #fff3e0; color: #ef6c00; }
`

/* Render the full HTML document */
let html = SSR.renderDocument(
  ~head=`
    <title>Xote SSR Demo</title>
    <style>${styles}</style>
  `,
  ~scripts=["./client.res.mjs"],
  appComponent,
)

/* Output the HTML */
Console.log(html)
