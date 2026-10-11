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
| `ReactFiberLane.js:upgradePendingLaneToSync/upgradePendingLanesToSync` (#27505) | `modules/react-reconciler/src/ReactFiberLane.lua` | Adapted | SyncLane is bit zero in this fork; existing zero-based lane maps remain. |
| `ReactFiberWorkLoop.js:prepareFreshStack`, begin/complete/unwind (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua`, `ReactFiberCompleteWork.new.lua` | Adapted | React 17's subtree stack implements the hidden context, retaining hidden base lanes independently of the root task. |
| `ReactFiberWorkLoop.js:markRootSuspended` (#35392) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | React 17 passes spawned lanes through its existing finish helper; entangled closure precedes ping/update exclusions. |
| `ReactFiberWorkLoop.js:flushRoot` (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | The existing React 17 scheduler performs the synchronous task; supported flushes upgrade pending lanes rather than importing the modern root scheduler. |
| `ReactFiberHiddenContext.js` (#27505) | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua:pushRenderLanes/popRenderLanes` | Adapted | React 17 has no standalone hidden-context module. Its existing stack preserves hidden-tree lane inclusion. |
| `ReactFiberHooks.js:mountSyncExternalStore` (#27505) | No standalone target | Out of scope | These foundation branches do not ship native external stores. Anime Rush's independent native-store backport records checks conservatively, and its integration audit retains that policy. |
| `ReactFiberRootScheduler.js` popstate eager sync upgrade (#27505) | No renderer target | Out of scope | DOM scroll-restoration scheduling is unavailable in ReactRoblox; supported `flushRoot` maps the shared upgrade contract. |
| `ReactDOMFiberAsync-test.js` popstate case (#27505) | No renderer target | Out of scope | ReactRoblox has no DOM navigation/scroll-restoration surface. |
| `packages/shared/ReactFeatureFlags.js` (#35392/#37290) | `modules/shared/src/ReactFeatureFlags.lua` | Adapted | One shared Luau flag serves the supported client renderers and defaults on. |
| `ReactFeatureFlags.native-fb.js`, `.native-oss.js`, `.test-renderer.js`, `.test-renderer.native-fb.js`, `.test-renderer.www.js` (#35392/#37290) | `modules/shared/src/ReactFeatureFlags.lua` | Adapted | React-Luau shares one module across its Noop/test/Roblox renderers; no unsupported JS native renderer is introduced. |
| `ReactFeatureFlags.www-dynamic.js`, `.www.js` (#35392) | No renderer target | Out of scope | Facebook dynamic rollout variants do not exist; Jest-Lua exercises both explicit shared flag values. |
| `ReactTransition-test.js` different-queue cases (#35392) | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Adapted | Complete cases and both variants map to the accompanying test ledger. |
| `ReactDeferredValue-test.js` sibling tasks and three changed cases (#35392) | `modules/react-reconciler/src/__tests__/ReactDeferredValue.spec.lua` | Adapted | Complete cases map to the accompanying test ledger; missing sibling prewarming is explicit. |
| Transition same/overlapping queue, interruption and retry cases | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Pending complete port | The foundation contains empty skipped placeholders for these cache-gated cases. The pinned renderer contracts replace them through controlled text resources without importing unsupported cache APIs. |
| Existing `ReactAsyncActions-test.js` and Action-state cases | `modules/react-reconciler/src/__tests__/ReactAsyncActions.spec.lua`, `ReactActionState.spec.lua` | Retained | Controlled `andThen` wakeables and React 17 scheduling translations remain as recorded in `react-19-actions-backport.md`. |
| `ReactFiberAsyncAction.js`, event lane reuse and hook/class queue entanglement | Existing Actions and transition modules | Retained | Concurrent async Actions remain globally entangled. Same-event allocation, optimistic revert lanes, Action-state serialization and per-Action errors remain unchanged. |

Seven rotating update lanes and two rotating deferred lanes retain their numeric
values. Independence applies to synchronous updates on distinct queues; finite
lane reuse and transitive queue entanglement still limit it. Concurrent async
Actions continue to share the pending combined scope.

Complete translated test inventory is in
`react-19-3-independent-transition-tests.md`.
