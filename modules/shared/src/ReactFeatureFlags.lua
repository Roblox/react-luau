--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ba82eea3837e4aaeb5a30b7827b664a8c2128d2e/packages/shared/ReactFeatureFlags.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Shared = script.Parent
local Packages = Shared.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local SafeFlags = require(Packages.SafeFlags)

local GetFFlagReactEnableSchedulingProfiler =
	SafeFlags.createGetFFlag("ReactEnableSchedulingProfiler")
local GetFFlagReactCatchYieldingInDEV =
	SafeFlags.createGetFFlag("ReactCatchYieldingInDEV")
local GetFFlagReactFilterInternalStackFrames =
	SafeFlags.createGetFFlag("ReactFilterInternalStackFrames")

-- Unknown globals fail type checking (see "Unknown symbols" section of
-- https://roblox.github.io/luau/typecheck.html)
local exports = {}

-- Adds verbose console logging for e.g. state updates, suspense, and work loop stuff.
-- Intended to enable React core members to more easily debug scheduling issues in DEV builds.
exports.enableDebugTracing = false

-- Adds user timing marks for e.g. state updates, suspense, and work loop stuff,
-- for an experimental scheduling profiler tool.
exports.enableSchedulingProfiler = GetFFlagReactEnableSchedulingProfiler()
	or (ReactGlobals.__PROFILE__ and ReactGlobals.__EXPERIMENTAL__)

-- When DEV mode is enabled, throw an error when a fiber attempts to yield.
exports.catchYieldingInDEV = ReactGlobals.__DEV__ and GetFFlagReactCatchYieldingInDEV()

-- Helps identify side effects in render-phase lifecycle hooks and setState
-- reducers by double invoking them in Strict Mode.
-- ROBLOX TODO: we'll want to enable this for DEV app bundles
exports.debugRenderPhaseSideEffectsForStrictMode = ReactGlobals.__DEV__

-- To preserve the "Pause on caught exceptions" behavior of the debugger, we
-- replay the begin phase of a failed component inside invokeGuardedCallback.
exports.replayFailedUnitOfWorkWithInvokeGuardedCallback = ReactGlobals.__DEV__

-- Warn about deprecated, async-unsafe lifecycles; relates to RFC #6:
exports.warnAboutDeprecatedLifecycles = true

-- Gather advanced timing metrics for Profiler subtrees.
exports.enableProfilerTimer = ReactGlobals.__PROFILE__

-- Record durations for commit and passive effects phases.
exports.enableProfilerCommitHooks = ReactGlobals.__PROFILE__

-- Trace which interactions trigger each commit.
exports.enableSchedulerTracing = ReactGlobals.__PROFILE__

-- SSR experiments
exports.enableSuspenseServerRenderer = ReactGlobals.__EXPERIMENTAL__

-- Flight experiments
exports.enableBlocksAPI = ReactGlobals.__EXPERIMENTAL__
exports.enableLazyElements = ReactGlobals.__EXPERIMENTAL__

-- Only used in www builds.
exports.enableSchedulerDebugging = false

-- Experimental Host Component support.
exports.enableFundamentalAPI = false

-- Experimental Scope support.
exports.enableScopeAPI = false

-- Experimental Create Event Handle API.
exports.enableCreateEventHandleAPI = false

-- We will enforce mocking scheduler with scheduler/unstable_mock at some point. (v18?)
-- Till then, we warn about the missing mock, but still fallback to a legacy mode compatible version
exports.warnAboutUnmockedScheduler = false

-- Add a callback property to suspense to notify which promises are currently
-- in the update queue. This allows reporting and tracing of what is causing
-- the user to see a loading state.
-- Also allows hydration callbacks to fire when a dehydrated boundary gets
-- hydrated or deleted.
exports.enableSuspenseCallback = false

-- Part of the simplification of React.createElement so we can eventually move
-- from React.createElement to React.jsx
-- https://github.com/reactjs/rfcs/blob/createlement-rfc/text/0000-create-element-changes.md
exports.warnAboutDefaultPropsOnFunctionComponents = false

-- Enables a warning when trying to spread a 'key' to an element
-- a deprecated pattern we want to get rid of in the future
exports.warnAboutSpreadingKeyToJSX = true

exports.enableComponentStackLocations = true

exports.enableNewReconciler = true

-- Errors that are thrown while unmounting (or after in the case of passive effects)
-- should bypass any error boundaries that are also unmounting (or have unmounted)
-- and be handled by the nearest still-mounted boundary.
-- If there are no still-mounted boundaries, the errors should be rethrown.
exports.skipUnmountedBoundaries = true

-- When a node is unmounted, recurse into the Fiber subtree and clean out
-- references. Each level cleans up more fiber fields than the previous level.
-- As far as we know, React itself doesn't leak, but because the Fiber contains
-- cycles, even a single leak in product code can cause us to retain large
-- amounts of memory.
--
-- The long term plan is to remove the cycles, but in the meantime, we clear
-- additional fields to mitigate.
--
-- It's an enum so that we can experiment with different levels of
-- aggressiveness.
exports.deletedTreeCleanUpLevel =
	SafeFlags.createGetFInt("ReactDeletedTreeCleanUpLevel", 1)()
exports.enableNewTreeCleanupPath =
	SafeFlags.createGetFFlag("ReactEnableNewTreeCleanupPath", false)()

-- Double buffer hook list nodes and effect queues between a fiber and its
-- alternate, overwriting the stale copy in place instead of allocating a new
-- one on every update render.
exports.enableHookDoubleBuffering =
	SafeFlags.createGetFFlag("ReactEnableHookDoubleBuffering", false)()

-- Clean up stacktraces by filtering out stack frames coming from inside React
-- itself.
exports.filterInternalStackFrames = ReactGlobals.__DEV__
	and GetFFlagReactFilterInternalStackFrames()

-- --------------------------
-- Future APIs to be deprecated
-- --------------------------

exports.warnAboutStringRefs = false

exports.disableLegacyContext = false

exports.disableModulePatternComponents = false

-- We should remove this flag once the above flag becomes enabled
exports.warnUnstableRenderSubtreeIntoContainer = false

-- Updates that occur in the render phase are not officially supported. But when
-- they do occur, we defer them to a subsequent render by picking a lane that's
-- not currently rendering. We treat them the same as if they came from an
-- interleaved event. Remove this flag once we have migrated to the
-- new behavior.
exports.deferRenderPhaseUpdateToNextBatch = false

-- Replacement for runWithPriority in React internals.
exports.decoupleUpdatePriorityFromScheduler = true

exports.enableEagerRootListeners = false

exports.enableDoubleInvokingEffects = false

-- ROBLOX performance: allocate less per render. useMemo/useCallback/useBinding
-- store their state without tuple tables, hook and context dependency objects
-- are sized to the fields they use, readContext reuses the cloned dependencies
-- object, state merges use table.clone, and refs/bindings share methods
-- instead of allocating closures per instance.
exports.enableAllocationTrims =
	SafeFlags.createGetFFlag("ReactEnableAllocationTrims", false)()

-- ROBLOX performance: cheaper per-fiber render work. Skip nil stores into
-- absent fiber, hook and effect keys (each can rehash the table in Luau), and
-- skip the per-fiber profiling and DEV-only helper calls when they are no-ops.
exports.enableWorkLoopTrims = SafeFlags.createGetFFlag("ReactWorkLoopTrims", false)()

-- ROBLOX performance: cheaper commit traversals. Host updates get their own
-- flag outside LayoutMask, the passive flush is scheduled from the root's flags
-- so the before mutation pass can skip passive-only subtrees, and passive mount
-- effects run from fibers collected by the unmount pass.
exports.enableCommitTraversalTrims =
	SafeFlags.createGetFFlag("ReactCommitTraversalTrims", false)()

-- ROBLOX performance: skip the host sibling lookup in commitPlacement for hosts
-- whose child order doesn't matter (supportsChildOrdering = false). Roblox
-- parents by setting Parent, so insertBefore ignores the sibling, and the lookup
-- costs k(k-1)/2 fiber steps when k siblings are inserted into a mounted parent.
exports.enableSkipHostSiblingLookup =
	SafeFlags.createGetFFlag("ReactSkipHostSiblingLookup", false)()

-- ROBLOX: re-entrancy-safe binding signals. Subscribing during a fire no longer
-- inserts into the table being traversed, and a nested fire no longer resets the
-- outer fire's state. Also skips clearing when nothing was suspended.
exports.enableReentrantSafeSignals =
	SafeFlags.createGetFFlag("ReactReentrantSafeSignals", false)()

-- ROBLOX fix: when a sync callback throws, keep the remaining callbacks queued
-- for the retry instead of dropping them (upstream semantics).
exports.keepSyncQueueOnError =
	SafeFlags.createGetFFlag("ReactKeepSyncQueueOnError", false)()

-- ROBLOX fix: getInstanceFromNode reads fibers from the instance maps and
-- compares against the right work tags (DevTools and test utilities).
exports.fixGetInstanceFromNode =
	SafeFlags.createGetFFlag("ReactFixGetInstanceFromNode", false)()

-- ROBLOX fix: when an eager reducer call errors, don't compare the error value
-- with the current state as if it were the next state.
exports.fixEagerReducerError =
	SafeFlags.createGetFFlag("ReactFixEagerReducerError", false)()

-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/shared/forks/ReactFeatureFlags.www.js
-- ROBLOX deviation: Transition tracing is not available in React Lua.
exports.enableTransitionTracing = false

-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/shared/ReactFeatureFlags.js#L227-L235
-- ROBLOX DEVIATION: The supported Luau renderers share this client flag module.
exports.enableParallelTransitions = true

return exports
