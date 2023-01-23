--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local Roact
local RoactCompat

local UNSUPPORTED = {
	-- Container for features that are unstable in current Roact
	UNSTABLE = true,
	-- Very old aliases for the top-level Roact tree management API
	reify = true,
	reconcile = true,
	teardown = true,
}
beforeEach(function()
	jest.resetModules()
	Roact = require(Packages.Dev.Roact)
	RoactCompat = require(script.Parent.Parent)
end)

it("has all interface members that old Roact exposes", function()
	for k, v in Roact do
		if UNSUPPORTED[k] then
			-- Skip any API members that are well and truly unsupported
			continue
		end

		jestExpect(RoactCompat).toHaveProperty(k)
		local memberType = typeof(v)
		-- Exports common Roact symbol keys as the reserved key names used
		-- by RoactCompat ("ref" and "children", respectively)
		if k == "Ref" or k == "Children" then
			memberType = "string"
		end
		-- Roact.Portal is replaced by ReactRoblox.createPortal. The
		-- latter is a function that returns a portal object, while the
		-- former is a special component type. By implementing Roact.Portal
		-- as a function component that returns `createPortal`'s result, we
		-- can get similar behavior, but with `Roact.Portal` having a
		-- different type.
		if k == "Portal" then
			memberType = "function"
		end
		jestExpect(typeof(RoactCompat[k])).toBe(memberType)
	end
end)

describe("warns about deprecated Roact API features", function()
	it("warns about createFragment", function()
		jestExpect(function()
			RoactCompat.createFragment({ div = RoactCompat.createElement("div") })
		end).toWarnDev(
			"Warning: The legacy Roact API 'createFragment' is deprecated",
			{ withoutStack = true }
		)
	end)

	it("warns about Component:extend() with no args", function()
		jestExpect(function()
			RoactCompat.Component:extend()
		end).toWarnDev(
			"Component:extend() accepting no arguments is deprecated",
			{ withoutStack = true }
		)
	end)

	it("warns about oneChild", function()
		jestExpect(function()
			RoactCompat.oneChild({ RoactCompat.createElement("div") })
		end).toWarnDev(
			"Warning: The legacy Roact API 'oneChild' is deprecated",
			{ withoutStack = true }
		)
	end)

	it("warns about setGlobalConfig", function()
		jestExpect(function()
			RoactCompat.setGlobalConfig({ propValidation = true })
		end).toWarnDev(
			"Warning: The legacy Roact API 'setGlobalConfig' is deprecated",
			{ withoutStack = true }
		)
	end)

	it("warns about Roact.Portal", function()
		local ReactRoblox = require(Packages.ReactRoblox)
		local target = Instance.new("Folder")
		local function withPortal(_props)
			return RoactCompat.createElement(RoactCompat.Portal, {
				target = target,
			}, RoactCompat.createElement("Frame"))
		end
		jestExpect(function()
			local root = ReactRoblox.createLegacyRoot(Instance.new("ScreenGui"))
			root:render(RoactCompat.createElement(withPortal))
		end).toWarnDev("Warning: The legacy Roact API 'Roact.Portal' is deprecated")
	end)

	it("warns about mount", function()
		jestExpect(function()
			RoactCompat.mount(RoactCompat.createElement("TextLabel", { Text = "Foo" }))
		end).toWarnDev({
			"Warning: The legacy Roact API 'mount' is deprecated",
		}, { withoutStack = true })
	end)

	it("warns about mount with invalid instance", function()
		jestExpect(function()
			jestExpect(function()
				RoactCompat.mount(
					RoactCompat.createElement("TextLabel", { Text = "Foo" }),
					"I'm not an instance!"
				)
			end).toWarnDev({
				"Warning: The legacy Roact API 'mount' is deprecated",
			}, { withoutStack = true })
		end).toThrow(
			"Cannot mount element (`TextLabel`) into a parent that is not a Roblox Instance (got type `string`)",
			{ withoutStack = true }
		)

		jestExpect(function()
			jestExpect(function()
				RoactCompat.mount(
					RoactCompat.createElement("Frame"),
					{ bogusParent = true }
				)
			end).toWarnDev({
				"Warning: The legacy Roact API 'mount' is deprecated",
			}, { withoutStack = true })
		end).toThrow(
			"Cannot mount element (`Frame`) into a parent that is not a Roblox Instance (got type `table`) \n{ bogusParent",
			{ withoutStack = true }
		)
	end)

	it("warns about update", function()
		local tree
		jestExpect(function()
			tree = RoactCompat.mount(
				RoactCompat.createElement("TextLabel", { Text = "Foo" })
			)
		end).toWarnDev(
			"Warning: The legacy Roact API 'mount' is deprecated",
			{ withoutStack = true }
		)

		jestExpect(function()
			RoactCompat.update(
				tree,
				RoactCompat.createElement("TextLabel", { Text = "Bar" })
			)
		end).toWarnDev(
			"Warning: The legacy Roact API 'update' is deprecated",
			{ withoutStack = true }
		)
	end)

	it("warns about unmount", function()
		local tree
		jestExpect(function()
			tree = RoactCompat.mount(
				RoactCompat.createElement("TextLabel", { Text = "Foo" })
			)
		end).toWarnDev(
			"Warning: The legacy Roact API 'mount' is deprecated",
			{ withoutStack = true }
		)

		jestExpect(function()
			RoactCompat.unmount(tree)
		end).toWarnDev(
			"Warning: The legacy Roact API 'unmount' is deprecated",
			{ withoutStack = true }
		)
	end)
end)

describe("handles uninitialized state", function()
	it("errors if uninitialized state is assigned", function()
		local ReactRoblox = require(Packages.ReactRoblox)
		local Scheduler = require(Packages.Dev.Scheduler)
		local parent = Instance.new("Folder")
		local Component = RoactCompat.Component:extend("Component")

		function Component:render()
			self.state.foo = "bar"
		end

		local componentInstance = RoactCompat.createElement(Component)
		local root = ReactRoblox.createRoot(parent)

		jestExpect(function()
			root:render(componentInstance)
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toErrorDev(
			"Attempted to directly mutate state. Use setState to assign new values to state."
		)
	end)

	it("warns if uninitialized state is accessed", function()
		local ReactRoblox = require(Packages.ReactRoblox)
		local parent = Instance.new("Folder")
		local Scheduler = require(Packages.Dev.Scheduler)
		local Component = RoactCompat.Component:extend("Component")

		local capturedBool = false

		function Component:render()
			if self.state.foo == nil then
				capturedBool = true
			end
		end

		local componentInstance = RoactCompat.createElement(Component)
		local root = ReactRoblox.createRoot(parent)

		jestExpect(function()
			root:render(componentInstance)
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toWarnDev(
			"Attempted to access uninitialized state. Use setState to initialize state"
		)

		jestExpect(capturedBool).toBe(true)
	end)
end)

describe("ChildArray Keys", function()
	it("Shozuld assign keys to children in an array", function()
		local ReactRoblox = require(Packages.ReactRoblox)
		local parent = Instance.new("Folder")
		local Scheduler = require(Packages.Dev.Scheduler)
		local Component = RoactCompat.Component:extend("Component")

		function Component:render()
			return RoactCompat.createElement("Frame", {}, {
				RoactCompat.createElement("TextLabel", { Text = "one" }),
				RoactCompat.createElement("TextLabel", { Text = "two" }),
				RoactCompat.createElement("TextLabel", { Text = "three" }),
			})
		end

		local componentInstance = RoactCompat.createElement(Component)

		local root = ReactRoblox.createRoot(parent)

		-- We expect this to warn us about the implicit keys even though
		-- it's assigning them to maintain ordering
		jestExpect(function()
			root:render(componentInstance)
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toErrorDev(
			'Warning: Each child in a list should have a unique "key" prop.'
		)

		local firstChild = parent:FindFirstChild(1, true)
		jestExpect(firstChild).toBeDefined()
		jestExpect(firstChild.Text).toEqual("one")

		local secondChild = parent:FindFirstChild(2, true)
		jestExpect(secondChild).toBeDefined()
		jestExpect(secondChild.Text).toEqual("two")

		local thirdChild = parent:FindFirstChild(3, true)
		jestExpect(thirdChild).toBeDefined()
		jestExpect(thirdChild.Text).toEqual("three")
	end)
end)
