-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js#L681-L796
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js#L873-L957
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js#L958-L1078
-- ROBLOX DEVIATION: ReactNoop act/host output and Scheduler yields replace DOM act/output.
-- ROBLOX DEVIATION: Native useSyncExternalStore cases remain owned by dependency PR #24.
-- ROBLOX DEVIATION: ReactRoblox has no server-rendering or hydration entry point.
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

local Packages = script.Parent.Parent.Parent
local Error = require(Packages.LuauPolyfill).Error

local React
local ReactNoop
local Scheduler
local useSyncExternalStoreWithSelector

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

type Store<T> = {
	getState: () -> T,
	set: (T) -> (),
	subscribe: (() -> ()) -> () -> (),
}

local function createExternalStore<T>(initialState: T): Store<T>
	local listeners = {}
	local currentState = initialState

	return {
		set = function(nextState: T)
			currentState = nextState
			ReactNoop.batchedUpdates(function()
				for _, listener in table.clone(listeners) do
					listener()
				end
			end)
		end,
		subscribe = function(listener: () -> ())
			table.insert(listeners, listener)
			return function()
				local index = table.find(listeners, listener)
				if index ~= nil then
					table.remove(listeners, index)
				end
			end
		end,
		getState = function()
			return currentState
		end,
	}
end

local function Text(props)
	Scheduler.unstable_yieldValue(props.text)
	return React.createElement("span", { prop = props.text })
end

-- ROBLOX DEVIATION: ReactNoop host props replace DOM textContent.
local function textContent(root)
	local content = ""
	for _, child in root.getChildren() do
		content ..= child.prop
	end
	return content
end

local function loadModules()
	jest.resetModules()
	React = require(Packages.React)
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	Scheduler = require(Packages.Scheduler)
	useSyncExternalStoreWithSelector =
		require(Packages.UseSyncExternalStore).useSyncExternalStoreWithSelector
end

local function createErrorBoundary()
	local ErrorBoundary = React.Component:extend("ErrorBoundary")
	function ErrorBoundary:init()
		self.state = { error_ = nil }
	end
	function ErrorBoundary.getDerivedStateFromError(error_)
		return { error_ = error_ }
	end
	function ErrorBoundary:render()
		if self.state.error_ ~= nil then
			return React.createElement(Text, { text = self.state.error_.message })
		end
		return self.props.children
	end
	return ErrorBoundary
end

beforeEach(loadModules)

describe("extra features implemented in user-space", function()
	it("memoized selectors are only called once per update", function()
		local store = createExternalStore({
			a = 0,
			b = 0,
		})
		local function selector(state)
			Scheduler.unstable_yieldValue("Selector")
			return state.a
		end
		local function App()
			Scheduler.unstable_yieldValue("App")
			local a = useSyncExternalStoreWithSelector(
				store.subscribe,
				store.getState,
				nil,
				selector
			)
			return React.createElement(Text, {
				text = "A" .. a,
			})
		end
		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "App", "Selector", "A0" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "A0" })
		)

		ReactNoop.act(function()
			store.set({
				a = 1,
				b = 0,
			})
		end)
		jestExpect(Scheduler).toHaveYielded({ "Selector", "App", "A1" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "A1" })
		)
	end)

	it("Using isEqual to bailout", function()
		local store = createExternalStore({
			a = 0,
			b = 0,
		})
		local function A()
			local selection = useSyncExternalStoreWithSelector(
				store.subscribe,
				store.getState,
				nil,
				function(state)
					return { a = state.a }
				end,
				function(state1, state2)
					return state1.a == state2.a
				end
			)
			return React.createElement(Text, {
				text = "A" .. selection.a,
			})
		end
		local function B()
			local selection = useSyncExternalStoreWithSelector(
				store.subscribe,
				store.getState,
				nil,
				function(state)
					return { b = state.b }
				end,
				function(state1, state2)
					return state1.b == state2.b
				end
			)
			return React.createElement(Text, {
				text = "B" .. selection.b,
			})
		end
		local function App()
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(A),
				React.createElement(B)
			)
		end
		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A0", "B0" })
		jestExpect(textContent(root)).toEqual("A0B0")

		ReactNoop.act(function()
			store.set({
				a = 0,
				b = 1,
			})
		end)
		jestExpect(Scheduler).toHaveYielded({ "B1" })
		jestExpect(textContent(root)).toEqual("A0B1")

		ReactNoop.act(function()
			store.set({
				a = 1,
				b = 1,
			})
		end)
		jestExpect(Scheduler).toHaveYielded({ "A1" })
		jestExpect(textContent(root)).toEqual("A1B1")
	end)
end)

it("compares selection to rendered selection even if selector changes", function()
	local store = createExternalStore({
		items = { "A", "B" },
	})
	local function shallowEqualArray(a, b)
		if #a ~= #b then
			return false
		end
		for index = 1, #a do
			if a[index] ~= b[index] then
				return false
			end
		end
		return true
	end
	local List = React.memo(function(props)
		local children = {}
		for _, text in props.items do
			table.insert(
				children,
				React.createElement(Text, {
					key = text,
					text = text,
				})
			)
		end
		return React.createElement(React.Fragment, nil, unpack(children))
	end)
	local function App(props)
		local function inlineSelector(state)
			Scheduler.unstable_yieldValue("Inline selector")
			local items = table.clone(state.items)
			table.insert(items, "C")
			return items
		end
		local items = useSyncExternalStoreWithSelector(
			store.subscribe,
			store.getState,
			nil,
			inlineSelector,
			shallowEqualArray
		)
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement(List, { items = items }),
			React.createElement(Text, { text = "Sibling: " .. props.step })
		)
	end
	local root = ReactNoop.createRoot()
	ReactNoop.act(function()
		root.render(React.createElement(App, { step = 0 }))
	end)
	jestExpect(Scheduler).toHaveYielded({
		"Inline selector",
		"A",
		"B",
		"C",
		"Sibling: 0",
	})

	ReactNoop.act(function()
		root.render(React.createElement(App, { step = 1 }))
	end)
	jestExpect(Scheduler).toHaveYielded({
		"Inline selector",
		"Sibling: 1",
	})
end)

describe("selector and isEqual error handling in extra", function()
	it("selector can throw on update", function()
		local store = createExternalStore({
			a = "a",
		})
		local function selector(state)
			if typeof(state.a) ~= "string" then
				error(Error.new("Malformed state"))
			end
			return string.upper(state.a)
		end
		local function App()
			local a = useSyncExternalStoreWithSelector(
				store.subscribe,
				store.getState,
				nil,
				selector
			)
			return React.createElement(Text, { text = a })
		end
		local ErrorBoundary = createErrorBoundary()
		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "A" })
		)

		-- ROBLOX DEVIATION: React 17 reports the concurrent recovery attempt twice.
		jestExpect(function()
			ReactNoop.act(function()
				store.set({} :: any)
			end)
		end).toErrorDev({
			"The above error occurred in the <App> component:",
			"The above error occurred in the <App> component:",
		}, {
			logAllErrors = true,
		})
		jestExpect(Scheduler).toHaveYielded({ "Malformed state" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "Malformed state" })
		)
	end)

	it("isEqual can throw on update", function()
		local store = createExternalStore({
			a = "A",
		})
		local function selector(state)
			return state.a
		end
		local function isEqual(left, right)
			-- ROBLOX DEVIATION: Luau cannot safely read a missing property from a string primitive.
			if typeof(left) ~= "string" or typeof(right) ~= "string" then
				error(Error.new("Malformed state"))
			end
			return string.gsub(left, "^%s*(.-)%s*$", "%1")
				== string.gsub(right, "^%s*(.-)%s*$", "%1")
		end
		local function App()
			local a = useSyncExternalStoreWithSelector(
				store.subscribe,
				store.getState,
				nil,
				selector,
				isEqual
			)
			return React.createElement(Text, { text = a })
		end
		local ErrorBoundary = createErrorBoundary()
		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "A" })
		)

		-- ROBLOX DEVIATION: React 17 reports the concurrent recovery attempt twice.
		jestExpect(function()
			ReactNoop.act(function()
				store.set({} :: any)
			end)
		end).toErrorDev({
			"The above error occurred in the <App> component:",
			"The above error occurred in the <App> component:",
		}, {
			logAllErrors = true,
		})
		jestExpect(Scheduler).toHaveYielded({ "Malformed state" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "Malformed state" })
		)
	end)
end)
