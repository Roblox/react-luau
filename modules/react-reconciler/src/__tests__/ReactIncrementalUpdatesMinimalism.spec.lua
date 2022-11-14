-- Upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncrementalUpdatesMinimalism-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
 --]]
--!strict
local React
local ReactNoop
local Packages = script.Parent.Parent.Parent
local jest
return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	describe("ReactIncrementalUpdatesMinimalism", function()
		jest = require(Packages.Dev.RobloxJest)
		beforeEach(function()
			jest.resetModules()
			React = require(Packages.React)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		end)
		it("should render a simple component", function()
			local function Child()
				return React.createElement("div", nil, "Hello World")
			end
			local function Parent()
				return React.createElement(Child)
			end

			ReactNoop.render(React.createElement(Parent))
			local x = ReactNoop.flushWithHostCounters()
			jestExpect(x).toEqual({
				hostDiffCounter = 0,
				hostUpdateCounter = 0,
			})
			ReactNoop.render(React.createElement(Parent))
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				hostDiffCounter = 1,
				hostUpdateCounter = 1,
			})
		end)
		it("should not diff referentially equal host elements", function()
			local function Leaf(props)
				return React.createElement(
					"span",
					nil,
					"hello",
					React.createElement("b"),
					props.name
				)
			end

			local constEl = React.createElement(
				"div",
				nil,
				React.createElement(Leaf, {
					name = "world",
				})
			)

			local function Child()
				return constEl
			end
			local function Parent()
				return React.createElement(Child)
			end

			ReactNoop.render(React.createElement(Parent))
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				hostDiffCounter = 0,
				hostUpdateCounter = 0,
			})
			ReactNoop.render(React.createElement(Parent))
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				hostDiffCounter = 0,
				hostUpdateCounter = 0,
			})
		end)
		it("should not diff parents of setState targets", function()
			local childInst

			local function Leaf(props)
				return React.createElement(
					"span",
					nil,
					"hello",
					React.createElement("b"),
					props.name
				)
			end

			local Child = React.Component:extend("Child")
			function Child:init()
				self.state = { name = "Batman" }
			end
			function Child:render()
				childInst = self
				return React.createElement(
					"div",
					nil,
					React.createElement(Leaf, { name = self.state.name })
				)
			end

			local function Parent()
				return React.createElement(
					"section",
					nil,
					React.createElement(
						"div",
						nil,
						React.createElement(Leaf, {
							name = "world",
						}),
						React.createElement(Child),
						React.createElement("hr"),
						React.createElement(Leaf, {
							name = "world",
						})
					)
				)
			end

			ReactNoop.render(React.createElement(Parent))
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				hostDiffCounter = 0,
				hostUpdateCounter = 0,
			})
			childInst:setState({
				name = "Robin",
			})
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				-- Child > div
				-- Child > Leaf > span
				-- Child > Leaf > span > b
				hostDiffCounter = 3,
				-- Child > div
				-- Child > Leaf > span
				-- Child > Leaf > span > b
				-- Child > Leaf > span > #text
				hostUpdateCounter = 4,
			})
			ReactNoop.render(React.createElement(Parent))
			jestExpect(ReactNoop.flushWithHostCounters()).toEqual({
				-- Parent > section
				-- Parent > section > div
				-- Parent > section > div > Leaf > span
				-- Parent > section > div > Leaf > span > b
				-- Parent > section > div > Child > div
				-- Parent > section > div > Child > div > Leaf > span
				-- Parent > section > div > Child > div > Leaf > span > b
				-- Parent > section > div > hr
				-- Parent > section > div > Leaf > span
				-- Parent > section > div > Leaf > span > b
				hostDiffCounter = 10,
				hostUpdateCounter = 10,
			})
		end)
	end)
end
