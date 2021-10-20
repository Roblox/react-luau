local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)
local wideTreeBenchmark =
	require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).wideTreeBenchmark

local config = {}
if _G.minSamples ~= nil then
	config.sampleCount = tonumber(_G.minSamples)
end

wideTreeBenchmark(Roact, ReactRoblox)(config)
