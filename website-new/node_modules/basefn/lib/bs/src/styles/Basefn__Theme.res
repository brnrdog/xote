open Xote

type theme = Light | Dark

// Global theme state
let currentTheme = Signal.make(Light)

// Convert theme to string
let themeToString = (theme: theme) => {
  switch theme {
  | Light => "light"
  | Dark => "dark"
  }
}

// Convert string to theme
let stringToTheme = (str: string) => {
  switch str {
  | "dark" => Dark
  | _ => Light
  }
}

// Apply theme to document (disables transitions temporarily for instant switch)
let applyTheme = (theme: theme) => {
  let themeValue = themeToString(theme)

  (
    %raw(`function(val) {
      // Disable all transitions
      document.documentElement.classList.add('no-transitions');

      // Apply theme
      document.documentElement.setAttribute('data-theme', val);

      // Force reflow to ensure styles are applied
      document.documentElement.offsetHeight;

      // Re-enable transitions after a frame
      requestAnimationFrame(() => {
        document.documentElement.classList.remove('no-transitions');
      });
    }`): string => unit
  )(themeValue)
}

// LocalStorage persistence
let saveThemePreference = (theme: theme) => {
  let themeValue = themeToString(theme)
  (%raw(`function(val) { localStorage.setItem('basefn-theme', val) }`): string => unit)(themeValue)
}

let loadThemePreference = () => {
  let stored: option<string> = %raw(`localStorage.getItem('basefn-theme')`)
  switch stored {
  | Some(value) => stringToTheme(value)
  | None => Light
  }
}

// Toggle between Light and Dark
let toggleTheme = () => {
  let newTheme = switch Signal.get(currentTheme) {
  | Light => Dark
  | Dark => Light
  }
  Signal.set(currentTheme, newTheme)
  applyTheme(newTheme)
  saveThemePreference(newTheme)
}

// Initialize theme system
let init = () => {
  let stored = loadThemePreference()
  Signal.set(currentTheme, stored)
  applyTheme(stored)
}
