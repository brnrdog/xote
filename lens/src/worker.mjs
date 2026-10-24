// A session in a child process, driven over IPC. The MCP server forks one per
// render, so every render starts from freshly loaded modules.

import { createSession } from "./session.mjs";

let session = null;
let root = null;

const methods = {
  async init(params) {
    root = params.root;
    session = await createSession({ root, captureStacks: params.captureStacks ?? true });
    return { status: session.status };
  },
  render: (params) => session.render(params),
  act: (params) => session.act(params),
  why: (params) => session.why(params),
  graph: (params) => session.graph(params),
  inspect: (params) => session.inspect(params.id),
  html: (params) => session.html(params.selector),
  diagnostics: () => session.diagnostics(),
};

process.on("message", async ({ id, method, params }) => {
  try {
    if (!methods[method]) throw new Error(`unknown method ${method}`);
    if (method !== "init" && !session) throw new Error("session not initialised");
    const result = await methods[method](params ?? {});
    process.send({ id, result });
  } catch (error) {
    process.send({ id, error: error?.message ?? String(error) });
  }
});
