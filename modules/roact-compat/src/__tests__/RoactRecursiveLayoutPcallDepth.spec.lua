return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local React
	local ReactRoblox
	local RoactCompat
	local Scheduler

	beforeEach(function()
		RobloxJest.resetModules()
		RoactCompat = require(script.Parent.Parent)
		ReactRoblox = require(Packages.ReactRoblox)
		Scheduler = require(Packages.Dev.Scheduler)
		React = require(Packages.React)
	end)

	describe("pcall depth", function()
		-- ROBLOX: we no longer warn, but this test is a good way to programmaitcally create a complex tree
		it("should render even when pcall depth limit is hit", function()
			local function LayoutEffect(props)
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Layout Effect")
				end)
				return RoactCompat.createElement("TextLabel", { Text = "Layout" })
			end

			local function constructDeepTree(n)
				local constructTreeTable = {
					[1] = function()
						return RoactCompat.createElement(LayoutEffect)
					end,
				}
				for i = 2, 500 do
					constructTreeTable[i] = function()
						return RoactCompat.createElement(constructTreeTable[i - 1])
					end
				end
				return constructTreeTable[n]
			end

			local DeepTree = RoactCompat.createElement(
				"Frame",
				nil,
				{ RoactCompat.createElement(constructDeepTree(500)) }
			)

			local instance = Instance.new("Folder")
			local root = ReactRoblox.createRoot(instance)
			jestExpect(function()
				root:render(DeepTree)
				Scheduler.unstable_flushAllWithoutAsserting()
			end).toWarnDev({})
			local children = instance:GetChildren()

			jestExpect(#children).toBe(1)
		end)
	end)
end
