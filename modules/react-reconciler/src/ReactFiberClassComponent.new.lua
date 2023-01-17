--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/c63741fb3daef6c1e8746cbe7d7b07ecb281a9fd/packages/react-reconciler/src/ReactFiberClassComponent.new.js
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
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
type UpdateQueue<State> = ReactInternalTypes.UpdateQueue<State>

local ReactTypes = require(Packages.Shared)
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>

local React = require(Packages.React)

local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Update = ReactFiberFlags.Update
local Snapshot = ReactFiberFlags.Snapshot
local MountLayoutDev = ReactFiberFlags.MountLayoutDev

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode
local disableLegacyContext = ReactFeatureFlags.disableLegacyContext
local enableDebugTracing = ReactFeatureFlags.enableDebugTracing
local enableSchedulingProfiler = ReactFeatureFlags.enableSchedulingProfiler
local warnAboutDeprecatedLifecycles = ReactFeatureFlags.warnAboutDeprecatedLifecycles
local enableDoubleInvokingEffects = ReactFeatureFlags.enableDoubleInvokingEffects

local ReactStrictModeWarnings = require(script.Parent["ReactStrictModeWarnings.new"])
local isMounted = require(script.Parent.ReactFiberTreeReflection).isMounted
local ReactInstanceMap = require(Packages.Shared).ReactInstanceMap
local getInstance = ReactInstanceMap.get
local setInstance = ReactInstanceMap.set
local shallowEqual = require(Packages.Shared).shallowEqual
local getComponentName = require(Packages.Shared).getComponentName
local UninitializedState = require(Packages.Shared).UninitializedState
local describeError = require(Packages.Shared).describeError
-- local invariant = require(Packages.Shared).invariant
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE

local resolveDefaultProps =
	require(script.Parent["ReactFiberLazyComponent.new"]).resolveDefaultProps
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local StrictMode = ReactTypeOfMode.StrictMode

local enqueueUpdate = ReactUpdateQueue.enqueueUpdate
local processUpdateQueue = ReactUpdateQueue.processUpdateQueue
local checkHasForceUpdateAfterProcessing =
	ReactUpdateQueue.checkHasForceUpdateAfterProcessing
local resetHasForceUpdateBeforeProcessing =
	ReactUpdateQueue.resetHasForceUpdateBeforeProcessing
local createUpdate = ReactUpdateQueue.createUpdate
local ReplaceState = ReactUpdateQueue.ReplaceState
local ForceUpdate = ReactUpdateQueue.ForceUpdate
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local cloneUpdateQueue = ReactUpdateQueue.cloneUpdateQueue
local NoLanes = ReactFiberLane.NoLanes

local ReactFiberContext = require(script.Parent["ReactFiberContext.new"])
local cacheContext = ReactFiberContext.cacheContext
local getMaskedContext = ReactFiberContext.getMaskedContext
local getUnmaskedContext = ReactFiberContext.getUnmaskedContext
local hasContextChanged = ReactFiberContext.hasContextChanged
local emptyContextObject = ReactFiberContext.emptyContextObject

local ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"])
local readContext = ReactFiberNewContext.readContext

-- local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"])
-- local requestEventTime = ReactFiberWorkLoop.requestEventTime
-- local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
-- local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
local DebugTracing = require(script.Parent.DebugTracing)
local logForceUpdateScheduled = DebugTracing.logForceUpdateScheduled
local logStateUpdateScheduled = DebugTracing.logStateUpdateScheduled

local ConsolePatchingDev = require(Packages.Shared).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local SchedulingProfiler = require(script.Parent.SchedulingProfiler)
local markForceUpdateScheduled = SchedulingProfiler.markForceUpdateScheduled
local markStateUpdateScheduled = SchedulingProfiler.markStateUpdateScheduled

local fakeInternalInstance = {}
-- ROBLOX TODO: If this is being localized, it might be for a hot path; that's
-- concerning, since our version of `isArray` is much more complex
-- local isArray = Array.isArray

-- React.Component uses a shared frozen object by default.
-- We'll use it to determine whether we need to initialize legacy refs.
-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
-- local emptyRefsObject = React.Component:extend("").refs
local emptyRefsObject = React.Component:extend("").__refs

local didWarnAboutStateAssignmentForComponent
local didWarnAboutUninitializedState
local didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate
local didWarnAboutLegacyLifecyclesAndDerivedState
local _didWarnAboutUndefinedDerivedState
local warnOnUndefinedDerivedState
local warnOnInvalidCallback
local didWarnAboutDirectlyAssigningPropsToState
local didWarnAboutContextTypeAndContextTypes
local didWarnAboutInvalidateContextType

if __DEV__ then
	didWarnAboutStateAssignmentForComponent = {}
	didWarnAboutUninitializedState = {}
	didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate = {}
	didWarnAboutLegacyLifecyclesAndDerivedState = {}
	didWarnAboutDirectlyAssigningPropsToState = {}
	_didWarnAboutUndefinedDerivedState = {}
	didWarnAboutContextTypeAndContextTypes = {}
	didWarnAboutInvalidateContextType = {}

	local didWarnOnInvalidCallback = {}

	function warnOnInvalidCallback(callback: any, callerName: string)
		if callback == nil or type(callback) == "function" then
			return
		end
		local key = callerName .. "_" .. tostring(callback)
		if not didWarnOnInvalidCallback[key] then
			didWarnOnInvalidCallback[key] = true
			console.error(
				"%s(...): Expected the last optional `callback` argument to be a "
					.. "function. Instead received: %s.",
				callerName,
				tostring(callback)
			)
		end
	end

	function warnOnUndefinedDerivedState(type_, partialState)
		-- ROBLOX deviation: `nil` is a valid return for getDerivedStateFromProps, but
		-- `undefined` is not possible for us to return; we could try to detect
		-- returning zero values, but that's likely not possible without tracking it
		-- differently at the original callsite (e.g. the value we save to
		-- `partialState` would still be nil)

		-- if partialState == nil then
		--   local componentName = getComponentName(type_) or "Component"
		--   if not didWarnAboutUndefinedDerivedState[componentName] then
		--     didWarnAboutUndefinedDerivedState[componentName] = true
		--     console.error(
		--       "%s.getDerivedStateFromProps(): A valid state object (or nil) must be returned. " ..
		--         "You have returned undefined.",
		--       componentName
		--     )
		--   end
		-- end
	end

	--   -- ROBLOX FIXME: I'm not sure this applies, need to revisit it
	--   -- -- This is so gross but it's at least non-critical and can be removed if
	--   -- -- it causes problems. This is meant to give a nicer error message for
	--   -- -- ReactDOM15.unstable_renderSubtreeIntoContainer(reactDOM16Component,
	--   -- -- ...)) which otherwise throws a "_processChildContext is not a function"
	--   -- -- exception.
	--   -- Object.defineProperty(fakeInternalInstance, '_processChildContext', {
	--   --   enumerable: false,
	--   --   value: function()
	--   --     invariant(
	--   --       false,
	--   --       '_processChildContext is not available in React 16+. This likely ' +
	--   --         'means you have multiple copies of React and are attempting to nest ' +
	--   --         'a React 15 tree inside a React 16 tree using ' +
	--   --         "unstable_renderSubtreeIntoContainer, which isn't supported. Try " +
	--   --         'to make sure you have only one copy of React (and ideally, switch ' +
	--   --         'to ReactDOM.createPortal).',
	--   --     )
	--   --   },
	--   -- })
	--   Object.freeze(fakeInternalInstance)
end

local function applyDerivedStateFromProps<Props, State>(
	workInProgress: Fiber,
	ctor: React_Component<Props, State>,
	getDerivedStateFromProps: (Props, State) -> State?,
	nextProps: Props
)
	local prevState = workInProgress.memoizedState

	if __DEV__ then
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			-- Invoke the function an extra time to help detect side-effects.
			local ok, result =
				xpcall(getDerivedStateFromProps, describeError, nextProps, prevState)

			reenableLogs()

			if not ok then
				error(result)
			end
		end
	end

	local partialState = getDerivedStateFromProps(nextProps, prevState)

	if __DEV__ then
		warnOnUndefinedDerivedState(ctor, partialState)
	end
	-- Merge the partial state and the previous state.
	local memoizedState = if partialState == nil
		then prevState
		else Object.assign({}, prevState, partialState)
	workInProgress.memoizedState = memoizedState

	-- Once the update queue is empty, persist the derived state onto the
	-- base state.
	if workInProgress.lanes == NoLanes then
		-- Queue is always non-null for classes
		local updateQueue: UpdateQueue<any> = workInProgress.updateQueue
		updateQueue.baseState = memoizedState
	end
end

-- deviation: lazy initialize this to avoid cycles
local classComponentUpdater = nil
local function initializeClassComponentUpdater()
	local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"])
	local requestEventTime = ReactFiberWorkLoop.requestEventTime
	local requestUpdateLane = ReactFiberWorkLoop.requestUpdateLane
	local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber

	classComponentUpdater = {
		isMounted = isMounted,
		enqueueSetState = function(inst, payload, callback: (() -> (...any))?)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, payload, callback)
			-- update.payload = payload
			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "setState")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logStateUpdateScheduled(name, lane, payload)
					end
				end
			end

			if enableSchedulingProfiler then
				markStateUpdateScheduled(fiber, lane)
			end
		end,
		enqueueReplaceState = function(inst, payload, callback)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, payload, callback)
			update.tag = ReplaceState
			-- update.payload = payload

			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "replaceState")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logStateUpdateScheduled(name, lane, payload)
					end
				end
			end

			if enableSchedulingProfiler then
				markStateUpdateScheduled(fiber, lane)
			end
		end,
		enqueueForceUpdate = function(inst, callback)
			local fiber = getInstance(inst)
			local eventTime = requestEventTime()
			local lane = requestUpdateLane(fiber)

			local update = createUpdate(eventTime, lane, nil, callback)
			update.tag = ForceUpdate

			if callback ~= nil then
				if __DEV__ then
					warnOnInvalidCallback(callback, "forceUpdate")
				end
				-- update.callback = callback
			end

			enqueueUpdate(fiber, update)
			scheduleUpdateOnFiber(fiber, lane, eventTime)

			if __DEV__ then
				if enableDebugTracing then
					if bit32.band(fiber.mode, DebugTracingMode) ~= 0 then
						local name = getComponentName(fiber.type) or "Unknown"
						logForceUpdateScheduled(name, lane)
					end
				end
			end

			if enableSchedulingProfiler then
				markForceUpdateScheduled(fiber, lane)
			end
		end,
	}
end

local function getClassComponentUpdater()
	if classComponentUpdater == nil then
		initializeClassComponentUpdater()
	end
	return classComponentUpdater
end

function checkShouldComponentUpdate(
	workInProgress,
	ctor,
	oldProps,
	newProps,
	oldState,
	newState,
	nextContext
)
	local instance = workInProgress.stateNode
	if
		instance.shouldComponentUpdate ~= nil
		and type(instance.shouldComponentUpdate) == "function"
	then
		if __DEV__ then
			if
				debugRenderPhaseSideEffectsForStrictMode
				and bit32.band(workInProgress.mode, StrictMode) ~= 0
			then
				disableLogs()
				-- deviation: Pass instance so that the method receives self
				-- Invoke the function an extra time to help detect side-effects.
				local ok, result = xpcall(
					instance.shouldComponentUpdate,
					describeError,
					instance,
					newProps,
					newState,
					nextContext
				)
				-- finally
				reenableLogs()
				if not ok then
					error(result)
				end
			end
		end
		-- deviation: Call with ":" so that the method receives self
		local shouldUpdate =
			instance:shouldComponentUpdate(newProps, newState, nextContext)

		if __DEV__ then
			if shouldUpdate == nil then
				console.error(
					"%s.shouldComponentUpdate(): Returned nil instead of a "
						.. "boolean value. Make sure to return true or false.",
					getComponentName(ctor) or "Component"
				)
			end
		end

		return shouldUpdate
	end

	-- ROBLOX deviation: for us, the isPureReactComponent flag will be visible as a
	-- direct member of the 'ctor', which in reality is the component definition
	if type(ctor) == "table" and ctor.isPureReactComponent then
		return (
			not shallowEqual(oldProps, newProps) or not shallowEqual(oldState, newState)
		)
	end

	return true
end

local function checkClassInstance(workInProgress: Fiber, ctor: any, newProps: any)
	local instance = workInProgress.stateNode
	if __DEV__ then
		local name = getComponentName(ctor) or "Component"
		local renderPresent = instance.render

		if not renderPresent then
			-- ROBLOX deviation: for us, the render function will be visible as a direct
			-- member of the 'ctor', which in reality is the component definition
			if type(ctor.render) == "function" then
				console.error(
					"%s(...): No `render` method found on the returned component "
						.. "instance: did you accidentally return an object from the constructor?",
					name
				)
			else
				console.error(
					"%s(...): No `render` method found on the returned component "
						.. "instance: you may have forgotten to define `render`.",
					name
				)
			end
		end

		if
			instance.getInitialState
			and not instance.getInitialState.isReactClassApproved
			and not instance.state
		then
			console.error(
				"getInitialState was defined on %s, a plain JavaScript class. "
					.. "This is only supported for classes created using React.createClass. "
					.. "Did you mean to define a state property instead?",
				name
			)
		end
		if
			instance.getDefaultProps
			and not instance.getDefaultProps.isReactClassApproved
		then
			console.error(
				"getDefaultProps was defined on %s, a plain JavaScript class. "
					.. "This is only supported for classes created using React.createClass. "
					.. "Use a static property to define defaultProps instead.",
				name
			)
		end
		-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
		if instance.propTypes and not ctor.propTypes then
			console.error(
				"propTypes was defined as an instance property on %s. Use a static "
					.. "property to define propTypes instead.",
				name
			)
		end
		-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
		if instance.contextType and not ctor.contextType then
			console.error(
				"contextType was defined as an instance property on %s. Use a static "
					.. "property to define contextType instead.",
				name
			)
		end

		if disableLegacyContext then
			if ctor.childContextTypes then
				console.error(
					"%s uses the legacy childContextTypes API which is no longer supported. "
						.. "Use React.createContext() instead.",
					name
				)
			end
			if ctor.contextTypes then
				console.error(
					"%s uses the legacy contextTypes API which is no longer supported. "
						.. "Use React.createContext() with static contextType instead.",
					name
				)
			end
		else
			-- ROBLOX TODO? the original check causes false positives, this adjustment should live up to the intention
			if instance.contextTypes and not ctor.contextTypes then
				console.error(
					"contextTypes was defined as an instance property on %s. Use a static "
						.. "property to define contextTypes instead.",
					name
				)
			end

			-- ROBLOX deviation: don't access fields on a function
			if
				type(ctor) == "table"
				and ctor.contextType
				and ctor.contextTypes
				and not didWarnAboutContextTypeAndContextTypes[ctor]
			then
				didWarnAboutContextTypeAndContextTypes[ctor] = true
				console.error(
					"%s declares both contextTypes and contextType static properties. "
						.. "The legacy contextTypes property will be ignored.",
					name
				)
			end
		end

		if type(instance.componentShouldUpdate) == "function" then
			console.error(
				"%s has a method called "
					.. "componentShouldUpdate(). Did you mean shouldComponentUpdate()? "
					.. "The name is phrased as a question because the function is "
					.. "expected to return a value.",
				name
			)
		end
		-- ROBLOX deviation: don't access fields on a function
		if
			type(ctor) == "table"
			and ctor.isPureReactComponent
			and instance.shouldComponentUpdate ~= nil
		then
			console.error(
				"%s has a method called shouldComponentUpdate(). "
					.. "shouldComponentUpdate should not be used when extending React.PureComponent. "
					.. "Please extend React.Component if shouldComponentUpdate is used.",
				getComponentName(ctor) or "A pure component"
			)
		end
		if type(instance.componentDidUnmount) == "function" then
			console.error(
				"%s has a method called "
					.. "componentDidUnmount(). But there is no such lifecycle method. "
					.. "Did you mean componentWillUnmount()?",
				name
			)
		end
		if type(instance.componentDidReceiveProps) == "function" then
			console.error(
				"%s has a method called "
					.. "componentDidReceiveProps(). But there is no such lifecycle method. "
					.. "If you meant to update the state in response to changing props, "
					.. "use componentWillReceiveProps(). If you meant to fetch data or "
					.. "run side-effects or mutations after React has updated the UI, use componentDidUpdate().",
				name
			)
		end
		if type(instance.componentWillRecieveProps) == "function" then
			console.error(
				"%s has a method called "
					.. "componentWillRecieveProps(). Did you mean componentWillReceiveProps()?",
				name
			)
		end
		if type(instance.UNSAFE_componentWillRecieveProps) == "function" then
			console.error(
				"%s has a method called "
					.. "UNSAFE_componentWillRecieveProps(). Did you mean UNSAFE_componentWillReceiveProps()?",
				name
			)
		end
		local hasMutatedProps = instance.props ~= newProps
		if instance.props ~= nil and hasMutatedProps then
			console.error(
				"%s(...): When calling super() in `%s`, make sure to pass "
					.. "up the same props that your component's constructor was passed.",
				name,
				name
			)
		end
		if rawget(instance, "defaultProps") then
			console.error(
				"Setting defaultProps as an instance property on %s is not supported and will be ignored."
					.. " Instead, define defaultProps as a static property on %s.",
				name,
				name
			)
		end

		if
			type(instance.getSnapshotBeforeUpdate) == "function"
			and type(instance.componentDidUpdate) ~= "function"
			and not didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate[ctor]
		then
			didWarnAboutGetSnapshotBeforeUpdateWithoutDidUpdate[ctor] = true
			console.error(
				"%s: getSnapshotBeforeUpdate() should be used with componentDidUpdate(). "
					.. "This component defines getSnapshotBeforeUpdate() only.",
				getComponentName(ctor)
			)
		end

		-- ROBLOX TODO: get function arity to see if it takes >0 arguments. if it takes 1, assume it's self, and warn
		-- if type(instance.getDerivedStateFromProps) == "function" then
		--   console.error(
		--     "%s: getDerivedStateFromProps() is defined as an instance method " ..
		--       "and will be ignored. Instead, declare it as a static method.",
		--     name
		--   )
		-- end
		-- if type(instance.getDerivedStateFromError) == "function" then
		--   console.error(
		--     "%s: getDerivedStateFromError() is defined as an instance method " ..
		--       "and will be ignored. Instead, declare it as a static method.",
		--     name
		--   )
		-- end
		-- if type(ctor.getSnapshotBeforeUpdate) == "function" then
		--   console.error(
		--     "%s: getSnapshotBeforeUpdate() is defined as a static method " ..
		--       "and will be ignored. Instead, declare it as an instance method.",
		--     name
		--   )
		-- end
		local state = instance.state
		-- deviation: It's not useful for us to try to distinguish an array from an
		-- object in this case
		-- if state and (type(state) ~= "table" or Array.isArray(state)) then
		if state ~= nil and type(state) ~= "table" then
			console.error("%s.state: must be set to an object or nil", name)
		end
		-- ROBLOX deviation: don't access fields on a function
		if
			type(ctor) == "table"
			and type(instance.getChildContext) == "function"
			and type(ctor.childContextTypes) ~= "table"
		then
			console.error(
				"%s.getChildContext(): childContextTypes must be defined in order to "
					.. "use getChildContext().",
				name
			)
		end
	end
end

local function adoptClassInstance(workInProgress: Fiber, instance: any)
	-- ROBLOX performance? it looks like this lazy init is a perf problem in tab switching hot path
	instance.__updater = getClassComponentUpdater()
	workInProgress.stateNode = instance
	-- The instance needs access to the fiber so that it can schedule updates
	setInstance(instance, workInProgress)
	if __DEV__ then
		instance._reactInternalInstance = fakeInternalInstance
	end
end

local function constructClassInstance(workInProgress: Fiber, ctor: any, props: any): any
	local isLegacyContextConsumer = false
	local unmaskedContext = emptyContextObject
	local context = emptyContextObject
	local contextType = ctor.contextType

	if __DEV__ then
		-- deviation: `ctor` is actually a table, in our case; use normal indexing
		if ctor["contextType"] ~= nil then
			-- ROBLOX TODO: Double-check this boolean for accuracy
			local isValid =
				-- Allow nil for conditional declaration
				contextType == nil or (contextType["$$typeof"] == REACT_CONTEXT_TYPE and contextType._context == nil) -- Not a <Context.Consumer>

			if not isValid and not didWarnAboutInvalidateContextType[ctor] then
				didWarnAboutInvalidateContextType[ctor] = true

				local addendum = ""
				if contextType == nil then
					addendum =
						-- ROBLOX deviation: s/undefined/nil
						" However, it is set to nil. " .. "This can be caused by a typo or by mixing up named and default imports. " .. "This can also happen due to a circular dependency, so " .. "try moving the createContext() call to a separate file."
				elseif type(contextType) ~= "table" then
					addendum = " However, it is set to a " .. type(contextType) .. "."
				elseif contextType["$$typeof"] == REACT_PROVIDER_TYPE then
					addendum = " Did you accidentally pass the Context.Provider instead?"
				elseif contextType._context ~= nil then
					-- <Context.Consumer>
					addendum = " Did you accidentally pass the Context.Consumer instead?"
				else
					addendum ..= " However, it is set to an object with keys {"
					for key, _ in contextType do
						addendum ..= key .. ", "
					end
					addendum ..= "}."
				end
				console.error(
					"%s defines an invalid contextType. "
						.. "contextType should point to the Context object returned by React.createContext().%s",
					getComponentName(ctor) or "Component",
					addendum
				)
			end
		end
	end

	-- ROBLOX performance: check for nil first to avoid typeof when possible
	if contextType ~= nil and type(contextType) == "table" then
		context = readContext(contextType)
	elseif not disableLegacyContext then
		unmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		local contextTypes = ctor.contextTypes
		isLegacyContextConsumer = contextTypes ~= nil
		context = isLegacyContextConsumer
				and getMaskedContext(workInProgress, unmaskedContext)
			or emptyContextObject
	end

	-- Instantiate twice to help detect side-effects.
	if __DEV__ then
		if
			debugRenderPhaseSideEffectsForStrictMode
			and bit32.band(workInProgress.mode, StrictMode) ~= 0
		then
			disableLogs()
			-- deviation: ctor will actually refer to a class component, we use the
			-- `__ctor` function that it exposes
			local ok, result = xpcall(ctor.__ctor, describeError, props, context) -- eslint-disable-line no-new
			-- finally
			reenableLogs()

			if not ok then
				error(result)
			end
		end
	end

	-- deviation: ctor will actually refer to a class component, we use the
	-- `__ctor` function that it exposes
	local instance = ctor.__ctor(props, context)
	-- deviation: no need to worry about undefined
	-- local state = (workInProgress.memoizedState =
	--   instance.state ~= nil and instance.state ~= undefined
	--     ? instance.state
	--     : nil)
	workInProgress.memoizedState = instance.state
	local state = workInProgress.memoizedState
	adoptClassInstance(workInProgress, instance)

	if __DEV__ then
		-- ROBLOX deviation: Instead of checking if state is nil, we check if it is our
		-- UninitializedState singleton.
		if
			type(ctor.getDerivedStateFromProps) == "function"
			and state == UninitializedState
		then
			local componentName = getComponentName(ctor) or "Component"
			if not didWarnAboutUninitializedState[componentName] then
				didWarnAboutUninitializedState[componentName] = true
				-- ROBLOX deviation: message adjusted for accuracy with Lua "class" components
				console.error(
					"`%s` uses `getDerivedStateFromProps` but its initial state has not been initialized. "
						.. "This is not recommended. Instead, define the initial state by "
						.. "passing an object to `self:setState` in the `init` method of `%s`. "
						.. "This ensures that `getDerivedStateFromProps` arguments have a consistent shape.",
					componentName,
					-- deviation: no need to worry about undefined
					-- instance.state == nil and 'nil' or 'undefined',
					componentName
				)
			end
		end

		-- If new component APIs are defined, "unsafe" lifecycles won't be called.
		-- Warn about these lifecycles if they are present.
		-- Don't warn about react-lifecycles-compat polyfilled methods though.
		if
			type(ctor.getDerivedStateFromProps) == "function"
			or type(instance.getSnapshotBeforeUpdate) == "function"
		then
			local foundWillMountName = nil
			local foundWillReceivePropsName = nil
			local foundWillUpdateName = nil
			if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillMount) == "function" -- and
				-- instance.componentWillMount.__suppressDeprecationWarning ~= true
			then
				foundWillMountName = "componentWillMount"
			elseif type(instance.UNSAFE_componentWillMount) == "function" then
				foundWillMountName = "UNSAFE_componentWillMount"
			end
			if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillReceiveProps) == "function" -- and
				-- instance.componentWillReceiveProps.__suppressDeprecationWarning ~= true
			then
				foundWillReceivePropsName = "componentWillReceiveProps"
			elseif type(instance.UNSAFE_componentWillReceiveProps) == "function" then
				foundWillReceivePropsName = "UNSAFE_componentWillReceiveProps"
			end
			if
				-- ROBLOX FIXME: This won't work! Lua functions can't have properties
				type(instance.componentWillUpdate) == "function" -- and
				-- instance.componentWillUpdate.__suppressDeprecationWarning ~= true
			then
				foundWillUpdateName = "componentWillUpdate"
			elseif type(instance.UNSAFE_componentWillUpdate) == "function" then
				foundWillUpdateName = "UNSAFE_componentWillUpdate"
			end
			if
				foundWillMountName ~= nil
				or foundWillReceivePropsName ~= nil
				or foundWillUpdateName ~= nil
			then
				local componentName = getComponentName(ctor) or "Component"
				local newApiName
				if type(ctor.getDerivedStateFromProps) == "function" then
					newApiName = "getDerivedStateFromProps()"
				else
					newApiName = "getSnapshotBeforeUpdate()"
				end

				local willMountName
				if foundWillMountName ~= nil then
					willMountName = ("\n  " .. tostring(foundWillMountName))
				else
					willMountName = ""
				end

				local willReceievePropsName
				if foundWillReceivePropsName ~= nil then
					willReceievePropsName = (
						"\n  " .. tostring(foundWillReceivePropsName)
					)
				else
					willReceievePropsName = ""
				end

				local willUpdateName
				if foundWillUpdateName ~= nil then
					willUpdateName = "\n  " .. tostring(foundWillUpdateName)
				else
					willUpdateName = ""
				end

				if not didWarnAboutLegacyLifecyclesAndDerivedState[componentName] then
					didWarnAboutLegacyLifecyclesAndDerivedState[componentName] = true
					console.error(
						"Unsafe legacy lifecycles will not be called for components using new component APIs.\n\n"
							.. "%s uses %s but also contains the following legacy lifecycles:%s%s%s\n\n"
							.. "The above lifecycles should be removed. Learn more about this warning here:\n"
							.. "https://reactjs.org/link/unsafe-component-lifecycles",
						componentName,
						newApiName,
						willMountName,
						willReceievePropsName,
						willUpdateName
					)
				end
			end
		end
	end

	-- Cache unmasked context so we can avoid recreating masked context unless necessary.
	-- ReactFiberContext usually updates this cache but can't for newly-created instances.
	if isLegacyContextConsumer then
		cacheContext(workInProgress, unmaskedContext, context)
	end

	return instance
end

local function callComponentWillMount(workInProgress, instance)
	local oldState = instance.state

	if
		instance.componentWillMount ~= nil
		and type(instance.componentWillMount) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:componentWillMount()
	end
	-- ROBLOX TODO: Should we really run both of these?
	if
		instance.UNSAFE_componentWillMount ~= nil
		and type(instance.UNSAFE_componentWillMount) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:UNSAFE_componentWillMount()
	end

	if oldState ~= instance.state then
		if __DEV__ then
			console.error(
				"%s.componentWillMount(): Assigning directly to this.state is "
					.. "deprecated (except inside a component's "
					.. "constructor). Use setState instead.",
				getComponentName(workInProgress.type) or "Component"
			)
		end
		getClassComponentUpdater().enqueueReplaceState(instance, instance.state)
	end
end

function callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
	local oldState = instance.state
	if
		instance.componentWillReceiveProps ~= nil
		and type(instance.componentWillReceiveProps) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:componentWillReceiveProps(newProps, nextContext)
	end
	if
		instance.UNSAFE_componentWillReceiveProps ~= nil
		and type(instance.UNSAFE_componentWillReceiveProps) == "function"
	then
		-- deviation: Call with ":" so that the method receives self
		instance:UNSAFE_componentWillReceiveProps(newProps, nextContext)
	end

	if instance.state ~= oldState then
		if __DEV__ then
			local componentName = getComponentName(workInProgress.type) or "Component"
			if not didWarnAboutStateAssignmentForComponent[componentName] then
				didWarnAboutStateAssignmentForComponent[componentName] = true
				console.error(
					"%s.componentWillReceiveProps(): Assigning directly to "
						.. "this.state is deprecated (except inside a component's "
						.. "constructor). Use setState instead.",
					componentName
				)
			end
		end
		getClassComponentUpdater().enqueueReplaceState(instance, instance.state)
	end
end

-- Invokes the mount life-cycles on a previously never rendered instance.
local function mountClassInstance(
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
)
	if __DEV__ then
		checkClassInstance(workInProgress, ctor, newProps)
	end

	local instance = workInProgress.stateNode
	instance.props = newProps
	instance.state = workInProgress.memoizedState
	-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
	-- instance.refs = emptyRefsObject
	instance.__refs = emptyRefsObject

	initializeUpdateQueue(workInProgress)

	-- ROBLOX deviation: don't access field on a function
	local contextType
	if type(ctor) == "table" then
		contextType = ctor.contextType
	end
	-- ROBLOX deviation: nil check first so we don't call typeof() unnecessarily
	if contextType ~= nil and type(contextType) == "table" then
		instance.context = readContext(contextType)
	elseif disableLegacyContext then
		instance.context = emptyContextObject
	else
		local unmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		instance.context = getMaskedContext(workInProgress, unmaskedContext)
	end

	if __DEV__ then
		if instance.state == newProps then
			local componentName = getComponentName(ctor) or "Component"
			if not didWarnAboutDirectlyAssigningPropsToState[componentName] then
				didWarnAboutDirectlyAssigningPropsToState[componentName] = true
				console.error(
					"%s: It is not recommended to assign props directly to state "
						.. "because updates to props won't be reflected in state. "
						.. "In most cases, it is better to use props directly.",
					componentName
				)
			end
		end

		if bit32.band(workInProgress.mode, StrictMode) ~= 0 then
			ReactStrictModeWarnings.recordLegacyContextWarning(workInProgress, instance)
		end

		if warnAboutDeprecatedLifecycles then
			ReactStrictModeWarnings.recordUnsafeLifecycleWarnings(
				workInProgress,
				instance
			)
		end
	end

	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	instance.state = workInProgress.memoizedState

	-- ROBLOX deviation START: don't access field on a function, cache typeofCtor
	local typeofCtor = type(ctor)
	local getDerivedStateFromProps
	if type(ctor) == "table" then
		getDerivedStateFromProps = ctor.getDerivedStateFromProps
	end
	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		instance.state = workInProgress.memoizedState
	end

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	-- ROBLOX deviation: don't access fields on a function
	if
		typeofCtor == "table"
		and type(ctor.getDerivedStateFromProps) ~= "function"
		and type(instance.getSnapshotBeforeUpdate) ~= "function"
		and (
			type(instance.UNSAFE_componentWillMount) == "function"
			or type(instance.componentWillMount) == "function"
		)
	then
		callComponentWillMount(workInProgress, instance)
		-- If we had additional state updates during this life-cycle, let's
		-- process them now.
		processUpdateQueue(workInProgress, newProps, instance, renderLanes)
		instance.state = workInProgress.memoizedState
	end

	if type(instance.componentDidMount) == "function" then
		if __DEV__ and enableDoubleInvokingEffects then
			workInProgress.flags =
				bit32.bor(workInProgress.flags, bit32.bor(MountLayoutDev, Update))
		else
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
	end
end

function resumeMountClassInstance(
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
): boolean
	local instance = workInProgress.stateNode

	local oldProps = workInProgress.memoizedProps
	instance.props = oldProps

	local oldContext = instance.context
	local contextType = ctor.contextType
	local nextContext = emptyContextObject

	-- ROBLOX performance: check for nil first to avoid typeof when possible
	if contextType ~= nil and type(contextType) == "table" then
		nextContext = readContext(contextType)
	elseif not disableLegacyContext then
		local nextLegacyUnmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		nextContext = getMaskedContext(workInProgress, nextLegacyUnmaskedContext)
	end

	local getDerivedStateFromProps = ctor.getDerivedStateFromProps
	local hasNewLifecycles = type(getDerivedStateFromProps) == "function"
		or type(instance.getSnapshotBeforeUpdate) == "function"

	-- Note: During these life-cycles, instance.props/instance.state are what
	-- ever the previously attempted to render - not the "current". However,
	-- during componentDidUpdate we pass the "current" props.

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	if
		not hasNewLifecycles
		and (
			type(instance.UNSAFE_componentWillReceiveProps) == "function"
			or type(instance.componentWillReceiveProps) == "function"
		)
	then
		if oldProps ~= newProps or oldContext ~= nextContext then
			callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
		end
	end

	resetHasForceUpdateBeforeProcessing()

	local oldState = workInProgress.memoizedState
	instance.state = oldState
	local newState = oldState
	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	newState = workInProgress.memoizedState
	if
		oldProps == newProps
		and oldState == newState
		and not hasContextChanged()
		and not checkHasForceUpdateAfterProcessing()
	then
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		return false
	end

	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		newState = workInProgress.memoizedState
	end

	local shouldUpdate = checkHasForceUpdateAfterProcessing()
		or checkShouldComponentUpdate(
			workInProgress,
			ctor,
			oldProps,
			newProps,
			oldState,
			newState,
			nextContext
		)

	if shouldUpdate then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			not hasNewLifecycles
			and (
				type(instance.UNSAFE_componentWillMount) == "function"
				or type(instance.componentWillMount) == "function"
			)
		then
			if type(instance.componentWillMount) == "function" then
				instance:componentWillMount()
			end
			if type(instance.UNSAFE_componentWillMount) == "function" then
				instance:UNSAFE_componentWillMount()
			end
		end
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
	else
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if type(instance.componentDidMount) == "function" then
			if __DEV__ and enableDoubleInvokingEffects then
				workInProgress.flags =
					bit32.bor(workInProgress.flags, MountLayoutDev, Update)
			else
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end

		-- If shouldComponentUpdate returned false, we should still update the
		-- memoized state to indicate that this work can be reused.
		workInProgress.memoizedProps = newProps
		workInProgress.memoizedState = newState
	end

	-- Update the existing instance's state, props, and context pointers even
	-- if shouldComponentUpdate returns false.
	instance.props = newProps
	instance.state = newState
	instance.context = nextContext

	return shouldUpdate
end

-- Invokes the update life-cycles and returns false if it shouldn't rerender.
local function updateClassInstance(
	current: Fiber,
	workInProgress: Fiber,
	ctor: any,
	newProps: any,
	renderLanes: Lanes
): boolean
	local instance = workInProgress.stateNode

	cloneUpdateQueue(current, workInProgress)

	local unresolvedOldProps = workInProgress.memoizedProps
	local oldProps = if workInProgress.type == workInProgress.elementType
		then unresolvedOldProps
		else resolveDefaultProps(workInProgress.type, unresolvedOldProps)
	instance.props = oldProps
	local unresolvedNewProps = workInProgress.pendingProps

	local oldContext = instance.context
	local contextType
	local getDerivedStateFromProps
	-- ROBLOX deviation: don't access fields on a function
	if type(ctor) == "table" then
		contextType = ctor.contextType
		getDerivedStateFromProps = ctor.getDerivedStateFromProps
	end
	local nextContext = emptyContextObject
	if type(contextType) == "table" then
		nextContext = readContext(contextType)
	elseif not disableLegacyContext then
		local nextUnmaskedContext = getUnmaskedContext(workInProgress, ctor, true)
		nextContext = getMaskedContext(workInProgress, nextUnmaskedContext)
	end

	local hasNewLifecycles = (
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	)
		or (
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		)

	-- Note: During these life-cycles, instance.props/instance.state are what
	-- ever the previously attempted to render - not the "current". However,
	-- during componentDidUpdate we pass the "current" props.

	-- In order to support react-lifecycles-compat polyfilled components,
	-- Unsafe lifecycles should not be invoked for components using the new APIs.
	if
		not hasNewLifecycles
		and (
			(
				instance.UNSAFE_componentWillReceiveProps ~= nil
				and type(instance.UNSAFE_componentWillReceiveProps) == "function"
			)
			or (
				instance.componentWillReceiveProps ~= nil
				and type(instance.componentWillReceiveProps) == "function"
			)
		)
	then
		if unresolvedOldProps ~= unresolvedNewProps or oldContext ~= nextContext then
			callComponentWillReceiveProps(workInProgress, instance, newProps, nextContext)
		end
	end

	resetHasForceUpdateBeforeProcessing()

	local oldState = workInProgress.memoizedState
	instance.state = oldState
	local newState = instance.state
	processUpdateQueue(workInProgress, newProps, instance, renderLanes)
	newState = workInProgress.memoizedState

	if
		unresolvedOldProps == unresolvedNewProps
		and oldState == newState
		and not hasContextChanged()
		and not checkHasForceUpdateAfterProcessing()
	then
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end
		return false
	end

	if
		getDerivedStateFromProps ~= nil
		and type(getDerivedStateFromProps) == "function"
	then
		applyDerivedStateFromProps(
			workInProgress,
			ctor,
			getDerivedStateFromProps,
			newProps
		)
		newState = workInProgress.memoizedState
	end

	local shouldUpdate = checkHasForceUpdateAfterProcessing()
		or checkShouldComponentUpdate(
			workInProgress,
			ctor,
			oldProps,
			newProps,
			oldState,
			newState,
			nextContext
		)

	if shouldUpdate then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			not hasNewLifecycles
			and (
				(
					instance.UNSAFE_componentWillUpdate ~= nil
					and type(instance.UNSAFE_componentWillUpdate) == "function"
				)
				or (
					instance.componentWillUpdate ~= nil
					and type(instance.componentWillUpdate) == "function"
				)
			)
		then
			if
				instance.componentWillUpdate ~= nil
				and type(instance.componentWillUpdate) == "function"
			then
				-- deviation: Call with ":" so that the method receives self
				instance:componentWillUpdate(newProps, newState, nextContext)
			end
			if
				instance.UNSAFE_componentWillUpdate ~= nil
				and type(instance.UNSAFE_componentWillUpdate) == "function"
			then
				-- deviation: Call with ":" so that the method receives self
				instance:UNSAFE_componentWillUpdate(newProps, newState, nextContext)
			end
		end
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
		end
	else
		-- If an update was already in progress, we should schedule an Update
		-- effect even though we're bailing out, so that cWU/cDU are called.
		if
			instance.componentDidUpdate ~= nil
			and type(instance.componentDidUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			instance.getSnapshotBeforeUpdate ~= nil
			and type(instance.getSnapshotBeforeUpdate) == "function"
		then
			if
				unresolvedOldProps ~= current.memoizedProps
				or oldState ~= current.memoizedState
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end

		-- If shouldComponentUpdate returned false, we should still update the
		-- memoized props/state to indicate that this work can be reused.
		workInProgress.memoizedProps = newProps
		workInProgress.memoizedState = newState
	end

	-- Update the existing instance's state, props, and context pointers even
	-- if shouldComponentUpdate returns false.
	instance.props = newProps
	instance.state = newState
	instance.context = nextContext

	return shouldUpdate
end

return {
	adoptClassInstance = adoptClassInstance,
	constructClassInstance = constructClassInstance,
	mountClassInstance = mountClassInstance,
	resumeMountClassInstance = resumeMountClassInstance,
	updateClassInstance = updateClassInstance,

	applyDerivedStateFromProps = applyDerivedStateFromProps,
	-- deviation: this should be safe to export, since it gets assigned only once
	emptyRefsObject = emptyRefsObject,
}
