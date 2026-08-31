--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/ReactAsyncActions-test.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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
local useState
local useTransition
local useOptimistic
local textCache
local previousReportError

local JestGlobals = require(Packages.Dev.JestGlobals)
local Error = require(Packages.LuauPolyfill).Error
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
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

describe("ReactAsyncActions", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		useState = React.useState
		useTransition = React.useTransition
		useOptimistic = React.useOptimistic
		textCache = {}
		previousReportError = rawget(_G, "reportError")
		rawset(_G, "reportError", function(error_)
			Scheduler.unstable_yieldValue("reportError: " .. error_.message)
		end)
	end)

	afterEach(function()
		rawset(_G, "reportError", previousReportError)
	end)

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return props.text
	end

	local function getText(text)
		local thenable = textCache[text]
		if thenable == nil then
			thenable = createControlledThenable()
			textCache[text] = thenable
		end
		return thenable
	end

	local function resolveText(text)
		getText(text):resolve(text)
	end

	local function AsyncText(props)
		local thenable = getText(props.text)
		if thenable.status == "pending" then
			Scheduler.unstable_yieldValue("Suspend! [" .. props.text .. "]")
			error(thenable)
		elseif thenable.status == "rejected" then
			error(thenable.reason, 0)
		end
		return React.createElement(Text, props)
	end

	local function pairedOutput(pending, text)
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement("span", nil, "Pending: " .. tostring(pending)),
			React.createElement("span", nil, text)
		)
	end

	local function entangledOutput(pending, a, b, c)
		return React.createElement(
			React.Fragment,
			nil,
			React.createElement("span", nil, "Pending: " .. tostring(pending)),
			React.createElement("span", nil, a, ", ", b, ", ", c)
		)
	end

	it("isPending remains true until async action finishes", function()
		local startTransition
		local action = createControlledThenable()

		local function App()
			local isPending, start = useTransition()
			startTransition = start
			return React.createElement(Text, {
				text = "Pending: " .. tostring(isPending),
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false" })
		jestExpect(root).toMatchRenderedOutput("Pending: false")

		ReactNoop.act(function()
			startTransition(function()
				Scheduler.unstable_yieldValue("Async action started")
				return action:andThen(function()
					Scheduler.unstable_yieldValue("Async action ended")
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Async action started", "Pending: true" })
		jestExpect(root).toMatchRenderedOutput("Pending: true")

		ReactNoop.act(function()
			action:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Async action ended", "Pending: false" })
		jestExpect(root).toMatchRenderedOutput("Pending: false")
	end)

	it("multiple updates in an async action scope are entangled together", function()
		local startTransition
		local wait = createControlledThenable()
		local root

		local function App(props)
			local isPending, start = useTransition()
			startTransition = start
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(
					"span",
					nil,
					React.createElement(Text, {
						text = "Pending: " .. tostring(isPending),
					})
				),
				React.createElement(
					"span",
					nil,
					React.createElement(Text, { text = props.text })
				)
			)
		end

		root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { text = "A" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false", "A" })
		jestExpect(root).toMatchRenderedOutput(pairedOutput(false, "A"))

		ReactNoop.act(function()
			startTransition(function()
				Scheduler.unstable_yieldValue("Async action started")
				return wait:andThen(function()
					Scheduler.unstable_yieldValue("Async action ended")
					startTransition(function()
						root.render(React.createElement(App, { text = "B" }))
					end)
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Async action started",
			"Pending: true",
			"A",
		})
		jestExpect(root).toMatchRenderedOutput(pairedOutput(true, "A"))

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Async action ended",
			"Pending: false",
			"B",
		})
		jestExpect(root).toMatchRenderedOutput(pairedOutput(false, "B"))
	end)

	it(
		"multiple async action updates in the same scope are entangled together",
		function()
			local startTransition
			local waitForB = createControlledThenable()
			local waitForC = createControlledThenable()

			local setStepA
			local function A()
				local step, setStep = useState(0)
				setStepA = setStep
				return React.createElement(AsyncText, { text = "A" .. step })
			end

			local setStepB
			local function B()
				local step, setStep = useState(0)
				setStepB = setStep
				return React.createElement(AsyncText, { text = "B" .. step })
			end

			local setStepC
			local function C()
				local step, setStep = useState(0)
				setStepC = setStep
				return React.createElement(AsyncText, { text = "C" .. step })
			end

			local function App()
				local isPending, start = useTransition()
				startTransition = start
				return React.createElement(
					React.Fragment,
					nil,
					React.createElement(
						"span",
						nil,
						React.createElement(Text, {
							text = "Pending: " .. tostring(isPending),
						})
					),
					React.createElement(
						"span",
						nil,
						React.createElement(A),
						", ",
						React.createElement(B),
						", ",
						React.createElement(C)
					)
				)
			end

			local root = ReactNoop.createRoot()
			resolveText("A0")
			resolveText("B0")
			resolveText("C0")
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false", "A0", "B0", "C0" })
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(false, "A0", "B0", "C0")
			)

			ReactNoop.act(function()
				startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					setStepA(1)
					return waitForB:andThen(function()
						startTransition(function()
							setStepB(1)
						end)
						return waitForC:andThen(function()
							startTransition(function()
								setStepC(1)
							end)
							Scheduler.unstable_yieldValue("Async action ended")
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Pending: true",
				"A0",
				"B0",
				"C0",
			})
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(true, "A0", "B0", "C0")
			)

			ReactNoop.act(function()
				waitForB:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(true, "A0", "B0", "C0")
			)

			ReactNoop.act(function()
				waitForC:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action ended",
				"Pending: false",
				"Suspend! [A1]",
			})
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(true, "A0", "B0", "C0")
			)

			ReactNoop.act(function()
				resolveText("A1")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Pending: false",
				"A1",
				"Suspend! [B1]",
			})
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(true, "A0", "B0", "C0")
			)
			ReactNoop.act(function()
				resolveText("B1")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Pending: false",
				"A1",
				"B1",
				"Suspend! [C1]",
			})
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(true, "A0", "B0", "C0")
			)
			ReactNoop.act(function()
				resolveText("C1")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false", "A1", "B1", "C1" })
			jestExpect(root).toMatchRenderedOutput(
				entangledOutput(false, "A1", "B1", "C1")
			)
		end
	)

	it("urgent updates are not blocked during an async action", function()
		local startTransition
		local setStepA
		local setStepB
		local wait = createControlledThenable()

		local function A()
			local stepA, setA = useState(0)
			setStepA = setA
			return React.createElement(Text, { text = "A" .. stepA })
		end

		local function B()
			local stepB, setB = useState(0)
			setStepB = setB
			return React.createElement(Text, { text = "B" .. stepB })
		end

		local function App()
			local isPending, start = useTransition()
			startTransition = start
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Text, { text = "Pending: " .. tostring(isPending) }),
				React.createElement(A),
				React.createElement(B)
			)
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false", "A0", "B0" })
		jestExpect(root).toMatchRenderedOutput("Pending: falseA0B0")

		ReactNoop.act(function()
			startTransition(function()
				Scheduler.unstable_yieldValue("Async action started")
				startTransition(function()
					setStepA(1)
				end)
				return wait:andThen(function()
					Scheduler.unstable_yieldValue("Async action ended")
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Async action started",
			"Pending: true",
			"A0",
			"B0",
		})
		jestExpect(root).toMatchRenderedOutput("Pending: trueA0B0")

		ReactNoop.act(function()
			setStepB(1)
		end)
		jestExpect(Scheduler).toHaveYielded({ "B1" })
		jestExpect(root).toMatchRenderedOutput("Pending: trueA0B1")

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Async action ended",
			"Pending: false",
			"A1",
			"B1",
		})
		jestExpect(root).toMatchRenderedOutput("Pending: falseA1B1")
	end)

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
					text = self.state.error.message,
				})
			end
			return self.props.children
		end

		return ErrorBoundary
	end

	it("if a sync action throws, it's rethrown from the `useTransition`", function()
		local ErrorBoundary = createErrorBoundary("SyncActionErrorBoundary")
		local startTransition

		local function App()
			local isPending, start = useTransition()
			startTransition = start
			return React.createElement(Text, {
				text = "Pending: " .. tostring(isPending),
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false" })
		jestExpect(root).toMatchRenderedOutput("Pending: false")

		ReactNoop.act(function()
			startTransition(function()
				error(Error("Oops!"), 0)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: true", "Oops!", "Oops!" })
		jestExpect(root).toMatchRenderedOutput("Oops!")
	end)

	it("if an async action throws, it's rethrown from the `useTransition`", function()
		local ErrorBoundary = createErrorBoundary("AsyncActionErrorBoundary")
		local startTransition
		local wait = createControlledThenable()

		local function App()
			local isPending, start = useTransition()
			startTransition = start
			return React.createElement(Text, {
				text = "Pending: " .. tostring(isPending),
			})
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false" })
		jestExpect(root).toMatchRenderedOutput("Pending: false")

		ReactNoop.act(function()
			startTransition(function()
				Scheduler.unstable_yieldValue("Async action started")
				return wait:andThen(function()
					error(Error("Oops!"), 0)
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Async action started", "Pending: true" })
		jestExpect(root).toMatchRenderedOutput("Pending: true")

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Oops!", "Oops!" })
		jestExpect(root).toMatchRenderedOutput("Oops!")
	end)

	it(
		"if there are multiple entangled actions, and one of them errors, it only affects that action",
		function()
			local ErrorBoundary = createErrorBoundary("EntangledActionErrorBoundary")
			local startTransitionA
			local startTransitionB
			local startTransitionC
			local waitForA = createControlledThenable()
			local waitForB = createControlledThenable()
			local waitForC = createControlledThenable()

			local function ActionA()
				local isPending, start = useTransition()
				startTransitionA = start
				return React.createElement(
					Text,
					{ text = "Pending A: " .. tostring(isPending) }
				)
			end

			local function ActionB()
				local isPending, start = useTransition()
				startTransitionB = start
				return React.createElement(
					Text,
					{ text = "Pending B: " .. tostring(isPending) }
				)
			end

			local function ActionC()
				local isPending, start = useTransition()
				startTransitionC = start
				return React.createElement(
					Text,
					{ text = "Pending C: " .. tostring(isPending) }
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(
							ErrorBoundary,
							nil,
							React.createElement(ActionA)
						),
						React.createElement(
							ErrorBoundary,
							nil,
							React.createElement(ActionB)
						),
						React.createElement(
							ErrorBoundary,
							nil,
							React.createElement(ActionC)
						)
					)
				)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Pending A: false",
				"Pending B: false",
				"Pending C: false",
			})
			jestExpect(root).toMatchRenderedOutput(
				"Pending A: falsePending B: falsePending C: false"
			)

			ReactNoop.act(function()
				startTransitionC(function()
					startTransitionB(function()
						startTransitionA(function()
							return waitForA:andThen(function()
								error(Error("Oops A!"), 0)
							end)
						end)
						return waitForB
					end)
					return waitForC:andThen(function()
						error(Error("Oops C!"), 0)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Pending A: true",
				"Pending B: true",
				"Pending C: true",
			})

			ReactNoop.act(function()
				waitForA:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({})
			ReactNoop.act(function()
				waitForB:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({})
			ReactNoop.act(function()
				waitForC:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Oops A!",
				"Pending B: false",
				"Oops C!",
				"Oops A!",
				"Pending B: false",
				"Oops C!",
			})
			jestExpect(root).toMatchRenderedOutput("Oops A!Pending B: falseOops C!")
		end
	)

	it("useOptimistic can be used to implement a pending state", function()
		local setIsPending

		local function App(props)
			local isPending, setPending = useOptimistic(false)
			setIsPending = setPending
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Text, { text = "Pending: " .. tostring(isPending) }),
				React.createElement(AsyncText, { text = props.text })
			)
		end

		local root = ReactNoop.createRoot()
		resolveText("A")
		ReactNoop.act(function()
			root.render(React.createElement(App, { text = "A" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false", "A" })
		jestExpect(root).toMatchRenderedOutput("Pending: falseA")

		ReactNoop.act(function()
			React.startTransition(function()
				setIsPending(true)
				root.render(React.createElement(App, { text = "B" }))
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Pending: true",
			"A",
			"Pending: false",
			"Suspend! [B]",
		})

		ReactNoop.act(function()
			resolveText("B")
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false", "B" })
	end)

	it("useOptimistic rebases pending updates on top of passthrough value", function()
		local addItemToCart
		local serverCartSize = 1
		local wait = createControlledThenable()
		local root

		local function App(props)
			local isPending, startTransition = useTransition()
			local optimisticCartSize, setOptimisticCartSize =
				useOptimistic(props.cartSize)
			addItemToCart = function()
				startTransition(function()
					setOptimisticCartSize(function(size)
						return size + 1
					end)
					return wait:andThen(function()
						serverCartSize += 1
						React.startTransition(function()
							root.render(
								React.createElement(App, { cartSize = serverCartSize })
							)
						end)
					end)
				end)
			end
			return React.createElement(Text, {
				text = string.format(
					"Pending: %s, Items in cart: %d",
					tostring(isPending),
					optimisticCartSize
				),
			})
		end

		root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { cartSize = serverCartSize }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false, Items in cart: 1" })
		jestExpect(root).toMatchRenderedOutput("Pending: false, Items in cart: 1")

		ReactNoop.act(addItemToCart)
		jestExpect(Scheduler).toHaveYielded({ "Pending: true, Items in cart: 2" })
		jestExpect(root).toMatchRenderedOutput("Pending: true, Items in cart: 2")

		serverCartSize += 1
		ReactNoop.flushSync(function()
			root.render(React.createElement(App, { cartSize = serverCartSize }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: true, Items in cart: 3" })
		jestExpect(root).toMatchRenderedOutput("Pending: true, Items in cart: 3")

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false, Items in cart: 3" })
		jestExpect(root).toMatchRenderedOutput("Pending: false, Items in cart: 3")
	end)

	it(
		"regression: when there are no pending transitions, useOptimistic should always return the passthrough value",
		function()
			local setCanonicalState
			local function App()
				local canonicalState, setState = useState(0)
				local optimisticState = useOptimistic(canonicalState)
				setCanonicalState = setState
				return React.createElement(Text, {
					text = string.format(
						"Canonical: %d, Optimistic: %d",
						canonicalState,
						optimisticState
					),
				})
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Canonical: 0, Optimistic: 0" })
			jestExpect(root).toMatchRenderedOutput("Canonical: 0, Optimistic: 0")

			ReactNoop.act(function()
				setCanonicalState(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Canonical: 1, Optimistic: 1" })
			jestExpect(root).toMatchRenderedOutput("Canonical: 1, Optimistic: 1")
		end
	)

	it("regression: useOptimistic during setState-in-render", function()
		local setOptimisticState
		local startTransition
		local wait = createControlledThenable()

		local function App()
			local optimisticState, setOptimistic = useOptimistic(0)
			setOptimisticState = setOptimistic
			local _, start = useTransition()
			startTransition = start
			local derivedState, setDerivedState = useState(0)
			if derivedState ~= optimisticState then
				setDerivedState(optimisticState)
			end
			return React.createElement(Text, { text = optimisticState })
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ 0 })
		jestExpect(root).toMatchRenderedOutput("0")

		ReactNoop.act(function()
			startTransition(function()
				setOptimisticState(1)
				return wait
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ 1 })
		jestExpect(root).toMatchRenderedOutput("1")
	end)

	it("useOptimistic accepts a custom reducer", function()
		local addItemToCart
		local serverCartSize = 1
		local wait = createControlledThenable()
		local root

		local function App(props)
			local isPending, startTransition = useTransition()
			local optimisticCartSize, addToOptimisticCart = useOptimistic(
				props.cartSize,
				function(size, item)
					Scheduler.unstable_yieldValue(
						"Increment optimistic cart size for " .. item
					)
					return size + 1
				end
			)
			addItemToCart = function(item)
				startTransition(function()
					addToOptimisticCart(item)
					return wait:andThen(function()
						serverCartSize += 1
						React.startTransition(function()
							root.render(
								React.createElement(App, { cartSize = serverCartSize })
							)
						end)
					end)
				end)
			end
			return React.createElement(Text, {
				text = string.format(
					"Pending: %s, Items in cart: %d",
					tostring(isPending),
					optimisticCartSize
				),
			})
		end

		root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { cartSize = serverCartSize }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false, Items in cart: 1" })
		jestExpect(root).toMatchRenderedOutput("Pending: false, Items in cart: 1")

		ReactNoop.act(function()
			addItemToCart("B")
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Increment optimistic cart size for B",
			"Pending: true, Items in cart: 2",
		})
		jestExpect(root).toMatchRenderedOutput("Pending: true, Items in cart: 2")

		serverCartSize += 1
		ReactNoop.flushSync(function()
			root.render(React.createElement(App, { cartSize = serverCartSize }))
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Increment optimistic cart size for B",
			"Pending: true, Items in cart: 3",
		})
		jestExpect(root).toMatchRenderedOutput("Pending: true, Items in cart: 3")

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Pending: false, Items in cart: 3" })
		jestExpect(root).toMatchRenderedOutput("Pending: false, Items in cart: 3")
	end)

	it(
		"useOptimistic rebases if the passthrough is updated during a render phase update",
		function()
			local increment
			local setCount
			local wait = createControlledThenable()

			local function App()
				local isPending, startTransition = useTransition()
				local count, updateCount = useState(0)
				setCount = updateCount
				local optimisticCount, setOptimisticCount = useOptimistic(
					count,
					function(previous)
						Scheduler.unstable_yieldValue("Increment optimistic count")
						return previous + 1
					end
				)

				if count == 1 then
					Scheduler.unstable_yieldValue("Render phase update count from 1 to 2")
					setCount(2)
				end

				increment = function()
					startTransition(function()
						setOptimisticCount(nil)
						return wait:andThen(function()
							React.startTransition(function()
								setCount(function(value)
									return value + 1
								end)
							end)
						end)
					end)
				end

				local optimistic = if isPending
					then ", Optimistic count: " .. optimisticCount
					else ""
				return React.createElement(
					Text,
					{ text = "Count: " .. count .. optimistic }
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 0" })
			jestExpect(root).toMatchRenderedOutput("Count: 0")

			ReactNoop.act(increment)
			jestExpect(Scheduler).toHaveYielded({
				"Increment optimistic count",
				"Count: 0, Optimistic count: 1",
			})
			jestExpect(root).toMatchRenderedOutput("Count: 0, Optimistic count: 1")

			ReactNoop.act(function()
				setCount(1)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Increment optimistic count",
				"Render phase update count from 1 to 2",
				"Increment optimistic count",
				"Count: 2, Optimistic count: 3",
			})
			jestExpect(root).toMatchRenderedOutput("Count: 2, Optimistic count: 3")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 3" })
			jestExpect(root).toMatchRenderedOutput("Count: 3")
		end
	)

	it(
		"useOptimistic rebases if the passthrough is updated during a render phase update (initial mount)",
		function()
			local function App()
				local count, setCount = useState(0)
				local optimisticCount = useOptimistic(count)
				if count == 0 then
					Scheduler.unstable_yieldValue("Render phase update count from 1 to 2")
					setCount(1)
				end
				return React.createElement(Text, {
					text = string.format(
						"Count: %d, Optimistic count: %d",
						count,
						optimisticCount
					),
				})
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Render phase update count from 1 to 2",
				"Count: 1, Optimistic count: 1",
			})
			jestExpect(root).toMatchRenderedOutput("Count: 1, Optimistic count: 1")
		end
	)

	it("useOptimistic can update repeatedly in the same async action", function()
		local startTransition
		local setLoadingProgress
		local setText
		local waitOne = createControlledThenable()
		local waitTwo = createControlledThenable()

		local function App()
			local _, start = useTransition()
			local text, updateText = useState("A")
			local loadingProgress, updateLoadingProgress = useOptimistic("0")
			startTransition = start
			setText = updateText
			setLoadingProgress = updateLoadingProgress
			local progress = if loadingProgress ~= "0"
				then "Loading... (" .. loadingProgress .. "), "
				else ""
			return React.createElement(Text, { text = progress .. text })
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })
		jestExpect(root).toMatchRenderedOutput("A")

		ReactNoop.act(function()
			startTransition(function()
				setLoadingProgress("25%")
				return waitOne:andThen(function()
					setLoadingProgress("75%")
					return waitTwo:andThen(function()
						startTransition(function()
							setText("B")
						end)
					end)
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Loading... (25%), A" })
		jestExpect(root).toMatchRenderedOutput("Loading... (25%), A")

		ReactNoop.act(function()
			waitOne:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Loading... (75%), A" })
		jestExpect(root).toMatchRenderedOutput("Loading... (75%), A")

		ReactNoop.act(function()
			waitTwo:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "B" })
		jestExpect(root).toMatchRenderedOutput("B")
	end)

	it("useOptimistic warns if outside of a transition", function()
		local setLoadingProgress
		local setText

		local function App()
			local text, updateText = useState("A")
			local loadingProgress, updateLoadingProgress = useOptimistic("0")
			setText = updateText
			setLoadingProgress = updateLoadingProgress
			local progress = if loadingProgress ~= "0"
				then "Loading... (" .. loadingProgress .. "), "
				else ""
			return React.createElement(Text, { text = progress .. text })
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })
		jestExpect(root).toMatchRenderedOutput("A")

		jestExpect(function()
			ReactNoop.act(function()
				setLoadingProgress("25%")
				React.startTransition(function()
					setText("B")
				end)
			end)
		end).toErrorDev(
			"An optimistic state update occurred outside a transition or action. "
				.. "To fix, move the update to an action, or wrap with startTransition.",
			{ withoutStack = true }
		)
		jestExpect(Scheduler).toHaveYielded({ "Loading... (25%), A", "B" })
		jestExpect(root).toMatchRenderedOutput("B")
	end)

	it(
		"optimistic state is not reverted until async action finishes, even if useTransition hook is unmounted",
		function()
			local startTransition
			local setText
			local setOptimisticText
			local wait = createControlledThenable()

			local function Updater()
				local isPending, start = useTransition()
				startTransition = start
				return React.createElement(
					Text,
					{ text = "Pending: " .. tostring(isPending) .. ", " }
				)
			end

			local function Sibling()
				local canonicalText, updateText = useState("A")
				setText = updateText
				local text, updateOptimisticText = useOptimistic(
					canonicalText,
					function(_, optimisticText)
						return optimisticText .. " (loading...)"
					end
				)
				setOptimisticText = updateOptimisticText
				return React.createElement(Text, { text = text })
			end

			local function App(props)
				return React.createElement(
					React.Fragment,
					nil,
					if props.showUpdater then React.createElement(Updater) else nil,
					React.createElement(Sibling)
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = true }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false, ", "A" })
			jestExpect(root).toMatchRenderedOutput("Pending: false, A")

			ReactNoop.act(function()
				startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					setOptimisticText("C")
					startTransition(function()
						setText("B")
					end)
					return wait:andThen(function()
						Scheduler.unstable_yieldValue("Async action ended")
						startTransition(function()
							setText("C")
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Pending: true, ",
				"C (loading...)",
			})
			jestExpect(root).toMatchRenderedOutput("Pending: true, C (loading...)")

			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = false }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "C (loading...)" })
			jestExpect(root).toMatchRenderedOutput("C (loading...)")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "C" })
			jestExpect(root).toMatchRenderedOutput("C")
		end
	)

	it(
		"updates in an async action are entangled even if useTransition hook is unmounted before it finishes",
		function()
			local startTransition
			local setText
			local wait = createControlledThenable()

			local function Updater()
				local isPending, start = useTransition()
				startTransition = start
				return React.createElement(
					Text,
					{ text = "Pending: " .. tostring(isPending) .. ", " }
				)
			end

			local function Sibling()
				local text, updateText = useState("A")
				setText = updateText
				return React.createElement(Text, { text = text })
			end

			local function App(props)
				return React.createElement(
					React.Fragment,
					nil,
					if props.showUpdater then React.createElement(Updater) else nil,
					React.createElement(Sibling)
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = true }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false, ", "A" })
			jestExpect(root).toMatchRenderedOutput("Pending: false, A")

			ReactNoop.act(function()
				startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					startTransition(function()
						setText("B")
					end)
					return wait:andThen(function()
						Scheduler.unstable_yieldValue("Async action ended")
						startTransition(function()
							setText("C")
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Pending: true, ",
				"A",
			})
			jestExpect(root).toMatchRenderedOutput("Pending: true, A")

			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = false }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "A" })
			jestExpect(root).toMatchRenderedOutput("A")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "C" })
			jestExpect(root).toMatchRenderedOutput("C")
		end
	)

	it(
		"updates in an async action are entangled even if useTransition hook is unmounted before it finishes (class component)",
		function()
			local startTransition
			local setText
			local wait = createControlledThenable()

			local function Updater()
				local isPending, start = useTransition()
				startTransition = start
				return React.createElement(
					Text,
					{ text = "Pending: " .. tostring(isPending) .. ", " }
				)
			end

			local Sibling = React.Component:extend("ActionClassSibling")
			function Sibling:init()
				self.state = { text = "A" }
			end
			function Sibling:render()
				setText = function(text)
					self:setState({ text = text })
				end
				return React.createElement(Text, { text = self.state.text })
			end

			local function App(props)
				return React.createElement(
					React.Fragment,
					nil,
					if props.showUpdater then React.createElement(Updater) else nil,
					React.createElement(Sibling)
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = true }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false, ", "A" })
			jestExpect(root).toMatchRenderedOutput("Pending: false, A")

			ReactNoop.act(function()
				startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					startTransition(function()
						setText("B")
					end)
					return wait:andThen(function()
						Scheduler.unstable_yieldValue("Async action ended")
						startTransition(function()
							setText("C")
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Pending: true, ",
				"A",
			})
			jestExpect(root).toMatchRenderedOutput("Pending: true, A")

			ReactNoop.act(function()
				root.render(React.createElement(App, { showUpdater = false }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "A" })
			jestExpect(root).toMatchRenderedOutput("A")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "C" })
			jestExpect(root).toMatchRenderedOutput("C")

			ReactNoop.act(function()
				setText("D")
			end)
			jestExpect(Scheduler).toHaveYielded({ "D" })
			jestExpect(root).toMatchRenderedOutput("D")
		end
	)

	it(
		"updates in an async action are entangled even if useTransition hook is unmounted before it finishes (root update)",
		function()
			local startTransition
			local setShowUpdater
			local wait = createControlledThenable()

			local function Updater()
				local isPending, start = useTransition()
				startTransition = start
				return React.createElement(
					Text,
					{ text = "Pending: " .. tostring(isPending) .. ", " }
				)
			end

			local function App(props)
				local showUpdater, updateShowUpdater = useState(true)
				setShowUpdater = updateShowUpdater
				return React.createElement(
					React.Fragment,
					nil,
					if showUpdater then React.createElement(Updater) else nil,
					React.createElement(Text, { text = props.text })
				)
			end

			local root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { text = "A" }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Pending: false, ", "A" })
			jestExpect(root).toMatchRenderedOutput("Pending: false, A")

			ReactNoop.act(function()
				startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					startTransition(function()
						root.render(React.createElement(App, { text = "B" }))
					end)
					return wait:andThen(function()
						Scheduler.unstable_yieldValue("Async action ended")
						startTransition(function()
							root.render(React.createElement(App, { text = "C" }))
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Pending: true, ",
				"A",
			})
			jestExpect(root).toMatchRenderedOutput("Pending: true, A")

			ReactNoop.act(function()
				setShowUpdater(false)
			end)
			jestExpect(Scheduler).toHaveYielded({ "A" })
			jestExpect(root).toMatchRenderedOutput("A")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "C" })
			jestExpect(root).toMatchRenderedOutput("C")

			ReactNoop.act(function()
				root.render(React.createElement(App, { text = "D" }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "D" })
			jestExpect(root).toMatchRenderedOutput("D")
		end
	)

	it("React.startTransition supports async actions", function()
		local wait = createControlledThenable()
		local function App(props)
			return React.createElement(Text, { text = props.text })
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App, { text = "A" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "A" })

		ReactNoop.act(function()
			React.startTransition(function()
				root.render(React.createElement(App, { text = "B" }))
				return wait:andThen(function()
					root.render(React.createElement(App, { text = "C" }))
					Scheduler.unstable_yieldValue("Async action ended")
				end)
			end)
		end)
		jestExpect(Scheduler).toHaveYielded({})
		jestExpect(root).toMatchRenderedOutput("A")

		ReactNoop.act(function()
			wait:resolve(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({ "Async action ended", "C" })
		jestExpect(root).toMatchRenderedOutput("C")
	end)

	it(
		"useOptimistic works with async actions passed to React.startTransition",
		function()
			local setOptimisticText
			local wait = createControlledThenable()
			local root

			local function App(props)
				local text, updateOptimisticText = useOptimistic(
					props.text,
					function(_, optimisticText)
						return optimisticText .. " (loading...)"
					end
				)
				setOptimisticText = updateOptimisticText
				return React.createElement(Text, { text = text })
			end

			root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { text = "Initial" }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Initial" })
			jestExpect(root).toMatchRenderedOutput("Initial")

			ReactNoop.act(function()
				React.startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					setOptimisticText("Updated")
					return wait:andThen(function()
						Scheduler.unstable_yieldValue("Async action ended")
						React.startTransition(function()
							root.render(React.createElement(App, { text = "Updated" }))
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Async action started",
				"Updated (loading...)",
			})
			jestExpect(root).toMatchRenderedOutput("Updated (loading...)")

			ReactNoop.act(function()
				wait:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "Updated" })
			jestExpect(root).toMatchRenderedOutput("Updated")
		end
	)

	it(
		"regression: updates in an action passed to React.startTransition are batched even if there were no updates before the first await",
		function()
			local setOptimisticText
			local waitBeforeOptimistic = createControlledThenable()
			local waitBeforeCanonical = createControlledThenable()
			local root

			local function App(props)
				local text, updateOptimisticText = useOptimistic(
					props.text,
					function(_, optimisticText)
						return optimisticText .. " (loading...)"
					end
				)
				setOptimisticText = updateOptimisticText
				return React.createElement(Text, { text = text })
			end

			root = ReactNoop.createRoot()
			ReactNoop.act(function()
				root.render(React.createElement(App, { text = "Initial" }))
			end)
			jestExpect(Scheduler).toHaveYielded({ "Initial" })
			jestExpect(root).toMatchRenderedOutput("Initial")

			ReactNoop.act(function()
				React.startTransition(function()
					Scheduler.unstable_yieldValue("Async action started")
					return waitBeforeOptimistic:andThen(function()
						setOptimisticText("Updated")
						return waitBeforeCanonical:andThen(function()
							Scheduler.unstable_yieldValue("Async action ended")
							React.startTransition(function()
								root.render(
									React.createElement(App, { text = "Updated" })
								)
							end)
						end)
					end)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action started" })

			ReactNoop.act(function()
				waitBeforeOptimistic:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Updated (loading...)" })
			jestExpect(root).toMatchRenderedOutput("Updated (loading...)")

			ReactNoop.act(function()
				waitBeforeCanonical:resolve(nil)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Async action ended", "Updated" })
			jestExpect(root).toMatchRenderedOutput("Updated")
		end
	)

	it(
		"React.startTransition captures async errors and passes them to reportError",
		function()
			local action = createControlledThenable()
			ReactNoop.act(function()
				React.startTransition(function()
					return action
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({})

			ReactNoop.act(function()
				action:reject(Error("Oops"))
			end)
			jestExpect(Scheduler).toHaveYielded({ "reportError: Oops" })
		end
	)

	it(
		"React.startTransition captures sync errors and passes them to reportError",
		function()
			ReactNoop.act(function()
				React.startTransition(function()
					error(Error("Oops"), 0)
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "reportError: Oops" })
		end
	)
end)
