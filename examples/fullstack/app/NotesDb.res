/* A pretend database. Only the server imports this module (through
 `NotesServer`), so none of it reaches the client bundle. */

type note = NotesPages.note

let notes: array<note> = [
  {
    id: "1",
    title: "Server-rendered by default",
    body: "Every page is rendered on the server from its loader's data, then hydrated.",
  },
  {
    id: "2",
    title: "Forms without JavaScript",
    body: "Actions handle plain POSTs and redirect. With JavaScript, the same forms submit without a reload.",
  },
]

let nextId = ref(3)

/* Pretend every query takes a little while. */
let wait = () => Promise.make((resolve, _) => setTimeout(() => resolve(), 150)->ignore)

let all = async () => {
  await wait()
  notes->Array.toReversed
}

let find = async id => {
  await wait()
  notes->Array.find(note => note.id == id)
}

let create = async (~title, ~body) => {
  await wait()
  let note: note = {id: Int.toString(nextId.contents), title, body}
  nextId := nextId.contents + 1
  notes->Array.push(note)
  note
}

let delete = async id => {
  await wait()
  switch notes->Array.findIndexOpt(note => note.id == id) {
  | Some(index) => notes->Array.splice(~start=index, ~remove=1, ~insert=[])
  | None => ()
  }
}
