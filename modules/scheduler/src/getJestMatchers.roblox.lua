--!strict
--[[
	Defines expectation extensions, including Scheduler-specific ones. This code
	is mostly based on:
	https://github.com/facebook/react/blob/47ff31a77add22bef54aaed9d4fb62d5aa693afd/scripts/jest/matchers/schedulerTestMatchers.js
]]
type Array<T> = { [number]: T }
-- ROBLOX FIXME Luau: have to have explicit annotation as workaround for CLI-50002
local function captureAssertion(fn): { pass: boolean, message: (() -> string)? }
	-- Trick to use a TestEZ expectation matcher inside another Jest
	-- matcher. `fn` contains an assertion; if it throws, we capture the
	-- error and return it, so the stack trace presented to the user points
	-- to the original assertion in the test file.
	local ok, result = pcall(fn)

	if not ok then
		-- ROBLOX deviation START: The message here will be a string with some extra info
		-- that's not helpful, so we trim it down a bit
		local stringResult = tostring(result)
		local subMessageIndex = string.find(stringResult, " ")
		assert(subMessageIndex ~= nil, "assertion failure text wasn't in expected format")
		local message = string.sub(stringResult, subMessageIndex + 1)

		return {
			pass = false,
			message = function()
				return message
			end,
		}
		-- ROBLOX deviation END
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

	-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
	local function expectToFlushAndYield(_matcherContext, scheduler, expectedYields: Array<any>)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushAllWithoutAsserting()
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
	local function expectToFlushAndYieldThrough(
		_matcherContext,
		scheduler,
		expectedYields: Array<any>
	)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushNumberOfYields(#expectedYields)
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
	local function toFlushUntilNextPaint(_matcherContext, Scheduler, expectedYields: Array<any>)
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

	-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
	local function expectToFlushExpired(_matcherContext, scheduler, expectedYields: Array<any>)
		assertYieldsWereCleared(scheduler)
		scheduler.unstable_flushExpired()
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
	local function expectToHaveYielded(_matcherContext, scheduler, expectedYields: Array<any>)
		local actualYields = scheduler.unstable_clearYields()

		return captureAssertion(function()
			jestExpect(actualYields).toEqual(expectedYields)
		end)
	end

	local function expectToFlushAndThrow(_matcherContext, scheduler, rest)
		assertYieldsWereCleared(scheduler)
		return captureAssertion(function()
			-- ROBLOX TODO Luau: if we wrap this function, we get an odd analyze error: Type '() -> ()' could not be converted into '{|  |}'
			jestExpect(scheduler.unstable_flushAllWithoutAsserting).toThrow(rest)
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
