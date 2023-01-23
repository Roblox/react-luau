-- ROBLOX upstream: https://github.com/facebook/react/blob/3e94bce765d355d74f6a60feb4addb6d196e3482/packages/scheduler/src/__tests__/SchedulerNoDOM-test.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @emails react-core
]]

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

local scheduleCallback
local ImmediatePriority
local UserBlockingPriority
local NormalPriority

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()
	local Scheduler = require(script.Parent.Parent.Scheduler)()

	scheduleCallback = Scheduler.unstable_scheduleCallback
	ImmediatePriority = Scheduler.unstable_ImmediatePriority
	UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
	NormalPriority = Scheduler.unstable_NormalPriority
end)

it("runAllTimers flushes all scheduled callbacks", function()
	local log = {}
	scheduleCallback(NormalPriority, function()
		table.insert(log, "A")
	end)
	scheduleCallback(NormalPriority, function()
		table.insert(log, "B")
	end)
	scheduleCallback(NormalPriority, function()
		table.insert(log, "C")
	end)

	jestExpect(log).toEqual({})

	jest.runAllTimers()

	jestExpect(log).toEqual({ "A", "B", "C" })
end)

it("executes callbacks in order of priority", function()
	local log = {}

	scheduleCallback(NormalPriority, function()
		table.insert(log, "A")
	end)
	scheduleCallback(NormalPriority, function()
		table.insert(log, "B")
	end)
	scheduleCallback(UserBlockingPriority, function()
		table.insert(log, "C")
	end)
	scheduleCallback(UserBlockingPriority, function()
		table.insert(log, "D")
	end)

	jestExpect(log).toEqual({})
	jest.runAllTimers()
	jestExpect(log).toEqual({ "C", "D", "A", "B" })
end)

it("handles errors", function()
	local log = {}

	scheduleCallback(ImmediatePriority, function()
		table.insert(log, "A")
		error("Oops A")
	end)
	scheduleCallback(ImmediatePriority, function()
		table.insert(log, "B")
	end)
	scheduleCallback(ImmediatePriority, function()
		table.insert(log, "C")
		error("Oops C")
	end)

	jestExpect(jest.runAllTimers).toThrow("Oops A")
	jestExpect(log).toEqual({ "A" })

	log = {}

	-- B and C flush in a subsequent event. That way, the second error is not
	-- swallowed.
	jestExpect(function()
		jest.runAllTimers()
	end).toThrow("Oops C")
	jestExpect(log).toEqual({ "B", "C" })
end)
