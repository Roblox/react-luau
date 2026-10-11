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
local useTransition
local textCache

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
		useTransition = React.useTransition
		textCache = {}
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	-- ROBLOX DEVIATION: React-Luau has no unstable_getCacheForType. These cases
	-- keep one cache per test; they never refresh or compare cache versions.
	local function resolveText(text)
		local record = textCache[text]
		if record == nil then
			textCache[text] = { status = "resolved", value = text }
		elseif record.status == "pending" then
			record.status = "resolved"
			record.value = text
			for _, ping in record.pings do
				ping()
			end
		end
	end

	local function AsyncText(props)
		local text = props.text
		local record = textCache[text]
		if record == nil then
			record = { status = "pending", pings = {} }
			-- ROBLOX DEVIATION: Luau thenables expose andThen, not then.
			record.value = {
				andThen = function(_self, resolve)
					if record.status == "pending" then
						table.insert(record.pings, resolve)
					else
						resolve(record.value)
					end
				end,
			}
			textCache[text] = record
		end
		if record.status == "pending" then
			Scheduler.unstable_yieldValue("Suspend! [" .. text .. "]")
			error(record.value)
		end
		Scheduler.unstable_yieldValue(text)
		return text
	end

	-- ROBLOX deviation: These upstream tests require the unimplemented cache API.
	it.skip("isPending works even if called from outside an input event", function() end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L212-L366
	-- ROBLOX DEVIATION: Upstream gate variants become nested suites. React 17
	-- synchronous act and Scheduler yield matchers replace async act/assertLog.
	for _, parallelTransitions in { false, true } do
		describe("enableParallelTransitions=" .. tostring(parallelTransitions), function()
			beforeEach(function()
				jest.resetModules()
				require(Packages.Shared).ReactFeatureFlags.enableParallelTransitions =
					parallelTransitions
				React = require(Packages.React)
				ReactNoop = require(Packages.Dev.ReactNoopRenderer)
				Scheduler = require(Packages.Scheduler)
				Suspense = React.Suspense
				useState = React.useState
				useTransition = React.useTransition
			end)

			it(
				"when multiple transitions update different queues, they entangle",
				function()
					local setA, startTransitionA, setB, startTransitionB
					local function A()
						local a, updateA = useState(0)
						local isPending, startA = useTransition()
						setA, startTransitionA = updateA, startA
						return React.createElement(
							"span",
							nil,
							isPending
									and React.createElement(
										"span",
										nil,
										React.createElement(
											Text,
											{ text = "Pending A..." }
										)
									)
								or nil,
							React.createElement(
								AsyncText,
								{ text = "A: " .. tostring(a) }
							)
						)
					end
					local function B()
						local b, updateB = useState(0)
						local isPending, startB = useTransition()
						setB, startTransitionB = updateB, startB
						return React.createElement(
							"span",
							nil,
							isPending
									and React.createElement(
										"span",
										nil,
										React.createElement(
											Text,
											{ text = "Pending B..." }
										)
									)
								or nil,
							React.createElement(
								AsyncText,
								{ text = "B: " .. tostring(b) }
							)
						)
					end
					local function App()
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								Suspense,
								{
									fallback = React.createElement(
										"span",
										nil,
										"Loading A"
									),
								},
								React.createElement(A)
							),
							React.createElement(
								Suspense,
								{
									fallback = React.createElement(
										"span",
										nil,
										"Loading B"
									),
								},
								React.createElement(B)
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(React.createElement(App))
					end)
					-- ROBLOX DEVIATION: React 17 has no sibling prewarming; upstream
					-- repeats both suspension yields after these first two yields.
					jestExpect(Scheduler).toHaveYielded({
						"Suspend! [A: 0]",
						"Suspend! [B: 0]",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement("span", nil, "Loading A"),
							React.createElement("span", nil, "Loading B")
						)
					)
					ReactNoop.act(function()
						resolveText("A: 0")
						resolveText("B: 0")
					end)
					jestExpect(Scheduler).toHaveYielded({ "A: 0", "B: 0" })
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement("span", nil, "A: 0"),
							React.createElement("span", nil, "B: 0")
						)
					)
					ReactNoop.act(function()
						startTransitionA(function()
							setA(1)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({
						"Pending A...",
						"A: 0",
						"Suspend! [A: 1]",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								"span",
								nil,
								React.createElement("span", nil, "Pending A..."),
								"A: 0"
							),
							React.createElement("span", nil, "B: 0")
						)
					)
					ReactNoop.act(function()
						startTransitionB(function()
							setB(1)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({
						"Pending B...",
						"B: 0",
						"Suspend! [A: 1]",
						"Suspend! [B: 1]",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								"span",
								nil,
								React.createElement("span", nil, "Pending A..."),
								"A: 0"
							),
							React.createElement(
								"span",
								nil,
								React.createElement("span", nil, "Pending B..."),
								"B: 0"
							)
						)
					)
					ReactNoop.act(function()
						resolveText("B: 1")
					end)
					jestExpect(Scheduler).toHaveYielded(
						if parallelTransitions
							then { "B: 1", "Suspend! [A: 1]" }
							else { "Suspend! [A: 1]", "B: 1" }
					)
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								"span",
								nil,
								React.createElement("span", nil, "Pending A..."),
								"A: 0"
							),
							if parallelTransitions
								then React.createElement("span", nil, "B: 1")
								else React.createElement(
									"span",
									nil,
									React.createElement("span", nil, "Pending B..."),
									"B: 0"
								)
						)
					)
					ReactNoop.act(function()
						resolveText("A: 1")
					end)
					jestExpect(Scheduler).toHaveYielded(
						if parallelTransitions then { "A: 1" } else { "A: 1", "B: 1" }
					)
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement("span", nil, "A: 1"),
							React.createElement("span", nil, "B: 1")
						)
					)
				end
			)
		end)
	end
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
