--!strict
-- upstream: https://github.com/facebook/react/blob/ddd1faa1972b614dfbfae205f2aa4a6c0b39a759/packages/react/src/ReactHooks.js
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
type MutableSourceGetSnapshotFn<Source, Snapshot> =
	ReactTypes.MutableSourceGetSnapshotFn<Source, Snapshot>
type MutableSourceSubscribeFn<Source, Snapshot> =
	ReactTypes.MutableSourceSubscribeFn<Source, Snapshot>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type ReactContext<T> = ReactTypes.ReactContext<T>
local ReactFiberHostConfig = require(Packages.Shared)
type OpaqueIDType = ReactFiberHostConfig.OpaqueIDType

local invariant = require(Packages.Shared).invariant

local ReactCurrentDispatcher = require(Packages.Shared).ReactSharedInternals.ReactCurrentDispatcher

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()


local function resolveDispatcher()
	local dispatcher = ReactCurrentDispatcher.current
	invariant(
		dispatcher ~= nil,
		'Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for' ..
			' one of the following reasons:\n' ..
			'1. You might have mismatching versions of React and the renderer (such as React DOM)\n' ..
			'2. You might be breaking the Rules of Hooks\n' ..
			'3. You might have more than one copy of React in the same app\n' ..
			'See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.'
	)
	return dispatcher :: Dispatcher
end

local exports = {}

-- ROBLOX TODO: function generics
-- export function useContext<T>(
-- 	Context: ReactContext<T>,
-- 	unstable_observedBits: number | boolean | void,
--   ): T {

type _T = any
exports.useContext = function(
	Context: ReactContext<_T>,
	unstable_observedBits: number | boolean | nil,
	... -- ROBLOX deviation: Lua must specify ... here to capture additional args
): _T
	local dispatcher = resolveDispatcher()
	if _G.__DEV__ then
		if unstable_observedBits ~= nil then
			console.error(
				'useContext() second argument is reserved for future ' ..
					'use in React. Passing it is not supported. ' ..
					'You passed: %s.%s',
				unstable_observedBits,
				(typeof(unstable_observedBits) == 'number' and Array.isArray({...})) and
					'\n\nDid you call Array.map(useContext)? ' ..
						'Calling Hooks inside a loop is not supported. ' ..
						'Learn more at https://reactjs.org/link/rules-of-hooks' or
					''
			)
		end

		-- TODO: add a more generic warning for invalid values.
		if (Context :: any)._context ~= nil then
			local realContext = (Context :: any)._context
			-- Don't deduplicate because this legitimately causes bugs
			-- and nobody should be using this in existing code.
			if realContext.Consumer == Context then
				console.error(
					'Calling useContext(Context.Consumer) is not supported, may cause bugs, and will be ' ..
						'removed in a future major release. Did you mean to call useContext(Context) instead?'
				)
			elseif realContext.Provider == Context then
				console.error(
					'Calling useContext(Context.Provider) is not supported. ' ..
						'Did you mean to call useContext(Context) instead?'
				)
			end
		end
	end
	return dispatcher.useContext(Context, unstable_observedBits)
end

-- ROBLOX TODO: function generics
-- export function useState<S>(
-- 	initialState: (() => S) | S,
--   ): [S, Dispatch<BasicStateAction<S>>] {
exports.useState = function(
	initialState: (() -> any) | any
): (any, Dispatch<BasicStateAction<any?>>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useState(initialState)
end

-- ROBLOX TODO: function generics
-- export function useReducer<S, I, A>(
-- 	reducer: (S, A) => S,
-- 	initialArg: I,
-- 	init?: I => S,
--   ): [S, Dispatch<A>] {

exports.useReducer = function(
	reducer: (any, any) -> any,
	initialArg: any,
	init: ((any) -> any)?
): (any, Dispatch<any?>)
	local dispatcher = resolveDispatcher()
	return dispatcher.useReducer(reducer, initialArg, init)
end

-- ROBLOX TODO: function generics
-- export function useRef<T>(initialValue: T): {|current: T|} {

exports.useRef = function(initialValue): { current: any }
	local dispatcher = resolveDispatcher()
	return dispatcher.useRef(initialValue)
end

-- ROBLOX TODO: function generics
-- export function useEffect(
-- 	create: () => (() => void) | void,
-- 	deps: Array<mixed> | void | null,
--   ): void {

exports.useEffect = function(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | ((() -> ()) -> ()),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useEffect(create, deps)
end

-- ROBLOX TODO: function generics
-- function useLayoutEffect(
-- 	create: () => (() => void) | void,
-- 	inputs: Array<mixed> | void | null,
--   ): void {
exports.useLayoutEffect = function(
	-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
	create: (() -> ()) | ((() -> ()) -> ()),
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useLayoutEffect(create, deps)
end

-- ROBLOX TODO: function generics
-- export function useCallback<T>(
-- 	callback: T,
-- 	deps: Array<mixed> | void | null,
--   ): T {
exports.useCallback = function(
	callback: _T,
	deps: Array<any> | nil
): _T
	local dispatcher = resolveDispatcher()
	return dispatcher.useCallback(callback, deps)
end

-- ROBLOX TODO: function generics
-- export function useMemo<T>(
-- 	create: () => T,
-- 	deps: Array<mixed> | void | null,
--   ): T {
exports.useMemo = function(
	create: () -> _T,
	deps: Array<any> | nil
): _T
	local dispatcher = resolveDispatcher()
	return dispatcher.useMemo(create, deps)
end

-- ROBLOX TODO: function generics:
-- export function useImperativeHandle<T>(
-- 	ref: {|current: T | null|} | ((inst: T | null) => mixed) | null | void,
-- 	create: () => T,
-- 	deps: Array<mixed> | void | null,
--   ): void {

exports.useImperativeHandle = function(
	ref: { current: _T | nil } | ((inst: _T | nil) -> any) | nil,
	create: () -> _T,
	deps: Array<any> | nil
): ()
	local dispatcher = resolveDispatcher()
	return dispatcher.useImperativeHandle(ref, create, deps)
end

-- ROBLOX TODO: function generics
-- export function useDebugValue<T>(
-- 	value: T,
-- 	formatterFn: ?(value: T) => mixed,
--   ): void {
	exports.useDebugValue = function(
	value: _T,
	formatterFn: ((value: _T) -> any)?
): ()
	if _G.__DEV__ then
		local dispatcher = resolveDispatcher()
		return dispatcher.useDebugValue(value, formatterFn)
	end

	-- deviation: return nil explicitly for safety
	return nil
end

exports.emptyObject = {}

-- ROBLOX TODO: enable useTransition later
-- exports.useTransition = function(): ((() -> ()) -> (), boolean)
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useTransition()
-- end

-- ROBLOX TODO: function generics
-- export function useDeferredValue<T>(value: T): T {
-- ROBLOX TODO: enable useTransition later
-- exports.useDeferredValue = function(value: _T): _T
-- 	local dispatcher = resolveDispatcher()
-- 	return dispatcher.useDeferredValue(value)
-- end

-- deviation: Stripped types from function signature
exports.useOpaqueIdentifier = function(): OpaqueIDType | nil
	local dispatcher = resolveDispatcher()
	return dispatcher.useOpaqueIdentifier()
end

-- deviation: Stripped types from function signature
-- ROBLOX TODO: function generics
-- function useMutableSource<Source, Snapshot>(
type Source = any
type Snapshot = any
exports.useMutableSource = function(
	source: MutableSource<Source>,
	getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
	subscribe: MutableSourceSubscribeFn<Source, Snapshot>
): Snapshot
	local dispatcher = resolveDispatcher()
	return dispatcher.useMutableSource(source, getSnapshot, subscribe)
end

return exports
