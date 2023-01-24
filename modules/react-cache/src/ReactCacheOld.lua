-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-cache/src/ReactCacheOld.js
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
-- ROBLOX deviation START: unnecessary import
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
-- ROBLOX deviation START: add inspect to print objects
local inspect = LuauPolyfill.util.inspect
-- ROBLOX deviation END
-- ROBLOX deviation START: not needed
-- local Error = LuauPolyfill.Error
-- local Map = LuauPolyfill.Map
-- ROBLOX deviation END
-- ROBLOX deviation START: use console from React Shared
-- local console = LuauPolyfill.console
local console = require(Packages.Shared).console
-- ROBLOX deviation END
type Map<T, U> = LuauPolyfill.Map<T, U>
local exports = {}
-- ROBLOX deviation START: add predeclared methods to fix declaration ordering
local deleteEntry
-- ROBLOX deviation END
-- ROBLOX deviation START: fix import
-- local sharedReactTypesModule = require(Packages.shared.ReactTypes)
-- type Thenable = sharedReactTypesModule.Thenable
local ReactTypes = require(Packages.Shared)
type Thenable<R> = ReactTypes.Thenable<R>
-- ROBLOX deviation END
local React = require(Packages.React)
local createLRU = require(script.Parent.LRU).createLRU
-- ROBLOX deviation START: add this type in an attempt to tighten up the types to detect bugs found manually
local LRU = require(script.Parent.LRU)
type Entry<T> = LRU.Entry<T>
type Record<K, V> = { [K]: V }
-- ROBLOX deviation END
-- ROBLOX deviation START: change then to andThen
-- type Suspender = { ["then"]: (resolve: () -> unknown, reject: () -> unknown) -> unknown } --[[ ROBLOX CHECK: inexact type upstream which is not supported by Luau. Verify if it doesn't break the analyze ]]
type Suspender = {
	andThen: (
		self: Suspender,
		resolve: (...any) -> () | Suspender,
		reject: (...any) -> () | Suspender
	) -> () | Suspender,
}
-- ROBLOX deviation END
type PendingResult = {
	status: number,--[[ ROBLOX NOTE: changed '0' to 'number' as Luau doesn't support numeric singleton types ]]
	value: Suspender,
}
type ResolvedResult<V> = {
	status: number,--[[ ROBLOX NOTE: changed '1' to 'number' as Luau doesn't support numeric singleton types ]]
	value: V,
}
type RejectedResult = {
	status: number,--[[ ROBLOX NOTE: changed '2' to 'number' as Luau doesn't support numeric singleton types ]]
	value: unknown,
}
type Result<V> = PendingResult | ResolvedResult<V> | RejectedResult
type Resource<I, V> = { read: (I) -> V, preload: (I) -> () } --[[ ROBLOX CHECK: inexact type upstream which is not supported by Luau. Verify if it doesn't break the analyze ]]
local Pending = 0
local Resolved = 1
local Rejected = 2
local ReactCurrentDispatcher =
	-- ROBLOX deviation START: import from Shared package
	-- React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
	require(Packages.Shared).ReactSharedInternals.ReactCurrentDispatcher
-- ROBLOX deviation END
local function readContext(Context, observedBits)
	local dispatcher = ReactCurrentDispatcher.current
	if dispatcher == nil then
		error(
			"react-cache: read and preload may only be called from within a "
				.. "component's render. They are not supported in event handlers or "
				.. "lifecycle methods."
		)
	end
	-- ROBLOX deviation START: use dot notation and additional cast as Luau doesn't narrow type to non-nil
	-- return dispatcher:readContext(Context, observedBits)
	return (dispatcher :: any).readContext(Context, observedBits)
	-- ROBLOX deviation END
end
local function identityHashFn(input)
	-- ROBLOX deviation START: remove unnecessary toJSBoolean and use _G
	-- if Boolean.toJSBoolean(__DEV__) then
	if _G.__DEV__ then
		-- ROBLOX deviation END
		if
			typeof(input) ~= "string"
			and typeof(input) ~= "number"
			and typeof(input) ~= "boolean"
			and input ~= nil
			-- ROBLOX deviation START: unnecessary duplicated condition - no difference between null and undefined
			-- and input ~= nil
			-- ROBLOX deviation END
		then
			console.error(
				"Invalid key type. Expected a string, number, symbol, or boolean, "
					.. "but instead received: %s"
					.. "\n\nTo use non-primitive values as keys, you must pass a hash "
					.. "function as the second argument to createResource().",
				-- ROBLOX deviation START: use inspect to print object
				-- input
				inspect(input)
				-- ROBLOX deviation END
			)
		end
	end
	return input
end
local CACHE_LIMIT = 500
local lru = createLRU(CACHE_LIMIT)
-- ROBLOX deviation START: tightened this up versus upstream to try and detect more bugs
-- local entries: Map<Resource<any, any>, Map<any, any>> = Map.new()
local entries: Record<Resource<any, any>, Record<number, Entry<any>>> = {}
-- ROBLOX deviation END
local CacheContext = React.createContext(nil)
local function accessResult<I, K, V>(
	resource: any,
	fetch: (I) -> Thenable<V>,
	input: I,
	key: K
): Result<V>
	-- ROBLOX deviation START: use regular indexing instead
	-- local entriesForResource = entries:get(resource)
	local entriesForResource = entries[resource]
	-- ROBLOX deviation END
	if entriesForResource == nil then
		-- ROBLOX deviation START: use table instead
		-- entriesForResource = Map.new()
		entriesForResource = {}
		-- ROBLOX deviation END
		-- ROBLOX deviation START: cast as Luau doesn't narrow type on itself and use regular index setting
		-- entries:set(resource, entriesForResource)
		entries[resource] = entriesForResource :: Record<number, Entry<any>>
		-- ROBLOX deviation END
	end
	-- ROBLOX deviation START: cast as Luau doesn't narrow type on itself
	-- local entry = entriesForResource:get(key)
	local entriesForResource_ = (
		entriesForResource :: Record<any, Entry<any>>
	) :: Record<K, Entry<any>>
	local entry = entriesForResource_[key]
	-- ROBLOX deviation END
	if entry == nil then
		local thenable = fetch(input)
		-- ROBLOX deviation START: add reordered declaration so newResults so it can be referenced in andThen()
		local newResult: PendingResult = {
			status = Pending,
			value = thenable :: any,
		}
		-- ROBLOX deviation END
		-- ROBLOX deviation START: use andThen
		-- thenable:then_(function(value)
		thenable:andThen(function(value)
			-- ROBLOX deviation END
			if newResult.status == Pending then
				local resolvedResult: ResolvedResult<V> = newResult :: any
				resolvedResult.status = Resolved
				resolvedResult.value = value
			end
			-- ROBLOX deviation START: explicit return type
			-- end, function(error_)
		end, function(error_): ()
			-- ROBLOX deviation END
			if newResult.status == Pending then
				local rejectedResult: RejectedResult = newResult :: any
				rejectedResult.status = Rejected
				rejectedResult.value = error_
			end
		end)
		-- ROBLOX deviation START: skip reordered code
		-- local newResult: PendingResult = { status = Pending, value = thenable }
		-- ROBLOX deviation END
		-- ROBLOX deviation START: use dot notation
		-- local newEntry = lru:add(newResult, function(...)
		local newEntry = lru.add(newResult, function(...)
			-- ROBLOX deviation END
			-- ROBLOX deviation START: deleteEntry doesn't use 'self'
			-- return deleteEntry(nil, resource, key, ...)
			return deleteEntry(resource, key :: any)
			-- ROBLOX deviation END
		end)
		-- ROBLOX deviation START: use casted variable as Luau doesn't narrow type on itself
		-- entriesForResource:set(key, newEntry)
		entriesForResource_[key] = newEntry
		-- ROBLOX deviation END
		return newResult
	else
		-- ROBLOX deviation START: use dot notation
		-- return lru:access(entry) :: any
		return lru.access(entry) :: any
		-- ROBLOX deviation END
	end
end
-- ROBLOX deviation START: predeclared function
-- local function deleteEntry(resource, key)
function deleteEntry(resource, key): ()
	-- ROBLOX deviation END
	-- ROBLOX deviation START: use regular indexer
	-- local entriesForResource = entries:get(resource)
	local entriesForResource = entries[resource]
	-- ROBLOX deviation END
	if entriesForResource ~= nil then
		-- ROBLOX deviation START: set property to nil instead
		-- entriesForResource:delete(key)
		entriesForResource[key] = nil
		-- ROBLOX deviation END
		-- ROBLOX deviation START: use # operator instead
		-- if entriesForResource.size == 0 then
		if #entriesForResource == 0 then
			-- ROBLOX deviation END
			-- ROBLOX deviation START: set property to nil instead
			-- entries:delete(resource)
			entries[resource] = nil
			-- ROBLOX deviation END
		end
	end
end
local function unstable_createResource<
	I,
	K, --[[ ROBLOX CHECK: upstream type uses type constraint which is not supported by Luau ]] --[[ K: string | number ]]
	V
>(
	fetch: (
		I
	) -> Thenable<V>,
	maybeHashInput: (
		(I) -> K
	)?
): Resource<
	I,
	V
>
	local hashInput: (I) -> K = if maybeHashInput ~= nil
		then maybeHashInput
		else identityHashFn :: any
	-- ROBLOX deviation START: split declaration and assignment
	-- local resource = {
	local resource
	resource = {
		-- ROBLOX deviation END
		-- ROBLOX deviation START: no self param
		-- read = function(self, input: I): V
		read = function(input: I): V
			-- ROBLOX deviation END
			-- react-cache currently doesn't rely on context, but it may in the
			-- future, so we read anyway to prevent access outside of render.
			readContext(CacheContext)
			local key = hashInput(input)
			local result: Result<V> = accessResult(resource, fetch, input, key)
			-- ROBLOX deviation START: simplify switch statement conversion
			-- repeat --[[ ROBLOX comment: switch statement conversion ]]
			-- 	local entered_, break_ = false, false
			-- 	local condition_ = result.status
			-- 	for _, v in ipairs({ Pending, Resolved, Rejected }) do
			-- 		if condition_ == v then
			-- 			if v == Pending then
			-- 				entered_ = true
			-- 				do
			-- 					local suspender = result.value
			-- 					error(suspender)
			-- 				end
			-- 			end
			-- 			if v == Resolved or entered_ then
			-- 				entered_ = true
			-- 				do
			-- 					local value = result.value
			-- 					return value
			-- 				end
			-- 			end
			-- 			if v == Rejected or entered_ then
			-- 				entered_ = true
			-- 				do
			-- 					local error_ = result.value
			-- 					error(error_)
			-- 				end
			-- 			end
			-- 		end
			-- 	end
			-- 	if not break_ then
			-- 		-- Should be unreachable
			-- 		return nil :: any
			-- 	end
			-- until true
			if result.status == Pending then
				local suspender = result.value
				error(suspender)
			elseif result.status == Resolved then
				local value = result.value
				-- ROBLOX deviation START: needs cast to narrow type
				-- return value
				return value :: V
				-- ROBLOX deviation END
			elseif result.status == Rejected then
				local error_ = result.value
				error(error_)
			else
				-- Should be unreachable
				return nil :: any
			end
			-- ROBLOX deviation END
		end,
		-- ROBLOX deviation START: no self param
		-- preload = function(self, input: I): ()
		preload = function(input: I): ()
			-- ROBLOX deviation END
			-- react-cache currently doesn't rely on context, but it may in the
			-- future, so we read anyway to prevent access outside of render.
			readContext(CacheContext)
			local key = hashInput(input)
			accessResult(resource, fetch, input, key)
		end,
	}
	return resource
end
exports.unstable_createResource = unstable_createResource
local function unstable_setGlobalCacheLimit(limit: number)
	-- ROBLOX deviation START: use dot notation
	-- lru:setLimit(limit)
	lru.setLimit(limit)
	-- ROBLOX deviation END
end
exports.unstable_setGlobalCacheLimit = unstable_setGlobalCacheLimit
return exports
