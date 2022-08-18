local processServiceExists, ProcessService = pcall(function()
	return game:GetService("ProcessService")
end)

local Packages = script.Parent:FindFirstChild("RoactAlignment")
	or game:FindFirstChild("RoactAlignment", true)
if not Packages then
	error("Packages not found")
end

local RotrieverWorkspace = Packages._Workspace

-- ROBLOX FIXME: What's the more reasonable way of accessing this? Are all dev
-- dependencies hoisted to the top level in addition to existing as their
-- relevant interdependency links?
local TestEZ = require(RotrieverWorkspace.React.Dev.JestGlobals).TestEZ
local RobloxJest = require(RotrieverWorkspace.React.Dev.RobloxJest)

-- ROBLOX deviation: upstream mocks both of these via
-- scripts/setupHostConfigs.js, but this testing entry-point is the closest
-- equivalent we have
_G.__ROACT_17_MOCK_SCHEDULER__ = true
RobloxJest.mock(RotrieverWorkspace.Scheduler.Scheduler, function()
	return require(RotrieverWorkspace.Scheduler.Scheduler.unstable_mock)
end)

-- Run all tests, collect results, and report to stdout.
local result = TestEZ.TestBootstrap:run(
	{ RotrieverWorkspace },
	TestEZ.Reporters.TextReporterQuiet,
	{ extraEnvironment = RobloxJest.testEnv }
)

if result.failureCount == 0 and #result.errors == 0 then
	if processServiceExists then
		ProcessService:ExitAsync(0)
	end
end

if processServiceExists then
	ProcessService:ExitAsync(1)
end

return nil
