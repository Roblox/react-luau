# React 19 root error callbacks

## Upstream baseline

The client contract is pinned to React `v19.2.0` commit
[`ae74234eae6ebd62f19190731278e20bc1c37d51`](https://github.com/facebook/react/tree/ae74234eae6ebd62f19190731278e20bc1c37d51).
Its relevant history is:

- [`6786563f3cbbc9b16d5a8187207b5bd904386e53`](https://github.com/facebook/react/commit/6786563f3cbbc9b16d5a8187207b5bd904386e53)
  for uncaught root reporting and `reportGlobalError`;
- [`a0537160771bafae90c6fd3154eeead2f2c903e7`](https://github.com/facebook/react/commit/a0537160771bafae90c6fd3154eeead2f2c903e7)
  for configurable caught and uncaught root callbacks;
- [`e10a7b5cd541882a78ff659147c1a0294413ccb0`](https://github.com/facebook/react/commit/e10a7b5cd541882a78ff659147c1a0294413ccb0)
  for suppressing recoverable reports when recovery fails;
- [`6090cab099a8f7f373e04c7eb2937425a8f80f80`](https://github.com/facebook/react/commit/6090cab099a8f7f373e04c7eb2937425a8f80f80)
  for contextual concurrent-recovery errors with the original cause.

## Source and test ledger

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `packages/react-dom/src/client/ReactDOMRoot.js` `CreateRootOptions` and `createRoot` | `modules/react-roblox/src/client/ReactRobloxHostTypes.roblox.lua`, `ReactRobloxRoot.lua` | Adapted | Roblox Instances replace DOM containers. Hydration, identifier prefixes, DOM listeners, transition tracing, and form state are unavailable. |
| `packages/react-native-renderer/src/ReactFabric.js` and `ReactNativeRenderer.js` root options | `modules/react-roblox/src/client/ReactRobloxRoot.lua` | Adapted | ReactRoblox is the only native host renderer in this repository. The common three callbacks are preserved; React Native Error Dialog integration is not applicable. |
| `packages/react-native-renderer/src/ReactNativeTypes.js` root option types | `modules/react-roblox/src/client/ReactRobloxHostTypes.roblox.lua` | Adapted | Luau structural callback types replace Flow types. |
| `packages/react-reconciler/src/ReactInternalTypes.js` `FiberRoot` handlers | `modules/react-reconciler/src/ReactInternalTypes.lua` | Direct | The callback and error-info shapes are preserved. |
| `packages/react-reconciler/src/ReactFiberRoot.js` `FiberRootNode`, `createFiberRoot` | `modules/react-reconciler/src/ReactFiberRoot.new.lua` | Direct | React 17 root construction has fewer unrelated arguments. |
| `packages/react-reconciler/src/ReactFiberReconciler.js` `createContainer` | `modules/react-reconciler/src/ReactFiberReconciler.new.lua` | Adapted | Optional arguments retain compatibility with older internal renderers while every FiberRoot receives concrete default handlers. |
| `packages/react-reconciler/src/ReactFiberErrorLogger.js` defaults, `logUncaughtError`, `logCaughtError` | `modules/react-reconciler/src/ReactFiberErrorLogger.lua` | Adapted | Roblox has no browser `reportError`, console task integration, or React 19 Act queue. Component stacks and class Error Boundary instances are preserved. |
| `packages/shared/reportGlobalError.js` | `modules/shared/src/reportGlobalError.lua`, `init.lua` | Adapted | A deferred thread error is Roblox's global uncaught-reporting boundary. `errorToString` preserves non-string error values for the VM. |
| `packages/react-reconciler/src/ReactFiberThrow.js` root and class error updates | `modules/react-reconciler/src/ReactFiberThrow.new.lua` | Adapted | React 17 update creation keeps its event-time argument. Initialization is split like React 19 so both caught and uncaught callbacks receive their FiberRoot. |
| `packages/react-reconciler/src/ReactFiberWorkLoop.js` retry, commit, and commit-phase capture | `modules/react-reconciler/src/ReactFiberWorkLoop.new.lua` | Adapted | React 17 lanes and recursive commit traversal are retained. First-attempt captured errors become recoverable only after a successful synchronous retry. |
| `packages/react-noop-renderer/src/createReactNoop.js` `createRoot` options | `modules/react-noop-renderer/src/createReactNoop.lua` | Direct | Transition callbacks and default transition indicators are unavailable. |
| `packages/react-reconciler/src/__tests__/ReactConfigurableErrorLogging-test.js` | `modules/react-roblox/src/client/__tests__/ReactRobloxConfigurableErrorLogging.spec.lua` | Adapted | The three renderer-observable cases retain their upstream order and assertions through `ReactRoblox.createRoot`. Roblox Instances replace DOM nodes and Scheduler flushing replaces async fake Act. |
| `ReactConfigurableErrorLogging-test.js` `does not log errors when inside real act` | No local target | Out of scope | React-Luau's React 17 Act implementation has no React 19 `actQueue` or `thrownErrors` aggregation. Adding that test would define a separate Act backport. |
| `packages/react-reconciler/src/__tests__/ReactErrorStacks-test.js` | Configurable logging component-stack assertions | Adapted | The complete suite was reviewed. Its owner-stack assertions, View Transitions, and newer built-in frame formatting are separate React 19.2 features. Public callback tests assert throwing components, host ancestors, and Error Boundary paths. |
| Existing React 17 concurrent retry contract in `ReactIncrementalErrorReplay-test.js` | `ReactRobloxConfigurableErrorLogging.spec.lua` successful recovery case | Adapted | The old silent recovery now asserts one `onRecoverableError` call, contextual message, original `cause`, and component stack. |
| `packages/react-reconciler/src/ReactFiberBeginWork.js` simulated DevTools error initialization | No local target | Out of scope | React-Luau does not implement this DevTools simulated-error branch. |
| `packages/react-reconciler/src/ReactFiberErrorDialog.js` and renderer forks | Existing `ReactFiberErrorDialog.lua` retained but unused by the new pipeline | Adapted | React-Luau has no renderer forks. Retaining the module avoids an unrelated package deletion; root handlers replace its behavior. |
| `packages/react-test-renderer/src/ReactTestRenderer.js` and its internal test | Existing renderer calls into `createContainer` defaults | Adapted | React Test Renderer has no public root option surface here. |
| `packages/react-reconciler/src/__tests__/ReactFiberHostContext-test.internal.js` | Existing host-context tests | Direct through defaults | The changed upstream calls only supply new default constructor arguments. Optional reconciler arguments preserve these callers. |

## Capability exclusions from the source commits

The complete changed-file inventories were reviewed. These groups have no
React-Luau target:

- DOM event and renderer behavior: `packages/react-dom-bindings/src/events/DOMPluginEventSystem.js`,
  `packages/react-dom/index.classic.fb.js`, `packages/react-dom/index.modern.fb.js`,
  `packages/react-dom/src/client/ReactDOMLegacy.js`, `ReactDOMRootFB.js`, and
  `client/__mocks__/ReactFiberErrorDialog.js`.
- DOM, Fizz, and hydration suites: `InvalidEventListeners-test.js`,
  `ReactBrowserEventEmitter-test.js`, `ReactCompositeComponent-test.js`,
  `ReactDOM-test.js`, `ReactDOMConsoleErrorReporting-test.js`,
  `ReactDOMConsoleErrorReportingLegacy-test.js`, `ReactDOMFiber-test.js`,
  `ReactDOMHydrationDiff-test.js`, `ReactDOMLegacyFiber-test.js`,
  `ReactDOMRoot-test.js`, `ReactDOMSelect-test.js`,
  `ReactDOMServerPartialHydration-test.internal.js`,
  `ReactErrorBoundaries-test.internal.js`, `ReactErrorLoggingRecovery-test.js`,
  `ReactLegacyErrorBoundaries-test.internal.js`, `ReactLegacyUpdates-test.js`,
  and `ReactUpdates-test.js` under `packages/react-dom/src/__tests__`.
- React Native event, mount, and Error Dialog behavior:
  `packages/react-native-renderer/src/__tests__/ReactNativeEvents-test.internal.js`,
  `ReactNativeMount-test.internal.js`, and the deleted
  `packages/react-reconciler/src/forks/ReactFiberErrorDialog.native.js` and
  `ReactFiberErrorDialog.www.js`.
- React 19 Act aggregation and JavaScript test infrastructure:
  `packages/internal-test-utils/ReactInternalTestUtils.js`, `internalAct.js`,
  `packages/react/src/ReactAct.js`, `ReactCurrentActQueue.js`,
  `scripts/jest/matchers/toWarnDev.js`, `scripts/jest/setupTests.js`,
  `scripts/jest/shouldIgnoreConsoleError.js`, and the three
  `scripts/rollup/validate/eslintrc.*.js` files.
- Async `startTransition` error handling belongs to the Actions backport:
  `packages/react/src/ReactStartTransition.js` and its class tests
  `ReactCoffeeScriptClass-test.coffee`, `ReactES6Class-test.js`, and
  `ReactTypeScriptClass-test.ts`.
- Assertions updated only for the new global test-error transport:
  `ReactFlushSync-test.js`, `ReactFlushSyncNoAggregateError-test.js`,
  `ReactHooks-test.internal.js`, `ReactHooksWithNoopRenderer-test.js`,
  `ReactIncrementalErrorHandling-test.internal.js`,
  `ReactIncrementalErrorLogging-test.js`, `ReactLazy-test.internal.js`,
  `ReactSuspenseWithNoopRenderer-test.js`,
  `packages/react-refresh/src/__tests__/ReactFresh-test.js`, and
  `packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js`.
- Fizz/server and hydration-only follow-ups in `e10a7b5` and `6090cab` are
  excluded. Their client invariant is retained: a failed synchronous retry does
  not also invoke `onRecoverableError`.
- Rollup fork deletion in `scripts/rollup/forks.js` is build-system-specific.

The result reports errors once at the selected root handler. An application
that installs `onCaughtError` must not also report from `componentDidCatch`;
the Error Boundary continues to own fallback UI and recovery state.
