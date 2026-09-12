/**
 * The dev server: your app runs here, the phone draws it.
 *
 *   npm run native:dev            # the tracker
 *   XOTE_APP=nav npm run native:dev
 *
 * A device connects, and from then on it is a view host and nothing else —
 * no JavaScript engine, no bundle, nothing to transfer when you save a file.
 * The app runs in a child process on this machine (see `app.mjs`), its batches
 * go down the wire, and the events come back.
 *
 * ## Why this is possible at all
 *
 * Because the bridge was already a wire format. `example/preview.mjs` runs the
 * app in a worker and the host on the page, with a command batch between them
 * and `postMessage` carrying it; this is the same arrangement with a socket
 * where `postMessage` was. Nothing in the app, the renderer, the shadow
 * document or the host changed to allow it.
 *
 * That also says what this is *not*. The app is running in Node, not in
 * JavaScriptCore on a phone, so it cannot show you a JSC-only behaviour, real
 * startup cost, or what a batch costs to apply at 60fps under a real thermal
 * budget. It is the inner loop, not the measurement.
 *
 * ## The transport, and why it is this one
 *
 * Newline-delimited JSON over one long-lived chunked HTTP response downward,
 * and an ordinary POST per event upward. No WebSocket, which would mean
 * writing frame masking and fragmentation in three languages to carry
 * newline-separated JSON that HTTP already carries. `curl -N` is a working
 * client, which is the property you want at three in the morning.
 */

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { watch } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const packageRoot = join(here, "..");

const PORT = Number(process.env.XOTE_DEV_PORT ?? 8081);
const APP = process.env.XOTE_APP ?? "tracker";

/* Directories whose compiled output is the app. ReScript writes `.res.mjs`
 next to the source, so watching for those is watching for "the app changed",
 and it ignores the `.res` save that precedes the compile. */
const WATCHED = ["src", "example"];

/** Every connected device. A batch goes to all of them. */
const clients = new Set();

let child = null;
/** The batches this generation of the app has produced, in order.
 *
 * A device that connects late must not get a half-built screen, and the app
 * has no way to re-render on request — it is not React, there is no root to
 * re-mount from the outside. So the server keeps the log and replays it, which
 * is exact rather than approximate: the commands *are* the screen. */
let log = [];
/** Bumped on every restart, so a device can tell a reload from a reconnect. */
let generation = 0;

const send = (client, message) => {
  try {
    client.write(JSON.stringify(message) + "\n");
  } catch {
    clients.delete(client);
  }
};

const broadcast = (message) => {
  for (const client of clients) send(client, message);
};

function startApp() {
  generation += 1;
  log = [];

  const mine = generation;
  child = spawn(process.execPath, [join(here, "app.mjs")], {
    cwd: packageRoot,
    stdio: ["ignore", "inherit", "inherit", "ipc"],
    env: { ...process.env, XOTE_APP: APP },
  });

  child.on("message", (message) => {
    // A message from a process we have already replaced is not this screen's.
    if (mine !== generation) return;
    if (message.type === "batch") {
      log.push(message.commands);
      broadcast(message);
    } else if (message.type === "error") {
      process.stderr.write(`\n  app error\n${message.message}\n\n`);
      broadcast(message);
    } else if (message.type === "ready") {
      console.log(`  ${message.app} is running — generation ${generation}`);
    }
  });

  child.on("exit", (code) => {
    if (mine !== generation) return;
    if (code !== 0) {
      const message = `the app process exited with code ${code}`;
      process.stderr.write(`\n  ${message}\n\n`);
      broadcast({ type: "error", message });
    }
  });
}

function restartApp(why) {
  console.log(`  ${why} — restarting`);
  const previous = child;
  child = null;
  previous?.kill();
  // Every device starts over: the new process numbers its nodes from 1, and an
  // id means nothing across a restart.
  broadcast({ type: "reset" });
  startApp();
}

/* ---- watching ------------------------------------------------------------ */

let pending = null;
function onChange(file) {
  if (!file || !file.endsWith(".res.mjs")) return;
  // ReScript writes a compiled file per module, so one save is a burst.
  clearTimeout(pending);
  pending = setTimeout(() => restartApp(file), 80);
}

for (const dir of WATCHED) {
  watch(join(packageRoot, dir), { recursive: true }, (_event, file) => onChange(file));
}

/* ---- the wire ------------------------------------------------------------ */

const server = createServer((request, response) => {
  const url = new URL(request.url, "http://localhost");

  /* The stream. One response that never ends, a JSON message per line. */
  if (request.method === "GET" && url.pathname === "/stream") {
    response.writeHead(200, {
      "content-type": "application/x-ndjson",
      "cache-control": "no-store",
      connection: "keep-alive",
    });
    clients.add(response);
    console.log(`  a device connected (${clients.size} connected)`);

    // Whatever the app has drawn so far, in order, so a device that arrives
    // late sees the same screen as one that was here from the start.
    send(response, { type: "reset" });
    for (const commands of log) send(response, { type: "batch", commands });

    request.on("close", () => {
      clients.delete(response);
      console.log(`  a device disconnected (${clients.size} connected)`);
    });
    return;
  }

  /* An event, coming back. */
  if (request.method === "POST" && url.pathname === "/event") {
    let body = "";
    request.on("data", (chunk) => {
      body += chunk;
    });
    request.on("end", () => {
      try {
        const { id, name, payload } = JSON.parse(body);
        child?.send({ type: "event", id, name, payload });
        response.writeHead(204).end();
      } catch (error) {
        response.writeHead(400).end(String(error));
      }
    });
    return;
  }

  /* Somewhere to point a browser to see that the server is up. */
  if (request.method === "GET" && url.pathname === "/") {
    response.writeHead(200, { "content-type": "application/json" }).end(
      JSON.stringify(
        { app: APP, generation, devices: clients.size, batches: log.length },
        null,
        1,
      ),
    );
    return;
  }

  response.writeHead(404).end();
});

server.listen(PORT, () => {
  console.log(`\n  Xote dev server on http://localhost:${PORT}`);
  console.log(`  the app runs here; the device draws it\n`);
  startApp();
});

const shutdown = () => {
  child?.kill();
  server.close();
  process.exit(0);
};
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

export { server };
