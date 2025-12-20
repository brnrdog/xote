## [4.4.3](https://github.com/brnrdog/xote/compare/v4.4.2...v4.4.3) (2025-12-20)


### Bug Fixes

* **component:** boolean attributes ([60e1155](https://github.com/brnrdog/xote/commit/60e11557f1d2b38560da593f153f4f5ea0267471))

## [4.4.2](https://github.com/brnrdog/xote/compare/v4.4.1...v4.4.2) (2025-12-20)


### Bug Fixes

* **jsx:** reactive support for boolean attributes ([c54ed60](https://github.com/brnrdog/xote/commit/c54ed60f174bd2049f27809f21f354546ba65912))

## [4.4.1](https://github.com/brnrdog/xote/compare/v4.4.0...v4.4.1) (2025-12-20)


### Bug Fixes

* **component:** attribute and property handling ([c49cbc0](https://github.com/brnrdog/xote/commit/c49cbc0d3b486c7a68b59a65671b139ae8b1eac5))

# [4.4.0](https://github.com/brnrdog/xote/compare/v4.3.1...v4.4.0) (2025-12-19)


### Features

* **jsx:** add support to many other common attributes ([d3460d8](https://github.com/brnrdog/xote/commit/d3460d84012964c5dc6a5659f42ada62465a8e18))
* **jsx:** add support to name attributes ([07de33d](https://github.com/brnrdog/xote/commit/07de33d9ac86c955efd1f04bc088217689288f08))

## [4.3.1](https://github.com/brnrdog/xote/compare/v4.3.0...v4.3.1) (2025-12-18)


### Bug Fixes

* expose missing source files for rescript projects ([4d93ebb](https://github.com/brnrdog/xote/commit/4d93ebbe77260381ca7058562626697c42da1aa1))

# [4.3.0](https://github.com/brnrdog/xote/compare/v4.2.0...v4.3.0) (2025-12-15)


### Features

* update rescript-signals from 1.2.0 to 1.3.0 ([f5f5c1b](https://github.com/brnrdog/xote/commit/f5f5c1bfd78dd2fedb89aa0bc6cfe26221b70f20))

# [4.2.0](https://github.com/brnrdog/xote/compare/v4.1.1...v4.2.0) (2025-12-14)


### Features

* **component:** introduce keyedList for list reconciliation ([#24](https://github.com/brnrdog/xote/issues/24)) ([96800de](https://github.com/brnrdog/xote/commit/96800dec3c9bbd32305643c0b36c74b993055650))

## [4.1.1](https://github.com/brnrdog/xote/compare/v4.1.0...v4.1.1) (2025-12-14)


### Bug Fixes

* **components:** fix component disposal ([adbfcce](https://github.com/brnrdog/xote/commit/adbfccefa088d87f0c00a38fd2b20792c911f4a0))

# [4.1.0](https://github.com/brnrdog/xote/compare/v4.0.0...v4.1.0) (2025-12-05)


### Features

* update rescript-signals from v1.0.1 to v1.2.0 ([d1f76d8](https://github.com/brnrdog/xote/commit/d1f76d809d70cb95f5757aa0f4483f6f6768876c))

# [4.0.0](https://github.com/brnrdog/xote/compare/v3.0.0...v4.0.0) (2025-12-02)


### Code Refactoring

* move signals to rescript-signals ([848b3b8](https://github.com/brnrdog/xote/commit/848b3b825e620c72cfb309ca7a170c7d16833043))


### BREAKING CHANGES

* - Xote.Core.t -> Xote.Signal.t
- Core.batch removed from API

# [3.0.0](https://github.com/brnrdog/xote/compare/v2.0.0...v3.0.0) (2025-11-28)


* fix!: add cleanup callback support to effects ([7aade4f](https://github.com/brnrdog/xote/commit/7aade4f3cb95a284169c42fa6771e31d33613b7c))
* refactor!: simplify Computed API with internal tracking ([5d9bc01](https://github.com/brnrdog/xote/commit/5d9bc0130208b8ebdde90f1207ae101695a6b6af))


### Bug Fixes

* add disposal support for computed observers ([f2e8a17](https://github.com/brnrdog/xote/commit/f2e8a177a37d87abc2477805a39e0eb896946664))
* add equality check to Signal.set to prevent unnecessary notifications ([2680a19](https://github.com/brnrdog/xote/commit/2680a195e8adfa9cf2ed3d3c5bb236044bf04027))
* convert recursive scheduler to iterative loop ([0b69c76](https://github.com/brnrdog/xote/commit/0b69c76d40130fb436b9df4feae8e4785deccc88))
* restore global tracking state on exceptions ([a6e5b70](https://github.com/brnrdog/xote/commit/a6e5b7030e59fb7e8323896ba1b02c44668a81f9))
* signal set structural equality check on objects with functions ([803aaba](https://github.com/brnrdog/xote/commit/803aaba12f75b7df660de1f11257b4eb1a3b4aa5))


### Features

* add automatic disposal for computed values ([d2f04db](https://github.com/brnrdog/xote/commit/d2f04dbe630388aa75a369c3785c4aa4ff2050b3))


### BREAKING CHANGES

* Computed.make now returns Core.t<'a> instead of
(Core.t<'a>, unit => unit). Use Computed.dispose(signal) for manual
disposal instead of calling the dispose function from the tuple.

Before:
  let (signal, dispose) = Computed.make(() => ...)
  dispose()

After:
  let signal = Computed.make(() => ...)
  Computed.dispose(signal)

This aligns better with common patterns in other reactive libraries
like Solid and Preact, providing a cleaner and more intuitive API.
* Effect.run now expects functions to return option<unit => unit> instead of unit. All existing effects must be updated to return None or Some(cleanupFn).

# [2.0.0](https://github.com/brnrdog/xote/compare/v1.3.3...v2.0.0) (2025-11-27)


* chore!: upgrade to ReScript v12.0.0 ([b20b9e0](https://github.com/brnrdog/xote/commit/b20b9e032cd62d6d2e1eea83adbe53ab412cea94)), closes [#function](https://github.com/brnrdog/xote/issues/function) [#object](https://github.com/brnrdog/xote/issues/object) [#function](https://github.com/brnrdog/xote/issues/function)


### BREAKING CHANGES

* ReScript v12 introduces API changes that affect the typeof operator and configuration fields. Projects upgrading will need to:
- Update rescript.json to use 'dependencies' and 'compiler-flags' instead of 'bs-dependencies' and 'bsc-flags'

## [1.3.3](https://github.com/brnrdog/xote/compare/v1.3.2...v1.3.3) (2025-11-26)


### Bug Fixes

* implement topological ordering to prevent scheduling glitches ([51f1a8c](https://github.com/brnrdog/xote/commit/51f1a8ca592c8e722e0a05d37017604e40547062))

## [1.3.2](https://github.com/brnrdog/xote/compare/v1.3.1...v1.3.2) (2025-11-24)


### Bug Fixes

* automatic disposal of reactive observers to prevent memory leaks ([befae81](https://github.com/brnrdog/xote/commit/befae8116f47347179f8d5bdfe6355b40942c79a)), closes [#7](https://github.com/brnrdog/xote/issues/7)
* preserve signal fragment effect when disposing children ([c3d530c](https://github.com/brnrdog/xote/commit/c3d530ccc344d58cc73aa209bbe02f0b87e7cd9a))

## [1.3.1](https://github.com/brnrdog/xote/compare/v1.3.0...v1.3.1) (2025-11-21)


### Bug Fixes

* preserve observer tracking context during nested execution ([afb9450](https://github.com/brnrdog/xote/commit/afb945059ca026072f777859e781fd086e88189b))

# [1.3.0](https://github.com/brnrdog/xote/compare/v1.2.1...v1.3.0) (2025-11-21)


### Features

* add support to data attributes in Xote.JSX ([903c265](https://github.com/brnrdog/xote/commit/903c265352d5344118dd8a66d65b2ec20ab57042))

## [1.2.1](https://github.com/brnrdog/xote/compare/v1.2.0...v1.2.1) (2025-11-19)


### Bug Fixes

* enable reactivity for JSX element attributes ([0ea7235](https://github.com/brnrdog/xote/commit/0ea72353a6a6d26b38e1f7c1058d95f843d3e898))

# [1.2.0](https://github.com/brnrdog/xote/compare/v1.1.0...v1.2.0) (2025-11-19)


### Features

* bump version to 1.2.0 ([19425d9](https://github.com/brnrdog/xote/commit/19425d976e540381ac85736b46b8a994c57f4fa8))

# [1.1.0](https://github.com/brnrdog/xote/compare/v1.0.1...v1.1.0) (2025-11-18)


### Bug Fixes

* revert keyed list reconciliation ([60aa2a0](https://github.com/brnrdog/xote/commit/60aa2a093fdae4d26558c4d4aec4e2e9f9384964))


### Features

* add JSX support with generic transform ([d71175d](https://github.com/brnrdog/xote/commit/d71175dc0a2680996b7725ba3c781cdd8c706b49))
* change className to class in JSX props ([2515242](https://github.com/brnrdog/xote/commit/251524249328cf06f78dfdfbcf348f1552e88e9f))
* implement keyed list reconciliation for efficient updates ([dd9c0b8](https://github.com/brnrdog/xote/commit/dd9c0b8c5d5473b1bdfc0aa8acc1dec8cec21999))
* standardize JSX component naming convention ([f683316](https://github.com/brnrdog/xote/commit/f68331613466a94004d34299b21b26c43bf43c0b))

## [1.0.1](https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1) (2025-11-02)


### Bug Fixes

* optimize build configuration and reduce bundle size ([f9e50dc](https://github.com/brnrdog/xote/commit/f9e50dc9ac713135de5cba589e49c4ff03fbaeb0))

# 1.0.0 (2025-11-02)


### Bug Fixes

* adjust build configuration and dist output ([5dcca3b](https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd))
* improve signal reactivity and add todo styling ([495f0bb](https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569))
* rescript build in release workflow ([9b2fb19](https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca))
* version bump ([2794ae6](https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a))
* version bump for release ([72fb74f](https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1))


### Features

* add Component system with automatic reactivity ([38815ed](https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac))
* add demo ([cf3faf3](https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a))
* bump version ([5ac8b19](https://github.com/brnrdog/xote/commit/5ac8b19a954d3fa10ce0f0d866f86fb74e3ad456))
* **component:** set reactivity to component element attributes ([57217e3](https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1))
* **component:** simplify textSignal to accept function directly ([9a9d551](https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3))
* **component:** unify attrs and signalAttrs into single attrs parameter ([d8942d9](https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc))
* minimal signal implementation based on the TC39 proposal ([9b78d0b](https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e))
* **router:** add signal-based routing with pattern matching ([7bab79e](https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5))

# [1.1.0](https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0) (2025-11-02)


### Features

* **component:** set reactivity to component element attributes ([57217e3](https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1))
* **component:** simplify textSignal to accept function directly ([9a9d551](https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3))
* **component:** unify attrs and signalAttrs into single attrs parameter ([d8942d9](https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc))
* **router:** add signal-based routing with pattern matching ([7bab79e](https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5))

# [1.1.0](https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0) (2025-11-01)


### Features

* **component:** set reactivity to component element attributes ([57217e3](https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1))
* **component:** simplify textSignal to accept function directly ([9a9d551](https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3))
* **component:** unify attrs and signalAttrs into single attrs parameter ([d8942d9](https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc))

# [1.1.0](https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0) (2025-10-31)


### Features

* **component:** add support to a tags ([8ea09c1](https://github.com/brnrdog/xote/commit/8ea09c19aaed9383b80d6cd15e61ae75113c6d73))

## [1.0.3](https://github.com/brnrdog/xote/compare/v1.0.2...v1.0.3) (2025-10-31)


### Bug Fixes

* adjust build configuration and dist output ([5dcca3b](https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd))
* rescript build in release workflow ([9b2fb19](https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca))

## [1.0.2](https://github.com/brnrdog/xote/compare/v1.0.1...v1.0.2) (2025-10-30)


### Bug Fixes

* version bump ([2794ae6](https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a))

## [1.0.1](https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1) (2025-10-30)


### Bug Fixes

* version bump for release ([72fb74f](https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1))

# 1.0.0 (2025-10-30)


### Bug Fixes

* improve signal reactivity and add todo styling ([495f0bb](https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569))


### Features

* add Component system with automatic reactivity ([38815ed](https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac))
* add demo ([cf3faf3](https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a))
* minimal signal implementation based on the TC39 proposal ([9b78d0b](https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e))
