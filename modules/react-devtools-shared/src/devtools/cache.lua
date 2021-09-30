-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/devtools/cache.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local Map = LuauPolyfill.Map
local WeakMap = LuauPolyfill.WeakMap

type Map<K, V> = LuauPolyfill.Map<K, V>
type WeakMap<K, V> = LuauPolyfill.WeakMap<K, V>

local ReactTypes = require(Packages.Shared)
export type Thenable<R> = ReactTypes.Thenable<R>

local React = require(Packages.React)
local createContext = React.createContext

-- Cache implementation was forked from the React repo:
-- https://github.com/facebook/react/blob/master/packages/react-cache/src/ReactCache.js
--
-- This cache is simpler than react-cache in that:
-- 1. Individual items don't need to be invalidated.
--    Profiling data is invalidated as a whole.
-- 2. We didn't need the added overhead of an LRU cache.
--    The size of this cache is bounded by how many renders were profiled,
--    and it will be fully reset between profiling sessions.

type Suspender = { andThen: (() -> any, () -> any) -> any }

type PendingResult = {
	status: number, -- ROBLOX TODO: Luau doesn't support literal: 0
	value: Suspender,
}

type ResolvedResult<Value> = {
	status: number, -- ROBLOX TODO: Luau doesn't support literal: 1
	value: Value,
}

type RejectedResult = {
	status: number, -- ROBLOX TODO: Luau doesn't support literal: 2
	value: any,
}

type Result<Value> = PendingResult | ResolvedResult<Value> | RejectedResult

export type Resource<Input, Key, Value> = {
	clear: () -> (),
	invalidate: (Key) -> (),
	read: (Input) -> Value,
	preload: (Input) -> (),
	write: (Key, Value) -> (),
}

local Pending = 0
local Resolved = 1
local Rejected = 2

local ReactCurrentDispatcher =
	React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher

local function readContext(Context, observedBits)
	local dispatcher = ReactCurrentDispatcher.current
	if dispatcher == nil then
		error(
			Error.new(
				"react-cache: read and preload may only be called from within a "
					.. "component's render. They are not supported in event handlers or "
					.. "lifecycle methods."
			)
		)
	end
	return dispatcher:readContext(Context, observedBits)
end

local CacheContext = createContext(nil)

type Config = { useWeakMap: boolean? }

local entries: Map<Resource<any, any, any>, Map<any, any> | WeakMap<any, any>> = Map.new()
local resourceConfigs: Map<Resource<any, any, any>, Config> = Map.new()

local function getEntriesForResource(resource: any): Map<any, any> | WeakMap<any, any>
	local entriesForResource = entries:get(resource)
	if entriesForResource == nil then
		local config = resourceConfigs:get(resource)

		entriesForResource = (function()
			if config ~= nil and config.useWeakMap then
				return WeakMap.new()
			end
			return Map.new()
		end)()

		entries:set(resource, entriesForResource)
	end

	return entriesForResource
end

-- ROBLOX TODO: Support function generics
-- accessResult<Input, Key, Value>(resource, fetch: Input -> Thenable<Value>, input: Input, key: Key)
local function accessResult(
	resource: any,
	fetch: (any) -> Thenable<any>,
	input: any,
	key: any
): Result<any>
	local entriesForResource = getEntriesForResource(resource)
	local entry = entriesForResource:get(key)

	if entry == nil then
		local thenable = fetch(input)

		-- ROBLOX deviation: define before use
		local newResult = {
			status = Pending,
		}

		thenable:andThen(function(value)
			if newResult.status == Pending then
				local resolvedResult = newResult

				resolvedResult.status = Resolved
				resolvedResult.value = value
			end
		end, function(error_)
			if newResult.status == Pending then
				local rejectedResult = newResult

				rejectedResult.status = Rejected
				rejectedResult.value = error_
			end
		end)

		-- ROBLOX deviation: deferred assign
		newResult.value = thenable

		entriesForResource[key] = newResult

		return newResult
	else
		return entry
	end
end

local exports = {}

-- ROBLOX TODO: function generics
-- export function createResource<Input, Key, Value>(
--     fetch: Input => Thenable<Value>,
--     hashInput: Input => Key,
--     config?: Config = {},
--   ): Resource<Input, Key, Value> {
type Input = any
type Key = any
type Value = any
exports.createResource = function(
	fetch: (Input) -> Thenable<Value>,
	hashInput: (Input) -> Key,
	config: Config?
): Resource<Input, Key, Value>
	config = config or {}
	-- ROBLOX deviation: define before reference
	local resource
	resource = {
		clear = function(): ()
			entries[resource] = nil
		end,
		invalidate = function(key: Key): ()
			local entriesForResource = getEntriesForResource(resource)
			entriesForResource[key] = nil
		end,
		read = function(input: Input): Value
			readContext(CacheContext)
			local key = hashInput(input)
			local result = accessResult(resource, fetch, input, key)
			if result.status == Pending then
				error(result.value)
			elseif result.status == Resolved then
				return result.value
			elseif result.status == Rejected then
				error(result.value)
			else
				-- Should be unreachable
				return nil
			end
		end,
		preload = function(input: Input): ()
			readContext(CacheContext)
			local key = hashInput(input)
			accessResult(resource, fetch, input, key)
		end,
		write = function(key: Key, value: Value): ()
			local entriesForResource = getEntriesForResource(resource)
			local resolvedResult = {
				status = Resolved,
				value = value,
			}

			entriesForResource[key] = resolvedResult
		end,
	}

	resourceConfigs[resource] = config

	return resource
end

exports.invalidateResources = function(): ()
	entries = Map.new()
end

return exports
