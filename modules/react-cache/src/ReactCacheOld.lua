-- Upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-cache/src/ReactCacheOld.js

-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent
local console = require(Packages.Shared).console
local LuauPolyfill = require(Packages.LuauPolyfill)
local inspect = LuauPolyfill.util.inspect
type Map<K, V> = { [K]: V }
type Object = { [string]: any }
local ReactTypes = require(Packages.Shared)
local React = require(Packages.React)
type Thenable<R> = ReactTypes.Thenable<R>

-- ROBLOX deviation: predeclare methods to fix declaration ordering
local deleteEntry

local LRU = require(script.Parent.LRU)
local createLRU = LRU.createLRU
-- ROBLOX devition: pull in this type in an attempt to tighten up the types to detect bugs found manually
type Entry<T> = LRU.Entry<T>

-- ROBLOX deviation: use andThen convention, aligned to be compatible with Thenable in Luau's analysis
type Suspender = {
	andThen: (
		self: Suspender,
		resolve: (...any) -> () | Suspender,
		reject: (...any) -> () | Suspender
	) -> () | Suspender,
}

type PendingResult = {
	status: number,
	value: Suspender,
}

type ResolvedResult<V> = {
	status: number,
	value: V,
}

type RejectedResult = {
	status: number,
	value: any,
}

type Result<V> = PendingResult | ResolvedResult<V> | RejectedResult

type Resource<I, V> = {
	read: (I) -> V,
	preload: (I) -> (),
}

local Pending = 0
local Resolved = 1
local Rejected = 2

local ReactCurrentDispatcher =
	require(Packages.Shared).ReactSharedInternals.ReactCurrentDispatcher

local exports = {}

local function readContext(Context, observedBits)
	local dispatcher = ReactCurrentDispatcher.current
	if dispatcher == nil then
		error(
			"react-cache: read and preload may only be called from within a "
				.. "component's render. They are not supported in event handlers or "
				.. "lifecycle methods."
		)
	end
	return dispatcher.readContext(Context, observedBits)
end

local function identityHashFn(input)
	if _G.__DEV__ then
		if
			typeof(input) ~= "string"
			and typeof(input) ~= "number"
			and typeof(input) ~= "boolean"
			and input ~= nil
		then
			console.error(
				"Invalid key type. Expected a string, number, symbol, or boolean, "
					.. "but instead received: %s"
					.. "\n\nTo use non-primitive values as keys, you must pass a hash "
					.. "function as the second argument to createResource().",
				inspect(input)
			)
		end
	end
	return input
end

local CACHE_LIMIT = 500
local lru = createLRU(CACHE_LIMIT)

-- ROBLOX deviation: tightened this up versus upstream to try and detect more bugs
local entries: Map<Resource<any, any>, Map<number, Entry<any>>> = {}

local CacheContext = React.createContext(nil)

-- ROBLOX TODO: use function generics when they are unflagged
-- local function accessResult<I, K, V>(
--    resource: any,
--    fetch: (I) -> Thenable<V, any>,
--    input: I,
--    key: K
-- ): Result<V>
local function accessResult(
	resource: any,
	fetch: (any) -> Thenable<any>,
	input: any,
	key: any
): Result<any>
	local entriesForResource = entries[resource]
	local entry
	if entriesForResource == nil then
		entriesForResource = {}
		entries[resource] = entriesForResource
	else
		-- ROBLOX performance: only assign the entry if its not a new table
		entry = entriesForResource[key]
	end

	if entry == nil then
		local thenable = fetch(input)

		-- ROBLOX deviation: reorder so newResult can be referenced in andThen()
		local newResult: PendingResult = {
			status = Pending,
			value = thenable,
		}

		thenable:andThen(function(value)
			if newResult.status == Pending then
				-- ROBLOX TODO: use function generics
				local resolvedResult: ResolvedResult<any> = newResult :: any
				resolvedResult.status = Resolved
				resolvedResult.value = value
			end
		end, function(error_)
			if newResult.status == Pending then
				local rejectedResult: RejectedResult = newResult :: any
				rejectedResult.status = Rejected
				rejectedResult.value = error_
			end
		end)

		local newEntry = lru.add(newResult, function()
			return deleteEntry(resource, key)
		end)
		entriesForResource[key] = newEntry
		return newResult
	else
		return (lru.access(entry) :: any)
	end
end

deleteEntry = function(resource, key)
	local entriesForResource = entries[resource]
	if entriesForResource ~= nil then
		entriesForResource[key] = nil
		if #entriesForResource == 0 then
			entries[resource] = nil
		end
	end
end

-- ROBLOX TODO: function generics and constraints
-- export function unstable_createResource<I, K: string | number, V>(
-- exports.unstable_createResource = function<I, K, V>(
--     fetch: (I) -> Thenable<V, any>,
--     maybeHashInput: ((I) -> K)?
--  ): Resource<I, V>
exports.unstable_createResource = function(
	fetch: (any) -> Thenable<any>,
	maybeHashInput: ((any) -> any)?
): Resource<any, any>
	local hashInput: (any) -> any
	if maybeHashInput ~= nil then
		-- ROBLOX TODO: remove recast once Luau understands nil check
		hashInput = maybeHashInput :: (any) -> any
	else
		hashInput = identityHashFn :: any
	end

	local resource
	resource = {
		-- ROBLOX TODO: function generics and constraints
		read = function(input: any): any
			-- react-cache currently doesn't rely on context, but it may in the
			-- future, so we read anyway to prevent access outside of render.
			readContext(CacheContext)
			local key = hashInput(input)
			-- ROBLOX TODO: function generics and constraints
			local result: Result<any> = accessResult(resource, fetch, input, key)
			if result.status == Pending then
				local suspender = result.value
				error(suspender)
			elseif result.status == Resolved then
				local value = result.value
				return value
			elseif result.status == Rejected then
				local error_ = result.value
				error(error_)
			else
				-- Should be unreachable
				return nil :: any
			end
		end,

		-- ROBLOX TODO: function generics and constraints
		preload = function(input: any): ()
			-- react-cache currently doesn't rely on context, but it may in the
			-- future, so we read anyway to prevent access outside of render.
			readContext(CacheContext)
			local key = hashInput(input)
			accessResult(resource, fetch, input, key)
		end,
	}
	return resource
end

exports.unstable_setGlobalCacheLimit = function(limit: number)
	lru.setLimit(limit)
end

return exports
