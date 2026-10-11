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
				useLayoutEffect = React.useLayoutEffect
				startTransition = React.startTransition
			end)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L173-L210
			it("isPending works even if called from outside an input event", function()
				local start
				local function App()
					local show, setShow = useState(false)
					local isPending, startUpdate = useTransition()
					start = function()
						startUpdate(function()
							setShow(true)
						end)
					end
					return React.createElement(
						Suspense,
						{ fallback = React.createElement(Text, { text = "Loading..." }) },
						isPending and React.createElement(Text, { text = "Pending..." })
							or nil,
						if show
							then React.createElement(AsyncText, { text = "Async" })
							else React.createElement(Text, { text = "(empty)" })
					)
				end
				local root = ReactNoop.createRoot()
				ReactNoop.act(function()
					root.render(React.createElement(App))
				end)
				jestExpect(Scheduler).toHaveYielded({ "(empty)" })
				jestExpect(root).toMatchRenderedOutput("(empty)")
				ReactNoop.act(function()
					start()
					jestExpect(Scheduler).toFlushAndYield({
						"Pending...",
						"(empty)",
						"Suspend! [Async]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput("Pending...(empty)")
					resolveText("Async")
				end)
				jestExpect(Scheduler).toHaveYielded({ "Async" })
				jestExpect(root).toMatchRenderedOutput("Async")
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
							React.createElement(Suspense, {
								fallback = React.createElement("span", nil, "Loading A"),
							}, React.createElement(A)),
							React.createElement(Suspense, {
								fallback = React.createElement("span", nil, "Loading B"),
							}, React.createElement(B))
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

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L368-L520
			it(
				"when multiple transitions update different queues, but suspend the same boundary, they do entangle",
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
						return React.createElement(Suspense, {
							fallback = React.createElement("span", nil, "Loading..."),
						}, React.createElement(A), React.createElement(B))
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(React.createElement(App))
					end)
					-- ROBLOX DEVIATION: React 17 renders both siblings on the initial
					-- attempt. Upstream renders A, then prewarms A and B, adding a
					-- second "Suspend! [A: 0]" before "Suspend! [B: 0]".
					jestExpect(Scheduler).toHaveYielded({
						"Suspend! [A: 0]",
						"Suspend! [B: 0]",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement("span", nil, "Loading...")
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

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L522-L643
			it(
				"when multiple transitions update the same queue, only the most recent one is allowed to finish (no intermediate states)",
				function()
					local update
					local function App()
						local isContentPending, startContentChange = useTransition()
						local label, setLabel = useState("A")
						local contents, setContents = useState("A")
						update = function(value)
							ReactNoop.discreteUpdates(function()
								setLabel(value)
								startContentChange(function()
									setContents(value)
								end)
							end)
						end
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(Text, {
								text = label .. " label" .. (if isContentPending
									then " (loading...)"
									else ""),
							}),
							React.createElement(
								"div",
								nil,
								React.createElement(
									Suspense,
									{
										fallback = React.createElement(
											Text,
											{ text = "Loading..." }
										),
									},
									React.createElement(
										AsyncText,
										{ text = contents .. " content" }
									)
								)
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						-- ROBLOX DEVIATION: Seeding the per-test cache substitutes upstream
						-- seedNextTextCache; this case never refreshes a cache.
						resolveText("A content")
						root.render(React.createElement(App))
					end)
					jestExpect(Scheduler).toHaveYielded({ "A label", "A content" })
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"A label",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						update("B")
					end)
					-- ROBLOX DEVIATION: discreteUpdates retains InputDiscreteLanePriority,
					-- while optimistic pending uses SyncLane. The pending-only A render
					-- finishes before the discrete B label update; modern React uses
					-- SyncLane for both and combines these urgent renders.
					jestExpect(Scheduler).toHaveYielded({
						"A label (loading...)",
						"A content",
						"B label (loading...)",
						"A content",
						"B label",
						"Suspend! [B content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"B label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						update("C")
					end)
					jestExpect(Scheduler).toHaveYielded({
						"C label (loading...)",
						"A content",
						"C label",
						"Suspend! [C content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						resolveText("B content")
					end)
					jestExpect(Scheduler).toHaveYielded({
						"C label",
						"Suspend! [C content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						resolveText("C content")
					end)
					jestExpect(Scheduler).toHaveYielded({ "C label", "C content" })
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label",
							React.createElement("div", nil, "C content")
						)
					)
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L645-L765
			it(
				"when multiple transitions update the same queue, only the most recent one is allowed to finish (no intermediate states) (classes)",
				function()
					local update
					-- ROBLOX DEVIATION: Component:extend and init translate the
					-- upstream JavaScript class and state field.
					local App = React.Component:extend("App")
					function App:init()
						self.state = { label = "A", contents = "A" }
					end
					function App:render()
						update = function(value)
							ReactNoop.discreteUpdates(function()
								self:setState({ label = value })
								React.startTransition(function()
									self:setState({ contents = value })
								end)
							end)
						end
						local label = self.state.label
						local contents = self.state.contents
						local isContentPending = label ~= contents
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(Text, {
								text = label .. " label" .. (if isContentPending
									then " (loading...)"
									else ""),
							}),
							React.createElement(
								"div",
								nil,
								React.createElement(
									Suspense,
									{
										fallback = React.createElement(
											Text,
											{ text = "Loading..." }
										),
									},
									React.createElement(
										AsyncText,
										{ text = contents .. " content" }
									)
								)
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						-- ROBLOX DEVIATION: Seeding the per-test cache substitutes upstream
						-- seedNextTextCache; this case never refreshes a cache.
						resolveText("A content")
						root.render(React.createElement(App))
					end)
					jestExpect(Scheduler).toHaveYielded({ "A label", "A content" })
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"A label",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						update("B")
					end)
					jestExpect(Scheduler).toHaveYielded({
						"B label (loading...)",
						"A content",
						"B label",
						"Suspend! [B content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"B label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						update("C")
					end)
					jestExpect(Scheduler).toHaveYielded({
						"C label (loading...)",
						"A content",
						"C label",
						"Suspend! [C content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						resolveText("B content")
					end)
					jestExpect(Scheduler).toHaveYielded({
						"C label",
						"Suspend! [C content]",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label (loading...)",
							React.createElement("div", nil, "A content")
						)
					)
					ReactNoop.act(function()
						resolveText("C content")
					end)
					jestExpect(Scheduler).toHaveYielded({ "C label", "C content" })
					jestExpect(root).toMatchRenderedOutput(
						React.createElement(
							React.Fragment,
							nil,
							"C label",
							React.createElement("div", nil, "C content")
						)
					)
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L767-L872
			it(
				"when multiple transitions update overlapping queues, all the transitions across all the queues are entangled",
				function()
					local setShowA, setShowB, setShowC
					local function App()
						local showA, updateShowA = useState(false)
						local showB, updateShowB = useState(false)
						local showC, updateShowC = useState(false)
						setShowA, setShowB, setShowC =
							updateShowA, updateShowB, updateShowC
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								Suspense,
								{
									fallback = React.createElement(
										Text,
										{ text = "Loading..." }
									),
								},
								showA and React.createElement(AsyncText, { text = "A" })
									or nil,
								showB and React.createElement(AsyncText, { text = "B" })
									or nil,
								showC and React.createElement(AsyncText, { text = "C" })
									or nil
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(React.createElement(App))
					end)
					jestExpect(Scheduler).toHaveYielded({})
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							setShowA(true)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Suspend! [A]", "Loading..." })
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							setShowA(false)
							setShowB(true)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Suspend! [B]", "Loading..." })
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							setShowB(false)
							setShowC(true)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Suspend! [C]", "Loading..." })
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							resolveText("B")
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Suspend! [C]", "Loading..." })
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							resolveText("A")
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Suspend! [C]", "Loading..." })
					jestExpect(root).toMatchRenderedOutput(nil)
					ReactNoop.act(function()
						React.startTransition(function()
							resolveText("C")
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "C" })
					jestExpect(root).toMatchRenderedOutput("C")
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L874-L926
			it(
				"interrupt a refresh transition if a new transition is scheduled",
				function()
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(
							React.createElement(
								React.Fragment,
								nil,
								React.createElement(Suspense, {
									fallback = React.createElement(
										Text,
										{ text = "Loading..." }
									),
								}),
								React.createElement(Text, { text = "Initial" })
							)
						)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Initial" })
					jestExpect(root).toMatchRenderedOutput("Initial")
					ReactNoop.act(function()
						React.startTransition(function()
							root.render(
								React.createElement(
									React.Fragment,
									nil,
									React.createElement(Suspense, {
										fallback = React.createElement(
											Text,
											{ text = "Loading..." }
										),
									}, React.createElement(
										AsyncText,
										{ text = "Async" }
									)),
									React.createElement(Text, { text = "After Suspense" }),
									React.createElement(Text, { text = "Sibling" })
								)
							)
						end)
						jestExpect(Scheduler).toFlushAndYieldThrough({
							"Suspend! [Async]",
							"Loading...",
							"After Suspense",
						})
						-- ROBLOX DEVIATION: This upstream async transition callback has
						-- no await; its synchronous render body has the same scheduling.
						React.startTransition(function()
							root.render(
								React.createElement(
									React.Fragment,
									nil,
									React.createElement(Suspense, {
										fallback = React.createElement(
											Text,
											{ text = "Loading..." }
										),
									}),
									React.createElement(Text, { text = "Updated" })
								)
							)
						end)
					end)
					jestExpect(Scheduler).toHaveYielded({ "Updated" })
					jestExpect(root).toMatchRenderedOutput("Updated")
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L928-L1020
			it(
				"interrupt a refresh transition when something suspends and we've already bailed out on another transition in a parent",
				function()
					local setShouldSuspend, setShouldHideInParent
					local function Parent(props)
						local shouldHideInParent, updateShouldHideInParent =
							useState(false)
						setShouldHideInParent = updateShouldHideInParent
						Scheduler.unstable_yieldValue(
							"shouldHideInParent: " .. tostring(shouldHideInParent)
						)
						if shouldHideInParent then
							return React.createElement(Text, { text = "(empty)" })
						end
						return props.children
					end
					local function App()
						local shouldSuspend, updateShouldSuspend = useState(false)
						setShouldSuspend = updateShouldSuspend
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(Text, { text = "A" }),
							React.createElement(
								Parent,
								nil,
								React.createElement(
									Suspense,
									{
										fallback = React.createElement(
											Text,
											{ text = "Loading..." }
										),
									},
									shouldSuspend
											and React.createElement(
												AsyncText,
												{ text = "Async" }
											)
										or nil
								)
							),
							React.createElement(Text, { text = "B" }),
							React.createElement(Text, { text = "C" })
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(React.createElement(App))
						jestExpect(Scheduler).toFlushAndYield({
							"A",
							"shouldHideInParent: false",
							"B",
							"C",
						})
						jestExpect(root).toMatchRenderedOutput("ABC")
						React.startTransition(function()
							setShouldSuspend(true)
						end)
						jestExpect(Scheduler).toFlushAndYieldThrough({ "A" })
						React.startTransition(function()
							setShouldHideInParent(true)
						end)
						jestExpect(Scheduler).toFlushAndYieldThrough({
							"shouldHideInParent: false",
							"Suspend! [Async]",
							"Loading...",
							"B",
						})
						jestExpect(root).toMatchRenderedOutput("ABC")
						jestExpect(Scheduler).toFlushUntilNextPaint({
							"shouldHideInParent: true",
							"(empty)",
						})
						jestExpect(root).toMatchRenderedOutput("A(empty)BC")
						jestExpect(Scheduler).toFlushAndYield({
							"A",
							"shouldHideInParent: true",
							"(empty)",
							"B",
							"C",
						})
						jestExpect(root).toMatchRenderedOutput("A(empty)BC")
					end)
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L1022-L1093
			it(
				"interrupt a refresh transition when something suspends and a parent component received an interleaved update after its queue was processed",
				function()
					local function App(props)
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								Text,
								{ text = "A" .. tostring(props.step) }
							),
							React.createElement(
								Suspense,
								{
									fallback = React.createElement(
										Text,
										{ text = "Loading..." }
									),
								},
								props.shouldSuspend
										and React.createElement(
											AsyncText,
											{ text = "Async" }
										)
									or nil
							),
							React.createElement(
								Text,
								{ text = "B" .. tostring(props.step) }
							),
							React.createElement(
								Text,
								{ text = "C" .. tostring(props.step) }
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(
							React.createElement(App, { shouldSuspend = false, step = 0 })
						)
					end)
					jestExpect(Scheduler).toHaveYielded({ "A0", "B0", "C0" })
					jestExpect(root).toMatchRenderedOutput("A0B0C0")
					ReactNoop.act(function()
						React.startTransition(function()
							root.render(
								React.createElement(
									App,
									{ shouldSuspend = true, step = 1 }
								)
							)
						end)
						jestExpect(Scheduler).toFlushAndYieldThrough({ "A1" })
						React.startTransition(function()
							root.render(
								React.createElement(
									App,
									{ shouldSuspend = false, step = 2 }
								)
							)
						end)
						jestExpect(Scheduler).toFlushAndYieldThrough({
							"Suspend! [Async]",
							"Loading...",
							"B1",
						})
						jestExpect(root).toMatchRenderedOutput("A0B0C0")
						jestExpect(Scheduler).toFlushAndYield({ "A2", "B2", "C2" })
						jestExpect(root).toMatchRenderedOutput("A2B2C2")
					end)
				end
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
							{
								fallback = React.createElement(
									Text,
									{ text = "Loading..." }
								),
							},
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
					jestExpect(root).toMatchRenderedOutput(
						"Transition pri: 0, Normal pri: 0"
					)

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
					jestExpect(root).toMatchRenderedOutput(
						"Transition pri: 1, Normal pri: 1"
					)
				end
			)

			-- ROBLOX upstream: https://github.com/facebook/react/blob/1d34f91dfde6bba84d08b683aaba164c7194dacb/packages/react-reconciler/src/__tests__/ReactTransition-test.js#L1150-L1223
			it(
				"should render normal pri updates before transition suspense retries",
				function()
					local updateTransitionPri, updateNormalPri
					local function App()
						local transitionPri, setTransitionPri = useState(false)
						local normalPri, setNormalPri = useState(0)
						updateTransitionPri = function()
							React.startTransition(function()
								setTransitionPri(true)
							end)
						end
						updateNormalPri = function()
							setNormalPri(function(value)
								return value + 1
							end)
						end
						useLayoutEffect(function()
							Scheduler.unstable_yieldValue("Commit")
						end)
						return React.createElement(
							Suspense,
							{
								fallback = React.createElement(
									Text,
									{ text = "Loading..." }
								),
							},
							if transitionPri
								then React.createElement(AsyncText, { text = "Async" })
								else React.createElement(Text, { text = "(empty)" }),
							", ",
							React.createElement(
								Text,
								{ text = "Normal pri: " .. tostring(normalPri) }
							)
						)
					end
					local root = ReactNoop.createRoot()
					ReactNoop.act(function()
						root.render(React.createElement(App))
					end)
					jestExpect(Scheduler).toHaveYielded({
						"(empty)",
						"Normal pri: 0",
						"Commit",
					})
					jestExpect(root).toMatchRenderedOutput("(empty), Normal pri: 0")
					ReactNoop.act(function()
						updateTransitionPri()
					end)
					-- ROBLOX DEVIATION: React 17 visits the normal-priority sibling in
					-- the original attempt; React 19 visits it during prewarming.
					jestExpect(Scheduler).toHaveYielded({
						"Suspend! [Async]",
						"Normal pri: 0",
						"Loading...",
					})
					jestExpect(root).toMatchRenderedOutput("(empty), Normal pri: 0")
					ReactNoop.act(function()
						resolveText("Async")
						updateNormalPri()
					end)
					jestExpect(Scheduler).toHaveYielded({
						"(empty)",
						"Normal pri: 1",
						"Commit",
						"Async",
						"Normal pri: 1",
						"Commit",
					})
					jestExpect(root).toMatchRenderedOutput("Async, Normal pri: 1")
				end
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
	end
end)
