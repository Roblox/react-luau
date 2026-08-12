-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactTransition-test.js
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
local React
local ReactNoop
local Scheduler
local Suspense
local useLayoutEffect
local useState
local startTransition

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

describe("ReactTransition", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		Suspense = React.Suspense
		useLayoutEffect = React.useLayoutEffect
		useState = React.useState
		startTransition = React.startTransition
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	-- ROBLOX deviation: These upstream tests require the unimplemented cache API.
	it.skip("isPending works even if called from outside an input event", function() end)
	it.skip(
		"when multiple transitions update the same queue, only the most recent one is allowed to finish (no intermediate states)",
		function() end
	)
	it.skip(
		"when multiple transitions update the same queue, only the most recent one is allowed to finish (no intermediate states) (classes)",
		function() end
	)
	it.skip(
		"when multiple transitions update overlapping queues, all the transitions across all the queues are entangled",
		function() end
	)
	it.skip(
		"interrupt a refresh transition if a new transition is scheduled",
		function() end
	)
	it.skip(
		"interrupt a refresh transition when something suspends and we've already bailed out on another transition in a parent",
		function() end
	)
	it.skip(
		"interrupt a refresh transition when something suspends and a parent component received an interleaved update after its queue was processed",
		function() end
	)

	it(
		"should render normal pri updates scheduled after transitions before transitions",
		function()
			local updateTransitionPri
			local updateNormalPri
			local function App()
				local normalPri, setNormalPri = useState(0)
				local transitionPri, setTransitionPri = useState(0)
				updateTransitionPri = function()
					startTransition(function()
						setTransitionPri(function(n)
							return n + 1
						end)
					end)
				end
				updateNormalPri = function()
					setNormalPri(function(n)
						return n + 1
					end)
				end
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Commit")
				end)

				return React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(Text, {
						text = "Transition pri: " .. tostring(transitionPri),
					}),
					", ",
					React.createElement(Text, {
						text = "Normal pri: " .. tostring(normalPri),
					})
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Transition pri: 0",
				"Normal pri: 0",
				"Commit",
			})
			jestExpect(root).toMatchRenderedOutput("Transition pri: 0, Normal pri: 0")

			ReactNoop.act(function()
				updateTransitionPri()
				updateNormalPri()
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Transition pri: 0",
				"Normal pri: 1",
				"Commit",
				"Transition pri: 1",
				"Normal pri: 1",
				"Commit",
			})
			jestExpect(root).toMatchRenderedOutput("Transition pri: 1, Normal pri: 1")
		end
	)

	-- ROBLOX deviation: This upstream test requires the unimplemented cache API.
	it.skip(
		"should render normal pri updates before transition suspense retries",
		function() end
	)

	it("should not interrupt transitions with normal pri updates", function()
		local updateNormalPri
		local updateTransitionPri
		local function App()
			local transitionPri, setTransitionPri = useState(0)
			local normalPri, setNormalPri = useState(0)
			updateTransitionPri = function()
				startTransition(function()
					setTransitionPri(function(n)
						return n + 1
					end)
				end)
			end
			updateNormalPri = function()
				setNormalPri(function(n)
					return n + 1
				end)
			end
			useLayoutEffect(function()
				Scheduler.unstable_yieldValue("Commit")
			end)

			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Text, {
					text = "Transition pri: " .. tostring(transitionPri),
				}),
				", ",
				React.createElement(Text, {
					text = "Normal pri: " .. tostring(normalPri),
				})
			)
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Transition pri: 0",
			"Normal pri: 0",
			"Commit",
		})
		jestExpect(root).toMatchRenderedOutput("Transition pri: 0, Normal pri: 0")

		ReactNoop.act(function()
			updateTransitionPri()
			jestExpect(Scheduler).toFlushAndYieldThrough({ "Transition pri: 1" })
			updateNormalPri()
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Normal pri: 0",
			"Commit",
			"Transition pri: 1",
			"Normal pri: 1",
			"Commit",
		})
		jestExpect(root).toMatchRenderedOutput("Transition pri: 1, Normal pri: 1")
	end)
end)
