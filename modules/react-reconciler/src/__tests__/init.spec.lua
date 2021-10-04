return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local getTestRendererJestMatchers = require(Packages.Dev.JestReact).getJestMatchers
	local getSchedulerJestMatchers = require(Packages.Scheduler).getJestMatchers

	beforeAll(function()
		jestExpect.extend(getTestRendererJestMatchers(jestExpect))
		jestExpect.extend(getSchedulerJestMatchers(jestExpect))
		jestExpect.extend(RobloxJest.Matchers)
	end)
end
