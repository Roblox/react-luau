--[[
	This test is currently run manually to verify the DeveloperTools library integrates into roact-alignment
]]
type Function = (...any) -> any?

return function()
	describe("Devtools Integration", function()
		local Packages = script.Parent.Parent.Parent
		local inspector
		local RobloxJest = require(Packages.Dev.RobloxJest)
		local JestGlobals = require(Packages.Dev.JestGlobals)
		local jestExpect = JestGlobals.expect
		local jest = JestGlobals.jest
		local ReactDevtoolsExtensions
		local React

		beforeEach(function()
			React = require(Packages.React)
			RobloxJest.resetModules()
			local DeveloperTools = require(Packages.Dev.DeveloperTools)
			ReactDevtoolsExtensions = require(Packages.ReactDevtoolsExtensions)

			inspector = DeveloperTools.forLibrary("UniversalApp", {})
			inspector:initRoact(ReactDevtoolsExtensions)
		end)

		afterEach(function()
			RobloxJest.resetModules()
		end)

		-- Devtools naturally relies on using DEV mode, so this test only makes
		-- sense when it's enabled
		local itSkipIfNonDEV = it
		if not _G.__DEV__ then
			itSkipIfNonDEV = xit
		end

		itSkipIfNonDEV(
			"can connect to a Roact tree and inspect its children and child branch nodes",
			function()
				local ReactRoblox = require(Packages.ReactRoblox)

				local function act(callback: Function): ()
					local actTestRenderer = require(Packages.Dev.ReactTestRenderer).act

					actTestRenderer(function()
						callback()
					end)

					while RobloxJest.getTimerCount() > 0 do
						actTestRenderer(function()
							RobloxJest.runAllTimers()
						end)
					end
				end

				-- Create a Roact root
				act(function()
					local root = ReactRoblox.createRoot(Instance.new("Frame"))
					return root:render(
						React.createElement("TextLabel", { Text = "Test" })
					)
				end)

				-- Deliver new root to the store
				local devtools = inspector.workers.reactTargetWatcher.devtools
				devtools.bridge:_flush()

				-- Check that the target has been added
				local _, target = next(inspector.targets)

				jestExpect(target.name).toBe("#1")

				-- Attach to the tree
				target.listener.onEvent("TEST")

				local worker = inspector.workers[target.id]

				-- Stub the message handler
				local spy = jest.fn()
				worker.send = spy
				worker:showChildren({})

				jestExpect(spy).toBeCalledWith(worker, {
					eventName = "RoactInspector.ShowChildren",
					path = {},
					children = {
						["1.2"] = {
							Children = {},
							Icon = "Branch",
							Name = "TextLabel",
							Path = { "1.2" },
						},
					},
				})

				worker:showBranch({ "1.2" })

				jestExpect(spy.mock.calls[2][2].eventName).toBe(
					"RoactInspector.ShowBranch"
				)
				jestExpect(spy.mock.calls[2][2].branch).toEqual({
					{
						Icon = "Branch",
						Name = "Root",
						Link = "",
						Source = "",
					},
					{
						Name = "TextLabel",
						Link = "",
						Source = "",
					} :: any, -- TODO Luau: Allow elements of an array to have different types.
				})
			end
		)
	end)
end
