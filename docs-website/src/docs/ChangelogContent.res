let changeLabel = count => {
  if count == 1 {
    "1 change"
  } else {
    `${count->Int.toString} changes`
  }
}

let sectionTitle = title => {
  if title == "" {
    "Changes"
  } else {
    title
  }
}

let sectionTone = title =>
  switch title {
  | "Features" => "feature"
  | "Bug Fixes" => "fix"
  | "Performance Improvements" => "perf"
  | "BREAKING CHANGES" => "breaking"
  | _ => "change"
  }

let releaseChangeCount = (release: RepoData.release) =>
  Array.reduce(release.sections, 0, (total, section) => total + Array.length(section.items))

let content = () => {
  let releases = RepoData.releases

  <div class="changelog-doc">
    <section class="changelog-hero">
      <div class="changelog-hero-copy">
        <p class="changelog-kicker"> {Node.text("Release history")} </p>
        <p class="changelog-meta">
          {Node.text("Scan every xote release, grouped by version with the release date visible on each entry. ")}
          <a href={RepoData.sourceUrl} target="_blank"> {Node.text("View full changelog")} </a>
        </p>
      </div>
    </section>

    <nav class="changelog-index" ariaLabel="Jump to release">
      <div class="changelog-index-head">
        <span class="changelog-index-title"> {Node.text("Versions")} </span>
        <span class="changelog-index-hint"> {Node.text("Version · release date · changes")} </span>
      </div>
      <div class="changelog-index-list">
        {Node.fragment(
          releases->Array.mapWithIndex((release, index) => {
            let count = releaseChangeCount(release)
            <a
              href={"#" ++ release.id}
              class={if index == 0 {
                "changelog-index-item is-latest"
              } else {
                "changelog-index-item"
              }}>
              <span class="changelog-index-version"> {Node.text("v" ++ release.version)} </span>
              {if index == 0 {
                <span class="changelog-index-latest"> {Node.text("Latest")} </span>
              } else {
                Node.fragment([])
              }}
              <span class="changelog-index-date"> {Node.text(release.formattedDate)} </span>
              <span class="changelog-index-count"> {Node.text(changeLabel(count))} </span>
            </a>
          }),
        )}
      </div>
    </nav>

    <div class="changelog-releases">
      {Node.fragment(
        releases->Array.mapWithIndex((release, index) => {
          let changeCount = releaseChangeCount(release)

          <article class="changelog-release" id={release.id}>
            <header class="changelog-release-head">
              <div class="changelog-version-block">
                <h2 class="changelog-release-title">
                  <a href={release.url} target="_blank" class="changelog-release-link">
                    {Node.text("v" ++ release.version)}
                  </a>
                </h2>
                {if index == 0 {
                  <span class="changelog-latest"> {Node.text("Latest")} </span>
                } else {
                  Node.fragment([])
                }}
              </div>
              <div class="changelog-release-meta">
                <time class="changelog-release-date"> {Node.text(release.formattedDate)} </time>
                <span class="changelog-release-count"> {Node.text(changeLabel(changeCount))} </span>
              </div>
            </header>
            <div class="changelog-release-body">
              {Node.fragment(
                release.sections->Array.map(section => {
                  let title = sectionTitle(section.title)

                  <section class={"changelog-section changelog-section-" ++ sectionTone(section.title)}>
                    <div class="changelog-section-head">
                      <h3 class="changelog-section-title">
                        {Node.text(title)}
                      </h3>
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
          </article>
        }),
      )}
    </div>
  </div>
}

let make = _props => content()
