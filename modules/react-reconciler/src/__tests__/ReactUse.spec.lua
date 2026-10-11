--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/ReactUse-test.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

local React
local ReactNoop
local Scheduler
local Promise
local use
local useState

local function createTextThenable()
	local listeners: {
		{
			resolve: (string) -> (),
			reject: (any) -> (),
		}
	} = {}
	local thenable = {
		andThen = function(_self, resolve, reject)
			table.insert(listeners, { resolve = resolve, reject = reject })
		end,
	}

	local function resolve(value: string)
		for _, listener in listeners do
			listener.resolve(value)
		end
	end

	local function reject(reason: any)
		for _, listener in listeners do
			listener.reject(reason)
		end
	end

	return thenable, resolve, reject
end

local function span(prop)
	return { type = "span", hidden = false, children = {}, prop = prop }
end

local function Text(props)
	Scheduler.unstable_yieldValue(props.text)
	return React.createElement("span", { prop = props.text })
end

local function createErrorBoundary()
	local ErrorBoundary = React.Component:extend("ErrorBoundary")
	function ErrorBoundary:init()
		self.state = { error = nil }
	end
	function ErrorBoundary.getDerivedStateFromError(error_)
		return { error = error_ }
	end
	function ErrorBoundary:render()
		if self.state.error ~= nil then
			return React.createElement(Text, { text = self.state.error.message })
		end
		return self.props.children
	end
	return ErrorBoundary
end

describe("ReactUse", function()
	beforeEach(function()
		jest.resetModules()

		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		Promise = require(Packages.Promise)
		use = React.use
		useState = React.useState
	end)

	it("does not infinite loop if already fulfilled thenable is thrown", function()
		-- An already fulfilled Promise should never be thrown. If it is, React
		-- must show the fallback without retrying the render indefinitely.
		local thenable = {
			andThen = function() end,
			status = "fulfilled",
		}

		local renderCount = 0
		local function Async()
			renderCount += 1
			if renderCount > 50 then
				error("Infinite loop detected")
			end
			Scheduler.unstable_yieldValue("Suspend!")
			-- A userspace Suspense library made the implementation mistake that
			-- this regression covers.
			error(thenable)
		end

		ReactNoop.render(
			React.createElement(
				React.Suspense,
				{ fallback = React.createElement(Text, { text = "Loading..." }) },
				React.createElement(Async)
			)
		)

		-- ROBLOX DEVIATION: React 17 has no sibling prewarming pass, so Async
		-- renders once instead of React 19's second post-fallback attempt.
		jestExpect(Scheduler).toFlushAndYield({ "Suspend!", "Loading..." })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Loading...") })
	end)

	it("basic use(promise)", function()
		local promiseA = {
			status = "fulfilled",
			value = "A",
			andThen = function() end,
		}
		local promiseB = {
			status = "fulfilled",
			value = "B",
			andThen = function() end,
		}
		local promiseC = {
			status = "fulfilled",
			value = "C",
			andThen = function() end,
		}

		local function Async()
			local text = use(promiseA) .. use(promiseB) .. use(promiseC)
			return React.createElement(Text, { text = text })
		end

		ReactNoop.render(React.createElement(Async))

		jestExpect(Scheduler).toFlushAndYield({ "ABC" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("ABC") })
	end)

	it("suspends until a pending promise resolves", function()
		local promise, resolve = createTextThenable()

		local function Async()
			return React.createElement(Text, { text = use(promise) })
		end

		ReactNoop.render(
			React.createElement(
				React.Suspense,
				{ fallback = React.createElement(Text, { text = "Loading..." }) },
				React.createElement(Async)
			)
		)

		jestExpect(Scheduler).toFlushAndYield({ "Loading..." })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Loading...") })

		resolve("Async")

		jestExpect(Scheduler).toFlushAndYield({ "Async" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Async") })
	end)

	it("instruments a Roblox Promise and retries after it resolves", function()
		local resolvePromise: ((string) -> ())? = nil
		local promise = Promise.new(function(resolve)
			resolvePromise = resolve
		end)

		local function Async()
			return React.createElement(Text, { text = use(promise) })
		end

		ReactNoop.render(
			React.createElement(
				React.Suspense,
				{ fallback = React.createElement(Text, { text = "Loading..." }) },
				React.createElement(Async)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({ "Loading..." })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Loading...") })

		assert(resolvePromise ~= nil, "Promise executor did not expose its resolver")
		resolvePromise("Async")
		return promise:andThen(function()
			jestExpect(Scheduler).toFlushAndYield({ "Async" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Async") })
		end)
	end)

	it("using a rejected promise will throw", function()
		local Error = require(Packages.LuauPolyfill).Error
		local rejected = {
			status = "rejected",
			reason = Error.new("Oops!"),
			andThen = function() end,
		}

		local ErrorBoundary = createErrorBoundary()

		local function Async()
			return React.createElement("span", { prop = use(rejected) })
		end

		ReactNoop.render(
			React.createElement(ErrorBoundary, nil, React.createElement(Async))
		)
		jestExpect(Scheduler).toFlushAndYield({ "Oops!", "Oops!" })

		jestExpect(ReactNoop.getChildren()).toEqual({ span("Oops!") })
	end)

	it("retries a pending promise rejection through an error boundary", function()
		local Error = require(Packages.LuauPolyfill).Error
		local promise, _, reject = createTextThenable()
		local ErrorBoundary = createErrorBoundary()

		local function Async()
			return React.createElement(Text, { text = use(promise) })
		end

		ReactNoop.render(
			React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(
					React.Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(Async)
				)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({ "Loading..." })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Loading...") })

		reject(Error.new("Rejected later"))
		jestExpect(Scheduler).toFlushAndYield({ "Rejected later", "Rejected later" })

		jestExpect(ReactNoop.getChildren()).toEqual({ span("Rejected later") })
	end)

	it("keeps thenable tracking independent between components", function()
		local function resolved(value)
			return {
				andThen = function() end,
				status = "fulfilled",
				value = value,
			}
		end
		local promiseA = resolved("A")
		local promiseB = resolved("B")
		local promiseC = resolved("C")
		local promiseD = resolved("D")

		local function Child(props)
			return React.createElement(Text, {
				text = props.prefix .. use(promiseC) .. use(promiseD),
			})
		end

		local function Parent()
			return React.createElement(Child, {
				prefix = use(promiseA) .. use(promiseB),
			})
		end

		ReactNoop.render(React.createElement(Parent))
		jestExpect(Scheduler).toFlushAndYield({ "ABCD" })

		jestExpect(ReactNoop.getChildren()).toEqual({ span("ABCD") })
	end)

	it("basic use(context)", function()
		local ContextA = React.createContext("")
		local ContextB = React.createContext("B")

		local function Sync()
			return React.createElement("span", {
				prop = use(ContextA) .. use(ContextB),
			})
		end

		ReactNoop.render(
			React.createElement(
				ContextA.Provider,
				{ value = "A" },
				React.createElement(Sync)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({})

		jestExpect(ReactNoop.getChildren()).toEqual({ span("AB") })
	end)

	it("allows conditional use calls before a stateful Hook", function()
		local Context = React.createContext("Context")

		local function App(props)
			local prefix = if props.readContext then use(Context) else "Skipped"
			local count = useState(0)
			return React.createElement(Text, { text = prefix .. ":" .. count })
		end

		ReactNoop.render(React.createElement(App, { readContext = false }))
		jestExpect(Scheduler).toFlushAndYield({ "Skipped:0" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Skipped:0") })

		ReactNoop.render(React.createElement(App, { readContext = true }))
		jestExpect(Scheduler).toFlushAndYield({ "Context:0" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Context:0") })
	end)

	it("allows use calls in a loop before a stateful Hook", function()
		local contexts = {
			React.createContext("A"),
			React.createContext("B"),
			React.createContext("C"),
		}

		local function App()
			local value = ""
			for _, context in contexts do
				value ..= use(context)
			end
			local count = useState(0)
			return React.createElement(Text, { text = value .. count })
		end

		ReactNoop.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "ABC0" })

		jestExpect(ReactNoop.getChildren()).toEqual({ span("ABC0") })
	end)

	it("discards thenable positions before a render-phase update", function()
		local promises = {
			{
				andThen = function() end,
				status = "fulfilled",
				value = "0",
			},
			{
				andThen = function() end,
				status = "fulfilled",
				value = "1",
			},
		}

		local function App()
			local count, setCount = useState(0)
			if count == 0 then
				setCount(1)
			end
			return React.createElement(Text, { text = use(promises[count + 1]) })
		end

		ReactNoop.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "1" })

		jestExpect(ReactNoop.getChildren()).toEqual({ span("1") })
	end)

	it("unwraps thenable that fulfills synchronously without suspending", function()
		local thenable = {
			andThen = function(_self, resolve)
				resolve("Hi")
			end,
		}

		local function App()
			return React.createElement(Text, { text = use(thenable) })
		end

		ReactNoop.flushSync(function()
			ReactNoop.render(React.createElement(App))
		end)

		jestExpect(Scheduler).toHaveYielded({ "Hi" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Hi") })
	end)

	it("warns if use(promise) is wrapped with try/catch", function()
		local promise = { andThen = function() end }

		local function App()
			pcall(function()
				use(promise)
			end)
			return React.createElement(Text, { text = "Caught" })
		end

		jestExpect(function()
			ReactNoop.render(React.createElement(App))
			jestExpect(Scheduler).toFlushAndYield({ "Caught" })
		end).toErrorDev(
			"`use` was called from inside a try/catch block. This is not allowed "
				.. "and can lead to unexpected behavior. To handle errors triggered "
				.. "by `use`, wrap your component in a error boundary.",
			{ withoutStack = true }
		)
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Caught") })
	end)

	it("resets the dispatcher after a component suspends", function()
		local promise = { andThen = function() end }
		local function Async()
			return React.createElement("span", { prop = use(promise) })
		end

		ReactNoop.render(
			React.createElement(
				React.Suspense,
				{ fallback = React.createElement(Text, { text = "Loading..." }) },
				React.createElement(Async)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({ "Loading..." })

		jestExpect(function()
			useState(0)
		end).toThrow("Invalid hook call")
	end)
end)
