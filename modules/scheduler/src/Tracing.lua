--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Tracing.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

type Function = (any) -> any
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Set<T> = LuauPolyfill.Set<T>
local Set = LuauPolyfill.Set
local exports = {}

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing

export type Interaction = {
	__count: number,
	id: number,
	name: string,
	timestamp: number,
}

export type Subscriber = {
	-- A new interaction has been created via the trace() method.
	onInteractionTraced: (Interaction) -> (),

	-- All scheduled async work for an interaction has finished.
	onInteractionScheduledWorkCompleted: (Interaction) -> (),

	-- New async work has been scheduled for a set of interactions.
	-- When this work is later run, onWorkStarted/onWorkStopped will be called.
	-- A batch of async/yieldy work may be scheduled multiple times before completing.
	-- In that case, onWorkScheduled may be called more than once before onWorkStopped.
	-- Work is scheduled by a "thread" which is identified by a unique ID.
	onWorkScheduled: (Set<Interaction>, number) -> (),

	-- A batch of scheduled work has been canceled.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkCanceled: (Set<Interaction>, number) -> (),

	-- A batch of work has started for a set of interactions.
	-- When this work is complete, onWorkStopped will be called.
	-- Work is not always completed synchronously yielding may occur in between.
	-- A batch of async/yieldy work may also be re-started before completing.
	-- In that case, onWorkStarted may be called more than once before onWorkStopped.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkStarted: (Set<Interaction>, number) -> (),

	-- A batch of work has completed for a set of interactions.
	-- Work is done by a "thread" which is identified by a unique ID.
	onWorkStopped: (Set<Interaction>, number) -> (),
	-- ...
}

export type InteractionsRef = { current: Set<Interaction> }

export type SubscriberRef = { current: Subscriber | nil }

local DEFAULT_THREAD_ID = 0

-- Counters used to generate unique IDs.
local interactionIDCounter: number = 0
local threadIDCounter: number = 0

-- Set of currently traced interactions.
-- Interactions "stack"–
-- Meaning that newly traced interactions are appended to the previously active set.
-- When an interaction goes out of scope, the previous set (if any) is restored.
local interactionsRef: InteractionsRef

-- Listener(s) to notify when interactions begin and end.
local subscriberRef: SubscriberRef

if enableSchedulerTracing then
	interactionsRef = {
		current = Set.new(),
	}
	subscriberRef = {
		current = nil,
	}
end

exports.__interactionsRef = interactionsRef
exports.__subscriberRef = subscriberRef

exports.unstable_clear = function(callback: Function)
	if not enableSchedulerTracing then
		return callback()
	end

	local prevInteractions = interactionsRef.current
	interactionsRef.current = Set.new()

	-- ROBLOX try
	local ok, result = pcall(callback)
	-- ROBLOX finally
	interactionsRef.current = prevInteractions

	if not ok then
		error(result)
	end

	return result
end

exports.unstable_getCurrent = function(): Set<Interaction> | nil
	if not enableSchedulerTracing then
		return nil
	else
		return interactionsRef.current
	end
end

exports.unstable_getThreadID = function(): number
	threadIDCounter += 1
	return threadIDCounter
end

exports.unstable_trace =
	function(name: string, timestamp: number, callback: Function, threadID_: number?): any
		-- ROBLOX: default argument value
		local threadID = if threadID_ ~= nil then threadID_ else DEFAULT_THREAD_ID

		if not enableSchedulerTracing then
			return callback()
		end

		local interaction: Interaction = {
			__count = 1,
			id = interactionIDCounter,
			name = name,
			timestamp = timestamp,
		}
		interactionIDCounter += 1

		local prevInteractions = interactionsRef.current

		-- Traced interactions should stack/accumulate.
		-- To do that, clone the current interactions.
		-- The previous set will be restored upon completion.
		local interactions = Set.new(prevInteractions)
		interactions:add(interaction)
		interactionsRef.current = interactions

		local subscriber = subscriberRef.current
		local returnValue

		-- ROBLOX try
		local ok, result = pcall(function()
			if subscriber ~= nil then
				subscriber.onInteractionTraced(interaction)
			end
		end)
		-- ROBLOX finally
		-- ROBLOX try 2
		local ok2, result2 = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkStarted(interactions, threadID)
			end
		end)

		-- ROBLOX finally 2
		-- ROBLOX try 3
		local ok3, result3 = pcall(function()
			returnValue = callback()
		end)
		-- ROBLOX finally 3
		interactionsRef.current = prevInteractions
		-- ROBLOX try 4
		local ok4, result4 = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkStopped(interactions, threadID)
			end
		end)
		-- ROBLOX finally 4
		interaction.__count -= 1

		-- If no async work was scheduled for this interaction,
		-- Notify subscribers that it's completed.
		if subscriber ~= nil and interaction.__count == 0 then
			subscriber.onInteractionScheduledWorkCompleted(interaction)
		end

		if not ok4 then
			error(result4)
		end

		if not ok3 then
			error(result3)
		end

		if not ok2 then
			error(result2)
		end

		if not ok then
			error(result)
		end

		return returnValue
	end

exports.unstable_wrap = function(
	callback: Function,
	threadID: number
): any -- ROLBOX deviation: any, since __call doesn't map to Function
	-- ROBLOX: default argument value
	if threadID == nil then
		threadID = DEFAULT_THREAD_ID
	end

	if not enableSchedulerTracing then
		return callback
	end

	local wrappedInteractions = interactionsRef.current

	local subscriber = subscriberRef.current
	if subscriber ~= nil then
		subscriber.onWorkScheduled(wrappedInteractions, threadID)
	end

	-- Update the pending async work count for the current interactions.
	-- Update after calling subscribers in case of error.
	for _, interaction in wrappedInteractions do
		interaction.__count += 1
	end

	local hasRun = false

	local function _wrapped(self, ...)
		local prevInteractions = interactionsRef.current
		interactionsRef.current = wrappedInteractions

		subscriber = subscriberRef.current

		-- ROBLOX try
		local ok, result = pcall(function(...)
			local returnValue

			-- ROBLOX try 2
			local ok2, result2 = pcall(function()
				if subscriber ~= nil then
					subscriber.onWorkStarted(wrappedInteractions, threadID)
				end
			end)
			-- ROBLOX finally 2
			-- ROBLOX try 3
			local ok3, result3 = pcall(function(...)
				returnValue = callback(...)
			end, ...)
			-- ROBLOX finally 3
			interactionsRef.current = prevInteractions

			if subscriber ~= nil then
				subscriber.onWorkStopped(wrappedInteractions, threadID)
			end

			if not ok3 then
				error(result3)
			end

			if not ok2 then
				error(result2)
			end

			return returnValue
		end, ...)

		-- ROBLOX finally {
		if not hasRun then
			-- We only expect a wrapped function to be executed once,
			-- But in the event that it's executed more than once–
			-- Only decrement the outstanding interaction counts once.
			hasRun = true

			-- Update pending async counts for all wrapped interactions.
			-- If this was the last scheduled async work for any of them,
			-- Mark them as completed.
			for _, interaction in wrappedInteractions do
				interaction.__count -= 1

				if subscriber ~= nil and interaction.__count == 0 then
					subscriber.onInteractionScheduledWorkCompleted(interaction)
				end
			end
		end

		if not ok then
			error(result)
		end

		return result
	end

	local _cancel = function()
		subscriber = subscriberRef.current

		local ok, result = pcall(function()
			if subscriber ~= nil then
				subscriber.onWorkCanceled(wrappedInteractions, threadID)
			end
		end)
		--ROBLOX finally {
		-- Update pending async counts for all wrapped interactions.
		-- If this was the last scheduled async work for any of them,
		-- Mark them as completed.
		for _, interaction in wrappedInteractions do
			interaction.__count -= 1

			if subscriber ~= nil and interaction.__count == 0 then
				subscriber.onInteractionScheduledWorkCompleted(interaction)
			end
		end

		if not ok then
			error(result)
		end
	end

	local wrapped = {}
	setmetatable(wrapped, {
		__call = _wrapped,
	})
	wrapped.cancel = _cancel

	return wrapped
end

return exports
