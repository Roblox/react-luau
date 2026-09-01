# use-sync-external-store

A Luau translation of React's `use-sync-external-store/with-selector` companion
package. It composes React's native `useSyncExternalStore` hook with memoized
selection and optional selection equality.

Status: 🔨 Port in progress

Source: React `v19.2.0` commit
[`ae74234e`](https://github.com/facebook/react/tree/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store)

## Dependency

This package requires the native `useSyncExternalStore` backport from
[Roblox/react-luau#24](https://github.com/Roblox/react-luau/pull/24). It is a
user-space companion package, not a React dispatcher or reconciler hook.

## Source history

- [`1314299c`](https://github.com/facebook/react/commit/1314299c7f70914d61d8e1cef56767f112110674)
  introduces the selector companion and its shared tests.
- [`fd5e01c2`](https://github.com/facebook/react/commit/fd5e01c2e0dbbeaff954d13fc6bc11bfc65e7dcf)
  reuses the currently rendered selection when a changed selector produces an
  equal value.
- [`f2c38113`](https://github.com/facebook/react/commit/f2c381131fb58c107e6153255bc8d1d6340db506)
  corrects memoized-snapshot behavior and adds error regressions.
- [`6bce0355`](https://github.com/facebook/react/commit/6bce0355c3e4bf23c16e82317094230908ee7560)
  establishes the stable `with-selector` package boundary.
- [`c5eca9b0`](https://github.com/facebook/react/commit/c5eca9b0824b6325dbc9613f9befb41077fe35a0)
  advances the memoized snapshot when equality reuses a selection.

## Source and test ledger

| Upstream source or test | React-Luau target | Port status | Deviation |
| --- | --- | --- | --- |
| `src/useSyncExternalStoreWithSelector.js` — `useSyncExternalStoreWithSelector` | `src/init.lua` | Direct | Luau multiple returns replace the JavaScript pair allocated inside `useMemo`; `nil` represents both nullish server-snapshot states. |
| `with-selector.js` public export | `src/init.lua` returned interface | Adapted | Rotriever and Wally publish one ModuleScript entry point instead of Node subpath exports. |
| `package.json` and `README.md` package boundary | `rotriever.toml`, `wally.toml`, `default.project.json`, and this file | Adapted | React-Luau uses workspace and Roblox package manifests rather than npm and Rollup. |
| `useSyncExternalStoreShared-test.js` — `memoized selectors are only called once per update` | `src/__tests__/useSyncExternalStoreWithSelector.spec.lua` | Adapted | ReactNoop act/host output and Scheduler yield assertions replace DOM act/text; assertions and order are preserved. |
| `useSyncExternalStoreShared-test.js` — `Using isEqual to bailout` | Same test file | Adapted | ReactNoop act and concatenated host props replace DOM act/text content; the two subscribers, updates, and bailout assertions are preserved. |
| `useSyncExternalStoreShared-test.js` — `compares selection to rendered selection even if selector changes` | Same test file | Adapted | ReactNoop act, Luau arrays, and ReactNoop host children replace DOM act, JavaScript arrays, and DOM list nodes. |
| `useSyncExternalStoreShared-test.js` — selector and `isEqual` error cases | Same test file | Adapted | ReactNoop act, explicit Scheduler yield assertions, Jest-Lua's error object, and ReactNoop's error boundary replace DOM act/output and JavaScript `TypeError`; React 17 performs concurrent recovery twice, duplicating its diagnostic and boundary yield. |
| `useSyncExternalStoreShared-test.js` — native/shim `useSyncExternalStore` cases | React-Luau#24 | Out of scope | The dependency backport owns the native hook contract; this package does not duplicate it. |
| `useSyncExternalStoreShared-test.js` — `basic server hydration` | No target | Out of scope | The case exercises native `useSyncExternalStore`, not the selector companion, and ReactRoblox has no hydration entry point. |
| `shim/with-selector.js` and shim build forks | No target | Out of scope | This package requires React-Luau#24 and does not support a React runtime without the native hook. |
| npm CommonJS wrappers and Rollup configuration | Rotriever and Wally manifests | Out of scope | Roblox package publication does not use npm runtime wrappers or Rollup forks. |

Selection equality suppresses consumer rendering. It does not suppress store
publication or snapshot collection.
