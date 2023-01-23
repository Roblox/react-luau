-- ROBLOX upstream: https://github.com/facebook/react/blob/8af27aeedbc6b00bc2ef49729fc84f116c70a27c/packages/scheduler/src/__tests__/SchedulerProfiling-test.js
--[[**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 *
 * LICENSE file in the root directory of this source tree.
 * @flow
 *]]

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
-- ROBLOX note: this uses a post-17.0.1 commit that removes a reliance on SharedArrayBuffer, but remains API compatible with 17.x

local Scheduler
local ImmediatePriority
local UserBlockingPriority
local NormalPriority
local LowPriority
local IdlePriority
local scheduleCallback
local cancelCallback
local function priorityLevelToString(priorityLevel)
	if priorityLevel == ImmediatePriority then
		return "Immediate"
	elseif priorityLevel == UserBlockingPriority then
		return "User-blocking"
	elseif priorityLevel == NormalPriority then
		return "Normal"
	elseif priorityLevel == LowPriority then
		return "Low"
	elseif priorityLevel == IdlePriority then
		return "Idle"
	else
		return nil
	end
end
describe("Scheduler", function()
	it("profiling APIs are not available", function()
		local SchedulerFeatureFlags = require(script.Parent.Parent.SchedulerFeatureFlags)
		SchedulerFeatureFlags.enableProfiling = false

		Scheduler = require(script.Parent.Parent.Scheduler)()
		jestExpect(Scheduler.unstable_Profiling).toBe(nil)
	end)
	beforeEach(function()
		jest.resetModules()

		jest.useFakeTimers()
		local SchedulerFeatureFlags = require(script.Parent.Parent.SchedulerFeatureFlags)
		SchedulerFeatureFlags.enableProfiling = true

		-- ROBLOX deviation: In react, jest mocks Scheduler -> unstable_mock since
		-- unstable_mock depends on the real Scheduler, and our mock
		-- functionality isn't smart enough to prevent self-requires, we simply
		-- require the mock entry point directly for use in tests
		Scheduler = require(script.Parent.Parent.unstable_mock)
		ImmediatePriority = Scheduler.unstable_ImmediatePriority
		UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
		NormalPriority = Scheduler.unstable_NormalPriority
		LowPriority = Scheduler.unstable_LowPriority
		IdlePriority = Scheduler.unstable_IdlePriority
		scheduleCallback = Scheduler.unstable_scheduleCallback
		cancelCallback = Scheduler.unstable_cancelCallback
	end)
	local TaskStartEvent = 1
	local TaskCompleteEvent = 2
	local TaskErrorEvent = 3
	local TaskCancelEvent = 4
	local TaskRunEvent = 5
	local TaskYieldEvent = 6
	local SchedulerSuspendEvent = 7
	local SchedulerResumeEvent = 8
	local function stopProfilingAndPrintFlamegraph()
		local eventBuffer = Scheduler.unstable_Profiling.stopLoggingProfilingEvents()
		if eventBuffer == nil then
			return "(empty profile)"
		end
		local eventLog = { table.unpack(eventBuffer) }
		local tasks = {}
		local mainThreadRuns = {}
		local isSuspended = true
		local i = 1
		while i <= #eventLog do
			local instruction = eventLog[i][1]
			local time_ = eventLog[i][2]
			if instruction == 0 then
				break
			elseif instruction == TaskStartEvent then
				local taskId = eventLog[i][3]
				local priorityLevel = eventLog[i][4]
				local task_ = {
					id = taskId,
					priorityLevel = priorityLevel,
					label = nil,
					start = time_,
					end_ = -1,
					exitStatus = nil,
					runs = {},
				}
				tasks[taskId] = task_
				i += 1
			elseif instruction == TaskCompleteEvent then
				if isSuspended then
					error("Task cannot Complete outside the work loop.")
				end
				local taskId = eventLog[i][3]
				local task_ = tasks[taskId]
				if task_ == nil then
					error("Task does not exist.")
				end
				task_.end_ = time_
				task_.exitStatus = "completed"
				i += 1
			elseif instruction == TaskErrorEvent then
				if isSuspended then
					error("Task cannot Error outside the work loop.")
				end
				local taskId = eventLog[i][3]
				local task_ = tasks[taskId]
				if task_ == nil then
					error("Task does not exist.")
				end
				task_.end_ = time_
				task_.exitStatus = "errored"
				i += 1
			elseif instruction == TaskCancelEvent then
				local taskId = eventLog[i][3]
				local task_ = tasks[taskId]
				if task_ == nil then
					error("Task does not exist.")
				end
				task_.end_ = time_
				task_.exitStatus = "canceled"
				i += 1
			elseif instruction == TaskRunEvent or instruction == TaskYieldEvent then
				if isSuspended then
					error("Task cannot Run or Yield outside the work loop.")
				end
				local taskId = eventLog[i][3]
				local task_ = tasks[taskId]
				if task_ == nil then
					error("Task does not exist.")
				end
				table.insert(task_.runs, time_)
				i += 1
			elseif instruction == SchedulerSuspendEvent then
				if isSuspended then
					error("Scheduler cannot Suspend outside the work loop.")
				end
				isSuspended = true
				table.insert(mainThreadRuns, time_)
				i += 1
			elseif instruction == SchedulerResumeEvent then
				if not isSuspended then
					error("Scheduler cannot Resume inside the work loop.")
				end
				isSuspended = false
				table.insert(mainThreadRuns, time_)
				i += 1
			else
				error("Unknown instruction type: " + instruction)
			end
		end
		local labelColumnWidth = 30
		local microsecondsPerChar = 50000
		local result = ""
		local mainThreadLabelColumn = "!!! Main thread              "
		local mainThreadTimelineColumn = ""
		local isMainThreadBusy = true
		for _, time_ in mainThreadRuns do
			local index = time_ / microsecondsPerChar
			for i = 1, index - string.len(mainThreadTimelineColumn), 1 do
				mainThreadTimelineColumn ..= (function()
					if isMainThreadBusy then
						return "X"
					end
					return "_"
				end)()
			end
			isMainThreadBusy = not isMainThreadBusy
		end
		result ..= mainThreadLabelColumn .. "│" .. mainThreadTimelineColumn .. "\n"
		local tasksValues = {}
		for _, tasksValue in tasks do
			table.insert(tasksValues, tasksValue)
		end
		table.sort(tasksValues, function(t1, t2)
			return t2.priorityLevel > t1.priorityLevel
		end)
		for _, task_ in tasksValues do
			local label = task_.label
			if label == nil then
				label = "Task"
			end
			local labelColumn = string.format(
				"Task %d [%s]",
				task_.id,
				priorityLevelToString(task_.priorityLevel)
			)
			for i = 1, labelColumnWidth - string.len(labelColumn) - 1, 1 do
				labelColumn ..= " "
			end

			-- Add empty space up until the start mark
			local timelineColumn = ""
			for i = 1, task_.start / microsecondsPerChar, 1 do
				timelineColumn ..= " "
			end

			local isRunning = false
			for _, time_ in task_.runs do
				local index = time_ / microsecondsPerChar
				for i = 1, index - string.len(timelineColumn), 1 do
					timelineColumn ..= (function()
						if isRunning then
							return "X"
						end
						return "_"
					end)()
				end

				isRunning = not isRunning
			end

			local endIndex = task_.end_ / microsecondsPerChar
			for i = 1, endIndex - string.len(timelineColumn), 1 do
				timelineColumn ..= (function()
					if isRunning then
						return "X"
					end
					return "_"
				end)()
			end

			if task_.exitStatus ~= "completed" then
				timelineColumn ..= "O " .. (task_.exitStatus or "")
			end

			result ..= labelColumn .. "│" .. timelineColumn .. "\n"
		end
		return "\n" .. result
	end

	it("creates a basic flamegraph", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		Scheduler.unstable_advanceTime(100)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(300)
			Scheduler.unstable_yieldValue("Yield 1")
			scheduleCallback(UserBlockingPriority, function()
				Scheduler.unstable_yieldValue("Yield 2")
				Scheduler.unstable_advanceTime(300)
			end, {
				label = "Bar",
			})
			Scheduler.unstable_advanceTime(100)
			Scheduler.unstable_yieldValue("Yield 3")
			return function()
				Scheduler.unstable_yieldValue("Yield 4")
				Scheduler.unstable_advanceTime(300)
			end
		end, {
			label = "Foo",
		})
		jestExpect(Scheduler).toFlushAndYieldThrough({ "Yield 1", "Yield 3" })
		Scheduler.unstable_advanceTime(100)
		jestExpect(Scheduler).toFlushAndYield({ "Yield 2", "Yield 4" })
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │XX________XX____________
Task 2 [User-blocking]       │        ____XXXXXX
Task 1 [Normal]              │  XXXXXXXX________XXXXXX
]])
	end)
	it("marks when a Task is canceled", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		local task_ = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("Yield 1")
			Scheduler.unstable_advanceTime(300)
			Scheduler.unstable_yieldValue("Yield 2")
			return function()
				Scheduler.unstable_yieldValue("Continuation")
				Scheduler.unstable_advanceTime(200)
			end
		end)
		jestExpect(Scheduler).toFlushAndYieldThrough({ "Yield 1", "Yield 2" })
		Scheduler.unstable_advanceTime(100)
		cancelCallback(task_)
		Scheduler.unstable_advanceTime(1000)
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │______XXXXXXXXXXXXXXXXXXXXXX
Task 1 [Normal]              │XXXXXX__O canceled
]])
	end)
	it("marks when a task errors", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(300)
			error("Oops")
		end)
		jestExpect(Scheduler).toFlushAndThrow("Oops")
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_advanceTime(1000)
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │______XXXXXXXXXXXXXXXXXXXXXX
Task 1 [Normal]              │XXXXXXO errored
]])
	end)

	it("marks when multiple tasks are canceled", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		local task1 = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("Yield 1")
			Scheduler.unstable_advanceTime(300)
			Scheduler.unstable_yieldValue("Yield 2")
			return function()
				Scheduler.unstable_yieldValue("Continuation")
				Scheduler.unstable_advanceTime(200)
			end
		end)
		local task2 = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("Yield 3")
			Scheduler.unstable_advanceTime(300)
			Scheduler.unstable_yieldValue("Yield 4")
			return function()
				Scheduler.unstable_yieldValue("Continuation")
				Scheduler.unstable_advanceTime(200)
			end
		end)
		jestExpect(Scheduler).toFlushAndYieldThrough({ "Yield 1", "Yield 2" })
		Scheduler.unstable_advanceTime(100)
		cancelCallback(task1)
		cancelCallback(task2)
		Scheduler.unstable_advanceTime(1000)
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │______XXXXXXXXXXXXXXXXXXXXXX
Task 1 [Normal]              │XXXXXX__O canceled
Task 2 [Normal]              │________O canceled
]])
	end)
	it("handles cancelling a task_ that already finished", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		local task_ = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
			Scheduler.unstable_advanceTime(1000)
		end)
		jestExpect(Scheduler).toFlushAndYield({ "A" })
		cancelCallback(task_)
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │____________________
Task 1 [Normal]              │XXXXXXXXXXXXXXXXXXXX
]])
	end)

	it("handles cancelling a task multiple times", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
			Scheduler.unstable_advanceTime(1000)
		end, {
			label = "A",
		})
		Scheduler.unstable_advanceTime(200)
		local task_ = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("B")
			Scheduler.unstable_advanceTime(1000)
		end, {
			label = "B",
		})
		Scheduler.unstable_advanceTime(400)
		cancelCallback(task_)
		cancelCallback(task_)
		cancelCallback(task_)
		jestExpect(Scheduler).toFlushAndYield({ "A" })
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │XXXXXXXXXXXX____________________
Task 1 [Normal]              │____________XXXXXXXXXXXXXXXXXXXX
Task 2 [Normal]              │    ________O canceled
]])
	end)
	it("handles delayed tasks", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(1000)
			Scheduler.unstable_yieldValue("A")
		end, {
			delay = 1000,
		})
		jestExpect(Scheduler).toFlushWithoutYielding()
		Scheduler.unstable_advanceTime(1000)
		jestExpect(Scheduler).toFlushAndYield({ "A" })
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │XXXXXXXXXXXXXXXXXXXX____________________
Task 1 [Normal]              │                    XXXXXXXXXXXXXXXXXXXX
]])
	end)
	it("handles cancelling a delayed Task", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		local task_ = scheduleCallback(NormalPriority, function()
			return Scheduler.unstable_yieldValue("A")
		end, {
			delay = 1000,
		})
		cancelCallback(task_)
		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │
]])
	end)
	it("automatically stops profiling and warns if event log gets too big", function()
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		-- ROBLOX deviation: use toWarvDev matcher below instead of overriding console global
		-- spyOnDevAndProd(console, "error")
		-- ROBLOX deviation: any lower than this, and the buffer doesn't overslow and we try to table.unpack() too many elements
		local originalMaxIterations = 41000
		local taskId = 1
		jestExpect(function()
			while taskId < originalMaxIterations do
				taskId += 1
				local task_ = scheduleCallback(NormalPriority, function()
					return {}
				end)
				cancelCallback(task_)
				jestExpect(Scheduler).toFlushAndYield({})
			end
		end).toErrorDev("Event log exceeded maximum size", { withoutStack = true })
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual("(empty profile)")
		Scheduler.unstable_Profiling.startLoggingProfilingEvents()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_advanceTime(1000)
		end)
		jestExpect(Scheduler).toFlushAndYield({})
		jestExpect(stopProfilingAndPrintFlamegraph()).toEqual([[

!!! Main thread              │____________________
Task 41000 [Normal]          │XXXXXXXXXXXXXXXXXXXX
]])
	end)
end)
