return function()
	local Packages = script.Parent.Parent.Parent.Parent

	local JestRoblox = require(Packages.Dev.JestRoblox)
	local jestExpect = JestRoblox.Globals.expect
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

	it("should update a value without re-rendering", function()
		local value, setValue = React.createBinding("hello")
		local renderCount = 0
		local function Component(props)
			renderCount += 1
			return React.createElement("TextLabel", {
				Name = "Label",
				Text = value,
			})
		end

		reactRobloxRoot:render(React.createElement(Component))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("hello")

		setValue("world")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("world")
	end)

	it("subscribe to updates when used as a ref", function()
		local leftButtonRef = React.createRef()
		local rightButtonRef = React.createRef()

		local function Component(props)
			return {
				React.createElement("TextButton", {
					ref = leftButtonRef,
					NextSelectionRight = rightButtonRef,
				}),
				React.createElement("TextButton", {
					ref = rightButtonRef,
					NextSelectionRight = leftButtonRef,
				}),
			}
		end

		reactRobloxRoot:render(React.createElement(Component))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(leftButtonRef.current).never.toBeNil()
		jestExpect(rightButtonRef.current).never.toBeNil()

		jestExpect(leftButtonRef.current.NextSelectionRight).toBe(rightButtonRef.current)
		jestExpect(rightButtonRef.current.NextSelectionRight).toBe(leftButtonRef.current)
	end)
end