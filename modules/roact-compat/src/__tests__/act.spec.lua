return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RoactCompat

	describe("production mode", function()
		local prevGlobal
		beforeEach(function()
			prevGlobal = _G.__ROACT_17_INLINE_ACT__
			_G.__ROACT_17_INLINE_ACT__ = nil
			RobloxJest.resetModules()
			RoactCompat = require(script.Parent.Parent)
		end)

		it("disallows use of 'act'", function()
			RobloxJest.resetModules()
			RoactCompat = require(script.Parent.Parent)

			jestExpect(function()
				RoactCompat.act(function()
					RoactCompat.mount(RoactCompat.createElement("TextLabel"))
				end)
			end).toThrow(
				"ReactRoblox.act is only available in testing environments, "
					.. "not production. Enable the `__ROACT_17_INLINE_ACT__` global in "
					.. "your test configuration in order to use `act`."
			)
		end)

		afterEach(function()
			_G.__ROACT_17_INLINE_ACT__ = prevGlobal
		end)
	end)

	describe("test mode", function()
		local prevGlobal
		beforeEach(function()
			prevGlobal = _G.__ROACT_17_INLINE_ACT__
			_G.__ROACT_17_INLINE_ACT__ = true
			RobloxJest.resetModules()
			RoactCompat = require(script.Parent.Parent)
		end)

		it("allows use of 'act'", function()
			RobloxJest.resetModules()
			RoactCompat = require(script.Parent.Parent)

			local parent = Instance.new("Folder")
			local tree
			jestExpect(function()
				RoactCompat.act(function()
					tree = RoactCompat.mount(
						RoactCompat.createElement("TextLabel"),
						parent
					)
				end)
			end).never.toThrow()

			jestExpect(parent:FindFirstChildWhichIsA("TextLabel")).toBeDefined()
			jestExpect(function()
				RoactCompat.act(function()
					RoactCompat.unmount(tree)
				end)
			end).never.toThrow()

			jestExpect(parent:FindFirstChildWhichIsA("TextLabel")).toBeNil()
		end)

		afterEach(function()
			_G.__ROACT_17_INLINE_ACT__ = prevGlobal
		end)
	end)
end
