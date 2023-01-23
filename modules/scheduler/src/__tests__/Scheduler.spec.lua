-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/__tests__/Scheduler-test.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @emails react-core
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest

local Scheduler
local runWithPriority
local ImmediatePriority
local UserBlockingPriority
local NormalPriority
-- deviation: These are only used in a commented-out _G.__DEV__-only test
-- (commented out to silence lints)
-- local LowPriority
-- local IdlePriority
local scheduleCallback
local cancelCallback
local wrapCallback
local getCurrentPriorityLevel
local shouldYield

local function shift(list)
	local first = list[1]
	local newLength = #list - 1

	for i = 1, newLength do
		list[i] = list[i + 1]
	end

	-- We need to explicitly nil out the end of the list
	list[newLength + 1] = nil

	return first
end

beforeEach(function()
	jest.resetModules()
	-- deviation: In react, jest mocks Scheduler -> unstable_mock; since
	-- unstable_mock depends on the real Scheduler, and our mock
	-- functionality isn't smart enough to prevent self-requires, we simply
	-- require the mock entry point directly for use in tests
	Scheduler = require(script.Parent.Parent.unstable_mock)

	runWithPriority = Scheduler.unstable_runWithPriority
	ImmediatePriority = Scheduler.unstable_ImmediatePriority
	UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
	NormalPriority = Scheduler.unstable_NormalPriority
	-- deviation: These are only used in a commented-out _G.__DEV__-only
	-- test (commented out to silence lints)
	-- LowPriority = Scheduler.unstable_LowPriority
	-- IdlePriority = Scheduler.unstable_IdlePriority
	scheduleCallback = Scheduler.unstable_scheduleCallback
	cancelCallback = Scheduler.unstable_cancelCallback
	wrapCallback = Scheduler.unstable_wrapCallback
	getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel
	shouldYield = Scheduler.unstable_shouldYield
end)

it("flushes work incrementally", function()
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("A")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("B")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("C")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("D")
	end)

	jestExpect(Scheduler).toFlushAndYieldThrough({ "A", "B" })
	jestExpect(Scheduler).toFlushAndYieldThrough({ "C" })
	jestExpect(Scheduler).toFlushAndYield({ "D" })
end)

it("cancels work", function()
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("A")
	end)
	local callbackHandleB = scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("B")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("C")
	end)

	cancelCallback(callbackHandleB)

	jestExpect(Scheduler).toFlushAndYield({
		"A",
		-- B should have been cancelled
		"C",
	})
end)

it("executes the highest priority callbacks first", function()
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("A")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("B")
	end)

	-- Yield before B is flushed
	jestExpect(Scheduler).toFlushAndYieldThrough({ "A" })

	scheduleCallback(UserBlockingPriority, function()
		Scheduler.unstable_yieldValue("C")
	end)
	scheduleCallback(UserBlockingPriority, function()
		Scheduler.unstable_yieldValue("D")
	end)

	-- C and D should come first, because they are higher priority
	jestExpect(Scheduler).toFlushAndYield({ "C", "D", "B" })
end)

it("expires work", function()
	scheduleCallback(NormalPriority, function(didTimeout)
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue(
			string.format("A (did timeout: %s)", tostring(didTimeout))
		)
	end)
	scheduleCallback(UserBlockingPriority, function(didTimeout)
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue(
			string.format("B (did timeout: %s)", tostring(didTimeout))
		)
	end)
	scheduleCallback(UserBlockingPriority, function(didTimeout)
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue(
			string.format("C (did timeout: %s)", tostring(didTimeout))
		)
	end)

	-- Advance time, but not by enough to expire any work
	Scheduler.unstable_advanceTime(249)
	jestExpect(Scheduler).toHaveYielded({})

	-- Schedule a few more callbacks
	scheduleCallback(NormalPriority, function(didTimeout)
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue(
			string.format("D (did timeout: %s)", tostring(didTimeout))
		)
	end)
	scheduleCallback(NormalPriority, function(didTimeout)
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue(
			string.format("E (did timeout: %s)", tostring(didTimeout))
		)
	end)

	-- Advance by just a bit more to expire the user blocking callbacks
	Scheduler.unstable_advanceTime(1)
	jestExpect(Scheduler).toFlushExpired({
		"B (did timeout: true)",
		"C (did timeout: true)",
	})

	-- Expire A
	Scheduler.unstable_advanceTime(4600)
	jestExpect(Scheduler).toFlushExpired({ "A (did timeout: true)" })

	-- Flush the rest without expiring
	jestExpect(Scheduler).toFlushAndYield({
		"D (did timeout: false)",
		"E (did timeout: true)",
	})
end)

it("has a default expiration of ~5 seconds", function()
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("A")
	end)

	Scheduler.unstable_advanceTime(4999)
	jestExpect(Scheduler).toHaveYielded({})

	Scheduler.unstable_advanceTime(1)
	jestExpect(Scheduler).toFlushExpired({ "A" })
end)

it("continues working on same task after yielding", function()
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue("A")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue("B")
	end)

	local didYield = false
	local tasks = {
		{ "C1", 100 },
		{ "C2", 100 },
		{ "C3", 100 },
	}
	local function C()
		while #tasks > 0 do
			local label, ms = unpack(shift(tasks))
			Scheduler.unstable_advanceTime(ms)
			Scheduler.unstable_yieldValue(label)
			if shouldYield() then
				didYield = true
				return C
			end
		end

		return nil
	end

	scheduleCallback(NormalPriority, C)

	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue("D")
	end)
	scheduleCallback(NormalPriority, function()
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue("E")
	end)

	-- Flush, then yield while in the middle of C.
	jestExpect(didYield).toBe(false)
	jestExpect(Scheduler).toFlushAndYieldThrough({ "A", "B", "C1" })
	jestExpect(didYield).toBe(true)

	-- When we resume, we should continue working on C.
	jestExpect(Scheduler).toFlushAndYield({ "C2", "C3", "D", "E" })
end)

it("continuation callbacks inherit the expiration of the previous callback", function()
	local tasks = {
		{ "A", 125 },
		{ "B", 124 },
		{ "C", 100 },
		{ "D", 100 },
	}
	local function work()
		while #tasks > 0 do
			local label, ms = unpack(shift(tasks))
			Scheduler.unstable_advanceTime(ms)
			Scheduler.unstable_yieldValue(label)
			if shouldYield() then
				return work
			end
		end

		return nil
	end

	-- Schedule a high priority callback
	scheduleCallback(UserBlockingPriority, work)

	-- Flush until just before the expiration time
	jestExpect(Scheduler).toFlushAndYieldThrough({ "A", "B" })

	-- Advance time by just a bit more. This should expire all the remaining work.
	Scheduler.unstable_advanceTime(1)
	jestExpect(Scheduler).toFlushExpired({ "C", "D" })
end)

it("continuations are interrupted by higher priority work", function()
	local tasks = {
		{ "A", 100 },
		{ "B", 100 },
		{ "C", 100 },
		{ "D", 100 },
	}
	local function work()
		while #tasks > 0 do
			local label, ms = unpack(shift(tasks))
			Scheduler.unstable_advanceTime(ms)
			Scheduler.unstable_yieldValue(label)
			if #tasks > 0 and shouldYield() then
				return work
			end
		end

		return nil
	end
	scheduleCallback(NormalPriority, work)
	jestExpect(Scheduler).toFlushAndYieldThrough({ "A" })

	scheduleCallback(UserBlockingPriority, function()
		Scheduler.unstable_advanceTime(100)
		Scheduler.unstable_yieldValue("High pri")
	end)

	jestExpect(Scheduler).toFlushAndYield({ "High pri", "B", "C", "D" })
end)

it(
	"continuations do not block higher priority work scheduled "
		.. "inside an executing callback",
	function()
		local tasks = {
			{ "A", 100 },
			{ "B", 100 },
			{ "C", 100 },
			{ "D", 100 },
		}
		local function work()
			while #tasks > 0 do
				local task = shift(tasks)
				local label, ms = unpack(task)
				Scheduler.unstable_advanceTime(ms)
				Scheduler.unstable_yieldValue(label)
				if label == "B" then
					-- Schedule high pri work from inside another callback
					Scheduler.unstable_yieldValue("Schedule high pri")
					scheduleCallback(UserBlockingPriority, function()
						Scheduler.unstable_advanceTime(100)
						Scheduler.unstable_yieldValue("High pri")
					end)
				end
				if #tasks > 0 then
					-- Return a continuation
					return work
				end
			end

			return nil
		end
		scheduleCallback(NormalPriority, work)
		jestExpect(Scheduler).toFlushAndYield({
			"A",
			"B",
			"Schedule high pri",
			-- The high pri callback should fire before the continuation of the
			-- lower pri work
			"High pri",
			-- Continue low pri work
			"C",
			"D",
		})
	end
)

it("cancelling a continuation", function()
	local task = scheduleCallback(NormalPriority, function()
		Scheduler.unstable_yieldValue("Yield")
		return function()
			Scheduler.unstable_yieldValue("Continuation")
		end
	end)

	jestExpect(Scheduler).toFlushAndYieldThrough({ "Yield" })
	cancelCallback(task)
	jestExpect(Scheduler).toFlushWithoutYielding()
end)

it("top-level immediate callbacks fire in a subsequent task", function()
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("A")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("B")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("C")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("D")
	end)
	-- Immediate callback hasn't fired, yet.
	jestExpect(Scheduler).toHaveYielded({})
	-- They all flush immediately within the subsequent task.
	jestExpect(Scheduler).toFlushExpired({ "A", "B", "C", "D" })
end)

it("nested immediate callbacks are added to the queue of immediate callbacks", function()
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("A")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("B")
		-- This callback should go to the end of the queue
		scheduleCallback(ImmediatePriority, function()
			Scheduler.unstable_yieldValue("C")
		end)
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("D")
	end)
	jestExpect(Scheduler).toHaveYielded({})
	-- C should flush at the end
	jestExpect(Scheduler).toFlushExpired({ "A", "B", "D", "C" })
end)

it("wrapped callbacks have same signature as original callback", function()
	local wrappedCallback = wrapCallback(function(...)
		return {
			args = { ... },
		}
	end)
	local result = wrappedCallback("a", "b")
	jestExpect(#result.args).toBe(2)
	jestExpect(result.args).toEqual({ "a", "b" })
end)

it("wrapped callbacks inherit the current priority", function()
	local wrappedCallback = runWithPriority(NormalPriority, function()
		return wrapCallback(function()
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		end)
	end)

	local wrappedUserBlockingCallback = runWithPriority(UserBlockingPriority, function()
		return wrapCallback(function()
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		end)
	end)

	wrappedCallback()
	jestExpect(Scheduler).toHaveYielded({ NormalPriority })

	wrappedUserBlockingCallback()
	jestExpect(Scheduler).toHaveYielded({ UserBlockingPriority })
end)

it("wrapped callbacks inherit the current priority even when nested", function()
	local wrappedCallback
	local wrappedUserBlockingCallback

	runWithPriority(NormalPriority, function()
		wrappedCallback = wrapCallback(function()
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		end)
		wrappedUserBlockingCallback = runWithPriority(UserBlockingPriority, function()
			return wrapCallback(function()
				Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			end)
		end)
	end)

	wrappedCallback()
	jestExpect(Scheduler).toHaveYielded({ NormalPriority })

	wrappedUserBlockingCallback()
	jestExpect(Scheduler).toHaveYielded({ UserBlockingPriority })
end)

it("immediate callbacks fire even if there's an error", function()
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("A")
		error("Oops A")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("B")
	end)
	scheduleCallback(ImmediatePriority, function()
		Scheduler.unstable_yieldValue("C")
		error(Error.new("Oops C"))
	end)

	jestExpect(function()
		jestExpect(Scheduler).toFlushExpired()
	end).toThrow("Oops A")
	jestExpect(Scheduler).toHaveYielded({ "A" })

	-- B and C flush in a subsequent event. That way, the second error is not
	-- swallowed.
	jestExpect(function()
		jestExpect(Scheduler).toFlushExpired()
	end).toThrow("Oops C")
	jestExpect(Scheduler).toHaveYielded({ "B", "C" })
end)

it(
	"multiple immediate callbacks can throw and there will be an error for each one",
	function()
		scheduleCallback(ImmediatePriority, function()
			error("First error")
		end)
		scheduleCallback(ImmediatePriority, function()
			error("Second error")
		end)
		jestExpect(function()
			Scheduler.unstable_flushAll()
		end).toThrow("First error")
		-- The next error is thrown in the subsequent event
		jestExpect(function()
			Scheduler.unstable_flushAll()
		end).toThrow("Second error")
	end
)

it("exposes the current priority level", function()
	Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
	runWithPriority(ImmediatePriority, function()
		Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
		runWithPriority(NormalPriority, function()
			Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			runWithPriority(UserBlockingPriority, function()
				Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
			end)
		end)
		Scheduler.unstable_yieldValue(getCurrentPriorityLevel())
	end)

	jestExpect(Scheduler).toHaveYielded({
		NormalPriority,
		ImmediatePriority,
		NormalPriority,
		UserBlockingPriority,
		ImmediatePriority,
	})
end)

-- if _G.__DEV__ then
-- ROBLOX TODO(align): Re-enable this test if it's useful
--
-- Function names are minified in prod, though you could still infer the
-- priority if you have sourcemaps.
-- TODO: Feature temporarily disabled while we investigate a bug in one of
-- our minifiers.
-- it.skip('adds extra function to the JS stack whose name includes the priority level', function()
-- 	function inferPriorityFromCallstack()
-- 		try {
-- 			throw Error()
-- 		} catch (e) {
-- 			local stack = e.stack
-- 			local lines = stack.split('\n')
-- 			for (local i = lines.length - 1 i >= 0 i--) {
-- 				local line = lines[i]
-- 				local found = line.match(
-- 					/scheduler_flushTaskAtPriority_({A-Za-z]+)/,
-- 				)
-- 				if (found !== null) {
-- 					local priorityStr = found[1]
-- 					switch (priorityStr) {
-- 						case 'Immediate':
-- 							return ImmediatePriority
-- 						case 'UserBlocking':
-- 							return UserBlockingPriority
-- 						case 'Normal':
-- 							return NormalPriority
-- 						case 'Low':
-- 							return LowPriority
-- 						case 'Idle':
-- 							return IdlePriority
-- 					}
-- 				}
-- 			}
-- 			return null
-- 		}
-- 	end

-- 	scheduleCallback(ImmediatePriority, () =>
-- 		Scheduler.unstable_yieldValue(
-- 			'Immediate: ' + inferPriorityFromCallstack(),
-- 		),
-- 	)
-- 	scheduleCallback(UserBlockingPriority, () =>
-- 		Scheduler.unstable_yieldValue(
-- 			'UserBlocking: ' + inferPriorityFromCallstack(),
-- 		),
-- 	)
-- 	scheduleCallback(NormalPriority, () =>
-- 		Scheduler.unstable_yieldValue(
-- 			'Normal: ' + inferPriorityFromCallstack(),
-- 		),
-- 	)
-- 	scheduleCallback(LowPriority, () =>
-- 		Scheduler.unstable_yieldValue('Low: ' + inferPriorityFromCallstack()),
-- 	)
-- 	scheduleCallback(IdlePriority, () =>
-- 		Scheduler.unstable_yieldValue('Idle: ' + inferPriorityFromCallstack()),
-- 	)

-- 	jestExpect(Scheduler).toFlushAndYield({
-- 		'Immediate: ' + ImmediatePriority,
-- 		'UserBlocking: ' + UserBlockingPriority,
-- 		'Normal: ' + NormalPriority,
-- 		'Low: ' + LowPriority,
-- 		'Idle: ' + IdlePriority,
-- 	})
-- end)
-- end

describe("delayed tasks", function()
	it("schedules a delayed task", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
		end, {
			delay = 1000,
		})

		-- Should flush nothing, because delay hasn't elapsed
		jestExpect(Scheduler).toFlushAndYield({})

		-- Advance time until right before the threshold
		Scheduler.unstable_advanceTime(999)
		-- Still nothing
		jestExpect(Scheduler).toFlushAndYield({})

		-- Advance time past the threshold
		Scheduler.unstable_advanceTime(1)

		-- Now it should flush like normal
		jestExpect(Scheduler).toFlushAndYield({ "A" })
	end)

	it("schedules multiple delayed tasks", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("C")
		end, {
			delay = 300,
		})

		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("B")
		end, {
			delay = 200,
		})

		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("D")
		end, {
			delay = 400,
		})

		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
		end, {
			delay = 100,
		})

		-- Should flush nothing, because delay hasn't elapsed
		jestExpect(Scheduler).toFlushAndYield({})

		-- Advance some time.
		Scheduler.unstable_advanceTime(200)
		-- Both A and B are no longer delayed. They can now flush incrementally.
		jestExpect(Scheduler).toFlushAndYieldThrough({ "A" })
		jestExpect(Scheduler).toFlushAndYield({ "B" })

		-- Advance the rest
		Scheduler.unstable_advanceTime(200)
		jestExpect(Scheduler).toFlushAndYield({ "C", "D" })
	end)

	it("interleaves normal tasks and delayed tasks", function()
		-- Schedule some high priority callbacks with a delay. When their delay
		-- elapses, they will be the most important callback in the queue.
		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue("Timer 2")
		end, {
			delay = 300,
		})
		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue("Timer 1")
		end, {
			delay = 100,
		})

		-- Schedule some tasks at default priority.
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
			Scheduler.unstable_advanceTime(100)
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("B")
			Scheduler.unstable_advanceTime(100)
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("C")
			Scheduler.unstable_advanceTime(100)
		end)
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("D")
			Scheduler.unstable_advanceTime(100)
		end)

		-- Flush all the work. The timers should be interleaved with the
		-- other tasks.
		jestExpect(Scheduler).toFlushAndYield({
			"A",
			"Timer 1",
			"B",
			"C",
			"Timer 2",
			"D",
		})
	end)

	it("interleaves delayed tasks with time-sliced tasks", function()
		-- Schedule some high priority callbacks with a delay. When their delay
		-- elapses, they will be the most important callback in the queue.
		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue("Timer 2")
		end, {
			delay = 300,
		})
		scheduleCallback(UserBlockingPriority, function()
			Scheduler.unstable_yieldValue("Timer 1")
		end, {
			delay = 100,
		})

		-- Schedule a time-sliced task at default priority.
		local tasks = {
			{ "A", 100 },
			{ "B", 100 },
			{ "C", 100 },
			{ "D", 100 },
		}
		local function work()
			while #tasks > 0 do
				local task = shift(tasks)
				local label, ms = unpack(task)
				Scheduler.unstable_advanceTime(ms)
				Scheduler.unstable_yieldValue(label)
				if #tasks > 0 then
					return work
				end
			end

			return nil
		end
		scheduleCallback(NormalPriority, work)

		-- Flush all the work. The timers should be interleaved with the
		-- other tasks.
		jestExpect(Scheduler).toFlushAndYield({
			"A",
			"Timer 1",
			"B",
			"C",
			"Timer 2",
			"D",
		})
	end)

	it("cancels a delayed task", function()
		-- Schedule several tasks with the same delay
		local options = {
			delay = 100,
		}

		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
		end, options)
		local taskB = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("B")
		end, options)
		local taskC = scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("C")
		end, options)

		-- Cancel B before its delay has elapsed
		jestExpect(Scheduler).toFlushAndYield({})
		cancelCallback(taskB)

		-- Cancel C after its delay has elapsed
		Scheduler.unstable_advanceTime(500)
		cancelCallback(taskC)

		-- Only A should flush
		jestExpect(Scheduler).toFlushAndYield({ "A" })
	end)

	it("gracefully handles scheduled tasks that are not a function", function()
		scheduleCallback(ImmediatePriority)
		jestExpect(Scheduler).toFlushWithoutYielding()

		scheduleCallback(ImmediatePriority, {})
		jestExpect(Scheduler).toFlushWithoutYielding()

		scheduleCallback(ImmediatePriority, 42)
		jestExpect(Scheduler).toFlushWithoutYielding()
	end)

	it("delayed tasks stringify their error", function()
		scheduleCallback(NormalPriority, function()
			Scheduler.unstable_yieldValue("A")
			error(Error.new("Oops A"))
		end, {
			delay = 100,
		})

		Scheduler.unstable_advanceTime(100)
		jestExpect(Scheduler).toFlushAndThrow("Oops A")
	end)
end)
