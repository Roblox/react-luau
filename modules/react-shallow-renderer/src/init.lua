--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of self source tree.
 *
 *
 ]]

local Packages = script.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local Error = LuauPolyfill.Error
local Array = LuauPolyfill.Array

local React = require(Packages.React)

local ReactIs = require(Packages.ReactIs)
local isForwardRef = ReactIs.isForwardRef
local isMemo = ReactIs.isMemo
local ForwardRef = ReactIs.ForwardRef

local ReactComponentStackFrame = require(Packages.Shared).ReactComponentStackFrame
local describeComponentFrame = ReactComponentStackFrame.describeComponentFrame
local getComponentName = require(Packages.Shared).getComponentName
local shallowEqual = require(Packages.Shared).shallowEqual
local checkPropTypes = require(Packages.Shared).checkPropTypes
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local consoleWithStackDev = require(Packages.Shared).consoleWithStackDev
local is = require(Packages.Shared).objectIs

local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

local RE_RENDER_LIMIT: number = 25

local emptyObject = {}
if _G.__DEV__ then
	Object.freeze(emptyObject)
end

-- In DEV, self is the name of the currently executing primitive hook
-- ROBLOX deviation: this is a weird unassigned variable bug present in upstream
local currentHookNameInDev = "currentHookNameInDev"

local function areHookInputsEqual(nextDeps, prevDeps)
	if prevDeps == nil then
		if _G.__DEV__ then
			consoleWithStackDev.error(
				"%s received a final argument during self render, but not during "
					.. "the previous render. Even though the final argument is optional, "
					.. "its type cannot change between renders.",
				currentHookNameInDev
			)
		end
		return false
	end

	if _G.__DEV__ then
		-- Don't bother comparing lengths in prod because these arrays should be
		-- passed inline.
		if #nextDeps ~= #prevDeps then
			consoleWithStackDev.error(
				"The final argument passed to %s changed size between renders. The "
					.. "order and size of self array must remain constant.\n\n"
					.. "Previous: %s\n"
					.. "Incoming: %s",
				currentHookNameInDev,
				table.concat(nextDeps, ", "),
				table.concat(prevDeps, ", ")
			)
		end
	end
	local maxValue = math.min(#prevDeps, #nextDeps)
	for i = 1, maxValue do
		if is(nextDeps[i], prevDeps[i]) then
			continue
		end
		return false
	end
	return true
end

-- ROBLOX deviation: bind functions to upvalue
function createUpdater(renderer)
	local updater = {
		_renderer = renderer,
		_callbacks = {},
	}

	function updater._enqueueCallback(callback, publicInstance)
		if typeof(callback) == "function" and publicInstance then
			table.insert(updater._callbacks, {
				callback = callback,
				publicInstance = publicInstance,
			})
		end
	end

	function updater._invokeCallbacks()
		local callbacks = updater._callbacks
		updater._callbacks = {}

		for _, value in pairs(callbacks) do
			local callback = value.callback
			local publicInstance = value.publicInstance

			callback(publicInstance)
		end
	end

	function updater.isMounted(publicInstance)
		return not not updater._renderer._element
	end

	function updater.enqueueForceUpdate(publicInstance, callback, _callerName)
		updater._enqueueCallback(callback, publicInstance)
		updater._renderer._forcedUpdate = true
		updater._renderer:render(updater._renderer._element, updater._renderer._context)
	end

	function updater.enqueueReplaceState(
		publicInstance,
		completeState,
		callback,
		_callerName
	)
		updater._enqueueCallback(callback, publicInstance)
		updater._renderer._newState = completeState
		updater._renderer:render(updater._renderer._element, updater._renderer._context)
	end

	function updater.enqueueSetState(publicInstance, partialState, callback, _callerName)
		updater._enqueueCallback(callback, publicInstance)
		local currentState = updater._renderer._newState or publicInstance.state

		if typeof(partialState) == "function" then
			-- ROBLOX deviation: in React, the partial state function is called on the
			-- publicInstance, meaning that `this` is accessible, and scoped correctly,
			-- inside of the state updater; with Lua, you would need to define your
			-- functions differently, by explicitly adding the first argument for 'self'
			-- for this to work the same way
			partialState = partialState(currentState, publicInstance.props)
		end

		-- Null and undefined are treated as no-ops.
		if partialState == nil then
			return
		end

		updater._renderer._newState = Object.assign({}, currentState, partialState)

		updater._renderer:render(updater._renderer._element, updater._renderer._context)
	end

	return updater
end

function createHook()
	return {
		memoizedState = nil,
		queue = nil,
		next = nil,
	}
end

function basicStateReducer(state, action)
	if typeof(action) == "function" then
		return action(state)
	else
		return action
	end
end

-- ROBLOX deviation: hoist declaration
local currentlyValidatingElement = nil

local ReactShallowRenderer = {}
ReactShallowRenderer.__index = ReactShallowRenderer

-- ROBLOX deviation: Collapse static create function and constructor together; since
-- Lua only has the former anyway
function ReactShallowRenderer.createRenderer()
	local self = setmetatable({}, ReactShallowRenderer)
	self:_reset()

	return self
end

function ReactShallowRenderer:_reset()
	self._context = nil
	self._element = nil
	self._instance = nil
	self._newState = nil
	self._rendered = nil
	self._rendering = false
	self._forcedUpdate = false
	self._updater = createUpdater(self)
	self._dispatcher = self:_createDispatcher()
	self._workInProgressHook = nil
	self._firstWorkInProgressHook = nil
	self._isReRender = false
	self._didScheduleRenderPhaseUpdate = false
	self._renderPhaseUpdates = nil
	self._numberOfReRenders = 0
end

function ReactShallowRenderer:_validateCurrentlyRenderingComponent()
	if not (self._rendering and not self._instance) then
		error(
			Error(
				[[Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for one of the following reasons:
1. You might have mismatching versions of React and the renderer (such as React DOM)
2. You might be breaking the Rules of Hooks
3. You might have more than one copy of React in the same app
See https://fb.me/react-invalid-hook-call for tips about how to debug and fix self problem.]]
			)
		)
	end
end

function ReactShallowRenderer:_createDispatcher()
	-- ROBLOX deviation: This function returns two values instead of an array. Lua does
	-- not support destructuring, but _does_ support multiple return values
	local function useReducer(reducer, initialArg, init)
		self:_validateCurrentlyRenderingComponent()
		self:_createWorkInProgressHook()
		local workInProgressHook = self._workInProgressHook

		if self._isReRender then
			-- This is a re-render.
			local queue = workInProgressHook.queue
			local dispatch = queue.dispatch
			if self._numberOfReRenders > 0 then
				-- Apply the new render phase updates to the previous current hook.
				if self._renderPhaseUpdates ~= nil then
					-- Render phase updates are stored in a map of queue -> linked list
					local firstRenderPhaseUpdate = self._renderPhaseUpdates[queue]
					if firstRenderPhaseUpdate ~= nil then
						self._renderPhaseUpdates[queue] = nil
						local newState = workInProgressHook.memoizedState
						local update = firstRenderPhaseUpdate
						repeat
							local action = update.action
							newState = reducer(newState, action)
							update = update.next
						until update == nil
						workInProgressHook.memoizedState = newState
						return newState, dispatch
					end
				end
				return workInProgressHook.memoizedState, dispatch
			end
			-- Process updates outside of render
			local newState = workInProgressHook.memoizedState
			local update = queue.first
			if update ~= nil then
				repeat
					local action = update.action
					newState = reducer(newState, action)
					update = update.next
				until update == nil
				queue.first = nil
				workInProgressHook.memoizedState = newState
			end
			return newState, dispatch
		else
			local initialState
			if reducer == basicStateReducer then
				-- Special case for `useState`.
				if typeof(initialArg) == "function" then
					initialState = initialArg()
				else
					initialState = initialArg
				end
			else
				if init ~= nil then
					initialState = init(initialArg)
				else
					initialState = initialArg
				end
			end
			workInProgressHook.memoizedState = initialState
			workInProgressHook.queue = {
				first = nil,
				dispatch = nil,
			}
			local queue = workInProgressHook.queue
			queue.dispatch = function(...)
				self:_dispatchAction(queue, ...)
			end
			local dispatch = queue.dispatch
			return workInProgressHook.memoizedState, dispatch
		end
	end

	local function useState(initialState)
		return useReducer(
			basicStateReducer,
			-- useReducer has a special case to support lazy useState initializers
			initialState
		)
	end

	local function useMemo(nextCreate, deps)
		self:_validateCurrentlyRenderingComponent()
		self:_createWorkInProgressHook()

		local nextDeps = deps

		if
			self._workInProgressHook ~= nil
			and self._workInProgressHook.memoizedState ~= nil
		then
			local prevState = self._workInProgressHook.memoizedState
			local prevDeps = prevState[2]
			if nextDeps ~= nil then
				if areHookInputsEqual(nextDeps, prevDeps) then
					return prevState[1]
				end
			end
		end

		local nextValue = nextCreate()
		self._workInProgressHook.memoizedState = { nextValue, nextDeps }
		return nextValue
	end

	local function useRef(initialValue)
		self:_validateCurrentlyRenderingComponent()
		self:_createWorkInProgressHook()
		local previousRef = self._workInProgressHook.memoizedState
		if previousRef == nil then
			local ref = { current = initialValue }
			if _G.__DEV__ then
				Object.seal(ref)
			end
			self._workInProgressHook.memoizedState = ref
			return ref
		else
			return previousRef
		end
	end

	local function readContext(context, _observedBits)
		return context._currentValue
	end

	local function noOp()
		self:_validateCurrentlyRenderingComponent()
	end

	local function identity(fn)
		return fn
	end

	local function useResponder(responder, props)
		return {
			props = props,
			responder = responder,
		}
	end

	-- TODO: implement if we decide to keep the shallow renderer
	local function useTransition(_config)
		self:_validateCurrentlyRenderingComponent()
		local startTransition = function(callback)
			callback()
		end
		return { startTransition, false }
	end

	-- TODO: implement if we decide to keep the shallow renderer
	local function useDeferredValue(value, _config)
		self:_validateCurrentlyRenderingComponent()
		return value
	end

	return {
		readContext = readContext,
		useCallback = identity,
		useContext = function(context)
			self:_validateCurrentlyRenderingComponent()
			return readContext(context)
		end,
		useDebugValue = noOp,
		useEffect = noOp,
		useImperativeHandle = noOp,
		useLayoutEffect = noOp,
		useMemo = useMemo,
		useReducer = useReducer,
		useRef = useRef,
		useState = useState,
		useResponder = useResponder,
		useTransition = useTransition,
		useDeferredValue = useDeferredValue,
	}
end

function ReactShallowRenderer:_dispatchAction(queue, action)
	local numberOfRenders: number = self._numberOfReRenders
	if numberOfRenders > RE_RENDER_LIMIT then
		error(
			Error(
				"Too many re-renders. React limits the number of renders to prevent an infinite loop."
			)
		)
	end

	if self._rendering then
		-- This is a render phase update. Stash it in a lazily-created map of
		-- queue -> linked list of updates. After self render pass, we'll restart
		-- and apply the stashed updates on top of the work-in-progress hook.
		self._didScheduleRenderPhaseUpdate = true
		local update = {
			action = action,
			next = nil,
		}
		local renderPhaseUpdates = self._renderPhaseUpdates
		if renderPhaseUpdates == nil then
			renderPhaseUpdates = {}
			self._renderPhaseUpdates = renderPhaseUpdates
		end
		local firstRenderPhaseUpdate = renderPhaseUpdates[queue]
		if firstRenderPhaseUpdate == nil then
			renderPhaseUpdates[queue] = update
		else
			-- Append the update to the end of the list.
			local lastRenderPhaseUpdate = firstRenderPhaseUpdate
			while lastRenderPhaseUpdate.next ~= nil do
				lastRenderPhaseUpdate = lastRenderPhaseUpdate.next
			end
			lastRenderPhaseUpdate.next = update
		end
	else
		local update = {
			action = action,
			next = nil,
		}

		-- Append the update to the end of the list.
		local last = queue.first
		if last == nil then
			queue.first = update
		else
			while last.next ~= nil do
				last = last.next
			end
			last.next = update
		end

		-- Re-render now.
		self:render(self._element, self._context)
	end
end

function ReactShallowRenderer:_createWorkInProgressHook()
	if self._workInProgressHook == nil then
		-- This is the first hook in the list
		if self._firstWorkInProgressHook == nil then
			self._isReRender = false
			self._workInProgressHook = createHook()
			self._firstWorkInProgressHook = self._workInProgressHook
		else
			-- There's already a work-in-progress. Reuse it.
			self._isReRender = true
			self._workInProgressHook = self._firstWorkInProgressHook
		end
	else
		if self._workInProgressHook.next == nil then
			self._isReRender = false
			-- Append to the end of the list
			self._workInProgressHook.next = createHook()
			self._workInProgressHook = self._workInProgressHook.next
		else
			-- There's already a work-in-progress. Reuse it.
			self._isReRender = true
			self._workInProgressHook = self._workInProgressHook.next
		end
	end
	return self._workInProgressHook
end

function ReactShallowRenderer:_finishHooks(element, context)
	if self._didScheduleRenderPhaseUpdate then
		-- Updates were scheduled during the render phase. They are stored in
		-- the `renderPhaseUpdates` map. Call the component again, reusing the
		-- work-in-progress hooks and applying the additional updates on top. Keep
		-- restarting until no more updates are scheduled.
		self._didScheduleRenderPhaseUpdate = false
		self._numberOfReRenders += 1

		-- Start over from the beginning of the list
		self._workInProgressHook = nil
		self._rendering = false
		self:render(element, context)
	else
		self._workInProgressHook = nil
		self._renderPhaseUpdates = nil
		self._numberOfReRenders = 0
	end
end

function ReactShallowRenderer:getMountedInstance()
	return self._instance
end

function ReactShallowRenderer:getRenderOutput()
	return self._rendered
end

function ReactShallowRenderer:render(element, maybeContext)
	local context = maybeContext or emptyObject
	if not React.isValidElement(element) then
		local message = ""
		if
			typeof(element) == "function"
			or (typeof(element) == "table" and element.__componentName ~= nil)
		then
			message = " Instead of passing a component class, make sure to instantiate "
				.. "it by passing it to React.createElement."
		end
		error(
			Error(
				string.format(
					"ReactShallowRenderer render(): Invalid component element.%s",
					message
				)
			)
		)
	end
	-- Show a special message for host elements since it's a common case.
	if not (typeof(element.type) ~= "string") then
		local elementType = element.type
		error(
			Error(
				string.format(
					"ReactShallowRenderer render(): Shallow rendering works only with custom components, not primitives (%s). Instead of calling `.render(el)` and inspecting the rendered output, look at `el.props` directly instead.",
					tostring(elementType)
				)
			)
		)
	end
	-- ROBLOX deviation: include check for isReactComponent since our "class" components
	-- aren't functions like React's are
	if
		not (
			isForwardRef(element)
			or typeof(element.type) == "function"
			or (typeof(element.type) == "table" and element.type.isReactComponent == true)
			or isMemo(element)
		)
	then
		local elementType = typeof(element.type)
		if Array.isArray(element.type) then
			elementType = "array"
		end
		error(
			Error(
				string.format(
					"ReactShallowRenderer render(): Shallow rendering works only with custom components, but the provided element type was `%s`.",
					elementType
				)
			)
		)
	end

	if self._rendering then
		return
	end
	if self._element ~= nil and self._element.type ~= element.type then
		self:_reset()
	end

	local elementType
	if isMemo(element) then
		elementType = element.type.type
	else
		elementType = element.type
	end

	local previousElement = self._element
	self._rendering = true
	self._element = element
	-- ROBLOX deviation: functions can't have properties in Lua, so we can't access
	-- `contextTypes` if `elementType` is a function; as far as I can tell, React
	-- doesn't support `contextTypes` on function components anyways, so the
	-- behavior should be compatible
	local contextTypes
	if typeof(elementType) == "table" then
		contextTypes = elementType.contextTypes
	end
	self._context = getMaskedContext(contextTypes, context)

	-- Inner memo component props aren't currently validated in createElement.
	local prevGetStack
	if _G.__DEV__ then
		prevGetStack = ReactDebugCurrentFrame.getCurrentStack
		ReactDebugCurrentFrame.getCurrentStack = getStackAddendum
	end
	local ok, result = pcall(function()
    if isMemo(element) and typeof(elementType) == "table" and (elementType.propTypes or elementType.validateProps) then
      currentlyValidatingElement = element
      -- ROBLOX deviation: adds support for legacy Roact's validateProps()
      checkPropTypes(
        elementType.propTypes,
        elementType.validateProps,
        element.props,
        'prop',
        getComponentName(elementType)
      )
    end

		if self._instance then
			self:_updateClassComponent(elementType, element, self._context)
		else
			if shouldConstruct(elementType) then
				-- ROBLOX deviation: we don't have 'new', so we need to enumerate the element
				-- types we can support
				if typeof(elementType) == "function" then
					self._instance = elementType(
						element.props,
						self._context,
						self._updater
					)
				else
					if elementType.isReactComponent then
						self._instance = elementType.__ctor(
							element.props,
							self._context,
							self._updater
						)
					end
				end
				if
					typeof(elementType) == "table"
					and typeof(elementType.getDerivedStateFromProps) == "function"
				then
					local partialState = elementType.getDerivedStateFromProps(
						element.props,
						self._instance.state
					)
					if partialState ~= nil then
						self._instance.state = Object.assign(
							{},
							self._instance.state,
							partialState
						)
					end
				end

        if typeof(elementType) == "table" and (elementType.contextTypes or elementType.validateProps) then
          currentlyValidatingElement = element
          -- ROBLOX deviation: adds support for legacy Roact's validateProps()
          checkPropTypes(
            elementType.contextTypes,
            elementType.validateProps,
            self._context,
            'context',
            getName(elementType, self._instance)
          )

          currentlyValidatingElement = nil
        end

				self:_mountClassComponent(elementType, element, self._context)
			else
				local shouldRender = true
				if isMemo(element) and previousElement ~= nil then
					-- This is a Memo component that is being re-rendered.
					local compare = element.type.compare or shallowEqual
					if compare(previousElement.props, element.props) then
						shouldRender = false
					end
				end
				if shouldRender then
					local prevDispatcher = ReactCurrentDispatcher.current
					ReactCurrentDispatcher.current = self._dispatcher
					local ok, result = pcall(function()
						-- elementType could still be a ForwardRef if it was
						-- nested inside Memo.
						if
							typeof(elementType) == "table"
							and elementType["$$typeof"] == ForwardRef
						then
							if typeof(elementType.render) ~= "function" then
								error(
									Error(
										string.format(
											"forwardRef requires a render function but was given %s.",
											typeof(elementType.render)
										)
									)
								)
							end
							self._rendered = elementType.render(
								element.props,
								element.ref
							)
						else
							self._rendered = elementType(element.props, self._context)
						end
					end)

					-- finally
					ReactCurrentDispatcher.current = prevDispatcher

					-- no catch, so we throw again
					if not ok then
						error(result)
					end

					self:_finishHooks(element, context)
				end
			end
		end
	end)

	-- finally
	if _G.__DEV__ then
		ReactDebugCurrentFrame.getCurrentStack = prevGetStack
	end

	-- no catch, so we throw after resolving the 'finally'
	if not ok then
		error(result)
	end

	self._rendering = false
	self._updater._invokeCallbacks()

	return self:getRenderOutput()
end

function ReactShallowRenderer:unmount()
	if self._instance then
		if typeof(self._instance.componentWillUnmount) == "function" then
			self._instance:componentWillUnmount()
		end
	end
	self:_reset()
end

function ReactShallowRenderer:_mountClassComponent(elementType, element, context)
	self._instance.context = context
	self._instance.props = element.props
	self._instance.state = self._instance.state or nil
	self._instance.__updater = self._updater

	if
		typeof(self._instance.UNSAFE_componentWillMount) == "function"
		or typeof(self._instance.componentWillMount) == "function"
	then
		local beforeState = self._newState

		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			typeof(elementType.getDerivedStateFromProps) ~= "function"
			and typeof(self._instance.getSnapshotBeforeUpdate) ~= "function"
		then
			if typeof(self._instance.componentWillMount) == "function" then
				self._instance:componentWillMount()
			end
			if typeof(self._instance.UNSAFE_componentWillMount) == "function" then
				self._instance:UNSAFE_componentWillMount()
			end
		end

		-- setState may have been called during cWM
		if beforeState ~= self._newState then
			self._instance.state = self._newState or emptyObject
		end
	end

	self._rendered = self._instance:render()
	-- Intentionally do not call componentDidMount()
	-- because DOM refs are not available.
end

function ReactShallowRenderer:_updateClassComponent(elementType, element, context)
	local props = element.props

	local oldState = self._instance.state or emptyObject
	local oldProps = self._instance.props

	if oldProps ~= props then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			typeof(elementType.getDerivedStateFromProps) ~= "function"
			and typeof(self._instance.getSnapshotBeforeUpdate) ~= "function"
		then
			if typeof(self._instance.componentWillReceiveProps) == "function" then
				self._instance:componentWillReceiveProps(props, context)
			end
			if typeof(self._instance.UNSAFE_componentWillReceiveProps) == "function" then
				self._instance:UNSAFE_componentWillReceiveProps(props, context)
			end
		end
	end

	-- Read state after cWRP in case it calls setState
	local state = self._newState or oldState
	if typeof(elementType.getDerivedStateFromProps) == "function" then
		local partialState = elementType.getDerivedStateFromProps(props, state)
		if partialState ~= nil then
			state = Object.assign({}, state, partialState)
		end
	end

	local shouldUpdate = true
	if self._forcedUpdate then
		shouldUpdate = true
		self._forcedUpdate = false
	elseif typeof(self._instance.shouldComponentUpdate) == "function" then
		shouldUpdate = not not self._instance:shouldComponentUpdate(props, state, context)
	elseif typeof(elementType) == "table" and elementType.isPureReactComponent then
		shouldUpdate = not shallowEqual(oldProps, props)
			or not shallowEqual(oldState, state)
	end

	if shouldUpdate then
		-- In order to support react-lifecycles-compat polyfilled components,
		-- Unsafe lifecycles should not be invoked for components using the new APIs.
		if
			typeof(elementType.getDerivedStateFromProps) ~= "function"
			and typeof(self._instance.getSnapshotBeforeUpdate) ~= "function"
		then
			if typeof(self._instance.componentWillUpdate) == "function" then
				self._instance:componentWillUpdate(props, state, context)
			end
			if typeof(self._instance.UNSAFE_componentWillUpdate) == "function" then
				self._instance:UNSAFE_componentWillUpdate(props, state, context)
			end
		end
	end

	self._instance.context = context
	self._instance.props = props
	self._instance.state = state
	self._newState = nil

	if shouldUpdate then
		self._rendered = self._instance:render()
	end
	-- Intentionally do not call componentDidUpdate()
	-- because DOM refs are not available.
end

function getDisplayName(element)
	if element == nil then
		return "#empty"
	elseif typeof(element) == "string" or typeof(element) == "number" then
		return "#text"
	elseif typeof(element.type) == "string" then
		return element.type
	else
		local elementType
		if isMemo(element) then
			elementType = element.type.type
		else
			elementType = element.type
		end
		return elementType.displayName or elementType.name or "Unknown"
	end
end

function getStackAddendum()
	local stack = ""
	if currentlyValidatingElement then
		local name = getDisplayName(currentlyValidatingElement)
		local owner = currentlyValidatingElement._owner
		stack ..= describeComponentFrame(
			name,
			currentlyValidatingElement._source,
			owner and getComponentName(owner.type)
		)
	end
	return stack
end

function getName(type, instance)
	local constructor = instance and instance.constructor
	return type.displayName
		or (constructor and constructor.displayName)
		or type.name
		or (constructor and constructor.name)
		or nil
end

function shouldConstruct(Component)
	return not not (typeof(Component) == "table" and Component.isReactComponent)
end

function getMaskedContext(contextTypes, unmaskedContext)
	if not contextTypes and not unmaskedContext then
		return emptyObject
	end
	if contextTypes and not unmaskedContext then
		return emptyObject
	end
	-- ROBLOX deviation: we can't mask context types for function components, so be 'unsafe' to make tests pass
	if not contextTypes and unmaskedContext then
		contextTypes = unmaskedContext
	end

	local context = {}
	for key, _ in pairs(contextTypes) do
		context[key] = unmaskedContext[key]
	end
	return context
end

return ReactShallowRenderer
