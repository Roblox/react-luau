# react-reconciler
A Roblox Lua port of the `react-reconciler` package from React, which contains the core reconciler logic that drives the various renderers that can be attached.

Status: 🔨 Port in progress

Source: https://github.com/facebook/react/tree/master/packages/react-reconciler

---

### ✏️ Notes

#### Profiling

```
src/SchedulingProfiler.js
src/__tests__/SchedulingProfiler-test.internal.js
```

Profiling logic used for debugging the Scheduler. Includes tests that produce flamegraphs of processed tasks. This functionality is gated behind the `enableProfiling` flag defined in `SchedulerFeatureFlags.js`. Additional functionality is gated behind the enableSchedulingProfiler in ReactFeatureFlags. When enabling the Scheduling Profiler, you'll need to plug in a table with a `mark` function to the `_G.performance` global, like this:
```lua
_G.performance = {
	mark = function(str)
		debug.profileBegin(str)
		debug.profileEnd(str)
}
```

#### Debug Tracing

```
src/DebugTracing.js
src/__tests__/DebugTracing-test.internal.js
```

Debug Tracing is enabled with the enableDebugTracing ReactFeatureFlag. The current Lua implementation outputs using Lua `print`, and strips out the color and styling versus upstream. We may want to more deeply customize this based on real-world use cases of Roblox UI developers.


### ❌ Excluded

```
src/__tests__/ReactSuspenseList-test.js
```

The initial release of Roact 17 includes support for Suspense, but not the unstable SuspenseList API. This was purely to pull in the delivery schedule and narrow the support surface for the initial release.
