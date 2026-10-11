-- ROBLOX upstream: https://github.com/facebook/react/blob/22edb9f777d27369fd2c1fad378f74e237b6dfd3/packages/react-reconciler/src/__tests__/ReactDeferredValue-test.js
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/ReactDeferredValue-test.js#L374-L697
-- ROBLOX DEVIATION: React 17 does not implement React 19.2 sibling prewarming, so the corresponding duplicate suspension logs are omitted.
-- ROBLOX DEVIATION: React 17's ReactNoop.act is synchronous; upstream async
-- act and wait helpers translate to inline Scheduler flush matchers.
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler
local startTransition
local useDeferredValue
local useMemo
local useState
local Suspense
local textCache

local JestGlobals = require(Packages.Dev.JestGlobals)
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

local function renderedOutput(originalValue, deferredValue)
	return React.createElement(
		"div",
		nil,
		React.createElement("div", nil, "Original: " .. tostring(originalValue)),
		React.createElement("div", nil, "Deferred: " .. tostring(deferredValue))
	)
end

describe("ReactDeferredValue", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		startTransition = React.startTransition
		useDeferredValue = React.useDeferredValue
		useMemo = React.useMemo
		useState = React.useState
		Suspense = React.Suspense
		textCache = {}
	end)

	-- ROBLOX DEVIATION: Handler regressions flush React 17's JND timer; always
	-- restore real timers, including when an assertion fails.
	afterEach(function()
		jest.useRealTimers()
	end)

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

	local function readText(text)
		local record = textCache[text]
		if record ~= nil then
			if record.status == "pending" then
				Scheduler.unstable_yieldValue("Suspend! [" .. text .. "]")
				error(record.value)
			elseif record.status == "rejected" then
				error(record.value)
			else
				return record.value
			end
		end

		Scheduler.unstable_yieldValue("Suspend! [" .. text .. "]")
		local newRecord
		local wakeable = {
			-- ROBLOX DEVIATION: Luau thenables use andThen and invoke an already
			-- resolved continuation synchronously in this test fixture.
			andThen = function(_self, resolve)
				if newRecord.status == "pending" then
					table.insert(newRecord.pings, resolve)
				else
					resolve(newRecord.value)
				end
			end,
		}
		newRecord = { pings = {}, status = "pending", value = wakeable }
		textCache[text] = newRecord
		error(wakeable)
	end

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	local function AsyncText(props)
		readText(props.text)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	local function createChildren(value, deferredValue)
		local child = useMemo(function()
			return React.createElement(Text, {
				text = "Original: " .. tostring(value),
			})
		end, { value })
		local deferredChild = useMemo(function()
			return React.createElement(Text, {
				text = "Deferred: " .. tostring(deferredValue),
			})
		end, { deferredValue })

		return React.createElement(
			"div",
			nil,
			React.createElement("div", nil, child),
			React.createElement("div", nil, deferredChild)
		)
	end

	local function runDeferredValueSequence(App)
		local root = ReactNoop.createRoot()

		ReactNoop.act(function()
			root.render(React.createElement(App, { value = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Original: 1", "Deferred: 1" })

		ReactNoop.act(function()
			root.render(React.createElement(App, { value = 2 }))
			jestExpect(Scheduler).toFlushUntilNextPaint({ "Original: 2" })
			jestExpect(Scheduler).toFlushUntilNextPaint({ "Deferred: 2" })
		end)
		jestExpect(root).toMatchRenderedOutput(renderedOutput(2, 2))

		ReactNoop.act(function()
			startTransition(function()
				root.render(React.createElement(App, { value = 3 }))
			end)
			jestExpect(Scheduler).toFlushUntilNextPaint({
				"Original: 3",
				"Deferred: 3",
			})
		end)
		jestExpect(root).toMatchRenderedOutput(renderedOutput(3, 3))
	end

	it(
		"does not cause an infinite defer loop if the original value isn't memoized",
		function()
			local function App(props)
				local deferredObject = useDeferredValue({ value = props.value })
				return createChildren(props.value, deferredObject.value)
			end

			runDeferredValueSequence(App)
		end
	)

	it("does not defer during a transition", function()
		local function App(props)
			local deferredValue = useDeferredValue(props.value)
			return createChildren(props.value, deferredValue)
		end

		runDeferredValueSequence(App)
	end)

	it("works if there's a render phase update", function()
		local function App(props)
			local value, setValue = useState(nil)
			if value ~= props.value then
				setValue(props.value)
			end

			local deferredValue = useDeferredValue(value)
			return createChildren(value, deferredValue)
		end

		runDeferredValueSequence(App)
	end)

	it(
		"regression test: during urgent update, reuse previous value, not initial value",
		function()
			local function App(props)
				local value, setValue = useState(nil)
				if value ~= props.value then
					setValue(props.value)
				end

				local deferredValue = useDeferredValue(value)
				return createChildren(value, deferredValue)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { value = 1 }))
				jestExpect(Scheduler).toFlushUntilNextPaint({
					"Original: 1",
					"Deferred: 1",
				})
				jestExpect(root).toMatchRenderedOutput(renderedOutput(1, 1))
			end)

			ReactNoop.act(function()
				startTransition(function()
					root.render(React.createElement(App, { value = 2 }))
				end)
				jestExpect(Scheduler).toFlushUntilNextPaint({
					"Original: 2",
					"Deferred: 2",
				})
				jestExpect(root).toMatchRenderedOutput(renderedOutput(2, 2))
			end)

			ReactNoop.act(function()
				root.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushUntilNextPaint({ "Original: 3" })
				jestExpect(root).toMatchRenderedOutput(renderedOutput(3, 2))
				jestExpect(Scheduler).toFlushUntilNextPaint({ "Deferred: 3" })
				jestExpect(root).toMatchRenderedOutput(renderedOutput(3, 3))
			end)
		end
	)

	it("supports initialValue argument", function()
		local function App()
			local value = useDeferredValue("Final", "Initial")
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
			jestExpect(Scheduler).toFlushUntilNextPaint({ "Initial" })
			jestExpect(root).toMatchRenderedOutput("Initial")
		end)
		jestExpect(Scheduler).toHaveYielded({ "Final" })
		jestExpect(root).toMatchRenderedOutput("Final")
	end)

	it(
		"defers during initial render when initialValue is provided, even if render is not sync",
		function()
			local function App()
				local value = useDeferredValue("Final", "Initial")
				return React.createElement(Text, { text = value })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				startTransition(function()
					root.render(React.createElement(App))
				end)
				jestExpect(Scheduler).toFlushUntilNextPaint({ "Initial" })
				jestExpect(root).toMatchRenderedOutput("Initial")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"if a suspended render spawns a deferred task, we can switch to the deferred task without finishing the original one (no Suspense boundary)",
		function()
			local function App()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Loading...]",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput(nil)

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			jestExpect(root).toMatchRenderedOutput("Final")

			ReactNoop.act(function()
				resolveText("Loading...")
			end)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"if a suspended render spawns a deferred task, we can switch to the deferred task without finishing the original one (no Suspense boundary, synchronous parent update)",
		function()
			local function App()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				ReactNoop.flushSync(function()
					root.render(React.createElement(App))
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Loading...]",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput(nil)

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			jestExpect(root).toMatchRenderedOutput("Final")

			ReactNoop.act(function()
				resolveText("Loading...")
			end)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"if a suspended render spawns a deferred task, we can switch to the deferred task without finishing the original one (Suspense boundary)",
		function()
			local function App()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(
						Suspense,
						{ fallback = React.createElement(Text, { text = "Fallback" }) },
						React.createElement(App)
					)
				)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Loading...]",
				"Fallback",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput("Fallback")

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			jestExpect(root).toMatchRenderedOutput("Final")

			ReactNoop.act(function()
				resolveText("Loading...")
			end)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberWorkLoop.js#L879-L886
	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberSuspenseContext.js#L20-L106
	-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberThrow.new.js#L224-L235
	-- ROBLOX DEVIATION: These regressions verify the React 17 reconstruction of
	-- the React 19 Suspense handler stack used by requestDeferredLane.
	it(
		"marks the outer Suspense boundary when a deferred value mounts in a fallback",
		function()
			jest.useFakeTimers()

			local function InnerFallback()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(
						Suspense,
						{
							fallback = React.createElement(Text, {
								text = "Outer Fallback",
							}),
						},
						React.createElement(
							Suspense,
							{ fallback = React.createElement(InnerFallback) },
							React.createElement(AsyncText, { text = "Primary" })
						)
					)
				)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Primary]",
				"Suspend! [Loading...]",
				"Outer Fallback",
				"Suspend! [Primary]",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput("Outer Fallback")

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Primary]",
				"Final",
			})
			-- ROBLOX DEVIATION: React 17's ReactNoop.act does not force this
			-- Suspense recovery timer. PR #34 uses the same JND test adaptation.
			jest.runOnlyPendingTimers()
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"marks a desirable outer Suspense boundary instead of an avoided fallback",
		function()
			jest.useFakeTimers()

			local function App()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(
					Suspense,
					{
						fallback = React.createElement(Text, {
							text = "Outer Fallback",
						}),
					},
					React.createElement(Suspense, {
						fallback = React.createElement(Text, {
							text = "Inner Fallback",
						}),
						unstable_avoidThisFallback = true,
					}, React.createElement(App))
				))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Loading...]",
				"Outer Fallback",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput("Outer Fallback")

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			-- ROBLOX DEVIATION: React 17's ReactNoop.act does not force this
			-- Suspense recovery timer. PR #34 uses the same JND test adaptation.
			jest.runOnlyPendingTimers()
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"if a suspended render spawns a deferred task that also suspends, we can finish the original task if that one loads first",
		function()
			local function App()
				local text = useDeferredValue("Final", "Loading...")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Suspend! [Loading...]",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput(nil)

			ReactNoop.act(function()
				resolveText("Loading...")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Loading...",
				"Suspend! [Final]",
			})
			jestExpect(root).toMatchRenderedOutput("Loading...")

			ReactNoop.act(function()
				resolveText("Final")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Final" })
			jestExpect(root).toMatchRenderedOutput("Final")
		end
	)

	it(
		"if there are multiple useDeferredValues in the same tree, only the first level defers; subsequent ones go straight to the final value, to avoid a waterfall",
		function()
			local Content
			local function App()
				local showContent = useDeferredValue(true, false)
				if not showContent then
					return React.createElement(Text, { text = "App Preview" })
				end
				return React.createElement(Content)
			end

			Content = function()
				local text = useDeferredValue("Content", "Content Preview")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			resolveText("App Preview")

			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"App Preview",
				"Suspend! [Content]",
			})
			jestExpect(root).toMatchRenderedOutput("App Preview")

			ReactNoop.act(function()
				resolveText("Content")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Content" })
			jestExpect(root).toMatchRenderedOutput("Content")
		end
	)

	it(
		"regression: useDeferredValue's initial value argument works even if an unrelated transition is suspended",
		function()
			local function Content(props)
				local text =
					useDeferredValue(props.text, "Preview " .. props.text .. "...")
				return React.createElement(AsyncText, { text = text })
			end

			local function App(props)
				return React.createElement(Content, {
					key = props.text,
					text = props.text,
				})
			end

			local root = ReactNoop.createRoot()

			resolveText("Preview A...")
			ReactNoop.act(function()
				startTransition(function()
					root.render(React.createElement(App, { text = "A" }))
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Preview A...",
				"Suspend! [A]",
			})

			resolveText("Preview B...")
			ReactNoop.act(function()
				startTransition(function()
					root.render(React.createElement(App, { text = "B" }))
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Preview B...",
				"Suspend! [B]",
			})

			ReactNoop.act(function()
				resolveText("B")
			end)
			jestExpect(Scheduler).toHaveYielded({ "B" })
			jestExpect(root).toMatchRenderedOutput("B")
		end
	)

	it(
		"avoids a useDeferredValue waterfall when separated by a Suspense boundary",
		function()
			local Content
			local function App()
				local showContent = useDeferredValue(true, false)
				if not showContent then
					return React.createElement(Text, { text = "App Preview" })
				end
				return React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(Content)
				)
			end

			Content = function()
				local text = useDeferredValue("Content", "Content Preview")
				return React.createElement(AsyncText, { text = text })
			end

			local root = ReactNoop.createRoot()
			resolveText("App Preview")

			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"App Preview",
				"Suspend! [Content]",
				"Loading...",
			})
			jestExpect(root).toMatchRenderedOutput("Loading...")

			ReactNoop.act(function()
				resolveText("Content")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Content" })
			jestExpect(root).toMatchRenderedOutput("Content")
		end
	)
end)
