-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-cache/src/LRU.js
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
type Object = LuauPolyfill.Object
local exports = {}
-- ROBLOX deviation START: fix import
-- local Scheduler = require(Packages.scheduler) -- Intentionally not named imports because Rollup would
local Scheduler = require(Packages.Scheduler)
-- ROBLOX deviation END
-- use dynamic dispatch for CommonJS interop named imports.
local scheduleCallback, IdlePriority =
	Scheduler.unstable_scheduleCallback, Scheduler.unstable_IdlePriority
-- ROBLOX deviation START: use next_ instead
-- type Entry<T> = { value: T, onDelete: () -> unknown, previous: Entry<T>, next: Entry<T> }
export type Entry<T> = {
	value: T,
	onDelete: () -> ...unknown,
	previous: Entry<T>,
	next_: Entry<T>,
}
-- ROBLOX deviation END
local function createLRU<T>(limit: number)
	-- ROBLOX deviation START: add predeclared methods to fix declaration ordering problems
	local deleteLeastRecentlyUsedEntries
	local cleanUp
	-- ROBLOX deviation END
	local LIMIT = limit -- Circular, doubly-linked list
	local first: Entry<T> | nil --[[ ROBLOX CHECK: verify if `null` wasn't used differently than `undefined` ]] =
		nil
	local size: number = 0
	local cleanUpIsScheduled: boolean = false
	local function scheduleCleanUp()
		if
			cleanUpIsScheduled == false
			and size > LIMIT --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
		then
			-- The cache size exceeds the limit. Schedule a callback to delete the
			-- least recently used entries.
			cleanUpIsScheduled = true
			scheduleCallback(IdlePriority, cleanUp)
		end
	end
	-- ROBLOX deviation START: predeclared function
	-- local function cleanUp()
	function cleanUp()
		-- ROBLOX deviation END
		cleanUpIsScheduled = false
		deleteLeastRecentlyUsedEntries(LIMIT)
	end
	-- ROBLOX deviation START: predeclared function
	-- local function deleteLeastRecentlyUsedEntries(targetSize: number)
	function deleteLeastRecentlyUsedEntries(targetSize: number)
		-- ROBLOX deviation END
		-- Delete entries from the cache, starting from the end of the list.
		if first ~= nil then
			local resolvedFirst: Entry<T> = first :: any
			-- ROBLOX deviation START: explicitly type last
			-- local last = resolvedFirst.previous
			local last: Entry<T>? = resolvedFirst.previous
			-- ROBLOX deviation END
			while
				size > targetSize --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
				and last ~= nil
			do
				local onDelete = last.onDelete
				local previous = last.previous
				last.onDelete = nil :: any -- Remove from the list
				-- ROBLOX deviation START: use next_ instead
				-- last.next = nil :: any
				-- last.previous = last.next
				last.next_ = nil :: any
				last.previous = last.next_
				-- ROBLOX deviation END
				if last == first then
					-- Reached the head of the list.
					last = nil
					first = last
				else
					(first :: any).previous = previous
					-- ROBLOX deviation START: use next_ instead
					-- previous.next = first :: any
					previous.next_ = first :: any
					-- ROBLOX deviation END
					last = previous
				end
				size -= 1 -- Call the destroy method after removing the entry from the list. If it
				-- throws, the rest of cache will not be deleted, but it will be in a
				-- valid state.
				onDelete()
			end
		end
	end
	local function add(value: Object, onDelete: () -> unknown): Entry<Object>
		local entry = {
			value = value,
			onDelete = onDelete,
			-- ROBLOX deviation START: use next_ instead
			-- next = nil :: any,
			next_ = nil :: any,
			-- ROBLOX deviation END
			previous = nil :: any,
			-- ROBLOX deviation START: need to cast to Entry<any>
			-- }
		} :: Entry<any>
		-- ROBLOX deviation END
		if first == nil then
			-- ROBLOX deviation START: use next_ instead
			-- entry.next = entry
			-- entry.previous = entry.next
			entry.next_ = entry
			entry.previous = entry.next_
			-- ROBLOX deviation END
			first = entry
		else
			-- Append to head
			local last = first.previous
			-- ROBLOX deviation START: use next_ instead
			-- last.next = entry
			last.next_ = entry
			-- ROBLOX deviation END
			entry.previous = last
			first.previous = entry
			-- ROBLOX deviation START: use next_ instead
			-- entry.next = first
			entry.next_ = first
			-- ROBLOX deviation END
			first = entry
		end
		size += 1
		return entry
	end
	local function update(entry: Entry<T>, newValue: T): ()
		entry.value = newValue
	end
	local function access(entry: Entry<T>): T
		-- ROBLOX deviation START: use next_ instead
		-- local next_ = entry.next
		local next_ = entry.next_
		-- ROBLOX deviation END
		if next_ ~= nil then
			-- Entry already cached
			local resolvedFirst: Entry<T> = first :: any
			if first ~= entry then
				-- Remove from current position
				local previous = entry.previous
				-- ROBLOX deviation START: use next_ instead
				-- previous.next = next_
				previous.next_ = next_
				-- ROBLOX deviation END
				next_.previous = previous -- Append to head
				local last = resolvedFirst.previous
				-- ROBLOX deviation START: use next_ instead
				-- last.next = entry
				last.next_ = entry
				-- ROBLOX deviation END
				entry.previous = last
				resolvedFirst.previous = entry
				-- ROBLOX deviation START: use next_ instead
				-- entry.next = resolvedFirst
				entry.next_ = resolvedFirst
				-- ROBLOX deviation END
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
	return { add = add, update = update, access = access, setLimit = setLimit }
end
exports.createLRU = createLRU
return exports
