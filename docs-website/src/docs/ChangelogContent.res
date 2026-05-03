let maxVisibleReleases = 10

let content = () => {
  let visibleReleases =
    RepoData.releases->Array.slice(
      ~start=0,
      ~end=min(maxVisibleReleases, Array.length(RepoData.releases)),
    )

  <div class="changelog-doc">
    <p class="changelog-meta">
      {Node.text("See the full history on GitHub: ")}
      <a href={RepoData.sourceUrl} target="_blank"> {Node.text("docs/CHANGELOG.md")} </a>
    </p>
    {Node.fragment(
      visibleReleases->Array.map(release => {
        <section class="changelog-release" id={release.id}>
          <div class="changelog-release-head">
            <div>
              <h2 class="changelog-release-title">
                <a
                  href={release.url}
                  target="_blank"
                  class="changelog-release-link">
                  {Node.text("v" ++ release.version)}
                </a>
              </h2>
              <p class="changelog-release-date"> {Node.text(release.date)} </p>
            </div>
          </div>
          {Node.fragment(
            release.sections->Array.map(section => {
              <div class="changelog-section">
                {if section.title != "" {
                  <h3 class="changelog-section-title"> {Node.text(section.title)} </h3>
                } else {
                  Node.fragment([])
                }}
                <ul class="changelog-list">
                  {Node.fragment(
                    section.items->Array.map(item => {
                      <li class="changelog-item"> {Node.fragment(item)} </li>
                    }),
                  )}
                </ul>
              </div>
            }),
          )}
        </section>
      }),
    )}
    <p class="changelog-more">
      <a href={RepoData.sourceUrl} target="_blank"> {Node.text("View the full changelog on GitHub")} </a>
    </p>
  </div>
}

let make = _props => content()
