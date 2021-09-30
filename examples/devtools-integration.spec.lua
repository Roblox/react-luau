--[[
	This test is currently run manually to verify the DeveloperTools library integrates into roact-alignment
	roblox-cli run --load.place examples.project.json --run bin/run-devtools-integration-test.lua --lua.globals __NO_LOADMODULE__=false __EXPERIMENTAL__=true __PROFILE__=true
]]

return function()
	describe("Devtools Integration", function()
		local Packages = game.ReplicatedStorage.Packages
		local Workspace = Packages._Workspace
		local ProjectWorkspace = game.StarterPlayer.StarterPlayerScripts.RoactExamples.ProjectWorkspace
		local inspector
		local jestModule = require(Packages._Index["roblox_jest-roblox"]["jest-roblox"])
		local RobloxJest = require(Workspace.RobloxJest.RobloxJest)
		local expect = jestModule.Globals.expect
		local jest = jestModule.Globals.jest
		local devtools

		local insert = table.insert
		
		beforeEach(function()
			local DeveloperTools = require(ProjectWorkspace.DeveloperTools)

			inspector = DeveloperTools.forLibrary("UniversalApp", {})
			devtools = inspector:initRoact(Workspace)
		end)

		it("can connect to a Roact tree and inspect its children and child branch nodes", function()
			local ReactDevtoolsShared = Workspace.ReactDevtoolsShared.ReactDevtoolsShared
			local utils = require(ReactDevtoolsShared.__tests__.utils)
			local act = utils.act

			local React = require(ProjectWorkspace.React)
			local ReactRoblox = require(ProjectWorkspace.ReactRoblox)

			-- Create a Roact root
			act(function()
				local root = ReactRoblox.createRoot(Instance.new("Frame"))
				return root:render(React.createElement("TextLabel", { Text = "Test" }))
			end)

			-- Deliver new root to the store
			local devtools = inspector.workers.reactTargetWatcher.devtools
			devtools.bridge:_flush()

			-- Check that the target has been added
			local _, target = next(inspector.targets)

			expect(target.name).toBe("#1")

			-- Attach to the tree
			target.listener.onEvent("TEST")
			
			local worker = inspector.workers[target.id]

			-- Stub the message handler
			local spy = jest:fn()
			worker.send = spy
			worker:showChildren({})
			
			expect(spy).toBeCalledWith(worker, {
				eventName = "RoactInspector.ShowChildren",
				path = {},
				children = {
					["1.2"] = {
						Children = {},
						Icon = "Branch",
						Name = "TextLabel",
						Path = {"1.2"},
					}
				}
			})

			worker:showBranch({"1.2"})

			expect(spy.mock.calls[2][2].eventName).toBe("RoactInspector.ShowBranch")
			expect(spy.mock.calls[2][2].branch).toEqual({
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
				}
			})
		end)
	end)
end
