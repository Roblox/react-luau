--[[
	Roblox upstream: https://github.com/facebook/react/blob/69060e1da6061af845162dcf6854a5d9af28350a/scripts/jest/matchers/reactTestMatchers.js

	Note: this file is partially redundant with modules/scheduler/src/getJestMatchers.roblox.lua
	That is also happening upstream: https://github.com/facebook/react/blob/47ff31a77add22bef54aaed9d4fb62d5aa693afd/scripts/jest/matchers/schedulerTestMatchers.js
]]
local JestReact = require(script.Parent.JestReact)

local function captureAssertion(fn)
	-- Trick to use a TestEZ expectation matcher inside another Jest
	-- matcher. `fn` contains an assertion; if it throws, we capture the
	-- error and return it, so the stack trace presented to the user points
	-- to the original assertion in the test file.
	local ok, result = pcall(fn)

	if not ok then
		return {
			pass = false,
			message = function()
				return tostring(result)
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

	local function expectToMatchRenderedOutput(_matcherContext, ReactNoop, expectedJSX)
		if typeof(ReactNoop.getChildrenAsJSX) == "function" then
			local Scheduler = ReactNoop._Scheduler
			assertYieldsWereCleared(Scheduler)
			return captureAssertion(function()
				jestExpect(ReactNoop.getChildrenAsJSX()).toEqual(expectedJSX)
			end)
		end
		return JestReact.unstable_toMatchRenderedOutput(ReactNoop, expectedJSX)
	end

	return {
		toMatchRenderedOutput = expectToMatchRenderedOutput,
	}
end
