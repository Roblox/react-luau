local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)
local Scheduler = require(RotrieverWorkspace.Scheduler.Scheduler)
local frameRateBenchmark = require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).frameRateBenchmark

frameRateBenchmark(Roact, ReactRoblox, Scheduler)({
	minSamples = 600,
})
