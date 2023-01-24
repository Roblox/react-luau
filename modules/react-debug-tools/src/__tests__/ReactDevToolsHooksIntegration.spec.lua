-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-debug-tools/src/__tests__/ReactDevToolsHooksIntegration-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
 ]]
local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
-- ROBLOX deviation START: not needed
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
local Error = LuauPolyfill.Error
local JestGlobals = require(Packages.Dev.JestGlobals)
-- ROBLOX deviation START: add additional import
local afterEach = JestGlobals.afterEach
-- ROBLOX deviation END
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

describe("React hooks DevTools integration", function()
	local React
	local ReactDebugTools
	local ReactTestRenderer
	local Scheduler
	local act
	local overrideHookState
	local scheduleUpdate
	local setSuspenseHandler
	beforeEach(function()
		-- ROBLOX deviation START: use _G instead of global
		-- global.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
		_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
			-- ROBLOX deviation END
			inject = function(injected)
				overrideHookState = injected.overrideHookState
				scheduleUpdate = injected.scheduleUpdate
				setSuspenseHandler = injected.setSuspenseHandler
			end,
			supportsFiber = true,
			onCommitFiberRoot = function() end,
			onCommitFiberUnmount = function() end,
		}
		jest.resetModules()
		-- ROBLOX deviation START: fix requires
		-- React = require_("react")
		-- ReactDebugTools = require_("react-debug-tools")
		-- ReactTestRenderer = require_("react-test-renderer")
		-- Scheduler = require_("scheduler")
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
		React = require(Packages.Dev.React)
		ReactDebugTools = require(Packages.ReactDebugTools)
		Scheduler = require(Packages.Dev.Scheduler)
		-- ROBLOX deviation END
		act = ReactTestRenderer.act
	end)
	-- ROBLOX deviation START: add afterEach to revert global flag
	afterEach(function()
		_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = nil
	end)
	-- ROBLOX deviation END
	it("should support editing useState hooks", function()
		local setCountFn
		local function MyComponent()
			-- ROBLOX deviation START: useState returns 2 values
			-- local count, setCount = table.unpack(React.useState(0), 1, 2)
			local count, setCount = React.useState(0)
			-- ROBLOX deviation END
			setCountFn = setCount
			-- ROBLOX deviation START: use TextLabel instead
			-- return React.createElement("div", nil, "count:", count)
			return React.createElement(
				"Frame",
				nil,
				React.createElement("TextLabel", { Text = "count:" }),
				React.createElement("TextLabel", { Text = tostring(count) })
			)
			-- ROBLOX deviation END
		end
		local renderer = ReactTestRenderer.create(React.createElement(MyComponent, nil))
		expect(renderer:toJSON()).toEqual({
			-- ROBLOX deviation START: use Frame instead
			-- type = "div",
			type = "Frame",
			-- ROBLOX deviation END
			props = {},
			-- ROBLOX deviation START: use TextLabels instead
			-- children = { "count:", "0" },
			children = {
				{ type = "TextLabel", props = { Text = "count:" } },
				{ type = "TextLabel", props = { Text = "0" } },
			},
			-- ROBLOX deviation END
		})
		local fiber = renderer.root:findByType(MyComponent):_currentFiber()
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooksOfFiber(fiber)
		local tree = ReactDebugTools.inspectHooksOfFiber(fiber)
		-- ROBLOX deviation END
		local stateHook = tree[
			1 --[[ ROBLOX adaptation: added 1 to array index ]]
		]
		expect(stateHook.isStateEditable).toBe(true)
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			overrideHookState(fiber, stateHook.id, {}, 10)
			expect(renderer:toJSON()).toEqual({
				-- ROBLOX deviation START: use Frame instead
				-- type = "div",
				type = "Frame",
				-- ROBLOX deviation END
				props = {},
				-- ROBLOX deviation START: use TextLabels instead
				-- children = { "count:", "10" },
				children = {
					{ type = "TextLabel", props = { Text = "count:" } },
					{ type = "TextLabel", props = { Text = "10" } },
				},
				-- ROBLOX deviation END
			})
			act(function()
				return setCountFn(function(count)
					return count + 1
				end)
			end)
			expect(renderer:toJSON()).toEqual({
				-- ROBLOX deviation START: use Frame instead
				-- type = "div",
				type = "Frame",
				-- ROBLOX deviation END
				props = {},
				-- ROBLOX deviation START: use TextLabels instead
				-- children = { "count:", "11" },
				children = {
					{ type = "TextLabel", props = { Text = "count:" } },
					{ type = "TextLabel", props = { Text = "11" } },
				},
				-- ROBLOX deviation END
			})
		end
	end)
	it("should support editable useReducer hooks", function()
		local initialData = { foo = "abc", bar = 123 }
		local function reducer(state, action)
			local condition_ = action.type
			if condition_ == "swap" then
				return { foo = state.bar, bar = state.foo }
			else
				error(Error.new())
			end
		end
		local dispatchFn
		local function MyComponent()
			-- ROBLOX deviation START: returns 2 values
			-- local state, dispatch =
			-- 	table.unpack(React.useReducer(reducer, initialData), 1, 2)
			-- ROBLOX deviation END
			local state, dispatch = React.useReducer(reducer, initialData)
			dispatchFn = dispatch
			-- ROBLOX deviation START: use Frame and TextLabels instead
			-- return React.createElement("div", nil, "foo:", state.foo, ", bar:", state.bar)
			return React.createElement(
				"Frame",
				{},
				React.createElement("TextLabel", { Text = "foo:" }),
				React.createElement("TextLabel", { Text = tostring(state.foo) }),
				React.createElement("TextLabel", { Text = ", bar:" }),
				React.createElement("TextLabel", { Text = tostring(state.bar) })
			)
			-- ROBLOX deviation END
		end
		local renderer = ReactTestRenderer.create(React.createElement(MyComponent, nil))
		expect(renderer:toJSON()).toEqual({
			-- ROBLOX deviation START: use Frame instead
			-- type = "div",
			type = "Frame",
			-- ROBLOX deviation END
			props = {},
			-- ROBLOX deviation START: use TextLabels instead
			-- children = { "foo:", "abc", ", bar:", "123" },
			children = {
				{ type = "TextLabel", props = { Text = "foo:" } },
				{ type = "TextLabel", props = { Text = "abc" } },
				{ type = "TextLabel", props = { Text = ", bar:" } },
				{ type = "TextLabel", props = { Text = "123" } },
			},
			-- ROBLOX deviation END
		})
		local fiber = renderer.root:findByType(MyComponent):_currentFiber()
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooksOfFiber(fiber)
		local tree = ReactDebugTools.inspectHooksOfFiber(fiber)
		-- ROBLOX deviation END
		local reducerHook = tree[
			1 --[[ ROBLOX adaptation: added 1 to array index ]]
		]
		expect(reducerHook.isStateEditable).toBe(true)
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			overrideHookState(fiber, reducerHook.id, { "foo" }, "def")
			expect(renderer:toJSON()).toEqual({
				-- ROBLOX deviation START: use Frame instead
				-- type = "div",
				type = "Frame",
				-- ROBLOX deviation END
				props = {},
				-- ROBLOX deviation START: use TextLabels instead
				-- children = { "foo:", "def", ", bar:", "123" },
				children = {
					{ type = "TextLabel", props = { Text = "foo:" } },
					{ type = "TextLabel", props = { Text = "def" } },
					{ type = "TextLabel", props = { Text = ", bar:" } },
					{ type = "TextLabel", props = { Text = "123" } },
				},
				-- ROBLOX deviation END
			})
			act(function()
				return dispatchFn({ type = "swap" })
			end)
			expect(renderer:toJSON()).toEqual({
				-- ROBLOX deviation START: use Frame instead
				-- type = "div",
				type = "Frame",
				-- ROBLOX deviation END
				props = {},
				-- ROBLOX deviation START: use TextLabels instead
				-- children = { "foo:", "123", ", bar:", "def" },
				children = {
					{ type = "TextLabel", props = { Text = "foo:" } },
					{ type = "TextLabel", props = { Text = "123" } },
					{ type = "TextLabel", props = { Text = ", bar:" } },
					{ type = "TextLabel", props = { Text = "def" } },
				},
				-- ROBLOX deviation END
			})
		end
	end) -- This test case is based on an open source bug report:
	-- facebookincubator/redux-react-hook/issues/34#issuecomment-466693787
	it(
		"should handle interleaved stateful hooks (e.g. useState) and non-stateful hooks (e.g. useContext)",
		function()
			local MyContext = React.createContext(1)
			local setStateFn
			local function useCustomHook()
				local context = React.useContext(MyContext)
				-- ROBLOX deviation START: returns 2 values
				-- local state, setState =
				-- 	table.unpack(React.useState({ count = context }), 1, 2)
				local state, setState = React.useState({ count = context })
				-- ROBLOX deviation END
				React.useDebugValue(state.count)
				setStateFn = setState
				return state.count
			end
			local function MyComponent()
				local count = useCustomHook()
				-- ROBLOX deviation START: use Frame and TextLabels instead
				-- return React.createElement("div", nil, "count:", count)
				return React.createElement(
					"Frame",
					nil,
					React.createElement("TextLabel", { Text = "count:" }),
					React.createElement("TextLabel", { Text = tostring(count) })
				)
				-- ROBLOX deviation END
			end
			local renderer =
				ReactTestRenderer.create(React.createElement(MyComponent, nil))
			expect(renderer:toJSON()).toEqual({
				-- ROBLOX deviation START: use Frame instead
				-- type = "div",
				type = "Frame",
				-- ROBLOX deviation END
				props = {},
				-- ROBLOX deviation START: use TextLabels instead
				-- children = { "count:", "1" },
				children = {
					{ type = "TextLabel", props = { Text = "count:" } },
					{ type = "TextLabel", props = { Text = "1" } },
				},
				-- ROBLOX deviation END
			})
			local fiber = renderer.root:findByType(MyComponent):_currentFiber()
			-- ROBLOX deviation START: use dot notation
			-- local tree = ReactDebugTools:inspectHooksOfFiber(fiber)
			local tree = ReactDebugTools.inspectHooksOfFiber(fiber)
			-- ROBLOX deviation END
			local stateHook = tree[
				1 --[[ ROBLOX adaptation: added 1 to array index ]]
			].subHooks[
				2 --[[ ROBLOX adaptation: added 1 to array index ]]
			]
			expect(stateHook.isStateEditable).toBe(true)
			-- ROBLOX deviation START: use _G.__DEV__
			-- if Boolean.toJSBoolean(__DEV__) then
			if _G.__DEV__ then
				-- ROBLOX deviation END
				overrideHookState(fiber, stateHook.id, { "count" }, 10)
				expect(renderer:toJSON()).toEqual({
					-- ROBLOX deviation START: use Frame instead
					-- type = "div",
					type = "Frame",
					-- ROBLOX deviation END
					props = {},
					-- ROBLOX deviation START: use TextLabels instead
					-- children = { "count:", "10" },
					children = {
						{ type = "TextLabel", props = { Text = "count:" } },
						{ type = "TextLabel", props = { Text = "10" } },
					},
					-- ROBLOX deviation END
				})
				act(function()
					return setStateFn(function(state)
						return { count = state.count + 1 }
					end)
				end)
				expect(renderer:toJSON()).toEqual({
					-- ROBLOX deviation START: use Frame instead
					-- type = "div",
					type = "Frame",
					-- ROBLOX deviation END
					props = {},
					-- ROBLOX deviation START: use TextLabels instead
					-- children = { "count:", "11" },
					children = {
						{ type = "TextLabel", props = { Text = "count:" } },
						{ type = "TextLabel", props = { Text = "11" } },
					},
					-- ROBLOX deviation END
				})
			end
		end
	)
	it("should support overriding suspense in legacy mode", function()
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			-- Lock the first render
			setSuspenseHandler(function()
				return true
			end)
		end
		local function MyComponent()
			-- ROBLOX deviation START: use TextLabel instead
			-- return "Done"
			return React.createElement("TextLabel", { Text = "Done" })
			-- ROBLOX deviation END
		end
		local renderer = ReactTestRenderer.create(React.createElement(
			-- ROBLOX deviation START: use Frame instead
			-- "div",
			"Frame",
			-- ROBLOX deviation END
			nil,
			React.createElement(
				React.Suspense,
				-- ROBLOX deviation START: use TextLabel instead
				-- { fallback = "Loading" },
				{ fallback = React.createElement("TextLabel", { Text = "Loading" }) },
				-- ROBLOX deviation END
				React.createElement(MyComponent, nil)
			)
		))
		local fiber = renderer.root:_currentFiber().child
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			-- First render was locked
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" }) -- Release the lock
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return false
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" }) -- Lock again
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return true
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" }) -- Release the lock again
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return false
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" }) -- Ensure it checks specific fibers.
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function(f)
				return f == fiber or f == fiber.alternate
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function(f)
				return f ~= fiber and f ~= fiber.alternate
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
		else
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
		end
	end)
	it("should support overriding suspense in concurrent mode", function()
		-- ROBLOX deviation START: add useFakeTimers
		jest.useFakeTimers()
		-- ROBLOX deviation END
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			-- Lock the first render
			setSuspenseHandler(function()
				return true
			end)
		end
		local function MyComponent()
			-- ROBLOX deviation START: use TextLabel instead
			-- return "Done"
			return React.createElement("TextLabel", { Text = "Done" })
			-- ROBLOX deviation END
		end
		local renderer = ReactTestRenderer.create(
			React.createElement(
				"div",
				nil,
				React.createElement(
					React.Suspense,
					-- ROBLOX deviation START: use TextLabel instead
					-- { fallback = "Loading" },
					{ fallback = React.createElement("TextLabel", { Text = "Loading" }) },
					-- ROBLOX deviation END
					React.createElement(MyComponent, nil)
				)
			),
			{ unstable_isConcurrent = true }
		)
		expect(Scheduler).toFlushAndYield({}) -- Ensure we timeout any suspense time.
		jest.advanceTimersByTime(1000)
		local fiber = renderer.root:_currentFiber().child
		-- ROBLOX deviation START: use _G.__DEV__
		-- if Boolean.toJSBoolean(__DEV__) then
		if _G.__DEV__ then
			-- ROBLOX deviation END
			-- First render was locked
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" }) -- Release the lock
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return false
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use dot notation
			-- Scheduler:unstable_flushAll()
			Scheduler.unstable_flushAll()
			-- ROBLOX deviation END
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" }) -- Lock again
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return true
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" }) -- Release the lock again
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function()
				return false
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" }) -- Ensure it checks specific fibers.
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function(f)
				return f == fiber or f == fiber.alternate
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Loading" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Loading" },
				},
			})
			-- ROBLOX deviation END
			setSuspenseHandler(function(f)
				return f ~= fiber and f ~= fiber.alternate
			end)
			scheduleUpdate(fiber) -- Re-render
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
			-- ROBLOX deviation END
		else
			-- ROBLOX deviation START: use TextLabel instead
			-- expect(renderer:toJSON().children).toEqual({ "Done" })
			expect(renderer:toJSON().children).toEqual({
				{
					type = "TextLabel",
					props = { Text = "Done" },
				},
			})
		end
		-- ROBLOX deviation START: add useRealTimers
		jest.useRealTimers()
		-- ROBLOX deviation END
	end)
end)
