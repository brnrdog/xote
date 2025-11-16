module Signal = Xote.Signal
module Component = Xote.Component

// Counter state
let count = Signal.make(0)

// Event handlers
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
let reset = (_evt: Dom.event) => Signal.set(count, 0)

let counterApp = () => {
  <div class="max-w-2xl mx-auto p-4 md:p-6 space-y-4">
    // Header
    <div class="mb-6 md:mb-8">
      <h1 class="text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2">
        {Component.text("Counter Demo")}
      </h1>
      <p class="text-sm md:text-base text-stone-600 dark:text-stone-400">
        {Component.text("A simple reactive counter built with Xote")}
      </p>
    </div>

    // Counter display
    <div class="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-8 md:p-12 text-center">
      <div class="text-5xl md:text-6xl font-bold text-stone-900 dark:text-white mb-2">
        {Component.textSignal(() => Signal.get(count)->Int.toString)}
      </div>
      <div class="text-xs md:text-sm text-stone-500 dark:text-stone-400">
        {Component.text("Current Count")}
      </div>
    </div>

    // Button controls
    <div class="flex flex-col sm:flex-row gap-3 justify-center">
      <button
        class="px-6 py-3 md:px-8 bg-stone-900 hover:bg-stone-700 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2 dark:bg-stone-700 dark:hover:bg-stone-600"
        onClick={decrement}>
        {Component.text("− Decrement")}
      </button>
      <button
        class="px-6 py-3 md:px-8 bg-stone-200 hover:bg-stone-300 text-stone-900 rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-300 focus:ring-offset-2 dark:bg-stone-800 dark:hover:bg-stone-700 dark:text-white"
        onClick={reset}>
        {Component.text("Reset")}
      </button>
      <button
        class="px-6 py-3 md:px-8 bg-stone-900 hover:bg-stone-700 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2 dark:bg-stone-700 dark:hover:bg-stone-600"
        onClick={increment}>
        {Component.text("+ Increment")}
      </button>
    </div>
  </div>
}
