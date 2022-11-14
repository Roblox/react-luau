local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)

local config = {}
if _G.minSamples ~= nil then
	config.sampleCount = tonumber(_G.minSamples)
end

require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).deepTreeBenchmark(
	Roact,
	ReactRoblox
)(config)
