# React 18 `useInsertionEffect` backport

This backport mirrors the stable React 18 client `useInsertionEffect` contract
that can run in React-Luau, ReactNoop, and React Debug Tools. Upstream source
and tests are the contract. Server and renderer packages that React-Luau does
not ship remain explicit capability exclusions.

## Pin and source history

- Stable upstream tag: `v18.0.0`
- Stable upstream commit: `34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d`
- React-Luau base: `9351444c2db37caa08b38ad5de90f438db9221ea`
- Source repository: `facebook/react`

The public seam is `React.useInsertionEffect` rendered through ReactNoop. React
Debug Tools inspection is a second public seam. The behavior-bearing upstream
chain is pinned to:

- `263cfa6ecb9879ecb629d4e04a8c26422b4c4ff9` — runtime, Debug Tools, and tests
- `02f411578a8e58af8ec28e385f6b0dcb768cdc41` — stable public export
- `34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d` — React 18.0.0 contract snapshot

## Supported contract

- create and cleanup in the mutation phase before layout effects
- component-local cleanup/create interleaving
- all insertion effects complete before any layout-effect create
- snapshot lifecycles complete before insertion effects
- pending passive effects flush before a later insertion effect
- dependency-array semantics shared with the other effect hooks
- deletion cleanup and development diagnostics with upstream hook names
- React Debug Tools inspection as `InsertionEffect`

## Source ledger

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `packages/react/src/ReactHooks.js` — `useInsertionEffect` | `modules/react/src/ReactHooks.lua` | Adapted | Luau arrays and cleanup function types replace Flow. |
| `packages/react/src/React.js` and stable index exports | `modules/react/src/React.lua` | Adapted | React-Luau has one Rojo runtime entry point. |
| `packages/react-reconciler/src/ReactHookEffectTags.js` — `Insertion` | `modules/react-reconciler/src/ReactHookEffectTags.lua` | Direct | Existing internal layout and passive bits shift to their React 18 values. |
| `packages/react-reconciler/src/ReactInternalTypes.js` — hook and dispatcher types | `modules/react-reconciler/src/ReactInternalTypes.lua` and `modules/shared/src/ReactSharedInternals/ReactCurrentDispatcher.lua` | Adapted | The dispatcher type lives in Shared to avoid React-Luau's existing require cycle. |
| `packages/react-reconciler/src/ReactFiberHooks.new.js` — mount/update implementation and dispatchers | `modules/react-reconciler/src/ReactFiberHooks.new.lua` | Adapted | Existing Luau dispatcher tables and effect queue mechanics are retained. |
| `packages/react-reconciler/src/ReactFiberCommitWork.new.js` — insertion create/cleanup and diagnostics | `modules/react-reconciler/src/ReactFiberCommitWork.new.lua` | Adapted | Luau protected calls and warning formatting replace JavaScript calls; order is unchanged. |
| `packages/react-debug-tools/src/ReactDebugHooks.js` — primitive inspection | `modules/react-debug-tools/src/ReactDebugHooks.lua` | Adapted | Luau hook-log tables replace JavaScript objects. Stack parsing accepts Roblox's legacy `LoadedCode` and current `[string "..."]` frame formats; a missing expected ancestor is treated as no shared ancestor. A single Luau `useMemo` result is inspected as its scalar value while multiple returns remain packed. |
| React stable and renderer-specific index variants | No additional target | Out of scope | The single `React.lua` export covers every React-Luau build. |
| `packages/react-dom` server implementation and tests | No target | Out of scope | React-Luau has no DOM or server renderer. |
| `packages/react-server` and `packages/react-suspense-test-utils` exports | No target | Out of scope | React-Luau ships neither package. |

## Test ledger

The reconciler target suite is
`modules/react-reconciler/src/__tests__/useInsertionEffect.spec.lua`. Tests
retain upstream names and order.

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `ReactHooksWithNoopRenderer-test.js` — `fires insertion effects after snapshots on update` | Same-named Jest-Lua case | Adapted | React-Luau class construction and scheduler matchers only. |
| `fires insertion effects before layout effects` | Same-named Jest-Lua case | Adapted | Scheduler and string construction syntax only. |
| `force flushes passive effects before firing new insertion effects` | Same-named Jest-Lua case | Adapted | React 17's available transition-free scheduling seam exercises the same pending-passive flush. |
| `fires all insertion effects (interleaved) before firing any layout effects` | Same-named Jest-Lua case | Adapted | Luau fragments, arrays, and string construction only. |
| `assumes insertion effect destroy function is either a function or undefined` | Same-named Jest-Lua case | Adapted | Jest-Lua console capture and promises replace their JavaScript equivalents. Luau cannot distinguish an omitted return from an explicit `nil`, so React's `null`-only warning is unrepresentable. Roblox reports the invalid cleanup passed to `xpcall` as an attempted nil call. |
| `ReactHooks-test.internal.js` — invalid dependency-array warning pattern and `ReactFiberHooks.new.js` mount validation | `warns if deps is not an array` | Adapted | Upstream applies `checkDepsAreArrayDev` to `useInsertionEffect` but does not add it to the generic warning test. A focused public-hook regression covers that required dispatcher call. |
| `ReactHooksInspectionIntegration-test.js` — `should inspect the current state of all stateful hooks, including useInsertionEffect` | Same-named case in `ReactHooksInspectionIntegration.spec.lua` | Adapted | Existing React-Luau inspector fixture and Jest-Lua tables are retained. |
| `ReactHooksInspectionIntegration-test.js` — `should inspect custom hooks` | Existing same-named case | Adapted | The upstream hook-tree assertion also locks Roblox's current `[string "..."]` stack-frame parser path. The test module disables Luau optimization because inlining can erase the custom-hook frames this stack-based API inspects. |
| `ReactDOMServerIntegrationHooks-test.js` — server warning | No target | Out of scope | React-Luau has no server renderer. |

## Standalone verification

- The repository-pinned StyLua `0.18.1` formatting check passes.
- Selene `0.28.0` passes with no errors or warnings.
- Luau compiler `0.731` parses and compiles the changed Luau files.
- `bash bin/testing.sh` stops before discovery because `roblox-cli` is not installed. This is a harness prerequisite failure, not a test failure.

## Completion criteria

The backport is complete when every Adapted test passes in an available Roblox
harness, source blocks link to pinned upstream code, standalone formatter and
linter gates pass, unavailable gates have one reproducible prerequisite, and
the React-Luau pull request and working tree are current and clean.
