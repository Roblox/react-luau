return function()
	local Packages = script.Parent.Parent.Parent

	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Error = LuauPolyfill.Error
	local errorToString = require(script.Parent.Parent["errorToString.roblox"])

	it("gives stack trace for Error", function()
		local errorString = errorToString(Error.new("h0wdy"))

		jestExpect(errorString).toContain("errorToString.roblox.spec")
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
end
