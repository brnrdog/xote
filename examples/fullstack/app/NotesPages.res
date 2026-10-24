/* The pages of the notes app: URL, data shape and view. Shared by server and
 client; loaders and actions live in `NotesServer`. */

module Codec = SSRState.Codec

type note = {id: string, title: string, body: string}

let noteCodec: Codec.t<note> = Codec.make(
  ~encode=note =>
    JSON.Encode.object(
      dict{
        "id": JSON.Encode.string(note.id),
        "title": JSON.Encode.string(note.title),
        "body": JSON.Encode.string(note.body),
      },
    ),
  ~decode=json =>
    switch json {
    | JSON.Object(dict{
        "id": JSON.String(id),
        "title": JSON.String(title),
        "body": JSON.String(body),
      }) =>
      Some({id, title, body})
    | _ => None
    },
)

let home = StackPage.make(
  ~path="/",
  ~codec=Codec.int,
  ~title=_ => "Xote notes",
  ({data: count}) =>
    <section>
      <h1> {View.text("Xote, full stack")} </h1>
      <p>
        {View.text(
          "Pages are rendered on the server from their loader's data, hydrated in the browser, and then navigated on the client by fetching JSON. ",
        )}
      </p>
      <p>
        <a href="/notes">
          {View.text(`See the ${Int.toString(count)} note${count == 1 ? "" : "s"} →`)}
        </a>
      </p>
    </section>,
)

/* The list page mixes server data with client state: the filter is a local
 signal that works once the page has hydrated. */
module NoteList = {
  @jsx.component
  let make = (~notes: array<note>) => {
    let query = Signal.make("")
    let visible = Computed.make(() => {
      let q = Signal.get(query)->String.toLowerCase
      notes->Array.filter(note => note.title->String.toLowerCase->String.includes(q))
    })
    <div>
      <input
        type_="search"
        placeholder="Filter notes"
        onInput={event => Signal.set(query, (event->Obj.magic)["target"]["value"])}
      />
      <ul class="notes">
        <View.For
          each={MaybeSignal.reactive(visible)}
          by={note => note.id}
          render={note =>
            <li>
              <a href={`/notes/${note.id}`}> {View.text(note.title)} </a>
            </li>}
        />
      </ul>
    </div>
  }
}

let notes = StackPage.make(
  ~path="/notes",
  ~codec=Codec.array(noteCodec),
  ~title=_ => "Notes",
  ({data: notes, error}) =>
    <section>
      <h1> {View.text("Notes")} </h1>
      <NoteList notes />
      <form method="post" class="new-note">
        <h2> {View.text("New note")} </h2>
        {switch error {
        | Some(message) => <p class="error"> {View.text(message)} </p>
        | None => View.fragment([])
        }}
        <input name="title" placeholder="Title" />
        <textarea name="body" placeholder="Say something" rows={3} />
        <button type_="submit"> {View.text("Add note")} </button>
      </form>
    </section>,
)

let note = StackPage.make(
  ~path="/notes/:id",
  ~codec=noteCodec,
  ~title=note => note.title,
  ({data: note}) => {
    let likes = Signal.make(0)
    <article>
      <p>
        <a href="/notes"> {View.text("← All notes")} </a>
      </p>
      <h1> {View.text(note.title)} </h1>
      <p> {View.text(note.body)} </p>
      <div class="actions">
        <button type_="button" onClick={_ => Signal.update(likes, n => n + 1)}>
          {View.signalText(() => `♥ ${Int.toString(Signal.get(likes))}`)}
        </button>
        <form method="post">
          <button type_="submit" name="intent" value="delete" class="danger">
            {View.text("Delete")}
          </button>
        </form>
      </div>
    </article>
  },
)

let about = StackPage.make(
  ~path="/about",
  ~codec=Codec.string,
  ~title=_ => "About",
  ({data}) =>
    <section>
      <h1> {View.text("About")} </h1>
      <p> {View.text(data)} </p>
    </section>,
)
