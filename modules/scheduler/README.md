# scheduler
A Roblox Lua port of the `scheduler` package from React, which is used under the hood by the Fiber Reconciler logic.

Status: ✔️ Ported

Source: https://github.com/facebook/react/tree/master/packages/scheduler

---

### ✏️ Notes
* The upstream implementation of min-heap does not include tests. To validate the port, `src/__tests__/SchedulerMinHeap.spec.lua` was added
* The scheduler contains two sets of tests
	* A small, basic set of tests using the real scheduler and mock timers.
	* A more thorough test suite that uses `MockSchedulerHostConfig.lua`, which mocks the entire HostConfig interface and provides functionality to manipulate it within tests.

#### Profiling

```
src/SchedulerProfiling.js
src/__tests__/SchedulerProfiling-test.js
```

Profiling logic used for debugging the Scheduler. Includes tests that produce flamegraphs of processed tasks. This functionality is gated behind the `enableProfiling` flag defined in `SchedulerFeatureFlags.js`. Additional functionality is gated behind the enableSchedulingProfiler flag in ReactFeatureFlags. When enabling the Scheduling Profiler, you'll need to plug in a table with a `mark` function to the `_G.performance` global, like this:
```lua
_G.performance = {
	mark = function(str)
		debug.profileBegin(str)
		debug.profileEnd(str)
}
```

We may customize this for deeper integration with the Roblox Studio profiler in the future, based on specific performance optimization workflow needs.


### ❌ Excluded

#### Post Task

```
unstable_post_task.js
src/SchedulerPostTask.js
src/__tests__/SchedulerPostTask-test.js
```

An alternate implementation of the Scheduler interface based on the new postTask browser API. There are relatively recent commits to these files, as well, suggesting new or ongoing development. Since the underlying browser API isn't relevant to the Roblox environment, this logic has been excluded.
