local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)
local Scheduler = require(RotrieverWorkspace.Scheduler.Scheduler)
local firstRenderBenchmark =
	require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).firstRenderBenchmark

local config = {
	minSamples = 200,
}
if _G.minSamples ~= nil then
	config.minSamples = tonumber(_G.minSamples)
end

firstRenderBenchmark(Roact, ReactRoblox, Scheduler)(config)
