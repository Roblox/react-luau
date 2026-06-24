--!strict

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

local Scheduler

beforeEach(function()
	jest.resetModules()
	Scheduler = require(script.Parent.Parent.Scheduler)()
end)

it("allows runtime overrides for scheduler frame-rate flags", function()
	Scheduler.unstable_setSchedulerFlags({
		desiredFrameRate = 120,
		minimumFrameRate = 30,
	})

	local flags = Scheduler.unstable_getSchedulerFlags()
	jestExpect(flags.desiredFrameRate).toBe(120)
	jestExpect(flags.minimumFrameRate).toBe(30)
end)
