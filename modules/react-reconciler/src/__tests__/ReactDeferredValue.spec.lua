-- ROBLOX upstream: https://github.com/facebook/react/blob/22edb9f777d27369fd2c1fad378f74e237b6dfd3/packages/react-reconciler/src/__tests__/ReactDeferredValue-test.js
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

local JestGlobals = require(Packages.Dev.JestGlobals)
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
	end)

	local function Text(props)
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
end)
