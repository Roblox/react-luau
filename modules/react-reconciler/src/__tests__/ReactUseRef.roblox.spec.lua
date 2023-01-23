local Packages = script.Parent.Parent.Parent
local React
local ReactRoblox
local Scheduler

--ROBLOX NOTE: Tests for the Bindings-based useRef approach
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local useRef

describe("useRef", function()
	beforeEach(function()
		jest.resetModules()

		React = require(Packages.React)
		ReactRoblox = require(Packages.Dev.ReactRoblox)
		Scheduler = require(Packages.Scheduler)
		useRef = React.useRef
	end)

	it("should assign initial value to the ref", function()
		local refNumber
		local refString
		local function component()
			refNumber = useRef(123)
			refString = useRef("HelloRef")
			return nil
		end

		local container = Instance.new("Folder")
		local root = ReactRoblox.createRoot(container)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		jestExpect(refNumber).toBeDefined()
		jestExpect(refNumber.current).toBe(123)
		jestExpect(refString).toBeDefined()
		jestExpect(refString.current).toBe("HelloRef")

		root:unmount()
	end)

	it("should allow current value to be updated", function()
		local refNumber
		local function component()
			refNumber = useRef(123)

			React.useEffect(function()
				refNumber.current = 456
			end, {})

			return nil
		end

		local container = Instance.new("Folder")
		local root = ReactRoblox.createRoot(container)

		root:render(React.createElement(component))

		-- ROBLOX Test Noise: jest setup config hides "act not enabled in
		-- prod" warnings (scripts/jest/setupTests.js:72)
		Scheduler.unstable_flushAll()

		jestExpect(refNumber).toBeDefined()
		jestExpect(refNumber.current).toBe(456)
	end)

	it("should remember current value between renders", function()
		local countRef
		local function component()
			countRef = useRef(0)
			countRef.current += 1
			return nil
		end

		local container = Instance.new("Folder")
		local root = ReactRoblox.createRoot(container)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		jestExpect(countRef).toBeDefined()
		local count1 = countRef.current
		jestExpect(count1).toBeGreaterThan(0)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		local count2 = countRef.current
		jestExpect(count2).toBeGreaterThan(count1)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		local count3 = countRef.current
		jestExpect(count3).toBeGreaterThan(count2)

		root:unmount()
	end)

	it("should bind to NextSelection props without error", function()
		local bottomRef
		local function component()
			bottomRef = useRef(nil)

			return React.createElement(React.Fragment, {}, {
				Top = React.createElement("Frame", {
					Size = UDim2.fromScale(1, 0.5),
					NextSelectionUp = bottomRef,
					NextSelectionDown = bottomRef,
					NextSelectionLeft = bottomRef,
					NextSelectionRight = bottomRef,
				}),
				Bottom = React.createElement("Frame", {
					Size = UDim2.fromScale(1, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					ref = bottomRef,
				}),
			})
		end

		local container = Instance.new("Folder")
		local root = ReactRoblox.createRoot(container)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		jestExpect(bottomRef).toBeDefined()
		jestExpect(bottomRef.current).toMatchInstance({
			Name = "Bottom",
		})

		root:unmount()
	end)

	it("should stringify refs correctly", function()
		local frameRef
		local function component()
			frameRef = useRef(nil)

			return React.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				ref = frameRef,
			})
		end

		local container = Instance.new("Folder")
		local root = ReactRoblox.createRoot(container)

		root:render(React.createElement(component))

		Scheduler.unstable_flushAll()

		jestExpect(frameRef).toBeDefined()
		jestExpect(tostring(frameRef)).toEqual("Ref(Frame)")

		root:unmount()
	end)
end)
