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

return exports
