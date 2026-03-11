# basefn

[![npm version](https://img.shields.io/npm/v/basefn.svg)](https://www.npmjs.com/package/basefn)
[![bundle size](https://img.shields.io/bundlephobia/minzip/basefn)](https://bundlephobia.com/package/basefn)

A UI component library for [Xote](https://github.com/brnrdog/xote) applications. Built with ReScript, designed to be lightweight and customizable.

## Installation

Ensure you have the dependencies installed:

```bash
npm install xote @rescript/core
```

Install `basefn`:

```bash
npm install basefn 
```

**Required peer dependencies:**
- `xote` - The reactive framework
- `@rescript/core` - ReScript standard library

**Add to your `rescript.json`:**
```json
{
  "dependencies": [
    // Standard ReScript library
    "@rescript/core",
    // Signals library
    "rescript-signals", 
    // UI library
    "xote"
  ],
}
```

## Quick Start

```rescript
open Xote
open Basefn

// Static values
<Button
  variant={Primary}
  label={static("Click me")}
  onClick={_ => Console.log("Clicked")}
/>

// Reactive values
let count = Signal.make(0)
<Button
  variant={Primary}
  label={reactive(count->Signal.map(n => `Clicked ${n->Int.toString} times`))}
  onClick={_ => count->Signal.update(n => n + 1)}
/>
```

## Components

**Forms:** [Button](src/components/Basefn__Button.res) · [Input](src/components/Basefn__Input.res) · [Textarea](src/components/Basefn__Textarea.res) · [Checkbox](src/components/Basefn__Checkbox.res) · [Radio](src/components/Basefn__Radio.res) · [Select](src/components/Basefn__Select.res) · [Switch](src/components/Basefn__Switch.res) · [Slider](src/components/Basefn__Slider.res)

**Layout:** [Card](src/components/Basefn__Card.res) · [Grid](src/components/Basefn__Grid.res) · [Separator](src/components/Basefn__Separator.res) · [AppLayout](src/components/Basefn__AppLayout.res) · [Sidebar](src/components/Basefn__Sidebar.res) · [Topbar](src/components/Basefn__Topbar.res)

**Feedback:** [Alert](src/components/Basefn__Alert.res) · [Toast](src/components/Basefn__Toast.res) · [Modal](src/components/Basefn__Modal.res) · [Drawer](src/components/Basefn__Drawer.res) · [Spinner](src/components/Basefn__Spinner.res) · [Progress](src/components/Basefn__Progress.res) · [Tooltip](src/components/Basefn__Tooltip.res)

**Navigation:** [Tabs](src/components/Basefn__Tabs.res) · [Breadcrumb](src/components/Basefn__Breadcrumb.res) · [Stepper](src/components/Basefn__Stepper.res) · [Dropdown](src/components/Basefn__Dropdown.res)

**Data Display:** [Typography](src/components/Basefn__Typography.res) · [Badge](src/components/Basefn__Badge.res) · [Avatar](src/components/Basefn__Avatar.res) · [Timeline](src/components/Basefn__Timeline.res) · [Accordion](src/components/Basefn__Accordion.res) · [Kbd](src/components/Basefn__Kbd.res) · [Icon](src/components/Basefn__Icon.res)

**Utilities:** [ThemeToggle](src/components/Basefn__ThemeToggle.res) · [Label](src/components/Basefn__Label.res)

## Theming

Customize via CSS variables:

```css
:root {
  --basefn-color-primary: #0066cc;
  --basefn-color-secondary: #6c757d;
  --basefn-radius: 0.375rem;
  /* See src/styles/variables.css for all variables */
}
```

## Development

```bash
npm install        # Install dependencies
npm run build      # Build ReScript
npm run watch      # Watch mode
npm run dev        # Dev server with demo
```

## License

MIT
