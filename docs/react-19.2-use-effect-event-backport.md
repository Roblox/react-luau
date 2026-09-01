# React 19.2 `useEffectEvent` backport

This backport mirrors the client `React.useEffectEvent` behavior that can run
in React-Luau and ReactNoop. Upstream source and tests are the contract. Server,
DOM, lint-plugin, and hooks that React-Luau does not expose remain explicit
capability exclusions rather than reconstructed substitutes.

## Pin and source history

- Stable upstream tag: `v19.2.0`
- Stable upstream commit: `ae74234eae6ebd62f19190731278e20bc1c37d51`
- Post-release correctness fix: `6bec011b407fe8a2d4babb363289ccce4bc8fcf3`
  from React PR `#34831`
- React-Luau base: `9351444c2db37caa08b38ad5de90f438db9221ea`
- Required API base: React 18 `useInsertionEffect` at
  `34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d`
- Source repository: `facebook/react`

The public seam is `React.useEffectEvent` rendered through ReactNoop. The
behavior-bearing upstream chain is pinned to:

- `c91a1e03be54733a7dbfcb5663d7a9e8606ab1c1` — initial `useEvent` runtime and tests
- `3517bd9f77dc63189f3bafedf83ba1bf8ae359df` — commit-queue implementation
- `3cc792bfb53c63de34bbb1e8ca131c11faca6cba` — non-stable returned identity
- `84a0a171ea0ecd25e287bd3d3dd30e932beb4677` — `useEffectEvent` rename
- `8bb7241f4c773376893701bfe8b8ff03687342a0` — stable client export
- `6bec011b407fe8a2d4babb363289ccce4bc8fcf3` — `memo` and `forwardRef` commit fix

## Supported contract

- a public hook with the callback's arguments and return values
- access to the latest committed props, state, and context
- callback replacement before layout and passive effects
- a fresh wrapper identity on every render
- render-time invocation errors with upstream text
- multiple Effect Events in one component
- use from custom hooks, function components, `memo`, and `forwardRef`
- no receiver preservation when a method is passed as the callback

## Capability boundary

React-Luau does not expose Fizz, server rendering, React DOM, or the upstream
`eslint-plugin-react-hooks` package. Their Effect Event tests and restrictions
are outside this runtime backport. The stacked React 18 backport supplies
`useInsertionEffect`, so the complete applicable client suite remains in scope.

## Source ledger

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `packages/react/src/ReactHooks.js` — `useEffectEvent` | `modules/react/src/ReactHooks.lua` | Adapted | Luau variadic type packs replace Flow argument arrays. |
| `packages/react/src/ReactClient.js` and stable index exports | `modules/react/src/React.lua` | Adapted | React-Luau has one Rojo runtime entry point. |
| `packages/shared/ReactFeatureFlags.js` and renderer forks — `enableUseEffectEventHook` | `modules/shared/src/ReactFeatureFlags.lua` | Adapted | React-Luau has one Shared feature-flag module. |
| `packages/react-reconciler/src/ReactInternalTypes.js` — hook and dispatcher types | `modules/react-reconciler/src/ReactInternalTypes.lua` and `modules/shared/src/ReactSharedInternals/ReactCurrentDispatcher.lua` | Adapted | The dispatcher type lives in Shared to avoid React-Luau's existing require cycle. |
| `packages/react-reconciler/src/ReactFiberHooks.js` — event payload, update queue, mount/update hooks, and dispatchers | `modules/react-reconciler/src/ReactFiberHooks.new.lua` | Adapted | Luau arrays, tables, and variadic calls replace JavaScript objects and `Function.apply`. |
| `packages/react-reconciler/src/ReactFiberFlags.js` — `BeforeMutationMask` | `modules/react-reconciler/src/ReactFiberFlags.lua` | Adapted | The single React-Luau build enables Effect Events, so upstream's feature-flagged `Update` bit is baked into the older numeric mask; flag values remain stable. |
| `packages/react-reconciler/src/ReactFiberWorkLoop.js` — invalid render context and before-mutation dispatch | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | React 17's commit traversal invokes the existing lifecycle helper for `Update` as well as `Snapshot`. |
| `packages/react-reconciler/src/ReactFiberCommitWork.js` — event payload commit and default snapshot guard | `modules/react-reconciler/src/ReactFiberCommitWork.new.lua` | Adapted | PR `#34831` extends the React 19.2 switch arm to `ForwardRef` and `SimpleMemoComponent`; the obsolete React 17 `Block` tag remains a no-op. The widened before-mutation traversal permits non-snapshot `Update` work on other Fiber tags, matching upstream. |
| `packages/react-debug-tools/src/ReactDebugHooks.js` — Effect Event inspection dispatcher | `modules/react-debug-tools/src/ReactDebugHooks.lua` | Adapted | React-Luau's hook log records the callback with its existing compact entry shape. Stack parsing accepts Roblox's legacy `LoadedCode` and current `[string "..."]` frame formats; a missing expected ancestor is treated as no shared ancestor. A single Luau `useMemo` result is inspected as its scalar value while multiple returns remain packed. |
| `scripts/error-codes/codes.json` — production error `440` | No target | Out of scope | React-Luau ships the full error string and has no production error-code transform. |
| React index build variants | No additional target | Out of scope | The single `React.lua` export covers every React-Luau build. |
| Shared renderer-specific feature-flag forks | No additional target | Out of scope | React-Luau ships one Shared package and one client reconciler. |
| `packages/react-server/src/ReactFizzHooks.js` and Fizz tests | No target | Out of scope | React-Luau does not ship Fizz or a server renderer. |
| `packages/eslint-plugin-react-hooks` Effect Event rules and tests | No target | Out of scope | React-Luau does not ship the JavaScript lint plugin; this is a separate tooling contract. |

## Test ledger

The primary target suite is
`modules/react-reconciler/src/__tests__/useEffectEvent.spec.lua`. The
cross-hook visibility regression remains with `useInsertionEffect.spec.lua`.
Tests retain upstream names and order. Port status describes the required
translation.

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `useEffectEvent-test.js` — `memoizes basic case correctly` | Same-named Jest-Lua case | Adapted | React-Luau class construction and scheduler matchers only. |
| `can be defined more than once` | Same-named Jest-Lua case | Adapted | React-Luau class construction and scheduler matchers only. |
| `does not preserve \`this\` in event functions` | Same-named Jest-Lua case | Adapted | An extracted Luau method observes a `nil` receiver instead of JavaScript `undefined`. |
| `throws when called in render` | Same-named Jest-Lua case | Adapted | Synchronous scheduler flush replaces `waitForThrow`; error text is unchanged. React-Luau's React 17 recovery renders the sibling in both the concurrent attempt and synchronous retry. |
| `useLayoutEffect shouldn't re-fire when event handlers change` | Same-named Jest-Lua case | Adapted | Scheduler and element construction syntax only. |
| `useEffect shouldn't re-fire when event handlers change` | Same-named Jest-Lua case | Adapted | Scheduler and element construction syntax only. |
| `is stable in a custom hook` | Same-named Jest-Lua case | Adapted | Lua returns the custom-hook pair as multiple values. |
| `is mutated before all other effects` | Same-named Jest-Lua case | Adapted | The stacked React 18 `useInsertionEffect` backport supplies the upstream ordering seam. |
| `doesn't provide a stable identity` | Same-named Jest-Lua case | Adapted | Scheduler and element construction syntax only. |
| `event handlers always see the latest committed value` | Same-named Jest-Lua case | Adapted | ReactNoop's available `act` and output matcher replace async helpers. |
| `integration: implements docs chat room example` | Same-named Jest-Lua case | Adapted | Jest-Lua fake timers and Luau connection table syntax replace JavaScript timers and objects. |
| `integration: implements the docs logVisit example` | Same-named Jest-Lua case | Adapted | Luau arrays and context tables replace JavaScript arrays and JSX. |
| PR `#34831` — `reads the latest context value in memo Components` | Same-named Jest-Lua case | Adapted | Scheduler and element construction syntax only. |
| PR `#34831` — `reads the latest context value in forwardRef Components` | Same-named Jest-Lua case | Adapted | Scheduler and element construction syntax only. |
| `Activity-test.js` — `insertion effects are not disconnected when the visibility changes` | Same-named case in `useInsertionEffect.spec.lua` | Adapted | React-Luau has no Activity API, so `unstable_LegacyHidden` exercises the same Offscreen visibility `Update`. Unlike Activity, LegacyHidden does not retain hidden host output after its deferred children commit an update. |
| React Debug Tools primitive inspection | Existing all-stateful-hooks integration case | Adapted | The React 18 insertion-effect integration case also checks `EffectEvent` and subsequent hook IDs. |
| React Debug Tools custom-hook stack inspection | Existing `should inspect custom hooks` case | Adapted | The test module disables Luau optimization because inlining can erase the custom-hook frames required by the stack-based inspector. |
| `ReactDOMFizzServer-test.js` Effect Event cases | No target | Out of scope | React-Luau has no server rendering or hydration. |

## Standalone verification

- The repository-pinned StyLua `0.18.1` and Selene `0.28.0` pass for the changed Luau files.
- Full-tree formatting passes. Full-tree linting retains the pre-existing
  `bin/spec.lua` standard-library error.
- Luau compiler `0.731` parses and compiles all 14 changed Luau files.
- The ReactNoop visibility regression fails on the unguarded invariant and passes mount, hide, hidden update, and reveal after the snapshot guard in Roblox Studio.
- `bash bin/testing.sh` stops before discovery because `roblox-cli` is not installed. This is a harness prerequisite failure, not a test failure.

## Completion criteria

The backport is complete when every Adapted test passes in an available Roblox
harness, every source block links to pinned upstream code, all standalone
formatter and linter gates pass, unavailable standalone gates have one
reproducible prerequisite, and the React-Luau pull request and working tree are
current and clean.
