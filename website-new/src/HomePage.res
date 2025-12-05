open Xote

// Feature data
type feature = {
  title: string,
  icon: string,
  description: string,
}

let features = [
  {
    title: "Zero Dependencies",
    icon: "📦",
    description: "Pure ReScript implementation with no runtime dependencies. Lightweight and efficient, Xote focuses on what matters most - reactivity.",
  },
  {
    title: "Fine-Grained Reactivity",
    icon: "⚡",
    description: "Direct DOM updates without a virtual DOM. Automatic dependency tracking means only what changed gets updated - no manual subscriptions needed.",
  },
  {
    title: "Based on TC39 Signals",
    icon: "🎯",
    description: "Aligned with the TC39 Signals proposal. Build with patterns that will feel familiar as JavaScript evolves to include native reactivity primitives.",
  },
]

// Feature card component
let featureCard = (feature: feature) => {
  <div class="feature-card">
    <div class="feature-icon"> {Component.text(feature.icon)} </div>
    <h3> {Component.text(feature.title)} </h3>
    <p> {Component.text(feature.description)} </p>
  </div>
}

// Hero section
let hero = () => {
  <section class="hero">
    <div class="hero-container">
      <h1> {Component.text("Xote")} </h1>
      <p class="hero-subtitle">
        {Component.text(
          "Lightweight, zero-dependency UI library for ReScript with fine-grained reactivity",
        )}
      </p>
      <div class="hero-buttons">
        <a href="/docs" class="button button-primary">
          {Component.text("Get Started")}
        </a>
        <a href="/demos" class="button button-outline">
          {Component.text("View Demos")}
        </a>
      </div>
    </div>
  </section>
}

// Features section
let featuresSection = () => {
  <section class="features">
    <div class="features-grid">
      {Component.fragment(features->Array.map(f => featureCard(f)))}
    </div>
  </section>
}

// Main homepage component
let make = () => {
  Layout.make(~children={
    Component.fragment([hero(), featuresSection()])
  })
}
