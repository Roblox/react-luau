-- ROBLOX upstream: https://github.com/facebook/react/blob/e9aa33ecc3715ebeacf28d453c6f18244719b359/packages/react-reconciler/src/__tests__/useSyncExternalStore-test.js
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/use-sync-external-store/src/__tests__/useSyncExternalStoreShared-test.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local Error = require(Packages.LuauPolyfill).Error

local React
local ReactNoop
local Scheduler
local useSyncExternalStore

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

type Store<T> = {
	getSnapshot: () -> T,
	getSubscriberCount: () -> number,
	set: (T, (() -> ())?) -> (),
	setWithoutNotification: (T) -> (),
	subscribe: (() -> ()) -> () -> (),
}

local function createStore<T>(
	initialState: T,
	onSubscribe: ((() -> (), (T) -> ()) -> ())?
): Store<T>
	local state = initialState
	local listeners = {}

	local function getSnapshot(): T
		return state
	end

	local function getSubscriberCount(): number
		return #listeners
	end

	local function setWithoutNotification(value: T): ()
		state = value
	end

	local function set(value: T, beforeReturn: (() -> ())?): ()
		state = value
		local currentListeners = table.clone(listeners)
		for _, listener in currentListeners do
			listener()
		end
		if beforeReturn ~= nil then
			beforeReturn()
		end
	end

	local function subscribe(listener: () -> ()): () -> ()
		table.insert(listeners, listener)
		if onSubscribe ~= nil then
			onSubscribe(listener, setWithoutNotification)
		end
		return function()
			local index = table.find(listeners, listener)
			if index ~= nil then
				table.remove(listeners, index)
			end
		end
	end

	return {
		getSnapshot = getSnapshot,
		getSubscriberCount = getSubscriberCount,
		set = set,
		setWithoutNotification = setWithoutNotification,
		subscribe = subscribe,
	}
end

local function Text(props)
	Scheduler.unstable_yieldValue(props.text)
	return React.createElement("span", { prop = props.text })
end

local function loadModules()
	jest.resetModules()
	jest.useFakeTimers()
	React = require(Packages.React)
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	Scheduler = require(Packages.Scheduler)
	useSyncExternalStore = React.useSyncExternalStore
end

local function createErrorBoundary()
	local ErrorBoundary = React.Component:extend("ErrorBoundary")
	function ErrorBoundary:init()
		self.state = { error_ = nil }
	end
	function ErrorBoundary.getDerivedStateFromError(error_)
		return { error_ = error_ }
	end
	function ErrorBoundary:render()
		if self.state.error_ ~= nil then
			return React.createElement(Text, { text = self.state.error_.message })
		end
		return self.props.children
	end
	return ErrorBoundary
end

describe("useSyncExternalStore", function()
	beforeEach(loadModules)

	it("subscribes to a store and skips unchanged snapshots", function()
		local store = createStore("Initial")
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "Initial" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "Initial" })
		)
		ReactNoop.flushPassiveEffects()

		store.set("Initial")
		jestExpect(Scheduler).toFlushAndYield({})

		store.set("Updated")
		jestExpect(Scheduler).toFlushAndYield({ "Updated" })
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "Updated" })
		)
	end)

	it("switches stores and unsubscribes from the previous store", function()
		local storeA = createStore(0)
		local storeB = createStore(0)
		local setStore

		local function App()
			local store, updateStore = React.useState(storeA)
			setStore = updateStore
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ 0 })
		ReactNoop.flushPassiveEffects()

		storeA.set(1)
		jestExpect(Scheduler).toFlushAndYield({ 1 })

		ReactNoop.flushSync(function()
			storeA.set(2)
			setStore(storeB)
		end)
		jestExpect(Scheduler).toHaveYielded({ 0 })
		ReactNoop.flushPassiveEffects()

		storeA.set(3)
		jestExpect(Scheduler).toFlushAndYield({})
		storeB.set(1)
		jestExpect(Scheduler).toFlushAndYield({ 1 })
	end)

	it("selects values inside getSnapshot", function()
		local store = createStore({ a = 0, b = 0 })
		local function A()
			local value = useSyncExternalStore(store.subscribe, function()
				return store.getSnapshot().a
			end)
			return React.createElement(Text, { text = "A" .. value })
		end
		local function B()
			local value = useSyncExternalStore(store.subscribe, function()
				return store.getSnapshot().b
			end)
			return React.createElement(Text, { text = "B" .. value })
		end

		ReactNoop.render(
			React.createElement(
				React.Fragment,
				nil,
				React.createElement(A),
				React.createElement(B)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({ "A0", "B0" })
		ReactNoop.flushPassiveEffects()

		store.set({ a = 0, b = 1 })
		jestExpect(Scheduler).toFlushAndYield({ "B1" })
		store.set({ a = 1, b = 1 })
		jestExpect(Scheduler).toFlushAndYield({ "A1" })
	end)

	it("uses the latest getSnapshot when it changes with a store update", function()
		local store = createStore({ a = 0, b = 0 })
		local function getSnapshotA()
			return store.getSnapshot().a
		end
		local function getSnapshotB()
			return store.getSnapshot().b
		end
		local setGetSnapshot
		local function App()
			local getSnapshot, updateGetSnapshot = React.useState(function()
				return getSnapshotA
			end)
			setGetSnapshot = updateGetSnapshot
			local value = useSyncExternalStore(store.subscribe, getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ 0 })
		ReactNoop.flushPassiveEffects()

		ReactNoop.flushSync(function()
			setGetSnapshot(function()
				return getSnapshotB
			end)
			store.set({ a = 1, b = 2 })
		end)
		jestExpect(Scheduler).toHaveYielded({ 2 })
	end)

	it("caches the next value across render-phase updates", function()
		local store = createStore("value:initial")
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			local sameValue, setSameValue = React.useState(value)
			if value ~= sameValue then
				setSameValue(value)
			end
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "value:initial" })
		ReactNoop.flushPassiveEffects()

		store.set("value:changed")
		jestExpect(Scheduler).toFlushAndYield({ "value:changed" })
		store.set("value:initial")
		jestExpect(Scheduler).toFlushAndYield({ "value:initial" })
	end)

	it("detects interleaved mutations before layout effects fire", function()
		local store1 = createStore(0)
		local store2 = createStore(0)
		local renderedValues = {}

		local function Child(props)
			local value =
				useSyncExternalStore(props.store.subscribe, props.store.getSnapshot)
			Scheduler.unstable_yieldValue(props.label .. value)
			React.useLayoutEffect(function()
				renderedValues[props.label] = value
			end, { value })
			return nil
		end

		local function App(props)
			React.useLayoutEffect(function()
				Scheduler.unstable_yieldValue(
					"layout:A"
						.. renderedValues.A
						.. "B"
						.. renderedValues.B
						.. "C"
						.. renderedValues.C
				)
			end)
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Child, { label = "A", store = props.store }),
				React.createElement(Child, { label = "B", store = props.store }),
				React.createElement(Child, { label = "C", store = props.store })
			)
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App, { store = store1 }))
		jestExpect(Scheduler).toFlushAndYieldThrough({ "A0", "B0" })
		store1.setWithoutNotification(1)
		jestExpect(Scheduler).toFlushAndYield({
			"C1",
			"A1",
			"B1",
			"C1",
			"layout:A1B1C1",
		})

		root.render(React.createElement(App, { store = store2 }))
		jestExpect(Scheduler).toFlushAndYieldThrough({ "A0", "B0" })
		store2.setWithoutNotification(1)
		jestExpect(Scheduler).toFlushAndYield({
			"C1",
			"A1",
			"B1",
			"C1",
			"layout:A1B1C1",
		})
	end)

	it("catches a silent mutation before the passive subscription", function()
		local store = createStore(0)
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushUntilNextPaint({ 0 })
		jestExpect(store.getSubscriberCount()).toBe(0)

		store.setWithoutNotification(1)
		jestExpect(Scheduler).toFlushAndYield({ 1 })
		jestExpect(store.getSubscriberCount()).toBe(1)
	end)

	it("catches a reentrant mutation while subscribing", function()
		local didMutate = false
		local store = createStore(0, function(listener, setWithoutNotification)
			if not didMutate then
				didMutate = true
				setWithoutNotification(1)
				listener()
			end
		end)
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushUntilNextPaint({ 0 })
		jestExpect(Scheduler).toFlushAndYield({ 1 })
		jestExpect(store.getSubscriberCount()).toBe(1)
	end)

	it("defers unbatched listener updates on a concurrent root", function()
		local store = createStore(0)
		local committedValues = { A = 0, B = 0, C = 0 }

		local function Consumer(props)
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			Scheduler.unstable_yieldValue(props.label .. value)
			React.useLayoutEffect(function()
				committedValues[props.label] = value
			end, { value })
			return nil
		end

		local function App()
			React.useLayoutEffect(function()
				Scheduler.unstable_yieldValue(
					"layout:"
						.. committedValues.A
						.. committedValues.B
						.. committedValues.C
				)
			end)
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Consumer, { label = "A" }),
				React.createElement(Consumer, { label = "B" }),
				React.createElement(Consumer, { label = "C" })
			)
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "A0", "B0", "C0", "layout:000" })
		ReactNoop.flushPassiveEffects()

		store.set(1)
		jestExpect(Scheduler.unstable_clearYields()).toEqual({})
		jestExpect(Scheduler).toFlushAndYield({ "A1", "B1", "C1", "layout:111" })
	end)

	it("flushes store updates inline on a legacy root", function()
		local store = createStore(0)
		local committedValue = nil
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			Scheduler.unstable_yieldValue("render:" .. value)
			React.useLayoutEffect(function()
				committedValue = value
			end, { value })
			return nil
		end

		local root = ReactNoop.createLegacyRoot()
		ReactNoop.act(function()
			root.render(React.createElement(App))
		end)
		jestExpect(Scheduler).toHaveYielded({ "render:0" })
		ReactNoop.flushPassiveEffects()

		local valueBeforeSetterReturn
		store.set(1, function()
			valueBeforeSetterReturn = committedValue
		end)
		jestExpect(valueBeforeSetterReturn).toBe(1)
		jestExpect(Scheduler).toHaveYielded({ "render:1" })
	end)

	it("flushes store updates inside flushSync on a concurrent root", function()
		local store = createStore(0)
		local committedValue = nil
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			Scheduler.unstable_yieldValue("render:" .. value)
			React.useLayoutEffect(function()
				committedValue = value
			end, { value })
			return nil
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "render:0" })
		ReactNoop.flushPassiveEffects()

		ReactNoop.flushSync(function()
			store.set(1)
		end)
		jestExpect(committedValue).toBe(1)
		jestExpect(Scheduler).toHaveYielded({ "render:1" })
	end)

	it("preserves store updates scheduled from layout effects", function()
		local store = createStore(0)
		local function App(props)
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			Scheduler.unstable_yieldValue("render:" .. value)
			React.useLayoutEffect(function()
				Scheduler.unstable_yieldValue("layout:" .. value)
				if props.updateStore and value == 0 then
					store.set(1)
				end
			end, { value, props.updateStore })
			return nil
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App, { updateStore = false }))
		jestExpect(Scheduler).toFlushAndYield({ "render:0", "layout:0" })
		ReactNoop.flushPassiveEffects()

		root.render(React.createElement(App, { updateStore = true }))
		jestExpect(Scheduler).toFlushAndYield({
			"render:0",
			"layout:0",
			"render:1",
			"layout:1",
		})
	end)

	it("does not bail out while a previous update is unfinished", function()
		local store = createStore(0)
		local function First()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			React.useLayoutEffect(function()
				if value == 1 then
					Scheduler.unstable_yieldValue("reset")
					store.set(0)
				end
			end, { value })
			return React.createElement(Text, { text = "A" .. value })
		end
		local function Second()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			return React.createElement(Text, { text = "B" .. value })
		end

		ReactNoop.render(
			React.createElement(
				React.Fragment,
				nil,
				React.createElement(First),
				React.createElement(Second)
			)
		)
		jestExpect(Scheduler).toFlushAndYield({ "A0", "B0" })
		ReactNoop.flushPassiveEffects()

		store.set(1)
		jestExpect(Scheduler).toFlushAndYield({ "A1", "B1", "reset", "A0", "B0" })
	end)

	it("uses the new getSnapshot after a commit-phase mutation", function()
		local store = createStore({ a = 1, b = 1 })
		local setStep
		local function Mutator(props)
			local state = useSyncExternalStore(store.subscribe, store.getSnapshot)
			React.useLayoutEffect(function()
				if props.step == 1 then
					Scheduler.unstable_yieldValue("mutate")
					store.set({ a = state.a, b = 2 })
				end
			end, { props.step })
			return nil
		end
		local function Reader(props)
			local getSnapshot = if props.step == 0
				then function()
					return store.getSnapshot().a
				end
				else function()
					return store.getSnapshot().b
				end
			local value = useSyncExternalStore(store.subscribe, getSnapshot)
			return React.createElement(Text, {
				text = (if props.step == 0 then "A" else "B") .. value,
			})
		end
		local function App()
			local step, updateStep = React.useState(0)
			setStep = updateStep
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Mutator, { step = step }),
				React.createElement(Reader, { step = step })
			)
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "A1" })
		ReactNoop.flushPassiveEffects()

		setStep(1)
		jestExpect(Scheduler).toFlushAndYield({ "B1", "mutate", "B2" })
	end)

	it("bails out after a commit-phase mutation when the snapshot is stable", function()
		local store = createStore({ a = 1, b = 1 })
		local setStep
		local function Mutator(props)
			local state = useSyncExternalStore(store.subscribe, store.getSnapshot)
			React.useLayoutEffect(function()
				if props.step == 1 then
					Scheduler.unstable_yieldValue("mutate")
					store.set({ a = state.a, b = 2 })
				end
			end, { props.step })
			return nil
		end
		local function Reader()
			local value = useSyncExternalStore(store.subscribe, function()
				return store.getSnapshot().a
			end)
			return React.createElement(Text, { text = "A" .. value })
		end
		local function App()
			local step, updateStep = React.useState(0)
			setStep = updateStep
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(Mutator, { step = step }),
				React.createElement(Reader)
			)
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "A1" })
		ReactNoop.flushPassiveEffects()

		setStep(1)
		jestExpect(Scheduler).toFlushAndYield({ "A1", "mutate" })
	end)

	it("handles errors thrown while reading the snapshot", function()
		local shouldThrow = false
		local store = createStore(0)
		local ErrorBoundary = createErrorBoundary()
		local function getSnapshot()
			if shouldThrow then
				error(Error.new("snapshot error"))
			end
			return store.getSnapshot()
		end
		local function App()
			local value = useSyncExternalStore(store.subscribe, getSnapshot)
			return React.createElement(Text, { text = value })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		jestExpect(Scheduler).toFlushAndYield({ 0 })
		ReactNoop.flushPassiveEffects()

		shouldThrow = true
		jestExpect(function()
			store.set(1)
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toErrorDev("The above error occurred in the <App> component:", {
			logAllErrors = true,
		})
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "snapshot error" })
		)
	end)

	it("retries a consistency check that throws through an error boundary", function()
		local shouldThrow = false
		local store = createStore(0)
		local ErrorBoundary = createErrorBoundary()

		local function getSnapshot()
			if shouldThrow then
				error(Error.new("snapshot error"))
			end
			return store.getSnapshot()
		end
		local function App()
			local value = useSyncExternalStore(store.subscribe, getSnapshot)
			Scheduler.unstable_yieldValue(value)
			React.useLayoutEffect(function()
				Scheduler.unstable_yieldValue("layout:" .. value)
			end, { value })
			return React.createElement(Text, { text = "tail" })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(ErrorBoundary, nil, React.createElement(App)))
		jestExpect(Scheduler).toFlushAndYieldThrough({ 0 })
		shouldThrow = true
		jestExpect(function()
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toErrorDev("The above error occurred in the <App> component:", {
			logAllErrors = true,
		})
		local yields = Scheduler.unstable_clearYields()
		jestExpect(yields).never.toContain("layout:0")
		jestExpect(root).toMatchRenderedOutput(
			React.createElement("span", { prop = "snapshot error" })
		)
	end)

	it("uses Object.is semantics for NaN and signed zero", function()
		local nan = math.huge - math.huge
		local store = createStore(nan)
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			local text
			if value ~= value then
				text = "NaN"
			elseif 1 / value == math.huge then
				text = "+0"
			else
				text = "-0"
			end
			return React.createElement(Text, { text = text })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "NaN" })
		ReactNoop.flushPassiveEffects()

		store.set(nan)
		jestExpect(Scheduler).toFlushAndYield({})
		store.set(0)
		jestExpect(Scheduler).toFlushAndYield({ "+0" })
		store.set(-1 / math.huge)
		jestExpect(Scheduler).toFlushAndYield({ "-0" })
	end)

	local itIfDev = if ReactGlobals.__DEV__ then it else it.skip :: any
	itIfDev("warns when getSnapshot is not cached", function()
		local readCount = 0
		local function getSnapshot()
			readCount += 1
			if readCount > 1000 then
				error(Error.new("uncached snapshot test exceeded its read limit"))
			end
			return {}
		end
		local function App()
			useSyncExternalStore(function()
				return function() end
			end, getSnapshot)
			return nil
		end

		local root = ReactNoop.createRoot()
		jestExpect(function()
			jestExpect(function()
				ReactNoop.act(function()
					root.render(React.createElement(App))
				end)
			end).toThrow("Maximum update depth exceeded")
		end).toErrorDev(
			"The result of getSnapshot should be cached to avoid an infinite loop"
		)
	end)

	local itIfProd = if ReactGlobals.__DEV__ then it.skip :: any else it
	itIfProd("handles render-phase updates in production", function()
		local store = createStore("Initial")
		local function App()
			local value = useSyncExternalStore(store.subscribe, store.getSnapshot)
			local derivedValue, setDerivedValue = React.useState(value)
			React.useEffect(function() end, {})
			local upperValue = string.upper(value)
			if derivedValue ~= upperValue then
				setDerivedValue(upperValue)
			end
			return React.createElement(Text, { text = derivedValue })
		end

		local root = ReactNoop.createRoot()
		root.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({ "INITIAL" })
		ReactNoop.flushPassiveEffects()

		store.set("Updated")
		jestExpect(Scheduler).toFlushAndYield({ "UPDATED" })
	end)
end)
