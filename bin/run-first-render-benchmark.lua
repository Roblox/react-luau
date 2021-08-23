local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)
local Scheduler = require(RotrieverWorkspace.Scheduler.Scheduler)
local firstRenderBenchmark =
	require(
		RotrieverWorkspace.React.Dev.PerformanceBenchmarks
	).firstRenderBenchmark

firstRenderBenchmark(Roact, ReactRoblox, Scheduler)({
	minSamples = 200,
})
