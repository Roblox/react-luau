-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-debug-tools/src/__tests__/ReactHooksInspection-test.js
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
-- ROBLOX deviation START: not needed
-- local LuauPolyfill = require(Packages.LuauPolyfill)
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

local React
local ReactDebugTools
describe("ReactHooksInspection", function()
	beforeEach(function()
		jest.resetModules()
		-- ROBLOX deviation START: fix requires
		-- React = require_("react")
		-- ReactDebugTools = require_("react-debug-tools")
		React = require(Packages.Dev.React)
		ReactDebugTools = require(Packages.ReactDebugTools)
		-- ROBLOX deviation END
	end)
	it("should inspect a simple useState hook", function()
		local function Foo(props)
			-- ROBLOX deviation START: useState returns 2 values
			-- local state = React.useState("hello world")[1]
			local state = React.useState("hello world")
			-- ROBLOX deviation END
			return React.createElement("div", nil, state)
		end
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooks(Foo, {})
		local tree = ReactDebugTools.inspectHooks(Foo, {})
		-- ROBLOX deviation END
		expect(tree).toEqual({
			{
				isStateEditable = true,
				-- ROBLOX deviation START: adjust for 1-based indexing
				-- id = 0,
				id = 1,
				-- ROBLOX deviation END
				name = "State",
				value = "hello world",
				subHooks = {},
			},
		})
	end)
	it("should inspect a simple custom hook", function()
		local function useCustom(value)
			local state = React.useState(value)[1]
			React.useDebugValue("custom hook label")
			return state
		end
		local function Foo(props)
			local value = useCustom("hello world")
			return React.createElement("div", nil, value)
		end
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooks(Foo, {})
		local tree = ReactDebugTools.inspectHooks(Foo, {})
		-- ROBLOX deviation END
		expect(tree).toEqual({
			{
				isStateEditable = false,
				id = nil,
				name = "Custom",
				-- ROBLOX deviation START: use _G.__DEV__
				-- value = if Boolean.toJSBoolean(__DEV__) then "custom hook label" else nil,
				value = if _G.__DEV__ then "custom hook label" else nil,
				-- ROBLOX deviation END
				subHooks = {
					{
						isStateEditable = true,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 0,
						id = 1,
						-- ROBLOX deviation END
						name = "State",
						value = "hello world",
						subHooks = {},
					},
				},
			},
		})
	end)
	it("should inspect a tree of multiple hooks", function()
		local function effect() end
		local function useCustom(value)
			-- ROBLOX deviation START: useState returns 2 values
			-- local state = React.useState(value)[1]
			local state = React.useState(value)
			-- ROBLOX deviation END
			React.useEffect(effect)
			return state
		end
		local function Foo(props)
			local value1 = useCustom("hello")
			local value2 = useCustom("world")
			return React.createElement("div", nil, value1, " ", value2)
		end
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooks(Foo, {})
		local tree = ReactDebugTools.inspectHooks(Foo, {})
		-- ROBLOX deviation END
		expect(tree).toEqual({
			{
				isStateEditable = false,
				id = nil,
				name = "Custom",
				value = nil,
				subHooks = {
					{
						isStateEditable = true,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 0,
						id = 1,
						-- ROBLOX deviation END
						name = "State",
						subHooks = {},
						-- ROBLOX deviation START: tell Luau to type this field loosely
						value = "hello" :: any,
						-- ROBLOX deviation END
					},
					{
						isStateEditable = false,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 1,
						id = 2,
						-- ROBLOX deviation END
						name = "Effect",
						subHooks = {},
						value = effect,
					},
				},
			},
			{
				isStateEditable = false,
				id = nil,
				name = "Custom",
				value = nil,
				subHooks = {
					{
						isStateEditable = true,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 2,
						id = 3,
						-- ROBLOX deviation END
						name = "State",
						-- ROBLOX deviation START: Luau doesn't support mixed arrays
						-- value = "world",
						value = "world" :: any,
						-- ROBLOX deviation END
						subHooks = {},
					},
					{
						isStateEditable = false,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 3,
						id = 4,
						-- ROBLOX deviation END
						name = "Effect",
						value = effect,
						subHooks = {},
					},
				},
			},
		})
	end)
	it("should inspect a tree of multiple levels of hooks", function()
		local function effect() end
		local function useCustom(value)
			local state = React.useReducer(function(s, a)
				return s
				-- ROBLOX deviation START: useReducer returns 2 values
				-- end, value)[1]
			end, value)
			-- ROBLOX deviation END
			React.useEffect(effect)
			return state
		end
		local function useBar(value)
			local result = useCustom(value)
			React.useLayoutEffect(effect)
			return result
		end
		local function useBaz(value)
			React.useLayoutEffect(effect)
			local result = useCustom(value)
			return result
		end
		local function Foo(props)
			local value1 = useBar("hello")
			local value2 = useBaz("world")
			return React.createElement("div", nil, value1, " ", value2)
		end
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooks(Foo, {})
		local tree = ReactDebugTools.inspectHooks(Foo, {})
		-- ROBLOX deviation END
		expect(tree).toEqual({
			{
				isStateEditable = false,
				-- ROBLOX deviation START: tell Luau to type this field loosely
				id = nil :: number?,
				-- ROBLOX deviation END
				name = "Bar",
				value = nil,
				subHooks = {
					{
						isStateEditable = false,
						-- ROBLOX deviation START: Luau doesn't support mixed arrays
						-- id = nil,
						id = nil :: number | nil,
						-- ROBLOX deviation END
						name = "Custom",
						-- ROBLOX deviation START: Luau doesn't support mixed arrays
						-- value = nil,
						value = nil :: any,
						-- ROBLOX deviation END
						subHooks = {
							{
								isStateEditable = true,
								-- ROBLOX deviation START: adjust for 1-based indexing
								-- id = 0,
								id = 1,
								-- ROBLOX deviation END
								name = "Reducer",
								-- ROBLOX deviation START: Luau doesn't support mixed arrays
								-- value = "hello",
								value = "hello" :: any,
								-- ROBLOX deviation END
								subHooks = {},
							},
							{
								isStateEditable = false,
								-- ROBLOX deviation START: adjust for 1-based indexing
								-- id = 1,
								id = 2,
								-- ROBLOX deviation END
								name = "Effect",
								value = effect,
								subHooks = {},
							},
						},
					},
					{
						isStateEditable = false,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 2,
						id = 3,
						-- ROBLOX deviation END
						name = "LayoutEffect",
						value = effect,
						subHooks = {},
					},
				},
			},
			{
				isStateEditable = false,
				id = nil,
				name = "Baz",
				value = nil,
				subHooks = {
					{
						isStateEditable = false,
						-- ROBLOX deviation START: adjust for 1-based indexing
						-- id = 3,
						id = 4 :: number?,
						-- ROBLOX deviation END
						name = "LayoutEffect",
						-- ROBLOX deviation START: Luau doesn't support mixed arrays
						-- value = effect,
						value = effect :: any,
						-- ROBLOX deviation END
						subHooks = {},
					},
					{
						isStateEditable = false,
						id = nil,
						name = "Custom",
						subHooks = {
							{
								isStateEditable = true,
								-- ROBLOX deviation START: adjust for 1-based indexing
								-- id = 4,
								id = 5,
								-- ROBLOX deviation END
								name = "Reducer",
								subHooks = {},
								-- ROBLOX deviation START: Luau doesn't support mixed arrays
								-- value = "world",
								value = "world" :: any,
								-- ROBLOX deviation END
							},
							{
								isStateEditable = false,
								-- ROBLOX deviation START: adjust for 1-based indexing
								-- id = 5,
								id = 6,
								-- ROBLOX deviation END
								name = "Effect",
								subHooks = {},
								value = effect,
							},
						},
						value = nil,
					},
				},
			},
		})
	end)
	it("should inspect the default value using the useContext hook", function()
		local MyContext = React.createContext("default")
		local function Foo(props)
			local value = React.useContext(MyContext)
			return React.createElement("div", nil, value)
		end
		-- ROBLOX deviation START: use dot notation
		-- local tree = ReactDebugTools:inspectHooks(Foo, {})
		local tree = ReactDebugTools.inspectHooks(Foo, {})
		-- ROBLOX deviation END
		expect(tree).toEqual({
			{
				isStateEditable = false,
				id = nil,
				name = "Context",
				value = "default",
				subHooks = {},
			},
		})
	end)
	it("should support an injected dispatcher", function()
		local function Foo(props)
			-- ROBLOX deviation START: useState returns 2 values
			-- local state = React.useState("hello world")[1]
			local state = React.useState("hello world")
			-- ROBLOX deviation END
			return React.createElement("div", nil, state)
		end
		local initial = {}
		local current = initial
		local getterCalls = 0
		local setterCalls = {}
		-- ROBLOX deviation START: implement getter and setter
		-- local FakeDispatcherRef = {
		-- 	current = function(self)
		-- 		getterCalls += 1
		-- 		return current
		-- 	end,
		-- 	current = function(self, value)
		-- 		table.insert(setterCalls, value) --[[ ROBLOX CHECK: check if 'setterCalls' is an Array ]]
		-- 		current = value
		-- 	end,
		-- }
		local FakeDispatcherRef = setmetatable({
			__getters = {
				current = function(self)
					print("getting current")
					getterCalls += 1
					return current
				end,
			},
			__setters = {
				current = function(self, value)
					print("setting current", value)
					table.insert(setterCalls, value)
					current = value
				end,
			},
		}, {
			__index = function(self, key)
				if typeof(self.__getters[key]) == "function" then
					return self.__getters[key](self)
				else
					return nil
				end
			end,
			__newindex = function(self, key, value)
				if typeof(self.__setters[key]) == "function" then
					return self.__setters[key](self, value)
				else
					return nil
				end
			end,
		}) :: any
		-- ROBLOX deviation END
		-- ROBLOX deviation START: aligned to React 18 so we get a hot path optimization in upstream
		-- expect(function()
		-- 	ReactDebugTools:inspectHooks(Foo, {}, FakeDispatcherRef)
		-- end).toThrow(
		-- 	"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
		-- 		.. " one of the following reasons:\n"
		-- 		.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
		-- 		.. "2. You might be breaking the Rules of Hooks\n"
		-- 		.. "3. You might have more than one copy of React in the same app\n"
		-- 		.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
		-- )
		local didCatch = false
		expect(function()
			-- mock the Error constructor to check the internal of the error instance
			expect(function()
				ReactDebugTools.inspectHooks(Foo, {}, FakeDispatcherRef)
			end).toThrow(
				-- ROBLOX NOTE: Lua-specific error on nil deref
				"attempt to index nil with 'useState'"
			)
			didCatch = true
		end).toErrorDev(
			"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
				.. " one of the following reasons:\n"
				.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
				.. "2. You might be breaking the Rules of Hooks\n"
				.. "3. You might have more than one copy of React in the same app\n"
				.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.",
			{ withoutStack = true }
		)
		-- avoid false positive if no error was thrown at all
		expect(didCatch).toBe(true)
		-- ROBLOX deviation END
		expect(getterCalls).toBe(1)
		expect(setterCalls).toHaveLength(2)
		expect(setterCalls[
			1 --[[ ROBLOX adaptation: added 1 to array index ]]
			-- ROBLOX deviation START: use never instead of ["not"]
			-- ])["not"].toBe(initial)
		]).never.toBe(initial)
		-- ROBLOX deviation END
		expect(setterCalls[
			2 --[[ ROBLOX adaptation: added 1 to array index ]]
		]).toBe(initial)
	end)
	describe("useDebugValue", function()
		it("should be ignored when called outside of a custom hook", function()
			local function Foo(props)
				React.useDebugValue("this is invalid")
				return nil
			end
			-- ROBLOX deviation START: use dot notation
			-- local tree = ReactDebugTools:inspectHooks(Foo, {})
			local tree = ReactDebugTools.inspectHooks(Foo, {})
			-- ROBLOX deviation END
			expect(tree).toHaveLength(0)
		end)
		it("should support an optional formatter function param", function()
			local function useCustom()
				React.useDebugValue({ bar = 123 }, function(object)
					return ("bar:%s"):format(tostring(object.bar))
				end)
				React.useState(0)
			end
			local function Foo(props)
				useCustom()
				return nil
			end
			-- ROBLOX deviation START: use dot notation
			-- local tree = ReactDebugTools:inspectHooks(Foo, {})
			local tree = ReactDebugTools.inspectHooks(Foo, {})
			-- ROBLOX deviation END
			expect(tree).toEqual({
				{
					isStateEditable = false,
					id = nil,
					name = "Custom",
					-- ROBLOX deviation START: use _G.__DEV__
					-- value = if Boolean.toJSBoolean(__DEV__) then "bar:123" else nil,
					value = if _G.__DEV__ then "bar:123" else nil,
					-- ROBLOX deviation END
					subHooks = {
						{
							isStateEditable = true,
							-- ROBLOX deviation START: adjust for 1-based indexing
							-- id = 0,
							id = 1,
							-- ROBLOX deviation END
							name = "State",
							subHooks = {},
							value = 0,
						},
					},
				},
			})
		end)
	end)
end)
