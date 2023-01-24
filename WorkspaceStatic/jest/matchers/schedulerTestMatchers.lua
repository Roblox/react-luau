-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/scripts/jest/matchers/schedulerTestMatchers.js
local Packages = script.Parent.Parent.Parent.TestRunner
-- ROBLOX deviation START: fix import
-- local LuauPolyfill = require(Packages.LuauPolyfill)
local LuauPolyfill = require(Packages.Dev.LuauPolyfill)
-- ROBLOX deviation END
-- ROBLOX deviation START: not used
-- local Array = LuauPolyfill.Array
-- local Error = LuauPolyfill.Error
-- ROBLOX deviation END
local JestGlobals = require(Packages.Dev.JestGlobals)
local expect = JestGlobals.expect
-- ROBLOX deviation START: add import
type Array<T> = LuauPolyfill.Array<T>
-- ROBLOX deviation END
-- ROBLOX FIXME Luau: have to have explicit annotation as workaround for CLI-50002
-- ROBLOX deviation START: add return type
-- local function captureAssertion(fn)
local function captureAssertion(fn): { pass: boolean, message: (() -> string)? }
	-- ROBLOX deviation END
	-- Trick to use a Jest matcher inside another Jest matcher. `fn` contains an
	-- assertion; if it throws, we capture the error and return it, so the stack
	-- trace presented to the user points to the original assertion in the
	-- test file.
	do --[[ ROBLOX COMMENT: try-catch block conversion ]]
		-- ROBLOX deviation START: replace xpcall, addapt message to something useful
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
			local stringResult = tostring(result)
			local subMessageIndex = string.find(stringResult, " ")
			assert(
				subMessageIndex ~= nil,
				"assertion failure text wasn't in expected format"
			)
			local message = string.sub(stringResult, subMessageIndex + 1)

			return {
				pass = false,
				message = function()
					return message
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

-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
-- ROBLOX deviation START: add context argument
-- local function toFlushAndYield(Scheduler, expectedYields)
local function toFlushAndYield(_matcherContext, Scheduler, expectedYields: Array<any>)
	-- ROBLOX deviation END
	assertYieldsWereCleared(Scheduler)
	-- ROBLOX deviation START: use dot notation
	-- Scheduler:unstable_flushAllWithoutAsserting()
	-- local actualYields = Scheduler:unstable_clearYields()
	Scheduler.unstable_flushAllWithoutAsserting()
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	return captureAssertion(function()
		expect(actualYields).toEqual(expectedYields)
	end)
end

-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
-- ROBLOX deviation START: add context argument
-- local function toFlushAndYieldThrough(Scheduler, expectedYields)
local function toFlushAndYieldThrough(
	_matcherContext,
	Scheduler,
	expectedYields: Array<any>
)
	-- ROBLOX deviation END
	assertYieldsWereCleared(Scheduler)
	-- ROBLOX deviation START: use dot notation
	-- Scheduler:unstable_flushNumberOfYields(expectedYields.length)
	-- local actualYields = Scheduler:unstable_clearYields()
	Scheduler.unstable_flushNumberOfYields(#expectedYields)
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	return captureAssertion(function()
		expect(actualYields).toEqual(expectedYields)
	end)
end
-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
-- ROBLOX deviation START: add context argument
-- local function toFlushUntilNextPaint(Scheduler, expectedYields)
local function toFlushUntilNextPaint(
	_matcherContext,
	Scheduler,
	expectedYields: Array<any>
)
	-- ROBLOX deviation END
	assertYieldsWereCleared(Scheduler)
	-- ROBLOX deviation START: use dot notation
	-- Scheduler:unstable_flushUntilNextPaint()
	-- local actualYields = Scheduler:unstable_clearYields()
	Scheduler.unstable_flushUntilNextPaint()
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	return captureAssertion(function()
		expect(actualYields).toEqual(expectedYields)
	end)
end
-- ROBLOX deviation START: add context argument
-- local function toFlushWithoutYielding(Scheduler)
local function toFlushWithoutYielding(_matcherContext, Scheduler)
	-- ROBLOX deviation END
	-- ROBLOX deviation START: add context argument
	-- return toFlushAndYield(Scheduler, {})
	return toFlushAndYield(_matcherContext, Scheduler, {})
	-- ROBLOX deviation END
end

-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
-- ROBLOX deviation START: add context argument
-- local function toFlushExpired(Scheduler, expectedYields)
local function toFlushExpired(_matcherContext, Scheduler, expectedYields: Array<any>)
	-- ROBLOX deviation END
	assertYieldsWereCleared(Scheduler)
	-- ROBLOX deviation START: use dot notation
	-- Scheduler:unstable_flushExpired()
	-- local actualYields = Scheduler:unstable_clearYields()
	Scheduler.unstable_flushExpired()
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	return captureAssertion(function()
		expect(actualYields).toEqual(expectedYields)
	end)
end

-- ROBLOX FIXME Luau: Array<any> annotation here is so we don't have to put the annotation in many places due to mixed arrays
-- ROBLOX deviation START: add context argument
-- local function toHaveYielded(Scheduler, expectedYields)
local function toHaveYielded(_matcherContext, Scheduler, expectedYields: Array<any>)
	-- ROBLOX deviation END
	return captureAssertion(function()
		-- ROBLOX deviation START: use dot notation
		-- local actualYields = Scheduler:unstable_clearYields()
		local actualYields = Scheduler.unstable_clearYields()
		-- ROBLOX deviation END
		expect(actualYields).toEqual(expectedYields)
	end)
end
-- ROBLOX deviation START: add context argument
-- local function toFlushAndThrow(
-- 	Scheduler,
-- 	...: any --[[ ROBLOX CHECK: check correct type of elements. ]]
-- )
local function toFlushAndThrow(_matcherContext, Scheduler, ...)
	-- ROBLOX deviation END
	local rest = { ... }
	assertYieldsWereCleared(Scheduler)
	return captureAssertion(function()
		-- ROBLOX TODO Luau: if we wrap this function, we get an odd analyze error: Type '() -> ()' could not be converted into '{|  |}'
		-- ROBLOX deviation START: use dot notation, fix spreading
		-- expect(function()
		-- 	Scheduler:unstable_flushAllWithoutAsserting()
		-- end).toThrow(table.unpack(Array.spread(rest)))
		expect(Scheduler.unstable_flushAllWithoutAsserting).toThrow(table.unpack(rest))
		-- ROBLOX deviation END
	end)
end
-- ROBLOX deviation START: replace module.exports
-- module.exports = {
return {
	-- ROBLOX deviation END
	toFlushAndYield = toFlushAndYield,
	toFlushAndYieldThrough = toFlushAndYieldThrough,
	toFlushUntilNextPaint = toFlushUntilNextPaint,
	toFlushWithoutYielding = toFlushWithoutYielding,
	toFlushExpired = toFlushExpired,
	toHaveYielded = toHaveYielded,
	toFlushAndThrow = toFlushAndThrow,
}
