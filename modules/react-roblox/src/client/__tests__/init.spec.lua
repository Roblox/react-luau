return function()
	local Packages = script.Parent.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local getJestMatchers = require(Packages.Scheduler).getJestMatchers

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))

		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
