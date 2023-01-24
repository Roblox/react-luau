--!nonstrict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6d50a9d090a2a672fc3dea5ce77a3a05332a6caa/fixtures/legacy-jsx-runtimes/setupTests.js
local Packages = script.Parent.Parent.Parent.TestRunner
local JestDiff = require(Packages.Dev.JestDiff)

local function shouldIgnoreConsoleError(format, args)
	-- deviation: instead of checking if `process.env.NODE_ENV ~= "production"`
	-- we use the __DEV__ global
	if _G.__DEV__ then
		if typeof(format) == "string" then
			if string.find(format, "Error: Uncaught %[") == 1 then
				-- // This looks like an uncaught error from invokeGuardedCallback() wrapper
				-- // in development that is reported by jsdom. Ignore because it's noisy.
				return true
			end
			-- ROBLOX FIXME: The "Warning: " prefix is applied before the string
			-- reaches this function, which appears to not be the case upstream
			if string.find(format, "Warning: The above error occurred") == 1 then
				-- // This looks like an error addendum from ReactFiberErrorLogger.
				-- // Ignore it too.
				return true
			end
		end
	else
		if
			format ~= nil
			and typeof(format.message) == "string"
			and typeof(format.stack) == "string"
			and #args == 0
		then
			-- // In production, ReactFiberErrorLogger logs error objects directly.
			-- // They are noisy too so we'll try to ignore them.
			return true
		end
		if
			string.find(format, "act(...) is not supported in production builds of React")
			== 0
		then
			-- // We don't yet support act() for prod builds, and warn for it.
			-- // But we'd like to use act() ourselves for prod builds.
			-- // Let's ignore the warning and #yolo.
			return true
		end
	end

	return false
end

local function normalizeCodeLocInfo(str)
	if typeof(str) ~= "string" then
		return str
	end

	-- // This special case exists only for the special source location in
	-- // ReactElementValidator. That will go away if we remove source locations.
	str = string.gsub(str, "Check your code at .*:%d+", "Check your code at **")
	-- // V8 format:
	-- //  at Component (/path/filename.js:123:45)
	-- // React format:
	-- //    in Component (at filename.js:123)

	-- ROBLOX deviation: In roblox/luau, we're using the stack frame from luau,
	-- which looks like:
	--     in Component (at ModulePath.FileName.lua:123)
	return (string.gsub(str, "\n    in ([%w%-%._]+)[^\n]*", "\n    in %1 (at **)"))
end

return function(consoleMethod, matcherName)
	return function(_matcherContext, callback, expectedMessages, options, ...)
		local LuauPolyfill = require(Packages.Dev.LuauPolyfill)
		local Array = LuauPolyfill.Array
		local console = LuauPolyfill.console

		if options == nil then
			options = {}
		end
		-- deviation: instead of checking if `process.env.NODE_ENV ~= "production"`
		-- we use the __DEV__ global
		if _G.__DEV__ then
			-- // Warn about incorrect usage of matcher.
			if typeof(expectedMessages) == "string" then
				expectedMessages = { expectedMessages }
			elseif not Array.isArray(expectedMessages) then
				error(
					string.format(
						"%s() requires a parameter of type string or an array of strings ",
						matcherName
					)
						.. string.format("but was given %s.", typeof(expectedMessages))
				)
			end
			-- deviation: since an empty table will return true for
			-- `Array.isArray(options)`, check if the table is not empty
			if
				typeof(options) ~= "table"
				or (Array.isArray(options) and next(options) ~= nil)
			then
				error(
					string.format(
						"%s() second argument, when present, should be an object. ",
						matcherName
					)
						.. "Did you forget to wrap the messages into an array?"
				)
			end
			if select("#", ...) > 0 then
				error(
					string.format("%s() received more than two arguments. ", matcherName)
						.. "Did you forget to wrap the messages into an array?"
				)
			end

			local withoutStack = options.withoutStack
			local logAllErrors = options.logAllErrors
			local warningsWithoutComponentStack = {}
			local warningsWithComponentStack = {}
			local unexpectedWarnings = {}

			local lastWarningWithMismatchingFormat = nil
			local lastWarningWithExtraComponentStack = nil

			-- // Catch errors thrown by the callback,
			-- // But only rethrow them if all test expectations have been satisfied.
			-- // Otherwise an Error in the callback can mask a failed expectation,
			-- // and result in a test that passes when it shouldn't.
			local caughtError

			local function isLikelyAComponentStack(message)
				return typeof(message) == "string"
					and string.match(message, "\n    in ") ~= nil
			end

			local function consoleSpy(format, ...)
				-- // Ignore uncaught errors reported by jsdom
				-- // and React addendums because they're too noisy.
				local args = { ... }
				if
					not logAllErrors
					and consoleMethod == "error"
					and shouldIgnoreConsoleError(format, args)
				then
					return
				end

				local message = format
				local formattedOk, formattedOrError =
					pcall(string.format, format, unpack(args))
				if formattedOk then
					message = formattedOrError
				end
				local normalizedMessage = normalizeCodeLocInfo(message)

				-- Remember if the number of %s interpolations
				-- doesn't match the number of arguments.
				-- We'll fail the test if it happens.
				local argIndex = 0
				-- ROBLOX FIXME selene: remove _ assignment when bug in selene is fixed https://github.com/Kampfkarren/selene/issues/406
				local _ = string.gsub(format, "%%s", function()
					argIndex = argIndex + 1
					return argIndex - 1
				end)

				if not formattedOk or argIndex ~= #args then
					lastWarningWithMismatchingFormat = {
						format = format,
						args = args,
						expectedArgCount = argIndex,
					}
				end

				-- // Protect against accidentally passing a component stack
				-- // to warning() which already injects the component stack.
				if
					#args >= 2
					and isLikelyAComponentStack(args[#args])
					and isLikelyAComponentStack(args[#args - 1])
				then
					lastWarningWithExtraComponentStack = { format = format }
				end

				for index = 1, #expectedMessages do
					local expectedMessage = expectedMessages[index]
					if
						normalizedMessage == expectedMessage
						or string.find(normalizedMessage, expectedMessage, 1, true)
							~= nil
					then
						if isLikelyAComponentStack(normalizedMessage) then
							table.insert(warningsWithComponentStack, normalizedMessage)
						else
							table.insert(warningsWithoutComponentStack, normalizedMessage)
						end
						Array.splice(expectedMessages, index, 1)
						return
					end
				end

				local errorMessage
				if #expectedMessages == 0 then
					errorMessage = "Unexpected warning recorded: " .. normalizedMessage
				elseif #expectedMessages == 1 then
					errorMessage = "Unexpected warning recorded: "
						.. tostring(JestDiff.diff(expectedMessages[1], normalizedMessage))
				else
					errorMessage = "Unexpected warning recorded: "
						.. tostring(
							JestDiff.diff(expectedMessages, { normalizedMessage })
						)
				end

				-- // Record the call stack for unexpected warnings.
				-- // We don't throw an Error here though,
				-- // Because it might be suppressed by ReactFiberScheduler.
				table.insert(unexpectedWarnings, errorMessage)
			end

			-- // TODO Decide whether we need to support nested toWarn* expectations.
			-- // If we don't need it, add a check here to see if this is already our spy,
			-- // And throw an error.
			local originalMethod = console[consoleMethod]

			-- // Avoid using Jest's built-in spy since it can't be removed.
			console[consoleMethod] = consoleSpy

			local ok, errorMessage = pcall(callback)
			if not ok then
				caughtError = errorMessage
			end

			-- finally block
			-- // Restore the unspied method so that unexpected errors fail tests.
			console[consoleMethod] = originalMethod

			-- // Any unexpected Errors thrown by the callback should fail the test.
			-- // This should take precedence since unexpected errors could block warnings.
			if caughtError then
				error(caughtError, 4)
			end

			-- // Any unexpected warnings should be treated as a failure.
			if #unexpectedWarnings > 0 then
				return {
					message = function()
						return unexpectedWarnings[1]
					end,
					pass = false,
				}
			end

			-- // Any remaining messages indicate a failed expectations.
			if #expectedMessages > 0 then
				return {
					message = function()
						return string.format(
							"Expected warning was not recorded: %s\n  ",
							expectedMessages[1]
						)
					end,
					pass = false,
				}
			end

			if typeof(withoutStack) == "number" then
				-- // We're expecting a particular number of warnings without stacks.
				if withoutStack ~= #warningsWithoutComponentStack then
					local warnings = warningsWithoutComponentStack
					return {
						message = function()
							return ("Expected %d warnings without a component stack but received %d:\n"):format(
								withoutStack,
								#warningsWithoutComponentStack
							) .. table.concat(warnings, "\n")
						end,
						pass = false,
					}
				end
			elseif withoutStack == true then
				if #warningsWithComponentStack > 0 then
					return {
						message = function()
							return "Received warning unexpectedly includes a component stack:\n"
								.. ("  %s\nIf this warning intentionally includes the component stack, remove "):format(
									warningsWithComponentStack[1]
								)
								.. ("{withoutStack: true} from the %s() call. If you have a mix of "):format(
									matcherName
								)
								.. ("warnings with and without stack in one %s() call, pass "):format(
									matcherName
								)
								.. "{withoutStack: N} where N is the number of warnings without stacks."
						end,
						pass = false,
					}
				end
			elseif withoutStack == false or withoutStack == nil then
				-- // We're expecting that all warnings *do* have the stack (default).
				-- // If some warnings don't have it, it's an error.
				if #warningsWithoutComponentStack > 0 then
					return {
						message = function()
							return "Received warning unexpectedly does not include a component stack:\n"
								.. ("  %s\nIf this warning intentionally omits the component stack, add "):format(
									warningsWithoutComponentStack[1]
								)
								.. string.format(
									"{withoutStack: true} to the %s call.",
									matcherName
								)
						end,
						pass = false,
					}
				end
			else
				error(
					("The second argument for %s(), when specified, must be an object. It may have a "):format(
						matcherName
					)
						.. 'property called "withoutStack" whose value may be undefined, boolean, or a number. '
						.. string.format("Instead received %s.", typeof(withoutStack))
				)
			end

			if lastWarningWithMismatchingFormat ~= nil then
				return {
					message = function()
						return ("Received %d arguments for a message with %s placeholders:\n  %s"):format(
							#lastWarningWithMismatchingFormat.args,
							lastWarningWithMismatchingFormat.expectedArgCount,
							lastWarningWithMismatchingFormat.format
						)
					end,
					pass = false,
				}
			end
			if lastWarningWithExtraComponentStack ~= nil then
				return {
					message = function()
						return "Received more than one component stack for a warning:\n"
							.. ("  %s\nDid you accidentally pass a stack to warning() as the last argument? "):format(
								lastWarningWithExtraComponentStack.format
							)
							.. "Don't forget warning() already injects the component stack automatically."
					end,
					pass = false,
				}
			end

			return { pass = true }
		else
			-- // Any uncaught errors or warnings should fail tests in production mode.
			callback()

			return { pass = true }
		end
	end
end
