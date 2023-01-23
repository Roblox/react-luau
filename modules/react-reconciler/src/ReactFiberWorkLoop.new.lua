-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberWorkLoop.new.js
--!nonstrict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__
local __YOLO__ = _G.__YOLO__

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set
type Set<T> = LuauPolyfill.Set<T>
type Array<T> = LuauPolyfill.Array<T>

local exports: any = {}

local ReactTypes = require(Packages.Shared)
type Thenable<T> = ReactTypes.Thenable<T>
type Wakeable = ReactTypes.Wakeable

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
-- The scheduler is imported here *only* to detect whether it's been mocked
local Scheduler = require(Packages.Scheduler)
-- ROBLOX deviation: we import from top-level Scheduler exports to avoid direct file access

type Interaction = Scheduler.Interaction

local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
local ReactFiberStack = require(script.Parent["ReactFiberStack.new"])
type StackCursor<T> = ReactFiberStack.StackCursor<T>

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
-- deviation: Use some properties directly instead of localizing to avoid 200 limit
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local replayFailedUnitOfWorkWithInvokeGuardedCallback = ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback
-- local warnAboutUnmockedScheduler = ReactFeatureFlags.warnAboutUnmockedScheduler
-- local deferRenderPhaseUpdateToNextBatch = ReactFeatureFlags.ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local skipUnmountedBoundaries = ReactFeatureFlags.skipUnmountedBoundaries
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects
local ReactShared = require(Packages.Shared)
-- ROBLOX deviation: we pull in Dispatcher type because we need it for our lazy loading deviations to typecheck
type Dispatcher = ReactShared.Dispatcher
local describeError = require(Packages.Shared).describeError
local ReactSharedInternals = ReactShared.ReactSharedInternals
local invariant = ReactShared.invariant

local SchedulerWithReactIntegration =
	require(script.Parent["SchedulerWithReactIntegration.new"])
local scheduleCallback = SchedulerWithReactIntegration.scheduleCallback
local cancelCallback = SchedulerWithReactIntegration.cancelCallback
local getCurrentPriorityLevel = SchedulerWithReactIntegration.getCurrentPriorityLevel
local runWithPriority = SchedulerWithReactIntegration.runWithPriority
local shouldYield = SchedulerWithReactIntegration.shouldYield
local requestPaint = SchedulerWithReactIntegration.requestPaint
local now = SchedulerWithReactIntegration.now
local NoSchedulerPriority = SchedulerWithReactIntegration.NoPriority
local ImmediateSchedulerPriority = SchedulerWithReactIntegration.ImmediatePriority
local UserBlockingSchedulerPriority = SchedulerWithReactIntegration.UserBlockingPriority
local NormalSchedulerPriority = SchedulerWithReactIntegration.NormalPriority
local flushSyncCallbackQueue = SchedulerWithReactIntegration.flushSyncCallbackQueue
local scheduleSyncCallback = SchedulerWithReactIntegration.scheduleSyncCallback
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local {
--   DebugTracing.logCommitStarted,
--   DebugTracing.logCommitStopped,
--   DebugTracing.logLayoutEffectsStarted,
--   DebugTracing.logLayoutEffectsStopped,
--   logPassiveEffectsStarted,
--   DebugTracing.logPassiveEffectsStopped,
--   DebugTracing.logRenderStarted,
--   DebugTracing.logRenderStopped,
local DebugTracing = require(script.Parent.DebugTracing)
-- local {
--   SchedulingProfiler.markCommitStarted,
--   SchedulingProfiler.markCommitStopped,
--   SchedulingProfiler.markLayoutEffectsStarted,
--   SchedulingProfiler.markLayoutEffectsStopped,
--   SchedulingProfiler.markPassiveEffectsStarted,
--   SchedulingProfiler.markPassiveEffectsStopped,
--   SchedulingProfiler.markRenderStarted,
--   SchedulingProfiler.markRenderYielded,
--   SchedulingProfiler.markRenderStopped,
local SchedulingProfiler = require(script.Parent.SchedulingProfiler)

local SchedulerTracing = require(Packages.Scheduler).tracing
local __interactionsRef, __subscriberRef =
	SchedulerTracing.__interactionsRef, SchedulerTracing.__subscriberRef

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local prepareForCommit = ReactFiberHostConfig.prepareForCommit
-- local resetAfterCommit = ReactFiberHostConfig.resetAfterCommit
-- local scheduleTimeout = ReactFiberHostConfig.scheduleTimeout
-- local cancelTimeout = ReactFiberHostConfig.cancelTimeout
-- local noTimeout = ReactFiberHostConfig.noTimeout
-- local warnsIfNotActing = ReactFiberHostConfig.warnsIfNotActing
-- local beforeActiveInstanceBlur = ReactFiberHostConfig.beforeActiveInstanceBlur
-- local afterActiveInstanceBlur = ReactFiberHostConfig.afterActiveInstanceBlur
-- local clearContainer = ReactFiberHostConfig.clearContainer

local ReactFiber = require(script.Parent["ReactFiber.new"])
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local createWorkInProgress = ReactFiber.createWorkInProgress
-- local assignFiberPropertiesInDEV = ReactFiber.assignFiberPropertiesInDEV
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local NoMode = ReactTypeOfMode.NoMode
-- local StrictMode = ReactTypeOfMode.StrictMode
-- local ProfileMode = ReactTypeOfMode.ProfileMode
-- local BlockingMode = ReactTypeOfMode.BlockingMode
-- local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local ReactWorkTags = require(script.Parent.ReactWorkTags)
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local HostRoot = ReactWorkTags.HostRoot
-- local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
-- local ClassComponent = ReactWorkTags.ClassComponent
-- local SuspenseComponent = ReactWorkTags.SuspenseComponent
-- local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
-- local FunctionComponent = ReactWorkTags.FunctionComponent
-- local ForwardRef = ReactWorkTags.ForwardRef
-- local MemoComponent = ReactWorkTags.MemoComponent
-- local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LegacyRoot = require(script.Parent.ReactRootTags).LegacyRoot
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
type Flags = ReactFiberFlags.Flags
-- ROBLOX deviation: Use properties directly instead of localizing to avoid 200 limit
-- local NoFlags = ReactFiberFlags.NoFlags
-- local Placement = ReactFiberFlags.Placement
-- local Incomplete = ReactFiberFlags.Incomplete
-- local HostEffectMask = ReactFiberFlags.HostEffectMask
-- local Hydrating = ReactFiberFlags.Hydrating
-- local BeforeMutationMask = ReactFiberFlags.BeforeMutationMask
-- local MutationMask = ReactFiberFlags.MutationMask
-- local LayoutMask = ReactFiberFlags.LayoutMask
-- local PassiveMask = ReactFiberFlags.PassiveMask
-- local NoLane = ReactFiberLane.NoLane
local SyncLane = ReactFiberLane.SyncLane
local SyncBatchedLane = ReactFiberLane.SyncBatchedLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local findUpdateLane = ReactFiberLane.findUpdateLane
local findTransitionLane = ReactFiberLane.findTransitionLane
local findRetryLane = ReactFiberLane.findRetryLane
local includesSomeLane = ReactFiberLane.includesSomeLane
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes
local removeLanes = ReactFiberLane.removeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane
local hasDiscreteLanes = ReactFiberLane.hasDiscreteLanes
local includesNonIdleWork = ReactFiberLane.includesNonIdleWork
local includesOnlyRetries = ReactFiberLane.includesOnlyRetries
local includesOnlyTransitions = ReactFiberLane.includesOnlyTransitions
local getNextLanes = ReactFiberLane.getNextLanes
local returnNextLanesPriority = ReactFiberLane.returnNextLanesPriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local markStarvedLanesAsExpired = ReactFiberLane.markStarvedLanesAsExpired
local getLanesToRetrySynchronouslyOnError =
	ReactFiberLane.getLanesToRetrySynchronouslyOnError
local getMostRecentEventTime = ReactFiberLane.getMostRecentEventTime
local markRootUpdated = ReactFiberLane.markRootUpdated
local markRootSuspended_dontCallThisOneDirectly = ReactFiberLane.markRootSuspended
local markRootPinged = ReactFiberLane.markRootPinged
local markRootExpired = ReactFiberLane.markRootExpired
local markDiscreteUpdatesExpired = ReactFiberLane.markDiscreteUpdatesExpired
local markRootFinished = ReactFiberLane.markRootFinished
local schedulerPriorityToLanePriority = ReactFiberLane.schedulerPriorityToLanePriority
local lanePriorityToSchedulerPriority = ReactFiberLane.lanePriorityToSchedulerPriority
local ReactFiberTransition = require(script.Parent.ReactFiberTransition)
-- deviation: Use properties directly instead of localizing to avoid 200 limit
-- local requestCurrentTransition = ReactFiberTransition.requestCurrentTransition
-- local NoTransition = ReactFiberTransition.NoTransition

local ReactFiberUnwindWork = require(script.Parent["ReactFiberUnwindWork.new"]) :: any
local unwindWork = ReactFiberUnwindWork.unwindWork
local unwindInterruptedWork = ReactFiberUnwindWork.unwindInterruptedWork
local ReactFiberThrow = require(script.Parent["ReactFiberThrow.new"]) :: any
local throwException = ReactFiberThrow.throwException
local createRootErrorUpdate = ReactFiberThrow.createRootErrorUpdate
local createClassErrorUpdate = ReactFiberThrow.createClassErrorUpdate
local ReactFiberCommitWork = require(script.Parent["ReactFiberCommitWork.new"])
local commitBeforeMutationEffectOnFiber =
	ReactFiberCommitWork.commitBeforeMutationLifeCycles
local commitPlacement = ReactFiberCommitWork.commitPlacement
local commitWork = ReactFiberCommitWork.commitWork
local commitDeletion = ReactFiberCommitWork.commitDeletion
local commitPassiveUnmountOnFiber = ReactFiberCommitWork.commitPassiveUnmount
local commitPassiveUnmountInsideDeletedTreeOnFiber =
	ReactFiberCommitWork.commitPassiveUnmountInsideDeletedTree
local commitPassiveMountOnFiber = ReactFiberCommitWork.commitPassiveMount
local commitDetachRef = ReactFiberCommitWork.commitDetachRef
-- local commitAttachRef = ReactFiberCommitWork.commitAttachRef
-- local commitResetTextContent = ReactFiberCommitWork.commitResetTextContent
-- local isSuspenseBoundaryBeingHidden = ReactFiberCommitWork.isSuspenseBoundaryBeingHidden
local invokeLayoutEffectMountInDEV = ReactFiberCommitWork.invokeLayoutEffectMountInDEV
local invokePassiveEffectMountInDEV = ReactFiberCommitWork.invokePassiveEffectMountInDEV
local invokeLayoutEffectUnmountInDEV = ReactFiberCommitWork.invokeLayoutEffectUnmountInDEV
local invokePassiveEffectUnmountInDEV =
	ReactFiberCommitWork.invokePassiveEffectUnmountInDEV
local recursivelyCommitLayoutEffects = ReactFiberCommitWork.recursivelyCommitLayoutEffects

local Promise = require(Packages.Promise)

local enqueueUpdate = require(script.Parent["ReactUpdateQueue.new"]).enqueueUpdate

local resetContextDependencies =
	require(script.Parent["ReactFiberNewContext.new"]).resetContextDependencies

-- ROBLOX deviation: Pre-declare function
local ensureRootIsScheduled

-- deviation: lazy init for functions from ReactFiberHooks, put in table b/c local var limit
local lazyInitRefs = {
	resetHooksAfterThrowRef = (nil :: any) :: (...any) -> ...any,
	ContextOnlyDispatcherRef = (nil :: any) :: Dispatcher,
	getIsUpdatingOpaqueValueInRenderPhaseInDEVRef = (nil :: any) :: (...any) -> ...any,
	originalBeginWorkRef = (nil :: any) :: (...any) -> ...any,
	completeWorkRef = (nil :: any) :: (...any) -> ...any,
}

-- ROBLOX deviation: lazy initialize beginwork to break cyclic dependencies
local originalBeginWork =
	function(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes): Fiber | nil
		if not lazyInitRefs.originalBeginWorkRef then
			lazyInitRefs.originalBeginWorkRef =
				require(script.Parent["ReactFiberBeginWork.new"]).beginWork
		end
		return lazyInitRefs.originalBeginWorkRef(current, workInProgress, renderLanes)
	end

local completeWork =
	function(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes): Fiber | nil
		if not lazyInitRefs.completeWorkRef then
			lazyInitRefs.completeWorkRef =
				require(script.Parent["ReactFiberCompleteWork.new"]).completeWork
		end
		return (lazyInitRefs.completeWorkRef :: any)(current, workInProgress, renderLanes)
	end

local ReactFiberHooks
-- ROBLOX deviation: lazy init for functions from ReactFiberHooks
local function initReactFiberHooks()
	ReactFiberHooks = require(script.Parent["ReactFiberHooks.new"])
	lazyInitRefs.resetHooksAfterThrowRef = ReactFiberHooks.resetHooksAfterThrow
	lazyInitRefs.ContextOnlyDispatcherRef = ReactFiberHooks.ContextOnlyDispatcher
	lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef =
		ReactFiberHooks.getIsUpdatingOpaqueValueInRenderPhaseInDEV
end

-- ROBLOX deviation: lazy init for resetHooksAfterThrow from ReactFiberHooks
local resetHooksAfterThrow = function(): ()
	if not lazyInitRefs.resetHooksAfterThrowRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.resetHooksAfterThrowRef()
end

-- ROBLOX deviation: lazy init for ContextOnlyDispatcher from ReactFiberHooks
local ContextOnlyDispatcher = function(): Dispatcher
	if not lazyInitRefs.ContextOnlyDispatcherRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.ContextOnlyDispatcherRef
end

-- ROBLOX deviation: lazy init for getIsUpdatingOpaqueValueInRenderPhaseInDEV from ReactFiberHooks
local getIsUpdatingOpaqueValueInRenderPhaseInDEV = function(): boolean?
	if not lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef then
		initReactFiberHooks()
	end
	return lazyInitRefs.getIsUpdatingOpaqueValueInRenderPhaseInDEVRef()
end

local createCapturedValue = require(script.Parent.ReactCapturedValue).createCapturedValue
local pushToStack = ReactFiberStack.push
local popFromStack = ReactFiberStack.pop
local createCursor = ReactFiberStack.createCursor

local ReactProfilerTimer = require(script.Parent["ReactProfilerTimer.new"])

-- DEV stuff
local getComponentName = require(Packages.Shared).getComponentName
local ReactStrictModeWarnings = require(script.Parent["ReactStrictModeWarnings.new"])
local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
-- deviation: these two properties would be captured as values instead of bound
-- local ReactCurrentDebugFiberIsRenderingInDEV = ReactCurrentFiber.isRendering
local ReactCurrentFiberCurrent = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local ReactErrorUtils = require(Packages.Shared).ReactErrorUtils
local invokeGuardedCallback = ReactErrorUtils.invokeGuardedCallback
local hasCaughtError = ReactErrorUtils.hasCaughtError
local clearCaughtError = ReactErrorUtils.clearCaughtError
local onCommitRootDevTools =
	require(script.Parent["ReactFiberDevToolsHook.new"]).onCommitRoot
local onCommitRootTestSelector = require(script.Parent.ReactTestSelectors).onCommitRoot

-- Used by `act`
local enqueueTask = require(Packages.Shared).enqueueTask
local doesFiberContain = require(script.Parent.ReactFiberTreeReflection).doesFiberContain

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner
local IsSomeRendererActing = ReactSharedInternals.IsSomeRendererActing
local captureCommitPhaseErrorOnRoot, flushPassiveMountEffects

-- local ceil = math.ceil

-- ROBLOX deviation: Pre-declare functions
local mod: { [string]: any } = {}

type ExecutionContext = number

local NoContext = --[[                    ]]
	0b0000000
local BatchedContext = --[[               ]]
	0b0000001
local EventContext = --[[                 ]]
	0b0000010
local DiscreteEventContext = --[[         ]]
	0b0000100
local LegacyUnbatchedContext = --[[       ]]
	0b0001000
local RenderContext = --[[                ]]
	0b0010000
local CommitContext = --[[                ]]
	0b0100000
local RetryAfterError = --[[              ]]
	0b1000000

exports.NoContext = NoContext
exports.RetryAfterError = RetryAfterError

-- ROBLOX deviation: Luau doesn't yet support literal types
-- type RootExitStatus = 0 | 1 | 2 | 3 | 4 | 5
type RootExitStatus = number
-- ROBLOX deviation: Define constants in a table instead of locals to avoid 200 limit
local RootExitStatus: { [string]: RootExitStatus } = {
	Incomplete = 0,
	FatalErrored = 1,
	Errored = 2,
	Suspended = 3,
	SuspendedWithDelay = 4,
	Completed = 5,
}

-- Describes where we are in the React execution stack
local executionContext: ExecutionContext = NoContext
-- The root we're working on
local workInProgressRoot: FiberRoot? = nil
-- The fiber we're working on
local workInProgress: Fiber? = nil
-- The lanes we're rendering
local workInProgressRootRenderLanes: Lanes = ReactFiberLane.NoLanes

-- Stack that allows components to change the render lanes for its subtree
-- This is a superset of the lanes we started working on at the root. The only
-- case where it's different from `workInProgressRootRenderLanes` is when we
-- enter a subtree that is hidden and needs to be unhidden: Suspense and
-- Offscreen component.
--
-- Most things in the work loop should deal with workInProgressRootRenderLanes.
-- Most things in begin/complete phases should deal with exports.subtreeRenderLanes.
exports.subtreeRenderLanes = ReactFiberLane.NoLanes
local subtreeRenderLanesCursor: StackCursor<Lanes> = createCursor(ReactFiberLane.NoLanes)

-- Whether to root completed, errored, suspended, etc.
local workInProgressRootExitStatus: RootExitStatus = RootExitStatus.Incomplete
-- A fatal error, if one is thrown
local workInProgressRootFatalError: any = nil
-- "Included" lanes refer to lanes that were worked on during this render. It's
-- slightly different than `renderLanes` because `renderLanes` can change as you
-- enter and exit an Offscreen tree. This value is the combination of all render
-- lanes for the entire render phase.
local workInProgressRootIncludedLanes: Lanes = ReactFiberLane.NoLanes
-- The work left over by components that were visited during this render. Only
-- includes unprocessed updates, not work in bailed out children.
local ReactFiberWorkInProgress = require(script.Parent.ReactFiberWorkInProgress)
local workInProgressRootSkippedLanes: (value: Lanes?) -> Lanes =
	ReactFiberWorkInProgress.workInProgressRootSkippedLanes --: Lanes = ReactFiberLane.NoLanes
-- Lanes that were updated (in an interleaved event) during this render.
local workInProgressRootUpdatedLanes: Lanes = ReactFiberLane.NoLanes
-- Lanes that were pinged (in an interleaved event) during this render.
local workInProgressRootPingedLanes: Lanes = ReactFiberLane.NoLanes

local mostRecentlyUpdatedRoot: FiberRoot | nil = nil

-- The most recent time we committed a fallback. This lets us ensure a train
-- model where we don't commit new loading states in too quick succession.
local globalMostRecentFallbackTime: number = 0
local FALLBACK_THROTTLE_MS: number = 500

-- The absolute time for when we should start giving up on rendering
-- more and prefer CPU suspense heuristics instead.
local workInProgressRootRenderTargetTime: number = math.huge
-- How long a render is supposed to take before we start following CPU
-- suspense heuristics and opt out of rendering more content.
local RENDER_TIMEOUT_MS = 500

-- Used to avoid traversing the return path to find the nearest Profiler ancestor during commit.
local nearestProfilerOnStack: Fiber | nil = nil

local function resetRenderTimer()
	workInProgressRootRenderTargetTime = now() + RENDER_TIMEOUT_MS
end

exports.getRenderTargetTime = function(): number
	return workInProgressRootRenderTargetTime
end

local hasUncaughtError = false
local firstUncaughtError = nil
local legacyErrorBoundariesThatAlreadyFailed: Set<any> | nil = nil

local rootDoesHavePassiveEffects: boolean = false
local rootWithPendingPassiveEffects: FiberRoot? = nil
local pendingPassiveEffectsRenderPriority: ReactPriorityLevel = NoSchedulerPriority
local pendingPassiveEffectsLanes: Lanes = ReactFiberLane.NoLanes

local rootsWithPendingDiscreteUpdates: Set<ReactInternalTypes.FiberRoot> | nil = nil

-- Use these to prevent an infinite loop of nested updates
local NESTED_UPDATE_LIMIT = 50
local nestedUpdateCount: number = 0
local rootWithNestedUpdates: FiberRoot | nil = nil

local NESTED_PASSIVE_UPDATE_LIMIT = 50
local nestedPassiveUpdateCount: number = 0

-- Marks the need to reschedule pending interactions at these lanes
-- during the commit phase. This enables them to be traced across components
-- that spawn new work during render. E.g. hidden boundaries, suspended SSR
-- hydration or SuspenseList.
-- TODO: Can use a bitmask instead of an array
local spawnedWorkDuringRender: nil | Array<Lane | Lanes> = nil

-- If two updates are scheduled within the same event, we should treat their
-- event times as simultaneous, even if the actual clock time has advanced
-- between the first and second call.
local currentEventTime: number = NoTimestamp
local currentEventWipLanes: Lanes = ReactFiberLane.NoLanes
local currentEventPendingLanes: Lanes = ReactFiberLane.NoLanes

local focusedInstanceHandle: nil | Fiber = nil
local shouldFireAfterActiveInstanceBlur: boolean = false

exports.getWorkInProgressRoot = function(): FiberRoot?
	return workInProgressRoot
end

exports.requestEventTime = function()
	if
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
		~= NoContext
	then
		-- We're inside React, so it's fine to read the actual time.
		return now()
	end
	-- We're not inside React, so we may be in the middle of a browser event.
	if currentEventTime ~= NoTimestamp then
		-- Use the same start time for all updates until we enter React again.
		return currentEventTime
	end
	-- This is the first update since React yielded. Compute a new start time.
	currentEventTime = now()
	return currentEventTime
end

-- exports.getCurrentTime()
--   return now()
-- end

exports.requestUpdateLane = function(fiber: Fiber): Lane
	-- Special cases
	local mode = fiber.mode
	if bit32.band(mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
		return SyncLane :: Lane
	elseif bit32.band(mode, ReactTypeOfMode.ConcurrentMode) == ReactTypeOfMode.NoMode then
		return if getCurrentPriorityLevel() == ImmediateSchedulerPriority
			then SyncLane :: Lane
			else SyncBatchedLane :: Lane
	elseif
		not ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
		and bit32.band(executionContext, RenderContext) ~= NoContext
		and workInProgressRootRenderLanes ~= ReactFiberLane.NoLanes
	then
		-- This is a render phase update. These are not officially supported. The
		-- old behavior is to give this the same "thread" (expiration time) as
		-- whatever is currently rendering. So if you call `setState` on a component
		-- that happens later in the same render, it will flush. Ideally, we want to
		-- remove the special case and treat them as if they came from an
		-- interleaved event. Regardless, this pattern is not officially supported.
		-- This behavior is only a fallback. The flag only exists until we can roll
		-- out the setState warning, since existing code might accidentally rely on
		-- the current behavior.
		return pickArbitraryLane(workInProgressRootRenderLanes)
	end

	-- The algorithm for assigning an update to a lane should be stable for all
	-- updates at the same priority within the same event. To do this, the inputs
	-- to the algorithm must be the same. For example, we use the `renderLanes`
	-- to avoid choosing a lane that is already in the middle of rendering.
	--
	-- However, the "included" lanes could be mutated in between updates in the
	-- same event, like if you perform an update inside `flushSync`. Or any other
	-- code path that might call `prepareFreshStack`.
	--
	-- The trick we use is to cache the first of each of these inputs within an
	-- event. Then reset the cached values once we can be sure the event is over.
	-- Our heuristic for that is whenever we enter a concurrent work loop.
	--
	-- We'll do the same for `currentEventPendingLanes` below.
	if currentEventWipLanes == ReactFiberLane.NoLanes then
		currentEventWipLanes = workInProgressRootIncludedLanes
	end

	local isTransition = ReactFiberTransition.requestCurrentTransition()
		~= ReactFiberTransition.NoTransition
	if isTransition then
		if currentEventPendingLanes ~= ReactFiberLane.NoLanes then
			if mostRecentlyUpdatedRoot ~= nil then
				currentEventPendingLanes = mostRecentlyUpdatedRoot.pendingLanes
			else
				currentEventPendingLanes = ReactFiberLane.NoLanes
			end
		end
		return findTransitionLane(currentEventWipLanes, currentEventPendingLanes)
	end

	-- TODO: Remove this dependency on the Scheduler priority.
	-- To do that, we're replacing it with an update lane priority.
	local schedulerPriority = getCurrentPriorityLevel()

	-- The old behavior was using the priority level of the Scheduler.
	-- This couples React to the Scheduler internals, so we're replacing it
	-- with the currentUpdateLanePriority above. As an example of how this
	-- could be problematic, if we're not inside `Scheduler.runWithPriority`,
	-- then we'll get the priority of the current running Scheduler task,
	-- which is probably not what we want.
	local lane
	if
		-- TODO: Temporary. We're removing the concept of discrete updates.
		bit32.band(executionContext, DiscreteEventContext) ~= NoContext
		and schedulerPriority == UserBlockingSchedulerPriority
	then
		lane =
			findUpdateLane(ReactFiberLane.InputDiscreteLanePriority, currentEventWipLanes)
	else
		local schedulerLanePriority = schedulerPriorityToLanePriority(schedulerPriority)

		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			-- In the new strategy, we will track the current update lane priority
			-- inside React and use that priority to select a lane for this update.
			-- For now, we're just logging when they're different so we can assess.
			local currentUpdateLanePriority = getCurrentUpdateLanePriority()

			if
				schedulerLanePriority ~= currentUpdateLanePriority
				and currentUpdateLanePriority ~= ReactFiberLane.NoLanePriority
			then
				if __DEV__ then
					console.error(
						"Expected current scheduler lane priority %s to match current update lane priority %s",
						tostring(schedulerLanePriority),
						tostring(currentUpdateLanePriority)
					)
				end
			end
		end

		lane = findUpdateLane(schedulerLanePriority, currentEventWipLanes)
	end

	return lane
end

function requestRetryLane(fiber: Fiber): Lane
	-- This is a fork of `requestUpdateLane` designed specifically for Suspense
	-- "retries" — a special update that attempts to flip a Suspense boundary
	-- from its placeholder state to its primary/resolved state.

	-- Special cases
	local mode = fiber.mode
	if bit32.band(mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
		return SyncLane :: Lane
	elseif bit32.band(mode, ReactTypeOfMode.ConcurrentMode) == ReactTypeOfMode.NoMode then
		return if getCurrentPriorityLevel() == ImmediateSchedulerPriority
			then SyncLane :: Lane
			else SyncBatchedLane :: Lane
	end

	-- See `requestUpdateLane` for explanation of `currentEventWipLanes`
	if currentEventWipLanes == ReactFiberLane.NoLanes then
		currentEventWipLanes = workInProgressRootIncludedLanes
	end
	return findRetryLane(currentEventWipLanes)
end

exports.scheduleUpdateOnFiber = function(
	fiber: Fiber,
	lane: Lane,
	eventTime: number
): FiberRoot | nil
	mod.checkForNestedUpdates()

	local root = mod.markUpdateLaneFromFiberToRoot(fiber, lane)
	if root == nil then
		return nil
	end

	-- Mark that the root has a pending update.
	markRootUpdated(root, lane, eventTime)

	if root == workInProgressRoot then
		-- Received an update to a tree that's in the middle of rendering. Mark
		-- that there was an interleaved update work on this root. Unless the
		-- `ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch` flag is off and this is a render
		-- phase update. In that case, we don't treat render phase updates as if
		-- they were interleaved, for backwards compat reasons.
		mod.warnAboutRenderPhaseUpdatesInDEV(fiber)

		if
			ReactFeatureFlags.deferRenderPhaseUpdateToNextBatch
			or bit32.band(executionContext, RenderContext) == NoContext
		then
			workInProgressRootUpdatedLanes =
				mergeLanes(workInProgressRootUpdatedLanes, lane)
		end
		if workInProgressRootExitStatus == RootExitStatus.SuspendedWithDelay then
			-- The root already suspended with a delay, which means this render
			-- definitely won't finish. Since we have a new update, let's mark it as
			-- suspended now, right before marking the incoming update. This has the
			-- effect of interrupting the current render and switching to the update.
			-- TODO: Make sure this doesn't override pings that happen while we've
			-- already started rendering.
			mod.markRootSuspended(root, workInProgressRootRenderLanes)
		end
	end

	-- TODO: requestUpdateLanePriority also reads the priority. Pass the
	-- priority as an argument to that function and this one.
	local priorityLevel = getCurrentPriorityLevel()

	if lane == SyncLane then
		if
			-- Check if we're inside unbatchedUpdates
			bit32.band(executionContext, LegacyUnbatchedContext) ~= NoContext
			-- Check if we're not already rendering
			and bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
				== NoContext
		then
			-- Register pending interactions on the root to avoid losing traced interaction data.
			mod.schedulePendingInteractions(root, lane)

			-- This is a legacy edge case. The initial mount of a ReactDOM.render-ed
			-- root inside of batchedUpdates should be synchronous, but layout updates
			-- should be deferred until the end of the batch.
			mod.performSyncWorkOnRoot(root)
		else
			ensureRootIsScheduled(root, eventTime)
			mod.schedulePendingInteractions(root, lane)
			if executionContext == NoContext then
				-- Flush the synchronous work now, unless we're already working or inside
				-- a batch. This is intentionally inside scheduleUpdateOnFiber instead of
				-- scheduleCallbackForFiber to preserve the ability to schedule a callback
				-- without immediately flushing it. We only do this for user-initiated
				-- updates, to preserve historical behavior of legacy mode.
				resetRenderTimer()
				flushSyncCallbackQueue()
			end
		end
	else
		-- Schedule a discrete update but only if it's not Sync.
		if
			bit32.band(executionContext, DiscreteEventContext) ~= NoContext
			-- Only updates at user-blocking priority or greater are considered
			-- discrete, even inside a discrete event.
			and (
				priorityLevel == UserBlockingSchedulerPriority
				or priorityLevel == ImmediateSchedulerPriority
			)
		then
			-- This is the result of a discrete event. Track the lowest priority
			-- discrete update per root so we can flush them early, if needed.
			if rootsWithPendingDiscreteUpdates == nil then
				rootsWithPendingDiscreteUpdates = Set.new({ root })
			else
				rootsWithPendingDiscreteUpdates:add(root)
			end
		end
		-- Schedule other updates after in case the callback is sync.
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, lane)
	end

	-- We use this when assigning a lane for a transition inside
	-- `requestUpdateLane`. We assume it's the same as the root being updated,
	-- since in the common case of a single root app it probably is. If it's not
	-- the same root, then it's not a huge deal, we just might batch more stuff
	-- together more than necessary.
	mostRecentlyUpdatedRoot = root
	return root
end

-- This is split into a separate function so we can mark a fiber with pending
-- work without treating it as a typical update that originates from an event
-- e.g. retrying a Suspense boundary isn't an update, but it does schedule work
-- on a fiber.
mod.markUpdateLaneFromFiberToRoot = function(sourceFiber: Fiber, lane: Lane): FiberRoot?
	-- Update the source fiber's lanes
	sourceFiber.lanes = mergeLanes(sourceFiber.lanes, lane)
	local alternate = sourceFiber.alternate
	if alternate ~= nil then
		alternate.lanes = mergeLanes(alternate.lanes, lane)
	end
	if __DEV__ then
		if
			alternate == nil
			and bit32.band(
					sourceFiber.flags,
					bit32.bor(ReactFiberFlags.Placement, ReactFiberFlags.Hydrating)
				)
				~= ReactFiberFlags.NoFlags
		then
			mod.warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
		end
	end
	-- Walk the parent path to the root and update the child expiration time.
	local node = sourceFiber
	local parent = sourceFiber.return_
	while parent ~= nil do
		parent.childLanes = mergeLanes(parent.childLanes, lane)
		alternate = parent.alternate
		if alternate ~= nil then
			alternate.childLanes = mergeLanes(alternate.childLanes, lane)
		else
			if __DEV__ then
				if
					bit32.band(
						parent.flags,
						bit32.bor(ReactFiberFlags.Placement, ReactFiberFlags.Hydrating)
					) ~= ReactFiberFlags.NoFlags
				then
					mod.warnAboutUpdateOnNotYetMountedFiberInDEV(sourceFiber)
				end
			end
		end
		node = parent
		parent = parent.return_
	end
	if node.tag == ReactWorkTags.HostRoot then
		local root: FiberRoot = node.stateNode
		return root
	else
		return nil
	end
end

-- Use this function to schedule a task for a root. There's only one task per
-- root; if a task was already scheduled, we'll check to make sure the priority
-- of the existing task is the same as the priority of the next level that the
-- root has work on. This function is called on every update, and right before
-- exiting a task.
ensureRootIsScheduled = function(root: FiberRoot, currentTime: number)
	local existingCallbackNode = root.callbackNode

	-- Check if any lanes are being starved by other work. If so, mark them as
	-- expired so we know to work on those next.
	markStarvedLanesAsExpired(root, currentTime)

	-- Determine the next lanes to work on, and their priority.
	local lanes
	if root == workInProgressRoot then
		lanes = workInProgressRootRenderLanes
	else
		lanes = ReactFiberLane.NoLanes
	end
	local nextLanes = getNextLanes(root, lanes)
	-- This returns the priority level computed during the `getNextLanes` call.
	local newCallbackPriority = returnNextLanesPriority()

	if nextLanes == ReactFiberLane.NoLanes then
		-- Special case: There's nothing to work on.
		if existingCallbackNode ~= nil then
			cancelCallback(existingCallbackNode)
			root.callbackNode = nil
			root.callbackPriority = ReactFiberLane.NoLanePriority
		end
		return
	end

	-- Check if there's an existing task. We may be able to reuse it.
	if existingCallbackNode ~= nil then
		local existingCallbackPriority = root.callbackPriority
		if existingCallbackPriority == newCallbackPriority then
			-- The priority hasn't changed. We can reuse the existing task. Exit.
			return
		end
		-- The priority changed. Cancel the existing callback. We'll schedule a new
		-- one below.
		cancelCallback(existingCallbackNode)
	end

	-- Schedule a new callback.
	local newCallbackNode
	if newCallbackPriority == ReactFiberLane.SyncLanePriority then
		-- Special case: Sync React callbacks are scheduled on a special
		-- internal queue
		newCallbackNode = scheduleSyncCallback(function()
			return mod.performSyncWorkOnRoot(root)
		end)
	elseif newCallbackPriority == ReactFiberLane.SyncBatchedLanePriority then
		newCallbackNode = scheduleCallback(ImmediateSchedulerPriority, function()
			return mod.performSyncWorkOnRoot(root)
		end)
	else
		local schedulerPriorityLevel =
			lanePriorityToSchedulerPriority(newCallbackPriority)
		newCallbackNode = scheduleCallback(schedulerPriorityLevel, function()
			return mod.performConcurrentWorkOnRoot(root)
		end)
	end

	root.callbackPriority = newCallbackPriority
	root.callbackNode = newCallbackNode
end

-- This is the entry point for every concurrent task, i.e. anything that
-- goes through Scheduler.
-- ROBLOX Luau FIXME: Luau needs explicit annotation with nil-able returns
mod.performConcurrentWorkOnRoot = function(root): (() -> ...any) | nil
	-- Since we know we're in a React event, we can clear the current
	-- event time. The next update will compute a new event time.
	currentEventTime = NoTimestamp
	currentEventWipLanes = ReactFiberLane.NoLanes
	currentEventPendingLanes = ReactFiberLane.NoLanes

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	-- Flush any pending passive effects before deciding which lanes to work on,
	-- in case they schedule additional work.
	local originalCallbackNode = root.callbackNode
	local didFlushPassiveEffects = exports.flushPassiveEffects()
	if didFlushPassiveEffects then
		-- Something in the passive effect phase may have canceled the current task.
		-- Check if the task node for this root was changed.
		if root.callbackNode ~= originalCallbackNode then
			-- The current task was canceled. Exit. We don't need to call
			-- `ensureRootIsScheduled` because the check above implies either that
			-- there's a new task, or that there's no remaining work on this root.
			return nil
		else
			-- Current task was not canceled. Continue.
		end
	end

	-- Determine the next expiration time to work on, using the fields stored
	-- on the root.
	local lanes = getNextLanes(
		root,
		if root == workInProgressRoot
			then workInProgressRootRenderLanes
			else ReactFiberLane.NoLanes
	)
	if lanes == ReactFiberLane.NoLanes then
		-- Defensive coding. This is never expected to happen.
		return nil
	end

	local exitStatus = mod.renderRootConcurrent(root, lanes)

	if
		includesSomeLane(workInProgressRootIncludedLanes, workInProgressRootUpdatedLanes)
	then
		-- The render included lanes that were updated during the render phase.
		-- For example, when unhiding a hidden tree, we include all the lanes
		-- that were previously skipped when the tree was hidden. That set of
		-- lanes is a superset of the lanes we started rendering with.
		--
		-- So we'll throw out the current work and restart.
		mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
	elseif exitStatus ~= RootExitStatus.Incomplete then
		if exitStatus == RootExitStatus.Errored then
			executionContext = bit32.bor(executionContext, RetryAfterError)

			-- If an error occurred during hydration,
			-- discard server response and fall back to client side render.
			if root.hydrate then
				root.hydrate = false
				ReactFiberHostConfig.clearContainer(root.containerInfo)
			end

			-- If something threw an error, try rendering one more time. We'll render
			-- synchronously to block concurrent data mutations, and we'll includes
			-- all pending updates are included. If it still fails after the second
			-- attempt, we'll give up and commit the resulting tree.
			lanes = getLanesToRetrySynchronouslyOnError(root)
			if lanes ~= ReactFiberLane.NoLanes then
				exitStatus = mod.renderRootSync(root, lanes)
			end
		end

		if exitStatus == RootExitStatus.FatalErrored then
			local fatalError = workInProgressRootFatalError
			mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
			mod.markRootSuspended(root, lanes)
			ensureRootIsScheduled(root, now())
			error(fatalError)
		end

		-- We now have a consistent tree. The next step is either to commit it,
		-- or, if something suspended, wait to commit it after a timeout.
		local finishedWork: Fiber = root.current.alternate :: any
		root.finishedWork = finishedWork
		root.finishedLanes = lanes
		mod.finishConcurrentRender(root, exitStatus, lanes)
	end

	ensureRootIsScheduled(root, now())
	if root.callbackNode == originalCallbackNode then
		-- The task node scheduled for this root is the same one that's
		-- currently executed. Need to return a continuation.
		return function()
			return mod.performConcurrentWorkOnRoot(root)
		end
	end
	-- ROBLOX Luau FIXME: Luau shouldn't error on nil-able returns
	return nil :: any
end

-- we track the 'depth' of the act() calls with this counter,
-- so we can tell if any async act() calls try to run in parallel.
local actingUpdatesScopeDepth = 0
local didWarnAboutUsingActInProd = false

function shouldForceFlushFallbacksInDEV()
	-- Never force flush in production. This function should get stripped out.
	return __DEV__ and actingUpdatesScopeDepth > 0
end

mod.finishConcurrentRender = function(root, exitStatus, lanes)
	if
		exitStatus == RootExitStatus.Incomplete
		or exitStatus == RootExitStatus.FatalErrored
	then
		invariant(false, "Root did not complete. This is a bug in React.")
	-- Flow knows about invariant, so it complains if I add a break
	-- if I do. eslint-disable-next-line no-fallthrough
	-- statement, but eslint doesn't know about invariant, so it complains
	elseif exitStatus == RootExitStatus.Errored then
		-- We should have already attempted to retry this tree. If we reached
		-- this point, it errored again. Commit it.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.Suspended then
		mod.markRootSuspended(root, lanes)

		-- We have an acceptable loading state. We need to figure out if we
		-- should immediately commit it or wait a bit.
		if
			includesOnlyRetries(lanes)
			-- do not delay if we're inside an act() scope
			and not shouldForceFlushFallbacksInDEV()
		then
			-- This render only included retries, no updates. Throttle committing
			-- retries so that we don't show too many loading states too quickly.
			local msUntilTimeout = globalMostRecentFallbackTime
				+ FALLBACK_THROTTLE_MS
				- now()
			-- Don't bother with a very short suspense time.
			if msUntilTimeout > 10 then
				local nextLanes = getNextLanes(root, ReactFiberLane.NoLanes)
				if nextLanes ~= ReactFiberLane.NoLanes then
					-- There's additional work on this root.
					return
				end
				local suspendedLanes = root.suspendedLanes
				if not isSubsetOfLanes(suspendedLanes, lanes) then
					-- We should prefer to render the fallback of at the last
					-- suspended level. Ping the last suspended level to try
					-- rendering it again.
					-- FIXME: What if the suspended lanes are Idle? Should not restart.
					local eventTime = exports.requestEventTime()
					markRootPinged(root, suspendedLanes, eventTime)
					return
				end

				-- The render is suspended, it hasn't timed out, and there's no
				-- lower priority work to do. Instead of committing the fallback
				-- immediately, wait for more data to arrive.
				root.timeoutHandle = ReactFiberHostConfig.scheduleTimeout(function()
					return mod.commitRoot(root)
				end, msUntilTimeout)
				return
			end
		end
		-- The work expired. Commit immediately.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.SuspendedWithDelay then
		mod.markRootSuspended(root, lanes)

		if includesOnlyTransitions(lanes) then
			-- This is a transition, so we should exit without committing a
			-- placeholder and without scheduling a timeout. Delay indefinitely
			-- until we receive more data.
			return
		end

		if not shouldForceFlushFallbacksInDEV() then
			-- This is not a transition, but we did trigger an avoided state.
			-- Schedule a placeholder to display after a short delay, using the Just
			-- Noticeable Difference.
			-- TODO: Is the JND optimization worth the added complexity? If this is
			-- the only reason we track the event time, then probably not.
			-- Consider removing.

			local mostRecentEventTime = getMostRecentEventTime(root, lanes)
			local eventTimeMs = mostRecentEventTime
			local timeElapsedMs = now() - eventTimeMs
			local msUntilTimeout = jnd(timeElapsedMs) - timeElapsedMs

			-- Don't bother with a very short suspense time.
			if msUntilTimeout > 10 then
				-- Instead of committing the fallback immediately, wait for more data
				-- to arrive.
				root.timeoutHandle = ReactFiberHostConfig.scheduleTimeout(function()
					return mod.commitRoot(root)
				end, msUntilTimeout)
				return
			end
		end
		-- Commit the placeholder.
		mod.commitRoot(root)
	elseif exitStatus == RootExitStatus.Completed then
		-- The work completed. Ready to commit.
		mod.commitRoot(root)
	else
		invariant(false, "Unknown root exit status.")
	end
end

mod.markRootSuspended = function(root, suspendedLanes)
	-- When suspending, we should always exclude lanes that were pinged or (more
	-- rarely, since we try to avoid it) updated during the render phase.
	-- TODO: Lol maybe there's a better way to factor this besides this
	-- obnoxiously named function :)
	suspendedLanes = removeLanes(suspendedLanes, workInProgressRootPingedLanes)
	suspendedLanes = removeLanes(suspendedLanes, workInProgressRootUpdatedLanes)
	markRootSuspended_dontCallThisOneDirectly(root, suspendedLanes)
end

-- This is the entry point for synchronous tasks that don't go
-- through Scheduler
mod.performSyncWorkOnRoot = function(root)
	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	exports.flushPassiveEffects()

	local lanes
	local exitStatus
	if
		root == workInProgressRoot
		and includesSomeLane(root.expiredLanes, workInProgressRootRenderLanes)
	then
		-- There's a partial tree, and at least one of its lanes has expired. Finish
		-- rendering it before rendering the rest of the expired work.
		lanes = workInProgressRootRenderLanes
		exitStatus = mod.renderRootSync(root, lanes)
		if
			includesSomeLane(
				workInProgressRootIncludedLanes,
				workInProgressRootUpdatedLanes
			)
		then
			-- The render included lanes that were updated during the render phase.
			-- For example, when unhiding a hidden tree, we include all the lanes
			-- that were previously skipped when the tree was hidden. That set of
			-- lanes is a superset of the lanes we started rendering with.
			--
			-- Note that this only happens when part of the tree is rendered
			-- concurrently. If the whole tree is rendered synchronously, then there
			-- are no interleaved events.
			lanes = getNextLanes(root, lanes)
			exitStatus = mod.renderRootSync(root, lanes)
		end
	else
		lanes = getNextLanes(root, ReactFiberLane.NoLanes)
		exitStatus = mod.renderRootSync(root, lanes)
	end

	if root.tag ~= LegacyRoot and exitStatus == RootExitStatus.Errored then
		executionContext = bit32.bor(executionContext, RetryAfterError)

		-- If an error occurred during hydration,
		-- discard server response and fall back to client side render.
		if root.hydrate then
			root.hydrate = false
			ReactFiberHostConfig.clearContainer(root.containerInfo)
		end

		-- If something threw an error, try rendering one more time. We'll render
		-- synchronously to block concurrent data mutations, and we'll includes
		-- all pending updates are included. If it still fails after the second
		-- attempt, we'll give up and commit the resulting tree.
		lanes = getLanesToRetrySynchronouslyOnError(root)
		if lanes ~= ReactFiberLane.NoLanes then
			exitStatus = mod.renderRootSync(root, lanes)
		end
	end

	if exitStatus == RootExitStatus.FatalErrored then
		local fatalError = workInProgressRootFatalError
		mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
		mod.markRootSuspended(root, lanes)
		ensureRootIsScheduled(root, now())
		error(fatalError)
	end

	-- We now have a consistent tree. Because this is a sync render, we
	-- will commit it even if something suspended.
	local finishedWork: Fiber = root.current.alternate :: any
	root.finishedWork = finishedWork
	root.finishedLanes = lanes
	mod.commitRoot(root)

	-- Before exiting, make sure there's a callback scheduled for the next
	-- pending level.
	ensureRootIsScheduled(root, now())

	return nil
end

exports.flushRoot = function(root: FiberRoot, lanes: Lanes)
	markRootExpired(root, lanes)
	ensureRootIsScheduled(root, now())
	if
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext))
		== NoContext
	then
		resetRenderTimer()
		flushSyncCallbackQueue()
	end
end

exports.getExecutionContext = function(): ExecutionContext
	return executionContext
end

exports.flushDiscreteUpdates = function()
	-- TODO: Should be able to flush inside batchedUpdates, but not inside `act`.
	-- However, `act` uses `batchedUpdates`, so there's no way to distinguish
	-- those two cases. Need to fix this before exposing flushDiscreteUpdates
	-- as a public API.
	if
		bit32.band(
			executionContext,
			bit32.bor(BatchedContext, RenderContext, CommitContext)
		) ~= NoContext
	then
		if __DEV__ then
			if bit32.band(executionContext, RenderContext) ~= NoContext then
				console.error(
					"unstable_flushDiscreteUpdates: Cannot flush updates when React is "
						.. "already rendering."
				)
			end
		end
		-- We're already rendering, so we can't synchronously flush pending work.s
		-- This is probably a nested event dispatch triggered by a lifecycle/effect,
		-- like `el.focus()`. Exit.
		return
	end
	mod.flushPendingDiscreteUpdates()
	-- If the discrete updates scheduled passive effects, flush them now so that
	-- they fire before the next serial event.
	exports.flushPassiveEffects()
end

exports.deferredUpdates = function<A>(fn: () -> A): A
	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			-- ROBLOX performance: hoist non-throwable out of try{} to eliminate anon function
			setCurrentUpdateLanePriority(ReactFiberLane.DefaultLanePriority)
			ok, result =
				xpcall(runWithPriority, describeError, NormalSchedulerPriority, fn)
		else
			ok = true
			setCurrentUpdateLanePriority(ReactFiberLane.DefaultLanePriority)
			result = runWithPriority(NormalSchedulerPriority, fn)
		end

		-- finally
		setCurrentUpdateLanePriority(previousLanePriority)

		if ok then
			return result
		else
			error(result)
		end
	else
		return runWithPriority(NormalSchedulerPriority, fn)
	end
end

mod.flushPendingDiscreteUpdates = function()
	if rootsWithPendingDiscreteUpdates ~= nil then
		-- For each root with pending discrete updates, schedule a callback to
		-- immediately flush them.
		local roots = rootsWithPendingDiscreteUpdates
		rootsWithPendingDiscreteUpdates = nil
		roots:forEach(function(root)
			markDiscreteUpdatesExpired(root)
			ensureRootIsScheduled(root, now())
		end)
	end
	-- Now flush the immediate queue.
	flushSyncCallbackQueue()
end

exports.batchedUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, BatchedContext)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.batchedEventUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, EventContext)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.discreteUpdates =
	function<A, B, C, D, R>(fn: (A, B, C, D) -> R, a: A, b: B, c: C, d: D): R
		local prevExecutionContext = executionContext
		executionContext = bit32.bor(executionContext, DiscreteEventContext)

		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()
			-- ROBLOX performance: extract non-throwable fn call out of try{} so we can remove an anon function
			setCurrentUpdateLanePriority(ReactFiberLane.InputDiscreteLanePriority)
			local ok, result = xpcall(
				runWithPriority,
				describeError,
				UserBlockingSchedulerPriority,
				function()
					return fn(a, b, c, d)
				end
			)

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)
			executionContext = prevExecutionContext
			if executionContext == NoContext then
				-- Flush the immediate callbacks that were scheduled during this batch
				resetRenderTimer()
				flushSyncCallbackQueue()
			end

			if ok then
				return result
			else
				error(result)
			end
		else
			local ok, result = xpcall(
				runWithPriority,
				describeError,
				UserBlockingSchedulerPriority,
				function()
					return fn(a, b, c, d)
				end
			)

			-- finally
			executionContext = prevExecutionContext
			if executionContext == NoContext then
				-- Flush the immediate callbacks that were scheduled during this batch
				resetRenderTimer()
				flushSyncCallbackQueue()
			end

			if ok then
				return result
			else
				error(result)
			end
		end
	end

exports.unbatchedUpdates = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	executionContext = bit32.band(executionContext, bit32.bnot(BatchedContext))
	executionContext = bit32.bor(executionContext, LegacyUnbatchedContext)
	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not __YOLO__ then
		ok, result = xpcall(fn, describeError, a)
	else
		ok = true
		result = fn(a)
	end

	-- finally
	executionContext = prevExecutionContext
	if executionContext == NoContext then
		-- Flush the immediate callbacks that were scheduled during this batch
		resetRenderTimer()
		flushSyncCallbackQueue()
	end

	if ok then
		return result
	else
		error(result)
	end
end

exports.flushSync = function<A, R>(fn: (A) -> R, a: A): R
	local prevExecutionContext = executionContext
	if
		(bit32.band(prevExecutionContext, bit32.bor(RenderContext, CommitContext)))
		~= NoContext
	then
		if __DEV__ then
			console.error(
				"flushSync was called from inside a lifecycle method. React cannot "
					.. "flush when React is already rendering. Consider moving this call to "
					.. "a scheduler task or micro task."
			)
		end
		return fn(a)
	end
	executionContext = bit32.bor(executionContext, BatchedContext)

	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()

		-- ROBLOX performance: extract non-throwable call out of try{} to eliminate an anon function
		setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			if fn then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediateSchedulerPriority,
					function()
						return fn(a)
					end
				)
			else
				ok = true
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		else
			ok = true
			setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
			if fn then
				result = runWithPriority(ImmediateSchedulerPriority, function()
					return fn(a)
				end)
			else
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		end

		-- ROBLOX finally
		setCurrentUpdateLanePriority(previousLanePriority)
		executionContext = prevExecutionContext
		-- Flush the immediate callbacks that were scheduled during this batch.
		-- Note that this will happen even if batchedUpdates is higher up
		-- the stack.
		flushSyncCallbackQueue()

		if not ok then
			error(result)
		end
		return result
	else
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not __YOLO__ then
			if fn then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediateSchedulerPriority,
					function()
						return fn(a)
					end
				)
			else
				ok = true
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		else
			ok = true
			if fn then
				result = runWithPriority(ImmediateSchedulerPriority, function()
					return fn(a)
				end)
			else
				-- ROBLOX note: return (undefined: $FlowFixMe)
				result = nil :: any
			end
		end
		-- ROBLOX: finally
		executionContext = prevExecutionContext
		-- Flush the immediate callbacks that were scheduled during this batch.
		-- Note that this will happen even if batchedUpdates is higher up
		-- the stack.
		flushSyncCallbackQueue()
		if not ok then
			error(result)
		end
		return result
	end
end

exports.flushControlled = function(fn: () -> any)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, BatchedContext)
	if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
		local previousLanePriority = getCurrentUpdateLanePriority()
		-- ROBLOX performance: extract non-throwable call out of try{} to eliminate an anon function
		setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		local ok, result =
			xpcall(runWithPriority, describeError, ImmediateSchedulerPriority, fn)

		-- finally
		setCurrentUpdateLanePriority(previousLanePriority)

		executionContext = prevExecutionContext
		if executionContext == NoContext then
			-- Flush the immediate callbacks that were scheduled during this batch
			resetRenderTimer()
			flushSyncCallbackQueue()
		end

		if not ok then
			error(result)
		end
	else
		local ok, result =
			xpcall(runWithPriority, describeError, ImmediateSchedulerPriority, fn)
		-- finally
		executionContext = prevExecutionContext
		if executionContext == NoContext then
			-- Flush the immediate callbacks that were scheduled during this batch
			resetRenderTimer()
			flushSyncCallbackQueue()
		end

		if not ok then
			error(result)
		end
	end
end

exports.pushRenderLanes = function(fiber: Fiber, lanes: Lanes)
	pushToStack(subtreeRenderLanesCursor, exports.subtreeRenderLanes, fiber)
	exports.subtreeRenderLanes = mergeLanes(exports.subtreeRenderLanes, lanes)
	workInProgressRootIncludedLanes = mergeLanes(workInProgressRootIncludedLanes, lanes)
end

exports.popRenderLanes = function(fiber: Fiber)
	exports.subtreeRenderLanes = subtreeRenderLanesCursor.current
	popFromStack(subtreeRenderLanesCursor, fiber)
end

mod.prepareFreshStack = function(root: FiberRoot, lanes: Lanes)
	root.finishedWork = nil
	root.finishedLanes = ReactFiberLane.NoLanes

	local timeoutHandle = root.timeoutHandle
	if timeoutHandle ~= ReactFiberHostConfig.noTimeout then
		-- The root previous suspended and scheduled a timeout to commit a fallback
		-- state. Now that we have additional work, cancel the timeout.
		root.timeoutHandle = ReactFiberHostConfig.noTimeout
		-- $FlowFixMe Complains noTimeout is not a TimeoutID, despite the check above
		ReactFiberHostConfig.cancelTimeout(timeoutHandle)
	end

	if workInProgress ~= nil then
		local interruptedWork = workInProgress.return_
		while interruptedWork ~= nil do
			unwindInterruptedWork(interruptedWork)
			interruptedWork = interruptedWork.return_
		end
	end
	workInProgressRoot = root
	workInProgress = ReactFiber.createWorkInProgress(root.current, nil)
	workInProgressRootRenderLanes = lanes
	exports.subtreeRenderLanes = lanes
	workInProgressRootIncludedLanes = lanes
	workInProgressRootExitStatus = RootExitStatus.Incomplete
	workInProgressRootFatalError = nil
	workInProgressRootSkippedLanes(ReactFiberLane.NoLanes)
	workInProgressRootUpdatedLanes = ReactFiberLane.NoLanes
	workInProgressRootPingedLanes = ReactFiberLane.NoLanes

	if ReactFeatureFlags.enableSchedulerTracing then
		spawnedWorkDuringRender = nil
	end

	if __DEV__ then
		ReactStrictModeWarnings.discardPendingWarnings()
	end
end

mod.handleError = function(root, thrownValue): ()
	while true do
		local erroredWork = workInProgress
		-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
		local ok, yetAnotherThrownValue = pcall(function()
			-- Reset module-level state that was set during the render phase.
			resetContextDependencies()
			resetHooksAfterThrow()
			resetCurrentDebugFiberInDEV()
			-- TODO: I found and added this missing line while investigating a
			-- separate issue. Write a regression test using string refs.
			ReactCurrentOwner.current = nil

			if erroredWork == nil or erroredWork.return_ == nil then
				-- Expected to be working on a non-root fiber. This is a fatal error
				-- because there's no ancestor that can handle it; the root is
				-- supposed to capture all errors that weren't caught by an error
				-- boundary.
				workInProgressRootExitStatus = RootExitStatus.FatalErrored
				workInProgressRootFatalError = thrownValue
				-- Set `workInProgress` to nil. This represents advancing to the next
				-- sibling, or the parent if there are no siblings. But since the root
				-- has no siblings nor a parent, we set it to nil. Usually this is
				-- handled by `completeUnitOfWork` or `unwindWork`, but since we're
				-- intentionally not calling those, we need set it here.
				-- TODO: Consider calling `unwindWork` to pop the contexts.
				workInProgress = nil
				-- ROBLOX FIXME: THIS IS A BUG, WE SHOULD BAIL ON THE OUTER FUNCTION -- NOT THE PCALL!
				return
			end

			-- ROBLOX Luau FIXME: Luau doesn't narrow based on the erroredWork == nil then return above
			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(
						(erroredWork :: Fiber).mode,
						ReactTypeOfMode.ProfileMode
					)
					~= 0
			then
				-- Record the time spent rendering before an error was thrown. This
				-- avoids inaccurate Profiler durations in the case of a
				-- suspended render.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					erroredWork :: Fiber,
					true
				)
			end

			-- ROBLOX deviation, we pass in onUncaughtError and renderDidError here since throwException can't call them due to a require cycle
			throwException(
				root,
				(erroredWork :: Fiber).return_,
				erroredWork :: Fiber,
				thrownValue,
				workInProgressRootRenderLanes,
				exports.onUncaughtError,
				exports.renderDidError
			)
			mod.completeUnitOfWork(erroredWork)
		end)
		if not ok then
			-- Something in the return path also threw.
			thrownValue = yetAnotherThrownValue
			if workInProgress == erroredWork and erroredWork ~= nil then
				-- If this boundary has already errored, then we had trouble processing
				-- the error. Bubble it to the next boundary.
				erroredWork = erroredWork.return_
				workInProgress = erroredWork
			else
				erroredWork = workInProgress
			end
			continue
		end
		-- Return to the normal work loop.
		return
	end
end

mod.pushDispatcher = function()
	local prevDispatcher = ReactCurrentDispatcher.current

	-- ROBLOX deviation: lazy init of ContextOnlyDispatcher wrapped in a function
	ReactCurrentDispatcher.current = ContextOnlyDispatcher()
	if prevDispatcher == nil then
		-- The React isomorphic package does not include a default dispatcher.
		-- Instead the first renderer will lazily attach one, in order to give
		-- nicer error messages.

		-- ROBLOX deviation: lazy init of ContextOnlyDispatcher wrapped in a function
		return ContextOnlyDispatcher()
	else
		return prevDispatcher
	end
end

mod.popDispatcher = function(prevDispatcher)
	ReactCurrentDispatcher.current = prevDispatcher
end

mod.pushInteractions = function(root)
	if ReactFeatureFlags.enableSchedulerTracing then
		local prevInteractions: Set<Interaction>? = __interactionsRef.current
		__interactionsRef.current = root.memoizedInteractions
		return prevInteractions
	end
	return nil
end

mod.popInteractions = function(prevInteractions)
	if ReactFeatureFlags.enableSchedulerTracing then
		__interactionsRef.current = prevInteractions
	end
end

exports.markCommitTimeOfFallback = function(): ()
	globalMostRecentFallbackTime = now()
end

exports.markSkippedUpdateLanes = function(lane: Lane | Lanes): ()
	ReactFiberWorkInProgress.markSkippedUpdateLanes(lane)
end

exports.renderDidSuspend = function(): ()
	if workInProgressRootExitStatus == RootExitStatus.Incomplete then
		workInProgressRootExitStatus = RootExitStatus.Suspended
	end
end

exports.renderDidSuspendDelayIfPossible = function(): ()
	if
		workInProgressRootExitStatus == RootExitStatus.Incomplete
		or workInProgressRootExitStatus == RootExitStatus.Suspended
	then
		workInProgressRootExitStatus = RootExitStatus.SuspendedWithDelay
	end

	-- Check if there are updates that we skipped tree that might have unblocked
	-- this render.
	if
		workInProgressRoot ~= nil
		and (
			includesNonIdleWork(workInProgressRootSkippedLanes())
			or includesNonIdleWork(workInProgressRootUpdatedLanes)
		)
	then
		-- Mark the current render as suspended so that we switch to working on
		-- the updates that were skipped. Usually we only suspend at the end of
		-- the render phase.
		-- TODO: We should probably always mark the root as suspended immediately
		-- (inside this function), since by suspending at the end of the render
		-- phase introduces a potential mistake where we suspend lanes that were
		-- pinged or updated while we were rendering.
		mod.markRootSuspended(workInProgressRoot, workInProgressRootRenderLanes)
	end
end

exports.renderDidError = function()
	if workInProgressRootExitStatus ~= RootExitStatus.Completed then
		workInProgressRootExitStatus = RootExitStatus.Errored
	end
end

-- Called during render to determine if anything has suspended.
-- Returns false if we're not sure.
exports.renderHasNotSuspendedYet = function(): boolean
	-- If something errored or completed, we can't really be sure,
	-- so those are false.
	return workInProgressRootExitStatus == RootExitStatus.Incomplete
end

mod.renderRootSync = function(root: FiberRoot, lanes: Lanes)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, RenderContext)
	local prevDispatcher = mod.pushDispatcher()

	-- If the root or lanes have changed, throw out the existing stack
	-- and prepare a fresh one. Otherwise we'll continue where we left off.
	if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes then
		mod.prepareFreshStack(root, lanes)
		mod.startWorkOnPendingInteractions(root, lanes)
	end

	local prevInteractions = mod.pushInteractions(root)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStarted(lanes)
	end

	while true do
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, thrownValue
		if not __YOLO__ then
			ok, thrownValue = xpcall(mod.workLoopSync, describeError)
		else
			ok = true
			mod.workLoopSync()
		end

		if not ok then
			mod.handleError(root, thrownValue)
		else
			break
		end
	end
	resetContextDependencies()
	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
	end

	executionContext = prevExecutionContext
	mod.popDispatcher(prevDispatcher)

	if workInProgress ~= nil then
		-- This is a sync render, so we should have finished the whole tree.
		invariant(
			false,
			"Cannot commit an incomplete root. This error is likely caused by a "
				.. "bug in React. Please file an issue."
		)
	end

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStopped()
	end

	-- Set this to nil to indicate there's no in-progress render.
	workInProgressRoot = nil
	workInProgressRootRenderLanes = ReactFiberLane.NoLanes

	return workInProgressRootExitStatus
end

-- The work loop is an extremely hot path. Tell Closure not to inline it.
--[[* @noinline ]]
mod.workLoopSync = function()
	-- Already timed out, so perform work without checking if we need to yield.
	while workInProgress ~= nil do
		mod.performUnitOfWork(workInProgress)
	end
end

mod.renderRootConcurrent = function(root: FiberRoot, lanes: Lanes)
	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, RenderContext)
	local prevDispatcher = mod.pushDispatcher()

	-- If the root or lanes have changed, throw out the existing stack
	-- and prepare a fresh one. Otherwise we'll continue where we left off.
	if workInProgressRoot ~= root or workInProgressRootRenderLanes ~= lanes then
		resetRenderTimer()
		mod.prepareFreshStack(root, lanes)
		mod.startWorkOnPendingInteractions(root, lanes)
	end

	local prevInteractions = mod.pushInteractions(root)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markRenderStarted(lanes)
	end

	while true do
		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, thrownValue
		if not __YOLO__ then
			-- ROBLOX deviation: when converting `try` to `pcall`, we can't use break inside it
			ok, thrownValue = xpcall(mod.workLoopConcurrent, describeError)
			if ok then
				thrownValue = "break"
			end
		else
			ok = true
			thrownValue = "break"
			mod.workLoopConcurrent()
		end

		if thrownValue == "break" then
			break
		end
		if not ok then
			mod.handleError(root, thrownValue)
		end
	end
	resetContextDependencies()
	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
	end

	mod.popDispatcher(prevDispatcher)
	executionContext = prevExecutionContext

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logRenderStopped()
		end
	end

	-- Check if the tree has completed.
	if workInProgress ~= nil then
		-- Still work remaining.
		if enableSchedulingProfiler then
			SchedulingProfiler.markRenderYielded()
		end
		return RootExitStatus.Incomplete
	else
		-- Completed the tree.
		if enableSchedulingProfiler then
			SchedulingProfiler.markRenderStopped()
		end

		-- Set this to nil to indicate there's no in-progress render.
		workInProgressRoot = nil
		workInProgressRootRenderLanes = ReactFiberLane.NoLanes

		-- Return the final exit status.
		return workInProgressRootExitStatus
	end
end

--[[* @noinline ]]
mod.workLoopConcurrent = function()
	-- Perform work until Scheduler asks us to yield
	while workInProgress ~= nil and not shouldYield() do
		mod.performUnitOfWork(workInProgress)
	end
end

mod.performUnitOfWork = function(unitOfWork: Fiber): ()
	-- The current, flushed, state of this fiber is the alternate. Ideally
	-- nothing should rely on this, but relying on it here means that we don't
	-- need an additional field on the work in progress.
	local current = unitOfWork.alternate
	setCurrentDebugFiberInDEV(unitOfWork)

	local next_
	if
		ReactFeatureFlags.enableProfilerTimer
		and bit32.band(unitOfWork.mode, ReactTypeOfMode.ProfileMode)
			~= ReactTypeOfMode.NoMode
	then
		ReactProfilerTimer.startProfilerTimer(unitOfWork)
		next_ = mod.beginWork(current, unitOfWork, exports.subtreeRenderLanes)
		ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(unitOfWork, true)
	else
		next_ = mod.beginWork(current, unitOfWork, exports.subtreeRenderLanes)
	end

	resetCurrentDebugFiberInDEV()
	unitOfWork.memoizedProps = unitOfWork.pendingProps
	if next_ == nil then
		-- If this doesn't spawn new work, complete the current work.
		mod.completeUnitOfWork(unitOfWork)
	else
		workInProgress = next_
	end

	ReactCurrentOwner.current = nil
end

mod.completeUnitOfWork = function(unitOfWork: Fiber)
	-- Attempt to complete the current unit of work, then move to the next
	-- sibling. If there are no more siblings, return to the parent fiber.
	local completedWork = unitOfWork
	repeat
		-- The current, flushed, state of this fiber is the alternate. Ideally
		-- nothing should rely on this, but relying on it here means that we don't
		-- need an additional field on the work in progress.
		local current = completedWork.alternate
		local returnFiber = completedWork.return_

		-- Check if the work completed or if something threw.
		if
			bit32.band(completedWork.flags, ReactFiberFlags.Incomplete)
			== ReactFiberFlags.NoFlags
		then
			setCurrentDebugFiberInDEV(completedWork)
			local next_
			if
				not ReactFeatureFlags.enableProfilerTimer
				or bit32.band(completedWork.mode, ReactTypeOfMode.ProfileMode)
					== ReactTypeOfMode.NoMode
			then
				next_ = completeWork(current, completedWork, exports.subtreeRenderLanes)
			else
				ReactProfilerTimer.startProfilerTimer(completedWork)
				next_ = completeWork(current, completedWork, exports.subtreeRenderLanes)
				-- Update render duration assuming we didn't error.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					completedWork,
					false
				)
			end
			resetCurrentDebugFiberInDEV()

			if next_ ~= nil then
				-- Completing this fiber spawned new work. Work on that next.
				workInProgress = next_
				return
			end
		else
			-- This fiber did not complete because something threw. Pop values off
			-- the stack without entering the complete phase. If this is a boundary,
			-- capture values if possible.
			local next_ = unwindWork(completedWork, exports.subtreeRenderLanes)

			-- Because this fiber did not complete, don't reset its expiration time.

			if next_ ~= nil then
				-- If completing this work spawned new work, do that next. We'll come
				-- back here again.
				-- Since we're restarting, remove anything that is not a host effect
				-- from the effect tag.
				next_.flags = bit32.band(next_.flags, ReactFiberFlags.HostEffectMask)
				workInProgress = next_
				return
			end

			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(completedWork.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
			then
				-- Record the render duration for the fiber that errored.
				ReactProfilerTimer.stopProfilerTimerIfRunningAndRecordDelta(
					completedWork,
					false
				)

				-- Include the time spent working on failed children before continuing.
				-- ROBLOX TODO: actualDuration is nil-able and only populated with enableProfilerTimer. contribute default value upstream.
				local actualDuration = completedWork.actualDuration or 0
				local child = completedWork.child
				while child ~= nil do
					actualDuration += child.actualDuration or 0
					child = child.sibling
				end
				completedWork.actualDuration = actualDuration
			end

			if returnFiber ~= nil then
				-- Mark the parent fiber as incomplete
				returnFiber.flags =
					bit32.bor(returnFiber.flags, ReactFiberFlags.Incomplete)
				returnFiber.subtreeFlags = ReactFiberFlags.NoFlags
				returnFiber.deletions = nil
			end
		end

		local siblingFiber = completedWork.sibling
		if siblingFiber ~= nil then
			-- If there is more work to do in this returnFiber, do that next.
			workInProgress = siblingFiber
			return
		end
		-- Otherwise, return to the parent
		-- ROBLOX Luau FIXME: Luau doesn't understand that completedWork is only nil-able at this point in the control flow
		completedWork = returnFiber :: any
		-- Update the next thing we're working on in case something throws.
		workInProgress = completedWork
	until completedWork == nil

	-- We've reached the root.
	if workInProgressRootExitStatus == RootExitStatus.Incomplete then
		workInProgressRootExitStatus = RootExitStatus.Completed
	end
end

mod.commitRoot = function(root)
	local renderPriorityLevel = getCurrentPriorityLevel()
	runWithPriority(ImmediateSchedulerPriority, function()
		return mod.commitRootImpl(root, renderPriorityLevel)
	end)
	return nil
end

-- ROBLOX Luau FIXME: Luau doesn't infer root as FiberRoot via the callgraph from ensureRootIsScheduled(root: FiberRoot)
mod.commitRootImpl = function(root: FiberRoot, renderPriorityLevel)
	repeat
		-- `flushPassiveEffects` will call `flushSyncUpdateQueue` at the end, which
		-- means `flushPassiveEffects` will sometimes result in additional
		-- passive effects. So we need to keep flushing in a loop until there are
		-- no more pending effects.
		-- TODO: Might be better if `flushPassiveEffects` did not automatically
		-- flush synchronous work at the end, to avoid factoring hazards like this.
		exports.flushPassiveEffects()
	until rootWithPendingPassiveEffects == nil
	flushRenderPhaseStrictModeWarningsInDEV()

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Should not already be working."
	)

	-- ROBLOX Luau FIXME: Luau doesn't narrow finishedWork based on the nil guard below
	local finishedWork = root.finishedWork :: Fiber
	local lanes = root.finishedLanes

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logCommitStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markCommitStarted(lanes)
	end

	if finishedWork == nil then
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logCommitStopped()
			end
		end

		if enableSchedulingProfiler then
			SchedulingProfiler.markCommitStopped()
		end

		return nil
	end
	root.finishedWork = nil
	root.finishedLanes = ReactFiberLane.NoLanes

	invariant(
		finishedWork ~= root.current,
		"Cannot commit the same tree as before. This error is likely caused by "
			.. "a bug in React. Please file an issue."
	)

	-- commitRoot never returns a continuation; it always finishes synchronously.
	-- So we can clear these now to allow a new callback to be scheduled.
	root.callbackNode = nil

	-- Update the first and last pending times on this root. The new first
	-- pending time is whatever is left on the root fiber.
	local remainingLanes = mergeLanes(finishedWork.lanes, finishedWork.childLanes)
	markRootFinished(root, remainingLanes)

	-- Clear already finished discrete updates in case that a later call of
	-- `flushDiscreteUpdates` starts a useless render pass which may cancels
	-- a scheduled timeout.
	if rootsWithPendingDiscreteUpdates ~= nil then
		if
			not hasDiscreteLanes(remainingLanes)
			and rootsWithPendingDiscreteUpdates:has(root)
		then
			rootsWithPendingDiscreteUpdates:delete(root)
		end
	end

	if root == workInProgressRoot then
		-- We can reset these now that they are finished.
		workInProgressRoot = nil
		workInProgress = nil
		workInProgressRootRenderLanes = ReactFiberLane.NoLanes
	else
		-- This indicates that the last root we worked on is not the same one that
		-- we're committing now. This most commonly happens when a suspended root
		-- times out.
	end

	-- Check if there are any effects in the whole tree.
	-- TODO: This is left over from the effect list implementation, where we had
	-- to check for the existence of `firstEffect` to satsify Flow. I think the
	-- only other reason this optimization exists is because it affects profiling.
	-- Reconsider whether this is necessary.
	local subtreeHasEffects = bit32.band(
		finishedWork.subtreeFlags,
		bit32.bor(
			ReactFiberFlags.BeforeMutationMask,
			ReactFiberFlags.MutationMask,
			ReactFiberFlags.LayoutMask,
			ReactFiberFlags.PassiveMask
		)
	) ~= ReactFiberFlags.NoFlags
	local rootHasEffect = bit32.band(
		finishedWork.flags,
		bit32.bor(
			ReactFiberFlags.BeforeMutationMask,
			ReactFiberFlags.MutationMask,
			ReactFiberFlags.LayoutMask,
			ReactFiberFlags.PassiveMask
		)
	) ~= ReactFiberFlags.NoFlags

	if subtreeHasEffects or rootHasEffect then
		local previousLanePriority
		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			previousLanePriority = getCurrentUpdateLanePriority()
			setCurrentUpdateLanePriority(ReactFiberLane.SyncLanePriority)
		end

		local prevExecutionContext = executionContext
		executionContext = bit32.bor(executionContext, CommitContext)
		local prevInteractions = mod.pushInteractions(root)

		-- Reset this to nil before calling lifecycles
		ReactCurrentOwner.current = nil

		-- The commit phase is broken into several sub-phases. We do a separate pass
		-- of the effect list for each phase: all mutation effects come before all
		-- layout effects, and so on.

		-- The first phase a "before mutation" phase. We use this phase to read the
		-- state of the host tree right before we mutate it. This is where
		-- getSnapshotBeforeUpdate is called.
		focusedInstanceHandle = ReactFiberHostConfig.prepareForCommit(root.containerInfo)
		shouldFireAfterActiveInstanceBlur = false

		mod.commitBeforeMutationEffects(finishedWork)

		-- We no longer need to track the active instance fiber
		focusedInstanceHandle = nil

		if ReactFeatureFlags.enableProfilerTimer then
			-- Mark the current commit time to be shared by all Profilers in this
			-- batch. This enables them to be grouped later.
			ReactProfilerTimer.recordCommitTime()
		end

		-- The next phase is the mutation phase, where we mutate the host tree.
		mod.commitMutationEffects(finishedWork, root, renderPriorityLevel)

		if shouldFireAfterActiveInstanceBlur then
			ReactFiberHostConfig.afterActiveInstanceBlur()
		end
		ReactFiberHostConfig.resetAfterCommit(root.containerInfo)

		-- The work-in-progress tree is now the current tree. This must come after
		-- the mutation phase, so that the previous tree is still current during
		-- componentWillUnmount, but before the layout phase, so that the finished
		-- work is current during componentDidMount/Update.
		root.current = finishedWork

		-- The next phase is the layout phase, where we call effects that read
		-- the host tree after it's been mutated. The idiomatic use case for this is
		-- layout, but class component lifecycles also fire here for legacy reasons.
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logLayoutEffectsStarted(lanes)
			end
		end
		if enableSchedulingProfiler then
			SchedulingProfiler.markLayoutEffectsStarted(lanes)
		end

		if __DEV__ then
			setCurrentDebugFiberInDEV(finishedWork)
			invokeGuardedCallback(
				nil,
				recursivelyCommitLayoutEffects,
				nil,
				finishedWork,
				root,
				-- ROBLOX deviation: pass in this function to avoid dependency cycle
				exports.captureCommitPhaseError,
				exports.schedulePassiveEffectCallback
			)
			if hasCaughtError() then
				local err = clearCaughtError()
				captureCommitPhaseErrorOnRoot(finishedWork, finishedWork, err)
			end
			resetCurrentDebugFiberInDEV()
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not __YOLO__ then
				-- ROBLOX deviation: pass in captureCommitPhaseError and schedulePassiveEffectCallback to avoid dependency cycle
				ok, result = xpcall(
					recursivelyCommitLayoutEffects,
					describeError,
					finishedWork,
					root,
					exports.captureCommitPhaseError,
					exports.schedulePassiveEffectCallback
				)
			else
				ok = true
				recursivelyCommitLayoutEffects(
					finishedWork,
					root,
					exports.captureCommitPhaseError,
					exports.schedulePassiveEffectCallback
				)
			end

			if not ok then
				captureCommitPhaseErrorOnRoot(finishedWork, finishedWork, result)
			end
		end

		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logLayoutEffectsStopped()
			end
		end
		if enableSchedulingProfiler then
			SchedulingProfiler.markLayoutEffectsStopped()
		end

		-- If there are pending passive effects, schedule a callback to process them.
		if
			bit32.band(finishedWork.subtreeFlags, ReactFiberFlags.PassiveMask)
				~= ReactFiberFlags.NoFlags
			or bit32.band(finishedWork.flags, ReactFiberFlags.PassiveMask)
				~= ReactFiberFlags.NoFlags
		then
			if not rootDoesHavePassiveEffects then
				rootDoesHavePassiveEffects = true
				scheduleCallback(NormalSchedulerPriority, function()
					exports.flushPassiveEffects()
					return nil
				end)
			end
		end

		-- Tell Scheduler to yield at the end of the frame, so the browser has an
		-- opportunity to paint.
		requestPaint()

		if ReactFeatureFlags.enableSchedulerTracing then
			mod.popInteractions(prevInteractions)
		end
		executionContext = prevExecutionContext

		if
			ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
			and previousLanePriority ~= nil
		then
			-- Reset the priority to the previous non-sync value.
			setCurrentUpdateLanePriority(previousLanePriority)
		end
	else
		-- No effects.
		root.current = finishedWork
		-- Measure these anyway so the flamegraph explicitly shows that there were
		-- no effects.
		-- TODO: Maybe there's a better way to report this.
		if ReactFeatureFlags.enableProfilerTimer then
			ReactProfilerTimer.recordCommitTime()
		end
	end

	local rootDidHavePassiveEffects = rootDoesHavePassiveEffects

	if rootDoesHavePassiveEffects then
		-- This commit has passive effects. Stash a reference to them. But don't
		-- schedule a callback until after flushing layout work.
		rootDoesHavePassiveEffects = false
		rootWithPendingPassiveEffects = root
		pendingPassiveEffectsLanes = lanes
		pendingPassiveEffectsRenderPriority = renderPriorityLevel
	end

	-- Read this again, since an effect might have updated it
	remainingLanes = root.pendingLanes

	-- Check if there's remaining work on this root
	if remainingLanes ~= ReactFiberLane.NoLanes then
		if ReactFeatureFlags.enableSchedulerTracing then
			if spawnedWorkDuringRender ~= nil then
				local expirationTimes = spawnedWorkDuringRender
				spawnedWorkDuringRender = nil
				for i = 1, #expirationTimes do
					scheduleInteractions(
						root,
						expirationTimes[i],
						root.memoizedInteractions
					)
				end
			end
			mod.schedulePendingInteractions(root, remainingLanes)
		end
	else
		-- If there's no remaining work, we can clear the set of already failed
		-- error boundaries.
		legacyErrorBoundariesThatAlreadyFailed = nil
	end

	if __DEV__ and enableDoubleInvokingEffects then
		if not rootDidHavePassiveEffects then
			commitDoubleInvokeEffectsInDEV(root.current, false)
		end
	end

	if ReactFeatureFlags.enableSchedulerTracing then
		if not rootDidHavePassiveEffects then
			-- If there are no passive effects, then we can complete the pending interactions.
			-- Otherwise, we'll wait until after the passive effects are flushed.
			-- Wait to do this until after remaining work has been scheduled,
			-- so that we don't prematurely signal complete for interactions when there's e.g. hidden work.
			mod.finishPendingInteractions(root, lanes)
		end
	end

	if remainingLanes == SyncLane then
		-- Count the number of times the root synchronously re-renders without
		-- finishing. If there are too many, it indicates an infinite update loop.
		if root == rootWithNestedUpdates then
			nestedUpdateCount += 1
		else
			nestedUpdateCount = 0
			rootWithNestedUpdates = root
		end
	else
		nestedUpdateCount = 0
	end

	onCommitRootDevTools(finishedWork.stateNode, renderPriorityLevel)

	if __DEV__ then
		onCommitRootTestSelector()
	end

	-- Always call this before exiting `commitRoot`, to ensure that any
	-- additional work on this root is scheduled.
	ensureRootIsScheduled(root, now())

	if hasUncaughtError then
		hasUncaughtError = false
		local error_ = firstUncaughtError
		firstUncaughtError = nil
		-- ROBLOX FIXME: we lose the original stack trace when we re-throw this way
		error(error_)
	end

	if bit32.band(executionContext, LegacyUnbatchedContext) ~= NoContext then
		if __DEV__ then
			if enableDebugTracing then
				DebugTracing.logCommitStopped()
			end
		end

		if enableSchedulingProfiler then
			SchedulingProfiler.markCommitStopped()
		end

		-- This is a legacy edge case. We just committed the initial mount of
		-- a ReactDOM.render-ed root inside of batchedUpdates. The commit fired
		-- synchronously, but layout updates should be deferred until the end
		-- of the batch.
		return nil
	end

	-- If layout work was scheduled, flush it now.
	flushSyncCallbackQueue()

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logCommitStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markCommitStopped()
	end

	return nil
end

mod.commitBeforeMutationEffects = function(firstChild: Fiber)
	local fiber = firstChild
	while fiber ~= nil do
		if fiber.deletions ~= nil then
			mod.commitBeforeMutationEffectsDeletions(fiber.deletions)
		end

		if fiber.child ~= nil then
			local primarySubtreeFlags =
				bit32.band(fiber.subtreeFlags, ReactFiberFlags.BeforeMutationMask)
			if primarySubtreeFlags ~= ReactFiberFlags.NoFlags then
				mod.commitBeforeMutationEffects(fiber.child)
			end
		end

		if __DEV__ then
			setCurrentDebugFiberInDEV(fiber)
			invokeGuardedCallback(nil, mod.commitBeforeMutationEffectsImpl, nil, fiber)
			if hasCaughtError() then
				local error_ = clearCaughtError()
				exports.captureCommitPhaseError(fiber, fiber.return_, error_)
			end
			resetCurrentDebugFiberInDEV()
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, error_
			if not __YOLO__ then
				ok, error_ =
					xpcall(mod.commitBeforeMutationEffectsImpl, describeError, fiber)
			else
				ok = true
				mod.commitBeforeMutationEffectsImpl(fiber)
			end

			if not ok then
				exports.captureCommitPhaseError(fiber, fiber.return_, error_)
			end
		end
		-- ROBLOX Luau FIXME: Luau doesn't narrow correctly for the while ~= nil pattern
		fiber = fiber.sibling :: Fiber
	end
end

mod.commitBeforeMutationEffectsImpl = function(fiber: Fiber)
	local current = fiber.alternate
	local flags = fiber.flags

	if not shouldFireAfterActiveInstanceBlur and focusedInstanceHandle ~= nil then
		-- Check to see if the focused element was inside of a hidden (Suspense) subtree.
		-- TODO: Move this out of the hot path using a dedicated effect tag.
		if
			fiber.tag == ReactWorkTags.SuspenseComponent
			and ReactFiberCommitWork.isSuspenseBoundaryBeingHidden(current, fiber)
			and doesFiberContain(fiber, focusedInstanceHandle)
		then
			shouldFireAfterActiveInstanceBlur = true
			ReactFiberHostConfig.beforeActiveInstanceBlur()
		end
	end

	if bit32.band(flags, ReactFiberFlags.Snapshot) ~= ReactFiberFlags.NoFlags then
		setCurrentDebugFiberInDEV(fiber)
		commitBeforeMutationEffectOnFiber(current, fiber)
		resetCurrentDebugFiberInDEV()
	end

	if bit32.band(flags, ReactFiberFlags.Passive) ~= ReactFiberFlags.NoFlags then
		-- If there are passive effects, schedule a callback to flush at
		-- the earliest opportunity.
		if not rootDoesHavePassiveEffects then
			rootDoesHavePassiveEffects = true
			scheduleCallback(NormalSchedulerPriority, function()
				exports.flushPassiveEffects()
				return nil
			end)
		end
	end
end

mod.commitBeforeMutationEffectsDeletions = function(deletions: Array<Fiber>)
	for i = 1, #deletions do
		local fiber = deletions[i]

		-- TODO (effects) It would be nice to avoid calling doesFiberContain()
		-- Maybe we can repurpose one of the subtreeFlags positions for this instead?
		-- Use it to store which part of the tree the focused instance is in?
		-- This assumes we can safely determine that instance during the "render" phase.
		if doesFiberContain(fiber, (focusedInstanceHandle :: any) :: Fiber) then
			shouldFireAfterActiveInstanceBlur = true
			ReactFiberHostConfig.beforeActiveInstanceBlur()
		end
	end
end

mod.commitMutationEffects =
	function(firstChild: Fiber, root: FiberRoot, renderPriorityLevel: ReactPriorityLevel)
		local fiber = firstChild
		while fiber ~= nil do
			local deletions = fiber.deletions
			if deletions ~= nil then
				-- ROBLOX performance: React 18 inlines commitMutationEffectsDeletions, pulling that in based on tab switching hot path
				for _, childToDelete in deletions do
					-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
					local ok, error_ = xpcall(
						commitDeletion,
						describeError,
						root,
						childToDelete,
						fiber,
						renderPriorityLevel
					)
					if not ok then
						exports.captureCommitPhaseError(childToDelete, fiber, error_)
					end
				end
			end

			if fiber.child ~= nil then
				local mutationFlags =
					bit32.band(fiber.subtreeFlags, ReactFiberFlags.MutationMask)
				if mutationFlags ~= ReactFiberFlags.NoFlags then
					mod.commitMutationEffects(fiber.child, root, renderPriorityLevel)
				end
			end

			if __DEV__ then
				setCurrentDebugFiberInDEV(fiber)
				invokeGuardedCallback(
					nil,
					mod.commitMutationEffectsImpl,
					nil,
					fiber,
					root,
					renderPriorityLevel
				)
				if hasCaughtError() then
					local error_ = clearCaughtError()
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
				resetCurrentDebugFiberInDEV()
			else
				-- ROBLOX deviation: YOLO flag for disabling pcall
				local ok, result
				if not __YOLO__ then
					ok, result = xpcall(
						mod.commitMutationEffectsImpl,
						describeError,
						fiber,
						root,
						renderPriorityLevel
					)
				else
					ok = true
					mod.commitMutationEffectsImpl(fiber, root, renderPriorityLevel)
				end
				if not ok then
					exports.captureCommitPhaseError(fiber, fiber.return_, result)
				end
			end
			-- ROBLOX Luau FIXME: Luau doesn't understand the while ~= nil construct
			fiber = fiber.sibling :: Fiber
		end
	end

mod.commitMutationEffectsImpl =
	function(fiber: Fiber, root: FiberRoot, renderPriorityLevel)
		local flags = fiber.flags
		-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
		-- if bit32.band(flags, ReactFiberFlags.ContentReset) ~= 0 then
		--   unimplemented("commitResetTextContent")
		-- commitResetTextContent(fiber)
		-- end

		if bit32.band(flags, ReactFiberFlags.Ref) ~= 0 then
			local current = fiber.alternate
			if current ~= nil then
				commitDetachRef(current)
			end
			-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
			-- if ReactFeatureFlags.enableScopeAPI then
			--   -- TODO: This is a temporary solution that allowed us to transition away from React Flare on www.
			--   if fiber.tag == ReactWorkTags.ScopeComponent then
			--     commitAttachRef(fiber)
			--   end
			-- end
		end

		-- The following switch statement is only concerned about placement,
		-- updates, and deletions. To avoid needing to add a case for every possible
		-- bitmap value, we remove the secondary effects from the effect tag and
		-- switch on that value.
		local primaryFlags = bit32.band(
			flags,
			bit32.bor(
				ReactFiberFlags.Placement,
				ReactFiberFlags.Update,
				ReactFiberFlags.Hydrating
			)
		)
		if primaryFlags == ReactFiberFlags.Placement then
			commitPlacement(fiber)
			-- Clear the "placement" from effect tag so that we know that this is
			-- inserted, before any life-cycles like componentDidMount gets called.
			-- TODO: findDOMNode doesn't rely on this any more but isMounted does
			-- and isMounted is deprecated anyway so we should be able to kill this.
			fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Placement))
		elseif primaryFlags == ReactFiberFlags.PlacementAndUpdate then
			-- Placement
			commitPlacement(fiber)
			-- Clear the "placement" from effect tag so that we know that this is
			-- inserted, before any life-cycles like componentDidMount gets called.
			fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Placement))

			-- Update
			local current = fiber.alternate
			commitWork(current, fiber)
		-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
		-- elseif primaryFlags == ReactFiberFlags.Hydrating then
		--   fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Hydrating))
		-- elseif primaryFlags == ReactFiberFlags.HydratingAndUpdate then
		--   fiber.flags = bit32.band(fiber.flags, bit32.bnot(ReactFiberFlags.Hydrating))
		--   -- Update
		--   local current = fiber.alternate
		--   commitWork(current, fiber)
		elseif primaryFlags == ReactFiberFlags.Update then
			local current = fiber.alternate
			commitWork(current, fiber)
		end
	end

mod.commitMutationEffectsDeletions =
	function(deletions: Array<Fiber>, fiber: Fiber, root: FiberRoot, renderPriorityLevel)
		-- ROBLOX performance: align to React 18, which ditches the __DEV__ branch and use of invokeGuardedCallback
		for _, childToDelete in deletions do
			-- ROBLOX FIXME Luau: CLI-49835, "Function only returns 1 value, 2 are required"
			local ok, error_ = xpcall(
				commitDeletion,
				describeError,
				root,
				childToDelete,
				fiber,
				renderPriorityLevel
			)
			if not ok then
				exports.captureCommitPhaseError(childToDelete, fiber, error_)
			end
		end
	end

exports.schedulePassiveEffectCallback = function()
	if not rootDoesHavePassiveEffects then
		rootDoesHavePassiveEffects = true
		scheduleCallback(NormalSchedulerPriority, function()
			exports.flushPassiveEffects()
			return nil
		end)
	end
end

-- deviation: Pre-declare functions
local flushPassiveEffectsImpl
exports.flushPassiveEffects = function(): boolean
	-- Returns whether passive effects were flushed.
	if pendingPassiveEffectsRenderPriority ~= NoSchedulerPriority then
		local priorityLevel = if pendingPassiveEffectsRenderPriority
				> NormalSchedulerPriority
			then NormalSchedulerPriority
			else pendingPassiveEffectsRenderPriority
		pendingPassiveEffectsRenderPriority = NoSchedulerPriority
		if ReactFeatureFlags.decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()

			-- ROBLOX performance: extract non-throwable function from try{} to remove need for anon function
			setCurrentUpdateLanePriority(schedulerPriorityToLanePriority(priorityLevel))
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not __YOLO__ then
				ok, result = xpcall(
					runWithPriority,
					describeError,
					priorityLevel,
					flushPassiveEffectsImpl
				)
			else
				ok = true
				setCurrentUpdateLanePriority(
					schedulerPriorityToLanePriority(priorityLevel)
				)
				result = runWithPriority(priorityLevel, flushPassiveEffectsImpl)
			end

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)

			if not ok then
				error(result)
			end
			return result
		else
			return runWithPriority(priorityLevel, flushPassiveEffectsImpl)
		end
	end
	return false
end

flushPassiveMountEffects = function(root, firstChild: Fiber): ()
	local fiber = firstChild
	while fiber ~= nil do
		local prevProfilerOnStack = nil
		if
			ReactFeatureFlags.enableProfilerTimer
			and ReactFeatureFlags.enableProfilerCommitHooks
		then
			if fiber.tag == ReactWorkTags.Profiler then
				prevProfilerOnStack = nearestProfilerOnStack
				nearestProfilerOnStack = fiber
			end
		end

		local primarySubtreeFlags =
			bit32.band(fiber.subtreeFlags, ReactFiberFlags.PassiveMask)

		if fiber.child ~= nil and primarySubtreeFlags ~= ReactFiberFlags.NoFlags then
			flushPassiveMountEffects(root, fiber.child)
		end

		if
			bit32.band(fiber.flags, ReactFiberFlags.Passive) ~= ReactFiberFlags.NoFlags
		then
			if __DEV__ then
				setCurrentDebugFiberInDEV(fiber)
				invokeGuardedCallback(nil, commitPassiveMountOnFiber, nil, root, fiber)
				if hasCaughtError() then
					local error_ = clearCaughtError()
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
				resetCurrentDebugFiberInDEV()
			else
				-- ROBLOX deviation: YOLO flag for disabling pcall
				local ok, error_
				if not __YOLO__ then
					ok, error_ =
						xpcall(commitPassiveMountOnFiber, describeError, root, fiber)
				else
					ok = true
					commitPassiveMountOnFiber(root, fiber)
				end

				if not ok then
					exports.captureCommitPhaseError(fiber, fiber.return_, error_)
				end
			end
		end

		if
			ReactFeatureFlags.enableProfilerTimer
			and ReactFeatureFlags.enableProfilerCommitHooks
		then
			if fiber.tag == ReactWorkTags.Profiler then
				-- Bubble times to the next nearest ancestor Profiler.
				-- After we process that Profiler, we'll bubble further up.
				if prevProfilerOnStack ~= nil then
					prevProfilerOnStack.stateNode.passiveEffectDuration += fiber.stateNode.passiveEffectDuration
				end

				nearestProfilerOnStack = prevProfilerOnStack
			end
		end

		-- ROBLOX Luau FIXME: Luau doesn't understand the loop ~= nil construct
		fiber = fiber.sibling :: Fiber
	end
end

local function flushPassiveUnmountEffects(firstChild: Fiber): ()
	local fiber = firstChild
	while fiber ~= nil do
		local deletions = fiber.deletions
		if deletions ~= nil then
			for i = 1, #deletions do
				local fiberToDelete = deletions[i]
				mod.flushPassiveUnmountEffectsInsideOfDeletedTree(fiberToDelete, fiber)

				-- Now that passive effects have been processed, it's safe to detach lingering pointers.
				mod.detachFiberAfterEffects(fiberToDelete)
			end
		end

		local child = fiber.child
		if child ~= nil then
			-- If any children have passive effects then traverse the subtree.
			-- Note that this requires checking subtreeFlags of the current Fiber,
			-- rather than the subtreeFlags/effectsTag of the first child,
			-- since that would not cover passive effects in siblings.
			local passiveFlags =
				bit32.band(fiber.subtreeFlags, ReactFiberFlags.PassiveMask)
			if passiveFlags ~= ReactFiberFlags.NoFlags then
				flushPassiveUnmountEffects(child)
			end
		end

		local primaryFlags = bit32.band(fiber.flags, ReactFiberFlags.Passive)
		if primaryFlags ~= ReactFiberFlags.NoFlags then
			setCurrentDebugFiberInDEV(fiber)
			commitPassiveUnmountOnFiber(fiber)
			resetCurrentDebugFiberInDEV()
		end

		-- ROBLOX FIXME Luau: Luau doesn't understand the loop ~= nil construct
		fiber = fiber.sibling :: Fiber
	end
end

mod.flushPassiveUnmountEffectsInsideOfDeletedTree =
	function(fiberToDelete: Fiber, nearestMountedAncestor: Fiber)
		if
			bit32.band(fiberToDelete.subtreeFlags, ReactFiberFlags.PassiveStatic)
			~= ReactFiberFlags.NoFlags
		then
			-- If any children have passive effects then traverse the subtree.
			-- Note that this requires checking subtreeFlags of the current Fiber,
			-- rather than the subtreeFlags/effectsTag of the first child,
			-- since that would not cover passive effects in siblings.
			local child = fiberToDelete.child
			while child ~= nil do
				mod.flushPassiveUnmountEffectsInsideOfDeletedTree(
					child,
					nearestMountedAncestor
				)
				child = child.sibling
			end
		end

		if
			bit32.band(fiberToDelete.flags, ReactFiberFlags.PassiveStatic)
			~= ReactFiberFlags.NoFlags
		then
			setCurrentDebugFiberInDEV(fiberToDelete)
			commitPassiveUnmountInsideDeletedTreeOnFiber(
				fiberToDelete,
				nearestMountedAncestor
			)
			resetCurrentDebugFiberInDEV()
		end
	end

flushPassiveEffectsImpl = function()
	if rootWithPendingPassiveEffects == nil then
		return false
	end

	-- ROBLOX Luau FIXME: Luau doesn't narrow to non-nil with the guard above
	local root = rootWithPendingPassiveEffects :: FiberRoot
	local lanes = pendingPassiveEffectsLanes
	rootWithPendingPassiveEffects = nil
	pendingPassiveEffectsLanes = ReactFiberLane.NoLanes

	invariant(
		bit32.band(executionContext, bit32.bor(RenderContext, CommitContext)) == NoContext,
		"Cannot flush passive effects while already rendering."
	)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logPassiveEffectsStarted(lanes)
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markPassiveEffectsStarted(lanes)
	end

	local prevExecutionContext = executionContext
	executionContext = bit32.bor(executionContext, CommitContext)
	local prevInteractions = mod.pushInteractions(root)

	-- It's important that ALL pending passive effect destroy functions are called
	-- before ANY passive effect create functions are called.
	-- Otherwise effects in sibling components might interfere with each other.
	-- e.g. a destroy function in one component may unintentionally override a ref
	-- value set by a create function in another component.
	-- Layout effects have the same constraint.
	flushPassiveUnmountEffects(root.current)
	flushPassiveMountEffects(root, root.current)

	if __DEV__ then
		if enableDebugTracing then
			DebugTracing.logPassiveEffectsStopped()
		end
	end

	if enableSchedulingProfiler then
		SchedulingProfiler.markPassiveEffectsStopped()
	end

	if __DEV__ and enableDoubleInvokingEffects then
		commitDoubleInvokeEffectsInDEV(root.current, true)
	end

	if ReactFeatureFlags.enableSchedulerTracing then
		mod.popInteractions(prevInteractions)
		mod.finishPendingInteractions(root, lanes)
	end

	executionContext = prevExecutionContext

	flushSyncCallbackQueue()

	-- If additional passive effects were scheduled, increment a counter. If this
	-- exceeds the limit, we'll fire a warning.
	if rootWithPendingPassiveEffects == nil then
		nestedPassiveUpdateCount = 0
	else
		nestedPassiveUpdateCount = nestedPassiveUpdateCount + 1
	end

	return true
end

exports.isAlreadyFailedLegacyErrorBoundary = function(instance): boolean
	return
		legacyErrorBoundariesThatAlreadyFailed ~= nil
			and legacyErrorBoundariesThatAlreadyFailed:has(instance)
end

exports.markLegacyErrorBoundaryAsFailed = function(instance)
	if legacyErrorBoundariesThatAlreadyFailed == nil then
		legacyErrorBoundariesThatAlreadyFailed = Set.new({ instance })
	else
		legacyErrorBoundariesThatAlreadyFailed:add(instance)
	end
end

-- ROBLOX TODO: this function and the related fields should be extracted/relocated to break a cycle
local function prepareToThrowUncaughtError(error_)
	if not hasUncaughtError then
		hasUncaughtError = true
		firstUncaughtError = error_
	end
end
exports.onUncaughtError = prepareToThrowUncaughtError

captureCommitPhaseErrorOnRoot = function(rootFiber: Fiber, sourceFiber: Fiber, error_)
	local errorInfo = createCapturedValue(error_, sourceFiber)
	-- ROBLOX deviation: parameterize method onUncaughtError to avoid circular dependency
	local update =
		createRootErrorUpdate(rootFiber, errorInfo, SyncLane, exports.onUncaughtError)
	enqueueUpdate(rootFiber, update)
	local eventTime = exports.requestEventTime()
	local root = mod.markUpdateLaneFromFiberToRoot(rootFiber, SyncLane)
	if root ~= nil then
		markRootUpdated(root, SyncLane, eventTime)
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, SyncLane)
	end
end

-- exports.captureCommitPhaseError(
--   sourceFiber: Fiber,
--   nearestMountedAncestor: Fiber | nil,
--   error: mixed
-- )
exports.captureCommitPhaseError =
	function(sourceFiber: Fiber, nearestMountedAncestor, error_)
		if sourceFiber.tag == ReactWorkTags.HostRoot then
			-- Error was thrown at the root. There is no parent, so the root
			-- itself should capture it.
			captureCommitPhaseErrorOnRoot(sourceFiber, sourceFiber, error_)
			return
		end

		local fiber = nil
		if skipUnmountedBoundaries then
			fiber = nearestMountedAncestor
		else
			fiber = sourceFiber.return_
		end

		while fiber ~= nil do
			if fiber.tag == ReactWorkTags.HostRoot then
				captureCommitPhaseErrorOnRoot(fiber, sourceFiber, error_)
				return
			else
				if fiber.tag == ReactWorkTags.ClassComponent then
					local ctor = fiber.type
					local instance = fiber.stateNode
					if
						typeof(ctor.getDerivedStateFromError) == "function"
						or (
							typeof(instance.componentDidCatch) == "function"
							and not exports.isAlreadyFailedLegacyErrorBoundary(instance)
						)
					then
						local errorInfo = createCapturedValue(error_, sourceFiber)
						local update = createClassErrorUpdate(fiber, errorInfo, SyncLane)
						enqueueUpdate(fiber, update)
						local eventTime = exports.requestEventTime()
						local root = mod.markUpdateLaneFromFiberToRoot(fiber, SyncLane)
						if root ~= nil then
							markRootUpdated(root, SyncLane, eventTime)
							ensureRootIsScheduled(root, eventTime)
							mod.schedulePendingInteractions(root, SyncLane)
						end
						return
					end
				end
				fiber = fiber.return_
			end
		end
	end

exports.pingSuspendedRoot =
	function(root: FiberRoot, wakeable: Wakeable, pingedLanes: Lanes)
		local pingCache = root.pingCache
		if pingCache ~= nil then
			-- The wakeable resolved, so we no longer need to memoize, because it will
			-- never be thrown again.
			pingCache[wakeable] = nil
		end

		local eventTime = exports.requestEventTime()
		markRootPinged(root, pingedLanes, eventTime)

		if
			workInProgressRoot == root
			and isSubsetOfLanes(workInProgressRootRenderLanes, pingedLanes)
		then
			-- Received a ping at the same priority level at which we're currently
			-- rendering. We might want to restart this render. This should mirror
			-- the logic of whether or not a root suspends once it completes.

			-- TODO: If we're rendering sync either due to Sync, Batched or expired,
			-- we should probably never restart.

			-- If we're suspended with delay, or if it's a retry, we'll always suspend
			-- so we can always restart.
			if
				workInProgressRootExitStatus == RootExitStatus.SuspendedWithDelay
				or workInProgressRootExitStatus == RootExitStatus.Suspended
					and includesOnlyRetries(workInProgressRootRenderLanes)
					and now() - globalMostRecentFallbackTime < FALLBACK_THROTTLE_MS
			then
				-- Restart from the root.
				mod.prepareFreshStack(root, ReactFiberLane.NoLanes)
			else
				-- Even though we can't restart right now, we might get an
				-- opportunity later. So we mark this render as having a ping.
				workInProgressRootPingedLanes =
					mergeLanes(workInProgressRootPingedLanes, pingedLanes)
			end
		end

		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, pingedLanes)
	end

function retryTimedOutBoundary(boundaryFiber: Fiber, retryLane: Lane)
	-- The boundary fiber (a Suspense component or SuspenseList component)
	-- previously was rendered in its fallback state. One of the promises that
	-- suspended it has resolved, which means at least part of the tree was
	-- likely unblocked. Try rendering again, at a new expiration time.
	if retryLane == ReactFiberLane.NoLane then
		retryLane = requestRetryLane(boundaryFiber)
	end
	-- TODO: Special case idle priority?
	local eventTime = exports.requestEventTime()
	local root = mod.markUpdateLaneFromFiberToRoot(boundaryFiber, retryLane)
	if root ~= nil then
		markRootUpdated(root, retryLane, eventTime)
		ensureRootIsScheduled(root, eventTime)
		mod.schedulePendingInteractions(root, retryLane)
	end
end

-- exports.retryDehydratedSuspenseBoundary(boundaryFiber: Fiber)
--   local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
--   local retryLane = NoLane
--   if suspenseState ~= nil)
--     retryLane = suspenseState.retryLane
--   end
--   retryTimedOutBoundary(boundaryFiber, retryLane)
-- end

exports.resolveRetryWakeable = function(boundaryFiber: Fiber, wakeable: Wakeable)
	local retryLane = ReactFiberLane.NoLane -- Default
	local retryCache -- : WeakSet<Wakeable> | Set<Wakeable> | nil
	-- ROBLOX performance: avoid always-false comapare
	-- if ReactFeatureFlags.enableSuspenseServerRenderer then
	--   if boundaryFiber.tag == ReactWorkTags.SuspenseComponent then
	--       retryCache = boundaryFiber.stateNode
	--       local suspenseState: nil | SuspenseState = boundaryFiber.memoizedState
	--       if suspenseState ~= nil then
	--         -- ROBLOX TODO: Remove Luau narrowing workaround
	--         retryLane = (suspenseState :: SuspenseState).retryLane
	--       end
	--     elseif boundaryFiber.tag == ReactWorkTags.SuspenseListComponent then
	--       retryCache = boundaryFiber.stateNode
	--     else
	--       invariant(
	--         false,
	--         'Pinged unknown suspense boundary type. ' ..
	--           'This is probably a bug in React.'
	--       )
	--   end
	-- else
	retryCache = boundaryFiber.stateNode
	-- end

	if retryCache ~= nil then
		-- The wakeable resolved, so we no longer need to memoize, because it will
		-- never be thrown again.
		retryCache:delete(wakeable)
	end

	retryTimedOutBoundary(boundaryFiber, retryLane)
end

-- Computes the next Just Noticeable Difference (JND) boundary.
-- The theory is that a person can't tell the difference between small differences in time.
-- Therefore, if we wait a bit longer than necessary that won't translate to a noticeable
-- difference in the experience. However, waiting for longer might mean that we can avoid
-- showing an intermediate loading state. The longer we have already waited, the harder it
-- is to tell small differences in time. Therefore, the longer we've already waited,
-- the longer we can wait additionally. At some point we have to give up though.
-- We pick a train model where the next boundary commits at a consistent schedule.
-- These particular numbers are vague estimates. We expect to adjust them based on research.
-- ROBLOX Luau FIXME: Luau needs an explicit number annotation here, but should infer: CLI-49832
function jnd(timeElapsed: number): number
	if timeElapsed < 120 then
		return 120
	elseif timeElapsed < 480 then
		return 480
	elseif timeElapsed < 1080 then
		return 1080
	elseif timeElapsed < 1920 then
		return 1920
	elseif timeElapsed < 3000 then
		return 3000
	elseif timeElapsed < 4320 then
		return 4320
	else
		return math.ceil(timeElapsed / 1960) * 1960
	end
end

mod.checkForNestedUpdates = function()
	if nestedUpdateCount > NESTED_UPDATE_LIMIT then
		nestedUpdateCount = 0
		rootWithNestedUpdates = nil
		invariant(
			false,
			"Maximum update depth exceeded. This can happen when a component "
				.. "repeatedly calls setState inside componentWillUpdate or "
				.. "componentDidUpdate. React limits the number of nested updates to "
				.. "prevent infinite loops."
		)
	end

	if __DEV__ then
		if nestedPassiveUpdateCount > NESTED_PASSIVE_UPDATE_LIMIT then
			nestedPassiveUpdateCount = 0
			console.error(
				"Maximum update depth exceeded. This can happen when a component "
					.. "calls setState inside useEffect, but useEffect either doesn't "
					.. "have a dependency array, or one of the dependencies changes on "
					.. "every render."
			)
		end
	end
end

function flushRenderPhaseStrictModeWarningsInDEV()
	if __DEV__ then
		ReactStrictModeWarnings.flushLegacyContextWarning()

		if ReactFeatureFlags.warnAboutDeprecatedLifecycles then
			ReactStrictModeWarnings.flushPendingUnsafeLifecycleWarnings()
		end
	end
end

function commitDoubleInvokeEffectsInDEV(fiber: Fiber, hasPassiveEffects: boolean)
	if __DEV__ and enableDoubleInvokingEffects then
		setCurrentDebugFiberInDEV(fiber)
		invokeEffectsInDev(
			fiber,
			ReactFiberFlags.MountLayoutDev,
			invokeLayoutEffectUnmountInDEV
		)
		if hasPassiveEffects then
			invokeEffectsInDev(
				fiber,
				ReactFiberFlags.MountPassiveDev,
				invokePassiveEffectUnmountInDEV
			)
		end

		invokeEffectsInDev(
			fiber,
			ReactFiberFlags.MountLayoutDev,
			invokeLayoutEffectMountInDEV
		)
		if hasPassiveEffects then
			invokeEffectsInDev(
				fiber,
				ReactFiberFlags.MountPassiveDev,
				invokePassiveEffectMountInDEV
			)
		end
		resetCurrentDebugFiberInDEV()
	end
end

function invokeEffectsInDev(
	firstChild: Fiber,
	fiberFlags: Flags,
	invokeEffectFn: (fiber: Fiber) -> ()
): ()
	if __DEV__ and enableDoubleInvokingEffects then
		local fiber = firstChild
		while fiber ~= nil do
			if fiber.child ~= nil then
				local primarySubtreeFlag = bit32.band(fiber.subtreeFlags, fiberFlags)
				if primarySubtreeFlag ~= ReactFiberFlags.NoFlags then
					invokeEffectsInDev(fiber.child, fiberFlags, invokeEffectFn)
				end
			end

			if bit32.band(fiber.flags, fiberFlags) ~= ReactFiberFlags.NoFlags then
				invokeEffectFn(fiber)
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand the loop ~= nil construct
			fiber = fiber.sibling :: Fiber
		end
	end
end

-- deviation: FIXME restore type Set<string>?, has trouble with narrowing
local didWarnStateUpdateForNotYetMountedComponent: any = nil
mod.warnAboutUpdateOnNotYetMountedFiberInDEV = function(fiber)
	if __DEV__ then
		if bit32.band(executionContext, RenderContext) ~= NoContext then
			-- We local the other warning about render phase updates deal with this one.
			return
		end

		if
			bit32.band(
				fiber.mode,
				bit32.bor(ReactTypeOfMode.BlockingMode, ReactTypeOfMode.ConcurrentMode)
			) == 0
		then
			return
		end

		local tag = fiber.tag
		if
			tag ~= ReactWorkTags.IndeterminateComponent
			and tag ~= ReactWorkTags.HostRoot
			and tag ~= ReactWorkTags.ClassComponent
			and tag ~= ReactWorkTags.FunctionComponent
			and tag ~= ReactWorkTags.ForwardRef
			and tag ~= ReactWorkTags.MemoComponent
			and tag ~= ReactWorkTags.SimpleMemoComponent
			and tag ~= ReactWorkTags.Block
		then
			-- Only warn for user-defined components, not internal ones like Suspense.
			return
		end

		-- We show the whole stack but dedupe on the top component's name because
		-- the problematic code almost always lies inside that component.
		local componentName = getComponentName(fiber.type) or "ReactComponent"
		if didWarnStateUpdateForNotYetMountedComponent ~= nil then
			if didWarnStateUpdateForNotYetMountedComponent[componentName] then
				return
			end
			didWarnStateUpdateForNotYetMountedComponent[componentName] = true
		else
			-- ROBLOX FIXME? not sure this translation is correct
			didWarnStateUpdateForNotYetMountedComponent = { [componentName] = true }
		end

		local previousFiber = ReactCurrentFiber.current
		local ok, result = pcall(function()
			setCurrentDebugFiberInDEV(fiber)
			console.error(
				"Can't perform a React state update on a component that hasn't mounted yet. "
					.. "This indicates that you have a side-effect in your render function that "
					.. "asynchronously later calls tries to update the component. Move this work to "
					.. "useEffect instead."
			)
		end)

		-- finally
		if previousFiber then
			setCurrentDebugFiberInDEV(fiber)
		else
			resetCurrentDebugFiberInDEV()
		end

		if not ok then
			error(result)
		end
	end
end

-- deviation: Declared on the mod table instead of as a local
if __DEV__ and ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback then
	local dummyFiber = nil
	mod.beginWork = function(current, unitOfWork, lanes)
		-- If a component throws an error, we replay it again in a synchronously
		-- dispatched event, so that the debugger will treat it as an uncaught
		-- error See ReactErrorUtils for more information.

		-- Before entering the begin phase, copy the work-in-progress onto a dummy
		-- fiber. If beginWork throws, we'll use this to reset the state.
		local originalWorkInProgressCopy =
			ReactFiber.assignFiberPropertiesInDEV(dummyFiber, unitOfWork)
		local ok, result =
			xpcall(originalBeginWork, describeError, current, unitOfWork, lanes)
		if not ok then
			local originalError = result

			if
				originalError ~= nil
				and typeof(originalError) == "table"
				and typeof(originalError.andThen) == "function"
			then
				-- Don't replay promises. Treat everything else like an error.
				error(originalError)
			end

			-- Keep this code in sync with handleError; any changes here must have
			-- corresponding changes there.
			resetContextDependencies()
			resetHooksAfterThrow()
			-- Don't reset current debug fiber, since we're about to work on the
			-- same fiber again.

			-- Unwind the failed stack frame
			unwindInterruptedWork(unitOfWork)

			-- Restore the original properties of the fiber.
			ReactFiber.assignFiberPropertiesInDEV(unitOfWork, originalWorkInProgressCopy)

			if
				ReactFeatureFlags.enableProfilerTimer
				and bit32.band(unitOfWork.mode, ReactTypeOfMode.ProfileMode) ~= 0
			then
				-- Reset the profiler timer.
				ReactProfilerTimer.startProfilerTimer(unitOfWork)
			end

			-- Run beginWork again.
			invokeGuardedCallback(nil, originalBeginWork, nil, current, unitOfWork, lanes)

			if hasCaughtError() then
				local replayError = clearCaughtError()
				-- `invokeGuardedCallback` sometimes sets an expando `_suppressLogging`.
				-- Rethrow this error instead of the original one.
				error(replayError)
			else
				-- This branch is reachable if the render phase is impure.
				error(originalError)
			end
		end

		return result
	end
else
	mod.beginWork = originalBeginWork
end

local didWarnAboutUpdateInRender = false
local didWarnAboutUpdateInRenderForAnotherComponent
if __DEV__ then
	didWarnAboutUpdateInRenderForAnotherComponent = {}
end

mod.warnAboutRenderPhaseUpdatesInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactCurrentFiber.isRendering
			and bit32.band(executionContext, RenderContext) ~= NoContext
			and not getIsUpdatingOpaqueValueInRenderPhaseInDEV()
		then
			if
				fiber.tag == ReactWorkTags.FunctionComponent
				or fiber.tag == ReactWorkTags.ForwardRef
				or fiber.tag == ReactWorkTags.SimpleMemoComponent
			then
				local renderingComponentName = (function()
					if workInProgress ~= nil then
						return getComponentName((workInProgress :: Fiber).type)
					end
					return "Unknown"
				end)()
				-- Dedupe by the rendering component because it's the one that needs to be fixed.
				local dedupeKey = renderingComponentName
				-- ROBLOX deviation:
				-- if !didWarnAboutUpdateInRenderForAnotherComponent.has(dedupeKey))
				if didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] == nil then
					didWarnAboutUpdateInRenderForAnotherComponent[dedupeKey] = true
					local setStateComponentName = getComponentName(fiber.type)
						or "Unknown"
					console.error(
						"Cannot update a component (`%s`) while rendering a "
							.. "different component (`%s`). To locate the bad setState() call inside `%s`, "
							.. "follow the stack trace as described in https://reactjs.org/link/setstate-in-render",
						setStateComponentName,
						renderingComponentName,
						renderingComponentName
					)
				end
			elseif fiber.tag == ReactWorkTags.ClassComponent then
				if not didWarnAboutUpdateInRender then
					console.error(
						"Cannot update during an existing state transition (such as "
							.. "within `render`). Render methods should be a pure "
							.. "function of props and state."
					)
					didWarnAboutUpdateInRender = true
				end
			end
		end
	end
end

-- a 'shared' variable that changes when act() opens/closes in tests.
exports.IsThisRendererActing = { current = false }

exports.warnIfNotScopedWithMatchingAct = function(fiber: Fiber)
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and IsSomeRendererActing.current == true
			and exports.IsThisRendererActing.current ~= true
		then
			local previousFiber = ReactCurrentFiber.current
			local ok, result = pcall(function()
				setCurrentDebugFiberInDEV(fiber)
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when we have a better idea of what it
				-- looks like; in React, this string is broken up oddly to avoid
				-- confusing tools, but we don't have any reason to do that right now
				console.error(
					"It looks like you're using the wrong act() around your test interactions.\n"
						.. "Be sure to use the matching version of act() corresponding to your renderer:\n\n"
						.. "-- for react-roblox:\n"
						.. "local React = require(Packages.React)\n"
						.. "-- ...\n"
						.. "React.TestUtils.act(function() ... end)\n\n"
						.. "-- for react-test-renderer:\n"
						.. "local TestRenderer = require(Packages.ReactTestRenderer)\n"
						.. "-- ...\n"
						.. "TestRenderer.act(function() ... end)"
				)
			end)

			-- finally
			if previousFiber then
				setCurrentDebugFiberInDEV(fiber)
			else
				resetCurrentDebugFiberInDEV()
			end

			if not ok then
				error(result)
			end
		end
	end
end

exports.warnIfNotCurrentlyActingEffectsInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and bit32.band(fiber.mode, ReactTypeOfMode.StrictMode) ~= ReactTypeOfMode.NoMode
			and IsSomeRendererActing.current == false
			and exports.IsThisRendererActing.current == false
		then
			-- ROBLOX deviation: Use Lua syntax for example fix
			console.error(
				"An update to %s ran an effect, but was not wrapped in act(...).\n\n"
					.. "When testing, code that causes React state updates should be "
					.. "wrapped into act(...):\n\n"
					.. "act(function()\n"
					.. "  --[[ fire events that update state ]]\n"
					.. "end)\n"
					.. "--[[ assert on the output ]]\n\n"
					.. "This ensures that you're testing the behavior the user would see "
					.. "in the real client."
					.. " Learn more at https://reactjs.org/link/wrap-tests-with-act",
				getComponentName(fiber.type)
			)
		end
	end
end

exports.warnIfNotCurrentlyActingUpdatesInDEV = function(fiber: Fiber): ()
	if __DEV__ then
		if
			ReactFiberHostConfig.warnsIfNotActing == true
			and executionContext == NoContext
			and IsSomeRendererActing.current == false
			and exports.IsThisRendererActing.current == false
		then
			local previousFiber = ReactCurrentFiberCurrent
			local ok, result = pcall(function()
				setCurrentDebugFiberInDEV(fiber)
				-- ROBLOX deviation: Use Lua syntax for example fix
				console.error(
					"An update to %s inside a test was not wrapped in act(...).\n\n"
						.. "When testing, code that causes React state updates should be "
						.. "wrapped into act(...):\n\n"
						.. "act(function()\n"
						.. "  --[[ fire events that update state ]]\n"
						.. "end)\n"
						.. "--[[ assert on the output ]]\n\n"
						.. "This ensures that you're testing the behavior the user would see "
						.. "in the client application."
						.. " Learn more at https://reactjs.org/link/wrap-tests-with-act",
					getComponentName(fiber.type)
				)
			end)

			-- Finally
			if previousFiber then
				setCurrentDebugFiberInDEV(fiber)
			else
				resetCurrentDebugFiberInDEV()
			end

			if ok then
				return result
			end
		end
	end
	-- ROBLOX deviation: explicit return to silence analyze
	return
end

-- In tests, we want to enforce a mocked scheduler.
local didWarnAboutUnmockedScheduler = false
-- TODO Before we release concurrent mode, revisit this and decide whether a mocked
-- scheduler is the actual recommendation. The alternative could be a testing build,
-- a new lib, or whatever; we dunno just yet. This message is for early adopters
-- to get their tests right.

exports.warnIfUnmockedScheduler = function(fiber: Fiber)
	if __DEV__ then
		if
			didWarnAboutUnmockedScheduler == false
			and Scheduler.unstable_flushAllWithoutAsserting == nil
		then
			if
				bit32.band(fiber.mode, ReactTypeOfMode.BlockingMode) ~= 0
				or bit32.band(fiber.mode, ReactTypeOfMode.ConcurrentMode) ~= 0
			then
				didWarnAboutUnmockedScheduler = true
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when jest-roblox is in use; in React,
				-- this string is broken up oddly to avoid confusing tools, but we don't
				-- have any reason to do that right now
				console.error(
					"In Concurrent or Sync modes, the 'scheduler' module needs to be mocked "
						.. "to guarantee consistent behaviour across tests and client application. "
						.. "For example, with Jest: \n"
						-- Break up requires to avoid accidentally parsing them as dependencies.
						.. "jest.mock('scheduler', function() return require(Packages.Scheduler).unstable_mock end)\n\n"
						.. "For more info, visit https://reactjs.org/link/mock-scheduler"
				)
			elseif ReactFeatureFlags.warnAboutUnmockedScheduler == true then
				didWarnAboutUnmockedScheduler = true
				-- deviation: error modified to suggest proper lua instead of JS

				-- FIXME (roblox): return to this when jest-roblox is in use; in React,
				-- this string is broken up oddly to avoid confusing tools, but we don't
				-- have any reason to do that right now
				console.error(
					"Starting from React v18, the 'scheduler' module will need to be mocked "
						.. "to guarantee consistent behaviour across tests and client applications. "
						.. "For example, with Jest: \n"
						-- Break up requires to avoid accidentally parsing them as dependencies.
						.. "jest.mock('scheduler', function() return require(Packages.Scheduler).unstable_mock end)\n\n"
						.. "For more info, visit https://reactjs.org/link/mock-scheduler"
				)
			end
		end
	end
end

function computeThreadID(root: FiberRoot, lane: Lane | Lanes)
	-- Interaction threads are unique per root and expiration time.
	-- NOTE: Intentionally unsound cast. All that matters is that it's a number
	-- and it represents a batch of work. Could make a helper function instead,
	-- but meh this is fine for now.
	return lane * 1000 + root.interactionThreadID
end

exports.markSpawnedWork = function(lane: Lane | Lanes)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end
	if spawnedWorkDuringRender == nil then
		spawnedWorkDuringRender = { lane }
	else
		-- ROBLOX FIXME Luau: depends on Luau type states
		table.insert(spawnedWorkDuringRender :: Array<number>, lane)
	end
end

function scheduleInteractions(
	root: FiberRoot,
	lane: Lane | Lanes,
	interactions: Set<Interaction>
)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	if interactions.size > 0 then
		local pendingInteractionMap = root.pendingInteractionMap
		local pendingInteractions = pendingInteractionMap:get(lane)
		if pendingInteractions ~= nil then
			interactions:forEach(function(interaction)
				if not pendingInteractions:has(interaction) then
					-- Update the pending async work count for previously unscheduled interaction.
					interaction.__count += 1
				end

				pendingInteractions:add(interaction)
			end)
		else
			pendingInteractionMap:set(lane, Set.new(interactions))

			-- Update the pending async work count for the current interactions.
			for _, interaction in interactions do
				interaction.__count += 1
			end
		end

		local subscriber = __subscriberRef.current
		if subscriber ~= nil then
			local threadID = computeThreadID(root, lane)
			subscriber.onWorkScheduled(interactions, threadID)
		end
	end
end

mod.schedulePendingInteractions = function(root: FiberRoot, lane: Lane | Lanes)
	-- This is called when work is scheduled on a root.
	-- It associates the current interactions with the newly-scheduled expiration.
	-- They will be restored when that expiration is later committed.
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	scheduleInteractions(root, lane, __interactionsRef.current)
end

mod.startWorkOnPendingInteractions = function(root: FiberRoot, lanes: Lanes)
	-- This is called when new work is started on a root.
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	-- Determine which interactions this batch of work currently includes, So that
	-- we can accurately attribute time spent working on it, And so that cascading
	-- work triggered during the render phase will be associated with it.
	local interactions: Set<Interaction> = Set.new()
	root.pendingInteractionMap:forEach(function(scheduledInteractions, scheduledLane)
		if includesSomeLane(lanes, scheduledLane) then
			scheduledInteractions:forEach(function(interaction)
				interactions:add(interaction)
			end)
		end
	end)

	-- Store the current set of interactions on the ReactInternalTypes.FiberRoot for a few reasons:
	-- We can re-use it in hot functions like performConcurrentWorkOnRoot()
	-- without having to recalculate it. We will also use it in commitWork() to
	-- pass to any Profiler onRender() hooks. This also provides DevTools with a
	-- way to access it when the onCommitRoot() hook is called.
	-- ROBLOX FIXME: manual type check to workaround Luau analyze bug "Type 'Set<Interaction>' could not be converted into 'Set<Interaction>'"
	root.memoizedInteractions = interactions :: any

	if interactions.size > 0 then
		local subscriber = __subscriberRef.current
		if subscriber ~= nil then
			local threadID = computeThreadID(root, lanes)
			local ok, error_ =
				xpcall(subscriber.onWorkStarted, describeError, interactions, threadID)
			if not ok then
				-- If the subscriber throws, rethrow it in a separate task
				scheduleCallback(ImmediateSchedulerPriority, function()
					error(error_)
				end)
			end
		end
	end
end

mod.finishPendingInteractions = function(root: FiberRoot, committedLanes)
	if not ReactFeatureFlags.enableSchedulerTracing then
		return
	end

	local remainingLanesAfterCommit = root.pendingLanes

	local subscriber

	-- ROBLOX try
	local ok = true
	local error_
	if subscriber ~= nil and root.memoizedInteractions.size > 0 then
		-- FIXME: More than one lane can finish in a single commit.
		-- ROBLOX peformance: hoist non-throwable things out of the pcall() so we can remove an anon function
		local threadID = computeThreadID(root, committedLanes)
		subscriber = __subscriberRef.current
		-- ROBLOX deviation: helper for raw table set/map size > 0
		ok, error_ = xpcall(
			subscriber.onWorkStopped,
			describeError,
			root.memoizedInteractions,
			threadID
		)
	end

	-- ROBLOX finally
	-- Clear completed interactions from the pending Map.
	-- Unless the render was suspended or cascading work was scheduled,
	-- In which case– leave pending interactions until the subsequent render.
	local pendingInteractionMap = root.pendingInteractionMap
	pendingInteractionMap:forEach(function(scheduledInteractions, lane)
		-- Only decrement the pending interaction count if we're done.
		-- If there's still work at the current priority,
		-- That indicates that we are waiting for suspense data.
		if not includesSomeLane(remainingLanesAfterCommit, lane) then
			pendingInteractionMap:delete(lane)
			scheduledInteractions:forEach(function(interaction)
				interaction.__count -= 1

				if subscriber ~= nil and interaction.__count == 0 then
					local ok_, error__ = xpcall(
						subscriber.onInteractionScheduledWorkCompleted,
						describeError,
						interaction
					)
					if not ok_ then
						-- If the subscriber throws, rethrow it in a separate task
						scheduleCallback(ImmediateSchedulerPriority, function()
							error(error__)
						end)
					end
				end
			end)
		end
	end)

	-- ROBLOX catch
	if not ok then
		-- If the subscriber throws, rethrow it in a separate task
		scheduleCallback(ImmediateSchedulerPriority, function()
			error(error_)
		end)
	end
end

-- `act` testing API
--
-- TODO: This is mostly a copy-paste from the legacy `act`, which does not have
-- access to the same internals that we do here. Some trade offs in the
-- implementation no longer make sense.
local isFlushingAct = false
local isInsideThisAct = false

local flushMockScheduler = Scheduler.unstable_flushAllWithoutAsserting
local isSchedulerMocked = typeof(flushMockScheduler) == "function"

-- Returns whether additional work was scheduled. Caller should keep flushing
-- until there's no work left.
local function flushActWork(): boolean
	if flushMockScheduler ~= nil then
		local prevIsFlushing = isFlushingAct
		isFlushingAct = true
		local ok, result = xpcall(flushMockScheduler, describeError)

		-- finally
		isFlushingAct = prevIsFlushing

		if not ok then
			error(result)
		else
			return result
		end
	else
		-- No mock scheduler available. However, the only type of pending work is
		-- passive effects, which we control. So we can flush that.
		local prevIsFlushing = isFlushingAct
		isFlushingAct = true
		-- ROBLOX performance? rewrite this loop to eliminate anon function?
		local ok, result = xpcall(function()
			local didFlushWork = false
			while exports.flushPassiveEffects() do
				didFlushWork = true
			end
			return didFlushWork
		end, describeError)

		-- finally
		isFlushingAct = prevIsFlushing

		if not ok then
			error(result)
		else
			return result
		end
	end
end

local function flushWorkAndMicroTasks(onDone: (any?) -> ())
	-- ROBLOX performance: split into two pcall to eliminate anonymous func allocation per call
	local ok, result = xpcall(flushActWork, describeError)
	if ok then
		ok, result = xpcall(enqueueTask, describeError, function()
			if flushActWork() then
				flushWorkAndMicroTasks(onDone)
			else
				onDone()
			end
		end)
	end

	if not ok then
		onDone(result)
	end
end

exports.act = function(callback: () -> Thenable<any>): Thenable<any>
	-- It's only viable to export `act` when we're using mocked scheduling logic.
	-- Since there are numerous testing scenarios in which we call `require` on
	-- the Roact library _before_ we bootstrap tests, we expose a global to toggle
	-- this explicilty
	if not (__DEV__ or _G.__ROACT_17_MOCK_SCHEDULER__) then
		if didWarnAboutUsingActInProd == false then
			didWarnAboutUsingActInProd = true
			-- eslint-disable-next-line react-internal/no-production-logging
			console.error(
				"act(...) is not supported in production builds of React, and might not behave as expected."
			)
		end
	end

	local previousActingUpdatesScopeDepth = actingUpdatesScopeDepth
	actingUpdatesScopeDepth += 1

	local previousIsSomeRendererActing = IsSomeRendererActing.current
	local previousIsThisRendererActing = exports.IsThisRendererActing.current
	local previousIsInsideThisAct = isInsideThisAct
	IsSomeRendererActing.current = true
	exports.IsThisRendererActing.current = true
	isInsideThisAct = true

	local function onDone()
		actingUpdatesScopeDepth -= 1
		IsSomeRendererActing.current = previousIsSomeRendererActing
		exports.IsThisRendererActing.current = previousIsThisRendererActing
		isInsideThisAct = previousIsInsideThisAct
		if __DEV__ then
			if actingUpdatesScopeDepth > previousActingUpdatesScopeDepth then
				-- if it's _less than_ previousActingUpdatesScopeDepth, then we can assume the 'other' one has warned
				console.error(
					"You seem to have overlapping act() calls, this is not supported. "
						.. "Be sure to await previous act() calls before making a new one. "
				)
			end
		end
	end

	local ok, result = xpcall(exports.batchedUpdates, describeError, callback)
	if not ok then
		onDone()
		error(result)
	end

	if
		result ~= nil
		and typeof(result) == "table"
		and typeof(result.andThen) == "function"
	then
		-- setup a boolean that gets set to true only
		-- once this act() call is await-ed
		local called = false
		if __DEV__ then
			if typeof(Promise) ~= nil then
				--eslint-disable-next-line no-undef
				Promise.resolve():andThen(function() end):andThen(function()
					if called == false then
						-- FIXME (roblox): We should replace this with proper Lua promise
						-- logic
						console.error(
							"You called act(Promise.new(function() --[[ ... ]] end)) without :await() or :expect(). "
								.. "This could lead to unexpected testing behaviour, interleaving multiple act "
								.. "calls and mixing their scopes. You should - act(function() Promise.new(function() --[[ ... ]] end):await() end);"
						)
					end
				end)
			end
		end

		-- in the async case, the returned thenable runs the callback, flushes
		-- effects and microtasks in a loop until flushPassiveEffects() == false,
		-- and cleans up
		return {
			-- ROBLOX FIXME Luau: have to explicitly annotate the unused generic arg: CLI-49996
			andThen = function<U>(self, resolve, reject)
				called = true
				return result:andThen(function()
					if
						actingUpdatesScopeDepth > 1
						or (
							isSchedulerMocked == true
							and previousIsSomeRendererActing == true
						)
					then
						onDone()
						resolve()
						return
					end
					-- we're about to exit the act() scope,
					-- now's the time to flush tasks/effects
					flushWorkAndMicroTasks(function(err: any?)
						onDone()
						if err then
							reject(err)
						else
							resolve()
						end
					end)
				end, function(err)
					onDone()
					reject(err)
				end)
			end,
		}
	else
		if __DEV__ then
			if result ~= nil then
				-- ROBLOX deviation: use Lua syntax
				console.error(
					"The callback passed to act(...) function "
						.. "must return nil, or a Promise. You returned %s",
					tostring(result)
				)
			end
		end

		-- flush effects until none remain, and cleanup
		local flushOk, flushResult = xpcall(function()
			if
				actingUpdatesScopeDepth == 1
				and (isSchedulerMocked == false or previousIsSomeRendererActing == false)
			then
				-- we're about to exit the act() scope,
				-- now's the time to flush effects
				flushActWork()
			end
			onDone()
		end, describeError)

		if not flushOk then
			onDone()
			error(flushResult)
		end

		-- in the sync case, the returned thenable only warns *if* await-ed
		return {
			-- ROBLOX FIXME Luau: have to explicitly annotate the unused generic arg: CLI-49996
			andThen = function<U>(self, resolve, reject_)
				if __DEV__ then
					console.error(
						"Do not await the result of calling act(...) with sync logic, it is not a Promise."
					)
				end
				resolve()
			end,
		}
	end
end

mod.detachFiberAfterEffects = function(fiber: Fiber)
	-- Null out fields to improve GC for references that may be lingering (e.g. DevTools).
	-- Note that we already cleared the return pointer in detachFiberMutation().
	fiber.child = nil
	fiber.deletions = nil
	fiber.dependencies = nil
	fiber.memoizedProps = nil
	fiber.memoizedState = nil
	fiber.pendingProps = nil
	fiber.sibling = nil
	fiber.stateNode = nil
	fiber.updateQueue = nil

	if __DEV__ then
		fiber._debugOwner = nil
	end
end

return exports
