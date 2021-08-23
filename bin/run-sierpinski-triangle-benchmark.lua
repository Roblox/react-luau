local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)

require(RotrieverWorkspace.React.Dev.PerformanceBenchmarks).sierpinskiTriangleBenchmark(
	Roact,
	ReactRoblox
)()
