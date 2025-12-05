open Xote

// Theme management
let theme = Signal.make("light")

let toggleTheme = _evt => {
  Signal.update(theme, current =>
    switch current {
    | "light" => "dark"
    | _ => "light"
    }
  )
}

// Update document theme
let _ = Effect.run(() => {
  let currentTheme = Signal.get(theme)
  %raw(`document.documentElement.setAttribute('data-theme', currentTheme)`)
  None
})

// Header component
let header = () => {
  <header class="header">
    <div class="header-container">
      <a href="/" class="logo"> {Component.text("Xote")} </a>
      <nav class="nav">
        <a href="/"> {Component.text("Home")} </a>
        <a href="/docs"> {Component.text("Docs")} </a>
        <a href="/demos"> {Component.text("Demos")} </a>
        <a href="https://www.npmjs.com/package/xote" target="_blank">
          {Component.text("npm")}
        </a>
        <a href="https://github.com/brnrdog/xote" target="_blank">
          {Component.text("GitHub")}
        </a>
        <button class="theme-toggle" onClick={toggleTheme}>
          {Component.textSignal(() =>
            Signal.get(theme) == "light" ? "🌙" : "☀️"
          )}
        </button>
      </nav>
    </div>
  </header>
}

// Footer component
let footer = () => {
  <footer class="footer">
    <div class="footer-container">
      <div class="footer-column">
        <h4> {Component.text("Docs")} </h4>
        <ul>
          <li>
            <a href="/docs"> {Component.text("Getting Started")} </a>
          </li>
          <li>
            <a href="/docs/api/signals"> {Component.text("API Reference")} </a>
          </li>
        </ul>
      </div>
      <div class="footer-column">
        <h4> {Component.text("Resources")} </h4>
        <ul>
          <li>
            <a href="/demos"> {Component.text("Demos")} </a>
          </li>
          <li>
            <a href="https://github.com/brnrdog/xote" target="_blank">
              {Component.text("GitHub")}
            </a>
          </li>
          <li>
            <a href="https://www.npmjs.com/package/xote" target="_blank">
              {Component.text("npm")}
            </a>
          </li>
        </ul>
      </div>
      <div class="footer-column">
        <h4> {Component.text("More")} </h4>
        <ul>
          <li>
            <a href="https://rescript-lang.org/" target="_blank">
              {Component.text("ReScript")}
            </a>
          </li>
          <li>
            <a href="https://github.com/tc39/proposal-signals" target="_blank">
              {Component.text("TC39 Signals Proposal")}
            </a>
          </li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">
      {Component.text(`Copyright © ${Date.now()->Date.fromTime->Date.getFullYear->Int.toString} Xote. Built with Xote.`)}
    </div>
  </footer>
}

// Main layout wrapper
let make = (~children) => {
  <div>
    {header()}
    <main> {children} </main>
    {footer()}
  </div>
}
