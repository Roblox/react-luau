--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ddd1faa1972b614dfbfae205f2aa4a6c0b39a759/packages/react/src/ReactHooks.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
-- ROBLOX TODO: we only pull in Dispatcher here for the typecheck, remove once Luau narrowing improves
type Dispatcher = ReactTypes.Dispatcher
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
local ReactFiberHostConfig = require(Packages.Shared)
type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType

-- local invariant = require(Packages.Shared).invariant

local ReactCurrentDispatcher =
	require(Packages.Shared).ReactSharedInternals.ReactCurrentDispatcher

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

-- ROBLOX FIXME Luau: we shouldn't need to explicitly annotate this
local function resolveDispatcher(): Dispatcher
	local dispatcher = ReactCurrentDispatcher.current
	-- ROBLOX performance: upstream main only does this check in DEV mode and then not as an invariant
	if _G.__DEV__ then
		if dispatcher == nil then
			console.error(
				"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
					.. " one of the following reasons:\n"
					.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
					.. "2. You might be breaking the Rules of Hooks\n"
					.. "3. You might have more than one copy of React in the same app\n"
					.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
			)
		end
	end
	-- Will result in a null access error if accessed outside render phase. We
	-- intentionally don't throw our own error because this is in a hot path.
	-- Also helps ensure this is inlined.
	return dispatcher :: Dispatcher
end

local exports = {}

local function useContext<T>(
	Context: ReactContext<T>,
	unstable_observedBits: number | boolean | nil,
	... -- ROBLOX deviation: Lua must specify ... here to capture additional args
): T
	local dispatcher = resolveDispatcher()
	if _G.__DEV__ then
		if unstable_observedBits ~= nil then
			console.error(
				"useContext() second argument is reserved for future "
					.. "use in React. Passing it is not supported. "
					.. "You passed: %s.%s",
				unstable_observedBits,
				(typeof(unstable_observedBits) == "number" and Array.isArray({ ... }))
						and "\n\nDid you call Array.map(useContext)? " .. "Calling Hooks inside a loop is not supported. " .. "Learn more at https://reactjs.org/link/rules-of-hooks"
					or ""
			)
		end

		-- TODO: add a more generic warning for invalid values.
		if (Context :: any)._context ~= nil then
			local realContext = (Context :: any)._context
			-- Don't deduplicate because this legitimately causes bugs
			-- and nobody should be using this in existing code.
			if realContext.Consumer == Context then
				console.error(
					"Calling useContext(Context.Consumer) is not supported, may cause bugs, and will be "
						.. "removed in a future major release. Did you mean to call useContext(Context) instead?"
				)
			elseif realContext.Provider == Context then
				console.error(
					"Calling useContext(Context.Provider) is not supported. "
						.. "Did you mean to call useContext(Context) instead?"
				)
			end
		end
	end
	return dispatcher.useContext(Context, unstable_observedBits)
end
exports.useContext = useContext

local function useState<S>(
	initialState: (() -> S) | S,
	...
): (S, Dispatch<BasicStateAction<S>>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useState(initialState, ...)
end
exports.useState = useState

local function useReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useReducer(reducer, initialArg, init)
end
exports.useReducer = useReducer

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
-- ROBLOX TODO: reconciling this with bindings and sharing any relevant Ref types (there may be different ones depending on whether it's just a loose ref, vs one being assigned to the ref prop
local function useRef<T>(initialValue: T): { current: T | nil }
	-- ROBLOX deviation END
	local dispatcher = resolveDispatcher()
	return dispatcher.useRef(initialValue)
end
exports.useRef = useRef

-- ROBLOX deviation: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
local function useBinding<T>(
	initialValue: T
): (
	ReactTypes.ReactBinding<T>,
	ReactTypes.ReactBindingUpdater<T>
)
	-- ROBLOX deviation END
	local dispatcher = resolveDispatcher()
	return dispatcher.useBinding(initialValue)
end
exports.useBinding = useBinding

local function useEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useEffect(create, deps)
end
exports.useEffect = useEffect

local function useLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> (() -> ())),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useLayoutEffect(create, deps)
end
exports.useLayoutEffect = useLayoutEffect

local function useCallback<T>(callback: T, deps: Array<any> | nil): T
	local dispatcher = resolveDispatcher()
	return dispatcher.useCallback(callback, deps)
end
exports.useCallback = useCallback

local function useMemo<T...>(create: () -> T..., deps: Array<any> | nil): T...
	local dispatcher = resolveDispatcher()
	return dispatcher.useMemo(create, deps)
end
exports.useMemo = useMemo

local function useImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useImperativeHandle(ref, create, deps)
end
exports.useImperativeHandle = useImperativeHandle

local function useDebugValue<T>(value: T, formatterFn: ((value: T) -> any)?): ()
	if _G.__DEV__ then
		local dispatcher = resolveDispatcher()
		return dispatcher.useDebugValue(value, formatterFn)
	end

	-- deviation: return nil explicitly for safety
	return nil
end
exports.useDebugValue = useDebugValue

exports.emptyObject = {}

-- ROBLOX TODO: enable useTransition later
-- exports.useTransition = function(): ((() -> ()) -> (), boolean)
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useTransition()
-- end

-- ROBLOX TODO: enable useDeferredValue later
-- exports.useDeferredValue = function<T>(value: T): T
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useDeferredValue(value)
-- end

exports.useOpaqueIdentifier = function(): OpaqueIDType | nil
	local dispatcher = resolveDispatcher()
	return dispatcher.useOpaqueIdentifier()
end

exports.useMutableSource =
	function<Source, Snapshot>(
		source: MutableSource<Source>,
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		subscribe: MutableSourceSubscribeFn<Source, Snapshot>
	): Snapshot
		local dispatcher = resolveDispatcher()
		return dispatcher.useMutableSource(source, getSnapshot, subscribe)
	end

return exports
