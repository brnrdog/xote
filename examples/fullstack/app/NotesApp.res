/* The app as both halves see it: its pages and its layout. */

module Layout = {
  @jsx.component
  let make = (~children: View.node) =>
    <div class="app">
      <div class={() => Signal.get(StackPage.pending) ? "progress active" : "progress"} />
      <header>
        <a href="/" class="brand"> {View.text("xote")} </a>
        <nav>
          <a href="/notes"> {View.text("Notes")} </a>
          <a href="/about"> {View.text("About")} </a>
        </nav>
      </header>
      <main> {children} </main>
    </div>
}

let app: StackPage.app = {
  pages: [
    StackPage.erase(NotesPages.home),
    StackPage.erase(NotesPages.notes),
    StackPage.erase(NotesPages.note),
    StackPage.erase(NotesPages.about),
  ],
  layout: outlet => <Layout> {outlet} </Layout>,
}
