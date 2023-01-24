-- ROBLOX upstream: https://github.com/facebook/react/blob/50d9451f320a9aaf94304209193562cc385567d8/packages/react-reconciler/src/ReactFiberReconciler.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local __DEV__ = _G.__DEV__ :: boolean
local Packages = script.Parent.Parent
local flowtypes = require(Packages.Shared)
type React_Component<Props, State> = flowtypes.React_Component<Props, State>
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
type Function = (...any) -> ...any

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

type Object = { [string]: any }
type Array<T> = { [number]: T }

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type SuspenseHydrationCallbacks = ReactInternalTypes.SuspenseHydrationCallbacks
type FiberRoot = ReactInternalTypes.FiberRoot

local ReactRootTags = require(script.Parent.ReactRootTags)
type RootTag = ReactRootTags.RootTag

local ReactFiberFlags = require(script.Parent.ReactFiberFlags)

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Instance = ReactFiberHostConfig.Instance
type TextInstance = ReactFiberHostConfig.TextInstance
type Container = ReactFiberHostConfig.Container
type PublicInstance = ReactFiberHostConfig.PublicInstance
type RendererInspectionConfig = ReactFiberHostConfig.RendererInspectionConfig

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList

local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lane = ReactFiberLane.Lane
type LanePriority = ReactFiberLane.LanePriority
local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactFiberTreeReflection = require(script.Parent.ReactFiberTreeReflection)
local findCurrentHostFiber = ReactFiberTreeReflection.findCurrentHostFiber
local findCurrentHostFiberWithNoPortals =
	ReactFiberTreeReflection.findCurrentHostFiberWithNoPortals
local getInstance = require(Packages.Shared).ReactInstanceMap.get
local HostComponent = ReactWorkTags.HostComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local getComponentName = require(Packages.Shared).getComponentName
local invariant = require(Packages.Shared).invariant
local describeError = require(Packages.Shared).describeError
local enableSchedulingProfiler =
	require(Packages.Shared).ReactFeatureFlags.enableSchedulingProfiler
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local getPublicInstance = require(script.Parent.ReactFiberHostConfig).getPublicInstance
local ReactFiberContext = require(script.Parent["ReactFiberContext.new"])
local findCurrentUnmaskedContext = ReactFiberContext.findCurrentUnmaskedContext
local processChildContext = ReactFiberContext.processChildContext
local emptyContextObject = ReactFiberContext.emptyContextObject
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local ReactFiberRoot = require(script.Parent["ReactFiberRoot.new"])
local createFiberRoot = ReactFiberRoot.createFiberRoot
local ReactFiberDevToolsHook = require(script.Parent["ReactFiberDevToolsHook.new"])
local injectInternals = ReactFiberDevToolsHook.injectInternals
local onScheduleRoot = ReactFiberDevToolsHook.onScheduleRoot
local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
local requestEventTime = ReactFiberWorkLoop.requestEventTime
local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local flushRoot = ReactFiberWorkLoop.flushRoot
local batchedEventUpdates = ReactFiberWorkLoop.batchedEventUpdates
local batchedUpdates = ReactFiberWorkLoop.batchedUpdates
local unbatchedUpdates = ReactFiberWorkLoop.unbatchedUpdates
local flushSync = ReactFiberWorkLoop.flushSync
local flushControlled = ReactFiberWorkLoop.flushControlled
local deferredUpdates = ReactFiberWorkLoop.deferredUpdates
local discreteUpdates = ReactFiberWorkLoop.discreteUpdates
local flushDiscreteUpdates = ReactFiberWorkLoop.flushDiscreteUpdates
local flushPassiveEffects = ReactFiberWorkLoop.flushPassiveEffects
local warnIfNotScopedWithMatchingAct = ReactFiberWorkLoop.warnIfNotScopedWithMatchingAct
local warnIfUnmockedScheduler = ReactFiberWorkLoop.warnIfUnmockedScheduler
local IsThisRendererActing = ReactFiberWorkLoop.IsThisRendererActing
local act = ReactFiberWorkLoop.act :: (() -> ()) -> ()
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
local createUpdate = ReactUpdateQueue.createUpdate
local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
local ReactCurrentFiberIsRendering = ReactCurrentFiber.isRendering
-- deviation: this property would be captured as values instead of bound
-- local ReactCurrentFiber.current = ReactCurrentFiber.current
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local StrictMode = ReactTypeOfMode.StrictMode
local SyncLane = ReactFiberLane.SyncLane
local InputDiscreteHydrationLane = ReactFiberLane.InputDiscreteHydrationLane
local SelectiveHydrationLane = ReactFiberLane.SelectiveHydrationLane
local NoTimestamp = ReactFiberLane.NoTimestamp
local getHighestPriorityPendingLanes = ReactFiberLane.getHighestPriorityPendingLanes
local higherPriorityLane = ReactFiberLane.higherPriorityLane
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority
-- local ReactFiberHotReloading = require(script.Parent["ReactFiberHotReloading.new"])
-- local scheduleRefresh = ReactFiberHotReloading.scheduleRefresh
-- local scheduleRoot = ReactFiberHotReloading.scheduleRoot
-- local setRefreshHandler = ReactFiberHotReloading.setRefreshHandler
-- local findHostInstancesForRefresh = ReactFiberHotReloading.findHostInstancesForRefresh
local markRenderScheduled = require(script.Parent.SchedulingProfiler).markRenderScheduled

local exports = {}

-- ROBLOX deviation: explicitly export internal type definitions used by the noop and test renderers
exports.ReactRootTags = ReactRootTags
-- ROBLOX deviation: explicitly export internal type definitions used by the test renderer
exports.ReactWorkTags = ReactWorkTags

-- ROBLOX deviation: explicitly export internal type definitions used by the dev tools
exports.ReactTypeOfMode = ReactTypeOfMode
exports.ReactFiberFlags = ReactFiberFlags
exports.getNearestMountedFiber = ReactFiberTreeReflection.getNearestMountedFiber
exports.findCurrentFiberUsingSlowPath =
	ReactFiberTreeReflection.findCurrentFiberUsingSlowPath

-- exports.registerMutableSourceForHydration = require(script.Parent["ReactMutableSource.new"]).registerMutableSourceForHydration
exports.createPortal = require(script.Parent.ReactPortal).createPortal
-- local ReactTestSelectors = require(script.Parent.ReactTestSelectors)
-- exports.createComponentSelector = ReactTestSelectors.createComponentSelector
-- ROBLOX FIXME: Should we deviate and fix this typo?
-- exports.createHasPsuedoClassSelector = ReactTestSelectors.createHasPsuedoClassSelector
-- exports.createRoleSelector = ReactTestSelectors.createRoleSelector
-- exports.createTestNameSelector = ReactTestSelectors.createTestNameSelector
-- exports.createTextSelector = ReactTestSelectors.createTextSelector
-- exports.getFindAllNodesFailureDescription = ReactTestSelectors.getFindAllNodesFailureDescription
-- exports.findAllNodes = ReactTestSelectors.findAllNodes
-- exports.findBoundingRects = ReactTestSelectors.findBoundingRects
-- exports.focusWithin = ReactTestSelectors.focusWithin
-- exports.observeVisibleRects = ReactTestSelectors.observeVisibleRects

type OpaqueRoot = FiberRoot

-- 0 is PROD, 1 is DEV.
-- Might add PROFILE later.
type BundleType = number

type DevToolsConfig = {
	bundleType: BundleType,
	version: string,
	rendererPackageName: string,
	-- Note: this actually *does* depend on Fiber internal fields.
	-- Used by "inspect clicked DOM element" in React DevTools.
	findFiberByHostInstance: ((Instance | TextInstance) -> Fiber)?,
	rendererConfig: RendererInspectionConfig?,
}

local didWarnAboutNestedUpdates
local didWarnAboutFindNodeInStrictMode

if __DEV__ then
	didWarnAboutNestedUpdates = false
	didWarnAboutFindNodeInStrictMode = {}
end

local function getContextForSubtree(parentComponent: any?): Object
	if not parentComponent then
		return emptyContextObject
	end

	local fiber = getInstance(parentComponent)
	local parentContext = findCurrentUnmaskedContext(fiber)

	if fiber.tag == ClassComponent then
		local Component = fiber.type
		if isLegacyContextProvider(Component) then
			return processChildContext(fiber, Component, parentContext)
		end
	end

	return parentContext
end

local function findHostInstance(component: Object): PublicInstance | nil
	local fiber = getInstance(component)
	if fiber == nil then
		if typeof(component.render) == "function" then
			invariant(false, "Unable to find node on an unmounted component.")
		else
			invariant(
				false,
				"Argument appears to not be a ReactComponent. Keys: %s",
				-- ROBLOX deviation: explicitly coerce the array of strings into a string
				table.concat(Object.keys(component))
			)
		end
	end
	local hostFiber = findCurrentHostFiber(fiber)
	if hostFiber == nil then
		return nil
	end
	return hostFiber.stateNode
end

local function findHostInstanceWithWarning(
	component: Object,
	methodName: string
): PublicInstance | nil
	if __DEV__ then
		local fiber = getInstance(component)
		if fiber == nil then
			if typeof(component.render) == "function" then
				invariant(false, "Unable to find node on an unmounted component.")
			else
				invariant(
					false,
					"Argument appears to not be a ReactComponent. Keys: %s",
					-- ROBLOX deviation: explicitly convert array into string
					table.concat(Object.keys(component))
				)
			end
		end
		local hostFiber = findCurrentHostFiber(fiber)
		if hostFiber == nil then
			return nil
		end
		if bit32.band(hostFiber.mode, StrictMode) ~= 0 then
			local componentName = getComponentName(fiber.type) or "Component"
			if not didWarnAboutFindNodeInStrictMode[componentName] then
				didWarnAboutFindNodeInStrictMode[componentName] = true

				local previousFiber = ReactCurrentFiber.current
				local ok, result = xpcall(function()
					setCurrentDebugFiberInDEV(hostFiber)
					if bit32.band(fiber.mode, StrictMode) ~= 0 then
						console.error(
							"%s is deprecated in StrictMode. "
								.. "%s was passed an instance of %s which is inside StrictMode. "
								.. "Instead, add a ref directly to the element you want to reference. "
								.. "Learn more about using refs safely here: "
								.. "https://reactjs.org/link/strict-mode-find-node",
							methodName,
							methodName,
							componentName
						)
					else
						console.error(
							"%s is deprecated in StrictMode. "
								.. "%s was passed an instance of %s which renders StrictMode children. "
								.. "Instead, add a ref directly to the element you want to reference. "
								.. "Learn more about using refs safely here: "
								.. "https://reactjs.org/link/strict-mode-find-node",
							methodName,
							methodName,
							componentName
						)
					end
				end, describeError)

				-- Ideally this should reset to previous but this shouldn't be called in
				-- render and there's another warning for that anyway.
				if previousFiber then
					setCurrentDebugFiberInDEV(previousFiber)
				else
					resetCurrentDebugFiberInDEV()
				end

				if not ok then
					error(result)
				end
			end
		end
		return hostFiber.stateNode
	end
	return findHostInstance(component)
end

exports.createContainer = function(
	containerInfo: Container,
	tag: RootTag,
	hydrate: boolean,
	hydrationCallbacks: nil | SuspenseHydrationCallbacks
): OpaqueRoot
	return createFiberRoot(containerInfo, tag, hydrate, hydrationCallbacks)
end

exports.updateContainer = function(
	element: ReactNodeList,
	container: OpaqueRoot,
	parentComponent,
	callback: Function?
): Lane
	if __DEV__ then
		onScheduleRoot(container, element)
	end
	local current = container.current
	local eventTime = requestEventTime()
	if __DEV__ then
		-- deviation: use TestEZ's __TESTEZ_RUNNING_TEST__ (no jest global)
		-- $FlowExpectedError - jest isn't a global, and isn't recognized outside of tests
		if _G.__TESTEZ_RUNNING_TEST__ then
			warnIfUnmockedScheduler(current)
			warnIfNotScopedWithMatchingAct(current)
		end
	end
	local lane = requestUpdateLane(current)

	if enableSchedulingProfiler then
		markRenderScheduled(lane)
	end

	local context = getContextForSubtree(parentComponent)
	if container.context == nil then
		container.context = context
	else
		container.pendingContext = context
	end

	if __DEV__ then
		if
			ReactCurrentFiberIsRendering
			and ReactCurrentFiber.current ~= nil
			and not didWarnAboutNestedUpdates
		then
			didWarnAboutNestedUpdates = true
			console.error(
				"Render methods should be a pure function of props and state; "
					.. "triggering nested component updates from render is not allowed. "
					.. "If necessary, trigger nested updates in componentDidUpdate.\n\n"
					.. "Check the render method of %s.",
				getComponentName((ReactCurrentFiber.current :: any).type) or "Unknown"
			)
		end
	end

	local update = createUpdate(eventTime, lane)
	-- deviation: We need to set element to a placeholder so that it gets
	-- removed from previous state when merging tables
	if element == nil then
		element = Object.None
	end
	-- Caution: React DevTools currently depends on this property
	-- being called "element".
	update.payload = {
		element = element,
	}

	-- deviation: no undefined, so not needed
	-- callback = callback == undefined ? nil : callback
	if callback ~= nil then
		if __DEV__ then
			if typeof(callback) ~= "function" then
				console.error(
					"render(...): Expected the last optional `callback` argument to be a "
						.. "function. Instead received: %s.",
					tostring(callback)
				)
			end
		end
		update.callback = callback
	end

	enqueueUpdate(current, update)
	scheduleUpdateOnFiber(current, lane, eventTime)

	return lane
end

-- FIXME: WIP
exports.batchedEventUpdates = batchedEventUpdates
exports.batchedUpdates = batchedUpdates
exports.unbatchedUpdates = unbatchedUpdates
exports.deferredUpdates = deferredUpdates
exports.discreteUpdates = discreteUpdates
exports.flushDiscreteUpdates = flushDiscreteUpdates
exports.flushControlled = flushControlled
exports.flushSync = flushSync
exports.flushPassiveEffects = flushPassiveEffects
exports.IsThisRendererActing = IsThisRendererActing
exports.act = act

exports.getPublicRootInstance =
	function(container: OpaqueRoot): React_Component<any, any> | PublicInstance | nil
		local containerFiber = container.current
		if not containerFiber.child then
			return nil
		end
		if containerFiber.child.tag == HostComponent then
			return getPublicInstance(containerFiber.child.stateNode)
		else
			return containerFiber.child.stateNode
		end
	end

-- deviation: Declare function ahead of use
local markRetryLaneIfNotHydrated

exports.attemptSynchronousHydration = function(fiber: Fiber)
	if fiber.tag == HostRoot then
		local root: FiberRoot = fiber.stateNode
		if root.hydrate then
			-- Flush the first scheduled "update".
			local lanes = getHighestPriorityPendingLanes(root)
			flushRoot(root, lanes)
		end
	elseif fiber.tag == SuspenseComponent then
		local eventTime = requestEventTime()
		flushSync(function()
			return scheduleUpdateOnFiber(fiber, SyncLane, eventTime)
		end)
		-- If we're still blocked after this, we need to increase
		-- the priority of any promises resolving within this
		-- boundary so that they next attempt also has higher pri.
		local retryLane = InputDiscreteHydrationLane
		markRetryLaneIfNotHydrated(fiber, retryLane)
	end
end

local function markRetryLaneImpl(fiber: Fiber, retryLane: Lane)
	local suspenseState: SuspenseState? = fiber.memoizedState
	if suspenseState then
		if suspenseState ~= nil and suspenseState.dehydrated ~= nil then
			suspenseState.retryLane =
				higherPriorityLane(suspenseState.retryLane, retryLane)
		end
	end
end

-- Increases the priority of thennables when they resolve within this boundary.
markRetryLaneIfNotHydrated = function(fiber: Fiber, retryLane: Lane)
	markRetryLaneImpl(fiber, retryLane)
	-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
	local alternate = fiber.alternate
	if alternate then
		markRetryLaneImpl(alternate, retryLane)
	end
end

exports.attemptUserBlockingHydration = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority and they should not suspend on I/O,
		-- since you have to wrap anything that might suspend in
		-- Suspense.
		return
	end
	local eventTime = requestEventTime()
	local lane = InputDiscreteHydrationLane
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.attemptContinuousHydration = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority and they should not suspend on I/O,
		-- since you have to wrap anything that might suspend in
		-- Suspense.
		return
	end
	local eventTime = requestEventTime()
	local lane = SelectiveHydrationLane
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.attemptHydrationAtCurrentPriority = function(fiber: Fiber)
	if fiber.tag ~= SuspenseComponent then
		-- We ignore HostRoots here because we can't increase
		-- their priority other than synchronously flush it.
		return
	end
	local eventTime = requestEventTime()
	local lane = requestUpdateLane(fiber)
	scheduleUpdateOnFiber(fiber, lane, eventTime)
	markRetryLaneIfNotHydrated(fiber, lane)
end

exports.runWithPriority = function<T>(priority: LanePriority, fn: () -> T): T
	local previousPriority = getCurrentUpdateLanePriority()
	-- ROBLOX performance: hoist non-throwable out of try{} to eliminate anon function
	setCurrentUpdateLanePriority(priority)
	local ok, result = xpcall(fn, describeError)
	setCurrentUpdateLanePriority(previousPriority)
	if not ok then
		error(result)
	end
	return result
end

exports.getCurrentUpdateLanePriority = getCurrentUpdateLanePriority

exports.findHostInstance = findHostInstance

exports.findHostInstanceWithWarning = findHostInstanceWithWarning

exports.findHostInstanceWithNoPortals = function(fiber: Fiber): PublicInstance?
	local hostFiber = findCurrentHostFiberWithNoPortals(fiber)
	if hostFiber == nil then
		return nil
	end
	if hostFiber.tag == FundamentalComponent then
		return hostFiber.stateNode.instance
	end
	return hostFiber.stateNode
end

local function shouldSuspendImpl(fiber)
	return false
end

exports.shouldSuspend = function(fiber: Fiber): boolean
	return shouldSuspendImpl(fiber)
end

local overrideHookState = nil
local overrideHookStateDeletePath = nil
local overrideHookStateRenamePath = nil
local overrideProps = nil
local overridePropsDeletePath = nil
local overridePropsRenamePath = nil
local scheduleUpdate = nil
local setSuspenseHandler = nil

if __DEV__ then
	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithDeleteImpl(
		obj: Object,
		path: Array<string | number>,
		index: number
	)
		local key = path[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		if index + 1 == #path then
			if Array.isArray(updated) then
				-- Narrow type
				local updatedIndex: number = key
				Array.splice(updated, updatedIndex, 1)
			else
				updated[key] = nil
			end
			return updated
		end
		-- $FlowFixMe number or string is fine here
		updated[key] = copyWithDeleteImpl(obj[key], path, index + 1)
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithDelete(
		obj: Object,
		path: Array<string | number>
	): Object | Array<any>
		return copyWithDeleteImpl(obj, path, 0)
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithRenameImpl(
		obj: Object,
		oldPath: Array<string | number>,
		newPath: Array<string | number>,
		index: number
	)
		local oldKey = oldPath[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		if index + 1 == #oldPath then
			local newKey = newPath[index]
			-- $FlowFixMe number or string is fine here
			updated[newKey] = updated[oldKey]
			if Array.isArray(updated) then
				Array.splice(updated, oldKey, 1)
			else
				updated[oldKey] = nil
			end
		else
			-- $FlowFixMe number or string is fine here
			updated[oldKey] = copyWithRenameImpl(
				-- $FlowFixMe number or string is fine here
				obj[oldKey],
				oldPath,
				newPath,
				index + 1
			)
		end
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithRename(
		obj: Object,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	): Object | Array<any> | nil
		if #oldPath ~= #newPath then
			console.warn("copyWithRename() expects paths of the same length")
			return nil
		else
			for i = 1, #newPath do
				if oldPath[i] ~= newPath[i] then
					console.warn(
						"copyWithRename() expects paths to be the same except for the deepest key"
					)
					return nil
				end
			end
		end
		return copyWithRenameImpl(obj, oldPath, newPath, 0)
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithSetImpl(
		obj: Object,
		path: Array<string | number>,
		index: number,
		value: any
	)
		if index >= (#path + 1) then
			return value
		end
		local key = path[index]
		local updated
		if Array.isArray(obj) then
			updated = Array.slice(obj)
		else
			updated = table.clone(obj)
		end
		-- $FlowFixMe number or string is fine here
		updated[key] = copyWithSetImpl(obj[key], path, index + 2, value)
		return updated
	end

	-- deviation: FIXME: obj: `Object | Array<any>`, narrowing not possible with `isArray`
	local function copyWithSet(
		obj: Object,
		path: Array<string | number>,
		value: any
	): Object | Array<any>
		return copyWithSetImpl(obj, path, 1, value)
	end

	local function findHook(fiber: Fiber, id: number)
		-- For now, the "id" of stateful hooks is just the stateful hook index.
		-- This may change in the future with e.g. nested hooks.
		local currentHook = fiber.memoizedState
		while currentHook ~= nil and id > 1 do
			currentHook = currentHook.next
			id -= 1
		end
		return currentHook
	end

	-- Support DevTools editable values for useState and useReducer.
	overrideHookState =
		function(fiber: Fiber, id: number, path: Array<string | number>, value: any)
			local hook = findHook(fiber, id)
			if hook ~= nil then
				local newState = copyWithSet(hook.memoizedState, path, value)
				hook.memoizedState = newState
				hook.baseState = newState

				-- We aren't actually adding an update to the queue,
				-- because there is no update we can add for useReducer hooks that won't trigger an error.
				-- (There's no appropriate action type for DevTools overrides.)
				-- As a result though, React will see the scheduled update as a noop and bailout.
				-- Shallow cloning props works as a workaround for now to bypass the bailout check.
				fiber.memoizedProps = table.clone(fiber.memoizedProps)

				scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
			end
		end
	overrideHookStateDeletePath =
		function(fiber: Fiber, id: number, path: Array<string | number>)
			local hook = findHook(fiber, id)
			if hook ~= nil then
				local newState = copyWithDelete(hook.memoizedState, path)
				hook.memoizedState = newState
				hook.baseState = newState

				-- We aren't actually adding an update to the queue,
				-- because there is no update we can add for useReducer hooks that won't trigger an error.
				-- (There's no appropriate action type for DevTools overrides.)
				-- As a result though, React will see the scheduled update as a noop and bailout.
				-- Shallow cloning props works as a workaround for now to bypass the bailout check.
				fiber.memoizedProps = table.clone(fiber.memoizedProps)

				scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
			end
		end
	overrideHookStateRenamePath = function(
		fiber: Fiber,
		id: number,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	)
		local hook = findHook(fiber, id)
		if hook ~= nil then
			local newState = copyWithRename(hook.memoizedState, oldPath, newPath)
			hook.memoizedState = newState
			hook.baseState = newState

			-- We aren't actually adding an update to the queue,
			-- because there is no update we can add for useReducer hooks that won't trigger an error.
			-- (There's no appropriate action type for DevTools overrides.)
			-- As a result though, React will see the scheduled update as a noop and bailout.
			-- Shallow cloning props works as a workaround for now to bypass the bailout check.
			fiber.memoizedProps = table.clone(fiber.memoizedProps)

			scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
		end
	end

	-- Support DevTools props for function components, forwardRef, memo, host components, etc.
	overrideProps = function(fiber: Fiber, path: Array<string | number>, value: any)
		fiber.pendingProps = copyWithSet(fiber.memoizedProps, path, value)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end
	overridePropsDeletePath = function(fiber: Fiber, path: Array<string | number>)
		fiber.pendingProps = copyWithDelete(fiber.memoizedProps, path)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end
	overridePropsRenamePath = function(
		fiber: Fiber,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	)
		fiber.pendingProps = copyWithRename(fiber.memoizedProps, oldPath, newPath)
		-- ROBLOX TODO: grab local for this since Luau can't deal with nested type narrowing
		local alternate = fiber.alternate
		if alternate then
			alternate.pendingProps = fiber.pendingProps
		end
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end

	scheduleUpdate = function(fiber: Fiber)
		scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
	end

	setSuspenseHandler = function(newShouldSuspendImpl: (Fiber) -> (boolean))
		shouldSuspendImpl = newShouldSuspendImpl
	end
end

function findHostInstanceByFiber(fiber: Fiber): Instance | TextInstance | nil
	local hostFiber = findCurrentHostFiber(fiber)
	if hostFiber == nil then
		return nil
	end
	return hostFiber.stateNode
end

function emptyFindFiberByHostInstance(instance: Instance | TextInstance): Fiber | nil
	return nil
end

function getCurrentFiberForDevTools()
	return ReactCurrentFiber.current
end

exports.injectIntoDevTools = function(devToolsConfig: DevToolsConfig): boolean
	local findFiberByHostInstance = devToolsConfig.findFiberByHostInstance
	local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
	local getCurrentFiber = nil
	if __DEV__ then
		getCurrentFiber = getCurrentFiberForDevTools
	end
	return injectInternals({
		bundleType = devToolsConfig.bundleType,
		version = devToolsConfig.version,
		rendererPackageName = devToolsConfig.rendererPackageName,
		rendererConfig = devToolsConfig.rendererConfig,
		overrideHookState = overrideHookState,
		overrideHookStateDeletePath = overrideHookStateDeletePath,
		overrideHookStateRenamePath = overrideHookStateRenamePath,
		overrideProps = overrideProps,
		overridePropsDeletePath = overridePropsDeletePath,
		overridePropsRenamePath = overridePropsRenamePath,
		setSuspenseHandler = setSuspenseHandler,
		scheduleUpdate = scheduleUpdate,
		currentDispatcherRef = ReactCurrentDispatcher,
		findHostInstanceByFiber = findHostInstanceByFiber,
		findFiberByHostInstance = findFiberByHostInstance or emptyFindFiberByHostInstance,
		-- FIXME: WIP
		-- React Refresh
		-- findHostInstancesForRefresh = __DEV__ and findHostInstancesForRefresh or nil,
		-- scheduleRefresh = __DEV__ and scheduleRefresh or nil,
		-- scheduleRoot = __DEV__ and scheduleRoot or nil,
		-- setRefreshHandler = __DEV__ and setRefreshHandler or nil,
		-- Enables DevTools to append owner stacks to error messages in DEV mode.
		getCurrentFiber = getCurrentFiber,
	})
end

return exports
