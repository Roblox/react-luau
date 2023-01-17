--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1faf9e3dd5d6492f3607d5c721055819e4106bc6/packages/react-reconciler/src/ReactFiberBeginWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- ROBLOX TODO remove this when CLI-38793 lands
--!nolint LocalShadow
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local __DEV__ = _G.__DEV__ :: boolean
local __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ =
	_G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ :: boolean
local __COMPAT_WARNINGS__ = _G.__COMPAT_WARNINGS__ :: boolean

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from Shared
local Shared = require(Packages.Shared)
local console = Shared.console
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect

local ReactTypes = require(Packages.Shared)
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type ReactContext<T> = ReactTypes.ReactContext<T>
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>

local React = require(Packages.React)
type LazyComponentType<T, P> = React.LazyComponent<T, P>

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
-- type Lane = ReactFiberLane.Lane;
-- local type {MutableSource} = require(Packages.Shared.ReactTypes)

local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
type SuspenseListRenderState = ReactFiberSuspenseComponent.SuspenseListRenderState
type SuspenseListTailMode = ReactFiberSuspenseComponent.SuspenseListTailMode
local ReactFiberSuspenseContext = require(script.Parent["ReactFiberSuspenseContext.new"])
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext

local ReactFiberOffscreenComponent = require(script.Parent.ReactFiberOffscreenComponent)
type OffscreenProps = ReactFiberOffscreenComponent.OffscreenProps
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState

local checkPropTypes = require(Packages.Shared).checkPropTypes

local ReactWorkTags = require(script.Parent.ReactWorkTags)
-- local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
-- local FundamentalComponent = ReactWorkTags.FundamentalComponent
-- local ScopeComponent = ReactWorkTags.ScopeComponent
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local NoFlags = ReactFiberFlags.NoFlags
local StaticMask = ReactFiberFlags.StaticMask
local PerformedWork = ReactFiberFlags.PerformedWork
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
local ContentReset = ReactFiberFlags.ContentReset
local DidCapture = ReactFiberFlags.DidCapture
-- local Update = ReactFiberFlags.Update
local Ref = ReactFiberFlags.Ref
local Deletion = ReactFiberFlags.Deletion
local ForceUpdateForLegacySuspense = ReactFiberFlags.ForceUpdateForLegacySuspense
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode
local disableLegacyContext = ReactFeatureFlags.disableLegacyContext
local disableModulePatternComponents = ReactFeatureFlags.disableModulePatternComponents
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
local warnAboutDefaultPropsOnFunctionComponents =
	ReactFeatureFlags.warnAboutDefaultPropsOnFunctionComponents
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local invariant = require(Packages.Shared).invariant
local describeError = require(Packages.Shared).describeError
local shallowEqual = require(Packages.Shared).shallowEqual
local getComponentName = require(Packages.Shared).getComponentName
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local _getIteratorFn = ReactSymbols.getIteratorFn
local ReactStrictModeWarnings = require(script.Parent["ReactStrictModeWarnings.new"])
local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
local getCurrentFiberOwnerNameInDevOrNull =
	ReactCurrentFiber.getCurrentFiberOwnerNameInDevOrNull
local setIsRendering = ReactCurrentFiber.setIsRendering
local ReactFiberHotReloadingModule = require(script.Parent["ReactFiberHotReloading.new"])
local resolveFunctionForHotReloading =
	ReactFiberHotReloadingModule.resolveFunctionForHotReloading
local resolveForwardRefForHotReloading =
	ReactFiberHotReloadingModule.resolveForwardRefForHotReloading
local resolveClassForHotReloading =
	ReactFiberHotReloadingModule.resolveClassForHotReloading

local ReactChildFiber = require(script.Parent["ReactChildFiber.new"]) :: any
local mountChildFibers = ReactChildFiber.mountChildFibers
local reconcileChildFibers = ReactChildFiber.reconcileChildFibers
local cloneChildFibers = ReactChildFiber.cloneChildFibers
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
local processUpdateQueue = ReactUpdateQueue.processUpdateQueue
local cloneUpdateQueue = ReactUpdateQueue.cloneUpdateQueue
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local NoMode = ReactTypeOfMode.NoMode
local ProfileMode = ReactTypeOfMode.ProfileMode
local StrictMode = ReactTypeOfMode.StrictMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local shouldSetTextContent = ReactFiberHostConfig.shouldSetTextContent
local isSuspenseInstancePending = ReactFiberHostConfig.isSuspenseInstancePending
local isSuspenseInstanceFallback = ReactFiberHostConfig.isSuspenseInstanceFallback
local registerSuspenseInstanceRetry = ReactFiberHostConfig.registerSuspenseInstanceRetry
local supportsHydration = ReactFiberHostConfig.supportsHydration
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance

local ReactFiberHostContext = require(script.Parent["ReactFiberHostContext.new"])
local pushHostContext = ReactFiberHostContext.pushHostContext
local pushHostContainer = ReactFiberHostContext.pushHostContainer
local suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
local hasSuspenseContext = ReactFiberSuspenseContext.hasSuspenseContext
local ForceSuspenseFallback = ReactFiberSuspenseContext.ForceSuspenseFallback
local addSubtreeSuspenseContext = ReactFiberSuspenseContext.addSubtreeSuspenseContext
local InvisibleParentSuspenseContext =
	ReactFiberSuspenseContext.InvisibleParentSuspenseContext
local pushSuspenseContext = ReactFiberSuspenseContext.pushSuspenseContext
-- local setShallowSuspenseContext = ReactFiberSuspenseContext.setShallowSuspenseContext
local setDefaultShallowSuspenseContext =
	ReactFiberSuspenseContext.setDefaultShallowSuspenseContext
-- local {findFirstSuspended} = require(script.Parent.ReactFiberSuspenseComponent.new)
-- local {
--   ,
local ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"])
local propagateContextChange = ReactFiberNewContext.propagateContextChange
local readContext = ReactFiberNewContext.readContext
local calculateChangedBits = ReactFiberNewContext.calculateChangedBits
-- local scheduleWorkOnParentPath = ReactFiberNewContext.scheduleWorkOnParentPath
local prepareToReadContext = ReactFiberNewContext.prepareToReadContext
local pushProvider = ReactFiberNewContext.pushProvider

-- ROBLOX deviation: Lazy init all methods from ReactFiberHooks
local lazyRefs = {
	renderWithHooksRef = nil :: any,
	bailoutHooksRef = nil :: any,
	shouldSuspendRef = nil :: any,
}

local function shouldSuspend(fiber: Fiber): boolean
	if not lazyRefs.shouldSuspendRef then
		lazyRefs.shouldSuspendRef =
			require(script.Parent.ReactFiberReconciler).shouldSuspend
	end
	return lazyRefs.shouldSuspendRef(fiber)
end

-- ROBLOX deviation: collective lazy init methods from ReactFiberHooks
local function initReactFiberHooks()
	local ReactFiberHooks = require(script.Parent["ReactFiberHooks.new"])
	lazyRefs.renderWithHooksRef = ReactFiberHooks.renderWithHooks
	lazyRefs.bailoutHooksRef = ReactFiberHooks.bailoutHooks
end

-- ROBLOX deviation: Lazy init renderWithHooks from ReactFiberHooks
local function renderWithHooks(...)
	if not lazyRefs.renderWithHooksRef then
		initReactFiberHooks()
	end
	return lazyRefs.renderWithHooksRef(...)
end

-- ROBLOX deviation: Lazy init bailoutHooks from ReactFiberHooks
local function bailoutHooks(...)
	if not lazyRefs.bailoutHooksRef then
		initReactFiberHooks()
	end
	return lazyRefs.bailoutHooksRef(...)
end

local stopProfilerTimerIfRunning =
	require(script.Parent["ReactProfilerTimer.new"]).stopProfilerTimerIfRunning
local ReactFiberContext = require(script.Parent["ReactFiberContext.new"])
local getMaskedContext = ReactFiberContext.getMaskedContext
local getUnmaskedContext = ReactFiberContext.getUnmaskedContext
local hasLegacyContextChanged = ReactFiberContext.hasContextChanged
local pushLegacyContextProvider = ReactFiberContext.pushContextProvider
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local pushTopLevelContextObject = ReactFiberContext.pushTopLevelContextObject
local invalidateContextProvider = ReactFiberContext.invalidateContextProvider

local ReactFiberHydrationContext =
	require(script.Parent["ReactFiberHydrationContext.new"])
local resetHydrationState = ReactFiberHydrationContext.resetHydrationState
local enterHydrationState = ReactFiberHydrationContext.enterHydrationState
local reenterHydrationStateFromDehydratedSuspenseInstance =
	ReactFiberHydrationContext.reenterHydrationStateFromDehydratedSuspenseInstance
local tryToClaimNextHydratableInstance =
	ReactFiberHydrationContext.tryToClaimNextHydratableInstance
local warnIfHydrating = ReactFiberHydrationContext.warnIfHydrating
local ReactFiberClassComponent =
	require(script.Parent["ReactFiberClassComponent.new"]) :: any
local adoptClassInstance = ReactFiberClassComponent.adoptClassInstance
local applyDerivedStateFromProps = ReactFiberClassComponent.applyDerivedStateFromProps
local constructClassInstance = ReactFiberClassComponent.constructClassInstance
local mountClassInstance = ReactFiberClassComponent.mountClassInstance
local resumeMountClassInstance = ReactFiberClassComponent.resumeMountClassInstance
local updateClassInstance = ReactFiberClassComponent.updateClassInstance

local resolveDefaultProps =
	require(script.Parent["ReactFiberLazyComponent.new"]).resolveDefaultProps
local ReactFiber = require(script.Parent["ReactFiber.new"])
local resolveLazyComponentTag = ReactFiber.resolveLazyComponentTag
local createFiberFromFragment = ReactFiber.createFiberFromFragment
local createFiberFromOffscreen = ReactFiber.createFiberFromOffscreen

local createFiberFromTypeAndProps = ReactFiber.createFiberFromTypeAndProps
local isSimpleFunctionComponent = ReactFiber.isSimpleFunctionComponent
local createWorkInProgress = ReactFiber.createWorkInProgress
local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
local pushRenderLanes = ReactFiberWorkLoop.pushRenderLanes
local markSpawnedWork = ReactFiberWorkLoop.markSpawnedWork
local retryDehydratedSuspenseBoundary = ReactFiberWorkLoop.retryDehydratedSuspenseBoundary
local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local renderDidSuspendDelayIfPossible = ReactFiberWorkLoop.renderDidSuspendDelayIfPossible
local getWorkInProgressRoot = ReactFiberWorkLoop.getWorkInProgressRoot
local getExecutionContext = ReactFiberWorkLoop.getExecutionContext
local RetryAfterError = ReactFiberWorkLoop.RetryAfterError
local NoContext = ReactFiberWorkLoop.NoContext

local Schedule_tracing_wrap
local setWorkInProgressVersion =
	require(script.Parent["ReactMutableSource.new"]).setWorkInProgressVersion
local markSkippedUpdateLanes =
	require(script.Parent.ReactFiberWorkInProgress).markSkippedUpdateLanes
local ConsolePatchingDev = require(Packages.Shared).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner

local exports: { [string]: any } = {}

-- ROBLOX deviation: Pre-declare functions
local bailoutOnAlreadyFinishedWork, updateFunctionComponent

local didReceiveUpdate: boolean = false

-- ROBLOX deviation: put didWarns in table to reduce number of local variables
local DidWarn = {
	didWarnAboutBadClass = {} :: { [string]: boolean },
	didWarnAboutModulePatternComponent = {} :: { [string]: boolean },
	didWarnAboutContextTypeOnFunctionComponent = {} :: { [string]: boolean },
	didWarnAboutGetDerivedStateOnFunctionComponent = {} :: { [string]: boolean },
	didWarnAboutFunctionRefs = {} :: { [string]: boolean },
	didWarnAboutDefaultPropsOnFunctionComponent = {} :: { [string]: boolean },
}
-- export local didWarnAboutReassigningProps
-- local didWarnAboutRevealOrder
-- local didWarnAboutTailOptions
local updateSimpleMemoComponent

if __DEV__ then
	DidWarn.didWarnAboutBadClass = {}
	DidWarn.didWarnAboutModulePatternComponent = {}
	DidWarn.didWarnAboutContextTypeOnFunctionComponent = {}
	DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent = {}
	DidWarn.didWarnAboutFunctionRefs = {}
	exports.didWarnAboutReassigningProps = false
	--   didWarnAboutRevealOrder = {}
	--   didWarnAboutTailOptions = {}
	DidWarn.didWarnAboutDefaultPropsOnFunctionComponent = {}
end

local function reconcileChildren(
	current: Fiber | nil,
	workInProgress: Fiber,
	nextChildren: any,
	renderLanes: Lanes
)
	if current == nil then
		-- If this is a fresh new component that hasn't been rendered yet, we
		-- won't update its child set by applying minimal side-effects. Instead,
		-- we will add them all to the child before it gets rendered. That means
		-- we can optimize this reconciliation pass by not tracking side-effects.
		workInProgress.child =
			mountChildFibers(workInProgress, nil, nextChildren, renderLanes)
	else
		-- If the current child is the same as the work in progress, it means that
		-- we haven't yet started any work on these children. Therefore, we use
		-- the clone algorithm to create a copy of all the current children.

		-- If we had any progressed work already, that is invalid at this point so
		-- let's throw it out.
		workInProgress.child = reconcileChildFibers(
			workInProgress,
			(current :: Fiber).child,
			nextChildren,
			renderLanes
		)
	end
end

local function forceUnmountCurrentAndReconcile(
	current: Fiber,
	workInProgress: Fiber,
	nextChildren: any,
	renderLanes: Lanes
)
	-- This function is fork of reconcileChildren. It's used in cases where we
	-- want to reconcile without matching against the existing set. This has the
	-- effect of all current children being unmounted; even if the type and key
	-- are the same, the old child is unmounted and a new child is created.
	--
	-- To do this, we're going to go through the reconcile algorithm twice. In
	-- the first pass, we schedule a deletion for all the current children by
	-- passing nil.
	workInProgress.child =
		reconcileChildFibers(workInProgress, current.child, nil, renderLanes)
	-- In the second pass, we mount the new children. The trick here is that we
	-- pass nil in place of where we usually pass the current child set. This has
	-- the effect of remounting all children regardless of whether their
	-- identities match.
	workInProgress.child =
		reconcileChildFibers(workInProgress, nil, nextChildren, renderLanes)
end

local function updateForwardRef(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	renderLanes: Lanes
)
	-- TODO: current can be non-null here even if the component
	-- hasn't yet mounted. This happens after the first render suspends.
	-- We'll need to figure out if this is fine or can cause issues.

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes = Component.propTypes
			local validateProps = Component.validateProps
			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	local render = Component.render
	local ref = workInProgress.ref

	-- The rest is a fork of updateFunctionComponent
	local nextChildren
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		nextChildren =
			renderWithHooks(current, workInProgress, render, nextProps, ref, renderLanes)
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			local ok, result = xpcall(
				renderWithHooks,
				describeError,
				current,
				workInProgress,
				render,
				nextProps,
				ref,
				renderLanes
			)
			if ok then
				nextChildren = result
			end
			-- finally
			reenableLogs()

			if not ok then
				error(result)
			end
		end
		setIsRendering(false)
	else
		nextChildren =
			renderWithHooks(current, workInProgress, render, nextProps, ref, renderLanes)
	end

	if current ~= nil and not didReceiveUpdate then
		bailoutHooks(current, workInProgress, renderLanes)
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function updateMemoComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	updateLanes: Lanes,
	renderLanes: Lanes
): nil | Fiber
	if current == nil then
		local type_ = Component.type
		if
			isSimpleFunctionComponent(type_)
			and Component.compare == nil
			-- SimpleMemoComponent codepath doesn't resolve outer props either.
			and Component.defaultProps == nil
		then
			local resolvedType = type_
			if __DEV__ then
				resolvedType = resolveFunctionForHotReloading(type_)
			end
			-- If this is a plain function component without default props,
			-- and with only the default shallow comparison, we upgrade it
			-- to a SimpleMemoComponent to allow fast path updates.
			workInProgress.tag = SimpleMemoComponent
			workInProgress.type = resolvedType
			if __DEV__ then
				validateFunctionComponentInDev(workInProgress, type_)
			end
			return updateSimpleMemoComponent(
				current,
				workInProgress,
				resolvedType,
				nextProps,
				updateLanes,
				renderLanes
			)
		end
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes
			local validateProps
			-- ROBLOX deviation: avoid accessing propTypes on a function, Lua doesn't support fields on functions
			if type(type_) == "table" then
				innerPropTypes = type_.propTypes
				validateProps = type_.validateProps
			end

			if innerPropTypes or validateProps then
				-- Inner memo component props aren't currently validated in createElement.
				-- We could move it there, but we'd still need this for lazy code path.
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(type_)
				)
			end
		end
		local child = createFiberFromTypeAndProps(
			Component.type,
			nil,
			nextProps,
			workInProgress,
			workInProgress.mode,
			renderLanes
		)
		child.ref = workInProgress.ref
		child.return_ = workInProgress
		workInProgress.child = child
		return child
	end
	-- ROBLOX TODO Deviation: remove redefinition + typecast when this lands: CLI-38793
	-- ROBLOX the if clause above returns early if current is nil
	local current = current :: Fiber
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local type_ = Component.type
		-- ROBLOX deviation: adds support for legacy Roact's validateProps()
		local innerPropTypes
		local validateProps
		-- ROBLOX deviation: only check for propTypes on class components, Lua doesn't support fields on functions
		if type(type_) == "table" then
			innerPropTypes = type_.propTypes
			validateProps = type_.validateProps
		end

		if innerPropTypes or validateProps then
			-- Inner memo component props aren't currently validated in createElement.
			-- We could move it there, but we'd still need this for lazy code path.
			checkPropTypes(
				innerPropTypes,
				validateProps,
				nextProps, -- Resolved props
				"prop",
				getComponentName(type_)
			)
		end
	end
	local currentChild = (current.child :: any) :: Fiber -- This is always exactly one child
	if not ReactFiberLane.includesSomeLane(updateLanes, renderLanes) then
		-- This will be the props with resolved defaultProps,
		-- unlike current.memoizedProps which will be the unresolved ones.
		local prevProps = currentChild.memoizedProps
		-- Default to shallow comparison
		local compare = Component.compare
		if compare == nil then
			compare = shallowEqual
		end
		if compare(prevProps, nextProps) and current.ref == workInProgress.ref then
			return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
		end
	end
	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	local newChild = createWorkInProgress(currentChild, nextProps)
	newChild.ref = workInProgress.ref
	newChild.return_ = workInProgress
	workInProgress.child = newChild
	return newChild
end

function updateSimpleMemoComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	updateLanes: Lanes,
	renderLanes: Lanes
): nil | Fiber
	-- TODO: current can be non-null here even if the component
	-- hasn't yet mounted. This happens when the inner render suspends.
	-- We'll need to figure out if this is fine or can cause issues.

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			local outerMemoType = workInProgress.elementType
			if outerMemoType["$$typeof"] == REACT_LAZY_TYPE then
				-- We warn when you define propTypes on lazy()
				-- so let's just skip over it to find memo() outer wrapper.
				-- Inner props for memo are validated later.
				local lazyComponent: LazyComponentType<any, any> = outerMemoType
				local payload = lazyComponent._payload
				local init = lazyComponent._init
				local ok, result = xpcall(init, describeError, payload)
				if ok then
					outerMemoType = result
				else
					outerMemoType = nil
				end
				-- Inner propTypes will be validated in the function component path.
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes
				local validateProps
				-- ROBLOX deviation: avoid accessing propTypes on a function, Lua doesn't support fields on functions
				if outerMemoType ~= nil and type(outerMemoType) == "table" then
					outerPropTypes = (outerMemoType :: any).propTypes
					-- ROBLOX deviation: support legacy Roact's equivalent of propTypes
					validateProps = (outerMemoType :: any).validateProps
				end

				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						nextProps, -- Resolved (SimpleMemoComponent has no defaultProps)
						"prop",
						getComponentName(outerMemoType)
					)
				end
			end
		end
	end
	if current ~= nil then
		-- ROBLOX TODO Deviation: remove redefinition + typecast when this lands: CLI-38793
		-- This unfortunately breaks if current gets reassigned somewhere in this if clause
		local current = current :: Fiber
		local prevProps = current.memoizedProps
		-- ROBLOX Deviation: replacing ternary operator
		local preventBailout = true
		if __DEV__ then
			preventBailout = workInProgress.type == current.type
		end
		if
			shallowEqual(prevProps, nextProps)
			and current.ref == workInProgress.ref
			-- Prevent bailout if the implementation changed due to hot reload.
			and preventBailout
		then
			didReceiveUpdate = false
			if not ReactFiberLane.includesSomeLane(renderLanes, updateLanes) then
				-- The pending lanes were cleared at the beginning of beginWork. We're
				-- about to bail out, but there might be other lanes that weren't
				-- included in the current render. Usually, the priority level of the
				-- remaining updates is accumlated during the evaluation of the
				-- component (i.e. when processing the update queue). But since since
				-- we're bailing out early *without* evaluating the component, we need
				-- to account for it here, too. Reset to the value of the current fiber.
				-- NOTE: This only applies to SimpleMemoComponent, not MemoComponent,
				-- because a MemoComponent fiber does not have hooks or an update queue
				-- rather, it wraps around an inner component, which may or may not
				-- contains hooks.
				-- TODO: Move the reset at in beginWork out of the common path so that
				-- this is no longer necessary.
				workInProgress.lanes = current.lanes
				return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
			elseif bit32.band(current.flags, ForceUpdateForLegacySuspense) ~= NoFlags then
				-- This is a special case that only exists for legacy mode.
				-- See https://github.com/facebook/react/pull/19216.
				didReceiveUpdate = true
			end
		end
	end
	return updateFunctionComponent(
		current,
		workInProgress,
		Component,
		nextProps,
		renderLanes
	)
end

local function updateOffscreenComponent(
	current: Fiber?,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	local nextProps: OffscreenProps = workInProgress.pendingProps
	local nextChildren = nextProps.children

	local prevState: OffscreenState?
	if current ~= nil then
		-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil checks
		prevState = (current :: Fiber).memoizedState
	end

	if
		nextProps.mode == "hidden"
		or nextProps.mode == "unstable-defer-without-hiding"
	then
		if bit32.band(workInProgress.mode, ConcurrentMode) == NoMode then
			-- In legacy sync mode, don't defer the subtree. Render it now.
			-- TODO: Figure out what we should do in Blocking mode.
			local nextState: OffscreenState = {
				baseLanes = ReactFiberLane.NoLanes,
			}
			workInProgress.memoizedState = nextState
			pushRenderLanes(workInProgress, renderLanes)
		-- ROBLOX TODO: recast ReactFiberLane.OffscreenLane to type Lane
		elseif
			not ReactFiberLane.includesSomeLane(renderLanes, ReactFiberLane.OffscreenLane)
		then
			local nextBaseLanes
			if prevState ~= nil then
				-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
				local prevBaseLanes = (prevState :: OffscreenState).baseLanes
				nextBaseLanes = ReactFiberLane.mergeLanes(prevBaseLanes, renderLanes)
			else
				nextBaseLanes = renderLanes
			end

			-- Schedule this fiber to re-render at offscreen priority. Then bailout.
			if enableSchedulerTracing then
				markSpawnedWork(ReactFiberLane.OffscreenLane)
			end

			-- deviation: unchain multiple assignment into two discrete assignments.
			workInProgress.childLanes =
				ReactFiberLane.laneToLanes(ReactFiberLane.OffscreenLane)
			workInProgress.lanes = workInProgress.childLanes

			local nextState: OffscreenState = {
				baseLanes = nextBaseLanes,
			}
			workInProgress.memoizedState = nextState
			-- We're about to bail out, but we need to push this to the stack anyway
			-- to avoid a push/pop misalignment.
			pushRenderLanes(workInProgress, nextBaseLanes)
			return nil
		else
			-- Rendering at offscreen, so we can clear the base lanes.
			local nextState: OffscreenState = {
				baseLanes = ReactFiberLane.NoLanes,
			}
			workInProgress.memoizedState = nextState
			-- Push the lanes that were skipped when we bailed out.
			local subtreeRenderLanes = renderLanes

			-- deviation: ternary converted to if statement
			if prevState ~= nil then
				-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
				subtreeRenderLanes = (prevState :: OffscreenState).baseLanes
			end

			pushRenderLanes(workInProgress, subtreeRenderLanes)
		end
	else
		local subtreeRenderLanes
		if prevState ~= nil then
			-- ROBLOX FIXME: remove :: recast once Luau understands if-statement nil check
			subtreeRenderLanes = ReactFiberLane.mergeLanes(
				(prevState :: OffscreenState).baseLanes,
				renderLanes
			)
			-- Since we're not hidden anymore, reset the state
			workInProgress.memoizedState = nil
		else
			-- We weren't previously hidden, and we still aren't, so there's nothing
			-- special to do. Need to push to the stack regardless, though, to avoid
			-- a push/pop misalignment.
			subtreeRenderLanes = renderLanes
		end
		pushRenderLanes(workInProgress, subtreeRenderLanes)
	end

	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

-- Note: These happen to have identical begin phases, for now. We shouldn't hold
-- ourselves to this constraint, though. If the behavior diverges, we should
-- fork the function.
local updateLegacyHiddenComponent = updateOffscreenComponent

function updateFragment(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	local nextChildren = workInProgress.pendingProps
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

function updateMode(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	local nextChildren = workInProgress.pendingProps.children
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

function updateProfiler(current: Fiber | nil, workInProgress: Fiber, renderLanes: Lanes)
	if enableProfilerTimer then
		-- Reset effect durations for the next eventual effect phase.
		-- These are reset during render to allow the DevTools commit hook a chance to read them,
		local stateNode = workInProgress.stateNode
		stateNode.effectDuration = 0
		stateNode.passiveEffectDuration = 0
	end
	local nextProps = workInProgress.pendingProps
	local nextChildren = nextProps.children
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function markRef(current: Fiber | nil, workInProgress: Fiber)
	local ref = workInProgress.ref
	if
		(current == nil and ref ~= nil)
		or (current ~= nil and (current :: Fiber).ref ~= ref)
	then
		-- Schedule a Ref effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Ref)
	end
end

function updateFunctionComponent(
	current,
	workInProgress,
	Component,
	nextProps: any,
	renderLanes
)
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		-- ROBLOX deviation: function components can't have props in Lua
		if
			type(Component) ~= "function"
			and (workInProgress.type ~= workInProgress.elementType)
		then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes
			local validateProps
			-- ROBLOX deviation: Roact won't support propTypes on functional components
			if type(Component) == "table" then
				innerPropTypes = (Component :: any).propTypes
				validateProps = (Component :: any).validateProps
			end

			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	local context
	if not disableLegacyContext then
		local unmaskedContext = getUnmaskedContext(workInProgress, Component, true)
		context = getMaskedContext(workInProgress, unmaskedContext)
	end

	local nextChildren
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		nextChildren = renderWithHooks(
			current,
			workInProgress,
			Component,
			nextProps,
			context,
			renderLanes
		)
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			local ok, result = xpcall(
				renderWithHooks,
				describeError,
				current,
				workInProgress,
				Component,
				nextProps,
				context,
				renderLanes
			)
			-- finally
			reenableLogs()
			if ok then
				nextChildren = result
			else
				error(result)
			end
		end
		setIsRendering(false)
	else
		nextChildren = renderWithHooks(
			current,
			workInProgress,
			Component,
			nextProps,
			context,
			renderLanes
		)
	end

	if current ~= nil and not didReceiveUpdate then
		bailoutHooks(current, workInProgress, renderLanes)
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

-- function updateBlock<Props, Data>(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   block: BlockComponent<Props, Data>,
--   nextProps: any,
--   renderLanes: Lanes,
-- )
--   -- TODO: current can be non-null here even if the component
--   -- hasn't yet mounted. This happens after the first render suspends.
--   -- We'll need to figure out if this is fine or can cause issues.

--   local render = block._render
--   local data = block._data

--   -- The rest is a fork of updateFunctionComponent
--   local nextChildren
--   prepareToReadContext(workInProgress, renderLanes, exports.markWorkInProgressReceivedUpdate)
--   if  __DEV__ then
--     ReactCurrentOwner.current = workInProgress
--     setIsRendering(true)
--     nextChildren = renderWithHooks(
--       current,
--       workInProgress,
--       render,
--       nextProps,
--       data,
--       renderLanes,
--     )
--     if
--       debugRenderPhaseSideEffectsForStrictMode and
--       workInProgress.mode & StrictMode
--     )
--       disableLogs()
--       try {
--         nextChildren = renderWithHooks(
--           current,
--           workInProgress,
--           render,
--           nextProps,
--           data,
--           renderLanes,
--         )
--       } finally {
--         reenableLogs()
--       end
--     end
--     setIsRendering(false)
--   else
--     nextChildren = renderWithHooks(
--       current,
--       workInProgress,
--       render,
--       nextProps,
--       data,
--       renderLanes,
--     )
--   end

--   if current ~= nil and !didReceiveUpdate)
--     bailoutHooks(current, workInProgress, renderLanes)
--     return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
--   end

--   -- React DevTools reads this flag.
--   workInProgress.flags |= PerformedWork
--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

-- ROBLOX FIXME: type refinement
-- local function updateClassComponent(
--   current: Fiber | nil,
--   ...
-- )
local function updateClassComponent(
	current: any,
	workInProgress: Fiber,
	Component: any,
	nextProps: any,
	renderLanes: Lanes
)
	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if workInProgress.type ~= workInProgress.elementType then
			-- Lazy component props can't be validated in createElement
			-- because they're only guaranteed to be resolved here.
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			local innerPropTypes = Component.propTypes
			local validateProps = Component.validateProps
			if innerPropTypes or validateProps then
				checkPropTypes(
					innerPropTypes,
					validateProps,
					nextProps, -- Resolved props
					"prop",
					getComponentName(Component)
				)
			end
		end
	end

	-- Push context providers early to prevent context stack mismatches.
	-- During mounting we don't know the child context yet as the instance doesn't exist.
	-- We will invalidate the child context in finishClassComponent() right after rendering.
	local hasContext
	if isLegacyContextProvider(Component) then
		hasContext = true
		pushLegacyContextProvider(workInProgress)
	else
		hasContext = false
	end
	-- ROBLOX deviation: pass in function to break cyclic require dependency
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)

	local instance = workInProgress.stateNode
	local shouldUpdate
	if instance == nil then
		if current ~= nil then
			-- A class component without an instance only mounts if it suspended
			-- inside a non-concurrent tree, in an inconsistent state. We want to
			-- treat it like a new mount, even though an empty version of it already
			-- committed. Disconnect the alternate pointers.
			current.alternate = nil
			workInProgress.alternate = nil
			-- Since this is conceptually a new fiber, schedule a Placement effect
			workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
		end
		-- In the initial pass we might need to construct the instance.
		constructClassInstance(workInProgress, Component, nextProps)
		mountClassInstance(workInProgress, Component, nextProps, renderLanes)
		shouldUpdate = true
	elseif current == nil then
		-- In a resume, we'll already have an instance we can reuse.
		shouldUpdate =
			resumeMountClassInstance(workInProgress, Component, nextProps, renderLanes)
	else
		shouldUpdate = updateClassInstance(
			current,
			workInProgress,
			Component,
			nextProps,
			renderLanes
		)
	end
	local nextUnitOfWork = finishClassComponent(
		current,
		workInProgress,
		Component,
		shouldUpdate,
		hasContext,
		renderLanes
	)
	if __DEV__ then
		local inst = workInProgress.stateNode
		if shouldUpdate and inst.props ~= nextProps then
			if not exports.didWarnAboutReassigningProps then
				console.error(
					"It looks like %s is reassigning its own `this.props` while rendering. "
						.. "This is not supported and can lead to confusing bugs.",
					getComponentName(workInProgress.type) or "a component"
				)
			end
			exports.didWarnAboutReassigningProps = true
		end
	end
	return nextUnitOfWork
end

function finishClassComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	Component: any,
	shouldUpdate: boolean,
	hasContext: boolean,
	renderLanes: Lanes
)
	-- Refs should update even if shouldComponentUpdate returns false
	markRef(current, workInProgress)

	local didCaptureError = bit32.band(workInProgress.flags, DidCapture) ~= NoFlags

	if not shouldUpdate and not didCaptureError then
		-- Context providers should defer to sCU for rendering
		if hasContext then
			invalidateContextProvider(workInProgress, Component, false)
		end

		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end

	local instance = workInProgress.stateNode

	-- Rerender
	ReactCurrentOwner.current = workInProgress
	local nextChildren
	if
		didCaptureError
		and (
			Component.getDerivedStateFromError == nil
			or type(Component.getDerivedStateFromError) ~= "function"
		)
	then
		-- If we captured an error, but getDerivedStateFromError is not defined,
		-- unmount all the children. componentDidCatch will schedule an update to
		-- re-render a fallback. This is temporary until we migrate everyone to
		-- the new API.
		-- TODO: Warn in a future release.
		nextChildren = nil

		if enableProfilerTimer then
			stopProfilerTimerIfRunning(workInProgress)
		end
	else
		if __DEV__ then
			setIsRendering(true)
			-- deviation: Call with ':' instead of '.' so that render can access self
			nextChildren = instance:render()
			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				-- deviation: Pass instance so that render can access self
				local ok, result = xpcall(instance.render, describeError, instance)
				-- finally
				reenableLogs()
				if not ok then
					error(result)
				end
			end
			setIsRendering(false)
		else
			-- deviation: Call with ':' instead of '.' so that render can access self
			nextChildren = instance:render()
		end
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	if current ~= nil and didCaptureError then
		-- If we're recovering from an error, reconcile without reusing any of
		-- the existing children. Conceptually, the normal children and the children
		-- that are shown on error are two different sets, so we shouldn't reuse
		-- normal children even if their identities match.
		forceUnmountCurrentAndReconcile(
			current :: Fiber,
			workInProgress,
			nextChildren,
			renderLanes
		)
	else
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	end

	-- Memoize state using the values we just used to render.
	-- TODO: Restructure so we never read values from the instance.
	workInProgress.memoizedState = instance.state

	-- The context might have changed so we need to recalculate it.
	if hasContext then
		invalidateContextProvider(workInProgress, Component, true)
	end

	return workInProgress.child
end

local function pushHostRootContext(workInProgress)
	-- FIXME (roblox): type refinement '(workInProgress.stateNode: FiberRoot)'
	local root = workInProgress.stateNode
	if root.pendingContext then
		pushTopLevelContextObject(
			workInProgress,
			root.pendingContext,
			root.pendingContext ~= root.context
		)
	elseif root.context then
		-- Should always be set
		pushTopLevelContextObject(workInProgress, root.context, false)
	end
	pushHostContainer(workInProgress, root.containerInfo)
end

local function updateHostRoot(current, workInProgress, renderLanes)
	pushHostRootContext(workInProgress)
	local updateQueue = workInProgress.updateQueue
	invariant(
		current ~= nil and updateQueue ~= nil,
		"If the root does not have an updateQueue, we should have already "
			.. "bailed out. This error is likely caused by a bug in React. Please "
			.. "file an issue."
	)
	local nextProps = workInProgress.pendingProps
	local prevState = workInProgress.memoizedState
	local prevChildren
	if prevState ~= nil then
		prevChildren = prevState.element
	end
	cloneUpdateQueue(current, workInProgress)
	processUpdateQueue(workInProgress, nextProps, nil, renderLanes)
	local nextState = workInProgress.memoizedState
	-- Caution: React DevTools currently depends on this property
	-- being called "element".
	local nextChildren = nextState.element
	if nextChildren == prevChildren then
		resetHydrationState()
		return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
	end
	local root: FiberRoot = workInProgress.stateNode
	if root.hydrate and enterHydrationState(workInProgress) then
		-- If we don't have any current children this might be the first pass.
		-- We always try to hydrate. If this isn't a hydration pass there won't
		-- be any children to hydrate which is effectively the same thing as
		-- not hydrating.

		if supportsHydration then
			local mutableSourceEagerHydrationData = root.mutableSourceEagerHydrationData
			if mutableSourceEagerHydrationData ~= nil then
				for i = 1, #mutableSourceEagerHydrationData, 2 do
					-- FIXME (roblox): type refinement
					-- local mutableSource = ((mutableSourceEagerHydrationData[
					--   i
					-- ]: any): MutableSource<any>)
					local mutableSource = mutableSourceEagerHydrationData[i]
					local version = mutableSourceEagerHydrationData[i + 1]
					setWorkInProgressVersion(mutableSource, version)
				end
			end
		end

		local child = mountChildFibers(workInProgress, nil, nextChildren, renderLanes)
		workInProgress.child = child

		local node = child
		while node do
			-- Mark each child as hydrating. This is a fast path to know whether this
			-- tree is part of a hydrating tree. This is used to determine if a child
			-- node has fully mounted yet, and for scheduling event replaying.
			-- Conceptually this is similar to Placement in that a new subtree is
			-- inserted into the React tree here. It just happens to not need DOM
			-- mutations because it already exists.
			node.flags =
				bit32.bor(bit32.band(node.flags, bit32.bnot(Placement)), Hydrating)
			node = node.sibling
		end
	else
		-- Otherwise reset hydration state in case we aborted and resumed another
		-- root.
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
		resetHydrationState()
	end
	return workInProgress.child
end

-- FIXME (roblox): type refinement
-- local function updateHostComponent(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes
-- )
local function updateHostComponent(
	current: any,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	pushHostContext(workInProgress)

	if current == nil then
		tryToClaimNextHydratableInstance(workInProgress)
	end

	local type_ = workInProgress.type
	local nextProps = workInProgress.pendingProps
	local prevProps
	if current ~= nil then
		prevProps = current.memoizedProps
	end

	local nextChildren = nextProps.children
	local isDirectTextChild = shouldSetTextContent(type_, nextProps)

	if isDirectTextChild then
		-- We special case a direct text child of a host node. This is a common
		-- case. We won't handle it as a reified child. We will instead handle
		-- this in the host environment that also has access to this prop. That
		-- avoids allocating another HostText fiber and traversing it.
		nextChildren = nil
	elseif prevProps ~= nil and shouldSetTextContent(type_, prevProps) then
		-- If we're switching from a direct text child to a normal child, or to
		-- empty, we need to schedule the text content to be reset.
		workInProgress.flags = bit32.bor(workInProgress.flags, ContentReset)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)

	markRef(current, workInProgress)
	reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	return workInProgress.child
end

local function updateHostText(current, workInProgress)
	if current == nil then
		tryToClaimNextHydratableInstance(workInProgress)
	end
	-- Nothing to do here. This is terminal. We'll do the completion step
	-- immediately after.
	return nil
end

local function mountLazyComponent(
	_current,
	workInProgress,
	elementType,
	updateLanes,
	renderLanes
)
	if _current ~= nil then
		-- A lazy component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		_current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	local props = workInProgress.pendingProps
	local lazyComponent: LazyComponentType<any, any> = elementType
	local payload = lazyComponent._payload
	local init = lazyComponent._init
	local Component = init(payload)
	-- Store the unwrapped component in the type.
	workInProgress.type = Component
	workInProgress.tag = resolveLazyComponentTag(Component)
	local resolvedTag = workInProgress.tag
	local resolvedProps = resolveDefaultProps(Component, props)
	local child
	if resolvedTag == FunctionComponent then
		if __DEV__ then
			validateFunctionComponentInDev(workInProgress, Component)
			Component = resolveFunctionForHotReloading(Component)
			workInProgress.type = Component
		end
		child = updateFunctionComponent(
			nil,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
		return child
	elseif resolvedTag == ClassComponent then
		if __DEV__ then
			Component = resolveClassForHotReloading(Component)
			workInProgress.type = Component
		end
		child = updateClassComponent(
			nil,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
		return child
	elseif resolvedTag == ForwardRef then
		if __DEV__ then
			Component = resolveForwardRefForHotReloading(Component)
			workInProgress.type = Component
		end
		child =
			updateForwardRef(nil, workInProgress, Component, resolvedProps, renderLanes)
		return child
	elseif resolvedTag == MemoComponent then
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			if workInProgress.type ~= workInProgress.elementType then
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes = Component.propTypes
				local validateProps = Component.validateProps
				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						resolvedProps, -- Resolved for outer only
						"prop",
						getComponentName(Component)
					)
				end
			end
		end
		child = updateMemoComponent(
			nil,
			workInProgress,
			Component,
			resolveDefaultProps(Component.type, resolvedProps), -- The inner type can have defaults too
			updateLanes,
			renderLanes
		)
		return child
		-- elseif resolvedTag == Block then
		--   unimplemented("Blocks API")
		--   if enableBlocksAPI then
		--     -- TODO: Resolve for Hot Reloading.
		--     child = updateBlock(
		--       nil,
		--       workInProgress,
		--       Component,
		--       props,
		--       renderLanes,
		--     )
		--     return child
		--   end
		--   -- ROBLOX deviation: break
	end
	local hint = ""
	if __DEV__ then
		if
			Component ~= nil
			and type(Component) == "table"
			and Component["$$typeof"] == REACT_LAZY_TYPE
		then
			hint = " Did you wrap a component in React.lazy() more than once?"
		elseif type(Component) == "table" and Component["$$typeof"] == nil then
			hint = "\n" .. inspect(Component)
		end
	end
	-- This message intentionally doesn't mention ForwardRef or MemoComponent
	-- because the fact that it's a separate type of work is an
	-- implementation detail.
	invariant(
		false,
		"Element type is invalid. Received a promise that resolves to: %s. "
			.. "Lazy element type must resolve to a class or function.%s",
		tostring(Component),
		hint
	)
	-- ROBLOX deviation: add nil to satisfy Luau, which doesn't doesn't bubble up the unconditional error() inside invariant
	return nil
end

function mountIncompleteClassComponent(
	_current,
	workInProgress,
	Component,
	nextProps,
	renderLanes
)
	if _current ~= nil then
		-- An incomplete component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		_current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	-- Promote the fiber to a class and try rendering again.
	workInProgress.tag = ClassComponent

	-- The rest of this function is a fork of `updateClassComponent`

	-- Push context providers early to prevent context stack mismatches.
	-- During mounting we don't know the child context yet as the instance doesn't exist.
	-- We will invalidate the child context in finishClassComponent() right after rendering.
	local hasContext
	if isLegacyContextProvider(Component) then
		hasContext = true
		pushLegacyContextProvider(workInProgress)
	else
		hasContext = false
	end
	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)

	constructClassInstance(workInProgress, Component, nextProps)
	mountClassInstance(workInProgress, Component, nextProps, renderLanes)

	return finishClassComponent(
		nil,
		workInProgress,
		Component,
		true,
		hasContext,
		renderLanes
	)
end

local function mountIndeterminateComponent(
	current,
	workInProgress,
	Component,
	renderLanes
)
	if current ~= nil then
		-- An indeterminate component only mounts if it suspended inside a non-
		-- concurrent tree, in an inconsistent state. We want to treat it like
		-- a new mount, even though an empty version of it already committed.
		-- Disconnect the alternate pointers.
		current.alternate = nil
		workInProgress.alternate = nil
		-- Since this is conceptually a new fiber, schedule a Placement effect
		workInProgress.flags = bit32.bor(workInProgress.flags, Placement)
	end

	local props = workInProgress.pendingProps
	local context
	if not disableLegacyContext then
		local unmaskedContext = getUnmaskedContext(workInProgress, Component, false)
		context = getMaskedContext(workInProgress, unmaskedContext)
	end

	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	local value

	if __DEV__ then
		if
			-- deviation: Instead of checking for the prototype, see if Component is a
			-- table with a render function
			type(Component) == "table" and type(Component.render) == "function"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutBadClass[componentName] then
				console.error(
					"The <%s /> component appears to have a render method, but doesn't extend React.Component. "
						.. "This is likely to cause errors. Change %s to extend React.Component instead.",
					componentName,
					componentName
				)
				DidWarn.didWarnAboutBadClass[componentName] = true
			end
		end

		if bit32.band(workInProgress.mode, StrictMode) ~= 0 then
			ReactStrictModeWarnings.recordLegacyContextWarning(workInProgress)
		end

		setIsRendering(true)
		ReactCurrentOwner.current = workInProgress
		value =
			renderWithHooks(nil, workInProgress, Component, props, context, renderLanes)
		setIsRendering(false)
	else
		value =
			renderWithHooks(nil, workInProgress, Component, props, context, renderLanes)
	end
	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	-- ROBLOX deviation START: cache type(value)
	local typeofValue = type(value)
	-- ROBLOX deviation END

	if __DEV__ then
		-- Support for module components is deprecated and is removed behind a flag.
		-- Whether or not it would crash later, we want to show a good message in DEV first.
		if
			value ~= nil
			and typeofValue == "table"
			and type(value.render) == "function"
			and value["$$typeof"] == nil
		then
			local componentName = getComponentName(Component) or "Unknown"
			if not DidWarn.didWarnAboutModulePatternComponent[componentName] then
				console.error(
					"The <%s /> component appears to be a function component that returns a class instance. "
						.. "Change %s to a class that extends React.Component instead. ",
					-- ROBLOX deviation: Don't print JS-specific remediation advice
					-- "If you can't use a class try assigning the prototype on the function as a workaround. " ..
					-- "`%s.prototype = React.Component.prototype`. Don't use an arrow function since it " ..
					-- "cannot be called with `new` by React.",
					componentName,
					componentName
					-- componentName
				)
				DidWarn.didWarnAboutModulePatternComponent[componentName] = true
			end
		end
	end

	if
		-- Run these checks in production only if the flag is off.
		-- Eventually we'll delete this branch altogether.
		not disableModulePatternComponents
		and value ~= nil
		and typeofValue == "table"
		and type(value.render) == "function"
		and value["$$typeof"] == nil
	then
		if __DEV__ then
			local componentName = getComponentName(Component) or "Unknown"
			if not DidWarn.didWarnAboutModulePatternComponent[componentName] then
				console.error(
					"The <%s /> component appears to be a function component that returns a class instance. "
						.. "Change %s to a class that extends React.Component instead. "
						-- ROBLOX deviation: Don't print JS-specific remediation advice
						-- "If you can't use a class try assigning the prototype on the function as a workaround. " ..
						-- "`%s.prototype = React.Component.prototype`. Don't use an arrow function since it " ..
						-- "cannot be called with `new` by React.",
						.. componentName,
					componentName
					-- componentName
				)
				DidWarn.didWarnAboutModulePatternComponent[componentName] = true
			end
		end

		-- Proceed under the assumption that this is a class instance
		workInProgress.tag = ClassComponent

		-- Throw out any hooks that were used.
		workInProgress.memoizedState = nil
		workInProgress.updateQueue = nil

		-- Push context providers early to prevent context stack mismatches.
		-- During mounting we don't know the child context yet as the instance doesn't exist.
		-- We will invalidate the child context in finishClassComponent() right after rendering.
		local hasContext = false
		if isLegacyContextProvider(Component) then
			hasContext = true
			pushLegacyContextProvider(workInProgress)
		else
			hasContext = false
		end

		-- deviation: Lua doesn't need to coerce `T | null | undefined` to `T | null`
		workInProgress.memoizedState = value.state

		initializeUpdateQueue(workInProgress)

		-- ROBLOX deviation: don't access field on function
		local getDerivedStateFromProps
		if type(Component) ~= "function" then
			getDerivedStateFromProps = (Component :: React_Component<any, any>).getDerivedStateFromProps
		end
		if
			getDerivedStateFromProps ~= nil
			and type(getDerivedStateFromProps) == "function"
		then
			applyDerivedStateFromProps(
				workInProgress,
				Component,
				getDerivedStateFromProps,
				props
			)
		end

		adoptClassInstance(workInProgress, value)
		mountClassInstance(workInProgress, Component, props, renderLanes)
		return finishClassComponent(
			nil,
			workInProgress,
			Component,
			true,
			hasContext,
			renderLanes
		)
	else
		-- Proceed under the assumption that this is a function component
		workInProgress.tag = FunctionComponent
		if __DEV__ then
			if disableLegacyContext and Component.contextTypes then
				console.error(
					"%s uses the legacy contextTypes API which is no longer supported. "
						.. "Use React.createContext() with React.useContext() instead.",
					getComponentName(Component) or "Unknown"
				)
			end

			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				local ok, result = xpcall(
					renderWithHooks,
					describeError,
					nil,
					workInProgress,
					Component,
					props,
					context,
					renderLanes
				)
				-- finally
				reenableLogs()
				if ok then
					value = result
				else
					error(result)
				end
			end
		end
		reconcileChildren(nil, workInProgress, value, renderLanes)
		if __DEV__ then
			validateFunctionComponentInDev(workInProgress, Component)
		end
		return workInProgress.child
	end
end

function validateFunctionComponentInDev(workInProgress: Fiber, Component: any)
	if __DEV__ then
		-- ROBLOX deviation: Lua doesn't allow fields on functions, so this never happens
		-- if Component then
		--   if Component.childContextTypes then
		--     console.error(
		--       '%s(...): childContextTypes cannot be defined on a function component.',
		--       Component.displayName or Component.name or 'Component'
		--     )
		--   end
		-- end
		if workInProgress.ref ~= nil then
			local info = ""
			local ownerName = getCurrentFiberOwnerNameInDevOrNull()
			if ownerName then
				info ..= "\n\nCheck the render method of `" .. ownerName .. "`."
			end

			local warningKey = ownerName or workInProgress._debugID or ""
			local debugSource = workInProgress._debugSource
			if debugSource then
				warningKey = debugSource.fileName .. ":" .. debugSource.lineNumber
			end
			if not DidWarn.didWarnAboutFunctionRefs[warningKey] then
				DidWarn.didWarnAboutFunctionRefs[warningKey] = true
				console.error(
					"Function components cannot be given refs. "
						.. "Attempts to access this ref will fail. "
						.. "Did you mean to use React.forwardRef()?%s",
					info
				)
			end
		end

		if
			warnAboutDefaultPropsOnFunctionComponents
			-- ROBLOX deviation: functions can't have fields in Lua
			and type(Component) ~= "function"
			and Component.defaultProps ~= nil
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutDefaultPropsOnFunctionComponent[componentName] then
				console.error(
					"%s: Support for defaultProps will be removed from function components "
						-- ROBLOX deviation: Don't print JS-specific remediation advice
						.. "in a future major release.", -- Use JavaScript default parameters instead.',
					componentName
				)
				DidWarn.didWarnAboutDefaultPropsOnFunctionComponent[componentName] = true
			end
		end

		-- ROBLOX deviation: Lua functions can't have fields
		if
			type(Component) ~= "function"
			and Component.getDerivedStateFromProps ~= nil
			and type(Component.getDerivedStateFromProps) == "function"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if
				not DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent[componentName]
			then
				console.error(
					"%s: Function components do not support getDerivedStateFromProps.",
					componentName
				)
				DidWarn.didWarnAboutGetDerivedStateOnFunctionComponent[componentName] =
					true
			end
		end

		-- ROBLOX deviation: Lua functions can't have fields
		if
			type(Component) ~= "function"
			and Component.contextType ~= nil
			and type(Component.contextType) == "table"
		then
			local componentName = getComponentName(Component) or "Unknown"

			if not DidWarn.didWarnAboutContextTypeOnFunctionComponent[componentName] then
				console.error(
					"%s: Function components do not support contextType.",
					componentName
				)
				DidWarn.didWarnAboutContextTypeOnFunctionComponent[componentName] = true
			end
		end
	end
end

local SUSPENDED_MARKER: SuspenseState = {
	dehydrated = nil,
	retryLane = ReactFiberLane.NoLane,
}

local function mountSuspenseOffscreenState(renderLanes: Lanes): OffscreenState
	return {
		baseLanes = renderLanes,
	}
end

local function updateSuspenseOffscreenState(
	prevOffscreenState: OffscreenState,
	renderLanes: Lanes
): OffscreenState
	return {
		baseLanes = ReactFiberLane.mergeLanes(prevOffscreenState.baseLanes, renderLanes),
	}
end

-- TODO: Probably should inline this back
local function shouldRemainOnFallback(
	suspenseContext: SuspenseContext,
	current: nil | Fiber,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	-- If we're already showing a fallback, there are cases where we need to
	-- remain on that fallback regardless of whether the content has resolved.
	-- For example, SuspenseList coordinates when nested content appears.
	if current ~= nil then
		local suspenseState: SuspenseState = (current :: Fiber).memoizedState
		if suspenseState == nil then
			-- Currently showing content. Don't hide it, even if ForceSuspenseFallack
			-- is true. More precise name might be "ForceRemainSuspenseFallback".
			-- Note: This is a factoring smell. Can't remain on a fallback if there's
			-- no fallback to remain on.
			return false
		end
	end

	-- Not currently showing content. Consult the Suspense context.
	return hasSuspenseContext(suspenseContext, ForceSuspenseFallback)
end

local function getRemainingWorkInPrimaryTree(current: Fiber, renderLanes)
	-- TODO: Should not remove render lanes that were pinged during this render
	return ReactFiberLane.removeLanes(current.childLanes, renderLanes)
end

-- ROBLOX deviation: predeclare these methods to resolve method declaration ordering
local updateSuspensePrimaryChildren
local mountDehydratedSuspenseComponent
local mountSuspensePrimaryChildren
local updateSuspenseFallbackChildren
local updateDehydratedSuspenseComponent

local function updateSuspenseComponent(current, workInProgress, renderLanes)
	local nextProps = workInProgress.pendingProps

	-- This is used by DevTools to force a boundary to suspend.
	if __DEV__ then
		if shouldSuspend(workInProgress) then
			workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
		end
	end

	local suspenseContext: SuspenseContext = suspenseStackCursor.current

	local showFallback = false
	local didSuspend = bit32.band(workInProgress.flags, DidCapture) ~= NoFlags

	if
		didSuspend
		or shouldRemainOnFallback(suspenseContext, current, workInProgress, renderLanes)
	then
		-- Something in this boundary's subtree already suspended. Switch to
		-- rendering the fallback children.
		showFallback = true
		workInProgress.flags = bit32.band(workInProgress.flags, bit32.bnot(DidCapture))
	else
		-- Attempting the main content
		if current == nil or current.memoizedState ~= nil then
			-- This is a new mount or this boundary is already showing a fallback state.
			-- Mark this subtree context as having at least one invisible parent that could
			-- handle the fallback state.
			-- Boundaries without fallbacks or should be avoided are not considered since
			-- they cannot handle preferred fallback states.
			if
				nextProps.fallback ~= nil
				and nextProps.unstable_avoidThisFallback ~= true
			then
				suspenseContext = addSubtreeSuspenseContext(
					suspenseContext,
					InvisibleParentSuspenseContext
				)
			end
		end
	end

	suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)

	pushSuspenseContext(workInProgress, suspenseContext)

	-- OK, the next part is confusing. We're about to reconcile the Suspense
	-- boundary's children. This involves some custom reconcilation logic. Two
	-- main reasons this is so complicated.
	--
	-- First, Legacy Mode has different semantics for backwards compatibility. The
	-- primary tree will commit in an inconsistent state, so when we do the
	-- second pass to render the fallback, we do some exceedingly, uh, clever
	-- hacks to make that not totally break. Like transferring effects and
	-- deletions from hidden tree. In Concurrent Mode, it's much simpler,
	-- because we bailout on the primary tree completely and leave it in its old
	-- state, no effects. Same as what we do for Offscreen (except that
	-- Offscreen doesn't have the first render pass).
	--
	-- Second is hydration. During hydration, the Suspense fiber has a slightly
	-- different layout, where the child points to a dehydrated fragment, which
	-- contains the DOM rendered by the server.
	--
	-- Third, even if you set all that aside, Suspense is like error boundaries in
	-- that we first we try to render one tree, and if that fails, we render again
	-- and switch to a different tree. Like a try/catch block. So we have to track
	-- which branch we're currently rendering. Ideally we would model this using
	-- a stack.
	if current == nil then
		-- Initial mount
		-- If we're currently hydrating, try to hydrate this boundary.
		-- But only if this has a fallback.
		if nextProps.fallback ~= nil then
			tryToClaimNextHydratableInstance(workInProgress)
			-- This could've been a dehydrated suspense component.
			if enableSuspenseServerRenderer then
				local suspenseState: nil | SuspenseState = workInProgress.memoizedState
				if suspenseState ~= nil then
					local dehydrated = (suspenseState :: SuspenseState).dehydrated
					if dehydrated ~= nil then
						return mountDehydratedSuspenseComponent(
							workInProgress,
							dehydrated,
							renderLanes
						)
					end
				end
			end
		end

		local nextPrimaryChildren = nextProps.children
		local nextFallbackChildren = nextProps.fallback
		if showFallback then
			local fallbackFragment = mountSuspenseFallbackChildren(
				workInProgress,
				nextPrimaryChildren,
				nextFallbackChildren,
				renderLanes
			)
			local primaryChildFragment: Fiber = workInProgress.child :: any
			primaryChildFragment.memoizedState = mountSuspenseOffscreenState(renderLanes)
			workInProgress.memoizedState = SUSPENDED_MARKER
			return fallbackFragment
		elseif
			nextProps.unstable_expectedLoadTime ~= nil
			and type(nextProps.unstable_expectedLoadTime) == "number"
		then
			-- This is a CPU-bound tree. Skip this tree and show a placeholder to
			-- unblock the surrounding content. Then immediately retry after the
			-- initial commit.
			local fallbackFragment = mountSuspenseFallbackChildren(
				workInProgress,
				nextPrimaryChildren,
				nextFallbackChildren,
				renderLanes
			)
			local primaryChildFragment: Fiber = workInProgress.child :: any
			primaryChildFragment.memoizedState = mountSuspenseOffscreenState(renderLanes)
			workInProgress.memoizedState = SUSPENDED_MARKER

			-- Since nothing actually suspended, there will nothing to ping this to
			-- get it started back up to attempt the next item. While in terms of
			-- priority this work has the same priority as this current render, it's
			-- not part of the same transition once the transition has committed. If
			-- it's sync, we still want to yield so that it can be painted.
			-- Conceptually, this is really the same as pinging. We can use any
			-- RetryLane even if it's the one currently rendering since we're leaving
			-- it behind on this node.
			workInProgress.lanes = ReactFiberLane.SomeRetryLane
			if enableSchedulerTracing then
				markSpawnedWork(ReactFiberLane.SomeRetryLane)
			end
			return fallbackFragment
		else
			return mountSuspensePrimaryChildren(
				workInProgress,
				nextPrimaryChildren,
				renderLanes
			)
		end
	else
		-- This is an update.

		-- If the current fiber has a SuspenseState, that means it's already showing
		-- a fallback.
		local prevState: nil | SuspenseState = current.memoizedState
		if prevState ~= nil then
			-- The current tree is already showing a fallback

			-- Special path for hydration
			if enableSuspenseServerRenderer then
				-- ROBLOX FIXME: remove :: when Luau understands ~= nil
				local dehydrated = (prevState :: SuspenseState).dehydrated

				if dehydrated ~= nil then
					if not didSuspend then
						return updateDehydratedSuspenseComponent(
							current,
							workInProgress,
							dehydrated,
							prevState,
							renderLanes
						)
					elseif workInProgress.memoizedState ~= nil then
						-- Something suspended and we should still be in dehydrated mode.
						-- Leave the existing child in place.
						workInProgress.child = current.child
						-- The dehydrated completion pass expects this flag to be there
						-- but the normal suspense pass doesn't.
						workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
						return nil
					else
						-- Suspended but we should no longer be in dehydrated mode.
						-- Therefore we now have to render the fallback.
						local nextPrimaryChildren = nextProps.children
						local nextFallbackChildren = nextProps.fallback
						local fallbackChildFragment =
							mountSuspenseFallbackAfterRetryWithoutHydrating(
								current,
								workInProgress,
								nextPrimaryChildren,
								nextFallbackChildren,
								renderLanes
							)
						local primaryChildFragment: Fiber = workInProgress.child :: any
						primaryChildFragment.memoizedState =
							mountSuspenseOffscreenState(renderLanes)
						workInProgress.memoizedState = SUSPENDED_MARKER
						return fallbackChildFragment
					end
				end
			end

			if showFallback then
				local nextFallbackChildren = nextProps.fallback
				local nextPrimaryChildren = nextProps.children
				local fallbackChildFragment = updateSuspenseFallbackChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					nextFallbackChildren,
					renderLanes
				)
				local primaryChildFragment: Fiber = workInProgress.child :: any
				local prevOffscreenState: OffscreenState | nil = (current.child :: any).memoizedState

				-- ROBLOX deviation: if/else in place of ternary
				if prevOffscreenState == nil then
					primaryChildFragment.memoizedState =
						mountSuspenseOffscreenState(renderLanes)
				else
					-- ROBLOX FIXME: remove :: when Luau understands ~= nil
					primaryChildFragment.memoizedState = updateSuspenseOffscreenState(
						prevOffscreenState :: OffscreenState,
						renderLanes
					)
				end

				primaryChildFragment.childLanes =
					getRemainingWorkInPrimaryTree(current, renderLanes)
				workInProgress.memoizedState = SUSPENDED_MARKER
				return fallbackChildFragment
			else
				local nextPrimaryChildren = nextProps.children
				local primaryChildFragment = updateSuspensePrimaryChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					renderLanes
				)
				workInProgress.memoizedState = nil
				return primaryChildFragment
			end
		else
			-- The current tree is not already showing a fallback.
			if showFallback then
				-- Timed out.
				local nextFallbackChildren = nextProps.fallback
				local nextPrimaryChildren = nextProps.children
				local fallbackChildFragment = updateSuspenseFallbackChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					nextFallbackChildren,
					renderLanes
				)
				local primaryChildFragment: Fiber = workInProgress.child :: any
				local prevOffscreenState: OffscreenState | nil = (current.child :: any).memoizedState

				-- ROBLOX deviation: if/else in place of ternary
				if prevOffscreenState == nil then
					primaryChildFragment.memoizedState =
						mountSuspenseOffscreenState(renderLanes)
				else
					-- ROBLOX FIXME: remove :: once Luau understands nil check
					primaryChildFragment.memoizedState = updateSuspenseOffscreenState(
						prevOffscreenState :: OffscreenState,
						renderLanes
					)
				end

				primaryChildFragment.childLanes =
					getRemainingWorkInPrimaryTree(current, renderLanes)
				-- Skip the primary children, and continue working on the
				-- fallback children.
				workInProgress.memoizedState = SUSPENDED_MARKER
				return fallbackChildFragment
			else
				-- Still haven't timed out. Continue rendering the children, like we
				-- normally do.
				local nextPrimaryChildren = nextProps.children
				local primaryChildFragment = updateSuspensePrimaryChildren(
					current,
					workInProgress,
					nextPrimaryChildren,
					renderLanes
				)
				workInProgress.memoizedState = nil
				return primaryChildFragment
			end
		end
	end
end

function mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
	local mode = workInProgress.mode
	local primaryChildProps: OffscreenProps = {
		mode = "visible",
		children = primaryChildren,
	}
	local primaryChildFragment =
		createFiberFromOffscreen(primaryChildProps, mode, renderLanes, nil)
	primaryChildFragment.return_ = workInProgress
	workInProgress.child = primaryChildFragment
	return primaryChildFragment
end

function mountSuspenseFallbackChildren(
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local progressedPrimaryFragment: Fiber | nil = workInProgress.child

	local primaryChildProps: OffscreenProps = {
		mode = "hidden",
		children = primaryChildren,
	}

	local primaryChildFragment
	local fallbackChildFragment
	if bit32.band(mode, BlockingMode) == NoMode and progressedPrimaryFragment ~= nil then
		-- In legacy mode, we commit the primary tree as if it successfully
		-- completed, even though it's in an inconsistent state.
		primaryChildFragment = progressedPrimaryFragment
		primaryChildFragment.childLanes = ReactFiberLane.NoLanes
		primaryChildFragment.pendingProps = primaryChildProps

		if enableProfilerTimer and bit32.band(workInProgress.mode, ProfileMode) ~= 0 then
			-- Reset the durations from the first pass so they aren't included in the
			-- final amounts. This seems counterintuitive, since we're intentionally
			-- not measuring part of the render phase, but this makes it match what we
			-- do in Concurrent Mode.
			primaryChildFragment.actualDuration = 0
			primaryChildFragment.actualStartTime = -1
			primaryChildFragment.selfBaseDuration = 0
			primaryChildFragment.treeBaseDuration = 0
		end

		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	else
		primaryChildFragment =
			createFiberFromOffscreen(primaryChildProps, mode, ReactFiberLane.NoLanes, nil)
		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	end

	primaryChildFragment.return_ = workInProgress
	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment
	return fallbackChildFragment
end

local function createWorkInProgressOffscreenFiber(
	current: Fiber,
	offscreenProps: OffscreenProps
)
	-- The props argument to `createWorkInProgress` is `any` typed, so we use this
	-- wrapper function to constrain it.
	return createWorkInProgress(current, offscreenProps)
end

function updateSuspensePrimaryChildren(
	current,
	workInProgress,
	primaryChildren,
	renderLanes
)
	local currentPrimaryChildFragment: Fiber = current.child :: any
	local currentFallbackChildFragment: Fiber | nil = currentPrimaryChildFragment.sibling

	local primaryChildFragment =
		createWorkInProgressOffscreenFiber(currentPrimaryChildFragment, {
			mode = "visible",
			children = primaryChildren,
		})
	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		primaryChildFragment.lanes = renderLanes
	end
	primaryChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = nil
	if currentFallbackChildFragment ~= nil then
		-- Delete the fallback child fragment
		local deletions = workInProgress.deletions
		if deletions == nil then
			workInProgress.deletions = { currentFallbackChildFragment }
			-- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
			workInProgress.flags = bit32.bor(workInProgress.flags, Deletion)
		else
			table.insert(deletions, currentFallbackChildFragment)
		end
	end

	workInProgress.child = primaryChildFragment
	return primaryChildFragment
end

function updateSuspenseFallbackChildren(
	current,
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local currentPrimaryChildFragment: Fiber = current.child :: any
	local currentFallbackChildFragment: Fiber | nil = currentPrimaryChildFragment.sibling

	local primaryChildProps: OffscreenProps = {
		mode = "hidden",
		children = primaryChildren,
	}

	local primaryChildFragment
	if
		-- In legacy mode, we commit the primary tree as if it successfully
		-- completed, even though it's in an inconsistent state.
		bit32.band(mode, BlockingMode) == NoMode
		-- Make sure we're on the second pass, i.e. the primary child fragment was
		-- already cloned. In legacy mode, the only case where this isn't true is
		-- when DevTools forces us to display a fallback; we skip the first render
		-- pass entirely and go straight to rendering the fallback. (In Concurrent
		-- Mode, SuspenseList can also trigger this scenario, but this is a legacy-
		-- only codepath.)
		and workInProgress.child ~= currentPrimaryChildFragment
	then
		local progressedPrimaryFragment: Fiber = workInProgress.child
		primaryChildFragment = progressedPrimaryFragment
		primaryChildFragment.childLanes = ReactFiberLane.NoLanes
		primaryChildFragment.pendingProps = primaryChildProps

		if enableProfilerTimer and bit32.band(workInProgress.mode, ProfileMode) ~= 0 then
			-- Reset the durations from the first pass so they aren't included in the
			-- final amounts. This seems counterintuitive, since we're intentionally
			-- not measuring part of the render phase, but this makes it match what we
			-- do in Concurrent Mode.
			primaryChildFragment.actualDuration = 0
			primaryChildFragment.actualStartTime = -1
			primaryChildFragment.selfBaseDuration =
				currentPrimaryChildFragment.selfBaseDuration
			primaryChildFragment.treeBaseDuration =
				currentPrimaryChildFragment.treeBaseDuration
		end

		-- The fallback fiber was added as a deletion effect during the first pass.
		-- However, since we're going to remain on the fallback, we no longer want
		-- to delete it.
		workInProgress.deletions = nil
	else
		primaryChildFragment = createWorkInProgressOffscreenFiber(
			currentPrimaryChildFragment,
			primaryChildProps
		)

		-- Since we're reusing a current tree, we need to reuse the flags, too.
		-- (We don't do this in legacy mode, because in legacy mode we don't re-use
		-- the current tree; see previous branch.)
		primaryChildFragment.subtreeFlags =
			bit32.band(currentPrimaryChildFragment.subtreeFlags, StaticMask)
	end
	local fallbackChildFragment
	if currentFallbackChildFragment ~= nil then
		fallbackChildFragment =
			createWorkInProgress(currentFallbackChildFragment, fallbackChildren)
	else
		fallbackChildFragment =
			createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
		-- Needs a placement effect because the parent (the Suspense boundary) already
		-- mounted but this is a new fiber.
		fallbackChildFragment.flags = bit32.bor(fallbackChildFragment.flags, Placement)
	end

	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment

	return fallbackChildFragment
end

local function retrySuspenseComponentWithoutHydrating(
	current: Fiber,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	-- This will add the old fiber to the deletion list
	reconcileChildFibers(workInProgress, current.child, nil, renderLanes)

	-- We're now not suspended nor dehydrated.
	local nextProps = workInProgress.pendingProps
	local primaryChildren = nextProps.children
	local primaryChildFragment =
		mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
	-- Needs a placement effect because the parent (the Suspense boundary) already
	-- mounted but this is a new fiber.
	primaryChildFragment.flags = bit32.bor(primaryChildFragment.flags, Placement)
	workInProgress.memoizedState = nil

	return primaryChildFragment
end

function mountSuspenseFallbackAfterRetryWithoutHydrating(
	current,
	workInProgress,
	primaryChildren,
	fallbackChildren,
	renderLanes
)
	local mode = workInProgress.mode
	local primaryChildFragment =
		createFiberFromOffscreen(primaryChildren, mode, ReactFiberLane.NoLanes, nil)
	local fallbackChildFragment =
		createFiberFromFragment(fallbackChildren, mode, renderLanes, nil)
	-- Needs a placement effect because the parent (the Suspense
	-- boundary) already mounted but this is a new fiber.
	fallbackChildFragment.flags = bit32.bor(fallbackChildFragment.flags, Placement)

	primaryChildFragment.return_ = workInProgress
	fallbackChildFragment.return_ = workInProgress
	primaryChildFragment.sibling = fallbackChildFragment
	workInProgress.child = primaryChildFragment

	if bit32.band(workInProgress.mode, BlockingMode) ~= NoMode then
		-- We will have dropped the effect list which contains the
		-- deletion. We need to reconcile to delete the current child.
		reconcileChildFibers(workInProgress, current.child, nil, renderLanes)
	end

	return fallbackChildFragment
end

function mountDehydratedSuspenseComponent(
	workInProgress: Fiber,
	suspenseInstance: SuspenseInstance,
	renderLanes: Lanes
): nil | Fiber
	-- During the first pass, we'll bail out and not drill into the children.
	-- Instead, we'll leave the content in place and try to hydrate it later.
	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		if __DEV__ then
			console.error(
				"Cannot hydrate Suspense in legacy mode. Switch from"
					.. "ReactDOM.hydrate(element, container) to "
					.. "ReactDOM.createBlockingRoot(container, { hydrate: true })"
					.. ".render(element) or remove the Suspense components"
					.. "the server rendered components."
			)
		end
		workInProgress.lanes = ReactFiberLane.laneToLanes(ReactFiberLane.SyncLane)
	elseif isSuspenseInstanceFallback(suspenseInstance) then
		-- This is a client-only boundary. Since we won't get any content from the server
		-- for this, we need to schedule that at a higher priority based on when it would
		-- have timed out. In theory we could render it in this pass but it would have the
		-- wrong priority associated with it and will prevent hydration of parent path.
		-- Instead, we'll leave work left on it to render it in a separate commit.

		-- TODO This time should be the time at which the server rendered response that is
		-- a parent to this boundary was displayed. However, since we currently don't have
		-- a protocol to transfer that time, we'll just estimate it by using the current
		-- time. This will mean that Suspense timeouts are slightly shifted to later than
		-- they should be.
		-- Schedule a normal pri update to render this content.
		if enableSchedulerTracing then
			markSpawnedWork(ReactFiberLane.DefaultHydrationLane)
		end
		workInProgress.lanes =
			ReactFiberLane.laneToLanes(ReactFiberLane.DefaultHydrationLane)
	else
		-- We'll continue hydrating the rest at offscreen priority since we'll already
		-- be showing the right content coming from the server, it is no rush.
		workInProgress.lanes = ReactFiberLane.laneToLanes(ReactFiberLane.OffscreenLane)
		if enableSchedulerTracing then
			markSpawnedWork(ReactFiberLane.OffscreenLane)
		end
	end
	return nil
end

function updateDehydratedSuspenseComponent(
	current: Fiber,
	workInProgress: Fiber,
	suspenseInstance: SuspenseInstance,
	suspenseState: SuspenseState,
	renderLanes: Lanes
): nil | Fiber
	-- We should never be hydrating at this point because it is the first pass,
	-- but after we've already committed once.
	warnIfHydrating()

	if bit32.band(getExecutionContext(), RetryAfterError) ~= NoContext then
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end

	if bit32.band(workInProgress.mode, BlockingMode) == NoMode then
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end

	if isSuspenseInstanceFallback(suspenseInstance) then
		-- This boundary is in a permanent fallback state. In this case, we'll never
		-- get an update and we'll never be able to hydrate the final content. Let's just try the
		-- client side render instead.
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	end
	-- We use lanes to indicate that a child might depend on context, so if
	-- any context has changed, we need to treat is as if the input might have changed.
	local hasContextChanged =
		ReactFiberLane.includesSomeLane(renderLanes, current.childLanes)
	if didReceiveUpdate or hasContextChanged then
		-- This boundary has changed since the first render. This means that we are now unable to
		-- hydrate it. We might still be able to hydrate it using a higher priority lane.
		local root = getWorkInProgressRoot()
		if root ~= nil then
			local attemptHydrationAtLane =
				ReactFiberLane.getBumpedLaneForHydration(root, renderLanes)
			if
				attemptHydrationAtLane ~= ReactFiberLane.NoLane
				and attemptHydrationAtLane ~= suspenseState.retryLane
			then
				-- Intentionally mutating since this render will get interrupted. This
				-- is one of the very rare times where we mutate the current tree
				-- during the render phase.
				suspenseState.retryLane = attemptHydrationAtLane
				-- TODO: Ideally this would inherit the event time of the current render
				local eventTime = ReactFiberLane.NoTimestamp
				scheduleUpdateOnFiber(current, attemptHydrationAtLane, eventTime)
			else
				-- We have already tried to ping at a higher priority than we're rendering with
				-- so if we got here, we must have failed to hydrate at those levels. We must
				-- now give up. Instead, we're going to delete the whole subtree and instead inject
				-- a new real Suspense boundary to take its place, which may render content
				-- or fallback. This might suspend for a while and if it does we might still have
				-- an opportunity to hydrate before this pass commits.
			end
		end

		-- If we have scheduled higher pri work above, this will probably just abort the render
		-- since we now have higher priority work, but in case it doesn't, we need to prepare to
		-- render something, if we time out. Even if that requires us to delete everything and
		-- skip hydration.
		-- Delay having to do this as long as the suspense timeout allows us.
		renderDidSuspendDelayIfPossible()
		return retrySuspenseComponentWithoutHydrating(
			current,
			workInProgress,
			renderLanes
		)
	elseif isSuspenseInstancePending(suspenseInstance) then
		-- This component is still pending more data from the server, so we can't hydrate its
		-- content. We treat it as if this component suspended itself. It might seem as if
		-- we could just try to render it client-side instead. However, this will perform a
		-- lot of unnecessary work and is unlikely to complete since it often will suspend
		-- on missing data anyway. Additionally, the server might be able to render more
		-- than we can on the client yet. In that case we'd end up with more fallback states
		-- on the client than if we just leave it alone. If the server times out or errors
		-- these should update this boundary to the permanent Fallback state instead.
		-- Mark it as having captured (i.e. suspended).
		workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
		-- Leave the child in place. I.e. the dehydrated fragment.
		workInProgress.child = current.child

		-- Register a callback to retry this boundary once the server has sent the result.
		-- ROBLOX deviation: wrapper function in place of bind
		local retry = function()
			return retryDehydratedSuspenseBoundary(current)
		end

		if enableSchedulerTracing then
			if Schedule_tracing_wrap == nil then
				Schedule_tracing_wrap = require(Packages.Scheduler).tracing.unstable_wrap
			end
			retry = Schedule_tracing_wrap(retry)
		end

		registerSuspenseInstanceRetry(suspenseInstance, retry)
		return nil
	else
		-- This is the first attempt.
		reenterHydrationStateFromDehydratedSuspenseInstance(
			workInProgress,
			suspenseInstance
		)
		local nextProps = workInProgress.pendingProps
		local primaryChildren = nextProps.children
		local primaryChildFragment =
			mountSuspensePrimaryChildren(workInProgress, primaryChildren, renderLanes)
		-- Mark the children as hydrating. This is a fast path to know whether this
		-- tree is part of a hydrating tree. This is used to determine if a child
		-- node has fully mounted yet, and for scheduling event replaying.
		-- Conceptually this is similar to Placement in that a new subtree is
		-- inserted into the React tree here. It just happens to not need DOM
		-- mutations because it already exists.
		primaryChildFragment.flags = bit32.bor(primaryChildFragment.flags, Hydrating)
		return primaryChildFragment
	end
end

-- function scheduleWorkOnFiber(fiber: Fiber, renderLanes: Lanes)
--   fiber.lanes = ReactFiberLane.mergeLanes(fiber.lanes, renderLanes)
--   local alternate = fiber.alternate
--   if alternate ~= nil)
--     alternate.lanes = ReactFiberLane.mergeLanes(alternate.lanes, renderLanes)
--   end
--   scheduleWorkOnParentPath(fiber.return, renderLanes)
-- end

-- function propagateSuspenseContextChange(
--   workInProgress: Fiber,
--   firstChild: nil | Fiber,
--   renderLanes: Lanes,
-- ): void {
--   -- Mark any Suspense boundaries with fallbacks as having work to do.
--   -- If they were previously forced into fallbacks, they may now be able
--   -- to unblock.
--   local node = firstChild
--   while (node ~= nil)
--     if node.tag == SuspenseComponent)
--       local state: SuspenseState | nil = node.memoizedState
--       if state ~= nil)
--         scheduleWorkOnFiber(node, renderLanes)
--       end
--     } elseif node.tag == SuspenseListComponent)
--       -- If the tail is hidden there might not be an Suspense boundaries
--       -- to schedule work on. In this case we have to schedule it on the
--       -- list itself.
--       -- We don't have to traverse to the children of the list since
--       -- the list will propagate the change when it rerenders.
--       scheduleWorkOnFiber(node, renderLanes)
--     } elseif node.child ~= nil)
--       node.child.return = node
--       node = node.child
--       continue
--     end
--     if node == workInProgress)
--       return
--     end
--     while (node.sibling == nil)
--       if node.return == nil or node.return == workInProgress)
--         return
--       end
--       node = node.return
--     end
--     node.sibling.return = node.return
--     node = node.sibling
--   end
-- end

-- function findLastContentRow(firstChild: nil | Fiber): nil | Fiber {
--   -- This is going to find the last row among these children that is already
--   -- showing content on the screen, as opposed to being in fallback state or
--   -- new. If a row has multiple Suspense boundaries, any of them being in the
--   -- fallback state, counts as the whole row being in a fallback state.
--   -- Note that the "rows" will be workInProgress, but any nested children
--   -- will still be current since we haven't rendered them yet. The mounted
--   -- order may not be the same as the new order. We use the new order.
--   local row = firstChild
--   local lastContentRow: nil | Fiber = nil
--   while (row ~= nil)
--     local currentRow = row.alternate
--     -- New rows can't be content rows.
--     if currentRow ~= nil and findFirstSuspended(currentRow) == nil)
--       lastContentRow = row
--     end
--     row = row.sibling
--   end
--   return lastContentRow
-- end

-- type SuspenseListRevealOrder = 'forwards' | 'backwards' | 'together' | void

-- function validateRevealOrder(revealOrder: SuspenseListRevealOrder)
--   if  __DEV__ then
--     if
--       revealOrder ~= undefined and
--       revealOrder ~= 'forwards' and
--       revealOrder ~= 'backwards' and
--       revealOrder ~= 'together' and
--       !didWarnAboutRevealOrder[revealOrder]
--     )
--       didWarnAboutRevealOrder[revealOrder] = true
--       if typeof revealOrder == 'string')
--         switch (revealOrder.toLowerCase())
--           case 'together':
--           case 'forwards':
--           case 'backwards': {
--             console.error(
--               '"%s" is not a valid value for revealOrder on <SuspenseList />. ' +
--                 'Use lowercase "%s" instead.',
--               revealOrder,
--               revealOrder.toLowerCase(),
--             )
--             break
--           end
--           case 'forward':
--           case 'backward': {
--             console.error(
--               '"%s" is not a valid value for revealOrder on <SuspenseList />. ' +
--                 'React uses the -s suffix in the spelling. Use "%ss" instead.',
--               revealOrder,
--               revealOrder.toLowerCase(),
--             )
--             break
--           end
--           default:
--             console.error(
--               '"%s" is not a supported revealOrder on <SuspenseList />. ' +
--                 'Did you mean "together", "forwards" or "backwards"?',
--               revealOrder,
--             )
--             break
--         end
--       else
--         console.error(
--           '%s is not a supported value for revealOrder on <SuspenseList />. ' +
--             'Did you mean "together", "forwards" or "backwards"?',
--           revealOrder,
--         )
--       end
--     end
--   end
-- end

-- function validateTailOptions(
--   tailMode: SuspenseListTailMode,
--   revealOrder: SuspenseListRevealOrder,
-- )
--   if  __DEV__ then
--     if tailMode ~= undefined and !didWarnAboutTailOptions[tailMode])
--       if tailMode ~= 'collapsed' and tailMode ~= 'hidden')
--         didWarnAboutTailOptions[tailMode] = true
--         console.error(
--           '"%s" is not a supported value for tail on <SuspenseList />. ' +
--             'Did you mean "collapsed" or "hidden"?',
--           tailMode,
--         )
--       } elseif revealOrder ~= 'forwards' and revealOrder ~= 'backwards')
--         didWarnAboutTailOptions[tailMode] = true
--         console.error(
--           '<SuspenseList tail="%s" /> is only valid if revealOrder is ' +
--             '"forwards" or "backwards". ' +
--             'Did you mean to specify revealOrder="forwards"?',
--           tailMode,
--         )
--       end
--     end
--   end
-- end

-- function validateSuspenseListNestedChild(childSlot: mixed, index: number)
--   if  __DEV__ then
--     local isArray = Array.isArray(childSlot)
--     local isIterable =
--       !isArray and typeof getIteratorFn(childSlot) == 'function'
--     if isArray or isIterable)
--       local type = isArray ? 'array' : 'iterable'
--       console.error(
--         'A nested %s was passed to row #%s in <SuspenseList />. Wrap it in ' +
--           'an additional SuspenseList to configure its revealOrder: ' +
--           '<SuspenseList revealOrder=...> ... ' +
--           '<SuspenseList revealOrder=...>{%s}</SuspenseList> ... ' +
--           '</SuspenseList>',
--         type,
--         index,
--         type,
--       )
--       return false
--     end
--   end
--   return true
-- end

-- function validateSuspenseListChildren(
--   children: mixed,
--   revealOrder: SuspenseListRevealOrder,
-- )
--   if  __DEV__ then
--     if
--       (revealOrder == 'forwards' or revealOrder == 'backwards') and
--       children ~= undefined and
--       children ~= nil and
--       children ~= false
--     )
--       if Array.isArray(children))
--         for (local i = 0; i < children.length; i++)
--           if not validateSuspenseListNestedChild(children[i], i))
--             return
--           end
--         end
--       else
--         local iteratorFn = getIteratorFn(children)
--         if typeof iteratorFn == 'function')
--           local childrenIterator = iteratorFn.call(children)
--           if childrenIterator)
--             local step = childrenIterator.next()
--             local i = 0
--             for (; !step.done; step = childrenIterator.next())
--               if not validateSuspenseListNestedChild(step.value, i))
--                 return
--               end
--               i++
--             end
--           end
--         else
--           console.error(
--             'A single row was passed to a <SuspenseList revealOrder="%s" />. ' +
--               'This is not useful since it needs multiple rows. ' +
--               'Did you mean to pass multiple children or an array?',
--             revealOrder,
--           )
--         end
--       end
--     end
--   end
-- end

-- function initSuspenseListRenderState(
--   workInProgress: Fiber,
--   isBackwards: boolean,
--   tail: nil | Fiber,
--   lastContentRow: nil | Fiber,
--   tailMode: SuspenseListTailMode,
-- ): void {
--   local renderState: nil | SuspenseListRenderState =
--     workInProgress.memoizedState
--   if renderState == nil)
--     workInProgress.memoizedState = ({
--       isBackwards: isBackwards,
--       rendering: nil,
--       renderingStartTime: 0,
--       last: lastContentRow,
--       tail: tail,
--       tailMode: tailMode,
--     }: SuspenseListRenderState)
--   else
--     -- We can reuse the existing object from previous renders.
--     renderState.isBackwards = isBackwards
--     renderState.rendering = nil
--     renderState.renderingStartTime = 0
--     renderState.last = lastContentRow
--     renderState.tail = tail
--     renderState.tailMode = tailMode
--   end
-- end

-- -- This can end up rendering this component multiple passes.
-- -- The first pass splits the children fibers into two sets. A head and tail.
-- -- We first render the head. If anything is in fallback state, we do another
-- -- pass through beginWork to rerender all children (including the tail) with
-- -- the force suspend context. If the first render didn't have anything in
-- -- in fallback state. Then we render each row in the tail one-by-one.
-- -- That happens in the completeWork phase without going back to beginWork.
-- function updateSuspenseListComponent(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes,
-- )
--   local nextProps = workInProgress.pendingProps
--   local revealOrder: SuspenseListRevealOrder = nextProps.revealOrder
--   local tailMode: SuspenseListTailMode = nextProps.tail
--   local newChildren = nextProps.children

--   validateRevealOrder(revealOrder)
--   validateTailOptions(tailMode, revealOrder)
--   validateSuspenseListChildren(newChildren, revealOrder)

--   reconcileChildren(current, workInProgress, newChildren, renderLanes)

--   local suspenseContext: SuspenseContext = suspenseStackCursor.current

--   local shouldForceFallback = hasSuspenseContext(
--     suspenseContext,
--     (ForceSuspenseFallback: SuspenseContext),
--   )
--   if shouldForceFallback)
--     suspenseContext = setShallowSuspenseContext(
--       suspenseContext,
--       ForceSuspenseFallback,
--     )
--     workInProgress.flags |= DidCapture
--   else
--     local didSuspendBefore =
--       current ~= nil and (current.flags & DidCapture) ~= NoFlags
--     if didSuspendBefore)
--       -- If we previously forced a fallback, we need to schedule work
--       -- on any nested boundaries to local them know to try to render
--       -- again. This is the same as context updating.
--       propagateSuspenseContextChange(
--         workInProgress,
--         workInProgress.child,
--         renderLanes,
--       )
--     end
--     suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)
--   end
--   pushSuspenseContext(workInProgress, suspenseContext)

--   if (workInProgress.mode & BlockingMode) == NoMode)
--     -- In legacy mode, SuspenseList doesn't work so we just
--     -- use make it a noop by treating it as the default revealOrder.
--     workInProgress.memoizedState = nil
--   else
--     switch (revealOrder)
--       case 'forwards': {
--         local lastContentRow = findLastContentRow(workInProgress.child)
--         local tail
--         if lastContentRow == nil)
--           -- The whole list is part of the tail.
--           -- TODO: We could fast path by just rendering the tail now.
--           tail = workInProgress.child
--           workInProgress.child = nil
--         else
--           -- Disconnect the tail rows after the content row.
--           -- We're going to render them separately later.
--           tail = lastContentRow.sibling
--           lastContentRow.sibling = nil
--         end
--         initSuspenseListRenderState(
--           workInProgress,
--           false, -- isBackwards
--           tail,
--           lastContentRow,
--           tailMode,
--         )
--         break
--       end
--       case 'backwards': {
--         -- We're going to find the first row that has existing content.
--         -- At the same time we're going to reverse the list of everything
--         -- we pass in the meantime. That's going to be our tail in reverse
--         -- order.
--         local tail = nil
--         local row = workInProgress.child
--         workInProgress.child = nil
--         while (row ~= nil)
--           local currentRow = row.alternate
--           -- New rows can't be content rows.
--           if currentRow ~= nil and findFirstSuspended(currentRow) == nil)
--             -- This is the beginning of the main content.
--             workInProgress.child = row
--             break
--           end
--           local nextRow = row.sibling
--           row.sibling = tail
--           tail = row
--           row = nextRow
--         end
--         -- TODO: If workInProgress.child is nil, we can continue on the tail immediately.
--         initSuspenseListRenderState(
--           workInProgress,
--           true, -- isBackwards
--           tail,
--           nil, -- last
--           tailMode,
--         )
--         break
--       end
--       case 'together': {
--         initSuspenseListRenderState(
--           workInProgress,
--           false, -- isBackwards
--           nil, -- tail
--           nil, -- last
--           undefined,
--         )
--         break
--       end
--       default: {
--         -- The default reveal order is the same as not having
--         -- a boundary.
--         workInProgress.memoizedState = nil
--       end
--     end
--   end
--   return workInProgress.child
-- end

function updatePortalComponent(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	pushHostContainer(workInProgress, workInProgress.stateNode.containerInfo)
	local nextChildren = workInProgress.pendingProps
	if current == nil then
		-- Portals are special because we don't append the children during mount
		-- but at commit. Therefore we need to track insertions which the normal
		-- flow doesn't do during mount. This doesn't happen at the root because
		-- the root always starts with a "current" with a nil child.
		-- TODO: Consider unifying this with how the root works.
		workInProgress.child =
			reconcileChildFibers(workInProgress, nil, nextChildren, renderLanes)
	else
		reconcileChildren(current, workInProgress, nextChildren, renderLanes)
	end
	return workInProgress.child
end

local hasWarnedAboutUsingNoValuePropOnContextProvider = false

local function updateContextProvider(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	local providerType: ReactProviderType<any> = workInProgress.type
	local context: ReactContext<any> = providerType._context

	local newProps = workInProgress.pendingProps
	local oldProps = workInProgress.memoizedProps

	local newValue = newProps.value

	if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		if Array.indexOf(Object.keys(newProps), "value") < 1 then
			if not hasWarnedAboutUsingNoValuePropOnContextProvider then
				hasWarnedAboutUsingNoValuePropOnContextProvider = true
				console.error(
					"The `value` prop is required for the `<Context.Provider>`. Did you misspell it or forget to pass it?"
				)
			end
		end
		-- ROBLOX deviation: adds support for legacy Roact's validateProps()
		local providerPropTypes = workInProgress.type.propTypes
		local validateProps = workInProgress.type.validateProps

		if providerPropTypes or validateProps then
			checkPropTypes(
				providerPropTypes,
				validateProps,
				newProps,
				"prop",
				"Context.Provider"
			)
		end
	end

	pushProvider(workInProgress, newValue)

	if oldProps ~= nil then
		local oldValue = oldProps.value
		local changedBits = calculateChangedBits(context, newValue, oldValue)
		if changedBits == 0 then
			-- No change. Bailout early if children are the same.
			if
				oldProps.children == newProps.children
				and not hasLegacyContextChanged()
			then
				return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
			end
		else
			-- The context value changed. Search for matching consumers and schedule
			-- them to update.
			propagateContextChange(workInProgress, context, changedBits, renderLanes)
		end
	end

	local newChildren = newProps.children
	reconcileChildren(current, workInProgress, newChildren, renderLanes)
	return workInProgress.child
end

-- ROBLOX deviation: combine two warning flags to dodge the registers limit
local hasWarnedAbout = {
	usingContextAsConsumer = false,
	usingLegacyConsumer = false,
}

function updateContextConsumer(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
)
	local context: ReactContext<any> = workInProgress.type
	-- The logic below for Context differs depending on PROD or DEV mode. In
	-- DEV mode, we create a separate object for Context.Consumer that acts
	-- like a proxy to Context. This proxy object adds unnecessary code in PROD
	-- so we use the old behaviour (Context.Consumer references Context) to
	-- reduce size and overhead. The separate object references context via
	-- a property called "_context", which also gives us the ability to check
	-- in DEV mode if this property exists or not and warn if it does not.
	if __DEV__ then
		if (context :: any)._context == nil then
			-- This may be because it's a Context (rather than a Consumer).
			-- Or it may be because it's older React where they're the same thing.
			-- We only want to warn if we're sure it's a new React.
			if context ~= context.Consumer then
				if not hasWarnedAbout.usingContextAsConsumer then
					hasWarnedAbout.usingContextAsConsumer = true
					console.error(
						"Rendering <Context> directly is not supported and will be removed in "
							.. "a future major release. Did you mean to render <Context.Consumer> instead?"
					)
				end
			end
		else
			context = (context :: any)._context
		end
	end
	local newProps = workInProgress.pendingProps

	-- ROBLOX deviation: compatibility for old Roact's context consumer API
	local render
	if newProps.render then
		if __DEV__ and __COMPAT_WARNINGS__ then
			if not hasWarnedAbout.usingLegacyConsumer then
				hasWarnedAbout.usingLegacyConsumer = true
				console.warn(
					"Your Context.Consumer component is using legacy Roact syntax, which won't be supported in future versions of Roact. \n"
						.. "Please provide no props and supply the 'render' function as a child (the 3rd argument of createElement). For example: \n"
						.. "       createElement(ContextConsumer, {render = function(...) end})\n"
						.. "becomes:\n"
						.. "       createElement(ContextConsumer, nil, function(...) end)\n"
						.. "For more info, reference the React documentation here: \n"
						.. "https://reactjs.org/docs/context.html#contextconsumer"
				)
			end
		end
		render = newProps.render
	else
		render = newProps.children
	end

	if __DEV__ then
		if type(render) ~= "function" then
			console.error(
				"A context consumer was rendered with multiple children, or a child "
					.. "that isn't a function. A context consumer expects a single child "
					.. "that is a function. If you did pass a function, make sure there "
					.. "is no trailing or leading whitespace around it."
			)
		end
	end

	prepareToReadContext(
		workInProgress,
		renderLanes,
		exports.markWorkInProgressReceivedUpdate
	)
	local newValue = readContext(context, newProps.unstable_observedBits)
	local newChildren
	if __DEV__ then
		ReactCurrentOwner.current = workInProgress
		setIsRendering(true)
		newChildren = render(newValue)
		setIsRendering(false)
	else
		newChildren = render(newValue)
	end

	-- React DevTools reads this flag.
	workInProgress.flags = bit32.bor(workInProgress.flags, PerformedWork)
	reconcileChildren(current, workInProgress, newChildren, renderLanes)
	return workInProgress.child
end

-- ROBLOX TODO: fundamental component is removed in React 18, clean up all traces when we upgrade
-- function updateFundamentalComponent(current, workInProgress, renderLanes)
--   local fundamentalImpl = workInProgress.type.impl
--   if fundamentalImpl.reconcileChildren == false then
--     return nil
--   end
--   local nextProps = workInProgress.pendingProps
--   local nextChildren = nextProps.children

--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

-- ROBLOX TODO: scope component is disabled in our FeatureFlags, uncomment when we enable it
-- function updateScopeComponent(current, workInProgress, renderLanes)
--   local nextProps = workInProgress.pendingProps
--   local nextChildren = nextProps.children

--   reconcileChildren(current, workInProgress, nextChildren, renderLanes)
--   return workInProgress.child
-- end

exports.markWorkInProgressReceivedUpdate = function()
	didReceiveUpdate = true
end

function bailoutOnAlreadyFinishedWork(
	current: Fiber | nil,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	if current then
		-- Reuse previous dependencies
		workInProgress.dependencies = current.dependencies
	end

	if enableProfilerTimer then
		-- Don't update "base" render times for bailouts.
		stopProfilerTimerIfRunning(workInProgress)
	end

	markSkippedUpdateLanes(workInProgress.lanes)

	-- Check if the children have any pending work.
	if not ReactFiberLane.includesSomeLane(renderLanes, workInProgress.childLanes) then
		-- The children don't have any work either. We can skip them.
		-- TODO: Once we add back resuming, we should check if the children are
		-- a work-in-progress set. If so, we need to transfer their effects.
		return nil
	else
		-- This fiber doesn't have work, but its subtree does. Clone the child
		-- fibers and continue.
		cloneChildFibers(current, workInProgress)
		return workInProgress.child
	end
end

function remountFiber(
	current: Fiber,
	oldWorkInProgress: Fiber,
	newWorkInProgress: Fiber
): Fiber | nil
	if __DEV__ then
		local returnFiber = oldWorkInProgress.return_
		if returnFiber == nil then
			error("Cannot swap the root fiber.")
		end
		-- ROBLOX FIXME Luau: remove this assert when Luau type states understands the above guard
		assert(returnFiber ~= nil, "returnFiber was nil in remountFiber")

		-- Disconnect from the old current.
		-- It will get deleted.
		current.alternate = nil
		oldWorkInProgress.alternate = nil

		-- Connect to the new tree.
		newWorkInProgress.index = oldWorkInProgress.index
		newWorkInProgress.sibling = oldWorkInProgress.sibling
		newWorkInProgress.return_ = oldWorkInProgress.return_
		newWorkInProgress.ref = oldWorkInProgress.ref

		-- Replace the child/sibling pointers above it.
		if oldWorkInProgress == returnFiber.child then
			returnFiber.child = newWorkInProgress
		else
			local prevSibling = returnFiber.child
			if prevSibling == nil then
				error("Expected parent to have a child.")
			end
			-- ROBLOX FIXME Luau: remove this assert when Luau type states understands the above guard
			assert(prevSibling ~= nil, "prevSibling was nil in remountFiber")

			while prevSibling.sibling ~= oldWorkInProgress do
				prevSibling = prevSibling.sibling
				if prevSibling == nil then
					error("Expected to find the previous sibling.")
				end
			end
			prevSibling.sibling = newWorkInProgress
		end

		-- Delete the old fiber and place the new one.
		-- Since the old fiber is disconnected, we have to schedule it manually.
		local deletions = returnFiber.deletions
		if deletions == nil then
			returnFiber.deletions = { current }
			-- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
			returnFiber.flags = bit32.bor(returnFiber.flags, Deletion)
		else
			table.insert(deletions, current)
		end

		newWorkInProgress.flags = bit32.bor(newWorkInProgress.flags, Placement)

		-- Restart work from the new fiber.
		return newWorkInProgress
	else
		error(
			"Did not expect this call in production. "
				.. "This is a bug in React. Please file an issue."
		)
	end
end

-- FIXME (roblox): restore types when refinement is better:
-- current: Fiber | nil,
local function beginWork(current: any, workInProgress: Fiber, renderLanes: Lanes): Fiber?
	local updateLanes = workInProgress.lanes

	if __DEV__ then
		if workInProgress._debugNeedsRemount and current ~= nil then
			-- This will restart the begin phase with a new fiber.
			return remountFiber(
				current,
				workInProgress,
				createFiberFromTypeAndProps(
					workInProgress.type,
					-- ROBLOX FIXME: we widen this to be number|string for Roact compatibility
					workInProgress.key :: string?,
					workInProgress.pendingProps,
					workInProgress._debugOwner or nil,
					workInProgress.mode,
					workInProgress.lanes
				)
			)
		end
	end

	if current ~= nil then
		local oldProps = current.memoizedProps
		local newProps = workInProgress.pendingProps

		if
			oldProps ~= newProps
			or hasLegacyContextChanged()
			-- Force a re-render if the implementation changed due to hot reload:
			or if __DEV__ then workInProgress.type ~= current.type else false
		then
			-- If props or context changed, mark the fiber as having performed work.
			-- This may be unset if the props are determined to be equal later (memo).
			didReceiveUpdate = true
		elseif not ReactFiberLane.includesSomeLane(renderLanes, updateLanes) then
			didReceiveUpdate = false
			-- This fiber does not have any pending work. Bailout without entering
			-- the begin phase. There's still some bookkeeping we that needs to be done
			-- in this optimized path, mostly pushing stuff onto the stack.
			if workInProgress.tag == HostRoot then
				pushHostRootContext(workInProgress)
				resetHydrationState()
			elseif workInProgress.tag == HostComponent then
				pushHostContext(workInProgress)
			elseif workInProgress.tag == ClassComponent then
				local Component = workInProgress.type
				if isLegacyContextProvider(Component) then
					pushLegacyContextProvider(workInProgress)
				end
			elseif workInProgress.tag == HostPortal then
				pushHostContainer(workInProgress, workInProgress.stateNode.containerInfo)
			elseif workInProgress.tag == ContextProvider then
				local newValue = workInProgress.memoizedProps.value
				pushProvider(workInProgress, newValue)
			elseif workInProgress.tag == Profiler then
				if enableProfilerTimer then
					-- Reset effect durations for the next eventual effect phase.
					-- These are reset during render to allow the DevTools commit hook a chance to read them,
					local stateNode = workInProgress.stateNode
					stateNode.effectDuration = 0
					stateNode.passiveEffectDuration = 0
				end
			elseif workInProgress.tag == SuspenseComponent then
				local state: SuspenseState | nil = workInProgress.memoizedState
				if state ~= nil then
					if enableSuspenseServerRenderer then
						if (state :: SuspenseState).dehydrated ~= nil then
							pushSuspenseContext(
								workInProgress,
								setDefaultShallowSuspenseContext(
									suspenseStackCursor.current
								)
							)
							-- We know that this component will suspend again because if it has
							-- been unsuspended it has committed as a resolved Suspense component.
							-- If it needs to be retried, it should have work scheduled on it.
							workInProgress.flags =
								bit32.bor(workInProgress.flags, DidCapture)
							-- We should never render the children of a dehydrated boundary until we
							-- upgrade it. We return nil instead of bailoutOnAlreadyFinishedWork.
							return nil
						end
					end

					-- If this boundary is currently timed out, we need to decide
					-- whether to retry the primary children, or to skip over it and
					-- go straight to the fallback. Check the priority of the primary
					-- child fragment.
					local primaryChildFragment: Fiber = workInProgress.child :: any
					local primaryChildLanes = primaryChildFragment.childLanes
					if
						ReactFiberLane.includesSomeLane(renderLanes, primaryChildLanes)
					then
						-- The primary children have pending work. Use the normal path
						-- to attempt to render the primary children again.
						return updateSuspenseComponent(
							current,
							workInProgress,
							renderLanes
						)
					else
						-- The primary child fragment does not have pending work marked
						-- on it
						pushSuspenseContext(
							workInProgress,
							setDefaultShallowSuspenseContext(suspenseStackCursor.current)
						)
						-- The primary children do not have pending work with sufficient
						-- priority. Bailout.
						local child = bailoutOnAlreadyFinishedWork(
							current,
							workInProgress,
							renderLanes
						)
						if child ~= nil then
							-- The fallback children have pending work. Skip over the
							-- primary children and work on the fallback.
							return child.sibling
						else
							return nil
						end
					end
				else
					pushSuspenseContext(
						workInProgress,
						setDefaultShallowSuspenseContext(suspenseStackCursor.current)
					)
				end
			elseif workInProgress.tag == SuspenseListComponent then
				unimplemented("beginWork: SuspenseListComponent")
			-- local didSuspendBefore = bit32.band(current.flags, DidCapture) ~= NoFlags

			-- local hasChildWork = ReactFiberLane.includesSomeLane(
			--   renderLanes,
			--   workInProgress.childLanes
			-- )

			-- if didSuspendBefore then
			--   if hasChildWork then
			--     -- If something was in fallback state last time, and we have all the
			--     -- same children then we're still in progressive loading state.
			--     -- Something might get unblocked by state updates or retries in the
			--     -- tree which will affect the tail. So we need to use the normal
			--     -- path to compute the correct tail.
			--     return updateSuspenseListComponent(
			--       current,
			--       workInProgress,
			--       renderLanes
			--     )
			--   end
			--   -- If none of the children had any work, that means that none of
			--   -- them got retried so they'll still be blocked in the same way
			--   -- as before. We can fast bail out.
			--   workInProgress.flags = bit32.bor(workInProgress.flags, DidCapture)
			-- end

			-- -- If nothing suspended before and we're rendering the same children,
			-- -- then the tail doesn't matter. Anything new that suspends will work
			-- -- in the "together" mode, so we can continue from the state we had.
			-- local renderState = workInProgress.memoizedState
			-- if renderState ~= nil then
			--   -- Reset to the "together" mode in case we've started a different
			--   -- update in the past but didn't complete it.
			--   renderState.rendering = nil
			--   renderState.tail = nil
			-- end
			-- pushSuspenseContext(workInProgress, suspenseStackCursor.current)

			-- if not hasChildWork then
			--   -- If none of the children had any work, that means that none of
			--   -- them got retried so they'll still be blocked in the same way
			--   -- as before. We can fast bail out.
			--   return nil
			-- end
			elseif
				workInProgress.tag == OffscreenComponent
				or workInProgress.tag == LegacyHiddenComponent
			then
				-- Need to check if the tree still needs to be deferred. This is
				-- almost identical to the logic used in the normal update path,
				-- so we'll just enter that. The only difference is we'll bail out
				-- at the next level instead of this one, because the child props
				-- have not changed. Which is fine.
				-- TODO: Probably should refactor `beginWork` to split the bailout
				-- path from the normal path. I'm tempted to do a labeled break here
				-- but I won't :)
				workInProgress.lanes = ReactFiberLane.NoLanes
				return updateOffscreenComponent(current, workInProgress, renderLanes)
			end
			return bailoutOnAlreadyFinishedWork(current, workInProgress, renderLanes)
		else
			if bit32.band(current.flags, ForceUpdateForLegacySuspense) ~= NoFlags then
				-- This is a special case that only exists for legacy mode.
				-- See https://github.com/facebook/react/pull/19216.
				didReceiveUpdate = true
			else
				-- An update was scheduled on this fiber, but there are no new props
				-- nor legacy context. Set this to false. If an update queue or context
				-- consumer produces a changed value, it will set this to true. Otherwise,
				-- the component will assume the children have not changed and bail out.
				didReceiveUpdate = false
			end
		end
	else
		didReceiveUpdate = false
	end

	-- Before entering the begin phase, clear pending update priority.
	-- TODO: This assumes that we're about to evaluate the component and process
	-- the update queue. However, there's an exception: SimpleMemoComponent
	-- sometimes bails out later in the begin phase. This indicates that we should
	-- move this assignment out of the common path and into each branch.
	workInProgress.lanes = ReactFiberLane.NoLanes

	if workInProgress.tag == ReactWorkTags.IndeterminateComponent then
		return mountIndeterminateComponent(
			current,
			workInProgress,
			workInProgress.type,
			renderLanes
		)
	elseif workInProgress.tag == LazyComponent then
		local elementType = workInProgress.elementType
		return mountLazyComponent(
			current,
			workInProgress,
			elementType,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == FunctionComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps
		if workInProgress.elementType == Component then
			resolvedProps = unresolvedProps
		else
			resolvedProps = resolveDefaultProps(Component, unresolvedProps)
		end
		return updateFunctionComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	elseif workInProgress.tag == ClassComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = workInProgress.elementType == Component and unresolvedProps
			or resolveDefaultProps(Component, unresolvedProps)
		return updateClassComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	elseif workInProgress.tag == HostRoot then
		return updateHostRoot(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostComponent then
		return updateHostComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostText then
		return updateHostText(current, workInProgress)
	elseif workInProgress.tag == SuspenseComponent then
		return updateSuspenseComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == HostPortal then
		return updatePortalComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ForwardRef then
		local type = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = unresolvedProps
		if workInProgress.elementType ~= type then
			resolvedProps = resolveDefaultProps(type, unresolvedProps)
		end
		return updateForwardRef(current, workInProgress, type, resolvedProps, renderLanes)
	elseif workInProgress.tag == Fragment then
		return updateFragment(current, workInProgress, renderLanes)
	elseif workInProgress.tag == Mode then
		return updateMode(current, workInProgress, renderLanes)
	elseif workInProgress.tag == Profiler then
		return updateProfiler(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ContextProvider then
		return updateContextProvider(current, workInProgress, renderLanes)
	elseif workInProgress.tag == ContextConsumer then
		return updateContextConsumer(current, workInProgress, renderLanes)
	elseif workInProgress.tag == MemoComponent then
		local type_ = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		-- Resolve outer props first, then resolve inner props.
		local resolvedProps = resolveDefaultProps(type_, unresolvedProps)
		if __DEV__ or __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
			if workInProgress.type ~= workInProgress.elementType then
				-- ROBLOX deviation: adds support for legacy Roact's validateProps()
				local outerPropTypes
				local validateProps
				-- ROBLOX deviation: only get propTypes from class components, Lua doesn't support fields on functions
				if type(type_) == "table" then
					outerPropTypes = type_.propTypes
					validateProps = type_.validateProps
				end
				if outerPropTypes or validateProps then
					checkPropTypes(
						outerPropTypes,
						validateProps,
						resolvedProps, -- Resolved for outer only
						"prop",
						getComponentName(type_)
					)
				end
			end
		end
		resolvedProps = resolveDefaultProps(type_.type, resolvedProps)
		return updateMemoComponent(
			current,
			workInProgress,
			type_,
			resolvedProps,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == SimpleMemoComponent then
		return updateSimpleMemoComponent(
			current,
			workInProgress,
			workInProgress.type,
			workInProgress.pendingProps,
			updateLanes,
			renderLanes
		)
	elseif workInProgress.tag == IncompleteClassComponent then
		local Component = workInProgress.type
		local unresolvedProps = workInProgress.pendingProps
		local resolvedProps = workInProgress.elementType == Component and unresolvedProps
			or resolveDefaultProps(Component, unresolvedProps)
		return mountIncompleteClassComponent(
			current,
			workInProgress,
			Component,
			resolvedProps,
			renderLanes
		)
	-- elseif workInProgress.tag == SuspenseListComponent then
	--   unimplemented("beginWork: SuspenseListComponent")
	-- return updateSuspenseListComponent(current, workInProgress, renderLanes)
	-- elseif workInProgress.tag == FundamentalComponent then
	--   if enableFundamentalAPI then
	--     return updateFundamentalComponent(current, workInProgress, renderLanes)
	--   end
	-- elseif workInProgress.tag == ScopeComponent then
	--   if enableScopeAPI then
	--     return updateScopeComponent(current, workInProgress, renderLanes)
	--   end
	elseif workInProgress.tag == OffscreenComponent then
		return updateOffscreenComponent(current, workInProgress, renderLanes)
	elseif workInProgress.tag == LegacyHiddenComponent then
		return updateLegacyHiddenComponent(current, workInProgress, renderLanes)
	end
	invariant(
		false,
		"Unknown unit of work tag (%s). This error is likely caused by a bug in "
			.. "React. Please file an issue.",
		tostring(workInProgress.tag)
	)
	return nil
end
exports.beginWork = beginWork

return exports
