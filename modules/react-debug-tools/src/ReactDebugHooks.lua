--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17.0.1/packages/react-debug-tools/src/ReactDebugHooks.js
--[[*
	* Copyright (c) Facebook, Inc. and its affiliates.
	*
	* This source code is licensed under the MIT license found in the
	* LICENSE file in the root directory of this source tree.
   ]]

local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
local Error = LuauPolyfill.Error
type Error = LuauPolyfill.Error
local String = LuauPolyfill.String

local Object = LuauPolyfill.Object
type Object = { [string]: any }
type Map<K, V> = { [K]: V }
type Function = (...any) -> ...any
local exports = {}

local ReactTypes = require(Packages.Shared)
-- ROBLOX deviation START: binding support
type ReactBinding<T> = ReactTypes.ReactBinding<T>
type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END: binding support
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type ReactContext<T> = ReactTypes.ReactContext<T>
-- ROBLOX deviation: import this type that is a built-in in flow
type React_Node = ReactTypes.React_Node

local ReactInternalTypes = require(Packages.ReactReconciler)
type Fiber = ReactInternalTypes.Fiber
type DispatcherType = ReactTypes.Dispatcher

local ReactFiberHostConfig = require(Packages.Shared)
type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType

local ReconcilerModule = require(Packages.ReactReconciler)({})
local ReactTypeOfMode = ReconcilerModule.ReactTypeOfMode
local NoMode = ReactTypeOfMode.NoMode

-- ROBLOX TODO: work out a suitable implementation for this, pulled from error-stack-parser definitelytyped
type StackFrame = {
	source: string?,
	functionName: string?,
}
local ErrorStackParser = {
	parse = function(error_: Error): Array<StackFrame>
		if error_.stack == nil then
			return {}
		end
		return Array.map(
			string.split((error_.stack :: string), "\n"),
			function(stackTraceLine)
				-- ROBLOX FIXME Luau: shouldn't need to explicitly provide nilable field
				return { source = stackTraceLine, functionName = nil }
			end
		)
	end,
}

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

type CurrentDispatcherRef = typeof(ReactSharedInternals.ReactCurrentDispatcher)

-- Used to track hooks called during a render

type HookLogEntry = {
	primitive: string,
	stackError: Error,
	value: any,
	-- ...
}

local hookLog: Array<HookLogEntry> = {}

-- Primitives

type BasicStateAction<S> = ((S) -> S) | S

type Dispatch<A> = (A) -> ()

local primitiveStackCache: nil | Map<string, Array<any>> = nil

local currentFiber: Fiber | nil = nil

type Hook = { memoizedState: any, next: Hook | nil }

-- ROBLOX deviation: hoist definition
local Dispatcher: DispatcherType

local function getPrimitiveStackCache(): Map<string, Array<any>>
	-- This initializes a cache of all primitive hooks so that the top
	-- most stack frames added by calling the primitive hook can be removed.
	if primitiveStackCache == nil then
		local cache = {}
		local readHookLog
		pcall(function()
			-- Use all hooks here to add them to the hook log.
			Dispatcher.useContext({ _currentValue = nil } :: any)
			Dispatcher.useState(nil)
			Dispatcher.useReducer(function(s, a)
				return s
			end, nil)
			Dispatcher.useRef(nil)
			-- ROBLOX deviation: support bindings
			Dispatcher.useBinding(nil)
			Dispatcher.useLayoutEffect(function() end)
			Dispatcher.useEffect(function() end)
			Dispatcher.useImperativeHandle(nil, function()
				return nil
			end)
			Dispatcher.useDebugValue(nil)
			Dispatcher.useCallback(function() end)
			Dispatcher.useMemo(function()
				return nil
			end)
		end)
		readHookLog = hookLog
		table.clear(hookLog)
		for i = 1, #readHookLog do
			local hook = readHookLog[i]
			cache[hook.primitive] = ErrorStackParser.parse(hook.stackError)
		end
		primitiveStackCache = cache
	end
	return primitiveStackCache :: Map<string, Array<any>>
end

local currentHook: nil | Hook = nil

local function nextHook(): nil | Hook
	local hook = currentHook
	if hook ~= nil then
		currentHook = hook.next
	end
	return hook
end

function readContext<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
	table.insert(hookLog, {
		primitive = "Context",
		stackError = Error.new(),
		value = context._currentValue,
	})
	return context._currentValue
end

function useContext<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
	table.insert(hookLog, {
		primitive = "Context",
		stackError = Error.new(),
		value = context._currentValue,
	})
	return context._currentValue
end

function useState<S>(initialState: (() -> S) | S): (S, Dispatch<BasicStateAction<S>>)
	local hook = nextHook()
	local state: S = if hook ~= nil
		then hook.memoizedState
		else if typeof(initialState) == "function" then initialState() else initialState

	table.insert(hookLog, {
		primitive = "State",
		stackError = Error.new(),
		value = state,
	})

	return state, function(_action: BasicStateAction<any>) end
end

local function useReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local hook = nextHook()
	local state

	if hook ~= nil then
		state = hook.memoizedState
	else
		state = (function(): any
			if init ~= nil then
				return (init :: Function)(initialArg)
			end
			return initialArg
		end)()
	end

	table.insert(hookLog, {
		primitive = "Reducer",
		stackError = Error.new(),
		value = state,
	})

	return state, function(_action: any) end
end

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
local function useRef<T>(initialValue: T): { current: T | nil }
	local hook = nextHook()
	local ref = if hook ~= nil then hook.memoizedState else { current = initialValue }
	table.insert(hookLog, {
		primitive = "Ref",
		stackError = Error.new(),
		value = ref.current,
	})

	return ref
end

-- ROBLOX deviaition: binding support; these aren't fully working hooks, so this
-- is just an approximation modeled off of the `ref` hook above
local function useBinding<T>(initialValue: T): (ReactBinding<T>, ReactBindingUpdater<T>)
	local hook = nextHook()
	local binding = if hook ~= nil
		then hook.memoizedState
		else
			(
				{
					getValue = function(_self)
						return initialValue
					end,
					-- FIXME Luau: I'd expect luau to complain about a lack of `map`
					-- field, but it only complains when non-nil and incorrectly typed
				} :: ReactBinding<T>
			)

	table.insert(hookLog, {
		primitive = "Binding",
		stackError = Error.new(),
		value = binding:getValue(),
	})

	return binding, function(_value) end
end

local function useLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	inputs: Array<any> | nil
): ()
	nextHook()
	table.insert(hookLog, {
		primitive = "LayoutEffect",
		stackError = Error.new(),
		value = create,
	})
end

local function useEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	inputs: Array<any> | nil
): ()
	nextHook()
	table.insert(hookLog, {
		primitive = "Effect",
		stackError = Error.new(),
		value = create,
	})
end

local function useImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
	create: () -> T,
	inputs: Array<any> | nil
): ()
	nextHook()
	-- We don't actually store the instance anywhere if there is no ref callback
	-- and if there is a ref callback it might not store it but if it does we
	-- have no way of knowing where. So let's only enable introspection of the
	-- ref itself if it is using the object form.
	local instance = nil

	if ref ~= nil and typeof(ref) == "table" then
		instance = ref.current
	end

	table.insert(hookLog, {
		primitive = "ImperativeHandle",
		stackError = Error.new(),
		value = instance,
	})
end

local function useDebugValue<T>(value: T, formatterFn: ((value: T) -> any)?): ()
	table.insert(hookLog, {
		primitive = "DebugValue",
		stackError = Error.new(),
		value = (function()
			if typeof(formatterFn) == "function" then
				return (formatterFn :: Function)(value)
			end

			return value
		end)(),
	})
end

local function useCallback<T>(callback: T, inputs: Array<any> | nil): T
	local hook = nextHook()

	table.insert(hookLog, {
		primitive = "Callback",
		stackError = Error.new(),
		value = (function()
			if hook ~= nil then
				return hook.memoizedState[0]
			end

			return callback
		end)(),
	})

	return callback
end

-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
local function useMemo<T...>(nextCreate: () -> T..., inputs: Array<any> | nil): ...any
	local hook = nextHook()
	-- ROBLOX DEVIATION: Wrap memoized values in a table and unpack to allow for multiple return values
	local value = if hook ~= nil then hook.memoizedState[1] else { nextCreate() }

	table.insert(hookLog, {
		primitive = "Memo",
		stackError = Error.new(),
		value = value,
	})

	return table.unpack(value)
end

function useMutableSource<Source, Snapshot>(
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
	-- useMutableSource() composes multiple hooks internally.
	-- Advance the current hook index the same number of times
	-- so that subsequent hooks have the right memoized state.
	nextHook() -- MutableSource
	nextHook() -- State
	nextHook() -- Effect
	nextHook() -- Effect

	local value = getSnapshot(source._source)

	table.insert(hookLog, {
		primitive = "MutableSource",
		stackError = Error.new(),
		value = value,
	})

	return value
end

-- ROBLOX TODO: enable these once they are fully enabled in the Dispatcher type and in ReactFiberHooks' myriad dispatchers

-- local function useTransition(): ((() -> ()) -> (), boolean)
-- 	-- useTransition() composes multiple hooks internally.
-- 	-- Advance the current hook index the same number of times
-- 	-- so that subsequent hooks have the right memoized state.
-- 	nextHook() -- State
-- 	nextHook() -- Callback
-- 	table.insert(hookLog, {
-- 		primitive = 'Transition',
-- 		stackError = Error.new(),
-- 		value = nil,
-- 	})

-- 	return
-- 		function() return function() end end,
-- 		false
-- end
-- ROBLOX TODO: function generics
-- export function useDeferredValue<T>(value: T): T {
-- local function useDeferredValue(value)
-- 	-- useDeferredValue() composes multiple hooks internally.
-- 	-- Advance the current hook index the same number of times
-- 	-- so that subsequent hooks have the right memoized state.
-- 	nextHook() -- State
-- 	nextHook() -- Effect
-- 	table.insert(hookLog, {
-- 		primitive = 'DeferredValue',
-- 		stackError = Error.new(),
-- 		value = value,
-- 	})

-- 	return value
-- end

local function useOpaqueIdentifier(): OpaqueIDType | nil
	local hook = nextHook() -- State

	if currentFiber and currentFiber.mode == NoMode then
		nextHook() -- Effect
	end

	local value = (function()
		if hook == nil then
			return nil
		end

		return (hook :: Hook).memoizedState
	end)()

	if value and (value :: any)["$$typeof"] == REACT_OPAQUE_ID_TYPE then
		value = nil
	end

	table.insert(hookLog, {
		primitive = "OpaqueIdentifier",
		stackError = Error.new(),
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
	-- ROBLOX FIXME Luau: work around 'Failed to unify type packs' error: CLI-51338
	useMemo = useMemo :: any,
	useReducer = useReducer,
	useRef = useRef,
	useBinding = useBinding,
	useState = useState,
	-- useTransition = useTransition,
	useMutableSource = useMutableSource,
	-- useDeferredValue = useDeferredValue,
	useOpaqueIdentifier = useOpaqueIdentifier,
}

-- Inspect

export type HooksNode = {
	id: number | nil,
	isStateEditable: boolean,
	name: string,
	value: any,
	subHooks: Array<HooksNode>,
	--   ...
}
export type HooksTree = Array<HooksNode>

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

local function findSharedIndex(hookStack, rootStack: Array<StackFrame>, rootIndex: number)
	local source = rootStack[rootIndex].source
	for i = 1, #hookStack do
		if hookStack[i].source == source then
			-- This looks like a match. Validate that the rest of both stack match up.
			-- ROBLOX deviation: rewrite complex loop
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
	-- ROBLOX deviation: use min to precompute iteration count
	for i = 1, math.min(#rootStack, 5) do
		rootIndex = findSharedIndex(hookStack, rootStack, i)
		if rootIndex ~= -1 then
			mostLikelyAncestorIndex = i
			return rootIndex
		end
	end

	return -1
end

local function isReactWrapper(functionName: string?, primitiveName: string)
	-- ROBLOX note: !functionName translates to this, because "" is falsey in JS
	if not functionName or functionName == "" then
		return false
	end

	local expectedPrimitiveName = "use" .. primitiveName

	-- ROBLOX FIXME Luau: Luau doesn't understand the guard above
	if string.len(functionName :: string) < string.len(expectedPrimitiveName) then
		return false
	end

	-- ROBLOX FIXME Luau: Luau doesn't understand the guard above
	return String.lastIndexOf(functionName :: string, expectedPrimitiveName)
		== string.len(functionName :: string) - string.len(expectedPrimitiveName)
end

local function findPrimitiveIndex(hookStack: Array<StackFrame>, hook)
	local stackCache = getPrimitiveStackCache()
	local primitiveStack = stackCache[hook.primitive]

	if primitiveStack == nil then
		return -1
	end

	-- ROBLOX deviation: precompute iteration count
	for i = 1, math.min(#primitiveStack, #hookStack) do
		if primitiveStack[i].source ~= hookStack[i].source then
			-- If the next two frames are functions called `useX` then we assume that they're part of the
			-- wrappers that the React packager or other packages adds around the dispatcher.
			-- ROBLOX deviation: 1-indexed so drop -1
			if
				i < #hookStack
				and isReactWrapper(hookStack[i].functionName, hook.primitive)
			then
				i += 1
			end
			-- ROBLOX deviation: 1-indexed so drop -1
			if
				i < #hookStack
				and isReactWrapper(hookStack[i].functionName, hook.primitive)
			then
				i += 1
			end
			return i
		end
	end

	return -1
end

-- ROBLOX FIXME Luau: Luau doesn't infer Array<StackFrame> | nil like it should
local function parseTrimmedStack(rootStack, hook): Array<StackFrame>?
	-- Get the stack trace between the primitive hook function and
	-- the root function call. I.e. the stack frames of custom hooks.

	local hookStack = ErrorStackParser.parse(hook.stackError)
	local rootIndex = findCommonAncestorIndex(rootStack, hookStack)
	local primitiveIndex = findPrimitiveIndex(hookStack, hook)

	if rootIndex == -1 or primitiveIndex == -1 or rootIndex - primitiveIndex < 2 then
		-- Something went wrong. Give up.
		return nil
	end

	-- ROBLOX FIXME? does rootIndex need the -1?
	return Array.slice(hookStack, primitiveIndex, rootIndex - 1)
end

local function parseCustomHookName(functionName: nil | string): string
	if not functionName then
		return ""
	end

	local startIndex = String.lastIndexOf((functionName :: string), ".")

	if startIndex == -1 then
		startIndex = 0
	end
	if String.substr(functionName :: string, startIndex, 3) == "use" then
		startIndex = startIndex + 3
	end

	return String.substr(functionName :: string, startIndex)
end

local processDebugValues

local function buildTree(rootStack, readHookLog): HooksTree
	local rootChildren = {}
	local prevStack = nil
	local levelChildren = rootChildren
	local nativeHookID = 0
	local stackOfChildren = {}

	for i = 1, #readHookLog do
		local hook = readHookLog[i]
		local stack = parseTrimmedStack(rootStack, hook)

		if stack ~= nil then
			-- Note: The indices 0 <= n < length-1 will contain the names.
			-- The indices 1 <= n < length will contain the source locations.
			-- That's why we get the name from n - 1 and don't check the source
			-- of index 0.
			local commonSteps = 0
			if prevStack ~= nil then
				-- Compare the current level's stack to the new stack.
				while commonSteps < #stack and commonSteps < #prevStack do
					local stackSource = stack[#stack - commonSteps].source
					local prevSource = prevStack[#prevStack - commonSteps].source

					if stackSource ~= prevSource then
						break
					end

					commonSteps += 1
				end
				-- Pop back the stack as many steps as were not common.
				for j = #prevStack, commonSteps, -1 do
					table.remove(levelChildren)
				end
			end

			-- The remaining part of the new stack are custom hooks. Push them
			-- to the tree.
			for j = #stack - commonSteps, 1, -1 do
				local children = {}
				table.insert(levelChildren, {
					-- ROBLOX FIXME Luau: Luau should infer number | nil here by (at least) looking at the function-level usage
					id = nil :: number | nil,
					isStateEditable = false,
					name = parseCustomHookName(stack[j].functionName),
					value = nil,
					subHooks = children,
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

		-- For now, the "id" of stateful hooks is just the stateful hook index.
		-- Custom hooks have no ids, nor do non-stateful native hooks (e.g. Context, DebugValue).
		-- ROBLOX FIXME Luau: Luau doesn't infer number | nil like it should
		local id = if primitive == "Context" or primitive == "DebugValue"
			then nil
			else POSTFIX_INCREMENT()
		-- For the time being, only State and Reducer hooks support runtime overrides.
		local isStateEditable = primitive == "Reducer" or primitive == "State"

		table.insert(levelChildren, {
			id = id,
			isStateEditable = isStateEditable,
			name = primitive,
			value = hook.value,
			subHooks = {},
		})
	end

	-- Associate custom hook values (useDebugValue() hook entries) with the correct hooks.
	processDebugValues(rootChildren)

	return rootChildren
end

-- Custom hooks support user-configurable labels (via the special useDebugValue() hook).
-- That hook adds user-provided values to the hooks tree,
-- but these values aren't intended to appear alongside of the other hooks.
-- Instead they should be attributed to their parent custom hook.
-- This method walks the tree and assigns debug values to their custom hook owners.
function processDebugValues(hooksTree: HooksTree, parentHooksNode: HooksNode | nil): ()
	local debugValueHooksNodes: Array<HooksNode> = {}

	local i = 0
	while i <= #hooksTree do
		local hooksNode = hooksTree[i]

		if hooksNode.name == "DebugValue" and #hooksNode.subHooks == 0 then
			Array.splice(hooksTree, i, 1)

			i -= 1

			table.insert(debugValueHooksNodes, hooksNode)
		else
			processDebugValues(hooksNode.subHooks, hooksNode)
		end

		i += 1
	end

	-- Bubble debug value labels to their custom hook owner.
	-- If there is no parent hook, just ignore them for now.
	-- (We may warn about this in the future.)
	if parentHooksNode ~= nil then
		if #debugValueHooksNodes == 1 then
			(parentHooksNode :: HooksNode).value = debugValueHooksNodes[1].value
		elseif #debugValueHooksNodes > 1 then
			(parentHooksNode :: HooksNode).value = Array.map(
				debugValueHooksNodes,
				function(_ref)
					local value = _ref.value
					return value
				end
			)
		end
	end
end

exports.inspectHooks = function<Props>(
	renderFunction: (Props) -> React_Node,
	props: Props,
	currentDispatcher: CurrentDispatcherRef?
): HooksTree
	-- DevTools will pass the current renderer's injected dispatcher.
	-- Other apps might compile debug hooks as part of their app though.
	if currentDispatcher == nil then
		currentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
	end

	local previousDispatcher = (currentDispatcher :: CurrentDispatcherRef).current
	local readHookLog;

	(currentDispatcher :: CurrentDispatcherRef).current = Dispatcher

	local ancestorStackError

	pcall(function()
		ancestorStackError = Error.new()
		renderFunction(props)
	end)
	readHookLog = hookLog
	hookLog = {};
	(currentDispatcher :: CurrentDispatcherRef).current = previousDispatcher

	local rootStack = ErrorStackParser.parse(ancestorStackError)

	return buildTree(rootStack, readHookLog)
end

local function setupContexts(contextMap: Map<ReactContext<any>, any>, fiber: Fiber)
	local current: Fiber? = fiber

	while current do
		if current.tag == ContextProvider then
			local providerType = current.type
			local context = providerType._context

			if not contextMap[context] then
				-- Store the current value that we're going to restore later.
				contextMap[context] = context._currentValue
				-- Set the inner most provider value on the context.
				context._currentValue = current.memoizedProps.value
			end
		end

		current = current.return_ :: Fiber
	end
end

local function restoreContexts(contextMap: Map<ReactContext<any>, any>)
	for context, value in contextMap do
		context._currentValue = value
	end
end

local function inspectHooksOfForwardRef<Props, Ref>(
	renderFunction: (Props, Ref) -> React_Node,
	props: Props,
	ref: Ref,
	currentDispatcher: CurrentDispatcherRef
): HooksTree
	local previousDispatcher = currentDispatcher.current
	local readHookLog

	currentDispatcher.current = Dispatcher

	local ancestorStackError
	pcall(function()
		ancestorStackError = Error.new()
		renderFunction(props, ref)
	end)
	readHookLog = hookLog
	hookLog = {}
	currentDispatcher.current = previousDispatcher

	local rootStack = ErrorStackParser.parse(ancestorStackError)

	return buildTree(rootStack, readHookLog)
end

local function resolveDefaultProps(Component, baseProps)
	if Component and Component.defaultProps then
		-- Resolve default props. Taken from ReactElement
		-- ROBLOX FIXME Luau: Expected type table, got 'any & any & any & {  }' instead
		local props = Object.assign({}, baseProps) :: typeof(baseProps)
		local defaultProps = Component.defaultProps
		for propName, _ in defaultProps do
			if props[propName] == nil then
				props[propName] = defaultProps[propName]
			end
		end
		return props
	end

	return baseProps
end

exports.inspectHooksOfFiber =
	function(fiber: Fiber, currentDispatcher: CurrentDispatcherRef?)
		-- DevTools will pass the current renderer's injected dispatcher.
		-- Other apps might compile debug hooks as part of their app though.
		if currentDispatcher == nil then
			currentDispatcher = ReactSharedInternals.ReactCurrentDispatcher
		end

		currentFiber = fiber

		if
			fiber.tag ~= FunctionComponent
			and fiber.tag ~= SimpleMemoComponent
			and fiber.tag ~= ForwardRef
			and fiber.tag ~= Block
		then
			error("Unknown Fiber. Needs to be a function component to inspect hooks.")
		end
		-- Warm up the cache so that it doesn't consume the currentHook.
		getPrimitiveStackCache()

		local type_ = fiber.type
		local props = fiber.memoizedProps

		if type_ ~= fiber.elementType then
			props = resolveDefaultProps(type_, props)
		end
		-- Set up the current hook so that we can step through and read the
		-- current state from them.
		currentHook = fiber.memoizedState

		local contextMap = {}
		pcall(function()
			setupContexts(contextMap, fiber)
			if fiber.tag == ForwardRef then
				return inspectHooksOfForwardRef(
					type_.render,
					props,
					fiber.ref,
					-- ROBLOX FIXME Luau: Luau doesn't understand lazy init above
					currentDispatcher :: CurrentDispatcherRef
				)
			end
			return exports.inspectHooks(type_, props, currentDispatcher)
		end)
		currentHook = nil
		restoreContexts(contextMap)
	end

return exports
