open! Zekr

/* `RuntimeTemplate` clones a region's repeated shapes: the first tree of a
   shape is rendered node by node, the second records a skeleton while it
   renders, and every one after that is a clone of the skeleton filled from
   its own tree. The rows below are therefore built three different ways, and
   each test reads the rows past the second — the cloned ones. */

type item = {id: string, label: string}

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
let querySelectorAll: ('a, string) => array<'b> = %raw(`function (el, selector) {
  return Array.from(el.querySelectorAll(selector))
}`)
@get external tagName: 'a => string = "tagName"
@get external selectValue: 'a => string = "value"
@get external childNodeCount: 'a => int = "childElementCount"

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let rows = (container): array<string> =>
  container->querySelectorAll("li")->Array.map(Zekr__DomBindings.textContent)

let attribute = (el, name) =>
  Zekr__DomBindings.getAttribute(el, name)->Nullable.toOption->Option.getOr("")

let subscriberCount: Signal.t<'a> => int = %raw(`function (signal) {
  let count = 0
  let link = signal.subs.first
  while (link) { count = count + 1; link = link.nextSub }
  return count
}`)

let countDomCalls: (string, unit => unit) => int = %raw(`function (name, run) {
  const proto = name === "cloneNode" ? globalThis.Node.prototype : Object.getPrototypeOf(globalThis.document)
  const original = proto[name]
  let calls = 0
  proto[name] = function (...args) { calls++; return original.apply(this, args) }
  try { run() } finally { proto[name] = original }
  return calls
}`)

let build = ids => ids->Array.map(id => {id, label: "L" ++ id})

let el = (tag, ~attrs=[], ~children=[], ()) => View.element(tag, ~attrs, ~children, ())

module Row = {
  @jsx.component
  let make = (~item: item, ~bodies: ref<int>, ~effects: ref<int>, ~tick: Signal.t<int>) => {
    bodies := bodies.contents + 1
    Effect.run(() => {
      let _ = Signal.get(tick)
      effects := effects.contents + 1
      None
    })
    <li class="row"> {View.text(item.label)} </li>
  }
}

let suite = Zekr.suite(
  "Template",
  [
    test("rows past the second are clones, and clones are as reactive as originals", () => {
      let {container} = Dom.render("")
      let theme = Signal.make("light")
      let labels = ["1", "2", "3", "4", "5"]->Array.map(id => Signal.make("L" ++ id))
      let clicks = ref("")
      let items = Signal.make(build(["1", "2", "3", "4", "5"]))
      let _ = mountTo(
        Html.ul(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                Html.li(
                  ~attrs=[View.signalAttr("class", theme)],
                  ~events=[("click", _ => clicks := clicks.contents ++ item.id)],
                  ~children=[
                    View.signalText(() =>
                      Signal.get(labels->Array.getUnsafe(Int.fromString(item.id)->Option.getOr(1) - 1))
                    ),
                  ],
                  (),
                ),
            ),
          ],
          (),
        ),
        container,
      )
      let initial = rows(container)
      Signal.set(labels->Array.getUnsafe(3), "four")
      Signal.set(theme, "dark")
      let lis = container->querySelectorAll("li")
      Dom.Event.click(lis->Array.getUnsafe(4))
      combineResults([
        assertEqual(initial, ["L1", "L2", "L3", "L4", "L5"]),
        assertEqual(rows(container), ["L1", "L2", "L3", "four", "L5"]),
        assertEqual(lis->Array.map(li => attribute(li, "class")), ["dark", "dark", "dark", "dark", "dark"]),
        assertEqual(clicks.contents, "5"),
      ])
    }),
    test("a list of a hundred rows creates one element per shape, not per row", () => {
      let {container} = Dom.render("")
      let items = Signal.make([])
      let _ = mountTo(
        Html.ul(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                Html.li(
                  ~children=[
                    Html.span(~attrs=[View.attr("class", "id")], ~children=[View.text(item.id)], ()),
                    Html.span(~attrs=[View.attr("class", "label")], ~children=[View.text(item.label)], ()),
                  ],
                  (),
                ),
            ),
          ],
          (),
        ),
        container,
      )
      let ids = Array.fromInitializer(~length=100, i => Int.toString(i))
      let creates = countDomCalls("createElement", () => Signal.set(items, build(ids)))
      let clones = countDomCalls("cloneNode", () => Signal.set(items, build(ids->Array.map(id => "b" ++ id))))
      combineResults([
        /* row one node by node (3), row two plus its skeleton (6), then clones */
        assertEqual(creates, 9),
        assertEqual(clones, 100),
        assertEqual(Array.length(rows(container)), 100),
        assertEqual(rows(container)->Array.getUnsafe(99), "b99Lb99"),
      ])
    }),
    test("static attributes that vary between rows are written on the clone", () => {
      let {container} = Dom.render("")
      let items = Signal.make(build(["1", "2", "3", "4", "5"]))
      let _ = mountTo(
        Html.ul(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                Html.li(
                  ~attrs=[View.attr("id", "row-" ++ item.id), View.attr("class", "row")],
                  ~children=[el("b", ~attrs=[View.attr("title", item.label)], ~children=[View.text(item.label)], ())],
                  (),
                ),
            ),
          ],
          (),
        ),
        container,
      )
      let lis = container->querySelectorAll("li")
      combineResults([
        assertEqual(lis->Array.map(li => attribute(li, "id")), ["row-1", "row-2", "row-3", "row-4", "row-5"]),
        assertEqual(lis->Array.map(li => attribute(li, "class")), ["row", "row", "row", "row", "row"]),
        assertEqual(
          container->querySelectorAll("b")->Array.map(b => attribute(b, "title")),
          ["L1", "L2", "L3", "L4", "L5"],
        ),
        assertEqual(rows(container), ["L1", "L2", "L3", "L4", "L5"]),
      ])
    }),
    test("rows of a different structure fall back to an ordinary render", () => {
      let {container} = Dom.render("")
      let items = Signal.make(build(["1", "2", "3", "4", "5", "6"]))
      let _ = mountTo(
        Html.ul(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                switch item.id {
                | "3" => Html.li(~children=[el("i", ~children=[View.text("italic " ++ item.id)], ())], ())
                | "5" => Html.li(~children=[View.text("a"), View.text("b"), View.text(item.id)], ())
                | _ => Html.li(~children=[el("b", ~children=[View.text("bold " ++ item.id)], ())], ())
                },
            ),
          ],
          (),
        ),
        container,
      )
      let lis = container->querySelectorAll("li")
      let firstChildTag = li =>
        switch querySelector(li, "*")->Nullable.toOption {
        | Some(child) => tagName(child)
        | None => "-"
        }
      combineResults([
        assertEqual(rows(container), ["bold 1", "bold 2", "italic 3", "bold 4", "ab5", "bold 6"]),
        assertEqual(lis->Array.map(firstChildTag), ["B", "B", "I", "B", "-", "B"]),
      ])
    }),
    test("a component rendered per row runs its body once per row", () => {
      let {container} = Dom.render("")
      let bodies = ref(0)
      let effects = ref(0)
      let tick = Signal.make(0)
      let pool = build(["1", "2", "3", "4", "5"])
      let items = Signal.make(pool)
      let _ = mountTo(
        Html.ul(
          ~children=[
            View.eachWithKey(items, item => item.id, item => <Row item={item} bodies={bodies} effects={effects} tick={tick} />),
          ],
          (),
        ),
        container,
      )
      let mountedBodies = bodies.contents
      let mountedEffects = effects.contents
      Signal.set(tick, 1)
      let afterTick = effects.contents
      /* Dropping the cloned rows disposes their effects too. The survivors
         keep their instances, so they are kept rather than rebuilt. */
      Signal.set(items, pool->Array.slice(~start=0, ~end=2))
      Signal.set(tick, 2)
      combineResults([
        assertEqual(rows(container), ["L1", "L2"]),
        assertEqual(mountedBodies, 5),
        assertEqual(mountedEffects, 5),
        assertEqual(afterTick, 10),
        assertEqual(effects.contents, 12),
        assertEqual(subscriberCount(tick), 2),
      ])
    }),
    test("a nested keyed list inside a cloned row reconciles on its own", () => {
      let {container} = Dom.render("")
      let inner = ["1", "2", "3"]->Array.map(_ => Signal.make(build(["a", "b"])))
      let items = Signal.make(build(["1", "2", "3"]))
      let _ = mountTo(
        Html.div(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                el(
                  "section",
                  ~children=[
                    Html.h3(~children=[View.text(item.label)], ()),
                    Html.ul(
                      ~children=[
                        View.eachWithKey(
                          inner->Array.getUnsafe(Int.fromString(item.id)->Option.getOr(1) - 1),
                          sub => sub.id,
                          sub => Html.li(~children=[View.text(item.id ++ sub.label)], ()),
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
            ),
          ],
          (),
        ),
        container,
      )
      let initial = rows(container)
      Signal.set(inner->Array.getUnsafe(2), build(["c", "a"]))
      combineResults([
        assertEqual(initial, ["1La", "1Lb", "2La", "2Lb", "3La", "3Lb"]),
        assertEqual(rows(container), ["1La", "1Lb", "2La", "2Lb", "3Lc", "3La"]),
        assertEqual(Array.length(container->querySelectorAll("section")), 3),
      ])
    }),
    test("a select inside a cloned row shows its own value", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "1", label: "a"}, {id: "2", label: "b"}, {id: "3", label: "b"}, {id: "4", label: "a"}])
      let _ = mountTo(
        Html.div(
          ~children=[
            View.eachWithKey(
              items,
              item => item.id,
              item =>
                View.element(
                  "select",
                  ~attrs=[View.attr("value", item.label)],
                  ~children=[
                    View.element("option", ~attrs=[View.attr("value", "a")], ~children=[View.text("a")], ()),
                    View.element("option", ~attrs=[View.attr("value", "b")], ~children=[View.text("b")], ()),
                  ],
                  (),
                ),
            ),
          ],
          (),
        ),
        container,
      )
      assertEqual(container->querySelectorAll("select")->Array.map(selectValue), ["a", "b", "b", "a"])
    }),
    test("a tracked block that re-renders is cloned from its second pass on", () => {
      let {container} = Dom.render("")
      let count = Signal.make(0)
      let name = Signal.make("x")
      let _ = mountTo(
        View.tracked(() =>
          Html.div(
            ~attrs=[View.attr("class", "card")],
            ~children=[
              Html.span(~children=[View.text(Signal.get(count)->Int.toString)], ()),
              el("b", ~children=[View.signalText(() => Signal.get(name))], ()),
            ],
            (),
          )
        ),
        container,
      )
      [1, 2, 3, 4]->Array.forEach(n => Signal.set(count, n))
      let afterCounts = Zekr__DomBindings.textContent(container)
      Signal.set(name, "y")
      combineResults([
        assertEqual(afterCounts, "4x"),
        assertEqual(Zekr__DomBindings.textContent(container), "4y"),
        /* one leaf computed is live at a time: each pass releases the last */
        assertEqual(subscriberCount(name), 1),
        assertEqual(Array.length(container->querySelectorAll(".card")), 1),
      ])
    }),
    test("text that is an element's only child is written without a script-made text node", () => {
      let {container} = Dom.render("")
      let items = Signal.make(build(["1", "2", "3", "4"]))
      let created = countDomCalls("createTextNode", () =>
        View.mount(
          Html.ul(
            ~children=[
              View.eachWithKey(items, item => item.id, item => Html.li(~children=[View.text(item.label)], ())),
            ],
            (),
          ),
          container,
        )
      )
      combineResults([
        assertEqual(created, 0),
        assertEqual(rows(container), ["L1", "L2", "L3", "L4"]),
        assertEqual(container->querySelectorAll("li")->Array.map(li => childNodeCount(li)), [0, 0, 0, 0]),
      ])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
