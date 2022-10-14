--!strict
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
type Map<K, V> = LuauPolyfill.Map<K, V>
local WeakMap = LuauPolyfill.WeakMap
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

-- ROBLOX deviation START: Suspender needs a generic param to be type compatible with Thenable
export type Suspender<R = any> = {
	andThen: <U>(
		self: Thenable<R>,
		onFulfill: (R) -> () | U,
		onReject: (error: any) -> () | U
	) -> (),
}
-- ROBLOX deviation END

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

local function readContext(Context, observedBits: boolean?)
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
	assert(dispatcher ~= nil, "assert needed until Luau understands if nil then error()")
	return dispatcher.readContext(Context, observedBits)
end

local CacheContext = createContext(nil)

type Config = { useWeakMap: boolean? }

-- ROBLOX deviation START: only use WeakMap
local entries: Map<Resource<any, any, any>, WeakMap<any, any>> = Map.new()
local resourceConfigs: Map<Resource<any, any, any>, Config> = Map.new()

local function getEntriesForResource(resource: any): WeakMap<any, any>
	local entriesForResource = entries:get(resource) :: WeakMap<any, any>
	if entriesForResource == nil then
		-- ROBLOX deviation START: skip the check and just use WeakMap
		-- local config = resourceConfigs:get(resource)
		entriesForResource = WeakMap.new()
		-- ROBLOX deviation END

		entries:set(resource, entriesForResource :: WeakMap<any, any>)
	end

	return entriesForResource :: WeakMap<any, any>
end
-- ROBLOX deviation END

local function accessResult<Input, Key, Value>(
	resource: any,
	fetch: (Input) -> Thenable<Value>,
	input: Input,
	key: Key
): Result<Value>
	local entriesForResource = getEntriesForResource(resource)
	local entry = entriesForResource:get(key)

	if entry == nil then
		local thenable = fetch(input)

		local newResult: PendingResult

		thenable:andThen(function(value)
			if newResult.status == Pending then
				local resolvedResult: ResolvedResult<Value> = newResult :: any

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

		newResult = {
			status = Pending,
			value = thenable,
		}
		entriesForResource:set(key, newResult)
		return newResult
	else
		return entry
	end
end

local exports = {}

exports.createResource = function<Input, Key, Value>(
	fetch: (Input) -> Thenable<Value>,
	hashInput: (Input) -> Key,
	_config: Config?
): Resource<Input, Key, Value>
	local config = _config or {}
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
			local result: Result<Value> = accessResult(resource, fetch, input, key)
			if result.status == Pending then
				error(result.value)
			elseif result.status == Resolved then
				return result.value
			elseif result.status == Rejected then
				error(result.value)
			else
				-- Should be unreachable
				return nil :: any
			end
		end,
		preload = function(input: Input): ()
			readContext(CacheContext)

			local key = hashInput(input)
			accessResult(resource, fetch, input, key)
		end,
		write = function(key: Key, value: Value): ()
			local entriesForResource = getEntriesForResource(resource)
			local resolvedResult: ResolvedResult<Value> = {
				status = Resolved,
				value = value,
			}

			entriesForResource:set(key, resolvedResult)
		end,
	}

	resourceConfigs:set(resource, config)

	return resource
end

exports.invalidateResources = function(): ()
	entries:clear()
end

return exports
