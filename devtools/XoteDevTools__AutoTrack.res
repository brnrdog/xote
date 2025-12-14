// Automatic signal tracking by patching global functions
// This allows tracking all signals without explicit wrapping

// Import Xote modules (not rescript-signals directly)
// We patch Xote's re-exported modules which are mutable objects
@module("../src/Xote.res.mjs")
external xoteSignal: 'a = "Signal"

@module("../src/Xote.res.mjs")
external xoteComputed: 'a = "Computed"

@module("../src/Xote.res.mjs")
external xoteEffect: 'a = "Effect"

// Counter for auto-generating labels
let signalCounter = ref(0)
let computedCounter = ref(0)
let effectCounter = ref(0)

// Import Xote Component registration functions for owner tracking
@module("../src/Xote__Component.res.mjs")
external xoteRegisterSignal: Signals.Signal.t<'a> => unit = "registerSignal"

@module("../src/Xote__Component.res.mjs")
external xoteRegisterComputed: Signals.Signal.t<'a> => unit = "registerComputed"

@module("../src/Xote__Component.res.mjs")
external xoteRegisterEffectDisposer: Signals.Effect.disposer => unit = "registerEffectDisposer"

// Store if already enabled
let isEnabled = ref(false)
let registerEffect = XoteDevTools__Registry.registerEffect
let registerSignal = XoteDevTools__Registry.registerSignal
let registerComputed = XoteDevTools__Registry.registerComputed
let registerDependency = XoteDevTools__Registry.registerDependency
let clearDependencies = XoteDevTools__Registry.clearDependencies
let markAsDisposed = XoteDevTools__Registry.markAsDisposed
let logUpdate = XoteDevTools__Timeline.logUpdate
let incrementVersion = XoteDevTools__Registry.incrementVersion

// Enable automatic tracking by patching global functions
let enable = () => {
  Console.log("=== XoteDevTools: AutoTrack enabled")
  if isEnabled.contents {
    () // Already enabled
  } else {
    isEnabled := true
    %raw(`(function(
      originalSignalMake,
      originalComputedMake,
      originalEffectRun,
      originalSignalGet,
      SignalModule,
      ComputedModule,
      EffectModule,
      registerSignal,
      registerComputed,
      registerEffect,
      registerDependency,
      clearDependencies,
      markAsDisposed,
      logUpdate,
      incrementVersion,
      signalCounter,
      computedCounter,
      effectCounter,
      xoteRegisterSignal,
      xoteRegisterComputed,
      xoteRegisterEffectDisposer
    ) {
      // Stack to track currently executing observer
      let currentObserverStack = [];

      // Helper to stringify values
      const stringifyValue = (val) => {
        if (val === null) return 'null';
        if (val === undefined) return 'undefined';
        if (typeof val === 'string') return val;
        if (typeof val === 'number' || typeof val === 'boolean') return String(val);
        try {
          return JSON.stringify(val, null, 0);
        } catch (e) {
          return '[circular or error]';
        }
      };

      // Patch Signal.get to track dependencies
      SignalModule.get = function(signal) {
        const result = originalSignalGet(signal);

        // If there's a current observer, register the dependency
        if (currentObserverStack.length > 0 && signal.__devtoolsId) {
          const currentObserver = currentObserverStack[currentObserverStack.length - 1];
          registerDependency(currentObserver, signal.__devtoolsId);
        }

        return result;
      };

      // Patch Signal.make (Xote's objects are mutable, so direct assignment works)
      SignalModule.make = function(initialValue, equals, name) {
        const signal = originalSignalMake(initialValue, equals, name);

        // Register with Xote's owner system (for component-scoped disposal)
        xoteRegisterSignal(signal);

        // Extract signal name if it exists, otherwise use auto-generated label
        const signalName = signal.name || ("signal_" + signalCounter.contents);

        const id = registerSignal(
          signalName,
          () => {
            try {
              const val = SignalModule.peek(signal);
              return stringifyValue(val);
            } catch (e) {
              return '[error]';
            }
          }
        );

        // Store devtools ID on signal for dependency tracking
        signal.__devtoolsId = id;

        signalCounter.contents++;

        // Track updates
        originalEffectRun(() => {
          const newValue = stringifyValue(SignalModule.get(signal));
          XoteDevTools__Timeline.logUpdate(id, signalName, undefined, newValue, 0);
          incrementVersion(); // Trigger Registry UI update
          return undefined;
        });

        return signal;
      };

      // Patch Computed.make
      ComputedModule.make = function(computation, name) {
        // Pre-register to get an ID for dependency tracking
        let tempId = "computed_temp_" + Math.random();
        let actualId = null;

        // Wrap computation to track dependencies
        const wrappedComputation = function() {
          const id = actualId || tempId;

          // Clear previous dependencies for this computed
          clearDependencies(id);

          // Push current observer
          currentObserverStack.push(id);

          try {
            return computation();
          } finally {
            // Pop current observer
            currentObserverStack.pop();
          }
        };

        // Create computed with wrapped computation and name
        const computed = originalComputedMake(wrappedComputation, name);

        // Register with Xote's owner system (for component-scoped disposal)
        xoteRegisterComputed(computed);

        // Extract computed name if it exists, otherwise use auto-generated label
        const computedName = computed.name || ("computed_" + computedCounter.contents);
        computedCounter.contents++;

        // Now register properly
        actualId = XoteDevTools__Registry.registerComputed(
          computedName,
          () => {
            try {
              const val = SignalModule.peek(computed);
              return stringifyValue(val);
            } catch (e) {
              return '[error]';
            }
          }
        );

        // Store devtools ID on computed for dependency tracking
        computed.__devtoolsId = actualId;

        // Track updates
        originalEffectRun(() => {
          const newValue = stringifyValue(SignalModule.get(computed));
          XoteDevTools__Timeline.logUpdate(actualId, computedName, undefined, newValue, 0);
          incrementVersion(); // Trigger Registry UI update
          return undefined;
        });

        return computed;
      };

      // Patch Effect.run
      EffectModule.run = function(effect, name) {
        // Generate effect name early
        const effectName = name || ("effect_" + effectCounter.contents);

        // Register effect to get ID
        const id = XoteDevTools__Registry.registerEffect(effectName);
        effectCounter.contents++;

        // Wrap the effect to track dependencies
        const wrappedEffect = () => {
          // Clear previous dependencies for this effect
          clearDependencies(id);

          // Push current observer
          currentObserverStack.push(id);

          try {
            XoteDevTools__Timeline.logUpdate(id, effectName, undefined, 'executed', 0);
            return effect();
          } finally {
            // Pop current observer
            currentObserverStack.pop();
          }
        };

        // Run the wrapped effect with the name
        const disposer = originalEffectRun(wrappedEffect, name);

        // Register disposer with Xote's owner system
        xoteRegisterEffectDisposer(disposer);

        // Wrap the dispose method to track when the effect is disposed
        const originalDispose = disposer.dispose;
        disposer.dispose = function() {
          markAsDisposed(id);
          return originalDispose.call(this);
        };

        return disposer;
      };

      // Expose markAsDisposed globally for Xote's disposal system
      window.__xoteDevToolsMarkAsDisposed = markAsDisposed;

      // Store restore function
      window.__xoteDevToolsRestore = () => {
        SignalModule.make = originalSignalMake;
        SignalModule.get = originalSignalGet;
        ComputedModule.make = originalComputedMake;
        EffectModule.run = originalEffectRun;
        delete window.__xoteDevToolsMarkAsDisposed;
      };
    })(
      xoteSignal.make,
       xoteComputed.make,
       xoteEffect.run,
       xoteSignal.get,
       xoteSignal,
       xoteComputed,
       xoteEffect,
       registerSignal,
       registerComputed,
       registerEffect,
       registerDependency,
       clearDependencies,
       markAsDisposed,
       logUpdate,
       incrementVersion,
       signalCounter,
       computedCounter,
       effectCounter,
       xoteRegisterSignal,
       xoteRegisterComputed,
       xoteRegisterEffectDisposer
       )`)
  }
}

// Disable automatic tracking and restore original functions
let disable = () => {
  if isEnabled.contents {
    isEnabled := false
    %raw(`(function() {
      if (window.__xoteDevToolsRestore) {
        window.__xoteDevToolsRestore();
        delete window.__xoteDevToolsRestore;
      }
    })()`)
  }
}
