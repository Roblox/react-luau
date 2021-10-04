local Packages = game.ReplicatedStorage.Packages
local RotrieverWorkspace = Packages._Workspace

-- ROBLOX FIXME: What's the more reasonable way of accessing this? Are all dev
-- dependencies hoisted to the top level in addition to existing as their
-- relevant interdependency links?
local TestEZ = require(RotrieverWorkspace.React.Dev.JestGlobals).TestEZ
local RobloxJest = require(RotrieverWorkspace.React.Dev.RobloxJest)

-- ROBLOX deviation: upstream mocks both of these via
-- scripts/setupHostConfigs.js, but this testing entry-point is the closest
-- equivalent we have
RobloxJest.mock(RotrieverWorkspace.Scheduler.Scheduler, function()
	return require(RotrieverWorkspace.Scheduler.Scheduler.unstable_mock)
end)

-- Run all tests, collect results, and report to stdout.
local result = TestEZ.TestBootstrap:run(
	{ game.StarterPlayer },
	TestEZ.Reporters.TextReporterQuiet,
	{ extraEnvironment = RobloxJest.testEnv }
)

return nil
