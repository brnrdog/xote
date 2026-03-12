open Xote

// Wrapper for rendering demos inside the docs layout with sidebar
type props = {
  currentPath: string,
  demoTitle: string,
  demoLead: string,
  content: Component.node,
  sourceUrl: string,
}

let make = (props: props) => {
  let {currentPath, demoTitle, demoLead, content, sourceUrl} = props

  <Layout
    children={
      <div class="docs-layout demo-page-layout">
        <DocsPage.Sidebar currentPath />
        <div class="docs-main demo-page-main">
          <DocsPage.DocsBreadcrumb currentPath />
          <h1 class="docs-page-title"> {Component.text(demoTitle)} </h1>
          <p class="docs-page-lead"> {Component.text(demoLead)} </p>
          <div class="demo-source-link">
            <a href={sourceUrl} target="_blank" class="btn btn-ghost">
              {Basefn.Icon.make({name: GitHub, size: Sm})}
              {Component.text(" View Source")}
            </a>
          </div>
          <div class="demo-page-content"> {content} </div>
        </div>
      </div>
    }
  />
}
