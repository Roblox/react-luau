-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/scripts/jest/matchers/reactTestMatchers.js
local Packages = script.Parent.Parent.Parent.TestRunner
-- ROBLOX deviation START: fix import
-- local LuauPolyfill = require(Packages.LuauPolyfill)
local LuauPolyfill = require(Packages.Dev.LuauPolyfill)
-- ROBLOX deviation END
-- ROBLOX deviation START: not used
-- local Error = LuauPolyfill.Error
-- ROBLOX deviation END
local Object = LuauPolyfill.Object
local JestGlobals = require(Packages.Dev.JestGlobals)
local expect = JestGlobals.expect
-- ROBLOX deviation START: fix import
-- local JestReact = require_("jest-react")
-- local SchedulerMatchers = require_("./schedulerTestMatchers")
local JestReact = require(Packages.Dev.JestReact)
local SchedulerMatchers = require(script.Parent.schedulerTestMatchers)
-- ROBLOX deviation END
-- ROBLOX deviation START: add return type
-- local function captureAssertion(fn)
local function captureAssertion(
	fn
): { pass: false, message: () -> string } | { pass: true }
	-- ROBLOX deviation END
	-- Trick to use a Jest matcher inside another Jest matcher. `fn` contains an
	-- assertion; if it throws, we capture the error and return it, so the stack
	-- trace presented to the user points to the original assertion in the
	-- test file.
	do --[[ ROBLOX COMMENT: try-catch block conversion ]]
		-- ROBLOX deviation START: use pcall, simplify
		-- local ok, result, hasReturned = xpcall(function()
		-- 	fn()
		-- end, function(error_)
		-- 	return {
		-- 		pass = false,
		-- 		message = function()
		-- 			return error_.message
		-- 		end,
		-- 	},
		-- 		true
		-- end)
		-- if hasReturned then
		-- 	return result
		-- end
		local ok, result = pcall(fn)

		if not ok then
			return {
				pass = false,
				message = function()
					return tostring(result)
				end,
			}
		end
		-- ROBLOX deviation END
	end
	return { pass = true }
end

local function assertYieldsWereCleared(Scheduler)
	-- ROBLOX deviation START: use dot notation
	-- local actualYields = Scheduler:unstable_clearYields()
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	-- ROBLOX deviation START: fix .length
	-- if actualYields.length ~= 0 then
	if #actualYields ~= 0 then
		-- ROBLOX deviation END
		error(
			-- ROBLOX deviation START: adapt error message, error with string
			-- Error.new(
			-- 	"Log of yielded values is not empty. "
			-- 		.. "Call expect(Scheduler).toHaveYielded(...) first."
			-- )
			"Log of yielded values is not empty. "
				.. "Call expectToHaveYielded(Scheduler, ...) first.",
			3
			-- ROBLOX deviation END
		)
	end
end
-- ROBLOX deviation START: add context argument
-- local function toMatchRenderedOutput(ReactNoop, expectedJSX)
local function toMatchRenderedOutput(_matcherContext, ReactNoop, expectedJSX)
	-- ROBLOX deviation END
	if typeof(ReactNoop.getChildrenAsJSX) == "function" then
		local Scheduler = ReactNoop._Scheduler
		assertYieldsWereCleared(Scheduler)
		return captureAssertion(function()
			-- ROBLOX deviation START: use dot notation
			-- expect(ReactNoop:getChildrenAsJSX()).toEqual(expectedJSX)
			expect(ReactNoop.getChildrenAsJSX()).toEqual(expectedJSX)
			-- ROBLOX deviation END
		end)
	end
	-- ROBLOX deviation START: use dot notation
	-- return JestReact:unstable_toMatchRenderedOutput(ReactNoop, expectedJSX)
	return JestReact.unstable_toMatchRenderedOutput(ReactNoop, expectedJSX)
	-- ROBLOX deviation END
end
-- ROBLOX deviation START: replace module.exports
-- module.exports = Object.assign(
return Object.assign(
	-- ROBLOX deviation END
	{},
	SchedulerMatchers,
	{ toMatchRenderedOutput = toMatchRenderedOutput }
)
