# React 19 client Actions backport

This backport mirrors the client Actions behavior shipped by React `v19.2.0` at
commit [`ae74234eae6ebd62f19190731278e20bc1c37d51`](https://github.com/facebook/react/tree/ae74234eae6ebd62f19190731278e20bc1c37d51).
It stacks on the React 18 transition lanes in Roblox/react-luau#25.

The behavior originates in these upstream commits and their follow-up fixes:

- [`cd2b79dedd6`](https://github.com/facebook/react/commit/cd2b79dedd6) for the initial client Actions runtime;
- [`6eadbe0c4ae`](https://github.com/facebook/react/commit/6eadbe0c4ae) for independent entangled Action failures;
- [`491aec5d611`](https://github.com/facebook/react/commit/491aec5d611), [`9a01c8b54e9`](https://github.com/facebook/react/commit/9a01c8b54e9), [`85c2b519b54`](https://github.com/facebook/react/commit/85c2b519b54), [`88d56b8e818`](https://github.com/facebook/react/commit/88d56b8e818), and [`60a927d04ad`](https://github.com/facebook/react/commit/60a927d04ad) for optimistic state and its corrections;
- [`456d153bb58`](https://github.com/facebook/react/commit/456d153bb58), [`77c4ac2ce88`](https://github.com/facebook/react/commit/77c4ac2ce88), [`163122766b6`](https://github.com/facebook/react/commit/163122766b6), [`67b05be0d21`](https://github.com/facebook/react/commit/67b05be0d21), and [`9598c41a201`](https://github.com/facebook/react/commit/9598c41a201) for the Action-state queue and corrections;
- [`11c9fd0c531`](https://github.com/facebook/react/commit/11c9fd0c531), [`85b296e9b6d`](https://github.com/facebook/react/commit/85b296e9b6d), and [`ee5c1949308`](https://github.com/facebook/react/commit/ee5c1949308) for unmounted owners and public async `startTransition` batching.

The scope is client Fiber scheduling: async `startTransition` and
`useTransition`, entangled Action scopes, optimistic updates and revert lanes,
and serialized `useActionState` queues. DOM form actions, `useFormStatus`,
Server Actions, Flight, Fizz, hydration, cache APIs, transition tracing, and
View Transitions remain out of scope.

## Source ledger

| Upstream source or symbol | React-Luau target | Status | Deviation |
| --- | --- | --- | --- |
| `ReactFiberAsyncAction.js` Action entanglement and chained thenables | `modules/react-reconciler/src/ReactFiberAsyncAction.lua` | Adapted | Luau wakeables use `andThen`. Profiler, default indicator, transition types, and shared global reporting belong to excluded features. |
| `ReactFiberRootScheduler.js::requestTransitionLane` | `ReactFiberAsyncAction.lua::requestTransitionLane` | Adapted | React 17 has no root scheduler. The Actions module owns the event-scoped transition-lane cache and Work Loop resets it at the existing event boundary. |
| `ReactFiberHooks.js::updateReducerImpl` revert-lane processing | `ReactFiberHooks.new.lua::updateReducerImpl` | Direct | The React 17 update shape keeps eager reducer fields and gains `revertLane`. |
| `ReactFiberHooks.js` optimistic hook mount/update/rerender | `ReactFiberHooks.new.lua` | Direct | Luau returns tuple members as multiple values. |
| `ReactFiberHooks.js::dispatchOptimisticSetState` | `ReactFiberHooks.new.lua` | Adapted | The shared action-local lane allocator replaces the modern root scheduler. |
| `ReactFiberHooks.js` Action-state queue | `ReactFiberHooks.new.lua` | Adapted | Action nodes expose `andThen`; generic `useThenable`, `SuspenseException`, and `SuspenseActionException` remain owned by Roblox/react-luau#32. `readActionThenable` is private to Actions, and React 17 traverses the queue hook before it can suspend because it has no suspended-component replay dispatcher. |
| `ReactFiberThenable.js` generic thenable state and suspension sentinel | No target in this branch | Excluded | Roblox/react-luau#32 owns the public `use` substrate. The Action runtime and Debug Tools use private, action-local adapters until consolidation. |
| `ReactFiberThrow.js` concurrent suspension without a boundary | `ReactFiberThrow.new.lua`, `ReactFiberUnwindWork.new.lua`, and `ReactFiberWorkLoop.new.lua` | Adapted | React 19's root suspension path restores the interrupted component, unwinds without an error-capture pass, and keeps the current UI while an Action transition is pending. The generic `use` substrate remains owned by Roblox/react-luau#32. |
| `ReactFiberHooks.js` hook `startTransition` | `ReactFiberHooks.new.lua` | Direct | React 17 keeps its update queue and scheduler entry points. |
| `ReactFiberClassUpdateQueue.js` entangled Action suspension | `ReactUpdateQueue.new.lua` | Direct | Module and update-field names follow React 17. |
| `ReactFiberBeginWork.js` HostRoot Action suspension | `ReactFiberBeginWork.new.lua` | Direct | The check follows the existing root queue call. |
| `ReactFiberClassComponent.js` class Action suspension | `ReactFiberClassComponent.new.lua` | Direct | All four React 17 queue-processing sites are covered. |
| `ReactFiberWorkLoop.js::requestUpdateLane` | `ReactFiberWorkLoop.new.lua` | Adapted | Transition lanes are requested from the action-local event cache because React 17 has no `ReactFiberRootScheduler`. |
| `ReactFiberTransition.js` renderer transition-finish registration | `ReactFiberTransition.lua` | Adapted | React-Luau has one client renderer registration point and preserves any previous callback. |
| `ReactStartTransition.js` async completion and failure reporting | `modules/react/src/ReactStartTransition.lua` | Adapted | The action-local adapter calls a host `_G.reportError` when supplied and otherwise defers the error. Shared `reportGlobalError` remains owned by Roblox/react-luau#31 and must replace it during consolidation. |
| `ReactHooks.js` public hooks | `modules/react/src/ReactHooks.lua` | Adapted | Luau tuples are multiple return values. Luau has no `Awaited` utility, so the Action callback returns `S | Thenable<S>` while state remains `S`. |
| React client exports | `modules/react/src/React.lua` | Direct | React-Luau exports from its existing public module. |
| Dispatcher and transition types | `modules/shared/src/ReactSharedInternals`, `ReactCurrentDispatcher.lua`, and `ReactTypes.lua` | Adapted | React 17 shared-internals names are retained. |
| `ReactInternalTypes.js` HookType Action names | `modules/react-reconciler/src/ReactInternalTypes.lua` | Direct | React 17 retains its existing HookType union. |
| `ReactDebugHooks.js` | `modules/react-debug-tools/src/ReactDebugHooks.lua` | Adapted | Inspection reads fulfilled values, rethrows rejected reasons, and stops at pending Action state with a private sentinel. Roblox/react-luau#32 owns the generic sentinel that must replace it. |
| `ReactHooksInspectionIntegration-test.js` | `modules/react-debug-tools/src/__tests__/ReactHooksInspectionIntegration.spec.lua` | Adapted | React-Luau hook IDs are one-based; trailing memo hooks verify all three Action-state hook slots are consumed. |
| `ReactHooks-test.internal.js` hook-order coverage | `modules/react-reconciler/src/__tests__/ReactHooks-internal.spec.lua` | Adapted | Existing Jest-Lua hook-order helpers cover `useOptimistic` and `useActionState`. |
| `ReactStartTransition.js` error reporting contract | `modules/react/src/__tests__/ReactStartTransition.spec.lua` | Adapted | Global callback errors use the scoped host reporter; hook transition errors continue through the render error path. |
| Shallow renderer dispatcher | `modules/react-shallow-renderer/src/init.lua` | Adapted | Shallow rendering exposes stable no-op Action dispatchers. |

## Async Actions test ledger

All 25 renderer-independent cases in
[`ReactAsyncActions-test.js`](https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/ReactAsyncActions-test.js)
map to `modules/react-reconciler/src/__tests__/ReactAsyncActions.spec.lua` in
upstream order.

| # | Upstream test | Status | Translation |
| ---: | --- | --- | --- |
| 1 | `isPending remains true until async action finishes` | Direct | Controlled `andThen` wakeable replaces a JavaScript Promise. |
| 2 | `multiple updates in an async action scope are entangled together` | Direct | ReactNoop host elements use `React.createElement`. |
| 3 | `multiple async action updates in the same scope are entangled together` | Adapted | The React 17 Suspense implementation retries siblings sequentially and has no React 19 sibling prewarming. The controlled cache invokes handlers synchronously for already fulfilled A0/B0/C0 resources; staged A1/B1/C1 suspension and final atomic commit remain covered. |
| 4 | `urgent updates are not blocked during an async action` | Direct | Separate A and B components preserve the bailout/log contract. |
| 5 | `if a sync action throws, it's rethrown from the useTransition` | Direct | LuauPolyfill `Error` and a React-Luau class boundary replace JavaScript syntax. |
| 6 | `if an async action throws, it's rethrown from the useTransition` | Direct | Rejected controlled wakeable replaces the async function. |
| 7 | `if there are multiple entangled actions, and one of them errors, it only affects that action` | Direct | Nested wakeable chains replace nested async functions. |
| 8 | `useOptimistic can be used to implement a pending state` | Direct | ReactNoop controlled text resource replaces the JavaScript cache, including synchronous reads of the already fulfilled initial A resource. |
| 9 | `useOptimistic rebases pending updates on top of passthrough value` | Adapted | Cart output is flattened while preserving transition, rebase, and authoritative-size assertions. |
| 10 | `regression: when there are no pending transitions, useOptimistic should always return the passthrough value` | Direct | String output replaces JSX host nodes. |
| 11 | `regression: useOptimistic during setState-in-render` | Direct | Numeric `Text` values follow ReactNoop conventions. |
| 12 | `useOptimistic accepts a custom reducer` | Adapted | Cart output is flattened; every reducer invocation and rebase remains asserted. |
| 13 | `useOptimistic rebases if the passthrough is updated during a render phase update` | Direct | Controlled wakeable replaces the async gap. |
| 14 | `useOptimistic rebases if the passthrough is updated during a render phase update (initial mount)` | Direct | No behavior change. |
| 15 | `useOptimistic can update repeatedly in the same async action` | Adapted | Loading and canonical host nodes are flattened into one ReactNoop text output. |
| 16 | `useOptimistic warns if outside of a transition` | Direct | Jest-Lua `toErrorDev` captures the exact warning. |
| 17 | `optimistic state is not reverted until async action finishes, even if useTransition hook is unmounted` | Adapted | Sibling host nodes are flattened; hook ownership and commit sequence are unchanged. |
| 18 | `updates in an async action are entangled even if useTransition hook is unmounted before it finishes` | Adapted | ReactNoop text output replaces span nodes. |
| 19 | `updates in an async action are entangled even if useTransition hook is unmounted before it finishes (class component)` | Adapted | React-Luau class construction replaces JavaScript class syntax. |
| 20 | `updates in an async action are entangled even if useTransition hook is unmounted before it finishes (root update)` | Adapted | ReactNoop text output replaces span nodes. |
| 21 | `React.startTransition supports async actions` | Direct | A chained wakeable replaces `await`. |
| 22 | `useOptimistic works with async actions passed to React.startTransition` | Direct | A chained wakeable replaces `await`. |
| 23 | `regression: updates in an action passed to React.startTransition are batched even if there were no updates before the first await` | Direct | Two returned wakeable chains preserve the outer pending lifetime. |
| 24 | `React.startTransition captures async errors and passes them to reportError` | Adapted | The suite starts with a pending Action, verifies no early report, then rejects it through the action-local host `_G.reportError` callback without introducing the shared reporter owned by #31. |
| 25 | `React.startTransition captures sync errors and passes them to reportError` | Adapted | Same temporary host callback as test 24. |

## Action-state test ledger

The 13 renderer-independent `useActionState` cases from
[`ReactDOMForm-test.js`](https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-dom/src/__tests__/ReactDOMForm-test.js#L980-L1510)
map to `modules/react-reconciler/src/__tests__/ReactActionState.spec.lua` in
upstream order. ReactNoop replaces the DOM root; these cases dispatch the public
hook callback directly upstream and do not depend on HTML form behavior.

| # | Upstream test | Status |
| ---: | --- | --- |
| 1 | `useActionState updates state asynchronously and queues multiple actions` | Direct |
| 2 | `useActionState supports inline actions` | Direct |
| 3 | `useActionState: dispatch throws if called during render` | Direct |
| 4 | `useActionState: queues multiple actions and runs them in order` | Direct |
| 5 | `useActionState: when calling a queued action, uses the implementation that was current at the time it was dispatched, not the most recent one` | Direct |
| 6 | `useActionState: works if action is sync` | Direct |
| 7 | `useActionState: can mix sync and async actions` | Direct |
| 8 | `useActionState: error handling (sync action)` | Adapted class syntax |
| 9 | `useActionState: error handling (async action)` | Adapted wakeable and class syntax |
| 10 | `useActionState: when an action errors, subsequent actions are canceled` | Adapted wakeable and class syntax |
| 11 | `useActionState works in StrictMode` | Direct |
| 12 | `useActionState does not wrap action in a transition unless dispatch is in a transition` | Adapted ReactNoop Suspense resource; React 17 has no sibling prewarming, so assertions follow its single-pass retry order. |
| 13 | `useActionState warns if async action is dispatched outside of a transition` | Adapted ReactNoop Suspense resource and Jest-Lua `toErrorDev`; a pending controlled thenable preserves the upstream async lifetime and is resolved in a later `act`. |

## Supporting public regression suites

`modules/react/src/__tests__/ReactStartTransition.spec.lua` retains the
transition update-count warning coverage from React 18 and separates the React
19 error contracts: global `React.startTransition` reports through a scoped host
`_G.reportError`, while `useTransition` callback errors continue through the
renderer error path. Debug Tools hook-slot traversal and reconciler hook-order
coverage are listed in the source ledger above.

## Mandatory consolidation

This branch deliberately avoids the generic surfaces owned by the parallel
backports:

- If Roblox/react-luau#32 lands first, rebase and replace
  `readActionThenable` with its generic `useThenable` path and replace Debug
  Tools' private `SuspenseException` with the shared thenable inspection path,
  retaining only Action-specific suspension mapping. Consolidate the temporary
  React 19 concurrent-root suspension path with that branch's Work Loop and
  `ReactFiberThrow` integration.
- If Roblox/react-luau#31 lands first, rebase and replace
  `ReactStartTransition.lua`'s local deferred-error fallback with Shared
  `reportGlobalError`.

The final merged runtime must not retain duplicate thenable or global-error
substrates.
