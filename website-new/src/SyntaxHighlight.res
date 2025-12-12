// Syntax highlighting using Prism.js

@module("prismjs") external prism: {..} = "default"

@module("./prism-rescript.js")
external addReScriptLanguage: ({..}) => unit = "addReScriptLanguage"

// Initialize Prism with ReScript language support
let init = () => {
  addReScriptLanguage(prism)
}

// Highlight all code blocks on the page
let highlightAll = () => {
  %raw(`typeof window !== 'undefined' && window.Prism && window.Prism.highlightAll()`)
}

// Highlight all after a short delay to ensure DOM is ready
let highlightAllDelayed = () => {
  %raw(`
    typeof window !== 'undefined' && setTimeout(() => {
      window.Prism && window.Prism.highlightAll();
    }, 100)
  `)
}

// Highlight a code snippet and return as Component.node
let highlight = (code: string): Xote.Component.node => {
  open Xote
  // For now, return plain text - will be highlighted by highlightAll after render
  Component.text(code)
}
