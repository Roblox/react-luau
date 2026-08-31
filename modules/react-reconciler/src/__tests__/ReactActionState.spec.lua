--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-dom/src/__tests__/ReactDOMForm-test.js#L980-L1510
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent

local React
local ReactNoop
local Scheduler
local useActionState

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

type ControlledThenable<T> = {
	status: "pending" | "fulfilled" | "rejected",
	value: T?,
	reason: any,
	andThen: (
		self: ControlledThenable<T>,
		onFulfill: ((T) -> any)?,
		onReject: ((any) -> any)?
	) -> ControlledThenable<any>,
	reject: (self: ControlledThenable<T>, reason: any) -> (),
	resolve: (self: ControlledThenable<T>, value: T) -> (),
}

local createControlledThenable

createControlledThenable = function<T>(): ControlledThenable<T>
	local listeners = {}
	local thenable = {
		status = "pending",
		value = nil,
		reason = nil,
	} :: any

	local function settleChild(child, ok, result)
		if ok then
			if typeof(result) == "table" and typeof(result.andThen) == "function" then
				result:andThen(function(value)
					child:resolve(value)
				end, function(reason)
					child:reject(reason)
				end)
			else
				child:resolve(result)
			end
		else
			child:reject(result)
		end
	end

	local function notify(listener)
		local callback = if thenable.status == "fulfilled"
			then listener.onFulfill
			else listener.onReject
		if callback == nil then
			if thenable.status == "fulfilled" then
				listener.child:resolve(thenable.value)
			else
				listener.child:reject(thenable.reason)
			end
			return
		end
		settleChild(
			listener.child,
			pcall(
				callback,
				if thenable.status == "fulfilled" then thenable.value else thenable.reason
			)
		)
	end

	function thenable:andThen(onFulfill, onReject)
		local child = createControlledThenable()
		local listener = {
			onFulfill = onFulfill,
			onReject = onReject,
			child = child,
		}
		if self.status == "pending" then
			table.insert(listeners, listener)
		else
			notify(listener)
		end
		return child
	end

	function thenable:resolve(value)
		if self.status ~= "pending" then
			return
		end
		self.status = "fulfilled"
		self.value = value
		for _, listener in listeners do
			notify(listener)
		end
		table.clear(listeners)
	end

	function thenable:reject(reason)
		if self.status ~= "pending" then
			return
		end
		self.status = "rejected"
		self.reason = reason
		for _, listener in listeners do
			notify(listener)
		end
		table.clear(listeners)
	end

	return thenable
end

describe("useActionState", function()
	local textCache

	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		useActionState = React.useActionState
		textCache = {}
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return tostring(props.text)
	end

	local function getText(text)
		local record = textCache[text]
		if record == nil then
			record = createControlledThenable()
			textCache[text] = record
		end
		return record
	end

	local function resolveText(text)
		getText(text):resolve(text)
	end

	local function readText(text)
		local record = getText(text)
		if record.status == "pending" then
			Scheduler.unstable_yieldValue("Suspend! [" .. text .. "]")
			error(record)
		elseif record.status == "rejected" then
			error(record.reason, 0)
		end
		return record.value
	end

	local function AsyncText(props)
		readText(props.text)
		return React.createElement(Text, props)
	end

	local function createErrorBoundary(name)
		local ErrorBoundary = React.Component:extend(name)
		function ErrorBoundary:init()
			self.state = { error = nil }
		end
		function ErrorBoundary.getDerivedStateFromError(error_)
			return { error = error_ }
		end
		function ErrorBoundary:render()
			if self.state.error ~= nil then
				return React.createElement(Text, {
					text = "Caught an error: " .. self.state.error.message,
				})
			end
			return self.props.children
		end
		return ErrorBoundary
	end

	it(
		"useActionState updates state asynchronously and queues multiple actions",
		function()
			local actionCounter = 0
			local dispatch

			local function action(state, actionType)
				actionCounter += 1
				local counter = actionCounter
				Scheduler.unstable_yieldValue("Async action started [" .. counter .. "]")
				return getText("Wait [" .. counter .. "]"):andThen(function()
					if actionType == "increment" then
						return state + 1
					elseif actionType == "decrement" then
						return state - 1
					end
					return state
				end)
			end

			local function App()
				local state, update, isPending = useActionState(action, 0)
				dispatch = update
				return React.createElement(Text, {
					text = (if isPending then "Pending " else "") .. state,
				})
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ "0" })

			ReactNoop.act(function()
				React.startTransition(function()
					dispatch("increment")
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started [1]",
				"Pending 0",
			})

			for _, actionType in { "increment", "decrement", "increment" } do
				ReactNoop.act(function()
					React.startTransition(function()
						dispatch(actionType)
					end)
				end)
			end
			jestExpect(Scheduler).toHaveYielded({})

			for counter = 1, 4 do
				ReactNoop.act(function()
					resolveText("Wait [" .. counter .. "]")
				end)
				if counter < 4 then
					jestExpect(Scheduler).toHaveYielded({
						"Async action started [" .. counter + 1 .. "]",
					})
				end
			end
			jestExpect(Scheduler).toHaveYielded({ "2" })
			jestExpect(root).toMatchRenderedOutput("2")
		end
	)

	it("useActionState supports inline actions", function()
		local increment
		local function App(props)
			local state, dispatch, isPending = useActionState(function(previousState)
				return previousState + props.stepSize
			end, 0)
			increment = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { stepSize = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "0" })

		ReactNoop.act(function()
			React.startTransition(increment)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending 0", "1" })

		ReactNoop.act(function()
			root.render(React.createElement(App, { stepSize = 10 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "1" })

		ReactNoop.act(function()
			React.startTransition(increment)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending 1", "11" })
	end)

	it("useActionState: dispatch throws if called during render", function()
		local function App()
			local state, dispatch, isPending = useActionState(function() end, 0)
			dispatch()
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		jestExpect(function()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
		end).toThrow("Cannot update form state while rendering.")
	end)

	it("useActionState: queues multiple actions and runs them in order", function()
		local action
		local function App()
			local state, dispatch, isPending = useActionState(function(_, value)
				return getText(value)
			end, "A")
			action = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })

		for _, value in { "B", "C", "D" } do
			ReactNoop.act(function()
				React.startTransition(function()
					action(value)
				end)
			end)
		end
		jestExpect(Scheduler).toHaveYielded({ "Pending A" })

		for _, value in { "B", "C", "D" } do
			ReactNoop.act(function()
				resolveText(value)
			end)
		end
		jestExpect(Scheduler).toHaveYielded({ "D" })
		jestExpect(root).toMatchRenderedOutput("D")
	end)

	it(
		"useActionState: when calling a queued action, uses the implementation that was current at the time it was dispatched, not the most recent one",
		function()
			local action
			local function App(props)
				local state, dispatch, isPending = useActionState(function(_, value)
					if props.throwIfActionIsDispatched then
						error(Error("Oops!"), 0)
					end
					return getText(value)
				end, "Initial")
				action = dispatch
				return React.createElement(Text, {
					text = state .. if isPending then " (pending)" else "",
				})
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(App, { throwIfActionIsDispatched = false })
				)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Initial" })

			for _, value in { "First action", "Second action" } do
				ReactNoop.act(function()
					React.startTransition(function()
						action(value)
					end)
				end)
			end
			jestExpect(Scheduler).toHaveYielded({ "Initial (pending)" })

			ReactNoop.act(function()
				root.render(
					React.createElement(App, { throwIfActionIsDispatched = true })
				)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Initial (pending)" })

			ReactNoop.act(function()
				resolveText("First action")
			end)
			ReactNoop.act(function()
				resolveText("Second action")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Second action" })

			jestExpect(function()
				ReactNoop.act(function()
					React.startTransition(function()
						action("Third action")
					end)
				end)
			end).toThrow("Oops!")
		end
	)

	it("useActionState: works if action is sync", function()
		local increment
		local function App(props)
			local state, dispatch, isPending = useActionState(function(previousState)
				return previousState + props.stepSize
			end, 0)
			increment = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { stepSize = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "0" })
		ReactNoop.act(function()
			React.startTransition(increment)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending 0", "1" })
		ReactNoop.act(function()
			root.render(React.createElement(App, { stepSize = 10 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "1" })
		ReactNoop.act(function()
			React.startTransition(increment)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending 1", "11" })
	end)

	it("useActionState: can mix sync and async actions", function()
		local action
		local function App()
			local state, dispatch, isPending = useActionState(function(_, value)
				return value
			end, "A")
			action = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })

		for _, value in { getText("B"), "C", getText("D"), "E" } do
			ReactNoop.act(function()
				React.startTransition(function()
					action(value)
				end)
			end)
		end
		jestExpect(Scheduler).toHaveYielded({ "Pending A" })

		ReactNoop.act(function()
			resolveText("B")
		end)
		ReactNoop.act(function()
			resolveText("D")
		end)
		jestExpect(Scheduler).toHaveYielded({ "E" })
		jestExpect(root).toMatchRenderedOutput("E")
	end)

	it("useActionState: error handling (sync action)", function()
		local ErrorBoundary = createErrorBoundary("SyncActionStateErrorBoundary")
		local action
		local function App()
			local state, dispatch, isPending = useActionState(function(_, value)
				if string.sub(value, -1) == "!" then
					error(Error(value), 0)
				end
				return value
			end, "A")
			action = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })

		ReactNoop.act(function()
			React.startTransition(function()
				action("Oops!")
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Pending A",
			"Caught an error: Oops!",
			"Caught an error: Oops!",
		})
		jestExpect(root).toMatchRenderedOutput("Caught an error: Oops!")
	end)

	it("useActionState: error handling (async action)", function()
		local ErrorBoundary = createErrorBoundary("AsyncActionStateErrorBoundary")
		local action
		local function App()
			local state, dispatch, isPending = useActionState(function(_, value)
				return getText(value):andThen(function(text)
					if string.sub(text, -1) == "!" then
						error(Error(text), 0)
					end
					return text
				end)
			end, "A")
			action = dispatch
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })

		ReactNoop.act(function()
			React.startTransition(function()
				action("Oops!")
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending A" })
		ReactNoop.act(function()
			resolveText("Oops!")
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Caught an error: Oops!",
			"Caught an error: Oops!",
		})
		jestExpect(root).toMatchRenderedOutput("Caught an error: Oops!")
	end)

	it(
		"useActionState: when an action errors, subsequent actions are canceled",
		function()
			local ErrorBoundary = createErrorBoundary("CanceledActionStateErrorBoundary")
			local action
			local function App()
				local state, dispatch, isPending = useActionState(function(_, value)
					Scheduler.unstable_yieldValue("Start action: " .. value)
					return getText(value):andThen(function(text)
						if string.sub(text, -1) == "!" then
							error(Error(text), 0)
						end
						return text
					end)
				end, "A")
				action = dispatch
				return React.createElement(Text, {
					text = (if isPending then "Pending " else "") .. state,
				})
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(ErrorBoundary, nil, React.createElement(App))
				)
			end)
			jestExpect(Scheduler).toHaveYielded({ "A" })

			ReactNoop.act(function()
				React.startTransition(function()
					action("Oops!")
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Start action: Oops!", "Pending A" })

			ReactNoop.act(function()
				React.startTransition(function()
					action("Should never run")
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({})

			ReactNoop.act(function()
				resolveText("Oops!")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Caught an error: Oops!",
				"Caught an error: Oops!",
			})
			jestExpect(root).toMatchRenderedOutput("Caught an error: Oops!")

			ReactNoop.act(function()
				React.startTransition(function()
					action("This also should never run")
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Caught an error: Oops!")
		end
	)

	it("useActionState works in StrictMode", function()
		local actionCounter = 0
		local dispatch
		local function action(state)
			actionCounter += 1
			local counter = actionCounter
			Scheduler.unstable_yieldValue("Async action started [" .. counter .. "]")
			return getText("Wait [" .. counter .. "]"):andThen(function()
				return state + 1
			end)
		end

		local function App()
			local state, update, isPending = useActionState(action, 0)
			dispatch = update
			return React.createElement(Text, {
				text = (if isPending then "Pending " else "") .. state,
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(
				React.createElement(React.StrictMode, nil, React.createElement(App))
			)
		end)
		jestExpect(Scheduler).toHaveYielded({ "0" })
		ReactNoop.act(function()
			React.startTransition(function()
				dispatch("increment")
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Async action started [1]", "Pending 0" })
		ReactNoop.act(function()
			resolveText("Wait [1]")
		end)
		jestExpect(Scheduler).toHaveYielded({ "1" })
	end)

	it(
		"useActionState does not wrap action in a transition unless dispatch is in a transition",
		function()
			local dispatch
			local function App()
				local state
				local update
				state, update = useActionState(function()
					return state + 1
				end, 0)
				dispatch = update
				return React.createElement(AsyncText, { text = "Count: " .. state })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(
						React.Suspense,
						{ fallback = React.createElement(Text, { text = "Loading..." }) },
						React.createElement(App)
					)
				)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Suspend! [Count: 0]", "Loading..." })
			ReactNoop.act(function()
				resolveText("Count: 0")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 0" })

			ReactNoop.act(dispatch)
			jestExpect(Scheduler).toHaveYielded({ "Suspend! [Count: 1]", "Loading..." })
			jestExpect(root).toMatchRenderedOutput("Loading...")
			ReactNoop.act(function()
				resolveText("Count: 1")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })

			ReactNoop.act(function()
				React.startTransition(dispatch)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1", "Suspend! [Count: 2]" })
			jestExpect(root).toMatchRenderedOutput("Count: 1")
			ReactNoop.act(function()
				resolveText("Count: 2")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 2" })
		end
	)

	it(
		"useActionState warns if async action is dispatched outside of a transition",
		function()
			local dispatch
			local actionResult = createControlledThenable()
			local function App()
				local state
				local update
				state, update = useActionState(function()
					return actionResult
				end, 0)
				dispatch = update
				return React.createElement(AsyncText, { text = "Count: " .. state })
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Suspend! [Count: 0]" })
			ReactNoop.act(function()
				resolveText("Count: 0")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 0" })

			jestExpect(function()
				ReactNoop.act(dispatch)
			end).toErrorDev(
				"An async function with useActionState was called outside of a transition. "
					.. "This is likely not what you intended (for example, isPending will not update correctly). "
					.. "Either call the returned function inside startTransition, or pass it to an `action` or `formAction` prop.",
				{ withoutStack = true }
			)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput("Count: 0")

			ReactNoop.act(function()
				actionResult:resolve(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Suspend! [Count: 1]" })
			jestExpect(root).toMatchRenderedOutput("Count: 0")

			ReactNoop.act(function()
				resolveText("Count: 1")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(root).toMatchRenderedOutput("Count: 1")
		end
	)
end)
