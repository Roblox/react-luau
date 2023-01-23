--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-dom/src/__tests__/ReactUpdates-test.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
local Error = LuauPolyfill.Error
local React
local ReactTestRenderer
-- local ReactDOM
-- local ReactDOMServer
local Scheduler
-- local PropTypes
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it

-- ROBLOX note: in upstream, this file is in react-dom, but we're submitting a PR that moves it to a generic place
-- ROBLOX TODO: split non-DOM test into separate file, make upstream PR for this division

local jestExpect = JestGlobals.expect

-- ROBLOX Test Noise: in upstream, jest setup config makes these tests hide
-- the error boundary warnings they trigger (scripts/jest/setupTests.js:72)
describe("ReactUpdates", function()
	beforeEach(function()
		jest.resetModules()

		-- ROBLOX deviation: workaround because our flag is currently always set to false
		local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = true
		React = require(script.Parent.Parent)

		-- ROBLOX deviation: using React Test Renderer in place of ReactDOM
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)

		-- ReactDOM = require('react-dom')
		-- ReactDOMServer = require('react-dom/server')
		Scheduler = require(Packages.Dev.Scheduler)
	end)

	it("should batch state when updating state twice", function()
		local instance
		local updateCount = 0
		local Component = React.Component:extend("Component")
		function Component:init()
			self.state = { x = 0 }
		end
		function Component:componentDidUpdate()
			(function()
				local result = updateCount
				updateCount += 1
				return result
			end)()
		end
		function Component:render()
			instance = self
			return React.createElement("div", nil, self.state.x)
		end

		ReactTestRenderer.create(React.createElement(Component))
		jestExpect(instance.state.x).toBe(0)
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 })
			instance:setState({ x = 2 })
			jestExpect(instance.state.x).toBe(0)
			jestExpect(updateCount).toBe(0)
		end)
		jestExpect(instance.state.x).toBe(2)
		jestExpect(updateCount).toBe(1)
	end)

	it("should batch state when updating two different state keys", function()
		local instance
		local updateCount = 0
		local Component = React.Component:extend("Component")
		function Component:init()
			self.state = { x = 0, y = 0 }
		end
		function Component:componentDidUpdate()
			(function()
				local result = updateCount
				updateCount += 1
				return result
			end)()
		end
		function Component:render()
			instance = self
			return React.createElement(
				"div",
				nil,
				string.format("(%s, %s)", self.state.x, self.state.y)
			)
		end
		ReactTestRenderer.create(React.createElement(Component))
		jestExpect(instance.state.x).toBe(0)
		jestExpect(instance.state.y).toBe(0)
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 })
			instance:setState({ y = 2 })
			jestExpect(instance.state.x).toBe(0)
			jestExpect(instance.state.y).toBe(0)
			jestExpect(updateCount).toBe(0)
		end)
		jestExpect(instance.state.x).toBe(1)
		jestExpect(instance.state.y).toBe(2)
		jestExpect(updateCount).toBe(1)
	end)

	it("should batch state and props together", function()
		local instance
		local updateCount = 0
		local Component = React.Component:extend("Component")
		function Component:init()
			instance = self
			self.state = { y = 0 }
		end
		function Component:componentDidUpdate()
			(function()
				local result = updateCount
				updateCount += 1
				return result
			end)()
		end
		function Component:render()
			return React.createElement(
				"div",
				nil,
				string.format("(%s, %s)", tostring(self.props.x), tostring(self.state.y))
			)
		end
		local root = ReactTestRenderer.create(React.createElement(Component, { x = 0 }))
		jestExpect(instance.props.x).toBe(0)
		jestExpect(instance.state.y).toBe(0)
		ReactTestRenderer.unstable_batchedUpdates(function()
			root.update(React.createElement(Component, { x = 1 }))
			instance:setState({ y = 2 })
			jestExpect(instance.props.x).toBe(0)
			jestExpect(instance.state.y).toBe(0)
			jestExpect(updateCount).toBe(0)
		end)
		jestExpect(instance.props.x).toBe(1)
		jestExpect(instance.state.y).toBe(2)
		jestExpect(updateCount).toBe(1)
	end)

	it("should batch parent/child state updates together", function()
		local instance
		local Child = React.Component:extend("Child")
		local parentUpdateCount = 0
		local Parent = React.Component:extend("Parent")
		function Parent:init()
			instance = self
			self.state = { x = 0 }
		end
		function Parent:componentDidUpdate()
			(function()
				local result = parentUpdateCount
				parentUpdateCount += 1
				return result
			end)()
		end
		local childRef = React.createRef()
		function Parent:render()
			return React.createElement(
				"div",
				nil,
				React.createElement(Child, { ref = childRef, x = self.state.x })
			)
		end
		local childUpdateCount = 0
		function Child:init()
			self.state = { y = 0 }
		end
		function Child:componentDidUpdate()
			(function()
				local result = childUpdateCount
				childUpdateCount += 1
				return result
			end)()
		end
		function Child:render()
			return React.createElement(
				"div",
				nil,
				tostring(self.props.x) .. tostring(self.state.y)
			)
		end
		ReactTestRenderer.create(React.createElement(Parent))
		local child = childRef.current
		jestExpect(instance.state.x).toBe(0)
		jestExpect(child.state.y).toBe(0)
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 })
			child:setState({ y = 2 })
			jestExpect(instance.state.x).toBe(0)
			jestExpect(child.state.y).toBe(0)
			jestExpect(parentUpdateCount).toBe(0)
			jestExpect(childUpdateCount).toBe(0)
		end)
		jestExpect(instance.state.x).toBe(1)
		jestExpect(child.state.y).toBe(2)
		jestExpect(parentUpdateCount).toBe(1)
		jestExpect(childUpdateCount).toBe(1)
	end)
	it("should batch child/parent state updates together", function()
		local Child = React.Component:extend("Child")
		local instance
		local parentUpdateCount = 0
		local Parent = React.Component:extend("Parent")
		function Parent:init()
			instance = self
			self.state = { x = 0 }
		end
		function Parent:componentDidUpdate()
			(function()
				local result = parentUpdateCount
				parentUpdateCount += 1
				return result
			end)()
		end
		local childRef = React.createRef()
		function Parent:render()
			return React.createElement(
				"div",
				nil,
				React.createElement(Child, { ref = childRef, x = self.state.x })
			)
		end
		local childUpdateCount = 0
		function Child:init()
			self.state = { y = 0 }
		end
		function Child:componentDidUpdate()
			(function()
				local result = childUpdateCount
				childUpdateCount += 1
				return result
			end)()
		end
		function Child:render()
			return React.createElement(
				"div",
				nil,
				tostring(self.props.x) .. tostring(self.state.y)
			)
		end
		ReactTestRenderer.create(React.createElement(Parent))
		local child = childRef.current
		jestExpect(instance.state.x).toBe(0)
		jestExpect(child.state.y).toBe(0)
		ReactTestRenderer.unstable_batchedUpdates(function()
			child:setState({ y = 2 })
			instance:setState({ x = 1 })
			jestExpect(instance.state.x).toBe(0)
			jestExpect(child.state.y).toBe(0)
			jestExpect(parentUpdateCount).toBe(0)
			jestExpect(childUpdateCount).toBe(0)
		end)
		jestExpect(instance.state.x).toBe(1)
		jestExpect(child.state.y).toBe(2)
		jestExpect(parentUpdateCount).toBe(1)

		-- Batching reduces the number of updates here to 1.
		jestExpect(childUpdateCount).toBe(1)
	end)

	it("should support chained state updates", function()
		local instance
		local updateCount = 0
		local Component = React.Component:extend("Component")
		function Component:init()
			instance = self
			self.state = { x = 0 }
		end
		function Component:componentDidUpdate()
			(function()
				local result = updateCount
				updateCount += 1
				return result
			end)()
		end
		function Component:render()
			return React.createElement("div", nil, self.state.x)
		end
		ReactTestRenderer.create(React.createElement(Component))
		jestExpect(instance.state.x).toBe(0)
		local innerCallbackRun = false
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 }, function()
				instance:setState({ x = 2 }, function(self)
					jestExpect(self).toBe(instance)
					innerCallbackRun = true
					jestExpect(instance.state.x).toBe(2)
					jestExpect(updateCount).toBe(2)
				end)
				jestExpect(instance.state.x).toBe(1)
				jestExpect(updateCount).toBe(1)
			end)
			jestExpect(instance.state.x).toBe(0)
			jestExpect(updateCount).toBe(0)
		end)
		jestExpect(innerCallbackRun).toBeTruthy()
		jestExpect(instance.state.x).toBe(2)
		jestExpect(updateCount).toBe(2)
	end)
	it("should batch forceUpdate together", function()
		local instance
		local shouldUpdateCount = 0
		local updateCount = 0
		local Component = React.Component:extend("Component")
		function Component:init()
			instance = self
			self.state = { x = 0 }
		end
		function Component:shouldComponentUpdate()
			(function()
				local result = shouldUpdateCount
				shouldUpdateCount += 1
				return result
			end)()
			return false
		end
		function Component:componentDidUpdate()
			(function()
				local result = updateCount
				updateCount += 1
				return result
			end)()
		end
		function Component:render()
			return React.createElement("div", nil, self.state.x)
		end
		ReactTestRenderer.create(React.createElement(Component))
		jestExpect(instance.state.x).toBe(0)
		local callbacksRun = 0
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 }, function()
				(function()
					local result = callbacksRun
					callbacksRun += 1
					return result
				end)()
			end)
			instance:forceUpdate(function()
				(function()
					local result = callbacksRun
					callbacksRun += 1
					return result
				end)()
			end)
			jestExpect(instance.state.x).toBe(0)
			jestExpect(updateCount).toBe(0)
		end)

		jestExpect(callbacksRun).toBe(2)
		-- shouldComponentUpdate shouldn't be called since we're forcing
		jestExpect(shouldUpdateCount).toBe(0)
		jestExpect(instance.state.x).toBe(1)
		jestExpect(updateCount).toBe(1)
	end)

	it("should update children even if parent blocks updates", function()
		local instance
		local Child = React.Component:extend("Child")
		local parentRenderCount = 0
		local childRenderCount = 0
		local Parent = React.Component:extend("Parent")
		function Parent:init()
			instance = self
		end
		function Parent:shouldComponentUpdate()
			return false
		end
		local childRef = React.createRef()
		function Parent:render()
			(function()
				local result = parentRenderCount
				parentRenderCount += 1
				return result
			end)()
			return React.createElement(Child, { ref = childRef })
		end
		function Child:render()
			(function()
				local result = childRenderCount
				childRenderCount += 1
				return result
			end)()
			return React.createElement("div")
		end
		jestExpect(parentRenderCount).toBe(0)
		jestExpect(childRenderCount).toBe(0)
		local ParentElement = React.createElement(Parent)
		ReactTestRenderer.create(ParentElement)
		jestExpect(parentRenderCount).toBe(1)
		jestExpect(childRenderCount).toBe(1)
		ReactTestRenderer.unstable_batchedUpdates(function()
			instance:setState({ x = 1 })
		end)
		jestExpect(parentRenderCount).toBe(1)
		jestExpect(childRenderCount).toBe(1)
		ReactTestRenderer.unstable_batchedUpdates(function()
			childRef.current:setState({ x = 1 })
		end)
		jestExpect(parentRenderCount).toBe(1)
		jestExpect(childRenderCount).toBe(2)
	end)
	it("should not reconcile children passed via props", function()
		local Bottom = React.Component:extend("Bottom")
		local Middle = React.Component:extend("Middle")
		local numMiddleRenders = 0
		local numBottomRenders = 0
		local Top = React.Component:extend("Top")
		function Top:render()
			return React.createElement(Middle, nil, React.createElement(Bottom))
		end
		function Middle:componentDidMount()
			self:forceUpdate()
		end
		function Middle:render()
			(function()
				local result = numMiddleRenders
				numMiddleRenders += 1
				return result
			end)()
			return React.Children.only(self.props.children)
		end
		function Bottom:render()
			(function()
				local result = numBottomRenders
				numBottomRenders += 1
				return result
			end)()
			return nil
		end
		ReactTestRenderer.create(React.createElement(Top))
		jestExpect(numMiddleRenders).toBe(2)
		jestExpect(numBottomRenders).toBe(1)
	end)

	-- ROBLOX FIXME: need to figure out how to make these work with test renderers
	it.skip("should flow updates correctly", function()
		-- 	local willUpdates = {}
		-- 	local didUpdates = {}
		-- 	local UpdateLoggingMixin = {
		-- 		UNSAFE_componentWillUpdate = function(self)
		-- 			willUpdates:push(self.constructor.displayName)
		-- 		end,
		-- 		componentDidUpdate = function(self)
		-- 			didUpdates:push(self.constructor.displayName)
		-- 		end,
		-- 	}
		-- 	local Box = React.Component:extend("")
		-- 	Box.__index = Box
		-- 	function Box:render()
		-- 		return React.createElement("div", { ref = "boxDiv" }, self.props.children)
		-- 	end
		-- 	Object:assign(Box.prototype, UpdateLoggingMixin)
		-- 	local Child = React.Component:extend("")
		-- 	Child.__index = Child
		-- 	function Child:render()
		-- 		return React.createElement("span", { ref = "span" }, "child")
		-- 	end
		-- 	Object:assign(Child.prototype, UpdateLoggingMixin)
		-- 	local Switcher = React.Component:extend("")
		-- 	Switcher.__index = Switcher
		-- 	function Switcher:render()
		-- 		local child = self.props.children
		-- 		return React.createElement(
		-- 			Box,
		-- 			{ ref = "box" },
		-- 			React.createElement(
		-- 				"div",
		-- 				{
		-- 					ref = "switcherDiv",
		-- 					style = { display = self.state.tabKey == child.key and "" or "none" },
		-- 				},
		-- 				child
		-- 			)
		-- 		)
		-- 	end
		-- 	Object:assign(Switcher.prototype, UpdateLoggingMixin)
		-- 	local App = React.Component:extend("")
		-- 	App.__index = App
		-- 	function App:render()
		-- 		return React.createElement(
		-- 			Switcher,
		-- 			{ ref = "switcher" },
		-- 			React.createElement(Child, { key = "hello", ref = "child" })
		-- 		)
		-- 	end
		-- 	Object:assign(App.prototype, UpdateLoggingMixin)
		-- 	local root = React.createElement(App)
		-- 	root = ReactTestUtils:renderIntoDocument(root)
		-- 	local function expectUpdates(desiredWillUpdates, desiredDidUpdates)
		-- 		local i
		-- 		error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
		-- 		--[[ for (i = 0; i < desiredWillUpdates; i++) {
		--     jestExpect(willUpdates).toContain(desiredWillUpdates[i]);
		--   } ]]
		-- 		error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
		-- 		--[[ for (i = 0; i < desiredDidUpdates; i++) {
		--     jestExpect(didUpdates).toContain(desiredDidUpdates[i]);
		--   } ]]
		-- 		willUpdates = {}
		-- 		didUpdates = {}
		-- 	end
		-- 	local function triggerUpdate(c)
		-- 		c:setState({ x = 1 })
		-- 	end
		-- 	local function testUpdates(components, desiredWillUpdates, desiredDidUpdates)
		-- 		local i
		-- 		ReactTestRenderer.unstable_batchedUpdates(function()
		-- 			error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
		-- 			--[[ for (i = 0; i < components.length; i++) {
		--       triggerUpdate(components[i]);
		--     } ]]
		-- 		end)
		-- 		expectUpdates(desiredWillUpdates, desiredDidUpdates)
		-- 		-- Try them in reverse order
		--      ReactTestRenderer.unstable_batchedUpdates(function()
		-- 			error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
		-- 			--[[ for (i = components.length - 1; i >= 0; i--) {
		--       triggerUpdate(components[i]);
		--     } ]]
		-- 		end)
		-- 		expectUpdates(desiredWillUpdates, desiredDidUpdates)
		-- 	end
		-- 	testUpdates(
		-- 		{ root.refs.switcher.refs.box, root.refs.switcher },
		--      -- Owner-child relationships have inverse will and did
		-- 		{ "Switcher", "Box" },
		-- 		{ "Box", "Switcher" }
		-- 	)
		-- 	testUpdates(
		-- 		{ root.refs.child, root.refs.switcher.refs.box },
		--      -- Not owner-child so reconcile independently
		-- 		{ "Box", "Child" },
		-- 		{ "Box", "Child" }
		-- 	)
		-- 	testUpdates(
		-- 		{ root.refs.child, root.refs.switcher },
		--      -- Switcher owns Box and Child, Box does not own Child
		-- 		{ "Switcher", "Box", "Child" },
		-- 		{ "Box", "Switcher", "Child" }
		-- 	)
	end)

	it.skip("should queue mount-ready handlers across different roots", function()
		-- We'll define two components A and B, then update both of them. When A's
		-- componentDidUpdate handlers is called, B's DOM should already have been
		-- updated.
		-- local bContainer = document:createElement("div")
		-- local b
		-- local aUpdated = false
		-- local A = React.Component:extend("")
		-- A.__index = A
		-- function A:componentDidUpdate()
		-- 	jestExpect(ReactTestRenderer.findDOMNode(b).textContent).toBe("B1")
		-- 	aUpdated = true
		-- end
		-- function A:render()
		-- 	local portal = nil
		-- 	portal = ReactTestRenderer.createPortal(
		-- 		React.createElement(B, {
		-- 			ref = function(n)
		-- 				b = n
		-- 				return b
		-- 			end,
		-- 		}),
		-- 		bContainer
		-- 	)
		-- 	return React.createElement("div", nil, "A", self.state.x, portal)
		-- end
		-- local B = React.Component:extend("")
		-- B.__index = B
		-- function B:render()
		-- 	return React.createElement("div", nil, "B", self.state.x)
		-- end
		-- local a = ReactTestUtils:renderIntoDocument(React.createElement(A))
		-- ReactTestRenderer.unstable_batchedUpdates(function()
		-- 	a:setState({ x = 1 })
		-- 	b:setState({ x = 1 })
		-- end)
		-- jestExpect(aUpdated).toBe(true)
	end)
	it("should flush updates in the correct order", function()
		local instance
		local Inner = React.Component:extend("Inner")
		local updates = {}
		local Outer = React.Component:extend("Outer")
		function Outer:init()
			instance = self
			self.state = { x = 0 }
		end
		local innerRef = React.createRef()
		function Outer:render()
			table.insert(updates, "Outer-render-" .. tostring(self.state.x))
			return React.createElement(
				"div",
				nil,
				React.createElement(Inner, { x = self.state.x, ref = innerRef })
			)
		end
		function Outer:componentDidUpdate()
			local x = self.state.x
			table.insert(updates, "Outer-didUpdate-" .. tostring(x))
			table.insert(updates, "Inner-setState-" .. tostring(x))
			innerRef.current:setState({ x = x }, function()
				table.insert(updates, "Inner-callback-" .. tostring(x))
			end)
		end
		function Inner:init()
			self.state = { x = 0 }
		end
		function Inner:render()
			table.insert(
				updates,
				"Inner-render-" .. tostring(self.props.x) .. "-" .. tostring(self.state.x)
			)
			return React.createElement("div")
		end
		function Inner:componentDidUpdate()
			table.insert(
				updates,
				"Inner-didUpdate-"
					.. tostring(self.props.x)
					.. "-"
					.. tostring(self.state.x)
			)
		end
		ReactTestRenderer.create(React.createElement(Outer))
		table.insert(updates, "Outer-setState-1")
		instance:setState({ x = 1 }, function()
			table.insert(updates, "Outer-callback-1")
			table.insert(updates, "Outer-setState-2")
			instance:setState({ x = 2 }, function()
				table.insert(updates, "Outer-callback-2")
			end)
		end)
		jestExpect(updates).toEqual({
			"Outer-render-0",
			"Inner-render-0-0",

			"Outer-setState-1",
			"Outer-render-1",
			"Inner-render-1-0",
			"Inner-didUpdate-1-0",
			"Outer-didUpdate-1",
			-- Happens in a batch, so don't re-render yet
			"Inner-setState-1",
			"Outer-callback-1",

			-- Happens in a batch
			"Outer-setState-2",

			-- Flush batched updates all at once
			"Outer-render-2",
			"Inner-render-2-1",
			"Inner-didUpdate-2-1",
			"Inner-callback-1",
			"Outer-didUpdate-2",
			"Inner-setState-2",
			"Outer-callback-2",
			"Inner-render-2-2",
			"Inner-didUpdate-2-2",
			"Inner-callback-2",
		})
	end)
	it("should flush updates in the correct order across roots", function()
		local instances = {}
		local updates = {}
		local MockComponent = React.Component:extend("MockComponent")
		function MockComponent:render()
			table.insert(updates, self.props.depth)
			return React.createElement("div")
		end
		function MockComponent:componentDidMount()
			table.insert(instances, self)
			if
				self.props.depth
				< self.props.count --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
			then
				ReactTestRenderer.create(
					React.createElement(
						MockComponent,
						{ depth = self.props.depth + 1, count = self.props.count }
					)
				)
			end
		end
		ReactTestRenderer.create(
			React.createElement(MockComponent, { depth = 0, count = 2 })
		)
		jestExpect(updates).toEqual({ 0, 1, 2 })
		ReactTestRenderer.unstable_batchedUpdates(function()
			-- Simulate update on each component from top to bottom.
			Array.forEach(instances, function(instance)
				instance:forceUpdate()
			end)
		end)
		jestExpect(updates).toEqual({ 0, 1, 2, 0, 1, 2 })
	end)

	it("should queue nested updates", function()
		-- See https://github.com/facebook/react/issues/1147
		local x
		local y
		local Y = React.Component:extend("Y")
		local Z = React.Component:extend("Z")
		local X = React.Component:extend("X")
		function X:init()
			x = self
			self.state = { s = 0 }
		end
		function X:render()
			if self.state.s == 0 then
				return React.createElement(
					"div",
					nil,
					React.createElement("span", nil, "0")
				)
			else
				return React.createElement("div", nil, "1")
			end
		end
		function X:go()
			self:setState({ s = 1 })
			self:setState({ s = 0 })
			self:setState({ s = 1 })
		end

		function Y:render()
			y = self
			return React.createElement("div", nil, React.createElement(Z))
		end
		function Z:render()
			return React.createElement("div")
		end
		function Z:UNSAFE_componentWillUpdate()
			x:go()
		end
		local root = ReactTestRenderer.create(React.createElement(X))
		ReactTestRenderer.create(React.createElement(Y))
		-- ROBLOX TODO: need a toMatchRenderedOutput to work with the test *and* noop renderers
		jestExpect(root.toJSON().children[1].children[1]).toBe("0")
		y:forceUpdate()
		jestExpect(root.toJSON().children[1]).toBe("1")
	end)
	it("should queue updates from during mount", function()
		-- See https://github.com/facebook/react/issues/1353

		local a
		local A = React.Component:extend("")
		function A:init()
			self.state = { x = 0 }
		end
		function A:UNSAFE_componentWillMount()
			a = self
		end
		function A:render()
			return React.createElement("div", nil, "A" .. tostring(self.state.x))
		end
		local B = React.Component:extend("")
		function B:UNSAFE_componentWillMount()
			a:setState({ x = 1 })
		end
		function B:render()
			return React.createElement("div")
		end
		local root
		ReactTestRenderer.unstable_batchedUpdates(function()
			root = ReactTestRenderer.create(
				React.createElement(
					"div",
					nil,
					React.createElement(A),
					React.createElement(B)
				)
			)
		end)
		jestExpect(a.state.x).toBe(1)
		-- ROBLOX TODO: need a toMatchRenderedOutput to work with the test *and* noop renderers
		jestExpect(root.toJSON().children[1].children[1]).toBe("A1")
	end)
	-- ROBLOX FIXME: cWRP never gets called
	it.skip("calls componentWillReceiveProps setState callback properly", function()
		local callbackCount = 0
		local A = React.Component:extend("")
		function A:init()
			self.state = { x = self.props.x }
		end
		function A:UNSAFE_componentWillReceiveProps(nextProps)
			local newX = nextProps.x
			self:setState({ x = newX }, function()
				-- State should have updated by the time this callback gets called
				jestExpect(self.state.x).toBe(newX);
				(function()
					local result = callbackCount
					callbackCount += 1
					return result
				end)()
			end)
		end
		function A:render()
			return React.createElement("div", nil, self.state.x)
		end
		ReactTestRenderer.create(React.createElement(A, { x = 1 }))
		ReactTestRenderer.create(React.createElement(A, { x = 2 }))
		jestExpect(callbackCount).toBe(1)
	end)
	it("does not call render after a component as been deleted", function()
		local renderCount = 0
		local componentB = nil
		local componentA = nil
		local B = React.Component:extend("")
		function B:init()
			self.state = { updates = 0 }
		end
		function B:componentDidMount()
			componentB = self
		end
		function B:render()
			(function()
				local result = renderCount
				renderCount += 1
				return result
			end)()
			return React.createElement("div")
		end
		local A = React.Component:extend("")
		function A:init()
			componentA = self
			self.state = { showB = true }
		end
		function A:render()
			return (function()
				if Boolean.toJSBoolean(self.state.showB) then
					return React.createElement(B)
				else
					return React.createElement("div")
				end
			end)()
		end
		ReactTestRenderer.create(React.createElement(A))
		ReactTestRenderer.unstable_batchedUpdates(function()
			-- B will have scheduled an update but the batching should ensure that its
			-- update never fires.
			componentB:setState({ updates = 1 })
			componentA:setState({ showB = false })
		end)
		jestExpect(renderCount).toBe(1)
	end)

	it("throws in setState if the update callback is not a function", function()
		-- ROBLOX deviation: this captures the instance since we aren't using the DOM test helper
		local component

		local A = React.Component:extend("A")
		function A:init()
			self.state = {}
		end

		function A:render()
			component = self
			return React.createElement("div")
		end

		-- ROBLOX deviation: use ReactNoop.render to render instead of ReactDOM.render
		ReactTestRenderer.create(React.createElement(A))

		jestExpect(function()
			jestExpect(function()
				component:setState({}, "no" :: any)
			end).toErrorDev(
				"setState(...): Expected the last optional `callback` argument to be "
					.. "a function. Instead received: no.",
				{ withoutStack = true }
			)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: no"
		)
		ReactTestRenderer.create(React.createElement(A))

		local invalidCallback = { foo = "bar" }

		jestExpect(function()
			jestExpect(function()
				component:setState({}, invalidCallback :: any)
			end).toErrorDev(
				"setState(...): Expected the last optional `callback` argument to be "
					.. "a function. Instead received: table."
			)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: table"
		)

		-- Make sure the warning is deduplicated and doesn't fire again
		ReactTestRenderer.create(React.createElement(A))
		jestExpect(function()
			component:setState({}, invalidCallback :: any)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: table"
		)
	end)

	it("throws in forceUpdate if the update callback is not a function", function()
		-- ROBLOX deviation: this captures the instance since we aren't using the DOM test helper
		local component

		local A = React.Component:extend("A")
		function A:init()
			self.state = {}
		end

		function A:render()
			component = self
			return React.createElement("div")
		end

		-- ROBLOX deviation: use ReactNoop.render to render instead of ReactDOM.render
		ReactTestRenderer.create(React.createElement(A))

		jestExpect(function()
			jestExpect(function()
				component:forceUpdate("no" :: any)
			end).toErrorDev(
				"forceUpdate(...): Expected the last optional `callback` argument to be "
					.. "a function. Instead received: no.",
				{ withoutStack = true }
			)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: no"
		)
		ReactTestRenderer.create(React.createElement(A))

		local invalidCallback = { foo = "bar" }

		jestExpect(function()
			jestExpect(function()
				component:forceUpdate(invalidCallback :: any)
			end).toErrorDev(
				"forceUpdate(...): Expected the last optional `callback` argument to be "
					.. "a function. Instead received: table."
			)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: table"
		)

		-- Make sure the warning is deduplicated and doesn't fire again
		ReactTestRenderer.create(React.createElement(A))
		jestExpect(function()
			component:forceUpdate(invalidCallback :: any)
		end).toThrowError(
			"Invalid argument passed as callback. Expected a function. Instead "
				.. "received: table"
		)
	end)

	it("does not update one component twice in a batch (#2410)", function()
		local parent
		local Child = React.Component:extend("Child")
		local childRef = React.createRef()
		local Parent = React.Component:extend("Parent")
		function Parent:getChild()
			return childRef.current
		end
		function Parent:render()
			parent = self
			return React.createElement(Child, { ref = childRef })
		end
		local renderCount = 0
		local postRenderCount = 0
		local once = false
		function Child:init()
			self.state = { updated = false }
		end
		function Child:UNSAFE_componentWillUpdate()
			if not Boolean.toJSBoolean(once) then
				once = true
				self:setState({ updated = true })
			end
		end
		function Child:componentDidMount()
			jestExpect(renderCount).toBe(postRenderCount + 1);
			(function()
				local result = postRenderCount
				postRenderCount += 1
				return result
			end)()
		end
		function Child:componentDidUpdate()
			jestExpect(renderCount).toBe(postRenderCount + 1);
			(function()
				local result = postRenderCount
				postRenderCount += 1
				return result
			end)()
		end
		function Child:render()
			jestExpect(renderCount).toBe(postRenderCount);
			(function()
				local result = renderCount
				renderCount += 1
				return result
			end)()
			return React.createElement("div")
		end
		ReactTestRenderer.create(React.createElement(Parent))
		local child = parent:getChild()
		ReactTestRenderer.unstable_batchedUpdates(function()
			parent:forceUpdate()
			child:forceUpdate()
		end)
	end)

	-- it("does not update one component twice in a batch (#6371)", function()
	--     local callbacks = {}
	--     local function emitChange()
	--         callbacks:forEach(function(c)
	--             return c()
	--         end)
	--     end
	--     local App = React.Component:extend("")
	--     App.__index = App
	--     function App.new(props)
	--         local self = setmetatable({}, App) --[[ ROBLOX TODO: super constructor may be used ]](
	--             error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: Super ]]
	--             --[[ super ]]
	--         )(props)
	--         self.state = { showChild = true }
	--         return self
	--     end
	--     function App:componentDidMount()
	--         self:setState({ showChild = false })
	--     end
	--     function App:render()
	--         return React.createElement(
	--             "div",
	--             nil,
	--             React.createElement(ForceUpdatesOnChange),
	--             (function()
	--                 if Boolean.toJSBoolean(self.state.showChild) then
	--                     return React.createElement(EmitsChangeOnUnmount)
	--                 else
	--                     return self.state.showChild
	--                 end
	--             end)()
	--         )
	--     end
	--     local EmitsChangeOnUnmount = React.Component:extend("")
	--     EmitsChangeOnUnmount.__index = EmitsChangeOnUnmount
	--     function EmitsChangeOnUnmount:componentWillUnmount()
	--         emitChange()
	--     end
	--     function EmitsChangeOnUnmount:render()
	--         return nil
	--     end
	--     local ForceUpdatesOnChange = React.Component:extend("")
	--     ForceUpdatesOnChange.__index = ForceUpdatesOnChange
	--     function ForceUpdatesOnChange:componentDidMount()
	--         self.onChange = function()
	--             return self:forceUpdate()
	--         end
	--         self:onChange()
	--         callbacks:push(self.onChange)
	--     end
	--     function ForceUpdatesOnChange:componentWillUnmount()
	--         callbacks = callbacks:filter(function(c)
	--             return c ~= self.onChange
	--         end)
	--     end
	--     function ForceUpdatesOnChange:render()
	--         return React.createElement("div", { key = Math:random(), onClick = function(self) end })
	--     end
	--     ReactTestRenderer.create(React.createElement(App), document:createElement("div"))
	-- end)
	it("unstable_batchedUpdates should return value from a callback", function()
		local result = ReactTestRenderer.unstable_batchedUpdates(function()
			return 42
		end)
		jestExpect(result).toEqual(42)
	end)
	it.skip("unmounts and remounts a root in the same batch", function()
		local root = ReactTestRenderer.create(React.createElement("span", nil, "a"))
		ReactTestRenderer.unstable_batchedUpdates(function()
			-- ROBLOX FIXME: how to do this with the test renderer?
			-- ReactTestRenderer.unmount()
			root:update(React.createElement("span", nil, "b"))
		end)
		-- ROBLOX TODO: need a toMatchRenderedOutput to work with the test *and* noop renderers
		jestExpect(root.toJSON().children[1]).toBe("b")
	end)
	-- it("handles reentrant mounting in synchronous mode", function()
	--     local mounts = 0
	--     local Editor = React.Component:extend("")
	--     Editor.__index = Editor
	--     function Editor:render()
	--         return React.createElement("div", nil, self.props.text)
	--     end
	--     function Editor:componentDidMount()
	--         (function()
	--             local result = mounts
	--             mounts += 1
	--             return result
	--         end)()
	--         if not Boolean.toJSBoolean(self.props.rendered) then
	--             self.props:onChange({ rendered = true })
	--         end
	--     end
	--     local container = document:createElement("div")
	--     local function render()
	--         ReactTestRenderer.create(
	--             React.createElement(
	--                 Editor,
	--                 _extends({
	--                     onChange = function(newProps)
	--                         props = Object.assign({}, props, newProps)
	--                         render()
	--                     end,
	--                 }, props)
	--             ),
	--             container
	--         )
	--     end
	--     local props = { text = "hello", rendered = false }
	--     render()
	--     props = Object.assign({}, props, { text = "goodbye" })
	--     render()
	--     jestExpect(container.textContent).toBe("goodbye")
	--     jestExpect(mounts).toBe(1)
	-- end)
	-- it("mounts and unmounts are sync even in a batch", function()
	--     local ops = {}
	--     local container = document:createElement("div")
	--     ReactTestRenderer.unstable_batchedUpdates(function()
	--         ReactTestRenderer.create(React.createElement("div", nil, "Hello"), container)
	--         table.insert(ops, container.textContent)
	--         ReactTestRenderer.unmountComponentAtNode(container)
	--         table.insert(ops, container.textContent)
	--     end)
	--     jestExpect(ops).toEqual({ "Hello", "" })
	-- end)
	-- it(
	--     "in legacy mode, updates in componentWillUpdate and componentDidUpdate "
	--         .. "should both flush in the immediately subsequent commit",
	--     function()
	--         local ops = {}
	--         local Foo = React.Component:extend("")
	--         Foo.__index = Foo
	--         function Foo:UNSAFE_componentWillUpdate(_, nextState)
	--             if not Boolean.toJSBoolean(nextState.a) then
	--                 self:setState({ a = true })
	--             end
	--         end
	--         function Foo:componentDidUpdate()
	--             table.insert(ops, "Foo updated")
	--             if not Boolean.toJSBoolean(self.state.b) then
	--                 self:setState({ b = true })
	--             end
	--         end
	--         function Foo:render()
	--             table.insert(ops, string.format("a: %s, b: %s", self.state.a, self.state.b))
	--             return nil
	--         end
	--         local container = document:createElement("div")
	--         ReactTestRenderer.create(React.createElement(Foo), container)
	--         ReactTestRenderer.create(React.createElement(Foo), container)
	--         jestExpect(ops).toEqual({
	--             "a: false, b: false",
	--             "a: false, b: false",
	--             "Foo updated",
	--             "a: true, b: true",
	--             "Foo updated",
	--         })
	--     end
	-- )
	-- it(
	--     "in legacy mode, updates in componentWillUpdate and componentDidUpdate "
	--         .. "(on a sibling) should both flush in the immediately subsequent commit",
	--     function()
	--         local ops = {}
	--         local Foo = React.Component:extend("")
	--         Foo.__index = Foo
	--         function Foo:UNSAFE_componentWillUpdate(_, nextState)
	--             if not Boolean.toJSBoolean(nextState.a) then
	--                 self:setState({ a = true })
	--             end
	--         end
	--         function Foo:componentDidUpdate()
	--             table.insert(ops, "Foo updated")
	--         end
	--         function Foo:render()
	--             table.insert(ops, string.format("a: %s", self.state.a))
	--             return nil
	--         end
	--         local Bar = React.Component:extend("")
	--         Bar.__index = Bar
	--         function Bar:componentDidUpdate()
	--             table.insert(ops, "Bar updated")
	--             if not Boolean.toJSBoolean(self.state.b) then
	--                 self:setState({ b = true })
	--             end
	--         end
	--         function Bar:render()
	--             table.insert(ops, string.format("b: %s", self.state.b))
	--             return nil
	--         end
	--         local container = document:createElement("div")
	--         ReactTestRenderer.create(
	--             React.createElement(
	--                 "div",
	--                 nil,
	--                 React.createElement(Foo),
	--                 React.createElement(Bar)
	--             ),
	--             container
	--         )
	--         ReactTestRenderer.create(
	--             React.createElement(
	--                 "div",
	--                 nil,
	--                 React.createElement(Foo),
	--                 React.createElement(Bar)
	--             ),
	--             container
	--         )
	--         jestExpect(ops).toEqual({
	--             "a: false",
	--             "b: false",
	--             "a: false",
	--             "b: false",
	--             "Foo updated",
	--             "Bar updated",
	--             "a: true",
	--             "b: true",
	--             "Foo updated",
	--             "Bar updated",
	--         })
	--     end
	-- )
	it("uses correct base state for setState inside render phase", function()
		local ops = {}
		local Foo = React.Component:extend("Foo")
		function Foo:init()
			self.state = { step = 0 }
		end
		function Foo:render()
			local memoizedStep = self.state.step
			self:setState(function(baseState)
				local baseStep = baseState.step
				table.insert(
					ops,
					string.format(
						"base: %s, memoized: %s",
						tostring(baseStep),
						memoizedStep
					)
				)
				return baseStep == 0 and { step = 1 } or nil
			end)
			return nil
		end
		jestExpect(function()
			ReactTestRenderer.create(React.createElement(Foo))
		end).toErrorDev("Cannot update during an existing state transition")
		jestExpect(ops).toEqual({ "base: 0, memoized: 0", "base: 1, memoized: 1" })
	end)
	it("does not re-render if state update is null", function()
		local instance
		local ops = {}
		local Foo = React.Component:extend("Foo")
		function Foo:render()
			instance = self
			table.insert(ops, "render")
			return React.createElement("div")
		end
		ReactTestRenderer.create(React.createElement(Foo))
		ops = {}
		instance:setState(function()
			return nil
		end)
		jestExpect(ops).toEqual({})
	end)

	-- Will change once we switch to async by default
	it("synchronously renders hidden subtrees", function()
		local ops = {}
		local function Baz()
			table.insert(ops, "Baz")
			return nil
		end
		local function Bar()
			table.insert(ops, "Bar")
			return nil
		end
		local function Foo()
			table.insert(ops, "Foo")
			return React.createElement(
				"div",
				nil,
				React.createElement("div", { hidden = true }, React.createElement(Bar)),
				React.createElement(Baz)
			)
		end

		-- Mount
		ReactTestRenderer.create(React.createElement(Foo))
		jestExpect(ops).toEqual({ "Foo", "Bar", "Baz" })
		ops = {}

		-- Update
		ReactTestRenderer.create(React.createElement(Foo))
		jestExpect(ops).toEqual({ "Foo", "Bar", "Baz" })
	end)
	-- @gate experimental
	-- it("delays sync updates inside hidden subtrees in Concurrent Mode", function()
	--     local container = document:createElement("div")
	--     local function Baz()
	--         Scheduler:unstable_yieldValue("Baz")
	--         return React.createElement("p", nil, "baz")
	--     end
	--     local setCounter
	--     local function Bar()
	--         local counter, _setCounter = table.unpack(React.useState(0), 1, 2)
	--         setCounter = _setCounter
	--         Scheduler:unstable_yieldValue("Bar")
	--         return React.createElement("p", nil, "bar ", counter)
	--     end
	--     local function Foo()
	--         Scheduler:unstable_yieldValue("Foo")
	--         React.useEffect(function()
	--             Scheduler:unstable_yieldValue("Foo#effect")
	--         end)
	--         return React.createElement(
	--             "div",
	--             nil,
	--             React.createElement(
	--                 LegacyHiddenDiv,
	--                 { mode = "hidden" },
	--                 React.createElement(Bar)
	--             ),
	--             React.createElement(Baz)
	--         )
	--     end
	--     local root = ReactTestRenderer.createRoot(container)
	--     local hiddenDiv
	--     act(function()
	--         root:render(React.createElement(Foo))
	--         jestExpect(Scheduler).toFlushAndYieldThrough({ "Foo", "Baz", "Foo#effect" })
	--         hiddenDiv = container.firstChild.firstChild
	--         jestExpect(hiddenDiv.hidden).toBe(true)
	--         jestExpect(hiddenDiv.innerHTML).toBe("")
	--         jestExpect(Scheduler).toFlushAndYield({ "Bar" })
	--         jestExpect(hiddenDiv.hidden).toBe(true)
	--         jestExpect(hiddenDiv.innerHTML).toBe("<p>bar 0</p>")
	--     end)
	--     ReactTestRenderer.flushSync(function()
	--         setCounter(1)
	--     end)
	--     jestExpect(hiddenDiv.innerHTML).toBe("<p>bar 0</p>")
	--     jestExpect(Scheduler).toFlushAndYield({ "Bar" })
	--     jestExpect(hiddenDiv.innerHTML).toBe("<p>bar 1</p>")
	-- end)
	-- it(
	--     "can render ridiculously large number of roots without triggering infinite update loop error",
	--     function()
	--         local Foo = React.Component:extend("Foo")
	--         Foo.__index = Foo
	--         function Foo:componentDidMount()
	--             local limit = 1200
	--             error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
	--             --[[ for (let i = 0; i < limit; i++) {
	--       if (i < limit - 1) {
	--         ReactDOM.render( /*#__PURE__*/React.createElement("div", null), document.createElement('div'));
	--       } else {
	--         ReactDOM.render( /*#__PURE__*/React.createElement("div", null), document.createElement('div'), () => {
	--           // The "nested update limit" error isn't thrown until setState
	--           this.setState({});
	--         });
	--       }
	--     } ]]
	--         end
	--         function Foo:render()
	--             return nil
	--         end
	--         local container = document:createElement("div")
	--         ReactTestRenderer.create(React.createElement(Foo), container)

	-- end)
	-- it("resets the update counter for unrelated updates", function()
	--     local container = document:createElement("div")
	--     local ref = React.createRef()
	--     local EventuallyTerminating = React.Component:extend("")
	--     EventuallyTerminating.__index = EventuallyTerminating
	--     function EventuallyTerminating:componentDidMount()
	--         self:setState({ step = 1 })
	--     end
	--     function EventuallyTerminating:componentDidUpdate()
	--         if
	--             self.state.step
	--             < limit --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
	--         then
	--             self:setState({ step = self.state.step + 1 })
	--         end
	--     end
	--     function EventuallyTerminating:render()
	--         return self.state.step
	--     end
	--     local limit = 55
	--     jestExpect(function()
	--         ReactTestRenderer.create(React.createElement(EventuallyTerminating, { ref = ref }), container)
	--     end).toThrow("Maximum")
	--     limit -= 10
	--     ReactTestRenderer.create(React.createElement(EventuallyTerminating, { ref = ref }), container)
	--     jestExpect(container.textContent).toBe(tostring(limit))
	--     ref.current:setState({ step = 0 })
	--     jestExpect(container.textContent).toBe(tostring(limit))
	--     ref.current:setState({ step = 0 })
	--     jestExpect(container.textContent).toBe(tostring(limit))
	--     limit += 10
	--     jestExpect(function()
	--         ref.current:setState({ step = 0 })
	--     end).toThrow("Maximum")
	--     jestExpect(ref.current).toBe(nil)
	-- end)
	-- it("does not fall into an infinite update loop", function()
	--     local NonTerminating = React.Component:extend("")
	--     NonTerminating.__index = NonTerminating
	--     function NonTerminating:componentDidMount()
	--         self:setState({ step = 1 })
	--     end
	--     function NonTerminating:UNSAFE_componentWillUpdate()
	--         self:setState({ step = 2 })
	--     end
	--     function NonTerminating:render()
	--         return React.createElement("div", nil, "Hello ", self.props.name, self.state.step)
	--     end
	--     local container = document:createElement("div")
	--     jestExpect(function()
	--         ReactTestRenderer.create(React.createElement(NonTerminating), container)
	--     end).toThrow("Maximum")
	-- end)
	it("does not fall into an infinite update loop with useLayoutEffect", function()
		local function NonTerminating()
			local step, setStep = React.useState(0)
			React.useLayoutEffect(function()
				setStep(function(x)
					return x + 1
				end)
			end)
			return step
		end
		jestExpect(function()
			ReactTestRenderer.create(React.createElement(NonTerminating))
		end).toThrow("Maximum")
	end)
	it("can recover after falling into an infinite update loop", function()
		local NonTerminating = React.Component:extend("NonTerminating")
		function NonTerminating:init()
			self.state = { step = 0 }
		end
		function NonTerminating:componentDidMount()
			self:setState({ step = 1 })
		end
		function NonTerminating:componentDidUpdate()
			self:setState({ step = 2 })
		end
		function NonTerminating:render()
			return self.state.step
		end
		local Terminating = React.Component:extend("Terminating")
		function Terminating:init()
			self.state = { step = 0 }
		end
		function Terminating:componentDidMount()
			self:setState({ step = 1 })
		end
		function Terminating:render()
			return self.state.step
		end
		jestExpect(function()
			ReactTestRenderer.create(React.createElement(NonTerminating))
		end).toThrow("Maximum")
		local container = ReactTestRenderer.create(React.createElement(Terminating))
		jestExpect(container.toJSON()).toBe("1")
		jestExpect(function()
			ReactTestRenderer.create(React.createElement(NonTerminating))
		end).toThrow("Maximum")
		container = ReactTestRenderer.create(React.createElement(Terminating))
		jestExpect(container.toJSON()).toBe("1")
	end)
	-- ROBLOX TODO: figure out how to do this with test renderer
	it.skip(
		"does not fall into mutually recursive infinite update loop with same container",
		function()
			-- Note: this test would fail if there were two or more different roots.
			local B = React.Component:extend("B")
			local container = ReactTestRenderer.create(React.createElement("div"))
			local A = React.Component:extend("A")
			function A:componentDidMount()
				container:update(React.createElement(B))
			end
			function A:render()
				return nil
			end
			function B:componentDidMount()
				container:update(React.createElement(A))
			end
			function B:render()
				return nil
			end
			jestExpect(function()
				container:update(React.createElement(A))
			end).toThrow("Maximum")
		end
	)
	it("does not fall into an infinite error loop", function()
		local function BadRender()
			error(Error.new("error"))
		end
		local ErrorBoundary = React.Component:extend("ErrorBoundary")
		function ErrorBoundary:componentDidCatch()
			-- Schedule a no-op state update to avoid triggering a DEV warning in the test.
			self:setState({})
			self.props.parent:remount()
		end
		function ErrorBoundary:render()
			return React.createElement(BadRender)
		end
		local NonTerminating = React.Component:extend("NonTerminating")
		function NonTerminating:init()
			self.state = { step = 0 }
		end
		function NonTerminating:remount()
			self:setState(function(state: { step: number })
				return { step = state.step + 1 }
			end)
		end
		function NonTerminating:render()
			return React.createElement(
				ErrorBoundary,
				{ key = self.state.step, parent = self }
			)
		end
		jestExpect(function()
			ReactTestRenderer.create(React.createElement(NonTerminating))
		end).toThrow("Maximum")
	end)
	-- it(
	--     "can schedule ridiculously many updates within the same batch without triggering a maximum update error",
	--     function()
	--         local subscribers = {}
	--         local Child = React.Component:extend("")
	--         Child.__index = Child
	--         function Child:componentDidMount()
	--             subscribers:push(self)
	--         end
	--         function Child:render()
	--             return nil
	--         end
	--         local App = React.Component:extend("")
	--         App.__index = App
	--         function App:render()
	--             local children = {}
	--             error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: ForStatement ]]
	--             --[[ for (let i = 0; i < 1200; i++) {
	--       children.push( /*#__PURE__*/React.createElement(Child, {
	--         key: i
	--       }));
	--     } ]]
	--             return children
	--         end
	--         local container = document:createElement("div")
	--         ReactTestRenderer.create(React.createElement(App), container)
	--         ReactTestRenderer.unstable_batchedUpdates(function()
	--             subscribers:forEach(function(s)
	--                 s:setState({ value = "update" })
	--             end)
	--         end)
	--     end
	-- )
	-- if Boolean.toJSBoolean(__DEV__) then
	--     it("warns about a deferred infinite update loop with useEffect", function()
	--         local function NonTerminating()
	--             local step, setStep = table.unpack(React.useState(0), 1, 2)
	--             React.useEffect(function()
	--                 setStep(function(x)
	--                     return x + 1
	--                 end)
	--                 Scheduler:unstable_yieldValue(step)
	--             end)
	--             return step
	--         end
	--         local function App()
	--             return React.createElement(NonTerminating)
	--         end
	--         local error_ = nil
	--         local stack = nil
	--         local originalConsoleError = console.error_
	--         console.error_ = function(e, s)
	--             error_ = e
	--             stack = s
	--         end
	--         do --[[ ROBLOX COMMENT: try-finally block conversion ]]
	--             local ok, result, hasReturned = pcall(function()
	--                 local container = document:createElement("div")
	--                 jestExpect(function()
	--                     act(function()
	--                         ReactTestRenderer.create(React.createElement(App), container)
	--                         error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: WhileStatement ]]
	--                         --[[ while (error === null) {
	--           Scheduler.unstable_flushNumberOfYields(1);
	--           Scheduler.unstable_clearYields();
	--         } ]]
	--                         jestExpect(error_).toContain("Warning: Maximum update depth exceeded.")
	--                         jestExpect(stack).toContain(" NonTerminating")
	--                         error(error_)
	--                     end)
	--                 end).toThrow("Maximum update depth exceeded.")
	--             end)
	--             do
	--                 console.error_ = originalConsoleError
	--             end
	--             if hasReturned then
	--                 return result
	--             end
	--             if not ok then
	--                 error(result)
	--             end
	--         end
	--     end)
	it("can have nested updates if they do not cross the limit", function()
		local _setStep
		local LIMIT = 50
		local function Terminating()
			local step, setStep = React.useState(0)
			_setStep = setStep
			React.useEffect(function()
				if
					step
					< LIMIT --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
				then
					setStep(function(x)
						return x + 1
					end)
				end
			end)
			Scheduler.unstable_yieldValue(step)
			return step
		end
		local container
		ReactTestRenderer.act(function()
			container = ReactTestRenderer.create(React.createElement(Terminating))
		end)
		jestExpect(container.toJSON()).toBe("50")
		ReactTestRenderer.act(function()
			_setStep(0)
		end)
		jestExpect(container.toJSON()).toBe("50")
	end)
	it("can have many updates inside useEffect without triggering a warning", function()
		-- ROBLOX deviation START: increase loop count to test our object caching logic
		local function Terminating()
			local step, setStep = React.useState(0)
			React.useEffect(function()
				for i = 1, 10000 do
					setStep(function(x)
						return x + 1
					end)
				end
				Scheduler.unstable_yieldValue("Done")
			end, {})
			return step
		end
		local container
		ReactTestRenderer.act(function()
			container = ReactTestRenderer.create(React.createElement(Terminating))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Done" })
		jestExpect(container.toJSON()).toBe("10000")
		-- ROBLOX deviation END
	end)
end)
