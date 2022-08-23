-- upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-dom/src/__tests__/ReactIdentity-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

-- ROBLOX deviation: This test file was adapted from `react-dom` and ported to roblox-renderer
local React, Scheduler
local ReactRoblox, reactRobloxRoot

return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.useFakeTimers()
		React = require(Packages.React)
		ReactRoblox = require(Packages.Dev.ReactRoblox)
		Scheduler = require(Packages.Scheduler)
		local parent = Instance.new("Folder")
		reactRobloxRoot = ReactRoblox.createRoot(parent)
	end)

	-- ROBLOX deviation: This test can hit succeed erroneously in luau, since
	-- table iteration order is unpredictable; with only two elements and no
	-- guaranteed order, react might happen to assign the right values even if key
	-- behavior isn't working.
	-- it("should allow key property to express identity", function()
	--   local ref = React.createRef()
	--   local function Component(props)
	--     return React.createElement("Frame", {ref=ref},
	--       React.createElement("Frame", {key=props.swap and "banana" or "apple", prop="Hello"}),
	--       React.createElement("Frame", {key=props.swap and "apple" or "banana", prop="World"})
	--     )
	--   end

	--   local function childrenByProp(children)
	--     local byProp = {}
	--     for _, instance in children do
	--       byProp[instance.prop] = instance
	--     end
	--     return byProp
	--   end

	--   -- ROBLOX deviation: Use react-noop + act instead of rendering into document
	--   ReactNoop.act(function()
	--     ReactNoop.render(React.createElement(Component))
	--   end)
	--   local origChildren = childrenByProp(ref.current.children)
	--   ReactNoop.act(function()
	--     ReactNoop.render(React.createElement(Component, {swap=true}))
	--   end)
	--   local newChildren = childrenByProp(ref.current.children)

	--   -- After rendering with `swap=true`, the keys will have switched and the
	--   -- prop values will correspond to the opposite children
	--   jestExpect(origChildren["Hello"]).toBe(newChildren["World"])
	--   jestExpect(origChildren["World"]).toBe(newChildren["Hello"])
	-- end)

	-- ROBLOX deviation: Replaces the above test. This new test verifies the
	-- behavior expected above, but uses enough table keys to greatly reduce the
	-- likelihood of coincidental success.
	it("should allow key property to express identity", function()
		local ref = React.createRef()
		local function Component(props)
			local children = {}
			for i = 1, 50 do
				local key = props.invert and tostring(51 - i) or tostring(i)
				children[key] = React.createElement("TextLabel", { Text = i })
			end

			return React.createElement("Frame", { ref = ref }, unpack(children))
		end

		local function childrenByProp(children)
			local byProp = {}
			for _, instance in children do
				byProp[instance.Text] = instance
			end
			return byProp
		end

		reactRobloxRoot:render(React.createElement(Component))
		Scheduler.unstable_flushAllWithoutAsserting()

		local origChildren = childrenByProp(ref.current:GetChildren())

		reactRobloxRoot:render(React.createElement(Component, { invert = true }))
		Scheduler.unstable_flushAllWithoutAsserting()

		local newChildren = childrenByProp(ref.current:GetChildren())

		-- After rendering with `invert=true`, the keys will have switched and the
		-- prop values will correspond to the opposite children
		for i = 1, 50 do
			jestExpect(origChildren[i]).toBe(newChildren[51 - i])
			jestExpect(origChildren[51 - i]).toBe(newChildren[i])
		end
	end)

	-- ROBLOX deviation: Verify equivalent behavior with table keys, an adaptation
	-- to be compatible with currently-released Roact
	it("should allow table key to express identity", function()
		local ref = React.createRef()
		local function Component(props)
			local children = {}
			for i = 1, 50 do
				local key = props.invert and tostring(51 - i) or tostring(i)
				children[key] = React.createElement("TextLabel", { Text = i })
			end

			return React.createElement("Frame", { ref = ref }, children)
		end

		local function childrenByProp(children)
			local byProp = {}
			for _, instance in children do
				byProp[instance.Text] = instance
			end
			return byProp
		end

		reactRobloxRoot:render(React.createElement(Component))
		Scheduler.unstable_flushAllWithoutAsserting()

		local origChildren = childrenByProp(ref.current:GetChildren())

		reactRobloxRoot:render(React.createElement(Component, { invert = true }))
		Scheduler.unstable_flushAllWithoutAsserting()

		local newChildren = childrenByProp(ref.current:GetChildren())

		-- After rendering with `invert=true`, the keys will have switched and the
		-- prop values will correspond to the opposite children
		for i = 1, 50 do
			jestExpect(origChildren[i]).toBe(newChildren[51 - i])
			jestExpect(origChildren[51 - i]).toBe(newChildren[i])
		end
	end)

	-- ROBLOX deviation: Verify equivalent behavior with table keys, an adaptation
	-- to be compatible with currently-released Roact
	it("should use table key to express identity when updating children type", function()
		local ref = React.createRef()

		local function Component(props)
			local children = {}
			for i = 1, props.count do
				children[tostring(i)] = React.createElement("TextLabel", { Text = tostring(i) })
			end

			if props.count == 0 then
				children["Test"] = React.createElement("Frame")
			end

			return React.createElement("Frame", { ref = ref }, children)
		end

		reactRobloxRoot:render(React.createElement(Component, {
			count = 0
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(ref.current:FindFirstChild(tostring("Test"))).never.toBe(nil)

		reactRobloxRoot:render(React.createElement(Component, {
			count = 15,
			complexComponents = false,
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		for i = 1, 15 do
			jestExpect(ref.current:FindFirstChild(tostring(i))).never.toBe(nil)
		end
	end)

	it("should defer to provided key if both are present", function()
		local ref = React.createRef()
		local function Component(props)
			local children = {}
			for i = 1, 50 do
				local key = props.invert and tostring(51 - i) or tostring(i)
				-- provide both explicit key and table key, where table-key does not
				-- obey the `invert` prop and should not be the one that's used.
				children[tostring(i)] = React.createElement("TextLabel", { key = key, Text = i })
			end

			return React.createElement("Frame", { ref = ref }, children)
		end

		local function childrenByProp(children)
			local byProp = {}
			for _, instance in children do
				byProp[instance.Text] = instance
			end
			return byProp
		end

		jestExpect(function()
			reactRobloxRoot:render(React.createElement(Component))
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toErrorDev({
			-- We expect to see warnings caused by using both kinds of key
			'Please provide only one key definition. When both are present, the "key" prop will take precedence.'
		})

		local origChildren = childrenByProp(ref.current:GetChildren())

		reactRobloxRoot:render(React.createElement(Component, { invert = true }))
		Scheduler.unstable_flushAllWithoutAsserting()

		local newChildren = childrenByProp(ref.current:GetChildren())

		-- After rendering with `invert=true`, the keys will have switched and the
		-- prop values will correspond to the opposite children
		for i = 1, 50 do
			jestExpect(origChildren[i]).toBe(newChildren[51 - i])
			jestExpect(origChildren[51 - i]).toBe(newChildren[i])
		end
	end)

	it("should use composite identity", function()
		local Wrapper = React.Component:extend("Wrapper")
		function Wrapper:render()
			return React.createElement("Frame", nil, self.props.children)
		end

		local ref1 = React.createRef()
		local ref2 = React.createRef()

		reactRobloxRoot:render(
			React.createElement(Wrapper, { key = "wrap1" }, React.createElement("Frame", { ref = ref1 }))
		)
		Scheduler.unstable_flushAllWithoutAsserting()

		reactRobloxRoot:render(
			React.createElement(Wrapper, { key = "wrap2" }, React.createElement("Frame", { ref = ref2 }))
		)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(ref1.current).never.toBe(ref2.current)
	end)

	local function renderAComponentWithKeyIntoContainer(key, container)
		local ref = React.createRef()

		local Wrapper = React.Component:extend("Wrapper")
		function Wrapper:render()
			return React.createElement("Frame", nil, React.createElement("Frame", { ref = ref, key = key }))
		end

		reactRobloxRoot:render(React.createElement(Wrapper), container)
		Scheduler.unstable_flushAllWithoutAsserting()

		local span = ref.current
		jestExpect(span).never.toBe(nil)
	end

	it("should allow any character as a key, in a detached parent", function()
		local detachedContainer = React.createElement("Frame")
		renderAComponentWithKeyIntoContainer("<'WEIRD/&\\key'>", detachedContainer)
	end)

	it("should allow any character as a key, in an attached parent", function()
		-- This test exists to protect against implementation details that
		-- incorrectly query escaped IDs using DOM tools like getElementById.
		local attachedContainer = React.createElement("Frame")
		reactRobloxRoot:render(attachedContainer)
		Scheduler.unstable_flushAllWithoutAsserting()

		renderAComponentWithKeyIntoContainer("<'WEIRD/&\\key'>", attachedContainer)
	end)

	-- ROBLOX deviation: this test not relevant to Roblox or reconciler, since
	-- script execution doesn't work this way to begin with
	-- it('should not allow scripts in keys to execute', function()
	--   local h4x0rKey =
	--     '"><script>window[\'YOUVEBEENH4X0RED\']=true;</script><div id="'

	--   local attachedContainer = document.createElement('div')
	--   document.body.appendChild(attachedContainer)

	--   renderAComponentWithKeyIntoContainer(h4x0rKey, attachedContainer)

	--   document.body.removeChild(attachedContainer)

	--   -- If we get this far, make sure we haven't executed the code
	--   jestExpect(window.YOUVEBEENH4X0RED).toBe(undefined)
	-- end)

	it("should let restructured components retain their uniqueness", function()
		local instance0 = React.createElement("Frame")
		local instance1 = React.createElement("Frame")
		local instance2 = React.createElement("Frame")

		local TestComponent = React.Component:extend("TestComponent")
		function TestComponent:render()
			return React.createElement("Frame", nil, instance2, self.props.children[1], self.props.children[2])
		end

		local TestContainer = React.Component:extend("TestContainer")
		function TestContainer:render()
			return React.createElement(TestComponent, nil, instance0, instance1)
		end

		jestExpect(function()
			reactRobloxRoot:render(React.createElement(TestContainer))
			Scheduler.unstable_flushAllWithoutAsserting()
		end).never.toThrow()
	end)

	it("should let nested restructures retain their uniqueness", function()
		local instance0 = React.createElement("Frame")
		local instance1 = React.createElement("Frame")
		local instance2 = React.createElement("Frame")

		local TestComponent = React.Component:extend("TestComponent")
		function TestComponent:render()
			return React.createElement("Frame", nil, instance2, self.props.children[1], self.props.children[2])
		end

		local TestContainer = React.Component:extend("TestContainer")
		function TestContainer:render()
			return React.createElement("Frame", nil, React.createElement(TestComponent, nil, instance0, instance1))
		end

		jestExpect(function()
			reactRobloxRoot:render(React.createElement(TestContainer))
			Scheduler.unstable_flushAllWithoutAsserting()
		end).never.toThrow()
	end)

	-- ROBLOX deviaton: Roblox game engine doesn't support raw text nodes
	xit("should let text nodes retain their uniqueness", function()
		local TestComponent = React.Component:extend("TestComponent")
		function TestComponent:render()
			return React.createElement("Frame", nil, self.props.children, React.createElement("Frame"))
		end

		local TestContainer = React.Component:extend("TestContainer")
		function TestContainer:render()
			return React.createElement(TestComponent, nil, React.createElement("Frame"), nil, { "second" })
		end

		jestExpect(function()
			reactRobloxRoot:render(React.createElement(TestContainer))
			Scheduler.unstable_flushAllWithoutAsserting()
		end).never.toThrow()
	end)

	it("should retain key during updates in composite components", function()
		local ref = React.createRef()
		local swap

		local TestComponent = React.Component:extend("TestComponent")
		function TestComponent:render()
			return React.createElement("Frame", { ref = ref }, self.props.children)
		end

		local TestContainer = React.Component:extend("TestContainer")
		function TestContainer:init()
			self.state = { swapped = false }

			swap = function()
				self:setState({ swapped = true })
			end
		end

		function TestContainer:render()
			return React.createElement(
				TestComponent,
				nil,
				self.state.swapped and self.props.second or self.props.first,
				self.state.swapped and self.props.first or self.props.second
			)
		end

		local instance0 = React.createElement("TextLabel", { key = "A", Text = "Hello" })
		local instance1 = React.createElement("TextLabel", { key = "B", Text = "World" })

		local function childrenByProp(children)
			local byProp = {}
			for _, instance in children do
				byProp[instance.Text] = instance
			end
			return byProp
		end

		reactRobloxRoot:render(React.createElement(TestContainer, { first = instance0, second = instance1 }))
		Scheduler.unstable_flushAllWithoutAsserting()

		local originalChildren = childrenByProp(ref.current:GetChildren())
		swap()
		local newChildren = childrenByProp(ref.current:GetChildren())

		jestExpect(originalChildren["Hello"]).toBe(newChildren["Hello"])
		jestExpect(originalChildren["World"]).toBe(newChildren["World"])
	end)

	it("should not allow implicit and explicit keys to collide", function()
		local component = function(_props)
			return React.createElement(
				"Frame",
				nil,
				React.createElement("Frame"),
				React.createElement("Frame", { key = "1" })
			)
		end

		jestExpect(function()
			reactRobloxRoot:render(React.createElement(component))
			Scheduler.unstable_flushAllWithoutAsserting()
		end).never.toThrow()
	end)
end
