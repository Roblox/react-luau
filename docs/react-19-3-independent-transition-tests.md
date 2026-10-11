# React 19.3 independent transition test contract

The upstream contract is React commit
[`1d34f91dfde6bba84d08b683aaba164c7194dacb`](https://github.com/facebook/react/commit/1d34f91dfde6bba84d08b683aaba164c7194dacb),
the complete change in [React #35392](https://github.com/facebook/react/pull/35392).
The runtime source ledger lives in the independent transition backport document.

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `ReactTransition-test.js`: `when multiple transitions update different queues, they entangle` | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Adapted | Both flag variants retain every render assertion and resolution step. Nested suites replace upstream gates. The renderer uses synchronous `act`, Scheduler yield matchers, and `React.createElement`. A per-test text cache replaces `unstable_getCacheForType`, which React-Luau does not implement; no cache refresh behavior is exercised. `andThen` replaces JavaScript `then`. React 17 omits the two duplicate initial sibling prewarming suspension logs. |
| `ReactTransition-test.js`: `when multiple transitions update different queues, but suspend the same boundary, they do entangle` | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Pending | Shares the preceding mechanics. |
| `ReactDeferredValue-test.js`: `if a suspended render spawns a deferred task that suspends on a sibling, we can finish the original task if the original sibling loads first` | `modules/react-reconciler/src/__tests__/ReactDeferredValue.spec.lua` | Pending | React 17 has no sibling prewarming. |
| `ReactDeferredValue-test.js`: `if a suspended render spawns a deferred task that suspends on a sibling, we can switch to the deferred task without finishing the original one` | `modules/react-reconciler/src/__tests__/ReactDeferredValue.spec.lua` | Pending | React 17 has no sibling prewarming. |
| `ReactDeferredValue-test.js`: changed initial logs in the no-boundary, synchronous-parent-update, and original-task-loads-first cases | `modules/react-reconciler/src/__tests__/ReactDeferredValue.spec.lua` | Pending | Existing tests retain their public render assertions; React 17 omits duplicate prewarming yields with either flag setting. |
| `ReactTransition-test.js`: existing same-queue function/class and overlapping-queue cases | `modules/react-reconciler/src/__tests__/ReactTransition.spec.lua` | Retained | The fork's existing skipped cache-API tests remain unchanged. |

Comments beside each affected assertion enumerate omitted upstream yields.
These adaptations preserve public rendered outputs and resolution ordering.
