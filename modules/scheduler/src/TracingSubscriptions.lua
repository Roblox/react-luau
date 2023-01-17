-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/TracingSubscriptions.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */
type Set<T> = { [T]: boolean? }
type Array<T> = { [number]: T }
local exports = {}
local Packages = script.Parent.Parent
local Object = require(Packages.LuauPolyfill).Object

local Tracing = require(script.Parent.Tracing)
type Interaction = Tracing.Interaction
type Subscriber = Tracing.Subscriber

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags

local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local __subscriberRef = Tracing.__subscriberRef

local subscribers: Set<Subscriber> = {}
if enableSchedulerTracing then
	subscribers = {}
end

exports.unstable_subscribe = function(subscriber: Subscriber): ()
	if enableSchedulerTracing then
		subscribers[subscriber] = true

		if #Object.keys(subscribers) == 1 then
			__subscriberRef.current = {
				onInteractionScheduledWorkCompleted = onInteractionScheduledWorkCompleted,
				onInteractionTraced = onInteractionTraced,
				onWorkCanceled = onWorkCanceled,
				onWorkScheduled = onWorkScheduled,
				onWorkStarted = onWorkStarted,
				onWorkStopped = onWorkStopped,
			}
		end
	end
end

exports.unstable_unsubscribe = function(subscriber: Subscriber): ()
	if enableSchedulerTracing then
		subscribers[subscriber] = nil

		if #Object.keys(subscribers) == 0 then
			__subscriberRef.current = nil
		end
	end
end

function onInteractionTraced(interaction: Interaction): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onInteractionTraced, interaction)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onInteractionScheduledWorkCompleted(interaction: Interaction): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result =
			pcall(subscriber.onInteractionScheduledWorkCompleted, interaction)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkScheduled(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkScheduled, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkStarted(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkStarted, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkStopped(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkStopped, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

function onWorkCanceled(interactions: Set<Interaction>, threadID: number): ()
	local didCatchError = false
	local caughtError = nil

	for subscriber, _ in subscribers do
		-- ROBLOX try
		local ok, result = pcall(subscriber.onWorkCanceled, interactions, threadID)
		-- ROBLOX catch
		if not ok then
			local error_ = result
			if not didCatchError then
				didCatchError = true
				caughtError = error_
			end
		end
	end

	if didCatchError then
		error(caughtError)
	end
end

return exports
