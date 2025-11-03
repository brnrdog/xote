# Xote Documentation Website

This directory contains the Docusaurus-based documentation website for Xote with embedded live demos.

## Development

### Prerequisites

- Node.js 20.0 or higher
- npm

### Getting Started

From the **root directory** of the project:

1. Install dependencies:
```bash
npm install
cd website && npm install && cd ..
```

2. Start the development server (this will build ReScript, build demos, and start Docusaurus):
```bash
npm run docs:start
```

This will:
- Compile ReScript code
- Build the demo applications
- Copy demos to the website static folder
- Start the Docusaurus dev server at `http://localhost:3000`

**Note**: The first build may take a minute. Subsequent starts will be faster if demos haven't changed.

### Building

To create a production build:

```bash
npm run build
```

The static files will be generated in the `build/` directory.

### Testing the Build

To serve the production build locally:

```bash
npm run serve
```

## Deployment

The documentation site is automatically deployed to GitHub Pages when changes are pushed to the `main` branch. The deployment is handled by the GitHub Actions workflow defined in `.github/workflows/deploy-docs.yml`.

To manually deploy (requires GitHub Pages to be set up):

```bash
npm run deploy
```

## Documentation Structure

- `docs/` - Documentation pages in Markdown
  - `intro.md` - Getting Started page
  - `core-concepts/` - Core reactivity concepts
  - `components/` - Component system documentation
  - `router/` - Router documentation
  - `api/` - API reference
  - `technical-overview.md` - Technical deep-dive
- `src/pages/` - Custom React pages
  - `index.tsx` - Homepage
  - `demos.tsx` - Demos page
- `src/components/` - React components
- `static/` - Static assets
- `docusaurus.config.ts` - Docusaurus configuration
- `sidebars.ts` - Sidebar navigation configuration

## Writing Documentation

### Adding a New Page

1. Create a new Markdown file in the appropriate directory under `docs/`
2. Add frontmatter at the top:
```markdown
---
sidebar_position: 1
---

# Page Title

Content here...
```

3. Update `sidebars.ts` if needed to add the page to navigation

### Code Blocks

Use fenced code blocks with language identifiers:

\`\`\`rescript
let count = Signal.make(0)
\`\`\`

Supported languages include: `rescript`, `reason`, `ocaml`, `javascript`, `typescript`, `json`, `bash`, etc.

### Links

- Internal docs: `[Link Text](/docs/page-name)`
- External: `[Link Text](https://example.com)`

## Learn More

- [Docusaurus Documentation](https://docusaurus.io/)
- [Markdown Features](https://docusaurus.io/docs/markdown-features)
