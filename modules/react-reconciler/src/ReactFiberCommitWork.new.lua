-- ROBLOX upstream: https://github.com/facebook/react/blob/7f08e908b10a58cda902611378ec053003d371ed/packages/react-reconciler/src/ReactFiberCommitWork.new.js
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
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local __DEV__ = _G.__DEV__ :: boolean
local __YOLO__ = _G.__YOLO__ :: boolean
-- ROBLOX DEVIATION: keep track of the pcall run depth and stop wrapping pcalls after we hit MAX_RUN_DEPTH.
-- ROBLOX note: if this number is raised to 195, the test in RoactRecursiveLayoutPcallDepth will fail
local runDepth = 0
local MAX_RUN_DEPTH = 20

local function isCallable(value)
	if typeof(value) == "function" then
		return true
	end
	if typeof(value) == "table" then
		local mt = getmetatable(value)
		if mt and rawget(mt, "__call") then
			return true
		end
		if value._isMockFunction then
			return true
		end
	end
	return false
end

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local Set = LuauPolyfill.Set
type Array<T> = { [number]: T }

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Instance = ReactFiberHostConfig.Instance
type Container = ReactFiberHostConfig.Container
type TextInstance = ReactFiberHostConfig.TextInstance
-- ROBLOX deviation START: we have to inline, because type imports don't work across dynamic requires like HostConfig
-- local type {
--   SuspenseInstance,
--   ChildSet,
--   UpdatePayload,
type UpdatePayload = Array<any>
-- } = require(script.Parent.ReactFiberHostConfig)
-- ROBLOX deviation END
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactUpdateQueueModule = require(script.Parent["ReactUpdateQueue.new"])
type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>

-- local ReactFiberHooks = require(script.Parent["ReactFiberHooks.new"])
-- type FunctionComponentUpdateQueue = ReactFiberHooks.FunctionComponentUpdateQueue
-- ROBLOX deviation: inline the typedef here to avoid circular dependency
type Effect = {
	tag: HookFlags,
	create: () -> (() -> ())?,
	destroy: (() -> ())?,
	deps: Array<any>?,
	next: Effect,
}
type FunctionComponentUpdateQueue = {
	lastEffect: Effect?,
}

local ReactTypes = require(Packages.Shared)
type Wakeable = ReactTypes.Wakeable

type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactFiberOffscreenComponent = require(script.Parent.ReactFiberOffscreenComponent)
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState
local ReactHookEffectTags = require(script.Parent.ReactHookEffectTags)
type HookFlags = ReactHookEffectTags.HookFlags

-- ROBLOX deviation: import tracing as a top-level export to avoid direct file access
local Schedule_tracing_wrap = require(Packages.Scheduler).tracing.unstable_wrap
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableProfilerCommitHooks = ReactFeatureFlags.enableProfilerCommitHooks
-- local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local FunctionComponent = ReactWorkTags.FunctionComponent
local ForwardRef = ReactWorkTags.ForwardRef
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local DehydratedFragment = ReactWorkTags.DehydratedFragment
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local Block = ReactWorkTags.Block
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactErrorUtils = require(Packages.Shared).ReactErrorUtils
local invokeGuardedCallback = ReactErrorUtils.invokeGuardedCallback
local hasCaughtError = ReactErrorUtils.hasCaughtError
local clearCaughtError = ReactErrorUtils.clearCaughtError
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local NoFlags = ReactFiberFlags.NoFlags
local ContentReset = ReactFiberFlags.ContentReset
local Placement = ReactFiberFlags.Placement
local Snapshot = ReactFiberFlags.Snapshot
local Update = ReactFiberFlags.Update
local Callback = ReactFiberFlags.Callback
local LayoutMask = ReactFiberFlags.LayoutMask
local PassiveMask = ReactFiberFlags.PassiveMask
local Ref = ReactFiberFlags.Ref
local getComponentName = require(Packages.Shared).getComponentName
local invariant = require(Packages.Shared).invariant
local describeError = require(Packages.Shared).describeError
local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
--  ROBLOX deviation: this property would be captured as values instead of bound
local currentDebugFiberInDEV = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local onCommitUnmount =
	require(script.Parent["ReactFiberDevToolsHook.new"]).onCommitUnmount
local resolveDefaultProps =
	require(script.Parent["ReactFiberLazyComponent.new"]).resolveDefaultProps
local ReactProfilerTimer = require(script.Parent["ReactProfilerTimer.new"])
local startLayoutEffectTimer = ReactProfilerTimer.startLayoutEffectTimer
local recordPassiveEffectDuration = ReactProfilerTimer.recordPassiveEffectDuration
local recordLayoutEffectDuration = ReactProfilerTimer.recordLayoutEffectDuration
local startPassiveEffectTimer = ReactProfilerTimer.startPassiveEffectTimer
local getCommitTime = ReactProfilerTimer.getCommitTime
local ProfileMode = require(script.Parent.ReactTypeOfMode).ProfileMode
local commitUpdateQueue = ReactUpdateQueueModule.commitUpdateQueue
local getPublicInstance = ReactFiberHostConfig.getPublicInstance
local supportsMutation = ReactFiberHostConfig.supportsMutation
local supportsPersistence = ReactFiberHostConfig.supportsPersistence
local supportsHydration = ReactFiberHostConfig.supportsHydration
local commitMount = ReactFiberHostConfig.commitMount
local commitUpdate = ReactFiberHostConfig.commitUpdate
local resetTextContent = ReactFiberHostConfig.resetTextContent
local commitTextUpdate = ReactFiberHostConfig.commitTextUpdate
local appendChild = ReactFiberHostConfig.appendChild
local appendChildToContainer = ReactFiberHostConfig.appendChildToContainer
local insertBefore = ReactFiberHostConfig.insertBefore
local insertInContainerBefore = ReactFiberHostConfig.insertInContainerBefore
local removeChild = ReactFiberHostConfig.removeChild
local removeChildFromContainer = ReactFiberHostConfig.removeChildFromContainer
-- local clearSuspenseBoundary = ReactFiberHostConfig.clearSuspenseBoundary
-- local clearSuspenseBoundaryFromContainer = ReactFiberHostConfig.clearSuspenseBoundaryFromContainer
-- local replaceContainerChildren = ReactFiberHostConfig.replaceContainerChildren
-- local createContainerChildSet = ReactFiberHostConfig.createContainerChildSet
local hideInstance = ReactFiberHostConfig.hideInstance
local hideTextInstance = ReactFiberHostConfig.hideTextInstance
local unhideInstance = ReactFiberHostConfig.unhideInstance
local unhideTextInstance = ReactFiberHostConfig.unhideTextInstance
-- local unmountFundamentalComponent = ReactFiberHostConfig.unmountFundamentalComponent
-- local updateFundamentalComponent = ReactFiberHostConfig.updateFundamentalComponent
-- local commitHydratedContainer = ReactFiberHostConfig.commitHydratedContainer
local commitHydratedSuspenseInstance = ReactFiberHostConfig.commitHydratedSuspenseInstance
local clearContainer = ReactFiberHostConfig.clearContainer
-- local prepareScopeUpdate = ReactFiberHostConfig.prepareScopeUpdate

-- ROBLOX deviation: Lazy init to avoid circular dependencies
local ReactFiberWorkLoop

local function resolveRetryWakeable(boundaryFiber: Fiber, wakeable: Wakeable): ()
	if not ReactFiberWorkLoop then
		ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
	end
	ReactFiberWorkLoop.resolveRetryWakeable(boundaryFiber, wakeable)
end

local function markCommitTimeOfFallback(): ()
	if not ReactFiberWorkLoop then
		ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
	end
	ReactFiberWorkLoop.markCommitTimeOfFallback()
end

-- deviation: stub to allow dependency injection that breaks circular dependency
local function schedulePassiveEffectCallback(): ()
	console.warn(
		"ReactFiberCommitWork: schedulePassiveEffectCallback causes a dependency cycle\n"
			.. debug.traceback()
	)
end

-- deviation: stub to allow dependency injection that breaks circular dependency
local function captureCommitPhaseError(
	rootFiber: Fiber,
	sourceFiber: Fiber | nil,
	error_: any?
): ()
	console.warn(
		"ReactFiberCommitWork: captureCommitPhaseError causes a dependency cycle"
	)
	error(error_)
end

local NoHookEffect = ReactHookEffectTags.NoFlags
local HookHasEffect = ReactHookEffectTags.HasEffect
local HookLayout = ReactHookEffectTags.Layout
local HookPassive = ReactHookEffectTags.Passive

-- ROBLOX deviation: lazy init to break cyclic dependency
local didWarnAboutReassigningPropsRef
local didWarnAboutReassigningProps = function()
	if not didWarnAboutReassigningPropsRef then
		didWarnAboutReassigningPropsRef =
			require(script.Parent["ReactFiberBeginWork.new"]).didWarnAboutReassigningProps
	end
	return didWarnAboutReassigningPropsRef
end

-- deviation: Common types
type Set<T> = { [T]: boolean }

-- deviation: pre-declare functions when necessary
local isHostParent, getHostSibling, insertOrAppendPlacementNode, insertOrAppendPlacementNodeIntoContainer, commitLayoutEffectsForHostRoot, commitLayoutEffectsForHostComponent, commitLayoutEffectsForClassComponent, unmountHostComponents, commitNestedUnmounts, commitUnmount

-- Used to avoid traversing the return path to find the nearest Profiler ancestor during commit.
local nearestProfilerOnStack: Fiber | nil = nil

-- deviation: Not possible to return `undefined` in lua
-- local didWarnAboutUndefinedSnapshotBeforeUpdate: Set<any>? = nil
-- if __DEV__ then
--   didWarnAboutUndefinedSnapshotBeforeUpdate = {}
-- end

-- local PossiblyWeakSet = typeof WeakSet == 'function' ? WeakSet : Set

local function callComponentWillUnmountWithTimer(current, instance)
	instance.props = current.memoizedProps
	instance.state = current.memoizedState
	if
		enableProfilerTimer
		and enableProfilerCommitHooks
		and bit32.band(current.mode, ProfileMode) ~= 0
	then
		-- ROBLOX performance? we could hoist start...Timer() out and eliminate the anon function, but then the timer would incldue the pcall overhead
		local ok, exception = xpcall(function()
			startLayoutEffectTimer()
			-- ROBLOX deviation: Call with ":" so that the method receives self
			instance:componentWillUnmount()
		end, describeError)

		recordLayoutEffectDuration(current)

		if not ok then
			error(exception)
		end
	else
		-- ROBLOX deviation: Call with ":" so that the method receives self
		instance:componentWillUnmount()
	end
end

-- Capture errors so they don't interrupt unmounting.
function safelyCallComponentWillUnmount(
	current: Fiber,
	instance: any,
	nearestMountedAncestor
): ()
	-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
	local ok, error_ =
		xpcall(callComponentWillUnmountWithTimer, describeError, current, instance)

	if not ok then
		captureCommitPhaseError(current, nearestMountedAncestor, error_)
	end
end

local function safelyDetachRef(current: Fiber, nearestMountedAncestor: Fiber): ()
	local ref = current.ref
	if ref ~= nil then
		if typeof(ref) == "function" then
			-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
			local ok, error_ = xpcall(ref, describeError)
			if not ok then
				captureCommitPhaseError(current, nearestMountedAncestor, error_)
			end
		else
			-- ROBLOX FIXME Luau: next line gets Expected type table, got 'RefObject | {| [string]: any, _stringRef: string? |}' instead
			ref.current = nil
		end
	end
end

local function safelyCallDestroy(
	current: Fiber,
	nearestMountedAncestor: Fiber | nil,
	destroy: () -> ()
): ()
	-- ROBLOX performance: eliminate the __DEV__ and invokeGuardedCallback, like React 18 has done
	local ok, error_ = xpcall(destroy, describeError)
	if not ok then
		captureCommitPhaseError(current, nearestMountedAncestor, error_)
	end
end

local function commitBeforeMutationLifeCycles(
	current: Fiber | nil,
	finishedWork: Fiber
): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		return
	elseif finishedWork.tag == ClassComponent then
		if bit32.band(finishedWork.flags, Snapshot) ~= 0 then
			if current ~= nil then
				local prevProps = (current :: Fiber).memoizedProps
				local prevState = (current :: Fiber).memoizedState
				local instance = finishedWork.stateNode
				-- We could update instance props and state here,
				-- but instead we rely on them being set during last render.
				-- TODO: revisit this when we implement resuming.
				if __DEV__ then
					if
						finishedWork.type == finishedWork.elementType
						and not didWarnAboutReassigningProps
					then
						if instance.props ~= finishedWork.memoizedProps then
							console.error(
								"Expected %s props to match memoized props before "
									.. "getSnapshotBeforeUpdate. "
									.. "This might either be because of a bug in React, or because "
									.. "a component reassigns its own `this.props`. "
									.. "Please file an issue.",
								getComponentName(finishedWork.type) or "instance"
							)
						end
						if instance.state ~= finishedWork.memoizedState then
							console.error(
								"Expected %s state to match memoized state before "
									.. "getSnapshotBeforeUpdate. "
									.. "This might either be because of a bug in React, or because "
									.. "a component reassigns its own `this.state`. "
									.. "Please file an issue.",
								getComponentName(finishedWork.type) or "instance"
							)
						end
					end
				end
				-- deviation: Call with ':' instead of '.' so that self is available
				local snapshot = instance:getSnapshotBeforeUpdate(
					finishedWork.elementType == finishedWork.type and prevProps
						or resolveDefaultProps(finishedWork.type, prevProps),
					prevState
				)
				if __DEV__ then
					-- ROBLOX deviation: not possible to return `undefined` in Lua
					-- local didWarnSet = ((didWarnAboutUndefinedSnapshotBeforeUpdate: any): Set<mixed>)
					-- if snapshot == nil and not didWarnSet[finishedWork.type] then
					--   didWarnSet[finishedWork.type] = true
					--   console.error(
					--     "%s.getSnapshotBeforeUpdate(): A snapshot value (or nil) " ..
					--       "must be returned. You have returned undefined.",
					--     getComponentName(finishedWork.type)
					--   )
					-- end
				end
				instance.__reactInternalSnapshotBeforeUpdate = snapshot
			end
		end
		return
	elseif finishedWork.tag == HostRoot then
		if supportsMutation then
			if bit32.band(finishedWork.flags, Snapshot) ~= 0 then
				local root = finishedWork.stateNode
				clearContainer(root.containerInfo)
			end
		end
		return
	elseif
		finishedWork.tag == HostComponent
		or finishedWork.tag == HostText
		or finishedWork.tag == HostPortal
		or finishedWork.tag == IncompleteClassComponent
	then
		-- Nothing to do for these component types
		return
	end
	invariant(
		false,
		"This unit of work tag should not have side-effects. This error is "
			.. "likely caused by a bug in React. Please file an issue."
	)
end

local function commitHookEffectListUnmount(
	flags: HookFlags,
	finishedWork: Fiber,
	nearestMountedAncestor: Fiber?
)
	local updateQueue: FunctionComponentUpdateQueue | nil = finishedWork.updateQueue
	local lastEffect
	if updateQueue ~= nil then
		lastEffect = (updateQueue :: FunctionComponentUpdateQueue).lastEffect
	end

	if lastEffect ~= nil then
		local firstEffect = lastEffect.next
		local effect = firstEffect
		repeat
			if bit32.band(effect.tag, flags) == flags then
				-- Unmount
				local destroy = effect.destroy
				effect.destroy = nil
				if destroy ~= nil then
					safelyCallDestroy(finishedWork, nearestMountedAncestor, destroy)
				end
			end
			effect = effect.next
		until effect == firstEffect
	end
end

local function commitHookEffectListMount(flags: HookFlags, finishedWork: Fiber)
	local updateQueue: FunctionComponentUpdateQueue | nil =
		finishedWork.updateQueue :: any
	local lastEffect = if updateQueue ~= nil then updateQueue.lastEffect else nil
	if lastEffect ~= nil then
		local firstEffect = lastEffect.next
		local effect = firstEffect
		repeat
			if bit32.band(effect.tag, flags) == flags then
				-- Mount
				local create = effect.create
				effect.destroy = create()

				if __DEV__ then
					local destroy = effect.destroy
					if destroy ~= nil and typeof(destroy) ~= "function" then
						local addendum
						if destroy == nil then
							addendum = " You returned nil. If your effect does not require clean "
								.. "up, return nil (or nothing)."
						elseif typeof(destroy.andThen) == "function" then
							addendum =
								-- ROBLOX FIXME: write a real program that does the equivalent and update this example, LUAFDN-754
								"\n\nIt looks like you wrote useEffect(Promise.new(function() --[[...]] end) or returned a Promise. " .. "Instead, write the async function inside your effect " .. "and call it immediately:\n\n" .. "useEffect(function()\n" .. "  function fetchData()\n" .. "    -- You can await here\n" .. "    local response = MyAPI.getData(someId):await()\n" .. "    -- ...\n" .. "  end\n" .. "  fetchData()\n" .. "end, {someId}) -- Or {} if effect doesn't need props or state\n\n" .. "Learn more about data fetching with Hooks: https://reactjs.org/link/hooks-data-fetching"
						else
							addendum = " You returned: " .. destroy
						end
						console.error(
							"An effect function must not return anything besides a function, "
								.. "which is used for clean-up.%s",
							addendum
						)
					end
				end
			end
			effect = effect.next
		until effect == firstEffect
	end
end

function commitProfilerPassiveEffect(finishedRoot: FiberRoot, finishedWork: Fiber): ()
	if enableProfilerTimer and enableProfilerCommitHooks then
		if finishedWork.tag == Profiler then
			local passiveEffectDuration = finishedWork.stateNode.passiveEffectDuration
			local id, onPostCommit =
				finishedWork.memoizedProps.id, finishedWork.memoizedProps.onPostCommit

			-- This value will still reflect the previous commit phase.
			-- It does not get reset until the start of the next commit phase.
			local commitTime = getCommitTime()

			if typeof(onPostCommit) == "function" then
				if enableSchedulerTracing then
					onPostCommit(
						id,
						if finishedWork.alternate == nil then "mount" else "update",
						passiveEffectDuration,
						commitTime,
						finishedRoot.memoizedInteractions
					)
				else
					onPostCommit(
						id,
						if finishedWork.alternate == nil then "mount" else "update",
						passiveEffectDuration,
						commitTime
					)
				end
			end
		end
	end
end

local function recursivelyCommitLayoutEffects(
	finishedWork: Fiber,
	finishedRoot: FiberRoot,
	-- ROBLOX deviation: pass in these functions to avoid dependency cycle
	_captureCommitPhaseError: (
		sourceFiber: Fiber,
		nearestMountedAncestor: Fiber?,
		error: any
	) -> (),
	_schedulePassiveEffectCallback: () -> ()
)
	if _captureCommitPhaseError ~= nil then
		captureCommitPhaseError = _captureCommitPhaseError
	end
	if _schedulePassiveEffectCallback ~= nil then
		schedulePassiveEffectCallback = _schedulePassiveEffectCallback
	end
	local flags = finishedWork.flags
	local tag = finishedWork.tag
	if tag == Profiler then
		local prevProfilerOnStack = nil
		if enableProfilerTimer and enableProfilerCommitHooks then
			prevProfilerOnStack = nearestProfilerOnStack
			nearestProfilerOnStack = finishedWork
		end

		local child = finishedWork.child
		while child ~= nil do
			local primarySubtreeFlags = bit32.band(finishedWork.subtreeFlags, LayoutMask)
			if primarySubtreeFlags ~= NoFlags then
				if __DEV__ then
					local prevCurrentFiberInDEV = currentDebugFiberInDEV
					setCurrentDebugFiberInDEV(child)
					invokeGuardedCallback(
						nil,
						recursivelyCommitLayoutEffects,
						nil,
						child,
						finishedRoot,
						-- ROBLOX deviation: pass in these functions to avoid dependency cycle
						captureCommitPhaseError,
						schedulePassiveEffectCallback
					)
					if hasCaughtError() then
						local error_ = clearCaughtError()
						captureCommitPhaseError(child, finishedWork, error_)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					local ok, error_ = xpcall(
						-- ROBLOX deviation: pass in captureCommitPhaseError function to avoid dependency cycle
						recursivelyCommitLayoutEffects,
						describeError,
						child,
						finishedRoot,
						captureCommitPhaseError,
						schedulePassiveEffectCallback
					)
					if not ok then
						captureCommitPhaseError(child, finishedWork, error_)
					end
				end
			end
			child = child.sibling
		end

		local primaryFlags = bit32.band(flags, bit32.bor(Update, Callback))
		if primaryFlags ~= NoFlags then
			if enableProfilerTimer then
				if __DEV__ then
					local prevCurrentFiberInDEV = currentDebugFiberInDEV
					setCurrentDebugFiberInDEV(finishedWork)
					invokeGuardedCallback(
						nil,
						commitLayoutEffectsForProfiler,
						nil,
						finishedWork,
						finishedRoot
					)
					if hasCaughtError() then
						local error_ = clearCaughtError()
						captureCommitPhaseError(
							finishedWork,
							finishedWork.return_,
							error_
						)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					-- ROBLOX TODO? pass in captureCommitPhaseError?
					local ok, error_ = xpcall(
						commitLayoutEffectsForProfiler,
						describeError,
						finishedWork,
						finishedRoot
					)
					if not ok then
						captureCommitPhaseError(
							finishedWork,
							finishedWork.return_,
							error_
						)
					end
				end
			end
		end

		if enableProfilerTimer and enableProfilerCommitHooks then
			-- Propagate layout effect durations to the next nearest Profiler ancestor.
			-- Do not reset these values until the next render so DevTools has a chance to read them first.
			if prevProfilerOnStack ~= nil then
				prevProfilerOnStack.stateNode.effectDuration += finishedWork.stateNode.effectDuration
			end

			nearestProfilerOnStack = prevProfilerOnStack
		end
	-- elseif tag == Offscreen then
	-- TODO: Fast path to invoke all nested layout effects when Offscren goes from hidden to visible.
	else
		local child = finishedWork.child
		while child ~= nil do
			local primarySubtreeFlags = bit32.band(finishedWork.subtreeFlags, LayoutMask)
			if primarySubtreeFlags ~= NoFlags then
				if __DEV__ then
					local prevCurrentFiberInDEV = ReactCurrentFiber.current
					setCurrentDebugFiberInDEV(child)
					--[[
              ROBLOX DEVIATION: In DEV, After MAX_RUN_DEPTH pcalls, do not wrap recursive calls in pcall. Otherwise,
              we hit the stack limit and get a stack overflow error.
            ]]
					if runDepth < MAX_RUN_DEPTH then
						runDepth += 1
						invokeGuardedCallback(
							nil,
							recursivelyCommitLayoutEffects,
							nil,
							child,
							finishedRoot,
							-- ROBLOX deviation: pass in this function to avoid dependency cycle
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
						runDepth -= 1

						if hasCaughtError() then
							local error_ = clearCaughtError()
							captureCommitPhaseError(child, finishedWork, error_)
						end
					else
						recursivelyCommitLayoutEffects(
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
					end
					if prevCurrentFiberInDEV ~= nil then
						setCurrentDebugFiberInDEV(prevCurrentFiberInDEV)
					else
						resetCurrentDebugFiberInDEV()
					end
				else
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, error_
					if not __YOLO__ and runDepth < MAX_RUN_DEPTH then
						--[[
              ROBLOX DEVIATION: After MAX_RUN_DEPTH pcalls, do not wrap recursive calls in pcall. Otherwise, we hit the
              stack limit and get a stack overflow error.
            ]]
						runDepth += 1

						ok, error_ = xpcall(
							-- ROBLOX deviation: pass in this function to avoid dependency cycle
							recursivelyCommitLayoutEffects,
							describeError,
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)

						runDepth -= 1
					else
						ok = true
						recursivelyCommitLayoutEffects(
							child,
							finishedRoot,
							captureCommitPhaseError,
							schedulePassiveEffectCallback
						)
					end

					if not ok then
						captureCommitPhaseError(child, finishedWork, error_)
					end
				end
			end
			child = child.sibling
		end

		local primaryFlags = bit32.band(flags, bit32.bor(Update, Callback))
		if primaryFlags ~= NoFlags then
			if
				tag == FunctionComponent
				or tag == ForwardRef
				or tag == SimpleMemoComponent
				or tag == Block
			then
				if
					enableProfilerTimer
					and enableProfilerCommitHooks
					and bit32.band(finishedWork.mode, ProfileMode) ~= 0
				then
					-- ROBLOX try
					local ok, error_ = xpcall(function()
						startLayoutEffectTimer()
						commitHookEffectListMount(
							bit32.bor(HookLayout, HookHasEffect),
							finishedWork
						)
					end, describeError)
					-- ROBLOX finally
					recordLayoutEffectDuration(finishedWork)
					if not ok then
						error(error_)
					end
				else
					commitHookEffectListMount(
						bit32.bor(HookLayout, HookHasEffect),
						finishedWork
					)
				end

				if bit32.band(finishedWork.subtreeFlags, PassiveMask) ~= NoFlags then
					schedulePassiveEffectCallback()
				end
			elseif tag == ClassComponent then
				-- NOTE: Layout effect durations are measured within this function.
				commitLayoutEffectsForClassComponent(finishedWork)
			elseif tag == HostRoot then
				commitLayoutEffectsForHostRoot(finishedWork)
			elseif tag == HostComponent then
				commitLayoutEffectsForHostComponent(finishedWork)
			elseif tag == SuspenseComponent then
				commitSuspenseHydrationCallbacks(finishedRoot, finishedWork)
			elseif
				tag == FundamentalComponent
				or tag == HostPortal
				or tag == HostText
				or tag == IncompleteClassComponent
				or tag == LegacyHiddenComponent
				or tag == OffscreenComponent
				or tag == ScopeComponent
				or tag == SuspenseListComponent
			then
			-- break
			else
				invariant(
					false,
					"This unit of work tag should not have side-effects. This error is "
						.. "likely caused by a bug in React. Please file an issue."
				)
			end
		end

		-- ROBLOX performance: avoid cmp on always-false value
		-- if enableScopeAPI then
		--   -- TODO: This is a temporary solution that allowed us to transition away from React Flare on www.
		--   if bit32.band(flags, Ref) ~= 0 and tag ~= ScopeComponent then
		--     commitAttachRef(finishedWork)
		--   end
		-- else
		if bit32.band(flags, Ref) ~= 0 then
			commitAttachRef(finishedWork)
		end
		-- end
	end
end

function commitLayoutEffectsForProfiler(finishedWork: Fiber, finishedRoot: FiberRoot)
	if enableProfilerTimer then
		local flags = finishedWork.flags
		local current = finishedWork.alternate

		local onCommit, onRender =
			finishedWork.memoizedProps.onCommit, finishedWork.memoizedProps.onRender
		local effectDuration = finishedWork.stateNode.effectDuration

		local commitTime = getCommitTime()

		local OnRenderFlag = Update
		local OnCommitFlag = Callback

		if
			bit32.band(flags, OnRenderFlag) ~= NoFlags
			-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
			and isCallable(onRender)
		then
			if enableSchedulerTracing then
				onRender(
					finishedWork.memoizedProps.id,
					if current == nil then "mount" else "update",
					finishedWork.actualDuration,
					finishedWork.treeBaseDuration,
					finishedWork.actualStartTime,
					commitTime,
					finishedRoot.memoizedInteractions
				)
			else
				onRender(
					finishedWork.memoizedProps.id,
					if current == nil then "mount" else "update",
					finishedWork.actualDuration,
					finishedWork.treeBaseDuration,
					finishedWork.actualStartTime,
					commitTime
				)
			end
		end

		if enableProfilerCommitHooks then
			if
				bit32.band(flags, OnCommitFlag) ~= NoFlags
				-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
				and isCallable(onCommit)
			then
				if enableSchedulerTracing then
					onCommit(
						finishedWork.memoizedProps.id,
						if current == nil then "mount" else "update",
						effectDuration,
						commitTime,
						finishedRoot.memoizedInteractions
					)
				else
					onCommit(
						finishedWork.memoizedProps.id,
						if current == nil then "mount" else "update",
						effectDuration,
						commitTime
					)
				end
			end
		end
	end
end

function commitLayoutEffectsForClassComponent(finishedWork: Fiber)
	local instance = finishedWork.stateNode
	local current = finishedWork.alternate
	if bit32.band(finishedWork.flags, Update) ~= 0 then
		if current == nil then
			-- We could update instance props and state here,
			-- but instead we rely on them being set during last render.
			-- TODO: revisit this when we implement resuming.
			if __DEV__ then
				if
					finishedWork.type == finishedWork.elementType
					and not didWarnAboutReassigningProps
				then
					if instance.props ~= finishedWork.memoizedProps then
						console.error(
							"Expected %s props to match memoized props before "
								.. "componentDidMount. "
								.. "This might either be because of a bug in React, or because "
								.. "a component reassigns its own `this.props`. "
								.. "Please file an issue.",
							getComponentName(finishedWork.type) or "instance"
						)
					end
					if instance.state ~= finishedWork.memoizedState then
						console.error(
							"Expected %s state to match memoized state before "
								.. "componentDidMount. "
								.. "This might either be because of a bug in React, or because "
								.. "a component reassigns its own `this.state`. "
								.. "Please file an issue.",
							getComponentName(finishedWork.type) or "instance"
						)
					end
				end
			end
			if
				enableProfilerTimer
				and enableProfilerCommitHooks
				and bit32.band(finishedWork.mode, ProfileMode) ~= 0
			then
				local ok, result = xpcall(function()
					startLayoutEffectTimer()
					-- ROBLOX deviation: Call with ":" so that the method receives self
					instance:componentDidMount()
				end, describeError)
				-- finally
				recordLayoutEffectDuration(finishedWork)
				if not ok then
					error(result)
				end
			else
				-- ROBLOX deviation: Call with ":" so that the method receives self
				instance:componentDidMount()
			end
		else
			local prevProps = finishedWork.elementType == finishedWork.type
					and current.memoizedProps
				or resolveDefaultProps(finishedWork.type, current.memoizedProps)
			local prevState = current.memoizedState
			-- We could update instance props and state here,
			-- but instead we rely on them being set during last render.
			-- TODO: revisit this when we implement resuming.
			if __DEV__ then
				if
					finishedWork.type == finishedWork.elementType
					and not didWarnAboutReassigningProps
				then
					if instance.props ~= finishedWork.memoizedProps then
						console.error(
							"Expected %s props to match memoized props before "
								.. "componentDidUpdate. "
								.. "This might either be because of a bug in React, or because "
								.. "a component reassigns its own `this.props`. "
								.. "Please file an issue.",
							getComponentName(finishedWork.type) or "instance"
						)
					end
					if instance.state ~= finishedWork.memoizedState then
						console.error(
							"Expected %s state to match memoized state before "
								.. "componentDidUpdate. "
								.. "This might either be because of a bug in React, or because "
								.. "a component reassigns its own `this.state`. "
								.. "Please file an issue.",
							getComponentName(finishedWork.type) or "instance"
						)
					end
				end
			end
			if
				enableProfilerTimer
				and enableProfilerCommitHooks
				and bit32.band(finishedWork.mode, ProfileMode) ~= 0
			then
				local ok, result = xpcall(function()
					startLayoutEffectTimer()
					-- deviation: Call with ":" so that the method receives self
					instance:componentDidUpdate(
						prevProps,
						prevState,
						instance.__reactInternalSnapshotBeforeUpdate
					)
				end, describeError)
				-- finally
				recordLayoutEffectDuration(finishedWork)
				if not ok then
					error(result)
				end
			else
				-- deviation: Call with ":" so that the method receives self
				instance:componentDidUpdate(
					prevProps,
					prevState,
					instance.__reactInternalSnapshotBeforeUpdate
				)
			end
		end
	end

	-- TODO: I think this is now always non-null by the time it reaches the
	-- commit phase. Consider removing the type check.
	local updateQueue: UpdateQueue<any> | nil = finishedWork.updateQueue
	if updateQueue ~= nil then
		if __DEV__ then
			if
				finishedWork.type == finishedWork.elementType
				and not didWarnAboutReassigningProps
			then
				if instance.props ~= finishedWork.memoizedProps then
					console.error(
						"Expected %s props to match memoized props before "
							.. "processing the update queue. "
							.. "This might either be because of a bug in React, or because "
							.. "a component reassigns its own `this.props`. "
							.. "Please file an issue.",
						getComponentName(finishedWork.type) or "instance"
					)
				end
				if instance.state ~= finishedWork.memoizedState then
					console.error(
						"Expected %s state to match memoized state before "
							.. "processing the update queue. "
							.. "This might either be because of a bug in React, or because "
							.. "a component reassigns its own `this.state`. "
							.. "Please file an issue.",
						getComponentName(finishedWork.type) or "instance"
					)
				end
			end
		end
		-- We could update instance props and state here,
		-- but instead we rely on them being set during last render.
		-- TODO: revisit this when we implement resuming.
		commitUpdateQueue(finishedWork, updateQueue, instance)
	end
end

function commitLayoutEffectsForHostRoot(finishedWork: Fiber)
	-- TODO: I think this is now always non-null by the time it reaches the
	-- commit phase. Consider removing the type check.
	local updateQueue: UpdateQueue<any> | nil = finishedWork.updateQueue
	if updateQueue ~= nil then
		local instance = nil
		if finishedWork.child ~= nil then
			-- ROBLOX TODO: localize child, workaround Luau type refinement shortcomings
			local child = finishedWork.child
			if child.tag == HostComponent then
				instance = getPublicInstance(child.stateNode)
			elseif child.tag == ClassComponent then
				instance = child.stateNode
			end
		end
		commitUpdateQueue(finishedWork, updateQueue, instance)
	end
end

function commitLayoutEffectsForHostComponent(finishedWork: Fiber)
	local instance: Instance = finishedWork.stateNode
	local current = finishedWork.alternate

	-- Renderers may schedule work to be done after host components are mounted
	-- (eg DOM renderer may schedule auto-focus for inputs and form controls).
	-- These effects should only be committed when components are first mounted,
	-- aka when there is no current/alternate.
	if current == nil and bit32.band(finishedWork.flags, Update) ~= 0 then
		local type = finishedWork.type
		local props = finishedWork.memoizedProps
		commitMount(instance, type, props, finishedWork)
	end
end

local function hideOrUnhideAllChildren(finishedWork, isHidden)
	if supportsMutation then
		-- We only have the top Fiber that was inserted but we need to recurse down its
		-- children to find all the terminal nodes.
		local node: Fiber = finishedWork
		while true do
			if node.tag == HostComponent then
				local instance = node.stateNode
				if isHidden then
					hideInstance(instance)
				else
					unhideInstance(node.stateNode, node.memoizedProps)
				end
			elseif node.tag == HostText then
				local instance = node.stateNode
				if isHidden then
					hideTextInstance(instance)
				else
					unhideTextInstance(instance, node.memoizedProps)
				end
			elseif
				(node.tag == OffscreenComponent or node.tag == LegacyHiddenComponent)
				and (node.memoizedState :: OffscreenState) ~= nil
				and node ~= finishedWork
			then
			-- Found a nested Offscreen component that is hidden. Don't search
			-- any deeper. This tree should remain hidden.
			elseif node.child ~= nil then
				-- ROBLOX FIXME: type casts to silence analyze, Luau doesn't understand nil check
				(node.child :: Fiber).return_ = node
				node = node.child :: Fiber
				continue
			end
			if node == finishedWork then
				return
			end
			while node.sibling == nil do
				if node.return_ == nil or node.return_ == finishedWork then
					return
				end
				node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
			end
			-- ROBLOX FIXME: cast to any to silence analyze
			(node.sibling :: Fiber).return_ = node.return_
			-- ROBLOX FIXME: recast to silence analyze while Luau doesn't understand nil check
			node = node.sibling :: Fiber
		end
	end
end

function commitAttachRef(finishedWork: Fiber)
	local ref = finishedWork.ref
	if ref ~= nil then
		local instance = finishedWork.stateNode
		local instanceToUse
		if finishedWork.tag == HostComponent then
			instanceToUse = getPublicInstance(instance)
		else
			instanceToUse = instance
		end
		-- Moved outside to ensure DCE works with this flag
		-- ROBLOX performance: avoid cmp on always-false value
		-- if enableScopeAPI and finishedWork.tag == ScopeComponent then
		--   instanceToUse = instance
		-- end
		if typeof(ref) == "function" then
			ref(instanceToUse)
		else
			if __DEV__ then
				-- ROBLOX FIXME: We won't be able to recognize a ref object by checking
				-- for the existence of the `current` key, since it won't be initialized
				-- at this point. We might consider using a symbol to uniquely identify
				-- ref objects, or relying more heavily on Luau types
				-- if not ref.current then
				if typeof(ref) ~= "table" then
					console.error(
						"Unexpected ref object provided for %s. "
							.. "Use either a ref-setter function or React.createRef().",
						getComponentName(finishedWork.type) or "instance"
					)
					return
				end
			end

			ref.current = instanceToUse
		end
	end
end

function commitDetachRef(current: Fiber)
	local currentRef = current.ref
	if currentRef ~= nil then
		if typeof(currentRef) == "function" then
			currentRef(nil)
		else
			currentRef.current = nil
		end
	end
end

-- User-originating errors (lifecycles and refs) should not interrupt
-- deletion, so don't local them throw. Host-originating errors should
-- interrupt deletion, so it's okay
function commitUnmount(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	onCommitUnmount(current)

	if
		current.tag == FunctionComponent
		or current.tag == ForwardRef
		or current.tag == MemoComponent
		or current.tag == SimpleMemoComponent
		or current.tag == Block
	then
		local updateQueue: FunctionComponentUpdateQueue | nil = current.updateQueue
		if updateQueue ~= nil then
			local lastEffect = (updateQueue :: FunctionComponentUpdateQueue).lastEffect
			if lastEffect ~= nil then
				local firstEffect = lastEffect.next

				local effect = firstEffect
				repeat
					if effect.destroy ~= nil then
						if bit32.band(effect.tag, HookLayout) ~= NoHookEffect then
							if
								enableProfilerTimer
								and enableProfilerCommitHooks
								and bit32.band(current.mode, ProfileMode) ~= 0
							then
								startLayoutEffectTimer()
								safelyCallDestroy(
									current,
									nearestMountedAncestor,
									effect.destroy
								)
								recordLayoutEffectDuration(current)
							else
								safelyCallDestroy(
									current,
									nearestMountedAncestor,
									effect.destroy
								)
							end
						end
					end
					effect = effect.next
				until effect == firstEffect
			end
		end
		return
	elseif current.tag == ClassComponent then
		safelyDetachRef(current, nearestMountedAncestor)
		local instance = current.stateNode
		if typeof(instance.componentWillUnmount) == "function" then
			safelyCallComponentWillUnmount(current, instance, nearestMountedAncestor)
		end
		return
	elseif current.tag == HostComponent then
		safelyDetachRef(current, nearestMountedAncestor)
		return
	elseif current.tag == HostPortal then
		-- TODO: this is recursive.
		-- We are also not using this parent because
		-- the portal will get pushed immediately.
		if supportsMutation then
			unmountHostComponents(
				finishedRoot,
				current,
				nearestMountedAncestor,
				renderPriorityLevel
			)
		elseif supportsPersistence then
			unimplemented("emptyPortalContainer")
			-- emptyPortalContainer(current)
		end
		return
		-- elseif current.tag == FundamentalComponent then
		--   unimplemented("commitUnmount - FundamentalComponent")
		-- if enableFundamentalAPI then
		--   local fundamentalInstance = current.stateNode
		--   if fundamentalInstance ~= nil then
		--     unmountFundamentalComponent(fundamentalInstance)
		--     current.stateNode = nil
		--   end
		-- end
		-- return
		-- elseif current.tag == DehydratedFragment then
		--   unimplemented("commitUnmount - DehydratedFragment")
		-- if enableSuspenseCallback then
		--   local hydrationCallbacks = finishedRoot.hydrationCallbacks
		--   if hydrationCallbacks ~= nil then
		--     local onDeleted = hydrationCallbacks.onDeleted
		--     if onDeleted then
		--       onDeleted((current.stateNode: SuspenseInstance))
		--     end
		--   end
		-- end
		-- return
		-- elseif current.tag == ScopeComponent then
		--   if enableScopeAPI then
		--     safelyDetachRef(current, nearestMountedAncestor)
		--   end
		--   return
	end
end

function commitNestedUnmounts(
	finishedRoot: FiberRoot,
	root: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
)
	-- While we're inside a removed host node we don't want to call
	-- removeChild on the inner nodes because they're removed by the top
	-- call anyway. We also want to call componentWillUnmount on all
	-- composites before this host node is removed from the tree. Therefore
	-- we do an inner loop while we're still inside the host node.
	local node: Fiber = root
	while true do
		commitUnmount(finishedRoot, node, nearestMountedAncestor, renderPriorityLevel)
		-- Visit children because they may contain more composite or host nodes.
		-- Skip portals because commitUnmount() currently visits them recursively.
		if
			node.child ~= nil
			-- If we use mutation we drill down into portals using commitUnmount above.
			-- If we don't use mutation we drill down into portals here instead.
			and (not supportsMutation or node.tag ~= HostPortal)
		then
			(node.child :: Fiber).return_ = node
			node = node.child :: Fiber
			continue
		end
		if node == root then
			return
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == root then
				return
			end
			node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
		end
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
end

local function detachFiberMutation(fiber: Fiber)
	-- Cut off the return pointer to disconnect it from the tree.
	-- This enables us to detect and warn against state updates on an unmounted component.
	-- It also prevents events from bubbling from within disconnected components.
	--
	-- Ideally, we should also clear the child pointer of the parent alternate to local this
	-- get GC:ed but we don't know which for sure which parent is the current
	-- one so we'll settle for GC:ing the subtree of this child.
	-- This child itself will be GC:ed when the parent updates the next time.
	--
	-- Note that we can't clear child or sibling pointers yet.
	-- They're needed for passive effects and for findDOMNode.
	-- We defer those fields, and all other cleanup, to the passive phase (see detachFiberAfterEffects).
	local alternate = fiber.alternate
	if alternate ~= nil then
		alternate.return_ = nil
		fiber.alternate = nil
	end
	fiber.return_ = nil
end

-- function emptyPortalContainer(current: Fiber)
--   if !supportsPersistence)
--     return
--   end

--   local portal: {
--     containerInfo: Container,
--     pendingChildren: ChildSet,
--     ...
--   } = current.stateNode
--   local {containerInfo} = portal
--   local emptyChildSet = createContainerChildSet(containerInfo)
--   replaceContainerChildren(containerInfo, emptyChildSet)
-- end

-- function commitContainer(finishedWork: Fiber)
--   if !supportsPersistence)
--     return
--   end

--   switch (finishedWork.tag)
--     case ClassComponent:
--     case HostComponent:
--     case HostText:
--     case FundamentalComponent: {
--       return
--     end
--     case HostRoot:
--     case HostPortal: {
--       local portalOrRoot: {
--         containerInfo: Container,
--         pendingChildren: ChildSet,
--         ...
--       } = finishedWork.stateNode
--       local {containerInfo, pendingChildren} = portalOrRoot
--       replaceContainerChildren(containerInfo, pendingChildren)
--       return
--     end
--   end
--   invariant(
--     false,
--     'This unit of work tag should not have side-effects. This error is ' +
--       'likely caused by a bug in React. Please file an issue.',
--   )
-- end

local function getHostParentFiber(fiber: Fiber): Fiber
	local parent = fiber.return_
	while parent ~= nil do
		if isHostParent(parent) then
			return parent
		end
		parent = parent.return_
	end
	-- ROBLOX deviation START: use React 18 approach, which Luau understands better than invariant
	error(
		Error.new(
			"Expected to find a host parent. This error is likely caused by a bug "
				.. "in React. Please file an issue."
		)
	)
	-- ROBLOX deviation END
end

function isHostParent(fiber: Fiber): boolean
	return fiber.tag == HostComponent or fiber.tag == HostRoot or fiber.tag == HostPortal
end

function getHostSibling(fiber: Fiber): Instance?
	-- We're going to search forward into the tree until we find a sibling host
	-- node. Unfortunately, if multiple insertions are done in a row we have to
	-- search past them. This leads to exponential search for the next sibling.
	-- TODO: Find a more efficient way to do this.
	local node: Fiber = fiber
	while true do
		-- ROBLOX deviation: we can't `continue` with labels in luau, so some variable
		-- juggling is used instead
		local continueOuter = false
		-- If we didn't find anything, let's try the next sibling.
		while node.sibling == nil do
			if node.return_ == nil or isHostParent(node.return_) then
				-- If we pop out of the root or hit the parent the fiber we are the
				-- last sibling.
				return nil
			end
			node = node.return_ :: Fiber -- ROBLOX TODO: Luau narrowing doesn't understand this loop until nil pattern
		end
		(node.sibling :: Fiber).return_ = node.return_ :: Fiber
		node = node.sibling :: Fiber
		while
			node.tag ~= HostComponent
			and node.tag ~= HostText
			and node.tag ~= DehydratedFragment
		do
			-- If it is not host node and, we might have a host node inside it.
			-- Try to search down until we find one.
			if bit32.band(node.flags, Placement) ~= 0 then
				-- If we don't have a child, try the siblings instead.
				continueOuter = true
				break
			end
			-- If we don't have a child, try the siblings instead.
			-- We also skip portals because they are not part of this host tree.
			if node.child == nil or node.tag == HostPortal then
				continueOuter = true
				break
			else
				(node.child :: Fiber).return_ = node
				node = node.child :: Fiber
			end
		end
		if continueOuter then
			continue
		end
		-- Check if this host node is stable or about to be placed.
		if bit32.band(node.flags, Placement) == 0 then
			-- Found it!
			return node.stateNode
		end
	end
end

local function commitPlacement(finishedWork: Fiber)
	if not supportsMutation then
		return
	end

	-- Recursively insert all host nodes into the parent.
	local parentFiber = getHostParentFiber(finishedWork)

	-- Note: these two variables *must* always be updated together.
	local parent
	local isContainer
	local parentStateNode = parentFiber.stateNode
	if parentFiber.tag == HostComponent then
		parent = parentStateNode
		isContainer = false
	elseif parentFiber.tag == HostRoot then
		parent = parentStateNode.containerInfo
		isContainer = true
	elseif parentFiber.tag == HostPortal then
		parent = parentStateNode.containerInfo
		isContainer = true
	-- elseif parentFiber.tag == FundamentalComponent then
	--   if enableFundamentalAPI then
	--     parent = parentStateNode.instance
	--     isContainer = false
	--   end
	else
		-- eslint-disable-next-line-no-fallthrough
		invariant(
			false,
			"Invalid host parent fiber. This error is likely caused by a bug "
				.. "in React. Please file an issue."
		)
	end
	if bit32.band(parentFiber.flags, ContentReset) ~= 0 then
		-- Reset the text content of the parent before doing any insertions
		resetTextContent(parent)
		-- Clear ContentReset from the effect tag
		parentFiber.flags = bit32.band(parentFiber.flags, bit32.bnot(ContentReset))
	end

	local before = getHostSibling(finishedWork)
	-- We only have the top Fiber that was inserted but we need to recurse down its
	-- children to find all the terminal nodes.
	if isContainer then
		insertOrAppendPlacementNodeIntoContainer(finishedWork, before, parent)
	else
		insertOrAppendPlacementNode(finishedWork, before, parent)
	end
end

function insertOrAppendPlacementNodeIntoContainer(
	node: Fiber,
	before: Instance?,
	parent: Container
)
	local tag = node.tag
	local isHost = tag == HostComponent or tag == HostText
	-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
	if isHost then -- or (enableFundamentalAPI and tag == FundamentalComponent) then
		local stateNode = node.stateNode
		if before then
			insertInContainerBefore(parent, stateNode, before)
		else
			appendChildToContainer(parent, stateNode)
		end
	elseif tag == HostPortal then
	-- If the insertion itself is a portal, then we don't want to traverse
	-- down its children. Instead, we'll get insertions from each child in
	-- the portal directly.
	else
		local child = node.child
		if child ~= nil then
			insertOrAppendPlacementNodeIntoContainer(child, before, parent)
			local sibling = child.sibling
			while sibling ~= nil do
				insertOrAppendPlacementNodeIntoContainer(sibling, before, parent)
				sibling = sibling.sibling
			end
		end
	end
end

function insertOrAppendPlacementNode(node: Fiber, before: Instance?, parent: Instance): ()
	local tag = node.tag
	local isHost = tag == HostComponent or tag == HostText
	-- ROBLOX performance: avoid always-false compare for Roblox renderer in hot path
	if isHost then -- or (enableFundamentalAPI and tag == FundamentalComponent) then
		local stateNode = node.stateNode
		if before then
			insertBefore(parent, stateNode, before)
		else
			appendChild(parent, stateNode)
		end
	elseif tag == HostPortal then
	-- If the insertion itself is a portal, then we don't want to traverse
	-- down its children. Instead, we'll get insertions from each child in
	-- the portal directly.
	else
		local child = node.child
		if child ~= nil then
			insertOrAppendPlacementNode(child, before, parent)
			local sibling = child.sibling
			while sibling ~= nil do
				insertOrAppendPlacementNode(sibling, before, parent)
				sibling = sibling.sibling
			end
		end
	end
end

function unmountHostComponents(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	-- We only have the top Fiber that was deleted but we need to recurse down its
	-- children to find all the terminal nodes.
	local node: Fiber = current

	-- Each iteration, currentParent is populated with node's host parent if not
	-- currentParentIsValid.
	local currentParentIsValid = false

	-- Note: these two variables *must* always be updated together.
	local currentParent
	local currentParentIsContainer

	while true do
		if not currentParentIsValid then
			-- ROBLOX FIXME Luau: Luau doesn't understand the nil guard at the top of the loop
			local parent = node.return_ :: Fiber
			while true do
				-- ROBLOX deviation START: use React 18 approach so Luau understands control flow better
				if parent == nil then
					error(
						Error.new(
							"Expected to find a host parent. This error is likely caused by "
								.. "a bug in React. Please file an issue."
						)
					)
				end
				-- ROBLOX deviation END
				local parentStateNode = parent.stateNode
				if parent.tag == HostComponent then
					currentParent = parentStateNode
					currentParentIsContainer = false
					break
				elseif parent.tag == HostRoot then
					currentParent = parentStateNode.containerInfo
					currentParentIsContainer = true
					break
				elseif parent.tag == HostPortal then
					currentParent = parentStateNode.containerInfo
					currentParentIsContainer = true
					break
					-- ROBLOX performance: eliminate always-false compare for Roblox in hot path
					-- elseif parent.tag == FundamentalComponent then
					--   if enableFundamentalAPI then
					--     currentParent = parentStateNode.instance
					--     currentParentIsContainer = false
					--   end
				end
				-- ROBLOX FIXME Luau: Luau doesn't understand the nil guard at the top of the loop
				parent = parent.return_ :: Fiber
			end
			currentParentIsValid = true
		end

		if node.tag == HostComponent or node.tag == HostText then
			commitNestedUnmounts(
				finishedRoot,
				node,
				nearestMountedAncestor,
				renderPriorityLevel
			)
			-- After all the children have unmounted, it is now safe to remove the
			-- node from the tree.
			if currentParentIsContainer then
				-- removeChildFromContainer(
				--   ((currentParent: any): Container),
				--   (fundamentalNode: Instance),
				-- )
				-- ROBLOX FIXME: type coercion
				removeChildFromContainer(currentParent, node.stateNode)
			else
				-- removeChild(
				--   ((currentParent: any): Instance),
				--   (fundamentalNode: Instance),
				-- )
				-- ROBLOX FIXME: type coercion
				removeChild(currentParent, node.stateNode)
			end
		-- Don't visit children because we already visited them.
		-- ROBLOX performance? fundamentalAPI  and suspenseServerRender are always false for Roblox. avoid unnecessary cmp in hot path
		-- elseif enableFundamentalAPI and node.tag == FundamentalComponent then
		--   local fundamentalNode = node.stateNode.instance
		--   commitNestedUnmounts(
		--     finishedRoot,
		--     node,
		--     nearestMountedAncestor,
		--     renderPriorityLevel
		--   )
		--   -- After all the children have unmounted, it is now safe to remove the
		--   -- node from the tree.
		--   if currentParentIsContainer then
		--     -- removeChildFromContainer(
		--     --   ((currentParent: any): Container),
		--     --   (fundamentalNode: Instance),
		--     -- )
		--     -- ROBLOX FIXME: type coercion
		--     removeChildFromContainer(currentParent, fundamentalNode)
		--   else
		--     -- removeChild(
		--     --   ((currentParent: any): Instance),
		--     --   (fundamentalNode: Instance),
		--     -- )
		--     -- ROBLOX FIXME: type coercion
		--     removeChild(currentParent, fundamentalNode)
		--   end
		-- elseif
		--   enableSuspenseServerRenderer and
		--   node.tag == DehydratedFragment
		-- then
		--   unimplemented("clearSuspenseBoundary")
		--   -- if enableSuspenseCallback then
		--   --   local hydrationCallbacks = finishedRoot.hydrationCallbacks
		--   --   if hydrationCallbacks ~= nil)
		--   --     local onDeleted = hydrationCallbacks.onDeleted
		--   --     if onDeleted)
		--   --       onDeleted((node.stateNode: SuspenseInstance))
		--   --     end
		--   --   end
		--   -- end

		--   -- -- Delete the dehydrated suspense boundary and all of its content.
		--   -- if currentParentIsContainer)
		--   --   clearSuspenseBoundaryFromContainer(
		--   --     ((currentParent: any): Container),
		--   --     (node.stateNode: SuspenseInstance),
		--   --   )
		--   -- } else {
		--   --   clearSuspenseBoundary(
		--   --     ((currentParent: any): Instance),
		--   --     (node.stateNode: SuspenseInstance),
		--   --   )
		--   -- end
		elseif node.tag == HostPortal then
			if node.child ~= nil then
				-- When we go into a portal, it becomes the parent to remove from.
				-- We will reassign it back when we pop the portal on the way up.
				currentParent = node.stateNode.containerInfo
				currentParentIsContainer = true
				-- Visit children because portals might contain host components.
				node.child.return_ = node
				node = node.child
				continue
			end
		else
			commitUnmount(finishedRoot, node, nearestMountedAncestor, renderPriorityLevel)
			-- Visit children because we may find more host components below.
			if node.child ~= nil then
				node.child.return_ = node
				node = node.child
				continue
			end
		end
		if node == current then
			return
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == current then
				return
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand narrowing by guard above
			node = node.return_ :: Fiber
			if node.tag == HostPortal then
				-- When we go out of the portal, we need to restore the parent.
				-- Since we don't keep a stack of them, we will search for it.
				currentParentIsValid = false
			end
		end
		-- ROBLOX TODO: flowtype makes an impossible leap here, contribute this annotation upstream
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
end

local function commitDeletion(
	finishedRoot: FiberRoot,
	current: Fiber,
	nearestMountedAncestor: Fiber,
	renderPriorityLevel: ReactPriorityLevel
): ()
	-- ROBLOX performance? supportsMutation always true, eliminate cmp on hot path
	-- if supportsMutation then
	-- Recursively delete all host nodes from the parent.
	-- Detach refs and call componentWillUnmount() on the whole subtree.
	unmountHostComponents(
		finishedRoot,
		current,
		nearestMountedAncestor,
		renderPriorityLevel
	)
	-- else
	--   -- Detach refs and call componentWillUnmount() on the whole subtree.
	--   commitNestedUnmounts(
	--     finishedRoot,
	--     current,
	--     nearestMountedAncestor,
	--     renderPriorityLevel
	--   )
	-- end
	local alternate = current.alternate
	detachFiberMutation(current)
	if alternate ~= nil then
		detachFiberMutation(alternate)
	end
end

local function commitWork(current: Fiber | nil, finishedWork: Fiber)
	-- if not supportsMutation then
	--   unimplemented("commitWork: non-mutation branch")
	-- switch (finishedWork.tag)
	--   case FunctionComponent:
	--   case ForwardRef:
	--   case MemoComponent:
	--   case SimpleMemoComponent:
	--   case Block: {
	--     -- Layout effects are destroyed during the mutation phase so that all
	--     -- destroy functions for all fibers are called before any create functions.
	--     -- This prevents sibling component effects from interfering with each other,
	--     -- e.g. a destroy function in one component should never override a ref set
	--     -- by a create function in another component during the same commit.
	--     if
	--       enableProfilerTimer and
	--       enableProfilerCommitHooks and
	--       finishedWork.mode & ProfileMode
	--     )
	--       try {
	--         startLayoutEffectTimer()
	--         commitHookEffectListUnmount(
	--           HookLayout | HookHasEffect,
	--           finishedWork,
	--           finishedWork.return_,
	--         )
	--       } finally {
	--         recordLayoutEffectDuration(finishedWork)
	--       end
	--     } else {
	--       commitHookEffectListUnmount(
	--         HookLayout | HookHasEffect,
	--         finishedWork,
	--         finishedWork.return_,
	--       )
	--     end
	--     return
	--   end
	--   case Profiler: {
	--     return
	--   end
	--   case SuspenseComponent: {
	--     commitSuspenseComponent(finishedWork)
	--     attachSuspenseRetryListeners(finishedWork)
	--     return
	--   end
	--   case SuspenseListComponent: {
	--     attachSuspenseRetryListeners(finishedWork)
	--     return
	--   end
	--   case HostRoot: {
	--     if supportsHydration)
	--       local root: FiberRoot = finishedWork.stateNode
	--       if root.hydrate)
	--         -- We've just hydrated. No need to hydrate again.
	--         root.hydrate = false
	--         commitHydratedContainer(root.containerInfo)
	--       end
	--     end
	--     break
	--   end
	--   case OffscreenComponent:
	--   case LegacyHiddenComponent: {
	--     return
	--   end
	-- end

	-- commitContainer(finishedWork)
	-- return
	-- end

	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == MemoComponent
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		-- Layout effects are destroyed during the mutation phase so that all
		-- destroy functions for all fibers are called before any create functions.
		-- This prevents sibling component effects from interfering with each other,
		-- e.g. a destroy function in one component should never override a ref set
		-- by a create function in another component during the same commit.
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			-- ROBLOX try
			local ok, result = xpcall(function()
				startLayoutEffectTimer()
				commitHookEffectListUnmount(
					bit32.bor(HookLayout, HookHasEffect),
					finishedWork,
					finishedWork.return_
				)
			end, describeError)
			-- ROBLOX finally
			recordLayoutEffectDuration(finishedWork)
			if not ok then
				error(result)
			end
		else
			commitHookEffectListUnmount(
				bit32.bor(HookLayout, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
		end
		return
	elseif finishedWork.tag == ClassComponent then
		return
	elseif finishedWork.tag == HostComponent then
		local instance: Instance = finishedWork.stateNode
		if instance ~= nil then
			-- Commit the work prepared earlier.
			local newProps = finishedWork.memoizedProps
			-- For hydration we reuse the update path but we treat the oldProps
			-- as the newProps. The updatePayload will contain the real change in
			-- this case.
			local oldProps
			if current then
				oldProps = current.memoizedProps
			else
				oldProps = newProps
			end
			local type = finishedWork.type
			-- TODO: Type the updateQueue to be specific to host components.
			local updatePayload: nil | UpdatePayload = finishedWork.updateQueue :: any
			finishedWork.updateQueue = nil
			if updatePayload ~= nil then
				commitUpdate(
					instance,
					updatePayload,
					type,
					oldProps,
					newProps,
					finishedWork
				)
			end
		end
		return
	elseif finishedWork.tag == HostText then
		invariant(
			finishedWork.stateNode ~= nil,
			"This should have a text node initialized. This error is likely "
				.. "caused by a bug in React. Please file an issue."
		)
		local textInstance: TextInstance = finishedWork.stateNode
		local newText: string = finishedWork.memoizedProps
		-- For hydration we reuse the update path but we treat the oldProps
		-- as the newProps. The updatePayload will contain the real change in
		-- this case.
		local oldText: string
		if current ~= nil then
			oldText = (current :: Fiber).memoizedProps
			oldText = newText
		end
		commitTextUpdate(textInstance, oldText, newText)
		return
	elseif finishedWork.tag == HostRoot then
		if supportsHydration then
			local root: FiberRoot = finishedWork.stateNode
			if root.hydrate then
				-- We've just hydrated. No need to hydrate again.
				root.hydrate = false
				unimplemented("commitWork: HostRoot: commitHydratedContainer")
				-- commitHydratedContainer(root.containerInfo)
			end
		end
		return
	elseif finishedWork.tag == Profiler then
		return
	elseif finishedWork.tag == SuspenseComponent then
		commitSuspenseComponent(finishedWork)
		attachSuspenseRetryListeners(finishedWork)
		return
	elseif finishedWork.tag == SuspenseListComponent then
		unimplemented("commitWork: SuspenseListComponent")
	-- attachSuspenseRetryListeners(finishedWork)
	-- return
	elseif finishedWork.tag == IncompleteClassComponent then
		return
	-- elseif finishedWork.tag == FundamentalComponent then
	--   unimplemented("commitWork: FundamentalComponent")
	-- if enableFundamentalAPI)
	--   local fundamentalInstance = finishedWork.stateNode
	--   updateFundamentalComponent(fundamentalInstance)
	--   return
	-- end
	-- break
	-- elseif finishedWork.tag == ScopeComponent then
	--   unimplemented("commitWork: ScopeComponent")
	-- if enableScopeAPI)
	--   local scopeInstance = finishedWork.stateNode
	--   prepareScopeUpdate(scopeInstance, finishedWork)
	--   return
	-- end
	-- break
	elseif
		finishedWork.tag == OffscreenComponent
		or finishedWork.tag == LegacyHiddenComponent
	then
		local newState: OffscreenState | nil = finishedWork.memoizedState
		local isHidden = newState ~= nil
		hideOrUnhideAllChildren(finishedWork, isHidden)
		return
	end
	invariant(
		false,
		"This unit of work tag should not have side-effects. This error is "
			.. "likely caused by a bug in React. Please file an issue."
	)
end

function commitSuspenseComponent(finishedWork: Fiber)
	local newState: SuspenseState | nil = finishedWork.memoizedState

	if newState ~= nil then
		markCommitTimeOfFallback()

		if supportsMutation then
			-- Hide the Offscreen component that contains the primary children. TODO:
			-- Ideally, this effect would have been scheduled on the Offscreen fiber
			-- itself. That's how unhiding works: the Offscreen component schedules an
			-- effect on itself. However, in this case, the component didn't complete,
			-- so the fiber was never added to the effect list in the normal path. We
			-- could have appended it to the effect list in the Suspense component's
			-- second pass, but doing it this way is less complicated. This would be
			-- simpler if we got rid of the effect list and traversed the tree, like
			-- we're planning to do.
			local primaryChildParent: Fiber = finishedWork.child :: any
			hideOrUnhideAllChildren(primaryChildParent, true)
		end
	end

	if enableSuspenseCallback and newState ~= nil then
		local suspenseCallback = finishedWork.memoizedProps.suspenseCallback
		if typeof(suspenseCallback) == "function" then
			local wakeables: Set<Wakeable> | nil = finishedWork.updateQueue :: any
			if wakeables ~= nil then
				suspenseCallback(table.clone(wakeables))
			end
		elseif __DEV__ then
			if suspenseCallback ~= nil then
				console.error(
					"Unexpected type for suspenseCallback: %s",
					tostring(suspenseCallback)
				)
			end
		end
	end
end

function commitSuspenseHydrationCallbacks(finishedRoot: FiberRoot, finishedWork: Fiber)
	if not supportsHydration then
		return
	end
	local newState: SuspenseState | nil = finishedWork.memoizedState
	if newState == nil then
		local current = finishedWork.alternate
		if current ~= nil then
			local prevState: SuspenseState | nil = current.memoizedState
			if prevState ~= nil then
				local suspenseInstance = prevState.dehydrated
				if suspenseInstance ~= nil then
					commitHydratedSuspenseInstance(suspenseInstance)
					if enableSuspenseCallback then
						local hydrationCallbacks = finishedRoot.hydrationCallbacks
						if hydrationCallbacks ~= nil then
							local onHydrated = hydrationCallbacks.onHydrated
							if onHydrated then
								onHydrated(suspenseInstance)
							end
						end
					end
				end
			end
		end
	end
end

function attachSuspenseRetryListeners(finishedWork: Fiber)
	-- If this boundary just timed out, then it will have a set of wakeables.
	-- For each wakeable, attach a listener so that when it resolves, React
	-- attempts to re-render the boundary in the primary (pre-timeout) state.
	local wakeables: Set<Wakeable> | nil = finishedWork.updateQueue :: any
	if wakeables ~= nil then
		finishedWork.updateQueue = nil
		local retryCache = finishedWork.stateNode
		if retryCache == nil then
			finishedWork.stateNode = Set.new()
			retryCache = finishedWork.stateNode
		end
		for wakeable, _ in wakeables :: Set<Wakeable> do
			-- Memoize using the boundary fiber to prevent redundant listeners.
			local retry = function()
				return resolveRetryWakeable(finishedWork, wakeable)
			end

			if not retryCache:has(wakeable) then
				if enableSchedulerTracing then
					if wakeable.__reactDoNotTraceInteractions ~= true then
						retry = Schedule_tracing_wrap(retry)
					end
				end
				retryCache:add(wakeable)
				wakeable:andThen(function()
					return retry()
				end, function()
					return retry()
				end)
			end
		end
	end
end

-- This function detects when a Suspense boundary goes from visible to hidden.
-- It returns false if the boundary is already hidden.
-- TODO: Use an effect tag.
function isSuspenseBoundaryBeingHidden(current: Fiber | nil, finishedWork: Fiber): boolean
	if current ~= nil then
		-- ROBLOX TODO: remove typechecks when narrowing works better
		local oldState: SuspenseState | nil = (current :: Fiber).memoizedState
		if oldState == nil or (oldState :: SuspenseState).dehydrated ~= nil then
			local newState: SuspenseState | nil = finishedWork.memoizedState
			return newState ~= nil and (newState :: SuspenseState).dehydrated == nil
		end
	end
	return false
end

function commitResetTextContent(current: Fiber): ()
	if not supportsMutation then
		return
	end
	resetTextContent(current.stateNode)
end

local function commitPassiveUnmount(finishedWork: Fiber): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			commitHookEffectListUnmount(
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
			recordPassiveEffectDuration(finishedWork)
		else
			commitHookEffectListUnmount(
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork,
				finishedWork.return_
			)
		end
	end
end

local function commitPassiveUnmountInsideDeletedTree(
	current: Fiber,
	nearestMountedAncestor: Fiber | nil
): ()
	if
		current.tag == FunctionComponent
		or current.tag == ForwardRef
		or current.tag == SimpleMemoComponent
		or current.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(current.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			commitHookEffectListUnmount(HookPassive, current, nearestMountedAncestor)
			recordPassiveEffectDuration(current)
		else
			commitHookEffectListUnmount(HookPassive, current, nearestMountedAncestor)
		end
	end
end

local function commitPassiveMount(finishedRoot: FiberRoot, finishedWork: Fiber): ()
	if
		finishedWork.tag == FunctionComponent
		or finishedWork.tag == ForwardRef
		or finishedWork.tag == SimpleMemoComponent
		or finishedWork.tag == Block
	then
		if
			enableProfilerTimer
			and enableProfilerCommitHooks
			and bit32.band(finishedWork.mode, ProfileMode) ~= 0
		then
			startPassiveEffectTimer()
			-- ROBLOX try
			local ok, error_ = xpcall(
				commitHookEffectListMount,
				describeError,
				bit32.bor(HookPassive, HookHasEffect),
				finishedWork
			)
			-- ROBLOX finally
			recordPassiveEffectDuration(finishedWork)
			if not ok then
				error(error_)
			end
		else
			commitHookEffectListMount(bit32.bor(HookPassive, HookHasEffect), finishedWork)
		end
	elseif finishedWork.tag == Profiler then
		commitProfilerPassiveEffect(finishedRoot, finishedWork)
	end
end

function invokeLayoutEffectMountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListMount,
				nil,
				bit32.bor(HookLayout, HookHasEffect),
				fiber
			)
			if hasCaughtError() then
				local mountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, mountError)
			end
			return
		end
	elseif fiber.tag == ClassComponent then
		local instance = fiber.stateNode
		invokeGuardedCallback(nil, instance.componentDidMount, instance)
		if hasCaughtError() then
			local mountError = clearCaughtError()
			captureCommitPhaseError(fiber, fiber.return_, mountError)
		end
		return
	end
end

function invokePassiveEffectMountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListMount,
				nil,
				bit32.bor(HookPassive, HookHasEffect),
				fiber
			)
			if hasCaughtError() then
				local mountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, mountError)
			end
			return
		end
	end
end

function invokeLayoutEffectUnmountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListUnmount,
				nil,
				bit32.bor(HookLayout, HookHasEffect),
				fiber,
				fiber.return_
			)
			if hasCaughtError() then
				local unmountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, unmountError)
			end
			return
		end
	elseif fiber.tag == ClassComponent then
		local instance = fiber.stateNode
		if typeof(instance.componentWillUnmount) == "function" then
			safelyCallComponentWillUnmount(fiber, instance, fiber.return_)
		end
		return
	end
end

function invokePassiveEffectUnmountInDEV(fiber: Fiber): ()
	if __DEV__ and enableDoubleInvokingEffects then
		if
			fiber.tag == FunctionComponent
			or fiber.tag == ForwardRef
			or fiber.tag == SimpleMemoComponent
			or fiber.tag == Block
		then
			invokeGuardedCallback(
				nil,
				commitHookEffectListUnmount,
				nil,
				bit32.bor(HookPassive, HookHasEffect),
				fiber,
				fiber.return_
			)
			if hasCaughtError() then
				local unmountError = clearCaughtError()
				captureCommitPhaseError(fiber, fiber.return_, unmountError)
			end
			return
		end
	end
end

return {
	safelyCallDestroy = safelyCallDestroy,

	commitBeforeMutationLifeCycles = commitBeforeMutationLifeCycles,
	commitResetTextContent = commitResetTextContent,
	commitPlacement = commitPlacement,
	commitDeletion = commitDeletion,
	commitWork = commitWork,
	commitAttachRef = commitAttachRef,
	commitDetachRef = commitDetachRef,
	commitPassiveUnmount = commitPassiveUnmount,
	commitPassiveUnmountInsideDeletedTree = commitPassiveUnmountInsideDeletedTree,
	commitPassiveMount = commitPassiveMount,
	invokeLayoutEffectMountInDEV = invokeLayoutEffectMountInDEV,
	invokeLayoutEffectUnmountInDEV = invokeLayoutEffectUnmountInDEV,
	invokePassiveEffectMountInDEV = invokePassiveEffectMountInDEV,
	invokePassiveEffectUnmountInDEV = invokePassiveEffectUnmountInDEV,
	isSuspenseBoundaryBeingHidden = isSuspenseBoundaryBeingHidden,
	recursivelyCommitLayoutEffects = recursivelyCommitLayoutEffects,
}
