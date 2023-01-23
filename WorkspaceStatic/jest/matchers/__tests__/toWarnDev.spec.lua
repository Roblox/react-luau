-- ROBLOX upstream https://github.com/facebook/react/blob/0b5a26a4895261894f04e50d5a700e83b9c0dcf6/scripts/jest/matchers/__tests__/toWarnDev-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
local Packages = script.Parent.Parent.Parent.Parent.TestRunner
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local beforeAll = JestGlobals.beforeAll
local describe = JestGlobals.describe
local it = JestGlobals.it
local toErrorDev = require(script.Parent.Parent.Parent.matchers.toErrorDev)
local toWarnDev = require(script.Parent.Parent.Parent.matchers.toWarnDev)

local console

beforeAll(function()
	jestExpect.extend({
		toErrorDev = toErrorDev,
		toWarnDev = toWarnDev,
	})
end)

beforeEach(function()
	local LuauPolyfill = require(Packages.Dev.LuauPolyfill)
	console = LuauPolyfill.console
end)

describe("toErrorDev", function()
	it("does not fail if a warning contains a stack", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.error("Hello\n    in div")
			end
		end).toErrorDev("Hello")
	end)

	it("does not fail if all warnings contain a stack", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.error("Hello\n    in div")
				console.error("Good day\n    in div")
				console.error("Bye\n    in div")
			end
		end).toErrorDev({
			"Hello",
			"Good day",
			"Bye",
		})
	end)

	it("does not fail if warnings without stack explicitly opt out", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.error("Hello")
			end
		end).toErrorDev("Hello", { withoutStack = true })
		jestExpect(function()
			if _G.__DEV__ then
				console.error("Hello")
				console.error("Good day")
				console.error("Bye")
			end
		end).toErrorDev({
			"Hello",
			"Good day",
			"Bye",
		}, {
			withoutStack = true,
		})
	end)

	it(
		"does not fail when expected stack-less warning number matches the actual one",
		function()
			jestExpect(function()
				if _G.__DEV__ then
					console.error("Hello\n    in div")
					console.error("Good day")
					console.error("Bye\n    in div")
				end
			end).toErrorDev({
				"Hello",
				"Good day",
				"Bye",
			}, {
				withoutStack = 1,
			})
		end
	)

	if _G.__DEV__ then
		-- // Helper methods avoids invalid toWarn().toThrow() nesting
		-- // See no-to-warn-dev-within-to-throw
		local function expectToWarnAndToThrow(expectBlock, expectedErrorMessage)
			-- deviation: use TestEZ to thow to get a better error message
			jestExpect(expectBlock).toThrow(expectedErrorMessage)
		end

		it("fails if a warning does not contain a stack", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello")
				end).toErrorDev("Hello")
			end, "Received warning unexpectedly does not include a component stack")
		end)

		it("fails if some warnings do not contain a stack", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello\n    in div")
					console.error("Good day\n    in div")
					console.error("Bye")
				end).toErrorDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello")
					console.error("Good day\n    in div")
					console.error("Bye\n    in div")
				end).toErrorDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello\n    in div")
					console.error("Good day")
					console.error("Bye\n    in div")
				end).toErrorDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello")
					console.error("Good day")
					console.error("Bye")
				end).toErrorDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
		end)

		it("fails if warning is expected to not have a stack, but does", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello\n    in div")
				end).toErrorDev("Hello", { withoutStack = true })
			end, "Received warning unexpectedly includes a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hello\n    in div")
					console.error("Good day")
					console.error("Bye\n    in div")
				end).toErrorDev({
					"Hello",
					"Good day",
					"Bye",
				}, {
					withoutStack = true,
				})
			end, "Received warning unexpectedly includes a component stack")
		end)

		it(
			"fails if expected stack-less warning number does not match the actual one",
			function()
				expectToWarnAndToThrow(function()
					jestExpect(function()
						console.error("Hello\n    in div")
						console.error("Good day")
						console.error("Bye\n    in div")
					end).toErrorDev({
						"Hello",
						"Good day",
						"Bye",
					}, {
						withoutStack = 4,
					})
				end, "Expected 4 warnings without a component stack but received 1")
			end
		)

		it("fails if withoutStack is invalid", function()
			-- deviation: null should error, but not undefined. Since they're the same
			-- in Lua, we can comment the expectation
			-- expectToWarnAndToThrow(function()
			-- 	jestExpect(function()
			-- 		console.error("Hi")
			-- 	end).toErrorDev("Hi", {withoutStack = null})
			-- end, "Instead received object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi")
				end).toErrorDev("Hi", { withoutStack = {} })
			end, "Instead received table")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi")
				end).toErrorDev("Hi", {
					withoutStack = "haha",
				})
			end, "Instead received string")
		end)

		it("fails if the argument number does not match", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi %s", "Sara", "extra")
				end).toErrorDev("Hi", { withoutStack = true })
			end, "Received 2 arguments for a message with 1 placeholders")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi %s")
				end).toErrorDev("Hi", { withoutStack = true })
			end, "Received 0 arguments for a message with 1 placeholders")
		end)

		it("fails if stack is passed twice", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi %s%s", "\n    in div", "\n    in div")
				end).toErrorDev("Hi")
			end, "Received more than one component stack for a warning")
		end)

		it("fails if multiple strings are passed without an array wrapper", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi \n    in div")
				end).toErrorDev("Hi", "Bye")
			end, "toErrorDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi \n    in div")
					console.error("Bye \n    in div")
				end).toErrorDev("Hi", "Bye")
			end, "toErrorDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi \n    in div")
					console.error("Wow \n    in div")
					console.error("Bye \n    in div")
				end).toErrorDev("Hi", "Bye")
			end, "toErrorDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi \n    in div")
					console.error("Wow \n    in div")
					console.error("Bye \n    in div")
				end).toErrorDev("Hi", "Wow", "Bye")
			end, "toErrorDev() second argument, when present, should be an object")
		end)

		it("fails on more than two arguments", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.error("Hi \n    in div")
					console.error("Wow \n    in div")
					console.error("Bye \n    in div")
				end).toErrorDev("Hi", nil, "Bye")
			end, "toErrorDev() received more than two arguments.")
		end)
	end
end)

describe("toWarnDev", function()
	it("does not fail if a warning contains a stack", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.warn("Hello\n    in div")
			end
		end).toWarnDev("Hello")
	end)

	it("does not fail if all warnings contain a stack", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.warn("Hello\n    in div")
				console.warn("Good day\n    in div")
				console.warn("Bye\n    in div")
			end
		end).toWarnDev({
			"Hello",
			"Good day",
			"Bye",
		})
	end)

	it("does not fail if warnings without stack explicitly opt out", function()
		jestExpect(function()
			if _G.__DEV__ then
				console.warn("Hello")
			end
		end).toWarnDev("Hello", { withoutStack = true })
		jestExpect(function()
			if _G.__DEV__ then
				console.warn("Hello")
				console.warn("Good day")
				console.warn("Bye")
			end
		end).toWarnDev({
			"Hello",
			"Good day",
			"Bye",
		}, {
			withoutStack = true,
		})
	end)

	it(
		"does not fail when expected stack-less warning number matches the actual one",
		function()
			jestExpect(function()
				if _G.__DEV__ then
					console.warn("Hello\n    in div")
					console.warn("Good day")
					console.warn("Bye\n    in div")
				end
			end).toWarnDev({
				"Hello",
				"Good day",
				"Bye",
			}, {
				withoutStack = 1,
			})
		end
	)

	if _G.__DEV__ then
		-- // Helper methods avoids invalid toWarn().toThrow() nesting
		-- // See no-to-warn-dev-within-to-throw
		local function expectToWarnAndToThrow(expectBlock, expectedErrorMessage)
			-- deviation: use TestEZ to thow to get a better error message
			jestExpect(expectBlock).toThrow(expectedErrorMessage)
		end

		it("fails if a warning does not contain a stack", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello")
				end).toWarnDev("Hello")
			end, "Received warning unexpectedly does not include a component stack")
		end)

		it("fails if some warnings do not contain a stack", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello\n    in div")
					console.warn("Good day\n    in div")
					console.warn("Bye")
				end).toWarnDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello")
					console.warn("Good day\n    in div")
					console.warn("Bye\n    in div")
				end).toWarnDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello\n    in div")
					console.warn("Good day")
					console.warn("Bye\n    in div")
				end).toWarnDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello")
					console.warn("Good day")
					console.warn("Bye")
				end).toWarnDev({
					"Hello",
					"Good day",
					"Bye",
				})
			end, "Received warning unexpectedly does not include a component stack")
		end)

		it("fails if warning is expected to not have a stack, but does", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello\n    in div")
				end).toWarnDev("Hello", { withoutStack = true })
			end, "Received warning unexpectedly includes a component stack")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hello\n    in div")
					console.warn("Good day")
					console.warn("Bye\n    in div")
				end).toWarnDev({
					"Hello",
					"Good day",
					"Bye",
				}, {
					withoutStack = true,
				})
			end, "Received warning unexpectedly includes a component stack")
		end)

		it(
			"fails if expected stack-less warning number does not match the actual one",
			function()
				expectToWarnAndToThrow(function()
					jestExpect(function()
						console.warn("Hello\n    in div")
						console.warn("Good day")
						console.warn("Bye\n    in div")
					end).toWarnDev({
						"Hello",
						"Good day",
						"Bye",
					}, {
						withoutStack = 4,
					})
				end, "Expected 4 warnings without a component stack but received 1")
			end
		)

		it("fails if withoutStack is invalid", function()
			-- deviation: null should error, but not undefined. Since they're the same
			-- in Lua, we can comment the expectation
			-- expectToWarnAndToThrow(function()
			-- 	jestExpect(function()
			-- 		console.warn("Hi")
			-- 	end).toWarnDev("Hi", {withoutStack = nil})
			-- end, "Instead received object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi")
				end).toWarnDev("Hi", { withoutStack = {} })
			end, "Instead received table")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi")
				end).toWarnDev("Hi", {
					withoutStack = "haha",
				})
			end, "Instead received string")
		end)

		it("fails if the argument number does not match", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi %s", "Sara", "extra")
				end).toWarnDev("Hi", { withoutStack = true })
			end, "Received 2 arguments for a message with 1 placeholders")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi %s")
				end).toWarnDev("Hi", { withoutStack = true })
			end, "Received 0 arguments for a message with 1 placeholders")
		end)

		it("fails if stack is passed twice", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi %s%s", "\n    in div", "\n    in div")
				end).toWarnDev("Hi")
			end, "Received more than one component stack for a warning")
		end)

		it("fails if multiple strings are passed without an array wrapper", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi \n    in div")
				end).toWarnDev("Hi", "Bye")
			end, "toWarnDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi \n    in div")
					console.warn("Bye \n    in div")
				end).toWarnDev("Hi", "Bye")
			end, "toWarnDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi \n    in div")
					console.warn("Wow \n    in div")
					console.warn("Bye \n    in div")
				end).toWarnDev("Hi", "Bye")
			end, "toWarnDev() second argument, when present, should be an object")
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi \n    in div")
					console.warn("Wow \n    in div")
					console.warn("Bye \n    in div")
				end).toWarnDev("Hi", "Wow", "Bye")
			end, "toWarnDev() second argument, when present, should be an object")
		end)

		it("fails on more than two arguments", function()
			expectToWarnAndToThrow(function()
				jestExpect(function()
					console.warn("Hi \n    in div")
					console.warn("Wow \n    in div")
					console.warn("Bye \n    in div")
				end).toWarnDev("Hi", nil, "Bye")
			end, "toWarnDev() received more than two arguments.")
		end)
	end
end)

describe("toLogDev", function()
	it("does not fail if a logs contains a stack", function()
		jestExpect(function()
			console.log("Hello\n    in div")
		end).toLogDev("Hello")
	end)

	it("does not fail if all logs contain a stack", function()
		jestExpect(function()
			console.log("Hello\n    in div")
			console.log("Good day\n    in div")
			console.log("Bye\n    in div")
		end).toLogDev({
			"Hello",
			"Good day",
			"Bye",
		})
	end)
end)
