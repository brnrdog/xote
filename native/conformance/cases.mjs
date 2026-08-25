/**
 * The host conformance suite.
 *
 * Each case is a viewport, a sequence of command batches, and the screen a
 * correct host ends up with — the tree, every frame in root coordinates, and
 * the text. The batches are the real wire format, so a host passes this by
 * being right rather than by being written a particular way.
 *
 * Two things make the comparison possible across languages. Frames are in root
 * coordinates, so a host is free to arrange its own view hierarchy however it
 * likes. And text is measured by the stub in `host/reference.mjs` — a
 * fixed-width font, wrapping on whole characters — because `UILabel`,
 * `StaticLayout` and Chromium will never agree on real metrics, and a suite
 * that depends on them tests fonts instead of hosts.
 *
 * Expected values are generated, not hand-written: `generate.mjs` runs each
 * case through the reference host and records the answer. That is only worth
 * anything because the layout underneath is itself checked against Chromium —
 * see `native/test/layout_test.mjs`.
 */

const CREATE = 1;
const CREATE_TEXT = 2;
const SET_PROP = 3;
const SET_TEXT = 4;
const INSERT = 5;
const REMOVE = 6;
const DESTROY = 7;
const LISTEN = 8;

/** A tiny builder, so a case reads as a tree rather than as opcodes. */
function builder() {
  let next = 1;
  const commands = [];
  const api = {
    root(style) {
      const id = next++;
      commands.push([CREATE, id, "root"]);
      if (style) commands.push([SET_PROP, id, "style", style]);
      return id;
    },
    node(type, style) {
      const id = next++;
      commands.push([CREATE, id, type]);
      if (style) commands.push([SET_PROP, id, "style", style]);
      return id;
    },
    text(value) {
      const id = next++;
      commands.push([CREATE_TEXT, id, value]);
      return id;
    },
    prop(id, key, value) {
      commands.push([SET_PROP, id, key, value]);
      return id;
    },
    setText(id, value) {
      commands.push([SET_TEXT, id, value]);
      return id;
    },
    listen(id, event) {
      commands.push([LISTEN, id, event]);
      return id;
    },
    insert(parent, child, index) {
      commands.push([INSERT, parent, child, index]);
      return child;
    },
    remove(parent, child) {
      commands.push([REMOVE, parent, child]);
    },
    destroy(id) {
      commands.push([DESTROY, id]);
    },
    /** Attach `children` under `parent` in order. */
    fill(parent, children) {
      children.forEach((child, index) => api.insert(parent, child, index));
      return parent;
    },
    take() {
      const out = commands.splice(0, commands.length);
      return out;
    },
  };
  return api;
}

const VIEWPORT = { width: 320, height: 640 };

function boxes() {
  const b = builder();
  const root = b.root();
  const screen = b.node("view", { flex: 1, padding: 16, gap: 12 });
  const header = b.node("view", { height: 40, backgroundColor: "#222222" });
  const row = b.node("view", {
    flexDirection: "row",
    gap: 8,
    alignItems: "center",
    justifyContent: "space-between",
  });
  const left = b.node("view", { width: 60, height: 24 });
  const middle = b.node("view", { flex: 1, height: 20 });
  const right = b.node("view", { width: "25%", height: 32 });
  const footer = b.node("view", { height: 24, marginTop: 8 });
  const badge = b.node("view", { position: "absolute", top: 4, right: 4, width: 18, height: 18 });

  b.fill(row, [left, middle, right]);
  b.fill(screen, [header, row, footer, badge]);
  b.insert(root, screen, 0);

  return { name: "boxes", viewport: VIEWPORT, steps: [b.take()] };
}

function reverseAndOverflow() {
  const b = builder();
  const root = b.root();
  const screen = b.node("view", { flex: 1, flexDirection: "column-reverse", padding: 10 });
  const tall = b.node("view", { height: 400 });
  const taller = b.node("view", { height: 400 });
  const strip = b.node("view", {
    flexDirection: "row-reverse",
    justifyContent: "space-evenly",
    height: 40,
    width: 100,
  });
  const a = b.node("view", { width: 80, height: 10 });
  const c = b.node("view", { width: 80, height: 10 });

  b.fill(strip, [a, c]);
  b.fill(screen, [tall, taller, strip]);
  b.insert(root, screen, 0);

  return { name: "reverse and overflow", viewport: VIEWPORT, steps: [b.take()] };
}

function textAndWrapping() {
  const b = builder();
  const root = b.root();
  const screen = b.node("view", { flex: 1, padding: 12, gap: 6 });

  const title = b.node("text", { fontSize: 20 });
  const titleRun = b.text("Xote Native");
  b.insert(title, titleRun, 0);

  const body = b.node("text", {});
  const bodyRun = b.text("a paragraph long enough that it has to wrap more than once");
  b.insert(body, bodyRun, 0);

  // Two runs in one text node — a host that keeps only the last one is caught.
  const joined = b.node("text", {});
  const first = b.text("one ");
  const second = b.text("two");
  b.fill(joined, [first, second]);

  // A bare text node directly inside a box, which is what an absent reactive
  // branch renders. It has no size but it does have an index.
  const placeholder = b.text("");

  b.fill(screen, [title, body, joined, placeholder]);
  b.insert(root, screen, 0);

  const steps = [b.take()];
  b.setText(bodyRun, "short now");
  b.setText(placeholder, "the branch appeared");
  steps.push(b.take());

  return { name: "text and wrapping", viewport: VIEWPORT, steps };
}

function keyedReorder() {
  const b = builder();
  const root = b.root();
  const list = b.node("view", { flex: 1, padding: 8, gap: 4 });
  const rows = [0, 1, 2, 3].map((i) =>
    b.node("view", { height: 20 + i * 4, backgroundColor: "#333333" }),
  );
  b.fill(list, rows);
  b.insert(root, list, 0);
  const steps = [b.take()];

  // A move is a remove and an insert in the same batch — the reconciler does
  // exactly this, and a host that destroys on remove loses the view.
  b.remove(list, rows[0]);
  b.insert(list, rows[0], 3);
  steps.push(b.take());

  // A retirement: removed, then destroyed at the flush.
  b.remove(list, rows[1]);
  b.destroy(rows[1]);
  steps.push(b.take());

  return { name: "keyed reorder", viewport: VIEWPORT, steps };
}

function scrolling() {
  const b = builder();
  const root = b.root();
  const scroll = b.node("scroll", { flex: 1, padding: 10, gap: 10 });
  const rows = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(() => b.node("view", { height: 80 }));
  b.fill(scroll, rows);
  b.insert(root, scroll, 0);
  return { name: "scrolling", viewport: VIEWPORT, steps: [b.take()] };
}

function nested() {
  const b = builder();
  const root = b.root();
  const screen = b.node("view", { flex: 1, paddingHorizontal: 20, paddingTop: 40, gap: 20 });

  const card = b.node("view", { padding: 16, gap: 10, borderWidth: 2, borderRadius: 8 });
  const cardRow = b.node("view", { flexDirection: "row", justifyContent: "space-between" });
  const cardLeft = b.node("text", { fontSize: 18 });
  b.insert(cardLeft, b.text("Todos"), 0);
  const cardRight = b.node("text", { fontSize: 14 });
  b.insert(cardRight, b.text("2 left"), 0);
  b.fill(cardRow, [cardLeft, cardRight]);

  const item = b.node("view", {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 8,
  });
  const check = b.node("view", { width: 18, height: 18, borderRadius: 9, borderWidth: 2 });
  const label = b.node("text", { fontSize: 16 });
  b.insert(label, b.text("Wire the bridge"), 0);
  b.fill(item, [check, label]);

  const button = b.node("pressable", {
    paddingVertical: 12,
    paddingHorizontal: 18,
    borderRadius: 12,
    alignSelf: "flex-start",
  });
  b.listen(button, "press");
  const buttonLabel = b.node("text", { fontSize: 16 });
  b.insert(buttonLabel, b.text("Add task"), 0);
  b.insert(button, buttonLabel, 0);

  b.fill(card, [cardRow, item, button]);
  b.fill(screen, [card]);
  b.insert(root, screen, 0);

  return { name: "nested screen", viewport: VIEWPORT, steps: [b.take()] };
}

export const cases = [
  boxes(),
  reverseAndOverflow(),
  textAndWrapping(),
  keyedReorder(),
  scrolling(),
  nested(),
];
