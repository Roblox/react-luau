local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)

local Tree = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmarks.cases.Tree
)(Roact, ReactRoblox)
local TestUtils = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmarks.testUtils
)(Roact, ReactRoblox)
local benchmark = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmark
)(Roact, ReactRoblox)

benchmark({
	benchmarkName = "Mount wide tree",
	timeout = 20000,
	testBlock = TestUtils.createTestBlock(function(components)
		return {
			benchmarkType = "mount",
			Component = Tree.Tree,
			getComponentProps = function()
				return { breadth = 6, components = components, depth = 3, id = 0, wrap = 2 }
			end,
			Provider = components.Provider,
			sampleCount = 50,
		}
	end),
})
