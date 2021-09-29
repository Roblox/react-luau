--[[
	Defines expectation extensions, including Scheduler-specific ones. This code
	is mostly based on:
	https://github.com/facebook/react/blob/47ff31a77add22bef54aaed9d4fb62d5aa693afd/scripts/jest/matchers/schedulerTestMatchers.js
]]

-- ROBLOX TODO remove this when CLI-38793 lands
--!nolint LocalShadowPedantic
local function captureAssertion(fn)
	-- Trick to use a TestEZ expectation matcher inside another Jest
	-- matcher. `fn` contains an assertion; if it throws, we capture the
	-- error and return it, so the stack trace presented to the user points
	-- to the original assertion in the test file.
	local ok, result = pcall(fn)

	if not ok then
		-- deviation: The message here will be a string with some extra info
		-- that's not helpful, so we trim it down a bit
		local stringResult = tostring(result)
		local subMessageIndex = string.find(stringResult, " ")
		local message = string.sub(stringResult, subMessageIndex + 1)

		return {
			pass = false,
			message = function()
				return message
			end,
		}
	end

	return { pass = true }
end

return function(jestExpect)
	local function assertYieldsWereCleared(scheduler)
		local actualYields = scheduler.unstable_clearYields()
		if #actualYields ~= 0 then
			error(
				"Log of yielded values is not empty. "
					.. "Call expectToHaveYielded(scheduler, ...) first.",
				3
			)
		end
	end

	local function expectToFlushAndYield(_matcherContext, scheduler, expectedYields)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushAllWithoutAsserting()
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	local function expectToFlushAndYieldThrough(
		_matcherContext,
		scheduler,
		expectedYields
	)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushNumberOfYields(#expectedYields)
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	local function toFlushUntilNextPaint(_matcherContext, Scheduler, expectedYields)
		assertYieldsWereCleared(Scheduler)
		Scheduler.unstable_flushUntilNextPaint()
		local actualYields = Scheduler.unstable_clearYields()
		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

		  local function expectToFlushWithoutYielding(_matcherContext, scheduler)
		return expectToFlushAndYield(_matcherContext, scheduler, {})
	end

	local function expectToFlushExpired(_matcherContext, scheduler, expectedYields)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushExpired()
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	local function expectToHaveYielded(_matcherContext, scheduler, expectedYields)
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	local function expectToFlushAndThrow(_matcherContext, scheduler, rest)
		assertYieldsWereCleared(scheduler)
		return captureAssertion(function()
			jestExpect(function()
				scheduler.unstable_flushAllWithoutAsserting()
			end).toThrow(rest)
		end)
	end

	return {
		toFlushAndYield = expectToFlushAndYield,
		toFlushAndYieldThrough = expectToFlushAndYieldThrough,
		toFlushWithoutYielding = expectToFlushWithoutYielding,
		toFlushUntilNextPaint = toFlushUntilNextPaint,
		toFlushExpired = expectToFlushExpired,
		toHaveYielded = expectToHaveYielded,
		toFlushAndThrow = expectToFlushAndThrow,
	}
end
