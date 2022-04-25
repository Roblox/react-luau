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
	local jest = require(Packages.Dev.JestGlobals).jest

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

		it("Can drive change and event signals from a ref", function()
			local ref = React.createRef()
			local textCallback = jest.fn()
			local clickCallback = jest.fn()

			local RootComponent = React.Component:extend("RootComponent")

			function RootComponent:render()
				return React.createElement("Frame", {}, {
					B = React.createElement("Frame", {
						ref = self.props.childRef,
						[React.Change.Text] = self.props.textCallback,
						[React.Event.Activated] = self.props.clickCallback,
					})
				})
			end

			local renderer = ReactTestRenderer.create(React.createElement(RootComponent, {
				childRef = ref,
				textCallback = textCallback,
				clickCallback = clickCallback,
			}), {
				createNodeMock = function(element)
					return element
				end
			})

			ref.current.props[React.Change.Text]("Changed Text")
			jestExpect(textCallback).toHaveBeenCalledWith("Changed Text")

			ref.current.props[React.Event.Activated]()
			ref.current.props[React.Event.Activated]()
			jestExpect(clickCallback).toHaveBeenCalledTimes(2)

			renderer.unmount()
			jestExpect(ref.current).never.toBeDefined()
		end)

		it("Collects tagged instances", function()
			local renderer = ReactTestRenderer.create(React.createElement("div", {
				Name = "A",
				[React.Tag] = "foo",
				key = "A"
			}, {
				B = React.createElement("div", {
					[React.Tag] = "foo",
				}),
				C = React.createElement("div", {
					[React.Tag] = "bar,foo",
				}),
				D = React.createElement("div", {
					[React.Tag] = "bar,foo",
				}, {
					E = React.createElement("div", {
						[React.Tag] = "bar",
					})
				})
			}))

			local barInstances = renderer.getInstancesForTag("bar")
			jestExpect(#barInstances).toEqual(3)

			local fooInstances = renderer.getInstancesForTag("foo")
			jestExpect(#fooInstances).toEqual(4)

			local bazInstances = renderer.getInstancesForTag("baz")
			jestExpect(#bazInstances).toEqual(0)

			-- Should update tags when components update
			renderer.update(React.createElement("div", {
				Name = "A",
				[React.Tag] = "foo",
				key = "A"
			}, {
				B = React.createElement("div", {
					[React.Tag] = "bar,baz",
				}),
				C = React.createElement("div", {
					[React.Tag] = "baz",
				}),
			}))

			fooInstances = renderer.getInstancesForTag("foo")
			jestExpect(#fooInstances).toEqual(1)

			barInstances = renderer.getInstancesForTag("bar")
			jestExpect(#barInstances).toEqual(1)

			bazInstances = renderer.getInstancesForTag("baz")
			jestExpect(#bazInstances).toEqual(2)

			-- Should remove tags when unmounting
			renderer.unmount()
			fooInstances = renderer.getInstancesForTag("foo")
			jestExpect(#fooInstances).toEqual(0)

			barInstances = renderer.getInstancesForTag("bar")
			jestExpect(#barInstances).toEqual(0)

			bazInstances = renderer.getInstancesForTag("baz")
			jestExpect(#bazInstances).toEqual(0)
		end)
	end)
end
