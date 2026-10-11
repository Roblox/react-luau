# React 19.3 independent synchronous transitions

The runtime contract is React `v19.3.0`, pinned to
`1d34f91dfde6bba84d08b683aaba164c7194dacb`. The scheduling prerequisite is
`309c8ad9688c491e5b17beb07ab01d65594914ce` (#27505), the behavior change is
`6913ea4d28229d066603bff9fc1170334e151a4a` (#35392), and the enabled default is
`eb8feb71096eec5c885b2a4c7d8d030d3622f265` (#37290).

The foundation contains native transitions at
`c6ce5642dc9e1881772a23fb0d01dd3a09162f61`, deferred initial values at
`dcd03505352a3349c939d744fd1294ad616dbd9f`, and client Actions at
`1a818c752727605c70e746afc518f72a8540b5b3`. The sibling features share one
concurrent-root suspension path; deferred HostRoot recovery and the Actions
HostRoot queue check remain additive. Root Action wakeables retain their
nil-parent path. Debug Tools retains one copy of its shared adapters.

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `ReactFiberLane.js:getHighestPriorityLanes` (#35392) | `modules/react-reconciler/src/ReactFiberLane.lua` | Adapted | React 17 priorities and seven existing update bits remain; Luau bit32 selects an individual update lane. |
| `ReactFiberLane.js:getNextLanes/getEntangledLanes` (#27505) | `modules/react-reconciler/src/ReactFiberLane.lua` | Adapted | React 17 retains expiration promotion; component entanglement is separate from scheduled task identity. The obsolete widening and reverse deferred selection are removed. |
| `ReactFiberLane.js:upgradePendingLanesToSync` (#27505, release-pin form) | `modules/react-reconciler/src/ReactFiberLane.lua` | Adapted | SyncLane is bit zero in this fork; existing zero-based lane maps remain. The historical single-lane helper is absent at the release pin, and DOM eager scheduling is excluded. |
| `ReactFiberWorkLoop.js:prepareFreshStack`, begin/complete/unwind (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua`, `ReactFiberCompleteWork.new.lua` | Adapted | React 17's subtree stack implements the hidden context, retaining hidden base lanes independently of the root task. |
| `ReactFiberWorkLoop.js:markRootSuspended` (#35392) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | React 17 passes spawned lanes through its existing finish helper; entangled closure precedes ping/update exclusions. |
| `ReactFiberWorkLoop.js:flushRoot` (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | The existing React 17 scheduler performs the synchronous task; supported flushes upgrade pending lanes rather than importing the modern root scheduler. |
| `ReactFiberHiddenContext.js` (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua:pushRenderLanes/popRenderLanes` | Adapted | React 17 has no standalone hidden-context module. Its existing stack preserves hidden-tree lane inclusion. |
| `ReactFiberHooks.js:isRenderingDeferredWork` (release pin) | `modules/react-reconciler/src/ReactFiberHooks.new.lua`, `ReactFiberLane.lua:UpdateLanes` | Adapted | Reserved deferred bits identify component work; original root task update bits prevent mixed entanglements from suppressing an initial preview. |
| `ReactFiberHooks.js:mountSyncExternalStore` (#27505) | No standalone target | Out of scope | These foundation branches do not ship native external stores. Anime Rush's independent native-store backport records checks conservatively, and its integration audit retains that policy. |
| `ReactFiberRootScheduler.js` popstate eager sync upgrade (#27505) | No renderer target | Out of scope | DOM scroll-restoration scheduling is unavailable in ReactRoblox; supported `flushRoot` maps the shared upgrade contract. |
| `ReactDOMFiberAsync-test.js` popstate case (#27505) | No renderer target | Out of scope | ReactRoblox has no DOM navigation/scroll-restoration surface. |
| `packages/shared/ReactFeatureFlags.js` (#35392/#37290) | `modules/shared/src/ReactFeatureFlags.lua` | Adapted | One shared Luau flag serves the supported client renderers and defaults on. |
| `ReactFeatureFlags.native-fb.js`, `.native-oss.js`, `.test-renderer.js`, `.test-renderer.native-fb.js`, `.test-renderer.www.js` (#35392/#37290) | `modules/shared/src/ReactFeatureFlags.lua` | Adapted | React-Luau shares one module across its Noop/test/Roblox renderers; no unsupported JS native renderer is introduced. |
| `ReactFeatureFlags.www-dynamic.js`, `.www.js` (#35392) | No renderer target | Out of scope | Facebook dynamic rollout variants do not exist; Jest-Lua exercises both explicit shared flag values. |
| `ReactTransition-test.js` different-queue cases (#35392) | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Adapted | Complete cases and both variants map to the accompanying test ledger. |
| `ReactDeferredValue-test.js` sibling tasks and three changed cases (#35392) | `modules/react-reconciler/src/__tests__/ReactDeferredValue.spec.lua` | Adapted | Complete cases map to the accompanying test ledger; missing sibling prewarming is explicit. |
| Transition same/overlapping queue and pending-state cases | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Adapted, verified | Complete hook/class/transitive-queue cases and both flag variants replace the empty foundation placeholders. The hook case adds the observed pending-only urgent render because React 17 discrete updates retain a separate priority from optimistic SyncLane. |
| Transition interruption and retry cases | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Adapted, verified | Complete pinned interruption, parent-bailout, interleaved-update and normal-priority-before-retry cases replace the empty foundation placeholders with both flag variants. Controlled text resources preserve the renderer contract; the refresh terminology does not exercise unsupported cache-refresh APIs. |
| Existing `ReactAsyncActions-test.js` and Action-state cases | `modules/react-reconciler/src/__tests__/ReactAsyncActions.spec.lua`, `ReactActionState.spec.lua` | Retained | Controlled `andThen` wakeables and React 17 scheduling translations remain as recorded in `react-19-actions-backport.md`. |
| `ReactAsyncActions-test.js`: `reconciles against new items when optimisticKey is used` | No target | Out of scope | The React 19.3 pin adds this separate `enableOptimisticKey` contract; optimistic keys are an adjacent feature with their own flag, not part of synchronous task independence. |
| `ReactFiberAsyncAction.js`, event lane reuse and hook/class queue entanglement | Existing Actions and transition modules | Retained | Concurrent async Actions remain globally entangled. Same-event allocation, optimistic revert lanes, Action-state serialization and per-Action errors remain unchanged. |

Seven rotating update lanes and two rotating deferred lanes retain their numeric
values. Independence applies to synchronous updates on distinct queues; finite
lane reuse and transitive queue entanglement still limit it. Concurrent async
Actions continue to share the pending combined scope.

Complete translated test inventory is in
`react-19-3-independent-transition-tests.md`.

Verification uses the standalone module archive at
`8c8757d7a2132738e727ee194e6c1196fbdfd5f1` through the installed Jest Roblox
CLI with the `studio-cli` backend and original tests and matchers. The isolated
archive records 458 source-file SHA256 hashes. Commands and results live in
`.harness/final-verification.txt`; the harness mounts this fork's modules and
uses installed Jest/polyfill dependencies.

| Gate | Result | Evidence |
| --- | --- | --- |
| Transition, DeferredValue, AsyncActions and ActionState suites | 84 passed, no skips; exit 0 | `.harness/final-formatted-four-result.json` |
| Global and hook transition error reporting | 3 passed | `ReactStartTransition.spec.lua` |
| Hook inspection integration, including thenables and composite Actions/deferred hooks | 21 passed, 3 existing skips | `ReactHooksInspectionIntegration.spec.lua` |
| Primitive/custom hook inspection | 8 passed, 3 inherited failures | `ReactHooksInspection.spec.lua`; custom-tree equality at lines 75, 118 and 213 |
| Assembled-foundation hook inspection | Same 8 passed and 3 failures | Immutable `e895ddcda96881075609fec1c0981e17ee29fb06`; `.harness/bookends-foundation-result.json` |
| Changed-file formatting and lint | Passed | Official StyLua 0.18.1 `--check` and Selene 0.28.0 `--config selene.toml` on every changed Lua file; `git diff --check` |

The inherited inspection failures flatten custom-hook tree nodes while retaining
primitive hook values. The foundation reproducer uses the same original tests
and matchers. The relevant Actions/thenable integration cases pass.

The native full-fork `bin/ci.sh` gate requires `rotrieve`, `roblox-cli` and
`robloxdev-cli`, which are absent. The current authorized GitHub account receives
HTTP 404 for `Roblox/rotriever` and `Roblox/safe-flags-internal`; the latter is
required by `rotriever.toml`. Native static analysis and the native complete
DEV/release test runs remain unavailable. These prerequisite failures are
separate from the executed renderer results above.
