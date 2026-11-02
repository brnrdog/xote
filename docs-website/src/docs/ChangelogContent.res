// The changelog page: the latest release up top, then every release on a
// timeline grouped by major version. Older majors start collapsed.
// Release data comes from docs/CHANGELOG.md via RepoData.res, which leaves
// pre-releases out.

type kind = Breaking | Feature | Fix | Perf | Refactor | Other

let kindOf = title =>
  switch title {
  | "BREAKING CHANGES" => Breaking
  | "Features" => Feature
  | "Bug Fixes" => Fix
  | "Performance Improvements" => Perf
  | "Code Refactoring" => Refactor
  | _ => Other
  }

// Breaking changes first, then what's new, then fixes.
let kindOrder = kind =>
  switch kind {
  | Breaking => 0
  | Feature => 1
  | Fix => 2
  | Perf => 3
  | Refactor => 4
  | Other => 5
  }

let kindName = kind =>
  switch kind {
  | Breaking => "Breaking changes"
  | Feature => "Features"
  | Fix => "Fixes"
  | Perf => "Performance"
  | Refactor => "Refactoring"
  | Other => "Changes"
  }

let kindClass = kind =>
  switch kind {
  | Breaking => "breaking"
  | Feature => "feature"
  | Fix => "fix"
  | Perf => "perf"
  | Refactor => "refactor"
  | Other => "other"
  }

// "3 features", "1 fix", ... for the summary line.
let countLabel = (kind, count) => {
  let one = switch kind {
  | Breaking => "breaking change"
  | Feature => "feature"
  | Fix => "fix"
  | Perf => "performance change"
  | Refactor => "refactor"
  | Other => "change"
  }
  let many = switch kind {
  | Fix => "fixes"
  | _ => one ++ "s"
  }
  `${Int.toString(count)} ${count == 1 ? one : many}`
}

let sortedSections = (release: RepoData.release) =>
  release.sections->Array.toSorted((a, b) =>
    Int.toFloat(kindOrder(kindOf(a.title)) - kindOrder(kindOf(b.title)))
  )

let hasBreaking = (release: RepoData.release) =>
  release.sections->Array.some(section => kindOf(section.title) == Breaking)

let majorOf = (release: RepoData.release) =>
  release.version->String.split(".")->Array.get(0)->Option.flatMap(s => Int.fromString(s))->Option.getOr(0)

type major = {
  number: int,
  id: string,
  releases: array<RepoData.release>,
}

// Releases grouped by major version, newest first.
let majors: array<major> = {
  let groups: array<major> = []
  RepoData.releases->Array.forEach(release => {
    let number = majorOf(release)
    switch groups->Array.find(group => group.number == number) {
    | Some(group) => group.releases->Array.push(release)->ignore
    | None => groups->Array.push({number, id: `xote-${Int.toString(number)}`, releases: [release]})->ignore
    }
  })
  groups
}

// The two newest majors start open.
let openMajors = 2

let pill = (className, label) => <span class={"cl-pill " ++ className}> {label} </span>

let releaseBadges = (release: RepoData.release, ~isLatest) =>
  View.fragment([
    isLatest ? pill("is-latest", "Latest") : View.null(),
    hasBreaking(release) ? pill("is-breaking", "Breaking") : View.null(),
  ])

let changeRow = (change: RepoData.change) =>
  <li class="cl-change">
    {switch change.scope {
    | Some(scope) => <span class="cl-scope"> {scope} </span>
    | None => View.null()
    }}
    <span class="cl-change-text"> {View.fragment(change.text)} </span>
    {View.fragment(
      change.refs->Array.map(ref =>
        <a class="cl-ref" href={ref.url} target="_blank" attrs=[("rel", "noreferrer")]> {ref.label} </a>
      ),
    )}
  </li>

let releaseBody = (release: RepoData.release) =>
  View.fragment(
    sortedSections(release)->Array.map(section => {
      let kind = kindOf(section.title)
      <section class={"cl-group is-" ++ kindClass(kind)}>
        <h4 class="cl-group-title">
          {kindName(kind)}
          <span class="cl-group-count"> {Array.length(section.changes)} </span>
        </h4>
        <ul class="cl-changes"> {View.fragment(section.changes->Array.map(changeRow))} </ul>
      </section>
    }),
  )

let releaseItem = (release: RepoData.release, ~isLatest) =>
  <li class={isLatest ? "cl-release is-latest" : "cl-release"} id={release.id}>
    <div class="cl-release-head">
      <h3 class="cl-version"> {"v" ++ release.version} </h3>
      {releaseBadges(release, ~isLatest)}
      <time class="cl-date" attrs=[("datetime", release.date)]> {release.formattedDate} </time>
      <a class="cl-compare" href={release.url} target="_blank" attrs=[("rel", "noreferrer")]>
        {"Compare ↗"}
      </a>
    </div>
    <div class="cl-release-body"> {releaseBody(release)} </div>
  </li>

let latestCard = (release: RepoData.release) => {
  let counts =
    sortedSections(release)->Array.map(section =>
      countLabel(kindOf(section.title), Array.length(section.changes))
    )
  <section class="cl-latest" ariaLabel="Latest release">
    <div class="cl-latest-top">
      <span class="cl-latest-label"> {"Latest release"} </span>
      <time class="cl-date" attrs=[("datetime", release.date)]> {release.formattedDate} </time>
    </div>
    <div class="cl-latest-version"> {"v" ++ release.version} </div>
    <p class="cl-latest-summary"> {counts->Array.join(" · ")} </p>
    <div class="cl-latest-actions">
      <a class="btn-pill btn-ink" href={"#" ++ release.id}> {"See what changed ↓"} </a>
      <a class="btn-pill btn-soft" href={release.url} target="_blank" attrs=[("rel", "noreferrer")]>
        {"Compare on GitHub ↗"}
      </a>
      <a class="btn-pill btn-soft" href={RepoData.sourceUrl} target="_blank" attrs=[("rel", "noreferrer")]>
        {"CHANGELOG.md ↗"}
      </a>
    </div>
  </section>
}

let majorRange = (group: major) =>
  switch (group.releases->Array.at(-1), group.releases[0]) {
  | (Some(oldest), Some(newest)) if oldest.date != newest.date =>
    `${oldest.formattedDate} – ${newest.formattedDate}`
  | (_, Some(newest)) => newest.formattedDate
  | _ => ""
  }

let majorSection = (group: major, index) => {
  let count = Array.length(group.releases)
  let summary =
    <summary class="cl-major-head">
      <h2 class="cl-major-title"> {`Xote ${Int.toString(group.number)}`} </h2>
      <span class="cl-major-meta">
        {`${Int.toString(count)} ${count == 1 ? "release" : "releases"} · ${majorRange(group)}`}
      </span>
      <span class="cl-major-toggle" ariaHidden=true />
    </summary>
  let timeline =
    <ol class="cl-timeline">
      {View.fragment(
        group.releases->Array.map(release =>
          releaseItem(release, ~isLatest=release.id == RepoData.releases[0]->Option.mapOr("", r => r.id))
        ),
      )}
    </ol>
  index < openMajors
    ? <details class="cl-major" id={group.id} attrs=[("open", "")]> {summary} {timeline} </details>
    : <details class="cl-major" id={group.id}> {summary} {timeline} </details>
}

let content = () =>
  <div class="cl">
    {switch RepoData.releases[0] {
    | Some(latest) => latestCard(latest)
    | None => View.null()
    }}
    {View.fragment(majors->Array.mapWithIndex(majorSection))}
  </div>

@xote.component
let make = () => content()
