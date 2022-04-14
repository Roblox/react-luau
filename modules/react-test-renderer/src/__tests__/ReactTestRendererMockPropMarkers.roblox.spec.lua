-- Upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-test-renderer/src/__tests__/ReactTestRenderer-test.internal.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

-- !strict
local Packages = script.Parent.Parent.Parent

local React
local ReactTestRenderer

local RobloxJest

return function()
	RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	describe("ReactTestRenderer", function()
		beforeEach(function()
			RobloxJest.resetModules()

			React = require(Packages.React)
			ReactTestRenderer = require(Packages.ReactTestRenderer)
		end)
		it("renders a component with React.Change, React.Event, React.Tag props", function()
			local onTextChangedCallback = function()

			end

			local onActivated = function()

			end

			local function Link()
				return React.createElement("a", {
					role = "link",
					[React.Change.Text] = onTextChangedCallback,
					[React.Event.Activated] = onActivated,
					[React.Tag] = "componentA",
				})
			end

			local renderer = ReactTestRenderer.create(React.createElement(Link))

			jestExpect(renderer.toJSON()).toEqual({
				type = "a",
				props = {
					role = "link",
					[React.Change.Text] = onTextChangedCallback,
					[React.Event.Activated] = onActivated,
					[React.Tag] = "componentA",
				},
				children = nil,
			})
		end)
	end)
end
