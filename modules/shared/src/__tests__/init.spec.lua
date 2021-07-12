return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local getTestRendererJestMatchers = require(Packages.Dev.JestReact).getJestMatchers
	local getSchedulerJestMatchers = require(Packages.Dev.Scheduler).getJestMatchers

	beforeAll(function()
		jestExpect.extend(getTestRendererJestMatchers(jestExpect))
		jestExpect.extend(getSchedulerJestMatchers(jestExpect))

		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
