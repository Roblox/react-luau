-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js#L681-L725
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

local Packages = script.Parent.Parent.Parent

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
			for _, listener in table.clone(listeners) do
				listener()
			end
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

local function loadModules()
	jest.resetModules()
	React = require(Packages.React)
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	Scheduler = require(Packages.Scheduler)
	useSyncExternalStoreWithSelector = require(Packages.UseSyncExternalStore).useSyncExternalStoreWithSelector
end

describe("extra features implemented in user-space", function()
	beforeEach(loadModules)

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
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "App", "Selector", "A0" })
		jestExpect(root).toMatchRenderedOutput(React.createElement("span", { prop = "A0" }))
		ReactNoop.flushPassiveEffects()

		store.set({
			a = 1,
			b = 0,
		})
		jestExpect(Scheduler).toFlushAndYield({ "Selector", "App", "A1" })
		jestExpect(root).toMatchRenderedOutput(React.createElement("span", { prop = "A1" }))
	end)
end)
