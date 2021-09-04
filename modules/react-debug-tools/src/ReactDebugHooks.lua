-- upstream: https://github.com/facebook/react/blob/17.0.1/packages/react-debug-tools/src/ReactDebugHooks.js
--[[*
	* Copyright (c) Facebook, Inc. and its affiliates.
	*
	* This source code is licensed under the MIT license found in the
	* LICENSE file in the root directory of this source tree.
   ]]

local Workspace = script.Parent
local Packages = Workspace.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object

-- ROBLOX TODO: work out a suitable implementation for this
local ErrorStackParser = {
	parse = function(stack)
		return stack:split("\n")
	end
}

-- ROBLOX FIXME: pass in a real host config, or make this able to use basic enums without initializing
local ReconcilerModule = require(Packages.ReactReconciler)({})
local ReactTypeOfMode = ReconcilerModule.ReactTypeOfMode
local NoMode = ReactTypeOfMode.NoMode
local SharedModule = require(Packages.Shared)
local ReactSharedInternals = SharedModule.ReactSharedInternals
local ReactSymbols = SharedModule.ReactSymbols
local REACT_OPAQUE_ID_TYPE = ReactSymbols.REACT_OPAQUE_ID_TYPE
local ReactWorkTags = ReconcilerModule.ReactWorkTags
local FunctionComponent = ReactWorkTags.FunctionComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local ContextProvider = ReactWorkTags.ContextProvider
local ForwardRef = ReactWorkTags.ForwardRef
local Block = ReactWorkTags.Block
local hookLog = {}
local primitiveStackCache = nil
local currentFiber = nil

local exports = {}

-- deviation: hoist definition
local Dispatcher

local function getPrimitiveStackCache()
	if primitiveStackCache == nil then
		local cache = {}
		local readHookLog
		pcall(function()
			-- Use all hooks here to add them to the hook log.
			Dispatcher.useContext({})
			Dispatcher.useState(nil)
			Dispatcher.useReducer(function(s, a)
				return s
			end, nil)
			Dispatcher.useRef(nil)
			Dispatcher.useLayoutEffect(function() end)
			Dispatcher.useEffect(function() end)
			Dispatcher.useImperativeHandle(nil, function() end)
			Dispatcher.useDebugValue(nil)
			Dispatcher.useCallback(function() end)
			Dispatcher.useMemo(function() end)
		end)
		readHookLog = hookLog
		hookLog = {}
		for i = 1, #readHookLog do
			local hook = readHookLog[i]
			cache[hook.primitive] = ErrorStackParser.parse(hook.stackError)
		end
		primitiveStackCache = cache
	end
	return primitiveStackCache
end

local currentHook = nil

local function nextHook()
	local hook = currentHook
	if hook ~= nil then
		currentHook = hook.next
	end
	return hook
end

local function readContext(context, observedBits)
	return context._currentValue
end

local function useContext(context, observedBits)
	table.insert(hookLog, {
		primitive = 'Context',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = context._currentValue,
	})
	return context._currentValue
end

local function useState(initialState)
	local hook = nextHook()
	local state = (function()
		if hook ~= nil then
			return hook.memoizedState
		end

		return(function()
			if typeof(initialState) == 'function' then
				return initialState()
			end

			return initialState
		end)()
	end)()

	table.insert(hookLog, {
		primitive = 'State',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = state,
	})

	return {
		state,
		function(action) end,
	}
end

local function useReducer(reducer, initialArg, init)
	local hook = nextHook()
	local state

	if hook ~= nil then
		state = hook.memoizedState
	else
		state = (function()
			if init ~= nil then
				return init(initialArg)
			end

			return initialArg
		end)()
	end

	table.insert(hookLog, {
		primitive = 'Reducer',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = state,
	})

	return{
		state,
		function(action) end,
	}
end

local function useRef(initialValue)
	local hook = nextHook()
	local ref = (function()
		if hook ~= nil then
			return hook.memoizedState
		end

		return{current = initialValue}
	end)()

	table.insert(hookLog, {
		primitive = 'Ref',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = ref.current,
	})

	return ref
end

local function useLayoutEffect(create, inputs)
	nextHook()
	table.insert(hookLog, {
		primitive = 'LayoutEffect',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = create,
	})
end

local function useEffect(create, inputs)
	nextHook()
	table.insert(hookLog, {
		primitive = 'Effect',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = create,
	})
end

local function useImperativeHandle(ref, create, inputs)
	nextHook()

	local instance = nil

	-- deviation: use 'table' not object
	if ref ~= nil and typeof(ref) == 'table' then
		instance = ref.current
	end

	table.insert(hookLog, {
		primitive = 'ImperativeHandle',
		-- deviation: use traceback rather than throwing an error',
		stackError = debug.traceback(),
		value = instance,
	})
end

local function useDebugValue(value, formatterFn)
	table.insert(hookLog, {
		primitive = 'DebugValue',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = (function()
			if typeof(formatterFn) == 'function' then
				return formatterFn(value)
			end

			return value
		end)(),
	})
end

local function useCallback(callback, inputs)
	local hook = nextHook()

	table.insert(hookLog, {
		primitive = 'Callback',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = (function()
			if hook ~= nil then
				return hook.memoizedState[0]
			end

			return callback
		end)(),
	})

	return callback
end

local function useMemo(nextCreate, inputs)
	local hook = nextHook()
	local value = (function()
		if hook ~= nil then
			return hook.memoizedState[0]
		end

		return nextCreate()
	end)()

	table.insert(hookLog, {
		primitive = 'Memo',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = value,
	})

	return value
end

local function useMutableSource(source, getSnapshot, subscribe)
	nextHook()
	nextHook()
	nextHook()
	nextHook()

	local value = getSnapshot(source._source)

	table.insert(hookLog, {
		primitive = 'MutableSource',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = value,
	})

	return value
end

local function useTransition()
	nextHook()
	nextHook()
	table.insert(hookLog, {
		primitive = 'Transition',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = nil,
	})

	return{
		function(callback) end,
		false,
	}
end

local function useDeferredValue(value)
	nextHook()
	nextHook()
	table.insert(hookLog, {
		primitive = 'DeferredValue',
		-- deviation: use traceback rather than throwing an error
		stackError = debug.traceback(),
		value = value,
	})

	return value
end

local function useOpaqueIdentifier()
	local hook = nextHook()

	if currentFiber and currentFiber.mode == NoMode then
		nextHook()
	end

	local value = (function()
		if hook == nil then
			return nil
		end

		return hook.memoizedState
	end)()

	if value and value['$$typeof'] == REACT_OPAQUE_ID_TYPE then
		value = nil
	end

	table.insert(hookLog, {
		primitive = 'OpaqueIdentifier',
		-- deviation: use traceback rather than throwing an error'
		stackError = debug.traceback(),
		value = value,
	})

	return value
end

Dispatcher = {
	readContext = readContext,
	useCallback = useCallback,
	useContext = useContext,
	useEffect = useEffect,
	useImperativeHandle = useImperativeHandle,
	useDebugValue = useDebugValue,
	useLayoutEffect = useLayoutEffect,
	useMemo = useMemo,
	useReducer = useReducer,
	useRef = useRef,
	useState = useState,
	useTransition = useTransition,
	useMutableSource = useMutableSource,
	useDeferredValue = useDeferredValue,
	useOpaqueIdentifier = useOpaqueIdentifier,
}
-- Don't assume
--
-- We can't assume that stack frames are nth steps away from anything.
-- E.g. we can't assume that the root call shares all frames with the stack
-- of a hook call. A simple way to demonstrate this is wrapping `new Error()`
-- in a wrapper constructor like a polyfill. That'll add an extra frame.
-- Similar things can happen with the call to the dispatcher. The top frame
-- may not be the primitive. Likewise the primitive can have fewer stack frames
-- such as when a call to useState got inlined to use dispatcher.useState.
--
-- We also can't assume that the last frame of the root call is the same
-- frame as the last frame of the hook call because long stack traces can be
-- truncated to a stack trace limit.
local mostLikelyAncestorIndex = 0

local function findSharedIndex(hookStack, rootStack, rootIndex)
	local source = rootStack[rootIndex].source
	for i = 1, #hookStack do
		if hookStack[i].source == source then
			-- This looks like a match. Validate that the rest of both stack match up.
			-- deviation: rewrite complex loop
			local a = rootIndex + 1
			local b = i + 1
			local skipReturn = false
			while a < #rootStack and b < #hookStack do
				if hookStack[b].source ~= rootStack[a].source then
					-- If not, give up and try a different match.
					skipReturn = true
					break
				end
			end
			if not skipReturn then
				return i
			end
		end
	end
	return -1
end

local function findCommonAncestorIndex(rootStack, hookStack)
	local rootIndex = findSharedIndex(hookStack, rootStack, mostLikelyAncestorIndex)
	if rootIndex ~= -1 then
		return rootIndex
	end
	-- If the most likely one wasn't a hit, try any other frame to see if it is shared.
	-- If that takes more than 5 frames, something probably went wrong.
	-- deviation: use min to precompute iteration count
	for i = 1, math.min(#rootStack, 5) do
		rootIndex = findSharedIndex(hookStack, rootStack, i)
		if rootIndex ~= -1 then
			mostLikelyAncestorIndex = i
			return rootIndex
		end
	end

	return -1
end

local function isReactWrapper(functionName, primitiveName)
	if not functionName then
		return false
	end

	local expectedPrimitiveName = 'use' + primitiveName

	if functionName.length < expectedPrimitiveName.length then
		return false
	end

	return functionName.lastIndexOf(expectedPrimitiveName) == functionName.length - expectedPrimitiveName.length
end

local function findPrimitiveIndex(hookStack, hook)
	local stackCache = getPrimitiveStackCache()
	local primitiveStack = stackCache.get(hook.primitive)

	if primitiveStack == nil then
		return -1
	end

	-- deviation: precompute iteration count
	for i = 1, math.min(#primitiveStack, #hookStack) do
		if primitiveStack[i].source ~= hookStack[i].source then
			-- If the next two frames are functions called `useX` then we assume that they're part of the
			-- wrappers that the React packager or other packages adds around the dispatcher.
			-- deviation: 1-indexed so drop -1
			if i < #hookStack and isReactWrapper(hookStack[i].functionName, hook.primitive) then
				i += 1
			end
		  	-- deviation: 1-indexed so drop -1
			if i < #hookStack and isReactWrapper(hookStack[i].functionName, hook.primitive) then
				i += 1
			end
		  return i
		end
	end

	return -1
end

local function parseTrimmedStack(rootStack, hook)
	-- deviation: don't parse traceback
	local hookStack = ErrorStackParser.parse(hook.stackError)
	local rootIndex = findCommonAncestorIndex(rootStack, hookStack)
	local primitiveIndex = findPrimitiveIndex(hookStack, hook)

	if rootIndex == -1 or primitiveIndex == -1 or rootIndex - primitiveIndex < 2 then
		return nil
	end

	return Array.slice(hookStack, primitiveIndex, rootIndex - 1)
end

local function parseCustomHookName(functionName)
	if not functionName then
		return''
	end

	local startIndex = functionName.lastIndexOf('.')

	if startIndex == -1 then
		startIndex = 0
	end
	if functionName.substr(startIndex, 3) == 'use' then
		startIndex = startIndex + 3
	end

	return functionName.substr(startIndex)
end

local processDebugValues

local function buildTree(rootStack, readHookLog)
	local rootChildren = {}
	local prevStack = nil
	local levelChildren = rootChildren
	local nativeHookID = 0
	local stackOfChildren = {}

	for i=0, readHookLog.length - 1 do
		local hook = readHookLog[i]
		local stack = parseTrimmedStack(rootStack, hook)

		if stack ~= nil then
			local commonSteps = 0

			if prevStack ~= nil then
				while commonSteps < stack.length and commonSteps < prevStack.length do
					local stackSource = stack[stack.length - commonSteps - 1].source
					local prevSource = prevStack[prevStack.length - commonSteps - 1].source

					if stackSource ~= prevSource then
						break
					end

					commonSteps += 1
				end
				-- Pop back the stack as many steps as were not common.
				-- deviation: use 1-indexing so drop -1
				for j = #prevStack, commonSteps, -1 do
					table.remove(levelChildren)
				end
			end

			-- The remaining part of the new stack are custom hooks. Push them
			-- to the tree.
			-- deviation: use 1-indexing so drop -1
			for j = #stack.length - commonSteps, 1, -1 do
		  		local children = {}
				table.insert(levelChildren, {
					id = nil,
					isStateEditable = false,
					-- deviation: use 1-indexing so drop -1
					name = parseCustomHookName(stack[j].functionName),
					value = nil,
					subHooks = children
				})
				table.insert(stackOfChildren, levelChildren)
		  		levelChildren = children
			end

			prevStack = stack
		end

		local function POSTFIX_INCREMENT()
			local prev = nativeHookID
			nativeHookID += 1
			return prev
		end

		local primitive = hook.primitive
		local id = (function()
			if primitive == 'Context' or primitive == 'DebugValue' then
				return nil
			end

			return POSTFIX_INCREMENT()
		end)()
		local isStateEditable = primitive == 'Reducer' or primitive == 'State'

		table.insert(levelChildren, {
			id = id,
			isStateEditable = isStateEditable,
			name = primitive,
			value = hook.value,
			subHooks = {},
		})
	end

	processDebugValues(rootChildren, nil)

	return rootChildren
end

processDebugValues = function(hooksTree, parentHooksNode)
	local debugValueHooksNodes = {}

	for i=0, hooksTree.length - 1 do
		local hooksNode = hooksTree[i]

		if hooksNode.name == 'DebugValue' and hooksNode.subHooks.length == 0 then
			Array.splice(hooksTree, i, 1)

			i = i - 1

			table.insert(debugValueHooksNodes,hooksNode)
		else
			processDebugValues(hooksNode.subHooks, hooksNode)
		end
	end

	if parentHooksNode ~= nil then
		if debugValueHooksNodes.length == 1 then
			parentHooksNode.value = debugValueHooksNodes[0].value
		elseif debugValueHooksNodes.length > 1 then
			parentHooksNode.value = Array.map(debugValueHooksNodes, function(_ref)
				local value = _ref.value
				return value
			end)
		end
	end
end

exports.inspectHooks = function(renderFunction, props, currentDispatcher)
	if currentDispatcher == nil then
		currentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
	end

	local previousDispatcher = currentDispatcher.current
	local readHookLog

	currentDispatcher.current = Dispatcher

	local ancestorStackError

	pcall(function()
		ancestorStackError = debug.traceback()
		renderFunction(props)
	end)
	readHookLog = hookLog
	hookLog = {}
	currentDispatcher.current = previousDispatcher

	local rootStack = ErrorStackParser.parse(ancestorStackError)

	return buildTree(rootStack, readHookLog)
end

local function setupContexts(contextMap, fiber)
	local current = fiber

	while current do
		if current.tag == ContextProvider then
			local providerType = current.type
			local context = providerType._context

			if not contextMap[context] then
				contextMap[context] = context._currentValue

				context._currentValue = current.memoizedProps.value
			end
		end

		current = current.return_
	end
end

local function restoreContexts(contextMap)
	for context, value in pairs(contextMap) do
		context._currentValue = value
	end
end

local function inspectHooksOfForwardRef(renderFunction, props, ref, currentDispatcher)
	local previousDispatcher = currentDispatcher.current
	local readHookLog

	currentDispatcher.current = Dispatcher

	local ancestorStackError
	pcall(function()
		ancestorStackError = debug.traceback()
		renderFunction(props)
	end)
	readHookLog = hookLog
	hookLog = {}
	currentDispatcher.current = previousDispatcher

	local rootStack = ErrorStackParser.parse(ancestorStackError)

	return buildTree(rootStack, readHookLog)
end

local function resolveDefaultProps(Component, baseProps)
	if Component and Component.defaultProps then
		local props = Object.assign({}, baseProps)
		local defaultProps = Component.defaultProps
		for propName, _ in pairs(defaultProps) do
			if props[propName] == nil then
				props[propName] = defaultProps[propName]
			end
		end
		return props
	end

	return baseProps
end

exports.inspectHooksOfFiber = function(fiber, currentDispatcher)
	if currentDispatcher == nil then
		currentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
	end

	currentFiber = fiber

	if fiber.tag ~= FunctionComponent and fiber.tag ~= SimpleMemoComponent and fiber.tag ~= ForwardRef and fiber.tag ~= Block then
		error('Unknown Fiber. Needs to be a function component to inspect hooks.')
	end

	getPrimitiveStackCache()

	local type_ = fiber.type
	local props = fiber.memoizedProps

	if type_ ~= fiber.elementType then
		props = resolveDefaultProps(type_, props)
	end

	currentHook = fiber.memoizedState

	local contextMap = {}
	pcall(function()
		setupContexts(contextMap, fiber)
		if fiber.tag == ForwardRef then
			return inspectHooksOfForwardRef(
				type_.render,
				props,
				fiber.ref,
				currentDispatcher
		  	)
		end
		return exports.inspectHooks(type_, props, currentDispatcher)
	end)
	currentHook = nil
	restoreContexts(contextMap)
end

return exports
