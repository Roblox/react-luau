return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local getJestMatchers = require(script.Parent.Parent["getJestMatchers.roblox"])

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))
		jestExpect.extend(RobloxJest.Matchers)
	end)
end
