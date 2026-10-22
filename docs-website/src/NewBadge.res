// "New in 7.2" pill for docs content: <New /> in MDX, beside a heading's
// first line or inline in text. Pages that are new as a whole carry `isNew`
// in docs.pages.mjs instead, which badges the sidebar and the page title.

// The release whose features are flagged as new.
let release = "7.2"

@xote.component
let make = (~version=release) => <span class="new-badge"> {"New in " ++ version} </span>
