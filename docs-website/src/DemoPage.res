// Wrapper for rendering demos inside the docs layout with sidebar
@jsx.component
let make = (
  ~currentPath: string,
  ~demoTitle: string,
  ~demoLead: string,
  ~content: Node.node,
  ~sourceUrl: string,
) => {
  <Layout
    children={
      <div class="docs-layout demo-page-layout">
        <DocsPage.Sidebar currentPath />
        <div class="docs-main demo-page-main">
          <DocsPage.DocsBreadcrumb currentPath />
          <h1 class="docs-page-title"> {Node.text(demoTitle)} </h1>
          <p class="docs-page-lead"> {Node.text(demoLead)} </p>
          <div class="demo-source-link">
            <a href={sourceUrl} target="_blank" class="btn btn-ghost">
              {Basefn.Icon.make({name: GitHub, size: Sm})}
              {Node.text(" View Source")}
            </a>
          </div>
          <div class="demo-page-content"> {content} </div>
        </div>
      </div>
    }
  />
}
