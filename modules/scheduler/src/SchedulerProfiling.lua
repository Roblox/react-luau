--!strict
-- ROBLOX upstream https://github.com/facebook/react/blob/8af27aeedbc6b00bc2ef49729fc84f116c70a27c/packages/scheduler/src/SchedulerProfiling.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]
-- ROBLOX NOTE: this file is synced against a post-17.0.1 version that doesn't use SharedArrayBuffer
local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local exports = {}

local SchedulerPriorities = require(script.Parent.SchedulerPriorities)
type PriorityLevel = SchedulerPriorities.PriorityLevel

local ScheduleFeatureFlags = require(script.Parent.SchedulerFeatureFlags)
local enableProfiling = ScheduleFeatureFlags.enableProfiling

local runIdCounter: number = 0
local mainThreadIdCounter: number = 0

-- Bytes per element is 4
local INITIAL_EVENT_LOG_SIZE = 131072
local MAX_EVENT_LOG_SIZE = 524288 -- Equivalent to 2 megabytes

-- Strictly speaking, only the first element of an EventLog can be a reference to another EventLog.
type EventLog = { EventLog | { number } }

local eventLogSize = 0
local eventLogBuffer = nil
local eventLog: EventLog? = nil
local eventLogIndex = 1

local TaskStartEvent = 1
local TaskCompleteEvent = 2
local TaskErrorEvent = 3
local TaskCancelEvent = 4
local TaskRunEvent = 5
local TaskYieldEvent = 6
local SchedulerSuspendEvent = 7
local SchedulerResumeEvent = 8

local function logEvent(entries)
	if eventLog ~= nil then
		-- ROBLOX deviation: upstream uses a packed array for performance. we do something simpler for now
		eventLogIndex += #entries
		if eventLogIndex + 1 > eventLogSize then
			eventLogSize *= 2
			if eventLogSize > MAX_EVENT_LOG_SIZE then
				-- Using console['error'] to evade Babel and ESLint
				console["error"](
					"Scheduler Profiling: Event log exceeded maximum size. Don't "
						.. "forget to call `stopLoggingProfilingEvents()`."
				)
				exports.stopLoggingProfilingEvents()
				return
			end
			local newEventLog = {}
			table.insert(newEventLog, eventLog)
			eventLogBuffer = newEventLog
			eventLog = newEventLog
		end
		table.insert(eventLog, entries)
	end
end

exports.startLoggingProfilingEvents = function()
	eventLogSize = INITIAL_EVENT_LOG_SIZE
	eventLogBuffer = {}
	eventLog = eventLogBuffer
	eventLogIndex = 1
end

exports.stopLoggingProfilingEvents = function()
	local buffer = eventLogBuffer
	eventLogSize = 0
	-- ROBLOX FIXME Luau: needs local inference? Type 'nil' could not be converted into '{|  |}'
	eventLogBuffer = nil :: any
	eventLog = nil :: any
	eventLogIndex = 1
	return buffer
end

exports.markTaskStart = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskStartEvent, ms * 1000, task.id, task.priorityLevel })
		end
	end
end

exports.markTaskCompleted = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			-- performance.now returns a float, representing milliseconds. When the
			-- event is logged, it's coerced to an int. Convert to microseconds to
			-- maintain extra degrees of precision.
			logEvent({ TaskCompleteEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskCanceled = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskCancelEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskErrored = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskErrorEvent, ms * 1000, task.id })
		end
	end
end

exports.markTaskRun = function(task, ms: number)
	if enableProfiling then
		runIdCounter += 1

		if eventLog ~= nil then
			logEvent({ TaskRunEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markTaskYield = function(task, ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ TaskYieldEvent, ms * 1000, task.id, runIdCounter })
		end
	end
end

exports.markSchedulerSuspended = function(ms: number)
	if enableProfiling then
		mainThreadIdCounter += 1

		if eventLog ~= nil then
			logEvent({ SchedulerSuspendEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

exports.markSchedulerUnsuspended = function(ms: number)
	if enableProfiling then
		if eventLog ~= nil then
			logEvent({ SchedulerResumeEvent, ms * 1000, mainThreadIdCounter })
		end
	end
end

return exports
