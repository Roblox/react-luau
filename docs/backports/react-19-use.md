# React 19 `use` backport ledger

This client backport is pinned to React 19.2.0 at
[`ae74234eae6e`](https://github.com/facebook/react/commit/ae74234eae6ebd62f19190731278e20bc1c37d51).
It adds stable `use(Context)` and `use` for cached Promise-compatible thenables.
It does not import React 19's server, cache, hydration, or uncached-render replay
architecture.

## Semantic history

| Commit | Contract |
| --- | --- |
| [`b6978bc38f67`](https://github.com/facebook/react/commit/b6978bc38f6788c7e73982b9fd2771aabdf36f15) | Initial client `use(promise)`, status instrumentation, rejection, and tests |
| [`bfb65681e7d7`](https://github.com/facebook/react/commit/bfb65681e7d77ba9bd79f7f95ac57930542b57c1) | `use(context)` |
| [`5c43c6f02652`](https://github.com/facebook/react/commit/5c43c6f02652) | Context unwind after suspension or interruption |
| [`d2a0176a13c9`](https://github.com/facebook/react/commit/d2a0176a13c95bd4a48cb355592db1b9105bd5d8) | Opaque suspension exception and swallowed `try/catch` warning |
| [`1a902623a84a`](https://github.com/facebook/react/commit/1a902623a84ab004f9f042162bdcbce20f08b13f) | Synchronously resolving thenables do not suspend |
| [`4a2d86bddbce`](https://github.com/facebook/react/commit/4a2d86bddbcef3e64bc404302cdbd9638af8801b), [`33e3d2878e9e`](https://github.com/facebook/react/commit/33e3d2878e9ec82c65468316ffcc473e5288bb87) | Preserve Hook state while replaying a suspended component |
| [`a8f971b7a669`](https://github.com/facebook/react/commit/a8f971b7a669a9a6321b9f3cea820f68b2e4ac6e), [`adbec0c25aff`](https://github.com/facebook/react/commit/adbec0c25aff07f04b0678679554505ba2813168) | Select the correct dispatcher after replay |
| [`7329ea81c154`](https://github.com/facebook/react/commit/7329ea81c154) | ForwardRef, memo, and legacy-context replay corrections |
| [`18282f881dae`](https://github.com/facebook/react/commit/18282f881dae106ebf6240aa52c8c02fe7c8d6f2) | Updates while suspended are not render-phase updates |
| [`178f4351947a`](https://github.com/facebook/react/commit/178f4351947a842ff0b56700e9115b25ae8f20d0) | Uncached client Promise warning |
| [`7ce765ec321a`](https://github.com/facebook/react/commit/7ce765ec321a6f213019b56b36f9dccb2a8a7d5c) | Stable, unconditional public API |
| [`7a32d718b9ea`](https://github.com/facebook/react/commit/7a32d718b9ea0eb9ea86e9d21d56a5af6c4ce9ed) | Promise inspection in React Debug Tools |

The post-19.2 conditional-order warning in `cbb046ab92b` is not imported.

## Source mapping

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `packages/shared/ReactTypes.js` | `modules/shared/src/ReactTypes.lua`, `init.lua` | Ported | `andThen` replaces `then`; status fields remain optional Luau properties |
| `packages/react/src/ReactHooks.js` | `modules/react/src/ReactHooks.lua` | Ported | None |
| `packages/react/src/ReactClient.js`, public index exports | `modules/react/src/React.lua` | Ported | React-Luau has one public module table |
| `packages/react-reconciler/src/ReactInternalTypes.js` | `ReactCurrentDispatcher.lua` | Ported | React-Luau duplicates the dispatcher type in Shared |
| `packages/shared/ReactSymbols.js` | Existing `ReactSymbols.lua` | Reused | Existing `REACT_CONTEXT_TYPE` identifies Context values |
| `packages/react-reconciler/src/ReactFiberHooks.js` | `ReactFiberHooks.new.lua` | Adapted | `use` allocates no Hook node; all dispatcher variants expose it; one-based thenable positions; full React 19 replay is excluded |
| `packages/react-reconciler/src/ReactFiberThenable.js` | New `ReactFiberThenable.lua` | Adapted | Cached client thenables, `andThen`, one-based positions, no async debug metadata, act accounting, Actions, or commit resources |
| `packages/react-reconciler/src/ReactFiberWorkLoop.js` | `ReactFiberWorkLoop.new.lua` | Adapted | Opaque sentinel is converted before React 17's existing unwind path; there is no `SuspendedOnImmediate` replay state |
| `packages/react-reconciler/src/ReactFiberThrow.js` | Existing `ReactFiberThrow.new.lua` | Reused | Existing `andThen` wakeable capture, ping listener, and retry path needs no change |
| `packages/react-reconciler/src/ReactFiberNewContext.js` | Existing `ReactFiberNewContext.new.lua` | Reused | Existing context dependency and unwind behavior is sufficient |
| `ReactFiber.js`, `ReactInternalTypes.js` DEV thenable state | No target | Excluded | Fiber-retained uncached thenable replay and committed thenable substitution are outside the cached-client boundary |
| `packages/react/src/ReactAct.js` | No target | Excluded | React-Luau's act implementation has no React 19 `didUsePromise` microtask protocol |
| `packages/react-debug-tools/src/ReactDebugHooks.js` | `modules/react-debug-tools/src/ReactDebugHooks.lua` | Adapted | Inspects Context and cached fulfilled/rejected thenables directly; unresolved inspection returns a partial tree |
| React shallow renderer dispatcher | `modules/react-shallow-renderer/src/init.lua` | React-Luau-only adaptation | A pending thenable is rethrown directly because this renderer has no Suspense work loop |

`ReactFiberThenable.useThenable` and suspended-thenable retrieval are generic
reconciler seams. A later Actions backport consumes them and adds only its
action-specific suspension exception and scheduling behavior.

## Test mapping

The primary upstream suite is
[`ReactUse-test.js`](https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/ReactUse-test.js).

| Upstream test | Port status | React-Luau coverage or reason |
| --- | --- | --- |
| `basic use(promise)` | Ported | Multiple cached fulfilled thenables |
| Pending Promise fallback, ping, resolve, and retry behavior | Ported | Custom thenable and real Roblox Promise cases |
| `using a promise that's not cached between attempts` | Excluded | Requires retained thenable state plus immediate component replay; callers must cache outside render |
| `using a rejected promise will throw` | Ported | Pre-rejected and pending-then-rejected paths reach an Error Boundary |
| `use(promise) in multiple components` | Ported | Parent and child read independent cached thenables |
| `use(promise) in multiple sibling components` | Covered by the same substrate | Per-component state resets on every successful render and unwind; sibling-prewarming ordering is excluded |
| `erroring in the same component as an uncached promise does not result in an infinite loop` | Excluded | Uncached render-created Promises are unsupported |
| `basic use(context)` | Ported | Provider and default Context values |
| `interrupting while yielded should reset contexts` | Covered by existing Context unwind | Its upstream fixture depends on React 19 lazy/renderable-node behavior outside this port |
| `warns if use(promise) is wrapped with try/catch block` | Ported | Identity-stable opaque exception and DEV warning |
| `unwraps thenable that fulfills synchronously without suspending` | Ported | Custom synchronous `andThen` fixture |
| `does not suspend indefinitely if an interleaved update was skipped` | Excluded | Depends on React 19 immediate replay and lane behavior |
| `load multiple nested Suspense boundaries` | Covered by existing Suspense tests | React 19 sibling prewarming and log ordering are excluded |
| `use() combined with render phase updates` | Adapted | Cached, already-fulfilled resources prove stale positions are discarded before rerender |
| Uncached ForwardRef, memo, and legacy-context cases | Excluded | Uncached replay architecture is outside scope; public `use` still works inside these component types with cached inputs |
| `updates while component is suspended should not be mistaken for render phase updates` | Excluded | React 19 replay/lane regression |
| Both `does not get stuck in pending state after use suspends` cases | Excluded | React 19 replay and transition scheduling regressions |
| Conditional and looped `use` calls | Ported | `use` never enters Hook type/order tracking and may precede a stateful Hook |
| Unsupported input | Ported in runtime | Throws the upstream unsupported-type error |

The `ReactUse-test.js` cases gated by `enableSuspendingDuringWorkLoop` are
inactive in React 19.2 and remain excluded. They exercise async Client
Components, generators, and async iterables.

| Other upstream suite | Port status | Coverage or reason |
| --- | --- | --- |
| `ReactHooksInspection-test.js`: Promise, Context, unresolved, anonymous loop | Ported/adapted | Direct inspection covers Promise, Context, and unresolved values; reconciler tests cover loop semantics |
| `ReactHooksInspectionIntegration-test.js`: `use(Context)` | Ported | Committed Fiber inspection covers cached Promise, Context, and following stateful Hook IDs |
| Committed `_debugThenableState` substitution | Excluded | No direct React 19.2 test; requires Fiber-retained replay state |
| `ReactIsomorphicAct-test.js` Promise microtask cases | Excluded | React-Luau uses its existing Promise-aware act implementation rather than React 19's `didUsePromise` protocol |
| Shallow renderer fulfilled/rejected/context behavior | Added | React-Luau compatibility coverage; no equivalent upstream renderer path |

## Runtime contract

- A Promise passed to `use` is created and cached outside render.
- A cached Promise must settle normally. Roblox Promise cancellation does not
  notify ordinary `andThen` listeners and is unsupported for this API.
- `use` is not a request launcher, cache, or data-fetching framework.
- Pending reads require a Suspense boundary; rejected reads require an Error
  Boundary.
- `use(Context)` and cached thenable reads may appear in conditions and loops.
- A thenable is unwrapped exactly once.

## Exclusions

- RSC/Flight hooks, serialization, task replay, and server resources
- Fizz/SSR and hydration or selective hydration
- `cache`, `cacheSignal`, `useCacheRefresh`, Cache components, and pooled caches
- Promise or Context values rendered as children
- Async components, generators, and async iterables
- Sibling prewarming and prerender lane behavior
- Actions, `useActionState`, `useOptimistic`, and `SuspenseActionException`
- Commit resources and lazy/resource suspension sentinels unrelated to public
  `use`
- JavaScript async-function detection and React 19 async debug metadata

Full uncached-Promise fidelity would additionally require
`ReactFiberBeginWork.new.lua`, split throw/unwind Hook resets, suspended reason
and replay machinery in `ReactFiberWorkLoop.new.lua`, Fiber dependency cloning,
and DEV `_debugThenableState`. That expansion is intentionally not part of this
backport.
