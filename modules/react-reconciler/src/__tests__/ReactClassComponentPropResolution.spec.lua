-- ROBLOX upstream: https://github.com/facebook/react/blob/v19.0.0/packages/react-reconciler/src/__tests__/ReactClassComponentPropResolution-test.js
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

local React
local ReactNoop
local Scheduler
local Object

-- ROBLOX DEVIATION: React-Luau records Scheduler logs with
-- unstable_yieldValue/toHaveYielded, and ReactNoop.act is synchronous.
describe("ReactClassComponentPropResolution", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Dev.Scheduler)
		Object = require(Packages.LuauPolyfill).Object
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	it("resolves ref and default props before calling lifecycle methods", function()
		local root = ReactNoop.createRoot()
		local function getPropKeys(props)
			local keys = Object.keys(props)
			-- ROBLOX DEVIATION: Luau table iteration order is unspecified.
			table.sort(keys)
			return table.concat(keys, ", ")
		end

		local Component = React.Component:extend("Component")
		-- ROBLOX DEVIATION: React-Luau class constructors are init methods and
		-- receive their props through self.props.
		function Component:init()
			Scheduler.unstable_yieldValue("constructor: " .. getPropKeys(self.props))
		end
		function Component:shouldComponentUpdate(props)
			Scheduler.unstable_yieldValue(
				"shouldComponentUpdate (prev props): " .. getPropKeys(self.props)
			)
			Scheduler.unstable_yieldValue(
				"shouldComponentUpdate (next props): " .. getPropKeys(props)
			)
			return true
		end
		function Component:componentDidUpdate(props)
			Scheduler.unstable_yieldValue(
				"componentDidUpdate (prev props): " .. getPropKeys(props)
			)
			Scheduler.unstable_yieldValue(
				"componentDidUpdate (next props): " .. getPropKeys(self.props)
			)
			return true
		end
		function Component:componentDidMount()
			Scheduler.unstable_yieldValue(
				"componentDidMount: " .. getPropKeys(self.props)
			)
			return true
		end
		function Component:UNSAFE_componentWillMount()
			Scheduler.unstable_yieldValue(
				"componentWillMount: " .. getPropKeys(self.props)
			)
		end
		function Component:UNSAFE_componentWillReceiveProps(nextProps)
			Scheduler.unstable_yieldValue(
				"componentWillReceiveProps (prev props): " .. getPropKeys(self.props)
			)
			Scheduler.unstable_yieldValue(
				"componentWillReceiveProps (next props): " .. getPropKeys(nextProps)
			)
		end
		function Component:UNSAFE_componentWillUpdate(nextProps)
			Scheduler.unstable_yieldValue(
				"componentWillUpdate (prev props): " .. getPropKeys(self.props)
			)
			Scheduler.unstable_yieldValue(
				"componentWillUpdate (next props): " .. getPropKeys(nextProps)
			)
		end
		function Component:componentWillUnmount()
			Scheduler.unstable_yieldValue(
				"componentWillUnmount: " .. getPropKeys(self.props)
			)
		end
		function Component:render()
			return React.createElement(Text, {
				text = "render: " .. getPropKeys(self.props),
			})
		end
		Component.defaultProps = {
			default = "yo",
		}

		-- `ref` should never appear as a prop. `default` always should.

		-- Mount
		local ref = React.createRef()
		ReactNoop.act(function()
			root.render(React.createElement(Component, { text = "Yay", ref = ref }))
		end)
		jestExpect(Scheduler).toHaveYielded({
			"constructor: default, text",
			"componentWillMount: default, text",
			"render: default, text",
			"componentDidMount: default, text",
		})
		-- Update
		ReactNoop.act(function()
			root.render(
				React.createElement(Component, { text = "Yay (again)", ref = ref })
			)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"componentWillReceiveProps (prev props): default, text",
			"componentWillReceiveProps (next props): default, text",
			"shouldComponentUpdate (prev props): default, text",
			"shouldComponentUpdate (next props): default, text",
			"componentWillUpdate (prev props): default, text",
			"componentWillUpdate (next props): default, text",
			"render: default, text",
			"componentDidUpdate (prev props): default, text",
			"componentDidUpdate (next props): default, text",
		})
		-- Unmount
		ReactNoop.act(function()
			root.render(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "componentWillUnmount: default, text" })
	end)
end)
