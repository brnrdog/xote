%%raw(`import './components/Basefn__Responsive.css'`)
open Xote

// ============================================================================
// Breakpoints
// ============================================================================

type breakpoint = Xs | Sm | Md | Lg | Xl | Xxl

let breakpointToPixels = (bp: breakpoint): int => {
  switch bp {
  | Xs => 480
  | Sm => 640
  | Md => 768
  | Lg => 1024
  | Xl => 1280
  | Xxl => 1536
  }
}

let breakpointToString = (bp: breakpoint): string => {
  switch bp {
  | Xs => "xs"
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  | Xl => "xl"
  | Xxl => "xxl"
  }
}

// ============================================================================
// Media query strings
// ============================================================================

let minWidth = (bp: breakpoint): string => {
  let px = breakpointToPixels(bp)
  `(min-width: ${Int.toString(px)}px)`
}

let maxWidth = (bp: breakpoint): string => {
  let px = breakpointToPixels(bp) - 1
  `(max-width: ${Int.toString(px)}px)`
}

let between = (lower: breakpoint, upper: breakpoint): string => {
  let minPx = breakpointToPixels(lower)
  let maxPx = breakpointToPixels(upper) - 1
  `(min-width: ${Int.toString(minPx)}px) and (max-width: ${Int.toString(maxPx)}px)`
}

// Predefined media query strings
module Query = {
  let xsUp = minWidth(Xs)
  let smUp = minWidth(Sm)
  let mdUp = minWidth(Md)
  let lgUp = minWidth(Lg)
  let xlUp = minWidth(Xl)
  let xxlUp = minWidth(Xxl)

  let xsDown = maxWidth(Xs)
  let smDown = maxWidth(Sm)
  let mdDown = maxWidth(Md)
  let lgDown = maxWidth(Lg)
  let xlDown = maxWidth(Xl)
  let xxlDown = maxWidth(Xxl)

  let xsOnly = maxWidth(Sm)
  let smOnly = between(Sm, Md)
  let mdOnly = between(Md, Lg)
  let lgOnly = between(Lg, Xl)
  let xlOnly = between(Xl, Xxl)
  let xxlOnly = minWidth(Xxl)

  let portrait = "(orientation: portrait)"
  let landscape = "(orientation: landscape)"
  let prefersReducedMotion = "(prefers-reduced-motion: reduce)"
  let prefersDark = "(prefers-color-scheme: dark)"
  let prefersLight = "(prefers-color-scheme: light)"
  let highContrast = "(prefers-contrast: more)"
  let touchDevice = "(hover: none) and (pointer: coarse)"
  let finePointer = "(hover: hover) and (pointer: fine)"
  let retina = "(-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi)"
}

// ============================================================================
// matchMedia binding
// ============================================================================

type mediaQueryList

@val external matchMedia: string => mediaQueryList = "window.matchMedia"
@get external matches: mediaQueryList => bool = "matches"
@send external addListener: (mediaQueryList, mediaQueryList => unit) => unit = "addEventListener"
@send external removeListener: (mediaQueryList, mediaQueryList => unit) => unit = "removeEventListener"

let addChangeListener: (mediaQueryList, mediaQueryList => unit) => unit = %raw(`
  function(mql, cb) { mql.addEventListener("change", cb) }
`)

let removeChangeListener: (mediaQueryList, mediaQueryList => unit) => unit = %raw(`
  function(mql, cb) { mql.removeEventListener("change", cb) }
`)

// ============================================================================
// Media query matching utilities
// ============================================================================

let matchesQuery = (query: string): bool => {
  matches(matchMedia(query))
}

let matchesBreakpointUp = (bp: breakpoint): bool => matchesQuery(minWidth(bp))
let matchesBreakpointDown = (bp: breakpoint): bool => matchesQuery(maxWidth(bp))

// ============================================================================
// Signal-based media query tracking
// ============================================================================

let makeMediaSignal = (query: string): Signal.t<bool> => {
  let mql = matchMedia(query)
  let signal = Signal.make(matches(mql))
  let handler = (evt: mediaQueryList) => {
    Signal.set(signal, matches(evt))
  }
  addChangeListener(mql, handler)
  signal
}

let makeBreakpointSignal = (bp: breakpoint): Signal.t<bool> => {
  makeMediaSignal(minWidth(bp))
}

// ============================================================================
// Predefined screen size signals (memoized singletons)
// ============================================================================

// Helper: create a memoized signal that initializes on first access
let _memo = (make: unit => Signal.t<bool>): (unit => Signal.t<bool>) => {
  let cached: ref<option<Signal.t<bool>>> = ref(None)
  () => {
    switch cached.contents {
    | Some(s) => s
    | None => {
        let s = make()
        cached := Some(s)
        s
      }
    }
  }
}

// Exact breakpoint range signals
let isXsScreen = _memo(() => makeMediaSignal(Query.xsDown))
let isSmScreen = _memo(() => makeMediaSignal(Query.smOnly))
let isMdScreen = _memo(() => makeMediaSignal(Query.mdOnly))
let isLgScreen = _memo(() => makeMediaSignal(Query.lgOnly))
let isXlScreen = _memo(() => makeMediaSignal(Query.xlOnly))
let isXxlScreen = _memo(() => makeMediaSignal(Query.xxlOnly))

// "And up" signals
let isSmallAndUp = _memo(() => makeMediaSignal(Query.smUp))
let isMediumAndUp = _memo(() => makeMediaSignal(Query.mdUp))
let isLargeAndUp = _memo(() => makeMediaSignal(Query.lgUp))
let isExtraLargeAndUp = _memo(() => makeMediaSignal(Query.xlUp))

// Semantic device signals
let isMobile = _memo(() => makeMediaSignal(Query.smDown))
let isTablet = _memo(() => makeMediaSignal(Query.mdOnly))
let isDesktop = _memo(() => makeMediaSignal(Query.lgUp))

// Preference / capability signals
let isPortrait = _memo(() => makeMediaSignal(Query.portrait))
let isLandscape = _memo(() => makeMediaSignal(Query.landscape))
let prefersReducedMotion = _memo(() => makeMediaSignal(Query.prefersReducedMotion))
let prefersDarkMode = _memo(() => makeMediaSignal(Query.prefersDark))
let isTouchDevice = _memo(() => makeMediaSignal(Query.touchDevice))
let isRetina = _memo(() => makeMediaSignal(Query.retina))

// ============================================================================
// Current breakpoint tracking
// ============================================================================

type currentBreakpoint = ExtraSmall | Small | Medium | Large | ExtraLarge | ExtraExtraLarge

let currentBreakpointToString = (bp: currentBreakpoint): string => {
  switch bp {
  | ExtraSmall => "xs"
  | Small => "sm"
  | Medium => "md"
  | Large => "lg"
  | ExtraLarge => "xl"
  | ExtraExtraLarge => "xxl"
  }
}

let getCurrentBreakpoint = (): currentBreakpoint => {
  if matchesQuery(Query.xxlUp) {
    ExtraExtraLarge
  } else if matchesQuery(Query.xlUp) {
    ExtraLarge
  } else if matchesQuery(Query.lgUp) {
    Large
  } else if matchesQuery(Query.mdUp) {
    Medium
  } else if matchesQuery(Query.smUp) {
    Small
  } else {
    ExtraSmall
  }
}

let makeCurrentBreakpointSignal = (): Signal.t<currentBreakpoint> => {
  let signal = Signal.make(getCurrentBreakpoint())

  let breakpoints = [Sm, Md, Lg, Xl, Xxl]
  breakpoints->Array.forEach(bp => {
    let mql = matchMedia(minWidth(bp))
    let _handler = (_evt: mediaQueryList) => {
      Signal.set(signal, getCurrentBreakpoint())
    }
    addChangeListener(mql, _handler)
  })

  signal
}

let currentBreakpoint: ref<option<Signal.t<currentBreakpoint>>> = ref(None)

let getCurrentBreakpointSignal = (): Signal.t<currentBreakpoint> => {
  switch currentBreakpoint.contents {
  | Some(s) => s
  | None => {
      let s = makeCurrentBreakpointSignal()
      currentBreakpoint := Some(s)
      s
    }
  }
}

// ============================================================================
// Responsive value helpers
// ============================================================================

type responsiveValue<'a> = {
  xs?: 'a,
  sm?: 'a,
  md?: 'a,
  lg?: 'a,
  xl?: 'a,
  xxl?: 'a,
}

let resolveResponsiveValue = (value: responsiveValue<'a>, fallback: 'a): 'a => {
  let bp = getCurrentBreakpoint()
  // Build ordered list from current breakpoint down, cascade to find first defined value
  let ordered = switch bp {
  | ExtraExtraLarge => [value.xxl, value.xl, value.lg, value.md, value.sm, value.xs]
  | ExtraLarge => [value.xl, value.lg, value.md, value.sm, value.xs]
  | Large => [value.lg, value.md, value.sm, value.xs]
  | Medium => [value.md, value.sm, value.xs]
  | Small => [value.sm, value.xs]
  | ExtraSmall => [value.xs]
  }
  let rec find = (items: array<option<'a>>, idx: int): 'a => {
    if idx >= Array.length(items) {
      fallback
    } else {
      switch items->Array.getUnsafe(idx) {
      | Some(v) => v
      | None => find(items, idx + 1)
      }
    }
  }
  find(ordered, 0)
}

// ============================================================================
// Visibility helpers (CSS class-based)
// ============================================================================

module Visibility = {
  let hiddenBelow = (bp: breakpoint): string =>
    `basefn-hidden-below-${breakpointToString(bp)}`

  let hiddenAbove = (bp: breakpoint): string =>
    `basefn-hidden-above-${breakpointToString(bp)}`

  let visibleOnly = (bp: breakpoint): string =>
    `basefn-visible-${breakpointToString(bp)}-only`
}
