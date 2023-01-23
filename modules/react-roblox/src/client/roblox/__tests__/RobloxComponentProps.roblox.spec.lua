local React
local ReactRoblox
local Scheduler
local RobloxComponentProps

local Packages = script.Parent.Parent.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it

beforeEach(function()
	jest.resetModules()
	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	Scheduler = require(Packages.Scheduler)
	RobloxComponentProps = require(script.Parent.Parent.RobloxComponentProps)
end)

local function getSizeOfMap(map)
	local count = 0
	for _ in map do
		count += 1
	end
	return count
end

it("should clear instanceToBindings map of unmounted instances", function()
	local value = React.createBinding("Hello world!")
	local function Component()
		return React.createElement("TextLabel", {
			key = "label",
			Text = value,
		})
	end

	local target = Instance.new("Folder")

	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(Component))
	Scheduler.unstable_flushAllWithoutAsserting()

	-- There should be one instance in the map
	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToBindings)).toBe(1)

	-- Validate that anything in the map is a mounted instance
	for hostInstance in RobloxComponentProps._instanceToBindings do
		jestExpect(hostInstance:IsDescendantOf(target)).toBe(true)
	end

	root:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToBindings)).toBe(0)
end)

it("should clear instanceToEventManager map of unmounted instances", function()
	local function Component()
		return React.createElement("TextButton", {
			key = "button",
			[ReactRoblox.Event.Activated] = function()
				-- do something
			end,
			[ReactRoblox.Change.Text] = function()
				-- do something
			end,
		})
	end

	local target = Instance.new("Folder")

	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement(Component))
	Scheduler.unstable_flushAllWithoutAsserting()

	-- There should be one instance in the map
	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToEventManager)).toBe(1)

	-- Validate that anything in the map is a mounted instance
	for hostInstance in RobloxComponentProps._instanceToEventManager do
		jestExpect(hostInstance:IsDescendantOf(target)).toBe(true)
	end

	root:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToEventManager)).toBe(0)
end)

it("should clear instanceToBindings map of unmounted descendents", function()
	local value = React.createBinding("Hello world!")
	local function Component()
		-- Outer component has no bindings or events, but will get cleaned
		-- up directly by `unmount`
		-- Outer component has no bindings or events, but will get cleaned
		-- up directly by `unmount`
		return React.createElement("Frame", {}, {
			Label = React.createElement("TextLabel", {
				Text = value,
			}),
			Button = React.createElement("TextButton", {
				Text = value:map(function(text)
					return text .. " (Button)"
				end),
			}),
		})
	end

	local target = Instance.new("Folder")

	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement("ScreenGui", nil, React.createElement(Component)))
	Scheduler.unstable_flushAllWithoutAsserting()

	-- There should be one instance in the map
	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToBindings)).toBe(2)

	-- Validate that anything in the map is a mounted instance
	for hostInstance in RobloxComponentProps._instanceToBindings do
		jestExpect(hostInstance:IsDescendantOf(target)).toBe(true)
	end

	root:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToBindings)).toBe(0)
end)

it("should clear instanceToEventManager map of unmounted descendents", function()
	local function Component()
		-- Outer component has no bindings or events, but will get cleaned
		-- up directly by `unmount`
		return React.createElement("Frame", {}, {
			Button = React.createElement("TextButton", {
				[ReactRoblox.Event.Activated] = function()
					-- do something
				end,
			}),
			Label = React.createElement("TextLabel", {
				[ReactRoblox.Change.Text] = function()
					-- do something
				end,
			}),
		})
	end

	local target = Instance.new("Folder")

	local root = ReactRoblox.createRoot(target)
	root:render(React.createElement("ScreenGui", nil, React.createElement(Component)))
	Scheduler.unstable_flushAllWithoutAsserting()

	-- There should be one instance in the map
	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToEventManager)).toBe(2)

	-- Validate that anything in the map is a mounted instance
	for hostInstance in RobloxComponentProps._instanceToEventManager do
		jestExpect(hostInstance:IsDescendantOf(target)).toBe(true)
	end

	root:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(getSizeOfMap(RobloxComponentProps._instanceToEventManager)).toBe(0)
end)
