return function()
	local Packages = script.Parent.Parent.Parent.Parent

	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local React
	local ReactRoblox
	local reactRobloxRoot
	local Scheduler
	local parent

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.useFakeTimers()
		local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false

		React = require(Packages.React)
		ReactRoblox = require(Packages.ReactRoblox)
		parent = Instance.new("Folder")
		reactRobloxRoot = ReactRoblox.createRoot(parent)
		Scheduler = require(Packages.Scheduler)
	end)

	it("should provide a useful error when initial prop assignment fails", function()
		reactRobloxRoot:render(
			React.createElement(
				"Frame",
				{},
				{ Root = React.createElement("TextLabel", { AbsentProp = 1 }) }
			)
		)

		jestExpect(function()
			jestExpect(Scheduler.unstable_flushAllWithoutAsserting).toErrorDev(
				"Error applying initial props to Roblox Instance 'Root' (TextLabel)"
			)
		end).toThrow()
	end)

	it("should provide a useful error when a props update fails", function()
		reactRobloxRoot:render(
			React.createElement(
				"Frame",
				{},
				{ Root = React.createElement("TextLabel", { Text = "Okay!" }) }
			)
		)

		Scheduler.unstable_flushAllWithoutAsserting()

		reactRobloxRoot:render(React.createElement("Frame", {}, {
			Root = React.createElement(
				"TextLabel",
				{ Text = "Not good", AbsentProp = 1 }
			),
		}))

		jestExpect(function()
			jestExpect(Scheduler.unstable_flushAllWithoutAsserting).toErrorDev(
				"Error updating props on Roblox Instance 'Root' (TextLabel):"
			)
		end).toThrow()
	end)

	it("should provide a useful error when a binding update fails", function()
		local neighbor, setNeighbor = React.createBinding(nil)
		reactRobloxRoot:render(React.createElement("Frame", {}, {
			Root = React.createElement("TextLabel", { NextSelectionLeft = neighbor }),
		}))

		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(function()
			jestExpect(function()
				setNeighbor("not an Instance")
			end).toErrorDev(
				"Error updating binding or ref assigned to key NextSelectionLeft of 'Root' (TextLabel).",
				{ withoutStack = true }
			)
		end).toThrow()
	end)
end
