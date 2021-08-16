local Packages = script.Parent.RoactAlignment
local RotrieverWorkspace = Packages._Workspace

local Roact = require(RotrieverWorkspace.React.React)
local ReactRoblox = require(RotrieverWorkspace.ReactRoblox.ReactRoblox)

local SierpinskiTriangle = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmarks.cases.SierpinskiTriangle
)(Roact, ReactRoblox)
local TestUtils = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmarks.testUtils
)(Roact, ReactRoblox)
local benchmark = require(
	Packages._Index.PerformanceBenchmarks.PerformanceBenchmarks.benchmark
)(Roact, ReactRoblox)

benchmark({
	benchmarkName = "Update dynamic styles",
	timeout = 20000,
	testBlock = TestUtils.createTestBlock(function(components)
		return {
			benchmarkType = "update",
			Component = SierpinskiTriangle.SierpinskiTriangle,
			getComponentProps = function(props)
				return {
					components = components,
					s = 200,
					renderCount = props.cycle,
					sampleCount = props.sampleCount,
					x = 0,
					y = 0,
				}
			end,
			Provider = components.Provider,
			sampleCount = 50,
			anchorPoint = Vector2.new(0, 0),
		}
	end),
})
