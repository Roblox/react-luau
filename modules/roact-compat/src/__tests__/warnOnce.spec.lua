return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jest = require(Packages.Dev.JestRoblox)
	local jestExpect = jest.Globals.expect
	local warnOnce

	beforeEach(function()
		RobloxJest.resetModules()
		warnOnce = require(script.Parent.Parent.warnOnce)
	end)

	it("warns exactly once", function()
		jestExpect(function()
			warnOnce("oldAPI", "Foo")
		end).toWarnDev(
			"Warning: The legacy Roact API 'oldAPI' is deprecated, and will be "
				.. "removed in a future release.\n\nFoo",
			{ withoutStack = true }
		)

		jestExpect(function()
			warnOnce("oldAPI", "Foo")
		end).toWarnDev({})
	end)
end
