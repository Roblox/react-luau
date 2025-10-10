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
local ReactGlobals = require(Packages.ReactGlobals)
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
	if ReactGlobals.__DEV__ then
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

--[[
	Accepts a context object (the value returned from `React.createContext`)
	and returns the current context value, as given by the nearest context
	provider for the given context.

	See [API reference for `useContext`](https://react.dev/reference/react/useContext).
]]
local function useContext<T>(
	Context: ReactContext<T>,
	unstable_observedBits: number | boolean | nil,
	... -- ROBLOX deviation: Lua must specify ... here to capture additional args
): T
	local dispatcher = resolveDispatcher()
	if ReactGlobals.__DEV__ then
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

--[[
	Returns a stateful value, and a function to update it.

	See [API reference for `useState`](https://react.dev/reference/react/useState).
]]
local function useState<S>(
	initialState: (() -> S) | S,
	...
): (S, Dispatch<BasicStateAction<S>>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useState(initialState, ...)
end
exports.useState = useState

--[[
	An alternative to `useState`.

	`useReducer` is usually preferable to `useState` when you have complex state
	logic that involves multiple sub-values. It also lets you optimize
	performance for components that trigger deep updates because you can pass
	`dispatch` down instead of callbacks.

	See [API reference for `useReducer`](https://react.dev/reference/react/useReducer).
]]
local function useReducer<S, I, A>(
	reducer: (S, A) -> S,
	initialArg: I,
	init: ((I) -> S)?
): (S, Dispatch<A>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useReducer(reducer, initialArg, init)
end
exports.useReducer = useReducer

-- ROBLOX TODO: reconciling this with bindings and sharing any relevant Ref types (there may be different ones depending on whether it's just a loose ref, vs one being assigned to the ref prop
--[[
	Returns a mutable ref object whose `.current` property is initialized to the
	passed argument (`initialValue`). The returned object will persist for the
	full lifetime of the component.

	Note that `useRef()` is useful for more than the `ref` attribute. It’s
	handy for keeping any mutable value around similar to how you’d use instance
	fields in classes.

	See [API reference for `useRef`](https://react.dev/reference/react/useRef).
]]
local function useRef<T>(initialValue: T): { current: T }
	local dispatcher = resolveDispatcher()
	return dispatcher.useRef(initialValue)
end
exports.useRef = useRef

-- ROBLOX deviation START: Bindings are a feature unique to Roact
--[[
	Creates a stateful value that can be binded directly to Instance properties.
	Updating a binding doesn't cause a re-render, which makes it very performant
	for things like animations.
]]
local function useBinding<T>(
	initialValue: T
): (
	ReactTypes.ReactBinding<T>,
	ReactTypes.ReactBindingUpdater<T>
)
	local dispatcher = resolveDispatcher()
	return dispatcher.useBinding(initialValue)
end
exports.useBinding = useBinding
-- ROBLOX deviation END

--[[
	Accepts a function that contains imperative, possibly effectful code.

	See [API reference for `useEffect`](https://react.dev/reference/react/useEffect).

	@param effect Imperative function that can return a cleanup function
	@param deps If present, effect will only activate if the values in the list change.
]]
local function useEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> () -> ()),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useEffect(create, deps)
end
exports.useEffect = useEffect

--[[
	The signature is identical to `useEffect`, but it fires synchronously after
	all DOM mutations. Use this to read layout from the DOM and synchronously
	re-render. Updates scheduled inside `useLayoutEffect` will be flushed
	synchronously, before the browser has a chance to paint.

	Prefer the standard `useEffect` when possible to avoid blocking visual
	updates.

	If you’re migrating code from a class component, `useLayoutEffect` fires in
	the same phase as `componentDidMount` and `componentDidUpdate`.

	See [API reference for `useLayoutEffect`](https://react.dev/reference/react/useLayoutEffect).
]]
local function useLayoutEffect(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | (() -> () -> ()),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useLayoutEffect(create, deps)
end
exports.useLayoutEffect = useLayoutEffect

--[[
	`useCallback` will return a memoized version of the callback that only
	changes if one of the `inputs` has changed.

	See [API reference for `useCallback`](https://react.dev/reference/react/useCallback).
]]
local function useCallback<T>(callback: T, deps: Array<any> | nil): T
	local dispatcher = resolveDispatcher()
	return dispatcher.useCallback(callback, deps)
end
exports.useCallback = useCallback

--[[
	Will only recompute the memoized value when one of the `deps` has changed.

	See [API reference for `useMemo`](https://react.dev/reference/react/useMemo).
]]
local function useMemo<T...>(create: () -> T..., deps: Array<any> | nil): T...
	local dispatcher = resolveDispatcher()
	return dispatcher.useMemo(create, deps)
end
exports.useMemo = useMemo

--[[
	Customizes the instance value that is exposed to parent components when
	using `ref`. As always, imperative code using refs should be avoided in most
	cases.

	`useImperativeHandle` should be used with `React.forwardRef`.

	See [API reference for `useImperativeHandle`](https://react.dev/reference/react/useImperativeHandle).
]]
local function useImperativeHandle<T>(
	ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
	create: () -> T,
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useImperativeHandle(ref, create, deps)
end
exports.useImperativeHandle = useImperativeHandle

--[[
	Can be used to display a label for custom hooks in React DevTools.

	NOTE: We don’t recommend adding debug values to every custom hook.
	It’s most valuable for custom hooks that are part of shared libraries.

	See [API reference for `useDebugValue`](https://react.dev/reference/react/useDebugValue).
]]
local function useDebugValue<T>(value: T, formatterFn: ((value: T) -> any)?): ()
	if ReactGlobals.__DEV__ then
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

exports.useMutableSource = function<Source, Snapshot>(
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
	local dispatcher = resolveDispatcher()
	return dispatcher.useMutableSource(source, getSnapshot, subscribe)
end

return exports
