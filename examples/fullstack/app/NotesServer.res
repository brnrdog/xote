/* Loaders and actions. This is the only module that touches `NotesDb`. */

open StackServer

let routes = [
  route(NotesPages.home, ~loader=async _ => (await NotesDb.all())->Array.length),
  route(
    NotesPages.notes,
    ~loader=_ => NotesDb.all(),
    ~action=async ({form}) => {
      let field = name => form->Dict.get(name)->Option.getOr("")->String.trim
      switch (field("title"), field("body")) {
      | ("", _) => Invalid("A note needs a title.")
      | (title, body) =>
        let note = await NotesDb.create(~title, ~body)
        Redirect(`/notes/${note.id}`)
      }
    },
  ),
  route(
    NotesPages.note,
    ~loader=async ({params}) =>
      switch await NotesDb.find(params->Dict.getUnsafe("id")) {
      | Some(note) => note
      | None => throw(StackPage.NotFound)
      },
    ~action=async ({params, form}) =>
      switch form->Dict.get("intent") {
      | Some("delete") =>
        await NotesDb.delete(params->Dict.getUnsafe("id"))
        Redirect("/notes")
      | _ => Invalid("Unknown action.")
      },
  ),
  route(NotesPages.about, ~loader=async _ =>
    "This page has no client-side state at all; its data still comes from a loader."
  ),
]

let handler = handler(
  routes,
  {
    layout: NotesApp.app.layout,
    styles: ["/assets/styles.css"],
    scripts: ["/assets/client.js"],
  },
)
