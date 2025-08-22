--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/storeComponentFilters-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

type Function = (...any) -> ...any
local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect

local global = ReactGlobals :: any

local bridgeModule = require(script.Parent.Parent.bridge)
type FrontendBridge = bridgeModule.FrontendBridge
local devtoolsTypes = require(script.Parent.Parent.devtools.types)
type Store = devtoolsTypes.Store

describe("Store component filters", function()
	local React
	local ReactRoblox
	local Types
	local bridge: FrontendBridge
	local store: Store
	local devtoolsUtils
	local utils

	local act = function(callback: Function)
		ReactRoblox.act(function()
			callback()
			-- ROBLOX FIXME: flush should be happening when all timers are run
			bridge:_flush()
		end)
		jest.runAllTimers() -- Flush Bridge operations
	end

	beforeEach(function()
		bridge = global.bridge
		store = global.store
		store:setCollapseNodesByDefault(false)
		store:setComponentFilters({})
		store:setRecordChangeDescriptions(true)

		local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = true

		React = require(Packages.React)
		ReactRoblox = require(Packages.ReactRoblox)
		Types = require(script.Parent.Parent.types)
		utils = require(script.Parent.utils)
		devtoolsUtils = require(script.Parent.Parent.devtools.utils)
	end)

	it("should throw if filters are updated while profiling", function()
		act(function()
			return store:getProfilerStore():startProfiling()
		end)
		jestExpect(function()
			store:setComponentFilters({})
			return store:getComponentFilters()
		end).toThrow("Cannot modify filter preferences while profiling")
	end)

	it("should support filtering by element type", function()
		local Root = React.Component:extend("Root")
		function Root:render()
			return React.createElement("Frame", nil, self.props.children)
		end
		local function Component()
			return React.createElement("TextLabel", { Text = "Hi" })
		end
		act(function()
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			return root:render(
				React.createElement(Root, {}, React.createElement(Component))
			)
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("1: mount")
		act(function()
			store:setComponentFilters({
				utils.createElementTypeFilter(Types.ElementTypeHostComponent),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: still shows the Frame and TextLabel, upstream only has [root] ▾ <Root> <Component>
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"2: hide host components"
		)
		act(function()
			store:setComponentFilters({
				utils.createElementTypeFilter(Types.ElementTypeClass),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: supposed to hide Root, but doesn't
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"3: hide class components"
		)
		act(function()
			store:setComponentFilters({
				utils.createElementTypeFilter(Types.ElementTypeClass),
				utils.createElementTypeFilter(Types.ElementTypeFunction),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: should only show Frame and TextLabel
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"4: hide class and function components"
		)
		act(function()
			store:setComponentFilters({
				utils.createElementTypeFilter(Types.ElementTypeClass, false),
				utils.createElementTypeFilter(Types.ElementTypeFunction, false),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"5: disable all filters"
		)
	end)
	it("should ignore invalid ElementTypeRoot filter", function()
		local function Root(props)
			return React.createElement("TextLabel", { Text = "Hi" }, props.children)
		end
		act(function()
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			root:render(React.createElement(Root))
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("1: mount")
		act(function()
			store:setComponentFilters({
				utils.createElementTypeFilter(Types.ElementTypeRoot),
			})
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"2: add invalid filter"
		)
	end)
	it("should filter by display name", function()
		local function Text(props)
			-- Roblox deviation: Text is a noop so we don't clutter our tree with TextLabels
			-- return React.createElement("TextLabel", { Text = props.label })
			return nil
		end
		local function Foo()
			return React.createElement(Text, { label = "foo" })
		end
		local function Bar()
			return React.createElement(Text, { label = "bar" })
		end
		local function Baz()
			return React.createElement(Text, { label = "baz" })
		end
		act(function()
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			return root:render(
				React.createElement(
					React.Fragment,
					nil,
					React.createElement(Foo),
					React.createElement(Bar),
					React.createElement(Baz)
				)
			)
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("1: mount")
		act(function()
			store:setComponentFilters({ utils.createDisplayNameFilter("Foo") })
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: doens't filter FOo
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot('2: filter "Foo"')
		act(function()
			store:setComponentFilters({ utils.createDisplayNameFilter("Ba") })
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot('3: filter "Ba"')
		act(function()
			store:setComponentFilters({ utils.createDisplayNameFilter("B.z") })
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot('4: filter "B.z"')
	end)
	it("should filter by path", function()
		local function Component()
			return React.createElement("TextLabel", { Text = "Hi" })
		end
		act(function()
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			root:render(React.createElement(Component))
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("1: mount")
		act(function()
			store:setComponentFilters({
				--	utils.createLocationFilter(__filename:replace(__dirname, "")),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: upstream only has `[root]`, we still show the whole tree
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"2: hide all components declared within this test filed"
		)
		act(function()
			store:setComponentFilters({
				utils.createLocationFilter("this:is:a:made:up:path"),
			})
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"3: hide components in a made up fake path"
		)
	end)
	it("should filter HOCs", function()
		local function Component()
			return React.createElement("TextLabel", { Text = "Hi" })
		end

		local Foo = React.Component:extend("Foo(Component)")
		function Foo:render()
			return React.createElement(Component)
		end
		local Bar = React.Component:extend("Bar(Foo(Component))")
		function Bar:render()
			return React.createElement(Foo)
		end

		act(function()
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			return root:render(React.createElement(Bar))
		end)

		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("1: mount")
		act(function()
			store:setComponentFilters({ utils.createHOCFilter(true) })
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		-- ROBLOX FIXME: still shows all components
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot("2: hide all HOCs")
		act(function()
			store:setComponentFilters({ utils.createHOCFilter(false) })
			return store:getComponentFilters()
		end)
		-- ROBLOX deviation: we use devtoolsUtils.printStore, upstream uses a jest serializer (storeSerializer) instead
		jestExpect(devtoolsUtils.printStore(store)).toMatchSnapshot(
			"3: disable HOC filter"
		)
	end)
	it(
		"should not send a bridge update if the set of enabled filters has not changed",
		function()
			act(function()
				store:setComponentFilters({ utils.createHOCFilter(true) })
				return store:getComponentFilters()
			end)
			bridge:addListener("updateComponentFilters", function(componentFilters)
				error("Unexpected component update")
			end)
			act(function()
				store:setComponentFilters({
					utils.createHOCFilter(false),
					utils.createHOCFilter(true),
				})
				return store:getComponentFilters()
			end)
			act(function()
				store:setComponentFilters({
					utils.createHOCFilter(true),
					utils.createLocationFilter("abc", false),
				})
				return store:getComponentFilters()
			end)
			act(function()
				store:setComponentFilters({
					utils.createHOCFilter(true),
					utils.createElementTypeFilter(Types.ElementTypeHostComponent, false),
				})
				return store:getComponentFilters()
			end)
		end
	)
end)
