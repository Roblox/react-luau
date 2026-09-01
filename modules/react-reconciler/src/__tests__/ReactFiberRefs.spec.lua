-- ROBLOX upstream: https://github.com/facebook/react/blob/v19.0.0/packages/react-reconciler/src/__tests__/ReactFiberRefs-test.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
--!strict

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect
local it = JestGlobals.it
local Set = require(Packages.LuauPolyfill).Set

local React
local ReactNoop
local Scheduler

-- ROBLOX DEVIATION: React-Luau records Scheduler logs with
-- unstable_yieldValue/toHaveYielded, and ReactNoop.act is synchronous.
describe("ReactFiberRefs", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Dev.Scheduler)
	end)

	it("ref is attached even if there are no other updates (class)", function()
		local component
		local Component = React.Component:extend("Component")
		function Component:shouldComponentUpdate()
			-- This component's output doesn't depend on any props or state
			return false
		end
		function Component:render()
			Scheduler.unstable_yieldValue("Render")
			component = self
			return "Hi"
		end

		local ref1 = React.createRef()
		local ref2 = React.createRef()
		local root = ReactNoop.createRoot()

		-- Mount with ref1 attached
		ReactNoop.act(function()
			root.render(React.createElement(Component, { ref = ref1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Render" })
		jestExpect(root).toMatchRenderedOutput("Hi")
		jestExpect(ref1.current).toBe(component)
		-- ref2 has no value
		jestExpect(ref2.current).toBe(nil)

		-- Switch to ref2, but don't update anything else.
		ReactNoop.act(function()
			root.render(React.createElement(Component, { ref = ref2 }))
		end)
		-- The component did not re-render because no props changed.
		jestExpect(Scheduler).toHaveYielded({})
		jestExpect(root).toMatchRenderedOutput("Hi")
		-- But the refs still should have been swapped.
		jestExpect(ref1.current).toBe(nil)
		jestExpect(ref2.current).toBe(component)
	end)

	it("ref is attached even if there are no other updates (host component)", function()
		-- This is kind of a silly test because host components never bail out if they
		-- receive a new element, and there's no way to update a ref without also
		-- updating the props, but adding it here anyway for symmetry with the
		-- class case above.
		local ref1 = React.createRef()
		local ref2 = React.createRef()
		local root = ReactNoop.createRoot()

		-- Mount with ref1 attached
		ReactNoop.act(function()
			root.render(React.createElement("div", { ref = ref1 }, "Hi"))
		end)
		jestExpect(root).toMatchRenderedOutput(React.createElement("div", nil, "Hi"))
		jestExpect(ref1.current).never.toBe(nil)
		-- ref2 has no value
		jestExpect(ref2.current).toBe(nil)

		-- Switch to ref2, but don't update anything else.
		ReactNoop.act(function()
			root.render(React.createElement("div", { ref = ref2 }, "Hi"))
		end)
		jestExpect(root).toMatchRenderedOutput(React.createElement("div", nil, "Hi"))
		-- But the refs still should have been swapped.
		jestExpect(ref1.current).toBe(nil)
		jestExpect(ref2.current).never.toBe(nil)
	end)

	it("throw if a string ref is passed to a ref-receiving component", function()
		local refProp
		local function Child(props)
			-- This component renders successfully because the ref type check does not
			-- occur until you pass it to a component that accepts refs.
			--
			-- So the div will throw, but not Child.
			refProp = props.ref
			return React.createElement("div", { ref = props.ref })
		end

		local Owner = React.Component:extend("Owner")
		function Owner:render()
			return React.createElement(Child, { ref = "child" })
		end

		local root = ReactNoop.createRoot()
		-- ROBLOX DEVIATION: ReactNoop.act is synchronous in React-Luau, so Jest-Lua
		-- observes the thrown error directly instead of through Promise rejection.
		jestExpect(function()
			ReactNoop.act(function()
				root.render(React.createElement(Owner))
			end)
		end).toThrow("Expected ref to be a function")
		jestExpect(refProp).toBe("child")
	end)

	it("strings refs can be codemodded to callback refs", function()
		local app
		local App = React.Component:extend("App")
		function App:render()
			app = self
			return React.createElement("div", {
				prop = "Hello!",
				ref = function(element)
					-- `refs` used to be a shared frozen object unless/until a string
					-- ref attached by the reconciler, but it's not anymore so that we
					-- can codemod string refs to userspace callback refs.
					-- ROBLOX DEVIATION: React-Luau names this field __refs.
					self.__refs.div = element
				end,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(app.__refs.div.prop).toBe("Hello!")
	end)

	it("class refs are initialized to a frozen shared object", function()
		local refsCollection = Set.new()
		local Component = React.Component:extend("Component")
		function Component:init()
			-- ROBLOX DEVIATION: React-Luau class constructors are init methods and
			-- name the refs field __refs.
			refsCollection:add(self.__refs)
		end
		function Component:render()
			return React.createElement("div")
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(React.Fragment, nil, {
				React.createElement(Component),
				React.createElement(Component),
			}))
		end)

		jestExpect(refsCollection.size).toBe(1)
		-- ROBLOX DEVIATION: Use Luau's Set iterator and table.isfrozen in place
		-- of Array.from and Object.isFrozen.
		local refsInstance
		for _, value in refsCollection do
			refsInstance = value
			break
		end
		jestExpect(table.isfrozen(refsInstance)).toBe(_G.__DEV__)
	end)
end)
