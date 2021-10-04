return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	beforeAll(function()
		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)
end
