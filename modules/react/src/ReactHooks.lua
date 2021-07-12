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
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
type ReactContext<T> = ReactTypes.ReactContext<T>

local invariant = require(Packages.Shared).invariant

local ReactCurrentDispatcher = require(Packages.Shared).ReactSharedInternals.ReactCurrentDispatcher

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
	return dispatcher
end

local exports = {}

-- ROBLOX TODO: Luau doesn't support function generics yet
exports.useContext = function(
	Context: ReactContext<any>,
	unstable_observedBits: number | boolean | nil,
	realContext,
	... -- ROBLOX deviation: Lua must specify ... here to capture additional args
)
	local dispatcher = resolveDispatcher()
	if _G.__DEV__ then
		if unstable_observedBits ~= nil then
			console.error(
				'useContext() second argument is reserved for future ' ..
					'use in React. Passing it is not supported. ' ..
					'You passed: %s.%s',
				unstable_observedBits,
				(typeof(unstable_observedBits) == 'number' and Array.isArray({...})) and
					'\n\nDid you call array.map(useContext)? ' ..
						'Calling Hooks inside a loop is not supported. ' ..
						'Learn more at https://reactjs.org/link/rules-of-hooks' or
					''
			)
		end

		-- TODO: add a more generic warning for invalid values.
		if Context._context ~= nil then
			local realContext = Context._context
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

-- deviation: Stripped types from function signature
exports.useState = function(initialState)
	local dispatcher = resolveDispatcher()
	return dispatcher.useState(initialState)
end

-- deviation: Stripped types from function signature
exports.useReducer = function(reducer, initialArg, init)
	local dispatcher = resolveDispatcher()
	return dispatcher.useReducer(reducer, initialArg, init)
end

-- deviation: Stripped types from function signature
exports.useRef = function(initialValue)
	local dispatcher = resolveDispatcher()
	return dispatcher.useRef(initialValue)
end

-- deviation: Stripped types from function signature
exports.useEffect = function(create, deps)
	local dispatcher = resolveDispatcher()
	return dispatcher.useEffect(create, deps)
end

-- deviation: Stripped types from function signature
exports.useLayoutEffect = function(create, deps)
	local dispatcher = resolveDispatcher()
	return dispatcher.useLayoutEffect(create, deps)
end

-- deviation: Stripped types from function signature
exports.useCallback = function(callback, deps)
	local dispatcher = resolveDispatcher()
	return dispatcher.useCallback(callback, deps)
end

-- deviation: Stripped types from function signature
exports.useMemo = function(create, deps)
	local dispatcher = resolveDispatcher()
	return dispatcher.useMemo(create, deps)
end

-- deviation: Stripped types from function signature
exports.useImperativeHandle = function(ref, create, deps)
	local dispatcher = resolveDispatcher()
	return dispatcher.useImperativeHandle(ref, create, deps)
end

-- deviation: Stripped types from function signature
exports.useDebugValue = function(value, formatterFn)
	if _G.__DEV__ then
		local dispatcher = resolveDispatcher()
		return dispatcher.useDebugValue(value, formatterFn)
	end

	-- deviation: return nil explicitly for safety
	return nil
end

exports.emptyObject = {}

-- deviation: Stripped types from function signature
exports.useTransition = function()
	local dispatcher = resolveDispatcher()
	return dispatcher.useTransition()
end

-- deviation: Stripped types from function signature
exports.useDeferredValue = function(value)
	local dispatcher = resolveDispatcher()
	return dispatcher.useDeferredValue(value)
end

-- deviation: Stripped types from function signature
exports.useOpaqueIdentifier = function()
	local dispatcher = resolveDispatcher()
	return dispatcher.useOpaqueIdentifier()
end

-- deviation: Stripped types from function signature
exports.useMutableSource = function(source, getSnapshot, subscribe)
	local dispatcher = resolveDispatcher()
	return dispatcher.useMutableSource(source, getSnapshot, subscribe)
end

return exports
