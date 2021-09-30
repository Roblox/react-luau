return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
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
		it("should warn when pcall depth limit is hit", function()
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

			local root = ReactRoblox.createRoot(Instance.new("Folder"))

			jestExpect(function()
				root:render(DeepTree)
				Scheduler.unstable_flushAllWithoutAsserting()
			end).toWarnDev(
				"Hit maximum pcall depth of 20, entering UNSAFE call mode. Suspense and Error "
					.. "Boundaries will no longer work correctly. This will be resolved in React 18."
			)
		end)
	end)
end
