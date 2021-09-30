local Packages = game.ReplicatedStorage.Packages
local RotrieverWorkspace = Packages._Workspace

-- ROBLOX FIXME: What's the more reasonable way of accessing this? Are all dev
-- dependencies hoisted to the top level in addition to existing as their
-- relevant interdependency links?
local JestRoblox = require(RotrieverWorkspace.React.Dev.JestRoblox)
local RobloxJest = require(RotrieverWorkspace.React.Dev.RobloxJest)

-- ROBLOX deviation: upstream mocks both of these via
-- scripts/setupHostConfigs.js, but this testing entry-point is the closest
-- equivalent we have
RobloxJest.mock(RotrieverWorkspace.Scheduler.Scheduler, function()
	return require(RotrieverWorkspace.Scheduler.Scheduler.unstable_mock)
end)

-- Run all tests, collect results, and report to stdout.
local result = JestRoblox.TestBootstrap:run(
	{ game.StarterPlayer },
	JestRoblox.Reporters.TextReporterQuiet,
	{ extraEnvironment = RobloxJest.testEnv }
)

return nil
