-- upstream: https://github.com/facebook/react/blob/d7dce572c7453737a685e791e7afcbc7e2b2fe16/packages/react-reconciler/src/__tests__/ReactClassSetStateCallback-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

--[[ eslint-disable no-func-assign ]]
local Packages = script.Parent.Parent.Parent
local React

local ReactNoop
local Scheduler

return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.useFakeTimers()

		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return React.createElement("span", {
			prop = props.text,
		})
	end

	it(
		"regression: setState callback (2nd arg) should only fire once, even after a rebase",
		function()
			local app
			local App = React.Component:extend("App")
			function App:init()
				self:setState({ step = 0 })
			end
			function App:render()
				app = self
				return React.createElement(Text, { text = self.state.step })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ 0 })

			ReactNoop.act(function()
				app:setState({ step = 1 }, function()
					return Scheduler.unstable_yieldValue("Callback 1")
				end)

				ReactNoop.flushSync(function()
					app:setState({ step = 2 }, function()
						return Scheduler.unstable_yieldValue("Callback 2")
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ 2, "Callback 2", 2, "Callback 1" })
		end
	)
end
