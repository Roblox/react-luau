local Packages = script.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local ErrorHandling = require(script.Parent.Parent["ErrorHandling.roblox"])
local describeError = ErrorHandling.describeError
local errorToString = ErrorHandling.errorToString
local parseReactError = ErrorHandling.parseReactError

describe("describeError", function()
	it("preserves original stack from string error when rethrown", function()
		local message = "preserve stack from string error"
		local function throws()
			error(message)
		end

		local ok, e = xpcall(throws, describeError)

		jestExpect(ok).toBe(false)
		jestExpect(e.message).toBe(message)
		local originalStack = e.stack

		local ok2, e2 = xpcall(function()
			error(e)
		end, describeError)

		jestExpect(ok2).toBe(false)
		jestExpect(e2.message).toBe(message)
		jestExpect(e2.stack).toBe(originalStack)
	end)

	it("preserves original stack from Error when rethrown", function()
		local message = "preserve stack from Error"
		local function throws()
			error(Error.new(message))
		end

		local ok, e = xpcall(throws, describeError)

		jestExpect(ok).toBe(false)
		jestExpect(e.message).toBe(message)
		local originalStack = e.stack

		local ok2, e2 = xpcall(function()
			error(e)
		end, describeError)

		jestExpect(ok2).toBe(false)
		jestExpect(e2.message).toBe(message)
		jestExpect(e2.stack).toBe(originalStack)
	end)

	it("transforms string errors into Error objects", function()
		local message = "transform string into Error"
		local function throws()
			error(message)
		end

		local ok, e = xpcall(throws, describeError)

		jestExpect(ok).toBe(false)
		jestExpect(LuauPolyfill.instanceof(e, Error)).toBe(true)
		jestExpect(e.message).toBe(message)
		jestExpect(e.stack).toContain(script:GetFullName())
	end)

	it("rethrows Error objects without changing them", function()
		local errorObject = Error.new("rethrow Error without changes")
		local function throws()
			error(errorObject)
		end

		local ok, e = xpcall(throws, describeError)

		jestExpect(ok).toBe(false)
		jestExpect(e).toBe(errorObject)
	end)
end)

describe("errorToString", function()
	it("gives stack trace for Error", function()
		local errorString = errorToString(Error.new("h0wdy"))

		jestExpect(errorString).toContain(script.Name)
		jestExpect(errorString).toContain("h0wdy")
	end)
	it("prints random tables", function()
		local errorString = errorToString({ ["$$h0wdy\n"] = 31337 })

		jestExpect(errorString).toContain("$$h0wdy")
		jestExpect(errorString).toContain("31337")
	end)
	it("prints arrays", function()
		local errorString = errorToString({ foo = 1, 2, 3 })

		jestExpect(errorString).toContain("foo: 1")
	end)
end)

describe("parseReactError", function()
	it("returns the whole message if not formatted as expected", function()
		local errorString = inspect(Error.new("not formatted for split"))

		local parsed, rethrow = parseReactError(errorString)
		jestExpect(parsed.message).toBe(errorString)
		-- Stack is nil because it's presumed to be included in the message
		-- and we wouldn't be able to generate a useful stack at parse time
		jestExpect(parsed.stack).toBeNil()
		-- The error was not rethrown, so rethrow will be an empty string
		jestExpect(rethrow).toBe("")
	end)

	it("does not split errors with the wrong number of sections", function()
		local errorString =
			table.concat({ "a", "b", "c", "d" }, ErrorHandling.__ERROR_DIVIDER)

		local parsed, rethrow = parseReactError(errorString)
		jestExpect(parsed.message).toBe(errorString)
		-- Stack is nil because it's presumed to be included in the message
		-- and we wouldn't be able to generate a useful stack at parse time
		jestExpect(parsed.stack).toBeNil()
		-- The error was not rethrown, so rethrow will be an empty string
		jestExpect(rethrow).toBe("")
	end)

	it("parses errors created by errorToString", function()
		local errorString = errorToString(Error.new("foo"))
		local stackIndex = debug.info(1, "l") - 1
		local throwFrame = string.format("%s:%d", debug.info(1, "s"), stackIndex)

		local parsed, rethrow = parseReactError(errorString)

		jestExpect(parsed.message).toBe("foo")
		jestExpect(parsed.stack).toContain(throwFrame)
		-- The error was not rethrown, so rethrow will be an empty string
		jestExpect(rethrow).toBe("")
	end)

	it("separates the stack frame from the rethrow", function()
		local errorObject = Error.new("bar")
		local stackIndex = debug.info(1, "l") - 1
		local throwFrame = string.format("%s:%d", debug.info(1, "s"), stackIndex)

		local ok, caughtString = xpcall(function()
			error(errorObject)
		end, errorToString)

		jestExpect(ok).toBe(false)
		-- Simluate rethrowing the stringified error (like Scheduler does in
		-- `performWorkUntilDeadline`) and catching it elsewhere
		local ok2, errorString = pcall(function()
			error(caughtString)
		end)
		stackIndex = debug.info(1, "l") - 2
		local rethrowFrame = string.format("%s:%d", debug.info(1, "s"), stackIndex)

		jestExpect(ok2).toBe(false)

		local parsed, rethrow = parseReactError(errorString)
		jestExpect(parsed.message).toBe("bar")
		jestExpect(parsed.stack).toContain(throwFrame)
		jestExpect(rethrow).toContain(rethrowFrame)
	end)
end)
