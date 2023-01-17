-- ROBLOX upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-cache/src/LRU.js

-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */
type Object = { [string]: any? }

local Packages = script.Parent.Parent
local Scheduler = require(Packages.Scheduler)
local exports = {}

-- ROBLOX deviation: predeclare methods to fix declaration ordering problems
local deleteLeastRecentlyUsedEntries
local cleanUp

-- Intentionally not named imports because Rollup would
-- use dynamic dispatch for CommonJS interop named imports.
local scheduleCallback = Scheduler.unstable_scheduleCallback
local IdlePriority = Scheduler.unstable_IdlePriority

export type Entry<T> = {
	value: T,
	onDelete: () -> ...any,
	previous: Entry<T>,
	next_: Entry<T>,
}

-- ROBLOX TODO: function generics
-- exports.createLRU = function<T>(limit: number)
exports.createLRU = function(limit: number)
	local LIMIT = limit

	-- Circular, doubly-linked list
	-- ROBLOX TODO: function generics
	local first: Entry<any> | nil = nil
	local size: number = 0

	local cleanUpIsScheduled: boolean = false

	local function scheduleCleanUp()
		if cleanUpIsScheduled == false and size > LIMIT then
			-- The cache size exceeds the limit. Schedule a callback to delete the
			-- least recently used entries.
			cleanUpIsScheduled = true
			scheduleCallback(IdlePriority, cleanUp)
		end
	end

	cleanUp = function()
		cleanUpIsScheduled = false
		deleteLeastRecentlyUsedEntries(LIMIT)
	end

	deleteLeastRecentlyUsedEntries = function(targetSize: number)
		-- Delete entries from the cache, starting from the end of the list.
		if first ~= nil then
			local resolvedFirst: Entry<any> = first :: any
			local last = resolvedFirst.previous
			while size > targetSize and last ~= nil do
				local onDelete = last.onDelete
				local previous = last.previous
				last.onDelete = nil :: any

				-- Remove from the list
				last.next_ = nil :: any
				last.previous = last.next_
				if last == first then
					-- Reached the head of the list.
					last = nil
					first = last
				else
					(first :: any).previous = previous
					previous.next_ = first :: any
					last = previous
				end

				size -= 1

				-- Call the destroy method after removing the entry from the list. If it
				-- throws, the rest of cache will not be deleted, but it will be in a
				-- valid state.
				onDelete()
			end
		end
	end

	-- ROBLOX TODO: function generics
	-- local function add(value: T, onDelete: () -> any): Entry<T>
	local function add(value: any, onDelete: () -> any): Entry<any>
		-- ROBLOX TODO: function generics
		local entry: Entry<any> = {
			value = value,
			onDelete = onDelete,
			next_ = nil,
			previous = nil,
		}
		if first == nil then
			entry.next_ = entry
			entry.previous = entry.next_
			first = entry
		else
			-- Append to head
			-- ROBLOX FIXME: function generics, remove recast once Luau understands nil check
			local last = (first :: Entry<any>).previous
			last.next_ = entry
			entry.previous = last;
			(first :: Entry<any>).previous = entry
			entry.next_ = first :: Entry<any>

			first = entry
		end
		size += 1
		return entry
	end

	-- ROBLOX TODO: function generics
	-- local function update(entry: Entry<T>, newValue: T): ()
	local function update(entry: Entry<any>, newValue: any): ()
		entry.value = newValue
	end

	-- ROBLOX TODO: function generics
	-- local function access(entry: Entry<T>): T
	local function access(entry: Entry<any>): any
		local next_ = entry.next_
		if next_ ~= nil then
			-- Entry already cached
			-- ROBLOX TODO: function generics
			local resolvedFirst: Entry<any> = first :: Entry<any>
			if first ~= entry then
				-- Remove from current position
				local previous = entry.previous
				previous.next_ = next_
				next_.previous = previous

				-- Append to head
				local last = resolvedFirst.previous
				last.next_ = entry
				entry.previous = last

				resolvedFirst.previous = entry
				entry.next_ = resolvedFirst

				first = entry
			end
		else
			-- Cannot access a deleted entry
			-- TODO: Error? Warning?
		end
		scheduleCleanUp()
		return entry.value
	end

	local function setLimit(newLimit: number)
		LIMIT = newLimit
		scheduleCleanUp()
	end

	return {
		add = add,
		update = update,
		access = access,
		setLimit = setLimit,
	}
end

return exports
