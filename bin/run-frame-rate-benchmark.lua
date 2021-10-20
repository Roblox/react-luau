local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)
local Scheduler = require(RotrieverWorkspace.Scheduler.Scheduler)
local frameRateBenchmark =
	require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).frameRateBenchmark

local config = {
	minSamples = 600,
}
if _G.minSamples ~= nil then
	config.minSamples = tonumber(_G.minSamples)
end

frameRateBenchmark(Roact, ReactRoblox, Scheduler)(config)
