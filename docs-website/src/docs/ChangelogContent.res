let maxVisibleReleases = 10

let changeLabel = count => {
  if count == 1 {
    "1 change"
  } else {
    `${count->Int.toString} changes`
  }
}

let releaseChangeCount = (release: RepoData.release) =>
  Array.reduce(release.sections, 0, (total, section) => total + Array.length(section.items))

let content = () => {
  let visibleReleases =
    RepoData.releases->Array.slice(
      ~start=0,
      ~end=min(maxVisibleReleases, Array.length(RepoData.releases)),
    )

  <div class="changelog-doc">
    <div class="changelog-summary">
      <div>
        <p class="changelog-kicker"> {Node.text("Release history")} </p>
        <p class="changelog-meta">
          {Node.text("Recent versions generated from ")}
          <a href={RepoData.sourceUrl} target="_blank"> {Node.text("docs/CHANGELOG.md")} </a>
        </p>
      </div>
      <a href={RepoData.sourceUrl} target="_blank" class="changelog-source-link">
        {Node.text("Full history")}
      </a>
    </div>
    <div class="changelog-releases">
      {Node.fragment(
        visibleReleases->Array.mapWithIndex((release, index) => {
          let changeCount = releaseChangeCount(release)

          <section class="changelog-release" id={release.id}>
            <header class="changelog-release-head">
              <div class="changelog-version-block">
                {if index == 0 {
                  <span class="changelog-latest"> {Node.text("Latest")} </span>
                } else {
                  Node.fragment([])
                }}
                <h2 class="changelog-release-title">
                  <a href={release.url} target="_blank" class="changelog-release-link">
                    {Node.text("v" ++ release.version)}
                  </a>
                </h2>
              </div>
              <div class="changelog-release-meta">
                <time class="changelog-release-date"> {Node.text(release.date)} </time>
                <span class="changelog-release-count"> {Node.text(changeLabel(changeCount))} </span>
              </div>
            </header>
            <div class="changelog-release-body">
              {Node.fragment(
                release.sections->Array.map(section => {
                  <section class="changelog-section">
                    <div class="changelog-section-head">
                      {if section.title != "" {
                        <h3 class="changelog-section-title"> {Node.text(section.title)} </h3>
                      } else {
                        <h3 class="changelog-section-title"> {Node.text("Changes")} </h3>
                      }}
                      <span class="changelog-section-count">
                        {Node.text(changeLabel(Array.length(section.items)))}
                      </span>
                    </div>
                    <ul class="changelog-list">
                      {Node.fragment(
                        section.items->Array.map(item => {
                          <li class="changelog-item">
                            <span class="changelog-item-marker" ariaHidden=true> {Node.text("")} </span>
                            <span class="changelog-item-copy"> {Node.fragment(item)} </span>
                          </li>
                        }),
                      )}
                    </ul>
                  </section>
                }),
              )}
            </div>
          </section>
        }),
      )}
    </div>
  </div>
}

let make = _props => content()
