// A session in a child process, driven over IPC by the MCP server (which
// forks one per render, so every render loads fresh modules).

import { createSession } from "./session.mjs";

let session = null;
const methods = {
  async init({ root, captureStacks = true }) {
    session = await createSession({ root, captureStacks });
    return { status: session.status };
  },
  inspect: ({ id }) => session.inspect(id),
  html: ({ selector }) => session.html(selector),
};
for (const name of ["render", "act", "why", "graph", "diagnostics"]) methods[name] = (params) => session[name](params);

process.on("message", async ({ id, method, params }) => {
  try {
    if (!Object.hasOwn(methods, method)) throw new Error(`unknown method ${method}`);
    if (method !== "init" && !session) throw new Error("session not initialised");
    process.send({ id, result: await methods[method](params ?? {}) });
  } catch (error) {
    process.send({ id, error: error?.message ?? String(error) });
  }
});
