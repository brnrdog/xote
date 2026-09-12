let signalTextStart = "<!--$-->"
let signalTextEnd = "<!--/$-->"
let signalTextStartContent = "$"
let signalTextEndContent = "/$"

let signalFragmentStart = "<!--#-->"
let signalFragmentEnd = "<!--/#-->"
let signalFragmentStartContent = "#"
let signalFragmentEndContent = "/#"

let keyedListStart = "<!--kl-->"
let keyedListEnd = "<!--/kl-->"
let keyedListStartContent = "kl"
let keyedListEndContent = "/kl"

let keyedItemPrefixContent = "k:"
let keyedItemStart = (key: string): string => `<!--${keyedItemPrefixContent}${key}-->`
let keyedItemEnd = "<!--/k-->"
let keyedItemEndContent = "/k"

let lazyComponentStart = "<!--lc-->"
let lazyComponentEnd = "<!--/lc-->"
let lazyComponentStartContent = "lc"
let lazyComponentEndContent = "/lc"
