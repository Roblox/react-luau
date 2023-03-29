--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/ReactFiberHooks.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. message)
	error("FIXME (roblox): " .. message .. " is unimplemented")
end
local __DEV__ = _G.__DEV__ :: boolean
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object

-- ROBLOX: use Bindings to implement useRef
local createRef = require(Packages.React).createRef
local createBinding = require(Packages.React).createBinding

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
type ReactContext<T> = ReactTypes.ReactContext<T>
type ReactBinding<T> = ReactTypes.ReactBinding<T>
type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type Dispatcher = ReactInternalTypes.Dispatcher
type HookType = ReactInternalTypes.HookType
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
local ReactHookEffectTags = require(script.Parent.ReactHookEffectTags)
type HookFlags = ReactHookEffectTags.HookFlags
type FiberRoot = ReactInternalTypes.FiberRoot
-- ROBLOX TODO: figure out how to expose types through dynamic exports
-- local type {OpaqueIDType} = require(script.Parent.ReactFiberHostConfig)
type OpaqueIDType = any

local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableDebugTracing: boolean? = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler: boolean? = ReactFeatureFlags.enableSchedulingProfiler
local enableNewReconciler: boolean? = ReactFeatureFlags.enableNewReconciler
-- local decoupleUpdatePriorityFromScheduler = ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects

-- local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local DebugTracingMode = require(script.Parent.ReactTypeOfMode).DebugTracingMode
local NoLane = ReactFiberLane.NoLane
local NoLanes = ReactFiberLane.NoLanes
-- local InputContinuousLanePriority = ReactFiberLane.InputContinuousLanePriority
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes
local removeLanes = ReactFiberLane.removeLanes
local markRootEntangled = ReactFiberLane.markRootEntangled
local markRootMutableRead = ReactFiberLane.markRootMutableRead
-- local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
-- local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
-- local higherLanePriority = ReactFiberLane.higherLanePriority
-- local DefaultLanePriority = ReactFiberLane.DefaultLanePriority
local ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"])
local readContext = ReactFiberNewContext.readContext
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local UpdateEffect = ReactFiberFlags.Update
local PassiveEffect = ReactFiberFlags.Passive
local PassiveStaticEffect = ReactFiberFlags.PassiveStatic
local MountLayoutDevEffect = ReactFiberFlags.MountLayoutDev
local MountPassiveDevEffect = ReactFiberFlags.MountPassiveDev
local HookHasEffect = ReactHookEffectTags.HasEffect
local HookLayout = ReactHookEffectTags.Layout
local HookPassive = ReactHookEffectTags.Passive
local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
local warnIfNotCurrentlyActingUpdatesInDEV =
	ReactFiberWorkLoop.warnIfNotCurrentlyActingUpdatesInDEV
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local warnIfNotScopedWithMatchingAct = ReactFiberWorkLoop.warnIfNotScopedWithMatchingAct
local requestEventTime = ReactFiberWorkLoop.requestEventTime
local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
local markSkippedUpdateLanes = ReactFiberWorkLoop.markSkippedUpdateLanes
local getWorkInProgressRoot = ReactFiberWorkLoop.getWorkInProgressRoot
local warnIfNotCurrentlyActingEffectsInDEV =
	ReactFiberWorkLoop.warnIfNotCurrentlyActingEffectsInDEV
-- local {
--   getWorkInProgressRoot,
--   requestUpdateLane,
--   requestEventTime,
--   warnIfNotCurrentlyActingEffectsInDEV,
-- } = require(script.Parent.ReactFiberWorkLoop.new)

local invariant = require(Packages.Shared).invariant
local getComponentName = require(Packages.Shared).getComponentName
-- local is = require(Packages.Shared).objectIs
local function is(x: any, y: any)
	return x == y and (x ~= 0 or 1 / x == 1 / y) or x ~= x and y ~= y -- eslint-disable-line no-self-compare
end
local markWorkInProgressReceivedUpdate =
	require(script.Parent["ReactFiberBeginWork.new"]).markWorkInProgressReceivedUpdate :: any
-- local {
--   UserBlockingPriority,
--   NormalPriority,
--   runWithPriority,
--   getCurrentPriorityLevel,
-- } = require(script.Parent.SchedulerWithReactIntegration.new)
local getIsHydrating =
	require(script.Parent["ReactFiberHydrationContext.new"]).getIsHydrating
-- local {
--   makeClientId,
--   makeClientIdInDEV,
--   makeOpaqueHydratingObject,
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local makeClientId = ReactFiberHostConfig.makeClientId
-- local makeOpaqueHydratingObject = ReactFiberHostConfig.makeOpaqueHydratingObject
-- local makeClientIdInDEV = ReactFiberHostConfig.makeClientIdInDEV

local ReactMutableSource = require(script.Parent["ReactMutableSource.new"])
local warnAboutMultipleRenderersDEV = ReactMutableSource.warnAboutMultipleRenderersDEV
local getWorkInProgressVersion = ReactMutableSource.getWorkInProgressVersion
local setWorkInProgressVersion = ReactMutableSource.setWorkInProgressVersion
local markSourceAsDirty = ReactMutableSource.markSourceAsDirty

-- local getIsRendering = require(script.Parent.ReactCurrentFiber).getIsRendering
local logStateUpdateScheduled =
	require(script.Parent.DebugTracing).logStateUpdateScheduled
local markStateUpdateScheduled =
	require(script.Parent.SchedulingProfiler).markStateUpdateScheduled

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
-- local ReactCurrentBatchConfig = ReactSharedInternals.ReactCurrentBatchConfig

-- deviation: common types
type Array<T> = { [number]: T }

type Update<S, A> = {
	lane: Lane,
	action: A,
	eagerReducer: ((S, A) -> S) | nil,
	eagerState: S | nil,
	next: Update<S, A>,
	priority: ReactPriorityLevel?,
}

type UpdateQueue<S, A> = {
	pending: Update<S, A> | nil,
	dispatch: ((A) -> ...any) | nil,
	lastRenderedReducer: ((S, A) -> S) | nil,
	lastRenderedState: S | nil,
}

local didWarnAboutMismatchedHooksForComponent
local _didWarnAboutUseOpaqueIdentifier
if __DEV__ then
	_didWarnAboutUseOpaqueIdentifier = {}
	didWarnAboutMismatchedHooksForComponent = {}
end

export type Hook = {
	memoizedState: any,
	baseState: any,
	baseQueue: Update<any, any> | nil,
	queue: UpdateQueue<any, any> | nil,
	next: Hook?,
}

export type Effect = {
	tag: HookFlags,
	-- ROBLOX TODO: this needs Luau type pack support to express accurately
	create: (() -> (() -> ())) | () -> (),
	destroy: (() -> ())?,
	deps: Array<any> | nil,
	next: Effect,
}

export type FunctionComponentUpdateQueue = {
	lastEffect: Effect?,
}

type BasicStateAction<S> = ((S) -> S) | S

type Dispatch<A> = (A) -> ()

local exports: any = {}

-- These are set right before calling the component.
local renderLanes: Lanes = NoLanes
-- The work-in-progress fiber. I've named it differently to distinguish it from
-- the work-in-progress hook.
local currentlyRenderingFiber: Fiber = nil :: any

-- Hooks are stored as a linked list on the fiber's memoizedState field. The
-- current hook list is the list that belongs to the current fiber. The
-- work-in-progress hook list is a new list that will be added to the
-- work-in-progress fiber.
-- FIXME (roblox): type refinement
-- local currentHook: Hook | nil = nil
local currentHook: any = nil
-- FIXME (roblox): type refinement
-- local workInProgressHook: Hook | nil = nil
local workInProgressHook: any = nil

-- Whether an update was scheduled at any point during the render phase. This
-- does not get reset if we do another render pass; only when we're completely
-- finished evaluating this component. This is an optimization so we know
-- whether we need to clear render phase updates after a throw.
local didScheduleRenderPhaseUpdate: boolean = false
-- Where an update was scheduled only during the current render pass. This
-- gets reset after each attempt.
-- TODO: Maybe there's some way to consolidate this with
-- `didScheduleRenderPhaseUpdate`. Or with `numberOfReRenders`.
local didScheduleRenderPhaseUpdateDuringThisPass: boolean = false

local RE_RENDER_LIMIT = 25

-- In DEV, this is the name of the currently executing primitive hook
local currentHookNameInDev: HookType? = nil

-- In DEV, this list ensures that hooks are called in the same order between renders.
-- The list stores the order of hooks used during the initial render (mount).
-- Subsequent renders (updates) reference this list.
local hookTypesDev: Array<HookType> | nil = nil
local hookTypesUpdateIndexDev: number = 0

-- In DEV, this tracks whether currently rendering component needs to ignore
-- the dependencies for Hooks that need them (e.g. useEffect or useMemo).
-- When true, such Hooks will always be "remounted". Only used during hot reload.
-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
local ignorePreviousDependencies: boolean = false

-- Deviation: move to top so below function can reference
local HooksDispatcherOnMountInDEV: Dispatcher | nil = nil
local HooksDispatcherOnMountWithHookTypesInDEV: Dispatcher | nil = nil
local HooksDispatcherOnUpdateInDEV: Dispatcher | nil = nil
local HooksDispatcherOnRerenderInDEV: Dispatcher | nil = nil
local InvalidNestedHooksDispatcherOnMountInDEV: Dispatcher | nil = nil
local InvalidNestedHooksDispatcherOnUpdateInDEV: Dispatcher | nil = nil
local InvalidNestedHooksDispatcherOnRerenderInDEV: Dispatcher | nil = nil

-- ROBLOX deviation: Used to better compare dependency arrays with gaps
local function getHighestIndex(array: Array<any>)
	local highestIndex = 0
	for k, v in array do
		highestIndex = if k > highestIndex then k else highestIndex
	end
	return highestIndex
end

-- ROBLOX deviation: Used to better detect dependency arrays with gaps, to be
-- used in place of Array.isArray
local function isArrayOrSparseArray(deps: any)
	if type(deps) ~= "table" then
		return false
	end
	for k, _v in deps do
		if type(k) ~= "number" then
			return false
		end
	end
	return true
end

local function mountHookTypesDev()
	if __DEV__ then
		local hookName = (currentHookNameInDev :: any) :: HookType

		if hookTypesDev == nil then
			-- ROBLOX FIXME Luau: needs normalization (I think)
			hookTypesDev = ({ hookName } :: any) :: Array<HookType>
		else
			table.insert(hookTypesDev, hookName)
		end
	end
end

function updateHookTypesDev()
	if __DEV__ then
		-- ROBLOX FIXME Luau: needs normalization (I think) to avoid duplicate type declaration
		local hookName: HookType = (currentHookNameInDev :: any) :: HookType

		if hookTypesDev ~= nil then
			hookTypesUpdateIndexDev += 1
			if hookTypesDev[hookTypesUpdateIndexDev] ~= hookName then
				warnOnHookMismatchInDev(hookName)
			end
		end
	end
end

local function checkDepsAreArrayDev(deps: any)
	if __DEV__ then
		if deps ~= nil and not isArrayOrSparseArray(deps) then
			-- Verify deps, but only on mount to avoid extra checks.
			-- It's unlikely their type would change as usually you define them inline.
			console.error(
				"%s received a final argument that is not an array (instead, received `%s`). When "
					.. "specified, the final argument must be an array.",
				currentHookNameInDev,
				type(deps)
			)
		end
	end
end

function warnOnHookMismatchInDev(currentHookName: HookType)
	if __DEV__ then
		-- ROBLOX deviation: getComponentName will return nil in most Hook cases, use same fallback as elsewhere
		local componentName = getComponentName(currentlyRenderingFiber.type)
			or "Component"
		if not didWarnAboutMismatchedHooksForComponent[componentName] then
			didWarnAboutMismatchedHooksForComponent[componentName] = true

			if hookTypesDev ~= nil then
				local table_ = ""

				local secondColumnStart = 30

				for i = 1, hookTypesUpdateIndexDev do
					local oldHookName = (hookTypesDev :: any)[i]
					local newHookName
					if i == hookTypesUpdateIndexDev then
						newHookName = currentHookName
					else
						newHookName = oldHookName
					end

					-- ROBLOX note: upstream lets this be void and string concat coerces it to 'undefined'
					local row = tostring(i) .. ". " .. (oldHookName or "undefined")

					-- Extra space so second column lines up
					-- lol @ IE not supporting String#repeat
					while string.len(row) < secondColumnStart do
						row ..= " "
					end

					row ..= newHookName .. "\n"

					table_ ..= row
				end

				console.error(
					"React has detected a change in the order of Hooks called by %s. "
						.. "This will lead to bugs and errors if not fixed. "
						.. "For more information, read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
						.. "   Previous render            Next render\n"
						.. "   ------------------------------------------------------\n"
						.. "%s"
						.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n",
					componentName,
					table_
				)
			end
		end
	end
end

local function throwInvalidHookError(): ()
	error(
		Error.new(
			"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
				.. " one of the following reasons:\n"
				.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
				.. "2. You might be breaking the Rules of Hooks\n"
				.. "3. You might have more than one copy of React in the same app\n"
				.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
		)
	)
end

-- FIXME (roblox): type refinement
-- prevDeps: Array<any>?
local function areHookInputsEqual(nextDeps: Array<any>, prevDeps: Array<any>)
	if __DEV__ then
		if ignorePreviousDependencies then
			-- Only true when this component is being hot reloaded.
			return false
		end
	end

	if prevDeps == nil then
		if __DEV__ then
			-- ROBLOX TODO: no unit tests in upstream for this, we should add some
			console.error(
				"%s received a final argument during this render, but not during "
					.. "the previous render. Even though the final argument is optional, "
					.. "its type cannot change between renders.",
				currentHookNameInDev
			)
		end
		return false
	end

	-- ROBLOX deviation START: calculate lengths with iteration instead of # to
	-- accommodate nil values and disable warning for differing lengths
	local nextDepsLength = getHighestIndex(nextDeps)
	local prevDepsLength = getHighestIndex(prevDeps)

	-- ROBLOX note: In upstream, lengths aren't even compared unless dev mode is
	-- enabled because they _always_ indicate a misuse of dependency arrays. In
	-- luau, since trailing `nil`s effectively change the length of the array,
	-- it's possible to trigger this scenario with a valid use of the dependencies
	-- array (e.g. `{1, 2, 3}` -> `{1, 2, nil}`)
	if nextDepsLength ~= prevDepsLength then
		-- ROBLOX TODO: linting like upstream does would make this warning less
		-- necessary, and would help justify our exclusion of the warning.

		-- https://jira.rbx.com/browse/LUAFDN-1175
		-- if __DEV__ then
		--   console.error(
		--     "The final argument passed to %s changed size between renders. The " ..
		--       "order and size of this array must remain constant.\n\n" ..
		--       "Previous: %s\n" ..
		--       "Incoming: %s",
		--     currentHookNameInDev,
		--     inspect(prevDeps),
		--     inspect(nextDeps)
		--   )
		-- end

		-- Short-circuit here since we know that different lengths means a change in
		-- values, even if it's due to trailing nil values
		return false
	end
	-- ROBLOX deviation END

	local minDependencyCount = math.min(prevDepsLength, nextDepsLength)
	for i = 1, minDependencyCount do
		if is(nextDeps[i], prevDeps[i]) then
			continue
		end
		return false
	end
	return true
end

exports.bailoutHooks = function(current: Fiber, workInProgress: Fiber, lanes: Lanes)
	-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
	workInProgress.updateQueue = current.updateQueue
	if __DEV__ and enableDoubleInvokingEffects then
		workInProgress.flags = bit32.band(
			workInProgress.flags,
			bit32.bnot(
				bit32.bor(
					MountPassiveDevEffect,
					PassiveEffect,
					MountLayoutDevEffect,
					UpdateEffect
				)
			)
		)
	else
		workInProgress.flags = bit32.band(
			workInProgress.flags,
			bit32.bnot(bit32.bor(PassiveEffect, UpdateEffect))
		)
	end
	current.lanes = removeLanes(current.lanes, lanes)
end

local _isUpdatingOpaqueValueInRenderPhase = false
exports.resetHooksAfterThrow = function(): ()
	-- We can assume the previous dispatcher is always this one, since we set it
	-- at the beginning of the render phase and there's no re-entrancy.
	ReactCurrentDispatcher.current = exports.ContextOnlyDispatcher

	if didScheduleRenderPhaseUpdate then
		-- There were render phase updates. These are only valid for this render
		-- phase, which we are now aborting. Remove the updates from the queues so
		-- they do not persist to the next render. Do not remove updates from hooks
		-- that weren't processed.
		--
		-- Only reset the updates from the queue if it has a clone. If it does
		-- not have a clone, that means it wasn't processed, and the updates were
		-- scheduled before we entered the render phase.
		-- FIXME (roblox): Better type refinement
		-- local hook: Hook | nil = currentlyRenderingFiber.memoizedState
		local hook: any = currentlyRenderingFiber.memoizedState
		while hook ~= nil do
			local queue = hook.queue
			if queue ~= nil then
				queue.pending = nil
			end
			hook = hook.next
		end
		didScheduleRenderPhaseUpdate = false
	end

	renderLanes = NoLanes
	currentlyRenderingFiber = nil :: any

	currentHook = nil
	workInProgressHook = nil

	if __DEV__ then
		hookTypesDev = nil
		hookTypesUpdateIndexDev = 0

		currentHookNameInDev = nil

		_isUpdatingOpaqueValueInRenderPhase = false
	end

	didScheduleRenderPhaseUpdateDuringThisPass = false
end

local function mountWorkInProgressHook(): Hook
	local hook: Hook = {
		memoizedState = nil,

		baseState = nil,
		baseQueue = nil,
		queue = nil,

		next = nil,
	}

	if workInProgressHook == nil then
		-- This is the first hook in the list
		currentlyRenderingFiber.memoizedState = hook
		workInProgressHook = hook
	else
		-- Append to the end of the list
		workInProgressHook.next = hook
		workInProgressHook = hook
	end
	return workInProgressHook
end

local function updateWorkInProgressHook(): Hook
	-- This function is used both for updates and for re-renders triggered by a
	-- render phase update. It assumes there is either a current hook we can
	-- clone, or a work-in-progress hook from a previous render pass that we can
	-- use as a base. When we reach the end of the base list, we must switch to
	-- the dispatcher used for mounts.
	-- FIXME (roblox): type refinement
	-- local nextCurrentHook: Hook?
	local nextCurrentHook
	if currentHook == nil then
		local current = currentlyRenderingFiber.alternate
		if current ~= nil then
			nextCurrentHook = current.memoizedState
		else
			nextCurrentHook = nil
		end
	else
		nextCurrentHook = currentHook.next
	end

	-- FIXME (roblox): type refinement
	-- local nextWorkInProgressHook: Hook?
	local nextWorkInProgressHook: Hook
	if workInProgressHook == nil then
		nextWorkInProgressHook = currentlyRenderingFiber.memoizedState
	else
		nextWorkInProgressHook = workInProgressHook.next
	end

	if nextWorkInProgressHook ~= nil then
		-- There's already a work-in-progress. Reuse it.
		workInProgressHook = nextWorkInProgressHook
		nextWorkInProgressHook = workInProgressHook.next

		currentHook = nextCurrentHook
	else
		-- Clone from the current hook.

		-- ROBLOX performance: use React 18 check to avoid function call overhead
		if nextCurrentHook == nil then
			error(Error.new("Rendered more hooks than during the previous render."))
		end

		currentHook = nextCurrentHook

		local newHook: Hook = {
			memoizedState = currentHook.memoizedState,

			baseState = currentHook.baseState,
			baseQueue = currentHook.baseQueue,
			queue = currentHook.queue,

			next = nil,
		}

		if workInProgressHook == nil then
			-- This is the first hook in the list.
			workInProgressHook = newHook
			currentlyRenderingFiber.memoizedState = newHook
		else
			-- Append to the end of the list.
			workInProgressHook.next = newHook
			workInProgressHook = newHook
		end
	end
	return workInProgressHook
end

-- ROBLOX performance: inlined in hot path
-- local function createFunctionComponentUpdateQueue(): FunctionComponentUpdateQueue
--   return {
--     lastEffect = nil,
--   }
-- end

function basicStateReducer<S>(state: S, action: BasicStateAction<S>): S
	-- $FlowFixMe: Flow doesn't like mixed types
	if type(action) == "function" then
		return action(state)
	else
		return action
	end
end

function mountReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = mountWorkInProgressHook()
	local initialState
	if init ~= nil then
		initialState = init(initialArg)
	else
		initialState = (initialArg :: any) :: S
	end
	hook.baseState = initialState
	hook.memoizedState = hook.baseState

	local queue: UpdateQueue<S, A> = {
		pending = nil,
		dispatch = nil,
		lastRenderedReducer = reducer,
		lastRenderedState = initialState :: any,
	}
	hook.queue = queue

	-- deviation: set currentlyRenderingFiber to a local varible so it doesn't change
	-- by call time
	local cRF = currentlyRenderingFiber
	-- ROBLOX FIXME? we pass in action here, but is that what really happens upstream?
	local dispatch: Dispatch<A> = function(action, ...)
		-- ROBLOX Luau FIXME: relies on normalization
		dispatchAction(cRF, queue :: UpdateQueue<any, any>, action, ...)
	end :: any
	queue.dispatch = dispatch :: any
	-- ROBLOX deviation START: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
	-- ROBLOX deviation END: Lua version of useState and useReducer return two items, not list like upstream
end

function updateReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = updateWorkInProgressHook()
	local queue = hook.queue
	-- ROBLOX deviation: change from invariant to avoid funtion call in hot path
	assert(
		queue ~= nil,
		"Should have a queue. This is likely a bug in React. Please file an issue."
	)

	queue.lastRenderedReducer = reducer

	local current: Hook = currentHook

	-- The last rebase update that is NOT part of the base state.
	local baseQueue = current.baseQueue

	-- The last pending update that hasn't been processed yet.
	local pendingQueue = queue.pending
	if pendingQueue ~= nil then
		-- We have new updates that haven't been processed yet.
		-- We'll add them to the base queue.
		if baseQueue ~= nil then
			-- Merge the pending queue and the base queue.
			local baseFirst = baseQueue.next
			local pendingFirst = pendingQueue.next
			baseQueue.next = pendingFirst
			pendingQueue.next = baseFirst
		end
		-- ROBLOX performance: elimiante cmp in hot path
		-- if __DEV__ then
		--   if current.baseQueue ~= baseQueue then
		--     -- Internal invariant that should never happen, but feasibly could in
		--     -- the future if we implement resuming, or some form of that.
		--     console.error(
		--       'Internal error: Expected work-in-progress queue to be a clone. ' ..
		--         'This is a bug in React.'
		--     )
		--   end
		-- end
		baseQueue = pendingQueue
		current.baseQueue = baseQueue
		queue.pending = nil
	end

	if baseQueue ~= nil then
		-- We have a queue to process.
		local first = baseQueue.next
		local newState = current.baseState

		local newBaseState = nil
		local newBaseQueueFirst = nil
		local newBaseQueueLast = nil
		local update = first
		repeat
			local updateLane = update.lane
			-- ROBLOX performance: inline isSubsetOfLanes for hot path
			-- if not isSubsetOfLanes(renderLanes, updateLane) then
			if bit32.band(renderLanes, updateLane) ~= updateLane then
				-- Priority is insufficient. Skip this update. If this is the first
				-- skipped update, the previous update/state is the new base
				-- update/state.
				local clone: Update<S, A> = {
					lane = updateLane,
					action = update.action,
					eagerReducer = update.eagerReducer,
					eagerState = update.eagerState,
					next = nil :: any,
				}
				if newBaseQueueLast == nil then
					newBaseQueueLast = clone
					newBaseQueueFirst = newBaseQueueLast
					newBaseState = newState
				else
					newBaseQueueLast.next = clone
					newBaseQueueLast = newBaseQueueLast.next
				end
				-- Update the remaining priority in the queue.
				-- TODO: Don't need to accumulate this. Instead, we can remove
				-- renderLanes from the original lanes.
				currentlyRenderingFiber.lanes =
					mergeLanes(currentlyRenderingFiber.lanes, updateLane)
				markSkippedUpdateLanes(updateLane)
			else
				-- This update does have sufficient priority.

				if newBaseQueueLast ~= nil then
					local clone: Update<S, A> = {
						-- This update is going to be committed so we never want uncommit
						-- it. Using NoLane works because 0 is a subset of all bitmasks, so
						-- this will never be skipped by the check above.
						lane = NoLane,
						action = update.action,
						eagerReducer = update.eagerReducer,
						eagerState = update.eagerState,
						next = nil :: any,
					}
					newBaseQueueLast.next = clone
					newBaseQueueLast = newBaseQueueLast.next
				end

				-- Process this update.
				if update.eagerReducer == reducer then
					-- If this update was processed eagerly, and its reducer matches the
					-- current reducer, we can use the eagerly computed state.
					newState = update.eagerState
				else
					local action = update.action
					newState = reducer(newState, action)
				end
			end
			update = update.next
		until update == nil or update == first

		if newBaseQueueLast == nil then
			newBaseState = newState
		else
			newBaseQueueLast.next = newBaseQueueFirst
		end

		-- Mark that the fiber performed work, but only if the new state is
		-- different from the current state.
		if not is(newState, hook.memoizedState) then
			markWorkInProgressReceivedUpdate()
		end

		hook.memoizedState = newState
		hook.baseState = newBaseState
		hook.baseQueue = newBaseQueueLast

		queue.lastRenderedState = newState
	end

	local dispatch: Dispatch<A> = queue.dispatch :: any
	-- deviation: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
end

function rerenderReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = updateWorkInProgressHook()
	local queue = hook.queue
	-- ROBLOX performance: changed from invariant to avoid function call in hot path
	assert(
		queue ~= nil,
		"Should have a queue. This is likely a bug in React. Please file an issue."
	)

	queue.lastRenderedReducer = reducer

	-- This is a re-render. Apply the new render phase updates to the previous
	-- work-in-progress hook.
	local dispatch: Dispatch<A> = queue.dispatch :: Dispatch<A>
	local lastRenderPhaseUpdate = queue.pending
	local newState = hook.memoizedState
	if lastRenderPhaseUpdate ~= nil then
		-- The queue doesn't persist past this render pass.
		queue.pending = nil

		local firstRenderPhaseUpdate = lastRenderPhaseUpdate.next
		local update = firstRenderPhaseUpdate
		repeat
			-- Process this render phase update. We don't have to check the
			-- priority because it will always be the same as the current
			-- render's.
			local action = update.action
			newState = reducer(newState, action)
			update = update.next
		until update == firstRenderPhaseUpdate

		-- Mark that the fiber performed work, but only if the new state is
		-- different from the current state.
		if not is(newState, hook.memoizedState) then
			markWorkInProgressReceivedUpdate()
		end

		hook.memoizedState = newState
		-- Don't persist the state accumulated from the render phase updates to
		-- the base state unless the queue is empty.
		-- TODO: Not sure if this is the desired semantics, but it's what we
		-- do for gDSFP. I can't remember why.
		if hook.baseQueue == nil then
			hook.baseState = newState
		end

		queue.lastRenderedState = newState
	end
	-- ROBLOX deviation: Lua version returns two values instead of an array
	return newState, dispatch
end

type MutableSourceMemoizedState<Source, Snapshot> = {
	refs: {
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		setSnapshot: (Snapshot) -> (),
	},
	source: MutableSource<any>,
	subscribe: MutableSourceSubscribeFn<Source, Snapshot>,
}

function readFromUnsubcribedMutableSource<Source, Snapshot>(
	root: FiberRoot,
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>
): Snapshot
	if __DEV__ then
		warnAboutMultipleRenderersDEV(source)
	end

	local getVersion = source._getVersion
	local version_ = getVersion(source._source)

	-- Is it safe for this component to read from this source during the current render?
	local isSafeToReadFromSource = false

	-- Check the version first.
	-- If this render has already been started with a specific version,
	-- we can use it alone to determine if we can safely read from the source.
	local currentRenderVersion = getWorkInProgressVersion(source)
	if currentRenderVersion ~= nil then
		-- It's safe to read if the store hasn't been mutated since the last time
		-- we read something.
		isSafeToReadFromSource = currentRenderVersion == version_
	else
		-- If there's no version, then this is the first time we've read from the
		-- source during the current render pass, so we need to do a bit more work.
		-- What we need to determine is if there are any hooks that already
		-- subscribed to the source, and if so, whether there are any pending
		-- mutations that haven't been synchronized yet.
		--
		-- If there are no pending mutations, then `root.mutableReadLanes` will be
		-- empty, and we know we can safely read.
		--
		-- If there *are* pending mutations, we may still be able to safely read
		-- if the currently rendering lanes are inclusive of the pending mutation
		-- lanes, since that guarantees that the value we're about to read from
		-- the source is consistent with the values that we read during the most
		-- recent mutation.
		isSafeToReadFromSource = isSubsetOfLanes(renderLanes, root.mutableReadLanes)

		if isSafeToReadFromSource then
			-- If it's safe to read from this source during the current render,
			-- store the version in case other components read from it.
			-- A changed version number will local those components know to throw and restart the render.
			setWorkInProgressVersion(source, version_)
		end
	end

	if isSafeToReadFromSource then
		local snapshot = getSnapshot(source._source)
		if __DEV__ then
			-- ROBLOX deviation: the Snapshot generic isn't constrained upstream, but it as to be for this typeof() to work
			if type(snapshot :: any) == "function" then
				console.error(
					"Mutable source should not return a function as the snapshot value. "
						.. "Functions may close over mutable values and cause tearing."
				)
			end
		end
		return snapshot
	else
		-- This handles the special case of a mutable source being shared between renderers.
		-- In that case, if the source is mutated between the first and second renderer,
		-- The second renderer don't know that it needs to reset the WIP version during unwind,
		-- (because the hook only marks sources as dirty if it's written to their WIP version).
		-- That would cause this tear check to throw again and eventually be visible to the user.
		-- We can avoid this infinite loop by explicitly marking the source as dirty.
		--
		-- This can lead to tearing in the first renderer when it resumes,
		-- but there's nothing we can do about that (short of throwing here and refusing to continue the render).
		markSourceAsDirty(source)

		error(
			Error.new(
				"Cannot read from mutable source during the current render without tearing. This is a bug in React. Please file an issue."
			)
		)
	end
end

function useMutableSource<Source, Snapshot>(
	hook: Hook,
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local root: FiberRoot = getWorkInProgressRoot()
	invariant(
		root ~= nil,
		"Expected a work-in-progress root. This is a bug in React. Please file an issue."
	)

	local getVersion = source._getVersion
	local version_ = getVersion(source._source)

	local dispatcher = ReactCurrentDispatcher.current
	-- ROBLOX deviation: upstream doesn't assert non-nil, but we have to for type soundness
	assert(dispatcher ~= nil, "dispatcher was nil, this is a bug in React")
	-- eslint-disable-next-line prefer-const
	local currentSnapshot, setSnapshot = dispatcher.useState(function()
		return readFromUnsubcribedMutableSource(root, source, getSnapshot)
	end)
	local snapshot = currentSnapshot

	-- Grab a handle to the state hook as well.
	-- We use it to clear the pending update queue if we have a new source.

	-- ROBLOX TODO: recast local stateHook = ((workInProgressHook: any): Hook)
	local stateHook = workInProgressHook

	local memoizedState: MutableSourceMemoizedState<any, any> = hook.memoizedState
	if memoizedState.refs == nil then
		error(tostring(debug.traceback()))
	end
	local refs = memoizedState.refs
	local prevGetSnapshot = refs.getSnapshot
	local prevSource = memoizedState.source
	local prevSubscribe = memoizedState.subscribe

	local fiber = currentlyRenderingFiber

	hook.memoizedState = {
		refs = refs,
		source = source,
		subscribe = subscribe,
	}

	-- Sync the values needed by our subscription handler after each commit.
	dispatcher.useEffect(function()
		refs.getSnapshot = getSnapshot

		-- Normally the dispatch function for a state hook never changes,
		-- but this hook recreates the queue in certain cases  to avoid updates from stale sources.
		-- handleChange() below needs to reference the dispatch function without re-subscribing,
		-- so we use a ref to ensure that it always has the latest version.
		refs.setSnapshot = setSnapshot

		-- Check for a possible change between when we last rendered now.
		local maybeNewVersion = getVersion(source._source)
		if not is(version_, maybeNewVersion) then
			local maybeNewSnapshot = getSnapshot(source._source)
			if __DEV__ then
				-- ROBLOX deviation: the Snapshot generic isn't constrained upstream, but it as to be for this typeof() to work
				if type(maybeNewSnapshot :: any) == "function" then
					console.error(
						"Mutable source should not return a function as the snapshot value. "
							.. "Functions may close over mutable values and cause tearing."
					)
				end
			end

			if not is(snapshot, maybeNewSnapshot) then
				setSnapshot(maybeNewSnapshot)

				local lane = requestUpdateLane(fiber)
				markRootMutableRead(root, lane)
			end
			-- If the source mutated between render and now,
			-- there may be state updates already scheduled from the old source.
			-- Entangle the updates so that they render in the same batch.
			markRootEntangled(root, root.mutableReadLanes)
		end
		-- ROBLOX Luau FIXME: Luau doesn't support mixed arrays
	end, { getSnapshot, source, subscribe } :: Array<any>)

	-- If we got a new source or subscribe function, re-subscribe in a passive effect.
	dispatcher.useEffect(function()
		local handleChange = function()
			local latestGetSnapshot = refs.getSnapshot
			local latestSetSnapshot = refs.setSnapshot

			-- ROBLOX performance? only latestGet..() is throwable. hoist the rest out to eliminate anon func overhead?
			local ok, result = pcall(function()
				latestSetSnapshot(latestGetSnapshot(source._source))

				-- Record a pending mutable source update with the same expiration time.
				local lane = requestUpdateLane(fiber)

				markRootMutableRead(root, lane)
			end)

			if not ok then
				-- A selector might throw after a source mutation.
				-- e.g. it might try to read from a part of the store that no longer exists.
				-- In this case we should still schedule an update with React.
				-- Worst case the selector will throw again and then an error boundary will handle it.
				latestSetSnapshot(function()
					error(result)
				end)
			end
		end

		local unsubscribe = subscribe(source._source, handleChange)
		if __DEV__ then
			if type(unsubscribe) ~= "function" then
				console.error(
					"Mutable source subscribe function must return an unsubscribe function."
				)
			end
		end

		return unsubscribe
		-- ROBLOX Luau FIXME: Luau doesn't support mixed arrays
	end, { source, subscribe } :: Array<any>)

	-- If any of the inputs to useMutableSource change, reading is potentially unsafe.
	--
	-- If either the source or the subscription have changed we can't can't trust the update queue.
	-- Maybe the source changed in a way that the old subscription ignored but the new one depends on.
	--
	-- If the getSnapshot function changed, we also shouldn't rely on the update queue.
	-- It's possible that the underlying source was mutated between the when the last "change" event fired,
	-- and when the current render (with the new getSnapshot function) is processed.
	--
	-- In both cases, we need to throw away pending updates (since they are no longer relevant)
	-- and treat reading from the source as we do in the mount case.
	if
		not is(prevGetSnapshot, getSnapshot)
		or not is(prevSource, source)
		or not is(prevSubscribe, subscribe)
	then
		-- Create a new queue and setState method,
		-- So if there are interleaved updates, they get pushed to the older queue.
		-- When this becomes current, the previous queue and dispatch method will be discarded,
		-- including any interleaving updates that occur.
		local newQueue = {
			pending = nil,
			dispatch = nil,
			lastRenderedReducer = basicStateReducer,
			lastRenderedState = snapshot,
		}

		-- ROBLOX deviation: keep local pointer so if global changes we maintain correct reference.
		local cRF = currentlyRenderingFiber

		setSnapshot = function(...)
			dispatchAction(cRF, newQueue, ...)
		end :: any
		newQueue.dispatch = setSnapshot :: any
		stateHook.queue = newQueue
		stateHook.baseQueue = nil
		snapshot = readFromUnsubcribedMutableSource(root, source, getSnapshot)
		stateHook.baseState = snapshot
		stateHook.memoizedState = stateHook.baseState
	end

	return snapshot
end

function mountMutableSource<Source, Snapshot>(
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local hook = mountWorkInProgressHook()
	hook.memoizedState = {
		refs = {
			getSnapshot = getSnapshot,
			setSnapshot = nil,
		},
		source = source,
		subscribe = subscribe,
	}
	return useMutableSource(hook, source, getSnapshot, subscribe)
end

function updateMutableSource<Source, Snapshot>(
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<
		Source,
		Snapshot
	>,
	subscribe: MutableSourceSubscribeFn<
		Source,
		Snapshot
	>
): Snapshot
	local hook = updateWorkInProgressHook()
	return useMutableSource(hook, source, getSnapshot, subscribe)
end

function mountState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	local hook = mountWorkInProgressHook()
	if type(initialState) == "function" then
		-- $FlowFixMe: Flow doesn't like mixed types
		-- deviation: workaround to silence cli analyze not understanding that we've already verified initialState is a function
		local initialStateAsFunction: () -> S = initialState
		initialState = initialStateAsFunction()
	end
	hook.baseState = initialState
	hook.memoizedState = hook.baseState
	local queue: UpdateQueue<S, BasicStateAction<S>> = {
		pending = nil,
		dispatch = nil,
		lastRenderedReducer = nil, --basicStateReducer,
		lastRenderedState = initialState :: any,
	}
	-- ROBLOX Luau FIXME: work around a toposorting issue in Luau: CLI-48752
	queue.lastRenderedReducer = basicStateReducer
	hook.queue = queue

	-- ROBLOX deviation: set currentlyRenderingFiber to a local varible so it doesn't change by call time
	local cRF = currentlyRenderingFiber
	local dispatch: Dispatch<BasicStateAction<S>> = function(action, ...)
		-- ROBLOX FIXME? we pass in action here, but is that what really happens upstream?
		dispatchAction(cRF, queue :: UpdateQueue<any, any>, action, ...)
	end :: any
	queue.dispatch = dispatch
	-- deviation: Lua version of useState and useReducer return two items, not list like upstream
	return hook.memoizedState, dispatch
end

function updateState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	return updateReducer(basicStateReducer, initialState)
end

function rerenderState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	return rerenderReducer(basicStateReducer, initialState)
end

local function pushEffect(tag, create, destroy, deps)
	local effect: Effect = {
		tag = tag,
		create = create,
		destroy = destroy,
		deps = deps,
		-- Circular
		next = nil :: any,
	}
	local componentUpdateQueue: FunctionComponentUpdateQueue =
		currentlyRenderingFiber.updateQueue :: any
	if componentUpdateQueue == nil then
		-- ROBLOX performance: inline simple function in hot path
		-- componentUpdateQueue = createFunctionComponentUpdateQueue()
		componentUpdateQueue = {
			lastEffect = nil,
		}
		currentlyRenderingFiber.updateQueue = componentUpdateQueue
		effect.next = effect
		componentUpdateQueue.lastEffect = effect
	else
		local lastEffect = componentUpdateQueue.lastEffect
		if lastEffect == nil then
			componentUpdateQueue.lastEffect = effect
			effect.next = effect
		else
			local firstEffect = lastEffect.next
			lastEffect.next = effect
			effect.next = firstEffect
			componentUpdateQueue.lastEffect = effect
		end
	end
	return effect
end

-- ROBLOX deviation: Bindings are a feature unique to Roact
function mountBinding<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
	local hook = mountWorkInProgressHook()
	local value, updateValue = createBinding(initialValue)

	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { value :: any, updateValue :: any }
	return value, updateValue
end

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
function updateBinding<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
	local hook = updateWorkInProgressHook()
	return unpack(hook.memoizedState)
end

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
function mountRef<T>(initialValue: T): { current: T | nil }
	local hook = mountWorkInProgressHook()
	-- ROBLOX DEVIATION: Implement useRef with bindings
	local ref: any = createRef()
	ref.current = initialValue
	-- if (__DEV__) then
	--   Object.seal(ref)
	-- end
	hook.memoizedState = ref
	return ref :: { current: T | nil }
end

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
function updateRef<T>(initialValue: T): { current: T | nil }
	local hook = updateWorkInProgressHook()
	return hook.memoizedState
end

local function mountEffectImpl(fiberFlags, hookFlags, create, deps): ()
	local hook = mountWorkInProgressHook()
	-- deviation: no need to account for undefined
	-- local nextDeps = deps == undefined ? nil : deps
	local nextDeps = deps
	currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

	hook.memoizedState =
		pushEffect(bit32.bor(HookHasEffect, hookFlags), create, nil, nextDeps)
end

-- ROBLOX deviation START: must explicitly mark deps argument as optional/nil-able
function updateEffectImpl(fiberFlags, hookFlags, create, deps: Array<any>?): ()
	-- ROBLOX deviation END
	local hook = updateWorkInProgressHook()
	-- ROBLOX deviation: no need to account for undefined
	-- local nextDeps = deps == undefined ? nil : deps
	local nextDeps = deps
	local destroy

	if currentHook ~= nil then
		local prevEffect = currentHook.memoizedState
		destroy = prevEffect.destroy
		if nextDeps ~= nil then
			local prevDeps = prevEffect.deps
			if areHookInputsEqual(nextDeps, prevDeps) then
				hook.memoizedState = pushEffect(hookFlags, create, destroy, nextDeps)
				return
			end
		end
	end

	currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags, fiberFlags)

	hook.memoizedState =
		pushEffect(bit32.bor(HookHasEffect, hookFlags), create, destroy, nextDeps)
end

local function mountEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ as well as jest
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
			warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
		end
	end

	if __DEV__ and enableDoubleInvokingEffects then
		mountEffectImpl(
			bit32.bor(MountPassiveDevEffect, PassiveEffect, PassiveStaticEffect),
			HookPassive,
			create,
			deps
		)
	else
		mountEffectImpl(
			bit32.bor(PassiveEffect, PassiveStaticEffect),
			HookPassive,
			create,
			deps
		)
	end
end

local function updateEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ in addition to jest
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
			warnIfNotCurrentlyActingEffectsInDEV(currentlyRenderingFiber)
		end
	end
	updateEffectImpl(PassiveEffect, HookPassive, create, deps)
end

local function mountLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	if __DEV__ and enableDoubleInvokingEffects then
		mountEffectImpl(
			bit32.bor(MountLayoutDevEffect, UpdateEffect),
			HookLayout,
			create,
			deps
		)
	else
		mountEffectImpl(UpdateEffect, HookLayout, create, deps)
	end
end

local function updateLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any>?
): ()
	updateEffectImpl(UpdateEffect, HookLayout, create, deps)
end

function imperativeHandleEffect<T>(
	create: () -> T,
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil
	-- ROBLOX deviation: explicit type annotation needed due to mixed return
): nil | () -> ...any
	if ref ~= nil and type(ref) == "function" then
		local refCallback = ref
		local inst = create()
		refCallback(inst)
		return function()
			return refCallback(nil)
		end
	elseif ref ~= nil then
		local refObject = ref :: any
		-- ROBLOX deviation: can't check for key presence because nil is a legitimate value.
		if __DEV__ then
			-- ROBLOX FIXME: This is a clumsy approximation, since we don't have any
			-- explicit way to know that something is a ref object; instead, we check
			-- that it's an empty object with a metatable, which is what Roact refs
			-- look like since they indirect to bindings via their metatable
			local isRefObject = getmetatable(refObject) ~= nil
				and #Object.keys(refObject) == 0
			if not isRefObject then
				console.error(
					"Expected useImperativeHandle() first argument to either be a "
						.. "ref callback or React.createRef() object. Instead received: %s.",
					"an object with keys {"
						.. Array.join(Object.keys(refObject), ", ")
						.. "}"
				)
			end
		end
		local inst = create()
		refObject.current = inst
		return function()
			refObject.current = nil
		end
	-- deviation: explicit return to silence analyze
	else
		return nil
	end
end

function mountImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	if __DEV__ then
		if type(create) ~= "function" then
			console.error(
				"Expected useImperativeHandle() second argument to be a function "
					.. "that creates a handle. Instead received: %s.",
				-- ROBLOX deviation START: nil instead of null
				if create ~= nil then type(create) else "nil"
				-- ROBLOX deviation END
			)
		end
	end
	-- TODO: If deps are provided, should we skip comparing the ref itself?
	local effectDeps = if deps ~= nil then Array.concat(deps, { ref }) else nil

	if __DEV__ and enableDoubleInvokingEffects then
		return mountEffectImpl(
			bit32.bor(MountLayoutDevEffect, UpdateEffect),
			HookLayout,
			function()
				return imperativeHandleEffect(create, ref)
			end,
			effectDeps
		)
	else
		return mountEffectImpl(UpdateEffect, HookLayout, function()
			return imperativeHandleEffect(create, ref)
		end, effectDeps)
	end
end

function updateImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	if __DEV__ then
		if type(create) ~= "function" then
			local errorArg = "nil"
			if create then
				errorArg = type(create)
			end
			console.error(
				"Expected useImperativeHandle() second argument to be a function "
					.. "that creates a handle. Instead received: %s.",
				errorArg
			)
		end
	end

	-- TODO: If deps are provided, should we skip comparing the ref itself?
	-- ROBLOX deviation: ternary turned to explicit if/else
	local effectDeps
	if deps ~= nil then
		effectDeps = table.clone(deps)
		table.insert(effectDeps, ref)
	end

	return updateEffectImpl(UpdateEffect, HookLayout, function()
		return imperativeHandleEffect(create, ref)
	end, effectDeps)
end

function mountDebugValue<T>(value: T, formatterFn: nil | (T) -> any): ()
	-- This hook is normally a no-op.
	-- The react-debug-hooks package injects its own implementation
	-- so that e.g. DevTools can display custom hook values.
end

local updateDebugValue = mountDebugValue

function mountCallback<T>(callback: T, deps: Array<any> | nil): T
	local hook = mountWorkInProgressHook()
	local nextDeps = deps
	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { callback :: any, nextDeps :: any }
	return callback
end

function updateCallback<T>(callback: T, deps: Array<any> | nil): T
	local hook = updateWorkInProgressHook()
	local nextDeps = deps
	local prevState = hook.memoizedState
	if prevState ~= nil then
		if nextDeps ~= nil then
			-- ROBLOX TODO: Luau false positive when this is `Array<any>?` (E001) Type 'Array<any>?' could not be converted into 'Array<any>'
			local prevDeps: Array<any> = prevState[2]
			if areHookInputsEqual(nextDeps, prevDeps) then
				return prevState[1]
			end
		end
	end
	-- ROBLOX Luau FIXME: Luau doesn't allow mixed arrays, forcing us to use any here
	hook.memoizedState = { callback :: any, nextDeps :: any }
	return callback
end

-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
function mountMemo<T...>(nextCreate: () -> T..., deps: Array<any> | nil): ...any
	local hook = mountWorkInProgressHook()

	-- deviation: equivilant to upstream ternary logic
	local nextDeps = deps
	-- ROBLOX DEVIATION: Wrap memoized values in a table and unpack to allow for multiple return values
	local nextValue = { nextCreate() }
	hook.memoizedState = { nextValue :: any, nextDeps }
	return unpack(nextValue)
end

-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
function updateMemo<T...>(nextCreate: () -> T..., deps: Array<any> | nil): ...any
	local hook = updateWorkInProgressHook()
	-- deviation: equivilant to upstream ternary logic
	local nextDeps = deps
	local prevState = hook.memoizedState
	if prevState ~= nil then
		-- Assume these are defined. If they're not, areHookInputsEqual will warn.
		if nextDeps ~= nil then
			local prevDeps: Array<any> = prevState[2]
			if areHookInputsEqual(nextDeps, prevDeps) then
				return unpack(prevState[1])
			end
		end
	end
	-- ROBLOX DEVIATION: Wrap memoized values in a table and unpack to allow for multiple return values
	local nextValue = { nextCreate() }
	hook.memoizedState = { nextValue :: any, nextDeps }
	return unpack(nextValue)
end

-- function mountDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = mountState(value)
--   mountEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function updateDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = updateState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function rerenderDeferredValue<T>(value: T): T {
--   local [prevValue, setValue] = rerenderState(value)
--   updateEffect(() => {
--     local prevTransition = ReactCurrentBatchConfig.transition
--     ReactCurrentBatchConfig.transition = 1
--     try {
--       setValue(value)
--     } finally {
--       ReactCurrentBatchConfig.transition = prevTransition
--     end
--   }, [value])
--   return prevValue
-- end

-- function startTransition(setPending, callback)
--   local priorityLevel = getCurrentPriorityLevel()
--   if decoupleUpdatePriorityFromScheduler)
--     local previousLanePriority = getCurrentUpdateLanePriority()
--     setCurrentUpdateLanePriority(
--       higherLanePriority(previousLanePriority, InputContinuousLanePriority),
--     )

--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     -- TODO: Can remove this. Was only necessary because we used to give
--     -- different behavior to transitions without a config object. Now they are
--     -- all treated the same.
--     setCurrentUpdateLanePriority(DefaultLanePriority)

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           if decoupleUpdatePriorityFromScheduler)
--             setCurrentUpdateLanePriority(previousLanePriority)
--           end
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   } else {
--     runWithPriority(
--       priorityLevel < UserBlockingPriority
--         ? UserBlockingPriority
--         : priorityLevel,
--       () => {
--         setPending(true)
--       },
--     )

--     runWithPriority(
--       priorityLevel > NormalPriority ? NormalPriority : priorityLevel,
--       () => {
--         local prevTransition = ReactCurrentBatchConfig.transition
--         ReactCurrentBatchConfig.transition = 1
--         try {
--           setPending(false)
--           callback()
--         } finally {
--           ReactCurrentBatchConfig.transition = prevTransition
--         end
--       },
--     )
--   end
-- end

-- function mountTransition(): [(() => void) => void, boolean] {
--   local [isPending, setPending] = mountState(false)
--   -- The `start` method can be stored on a ref, since `setPending`
--   -- never changes.
--   local start = startTransition.bind(null, setPending)
--   mountRef(start)
--   return [start, isPending]
-- end

-- function updateTransition(): [(() => void) => void, boolean] {
--   local [isPending] = updateState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

-- function rerenderTransition(): [(() => void) => void, boolean] {
--   local [isPending] = rerenderState(false)
--   local startRef = updateRef()
--   local start: (() => void) => void = (startRef.current: any)
--   return [start, isPending]
-- end

local isUpdatingOpaqueValueInRenderPhase = false
exports.getIsUpdatingOpaqueValueInRenderPhaseInDEV = function(): boolean?
	if __DEV__ then
		return isUpdatingOpaqueValueInRenderPhase
	end
	return nil
end

-- function warnOnOpaqueIdentifierAccessInDEV(fiber)
--   if __DEV__ then
--     -- TODO: Should warn in effects and callbacks, too
--     local name = getComponentName(fiber.type) or 'Unknown'
--     if getIsRendering() and not didWarnAboutUseOpaqueIdentifier[name] then
--       console.error(
--         'The object passed back from useOpaqueIdentifier is meant to be ' ..
--           'passed through to attributes only. Do not read the ' ..
--           'value directly.'
--       )
--       didWarnAboutUseOpaqueIdentifier[name] = true
--     end
--   end
-- end

function mountOpaqueIdentifier()
	local makeId
	if __DEV__ then
		console.warn("!!! unimplemented: warnOnOpaqueIdentifierAccessInDEV")
	-- makeId = makeClientIdInDEV.bind(
	--     nil,
	--     warnOnOpaqueIdentifierAccessInDEV.bind(null, currentlyRenderingFiber),
	--   )
	else
		makeId = makeClientId
	end

	if getIsHydrating() then
		unimplemented("ReactFiberHooks: getIsHydrating() true")
		return nil
	--   local didUpgrade = false
	--   local fiber = currentlyRenderingFiber
	--   local readValue = function()
	--     if not didUpgrade then
	--       -- Only upgrade once. This works even inside the render phase because
	--       -- the update is added to a shared queue, which outlasts the
	--       -- in-progress render.
	--       didUpgrade = true
	--       if __DEV__ then
	--         isUpdatingOpaqueValueInRenderPhase = true
	--         setId(makeId())
	--         isUpdatingOpaqueValueInRenderPhase = false
	--         warnOnOpaqueIdentifierAccessInDEV(fiber)
	--       else
	--         setId(makeId())
	--       end
	--     end
	--     invariant(
	--       false,
	--       'The object passed back from useOpaqueIdentifier is meant to be ' ..
	--         'passed through to attributes only. Do not read the value directly.'
	--     )
	--   end
	--   local id = makeOpaqueHydratingObject(readValue)

	--   local setId = mountState(id)[1]

	--   if bit32.band(currentlyRenderingFiber.mode, ReactTypeOfMode.BlockingMode) == ReactTypeOfMode.NoMode then
	--     if __DEV__ and enableDoubleInvokingEffects then
	--       currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags,
	--         MountPassiveDevEffect, PassiveEffect, PassiveStaticEffect)
	--     else
	--       currentlyRenderingFiber.flags = bit32.bor(currentlyRenderingFiber.flags,
	-- 				PassiveEffect, PassiveStaticEffect)
	--     end
	--     pushEffect(
	--       bit32.bor(HookHasEffect, HookPassive),
	--       function()
	--         setId(makeId())
	-- 			end,
	--       nil,
	--       nil
	--     )
	--   end
	--   return id
	else
		local id = makeId()
		mountState(id)
		return id
	end
end

function updateOpaqueIdentifier(): OpaqueIDType
	local id, _ = updateState(nil)
	return id
end

function rerenderOpaqueIdentifier(): OpaqueIDType
	local id, _ = rerenderState(nil)
	return id
end

function dispatchAction<S, A>(fiber: Fiber, queue: UpdateQueue<S, A>, action: A, ...): ()
	if __DEV__ then
		local childrenLength = select("#", ...)
		local extraArg
		if childrenLength == 1 then
			extraArg = select(1, ...)
		end
		if type(extraArg) == "function" then
			console.error(
				"State updates from the useState() and useReducer() Hooks don't support the "
					.. "second callback argument. To execute a side effect after "
					.. "rendering, declare it in the component body with useEffect()."
			)
		end
	end

	local eventTime = requestEventTime()
	local lane = requestUpdateLane(fiber)

	local update: Update<S, A> = {
		lane = lane,
		action = action,
		eagerReducer = nil,
		eagerState = nil,
		next = nil :: any,
	}

	-- Append the update to the end of the list.
	local pending = queue.pending
	if pending == nil then
		-- This is the first update. Create a circular list.
		update.next = update
	else
		update.next = pending.next
		pending.next = update
	end
	queue.pending = update

	local alternate = fiber.alternate
	if
		fiber == currentlyRenderingFiber
		or (alternate ~= nil and alternate == currentlyRenderingFiber)
	then
		-- This is a render phase update. Stash it in a lazily-created map of
		-- queue -> linked list of updates. After this render pass, we'll restart
		-- and apply the stashed updates on top of the work-in-progress hook.
		didScheduleRenderPhaseUpdate = true
		didScheduleRenderPhaseUpdateDuringThisPass = true
	else
		if
			fiber.lanes == NoLanes and (alternate == nil or alternate.lanes == NoLanes)
		then
			-- The queue is currently empty, which means we can eagerly compute the
			-- next state before entering the render phase. If the new state is the
			-- same as the current state, we may be able to bail out entirely.
			local lastRenderedReducer = queue.lastRenderedReducer
			if lastRenderedReducer ~= nil then
				local prevDispatcher
				if __DEV__ then
					prevDispatcher = ReactCurrentDispatcher.current
					ReactCurrentDispatcher.current =
						InvalidNestedHooksDispatcherOnUpdateInDEV
				end
				-- ROBLOX try
				local currentState: S = queue.lastRenderedState :: any
				-- ROBLOX performance: only wrap the thing that can throw in a pcall to elimiante anon function creation overhead
				local ok, eagerState = pcall(lastRenderedReducer, currentState, action)
				-- Stash the eagerly computed state, and the reducer used to compute
				-- it, on the update object. If the reducer hasn't changed by the
				-- time we enter the render phase, then the eager state can be used
				-- without calling the reducer again.
				if ok then
					update.eagerReducer = lastRenderedReducer
					update.eagerState = eagerState
				end

				-- ROBLOX finally
				if __DEV__ then
					ReactCurrentDispatcher.current = prevDispatcher
				end

				if is(eagerState, currentState) then
					-- Fast path. We can bail out without scheduling React to re-render.
					-- It's still possible that we'll need to rebase this update later,
					-- if the component re-renders for a different reason and by that
					-- time the reducer has changed.
					return
				end
				-- ROBLOX catch
				if not ok then
					-- Suppress the error. It will throw again in the render phase.
				end
			end
		end
		if __DEV__ then
			-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
			-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ as well as jest
			if type(_G.jest) ~= "nil" or _G.__TESTEZ_RUNNING_TEST__ then
				warnIfNotScopedWithMatchingAct(fiber)
				warnIfNotCurrentlyActingUpdatesInDEV(fiber)
			end
		end
		scheduleUpdateOnFiber(fiber, lane, eventTime)
	end

	if __DEV__ then
		if enableDebugTracing then
			if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
				local name = getComponentName(fiber.type) or "Unknown"
				logStateUpdateScheduled(name, lane, action)
			end
		end
	end

	if enableSchedulingProfiler then
		markStateUpdateScheduled(fiber, lane)
	end

	return
end

-- deviation: Move these to the top so they're in scope for above functions
local ContextOnlyDispatcher: Dispatcher = {
	readContext = readContext,

	useCallback = throwInvalidHookError :: any,
	useContext = throwInvalidHookError :: any,
	useEffect = throwInvalidHookError :: any,
	useImperativeHandle = throwInvalidHookError :: any,
	useLayoutEffect = throwInvalidHookError :: any,
	useMemo = throwInvalidHookError :: any,
	useReducer = throwInvalidHookError :: any,
	useRef = throwInvalidHookError :: any,
	useBinding = throwInvalidHookError :: any,
	useState = throwInvalidHookError :: any,
	useDebugValue = throwInvalidHookError :: any,
	-- useDeferredValue = throwInvalidHookError,
	-- useTransition = throwInvalidHookError,
	useMutableSource = throwInvalidHookError :: any,
	useOpaqueIdentifier = throwInvalidHookError :: any,

	unstable_isNewReconciler = enableNewReconciler,
}
exports.ContextOnlyDispatcher = ContextOnlyDispatcher

local HooksDispatcherOnMount: Dispatcher = {
	readContext = readContext,

	useCallback = mountCallback,
	useContext = readContext,
	useEffect = mountEffect,
	useImperativeHandle = mountImperativeHandle,
	useLayoutEffect = mountLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = mountMemo :: any,
	useReducer = mountReducer,
	useRef = mountRef,
	useBinding = mountBinding,
	useState = mountState,
	useDebugValue = mountDebugValue,
	-- useDeferredValue = mountDeferredValue,
	-- useTransition = mountTransition,
	useMutableSource = mountMutableSource,
	useOpaqueIdentifier = mountOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnUpdate: Dispatcher = {
	readContext = readContext,

	useCallback = updateCallback,
	useContext = readContext,
	useEffect = updateEffect,
	useImperativeHandle = updateImperativeHandle,
	useLayoutEffect = updateLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = updateMemo :: any,
	useReducer = updateReducer,
	useRef = updateRef,
	useBinding = updateBinding,
	useState = updateState,
	useDebugValue = updateDebugValue,
	-- useDeferredValue = updateDeferredValue,
	-- useTransition = updateTransition,
	useMutableSource = updateMutableSource,
	useOpaqueIdentifier = updateOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

local HooksDispatcherOnRerender: Dispatcher = {
	readContext = readContext,

	useCallback = updateCallback,
	useContext = readContext,
	useEffect = updateEffect,
	useImperativeHandle = updateImperativeHandle,
	useLayoutEffect = updateLayoutEffect,
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = updateMemo :: any,
	useReducer = rerenderReducer,
	useRef = updateRef,
	useBinding = updateBinding,
	useState = rerenderState,
	useDebugValue = updateDebugValue,
	-- useDeferredValue = rerenderDeferredValue,
	-- useTransition = rerenderTransition,
	useMutableSource = updateMutableSource,
	useOpaqueIdentifier = rerenderOpaqueIdentifier,

	unstable_isNewReconciler = enableNewReconciler,
}

if __DEV__ then
	local warnInvalidContextAccess = function()
		console.error(
			"Context can only be read while React is rendering. "
				.. "In classes, you can read it in the render method or getDerivedStateFromProps. "
				.. "In function components, you can read it directly in the function body, but not "
				.. "inside Hooks like useReducer() or useMemo()."
		)
	end

	local warnInvalidHookAccess = function()
		console.error(
			"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks. "
				.. "You can only call Hooks at the top level of your React function. "
				.. "For more information, see "
				.. "https://reactjs.org/link/rules-of-hooks"
		)
	end

	HooksDispatcherOnMountInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			mountHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			mountHookTypesDev()
			checkDepsAreArrayDev(deps)
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			-- ROBLOX FIXME Luau: TypeError: Type 'boolean' could not be converted into 'T'
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			mountHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			mountHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of mountState return two items, not list like upstream.
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- ROBLOX deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			mountHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       mountHookTypesDev()
		--       return mountDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       mountHookTypesDev()
		--       return mountTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			mountHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function()
			currentHookNameInDev = "useOpaqueIdentifier"
			mountHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnMountWithHookTypesInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			checkDepsAreArrayDev(deps)
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of mountState return two items, not list like upstream
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of mountState return two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return mountDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return mountTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function()
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnUpdateInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			return updateCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult = pcall(updateReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of updateState returns two items, not list like upstream
			local ok, result, setResult = pcall(updateState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return updateDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return updateTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return updateOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	HooksDispatcherOnRerenderInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			updateHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			local ok, result, setResult =
				pcall(rerenderReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- ROBLOX deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnRerenderInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(rerenderState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       updateHookTypesDev()
		--       return rerenderDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       updateHookTypesDev()
		--       return rerenderTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			updateHookTypesDev()
			return rerenderOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnMountInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(mountMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			local ok, result, setResult = pcall(mountReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			mountHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnMountInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(mountState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountDebugValue(value, formatterFn)
		end,
		-- useDeferredValue<T>(value: T): T {
		--   currentHookNameInDev = 'useDeferredValue'
		--   warnInvalidHookAccess()
		--   mountHookTypesDev()
		--   return mountDeferredValue(value)
		-- },
		-- useTransition(): [(() => void) => void, boolean] {
		--   currentHookNameInDev = 'useTransition'
		--   warnInvalidHookAccess()
		--   mountHookTypesDev()
		--   return mountTransition()
		-- },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			mountHookTypesDev()
			return mountOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnUpdateInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return mountCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult = pcall(updateReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher

			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(updateState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return updateDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return updateTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}

	InvalidNestedHooksDispatcherOnRerenderInDEV = {
		readContext = function<T>(context: ReactContext<T>, observedBits: number | boolean | nil): T
			warnInvalidContextAccess()
			return readContext(context, observedBits)
		end,
		useCallback = function<T>(callback: T, deps: Array<any> | nil): T
			currentHookNameInDev = "useCallback"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateCallback(callback, deps)
		end,
		useContext = function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
			currentHookNameInDev = "useContext"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return readContext(context, observedBits)
		end,
		useEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateEffect(create, deps)
		end,
		useImperativeHandle = function<T>(
			ref: { current: T | nil } | ((inst: T | nil) -> ...any) | nil,
			create: () -> T,
			deps: Array<any> | nil
		): ()
			currentHookNameInDev = "useImperativeHandle"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateImperativeHandle(ref, create, deps)
		end,
		useLayoutEffect = function(
			-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
			create: (() -> ()) | (() -> (() -> ())),
			deps: Array<any>?
		): ()
			currentHookNameInDev = "useLayoutEffect"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateLayoutEffect(create, deps)
		end,
		-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
		useMemo = function<T...>(create: () -> T..., deps: Array<any> | nil): ...any
			currentHookNameInDev = "useMemo"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			--[[
        ROBLOX DEVIATION: `results` captures all pcall return value: either
        { false, errorObject } or { true, ...returnValues }
      ]]
			local results = { pcall(updateMemo, create, deps) }
			ReactCurrentDispatcher.current = prevDispatcher
			if not results[1] then
				error(results[2])
			end
			return unpack(results, 2)
		end :: any,
		useReducer = function<S, I, A>(
			reducer: (S, A) -> S,
			initialArg: I,
			init: ((I) -> S)?
		): (S, Dispatch<A>)
			currentHookNameInDev = "useReducer"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			local ok, result, setResult =
				pcall(rerenderReducer, reducer, initialArg, init)
			-- ROBLOX finally
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState and useReducer return two items, not list like upstream
			return result, setResult
		end,
		-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
		useRef = function<T>(initialValue: T): { current: T | nil }
			currentHookNameInDev = "useRef"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateRef(initialValue)
		end,
		-- ROBLOX deviation: Bindings are a feature unique to Roact
		useBinding = function<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
			currentHookNameInDev = "useBinding"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateBinding(initialValue)
		end,
		useState = function<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
			currentHookNameInDev = "useState"
			warnInvalidHookAccess()
			updateHookTypesDev()
			local prevDispatcher = ReactCurrentDispatcher.current
			ReactCurrentDispatcher.current = InvalidNestedHooksDispatcherOnUpdateInDEV
			-- deviation: Lua version of useState returns two items, not list like upstream
			local ok, result, setResult = pcall(rerenderState, initialState)
			ReactCurrentDispatcher.current = prevDispatcher
			if not ok then
				error(result)
			end
			-- deviation: Lua version of useState returns two items, not list like upstream
			return result, setResult
		end,
		useDebugValue = function<T>(value: T, formatterFn: ((value: T) -> any)?): ()
			currentHookNameInDev = "useDebugValue"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateDebugValue(value, formatterFn)
		end,
		--     useDeferredValue<T>(value: T): T {
		--       currentHookNameInDev = 'useDeferredValue'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return rerenderDeferredValue(value)
		--     },
		--     useTransition(): [(() => void) => void, boolean] {
		--       currentHookNameInDev = 'useTransition'
		--       warnInvalidHookAccess()
		--       updateHookTypesDev()
		--       return rerenderTransition()
		--     },
		useMutableSource = function<Source, Snapshot>(
			source: MutableSource<Source>,
			getSnapshot: MutableSourceGetSnapshotFn<
				Source,
				Snapshot
			>,
			subscribe: MutableSourceSubscribeFn<
				Source,
				Snapshot
			>
		): Snapshot
			currentHookNameInDev = "useMutableSource"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return updateMutableSource(source, getSnapshot, subscribe)
		end,
		useOpaqueIdentifier = function(): OpaqueIDType
			currentHookNameInDev = "useOpaqueIdentifier"
			warnInvalidHookAccess()
			updateHookTypesDev()
			return rerenderOpaqueIdentifier()
		end,

		unstable_isNewReconciler = enableNewReconciler,
	}
end

local function renderWithHooks<Props, SecondArg>(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: (p: Props, arg: SecondArg) -> any,
	props: Props,
	secondArg: SecondArg,
	nextRenderLanes: Lanes
): any
	renderLanes = nextRenderLanes
	currentlyRenderingFiber = workInProgress

	if __DEV__ then
		hookTypesDev = if current ~= nil
			then (current._debugHookTypes :: any) :: Array<HookType>
			else nil
		-- ROBLOX deviation START: index variable offset by one for Lua
		hookTypesUpdateIndexDev = 0
		-- ROBLOX deviation END
		-- Used for hot reloading:
		-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
		-- ignorePreviousDependencies =
		--   current ~= nil and current.type ~= workInProgress.type
	end

	workInProgress.memoizedState = nil
	-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
	workInProgress.updateQueue = nil
	workInProgress.lanes = NoLanes

	-- The following should have already been reset
	-- currentHook = nil
	-- workInProgressHook = nil

	-- didScheduleRenderPhaseUpdate = false

	-- TODO Warn if no hooks are used at all during mount, then some are used during update.
	-- Currently we will identify the update render as a mount because memoizedState == nil.
	-- This is tricky because it's valid for certain types of components (e.g. React.lazy)

	-- Using memoizedState to differentiate between mount/update only works if at least one stateful hook is used.
	-- Non-stateful hooks (e.g. context) don't get added to memoizedState,
	-- so memoizedState would be nil during updates and mounts.
	if __DEV__ then
		if current ~= nil and current.memoizedState ~= nil then
			ReactCurrentDispatcher.current = HooksDispatcherOnUpdateInDEV
		elseif hookTypesDev ~= nil then
			-- This dispatcher handles an edge case where a component is updating,
			-- but no stateful hooks have been used.
			-- We want to match the production code behavior (which will use HooksDispatcherOnMount),
			-- but with the extra DEV validation to ensure hooks ordering hasn't changed.
			-- This dispatcher does that.
			ReactCurrentDispatcher.current = HooksDispatcherOnMountWithHookTypesInDEV
		else
			ReactCurrentDispatcher.current = HooksDispatcherOnMountInDEV
		end
	else
		ReactCurrentDispatcher.current = (current == nil or current.memoizedState == nil)
				and HooksDispatcherOnMount
			or HooksDispatcherOnUpdate
	end

	local children = Component(props, secondArg)

	-- Check if there was a render phase update
	if didScheduleRenderPhaseUpdateDuringThisPass then
		-- Keep rendering in a loop for as long as render phase updates continue to
		-- be scheduled. Use a counter to prevent infinite loops.
		local numberOfReRenders: number = 0
		repeat
			didScheduleRenderPhaseUpdateDuringThisPass = false
			-- ROBLOX performance: use React 18 approach to avoid invariant in hot path
			if numberOfReRenders >= RE_RENDER_LIMIT then
				error(
					Error.new(
						"Too many re-renders. React limits the number of renders to prevent "
							.. "an infinite loop."
					)
				)
			end

			numberOfReRenders += 1
			-- ROBLOX performance: eliminate unuseful cmp in hot path, we don't currently support hot reloading
			-- if __DEV__ then
			-- Even when hot reloading, allow dependencies to stabilize
			-- after first render to prevent infinite render phase updates.
			-- ignorePreviousDependencies = false
			-- end

			-- Start over from the beginning of the list
			currentHook = nil
			workInProgressHook = nil

			-- ROBLOX performance TODO: return non-nil updateQueue object to the ReactUpdateQUeue pool
			workInProgress.updateQueue = nil

			if __DEV__ then
				-- Also validate hook order for cascading updates.
				hookTypesUpdateIndexDev = 0
			end

			ReactCurrentDispatcher.current = __DEV__ and HooksDispatcherOnRerenderInDEV
				or HooksDispatcherOnRerender

			children = Component(props, secondArg)
		until not didScheduleRenderPhaseUpdateDuringThisPass
	end

	-- We can assume the previous dispatcher is always this one, since we set it
	-- at the beginning of the render phase and there's no re-entrancy.
	ReactCurrentDispatcher.current = ContextOnlyDispatcher

	if __DEV__ then
		workInProgress._debugHookTypes = hookTypesDev
	end

	-- This check uses currentHook so that it works the same in DEV and prod bundles.
	-- hookTypesDev could catch more cases (e.g. context) but only in DEV bundles.
	local didRenderTooFewHooks = currentHook ~= nil and currentHook.next ~= nil

	renderLanes = NoLanes
	currentlyRenderingFiber = nil :: any

	currentHook = nil
	workInProgressHook = nil

	if __DEV__ then
		currentHookNameInDev = nil
		hookTypesDev = nil
		hookTypesUpdateIndexDev = 0
	end

	didScheduleRenderPhaseUpdate = false

	-- ROBLOX performance: use React 18 approach that avoid invariant in hot paths
	if didRenderTooFewHooks then
		error(
			Error.new(
				"Rendered fewer hooks than expected. This may be caused by an accidental "
					.. "early return statement."
			)
		)
	end

	return children
end
exports.renderWithHooks = renderWithHooks

return exports
