--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/profilingCache-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local xdescribe = JestGlobals.xdescribe
local it = JestGlobals.it
local xit = JestGlobals.xit
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error

local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge

local devtoolsTypes = require(script.Parent.Parent.devtools.types)
type Store = devtoolsTypes.Store

local ProfilerTypes = require(script.Parent.Parent.devtools.views.Profiler.types)
type ProfilingDataFrontend = ProfilerTypes.ProfilingDataFrontend

local global = ReactGlobals :: any

-- ROBLOX deviation START: inline simplified PropTypes logic
-- ROBLOX FIXME luau: if not annotated, gets 'Failed ot unify type packs'
local function propTypes(value: any, expectedType): any
	if value == nil then
		return nil
	end
	if type(value) ~= expectedType then
		return Error("expected " .. expectedType)
	end
	return nil
end
local PropTypes = {
	number = function(props, typeSpecName)
		return propTypes(props[typeSpecName], "number")
	end,
	string = function(props, typeSpecName)
		return propTypes(props[typeSpecName], "string")
	end,
}
-- ROBLOX deviation END

xdescribe("ProfilingCache", function()
	local React
	local ReactRoblox
	local Scheduler
	local SchedulerTracing
	local bridge: FrontendBridge
	local store: Store
	local utils
	local act

	beforeEach(function()
		ReactGlobals.__PROFILE__ = true
		utils = require(script.Parent.utils)
		act = utils.act

		bridge = global.bridge
		store = global.store
		store:setCollapseNodesByDefault(false)
		store:setRecordChangeDescriptions(true)

		--PropTypes = require_("prop-types")
		React = require(Packages.React)
		ReactRoblox = require(Packages.ReactRoblox)
		Scheduler = require(Packages.Dev.Scheduler)
		SchedulerTracing = Scheduler.tracing

		utils.beforeEachProfiling()
	end)

	afterEach(function()
		ReactGlobals.__PROFILE__ = nil
	end)

	it(
		"should collect data for each root (including ones added or mounted after profiling started)",
		function()
			local function Child(props)
				Scheduler.unstable_advanceTime(props.duration)
				return nil
			end

			local MemoizedChild = React.memo(Child)

			local function Parent(props)
				Scheduler.unstable_advanceTime(10)

				local count = props.count
				local children = table.create(count) :: any
				for index = 0, count - 1 do
					children[index + 1] =
						React.createElement(Child, { key = index, duration = index })
				end

				return React.createElement(
					React.Fragment,
					nil,
					children,
					React.createElement(MemoizedChild, { duration = 1 })
				)
			end

			local containerA = ReactRoblox.createRoot(Instance.new("Frame"))
			local containerB = ReactRoblox.createRoot(Instance.new("Frame"))
			local containerC = ReactRoblox.createRoot(Instance.new("Frame"))
			act(function()
				return containerA:render(React.createElement(Parent, { count = 2 }))
			end)

			act(function()
				return containerB:render(React.createElement(Parent, { count = 1 }))
			end)
			act(function()
				return store._profilerStore:startProfiling()
			end)
			act(function()
				return containerA:render(React.createElement(Parent, { count = 3 }))
			end)
			act(function()
				return containerC:render(React.createElement(Parent, { count = 1 }))
			end)
			act(function()
				return containerA:render(React.createElement(Parent, { count = 1 }))
			end)
			act(function()
				return containerB:render(nil)
			end)
			act(function()
				return containerA:render(React.createElement(Parent, { count = 0 }))
			end)
			act(function()
				return store._profilerStore:stopProfiling()
			end)

			local allProfilingDataForRoots = {}
			local function Validator(rootID, previousProfilingDataForRoot)
				local profilingDataForRoot = store._profilerStore:getDataForRoot(rootID)

				if previousProfilingDataForRoot ~= nil then
					jestExpect(profilingDataForRoot).toEqual(previousProfilingDataForRoot)
				else
					jestExpect(profilingDataForRoot).toMatchSnapshot(
						string.format(
							"Data for root %s",
							tostring(profilingDataForRoot.displayName)
						)
					)
				end
				table.insert(allProfilingDataForRoots, profilingDataForRoot)
			end

			local profilingData = store._profilerStore:profilingData()
			local dataForRoots = if profilingData ~= nil
				then profilingData.dataForRoots
				else nil
			jestExpect(dataForRoots).never.toBeNull()

			if dataForRoots ~= nil then
				dataForRoots:forEach(function(dataForRoot)
					Validator(dataForRoot.rootID, nil)
				end)
			end
			jestExpect(#allProfilingDataForRoots).toBe(3)
			utils.exportImportHelper(bridge, store)

			for _, profilingDataForRoot in allProfilingDataForRoots do
				Validator(profilingDataForRoot.rootID, profilingDataForRoot)
			end
		end
	)
	it("should collect data for each commit", function()
		local MemoizedChild, Child
		local function Parent(props)
			Scheduler.unstable_advanceTime(10)

			local count = props.count
			local children = table.create(count) :: any
			for index = 0, count - 1 do
				children[index + 1] =
					React.createElement(Child, { key = index, duration = index })
			end

			return React.createElement(
				React.Fragment,
				nil,
				children,
				React.createElement(MemoizedChild, { key = -1, duration = 1 })
			)
		end
		function Child(ref)
			local duration = ref.duration
			Scheduler.unstable_advanceTime(duration)
			return nil
		end
		MemoizedChild = React.memo(Child)

		-- ROBLOX deviation START: use Roblox renderer
		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		-- ROBLOX deviation END

		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 2 }))
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 3 }))
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 1 }))
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 0 }))
		end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)
		local allCommitData = {}
		local function Validator(ref)
			local commitIndex, previousCommitDetails, rootID =
				ref.commitIndex, ref.previousCommitDetails, ref.rootID
			local commitData = store._profilerStore:getCommitData(rootID, commitIndex)
			if previousCommitDetails ~= nil then
				jestExpect(commitData).toEqual(previousCommitDetails)
			else
				table.insert(allCommitData, commitData)
				jestExpect(commitData).toMatchSnapshot(
					string.format("CommitDetails commitIndex: %d", commitIndex - 1)
				)
			end
		end
		local rootID = store:getRoots()[1]

		for commitIndex = 1, 4 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = nil,
				rootID = rootID,
			})
		end
		jestExpect(#allCommitData).toBe(4)
		utils.exportImportHelper(bridge, store)

		for commitIndex = 1, 4 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = allCommitData[commitIndex],
				rootID = rootID,
			})
		end
	end)
	it("should record changed props/state/context/hooks", function()
		local LegacyContextConsumer, ModernContextConsumer
		local instance = nil
		local ModernContext = React.createContext(0)

		local LegacyContextProvider = React.Component:extend("LegacyContextProvider")
		LegacyContextProvider.childContextTypes = { count = PropTypes.number }

		function LegacyContextProvider:init()
			self:setState({ count = 0 })
		end
		function LegacyContextProvider:getChildContext()
			return self.state
		end
		function LegacyContextProvider:render()
			return React.createElement(
				ModernContext.Provider,
				{
					value = self.state.count,
				},
				React.createElement(React.Fragment, nil, {
					React.createElement(ModernContextConsumer),
					React.createElement(LegacyContextConsumer),
				})
			)
		end

		local function FunctionComponentWithHooks(ref)
			local count = ref.count
			React.useMemo(function()
				return count
			end, { count })
			return nil
		end
		ModernContextConsumer = React.Component:extend("ModernContextConsumer")
		function ModernContextConsumer:render()
			return React.createElement(
				FunctionComponentWithHooks,
				{ count = self.context }
			)
		end

		LegacyContextConsumer = React.Component:extend("LegacyContextConsumer")
		function LegacyContextConsumer:render()
			instance = self
			return React.createElement(
				FunctionComponentWithHooks,
				{ count = self.context.count }
			)
		end

		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return container:render(React.createElement(LegacyContextProvider, nil))
		end)
		jestExpect(instance).never.toBeNull()
		act(function()
			return (instance :: any):setState({ count = 1 })
		end)
		act(function()
			return container:render(
				React.createElement(LegacyContextProvider, { foo = 123 })
			)
		end)
		act(function()
			return container:render(
				React.createElement(LegacyContextProvider, { bar = "abc" })
			)
		end)
		act(function()
			return container:render(React.createElement(LegacyContextProvider, nil))
		end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)
		local allCommitData = {}
		local function Validator(ref)
			local commitIndex, previousCommitDetails, rootID =
				ref.commitIndex, ref.previousCommitDetails, ref.rootID
			local commitData = store._profilerStore:getCommitData(rootID, commitIndex)
			if previousCommitDetails ~= nil then
				jestExpect(commitData).toEqual(previousCommitDetails)
			else
				table.insert(allCommitData, commitData)
				jestExpect(commitData).toMatchSnapshot(
					string.format("CommitDetails commitIndex: %d", commitIndex - 1)
				)
			end
		end
		local rootID = store:getRoots()[1]
		for commitIndex = 1, 5 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = nil,
				rootID = rootID,
			})
		end
		jestExpect(allCommitData).toHaveLength(5)
		utils.exportImportHelper(bridge, store)
		for commitIndex = 1, 5 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = allCommitData[commitIndex],
				rootID = rootID,
			})
		end
	end)

	-- ROBLOX FIXME: upstream has priorityLevel as "Immediate"
	-- ROBLOX FIXME: upstream has didHooksChange as false in this step. maybe related to the priorityLevel difference below?
	-- ROBLOX Note: These bugs only happen in CommitIndex 1 1
	it("should properly detect changed hooks", function()
		local Context = React.createContext(0)
		local function reducer(state, action)
			if action.type == "invert" then
				return { value = not state.value }
			else
				error(Error.new())
			end
		end
		local dispatch
		local setState
		local function Component(ref)
			local string_ = ref.string
			local _
			-- These hooks may change and initiate re-renders.
			_, setState = React.useState("abc")
			-- ROBLOX FIXME Luau: without this any cast, Type '{| value: boolean |}' could not be converted into 'string'
			_, dispatch = React.useReducer(reducer :: any, { value = true })

			-- This hook's return value may change between renders,
			-- but the hook itself isn't stateful.
			React.useContext(Context)

			-- These hooks and their dependencies may not change between renders.
			-- We're using them to ensure that they don't trigger false positives.
			React.useCallback(function()
				return function() end
			end, { string_ })
			React.useMemo(function()
				return string_
			end, { string_ })

			-- These hooks never "change".
			React.useEffect(function() end, { string_ })
			React.useLayoutEffect(function() end, { string_ })

			return nil
		end

		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return container:render(
				React.createElement(
					Context.Provider,
					{ value = true },
					React.createElement(Component, { count = 1 })
				)
			)
		end)

		-- Second render has no changed hooks, only changed props.
		act(function()
			return container:render(
				React.createElement(
					Context.Provider,
					{ value = true },
					React.createElement(Component, { count = 2 })
				)
			)
		end)

		-- Third render has a changed reducer hook
		act(function()
			return dispatch({ type = "invert" })
		end)

		-- Fourth render has a changed state hook
		act(function()
			return setState("def")
		end)

		-- Fifth render has a changed context value, but no changed hook.
		-- Technically, DevTools will miss this "context" change since it only tracks legacy context.
		act(function()
			return container:render(
				React.createElement(
					Context.Provider,
					{ value = false },
					React.createElement(Component, { count = 2 })
				)
			)
		end)

		act(function()
			return store._profilerStore:stopProfiling()
		end)

		local allCommitData = {}

		local function Validator(ref)
			local commitIndex, previousCommitDetails, rootID =
				ref.commitIndex, ref.previousCommitDetails, ref.rootID
			local commitData = store._profilerStore:getCommitData(rootID, commitIndex)
			if previousCommitDetails ~= nil then
				jestExpect(commitData).toEqual(previousCommitDetails)
			else
				table.insert(allCommitData, commitData)
				jestExpect(commitData).toMatchSnapshot(
					string.format(
						"CommitDetails commitIndex: %s",
						tostring(commitIndex - 1)
					)
				)
			end
			return nil
		end
		local rootID = store:getRoots()[1]
		for commitIndex = 1, 5 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = nil,
				rootID = rootID,
			})
		end

		jestExpect(allCommitData).toHaveLength(5)

		-- Export and re-import profile data and make sure it is retained.
		utils.exportImportHelper(bridge, store)

		for commitIndex = 1, 5 do
			Validator({
				commitIndex = commitIndex,
				previousCommitDetails = allCommitData[commitIndex],
				rootID = rootID,
			})
		end
	end)
	it(
		"should calculate a self duration based on actual children (not filtered children)",
		function()
			local Parent, Child
			store:setComponentFilters({ utils.createDisplayNameFilter("^Parent$") })
			local function Grandparent()
				Scheduler.unstable_advanceTime(10)
				return React.createElement(
					React.Fragment,
					nil,
					React.createElement(Parent, { key = "one" }),
					React.createElement(Parent, { key = "two" })
				)
			end
			function Parent()
				Scheduler.unstable_advanceTime(2)
				return React.createElement(Child, nil)
			end
			function Child()
				Scheduler.unstable_advanceTime(1)
				return nil
			end
			act(function()
				return store._profilerStore:startProfiling()
			end)
			act(function()
				return ReactRoblox.createRoot(Instance.new("Frame"))
					:render(React.createElement(Grandparent, nil))
			end)
			act(function()
				return store._profilerStore:stopProfiling()
			end)
			local commitData = nil
			local function Validator(ref)
				local commitIndex, rootID = ref.commitIndex, ref.rootID
				commitData = store._profilerStore:getCommitData(rootID, commitIndex)
				jestExpect(commitData).toMatchSnapshot(
					"CommitDetails with filtered self durations"
				)
			end
			local rootID = store:getRoots()[1]
			Validator({ commitIndex = 1, rootID = rootID })
			jestExpect(commitData).never.toBeNull()
		end
	)
	--[=[
		xit("should calculate self duration correctly for suspended views", function(done)
			local Fallback, Async
			return Promise.resolve():andThen(function()
				local data
				local function getData()
					if data then
						return data
					else
						error(Promise.new(function(resolve)
							data = "abc"
							resolve(data)
						end))
					end
				end
				local function Parent()
					Scheduler.unstable_advanceTime(10)
					return React.createElement(
						React.Suspense,
						{ fallback = React.createElement(Fallback, nil) },
						React.createElement(Async, nil)
					)
				end
				function Fallback()
					Scheduler.unstable_advanceTime(2)
					return "Fallback..."
				end
				function Async()
					Scheduler.unstable_advanceTime(3)
					return getData()
				end
				act(function()
					return store._profilerStore:startProfiling()
				end)
				utils
					:actAsync(function()
						return ReactDOM:render(
							React.createElement(Parent, nil),
							document:createElement("div")
						)
					end)
					:jestExpect()
				act(function()
					return store._profilerStore:stopProfiling()
				end)
				local allCommitData = {}
				local function Validator(ref)
					local commitIndex, rootID = ref.commitIndex, ref.rootID
					local commitData = store._profilerStore:getCommitData(
						rootID,
						commitIndex
					)
					table.insert(allCommitData, commitData) --[[ ROBLOX CHECK: check if 'allCommitData' is an Array ]]
					jestExpect(commitData).toMatchSnapshot(
						"CommitDetails with filtered self durations"
					)
					return nil
				end
				local rootID = store.roots[
					1 --[[ ROBLOX adaptation: added 1 to array index ]]
				]
				do
					local function _loop(commitIndex)
						act(function()
							TestRenderer:create(
								React.createElement(
									Validator,
									{ commitIndex = commitIndex, rootID = rootID }
								)
							)
						end)
					end
					local commitIndex = 0
					while
						commitIndex
						< 2 --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
					do
						_loop(commitIndex)
						commitIndex += 1
					end
				end
				jestExpect(allCommitData).toHaveLength(2)
				done()
			end)
		end)
		--]=]
	it("should collect data for each rendered fiber", function()
		local MemoizedChild, Child
		local function Parent(props)
			Scheduler.unstable_advanceTime(10)

			local count = props.count
			local children = table.create(count) :: any
			for index = 0, count - 1 do
				children[index + 1] =
					React.createElement(Child, { key = index, duration = index })
			end

			return React.createElement(
				React.Fragment,
				nil,
				children,
				React.createElement(MemoizedChild, { key = -1, duration = 1 })
			)
		end
		function Child(ref)
			local duration = ref.duration
			Scheduler.unstable_advanceTime(duration)
			return nil
		end
		MemoizedChild = React.memo(Child)

		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 1 }))
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 2 }))
		end)
		act(function()
			return container:render(React.createElement(Parent, { count = 3 }))
		end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)

		local allFiberCommits = {}
		local function Validator(ref)
			local fiberID, previousFiberCommits, rootID =
				ref.fiberID, ref.previousFiberCommits, ref.rootID
			local fiberCommits = store._profilerStore:profilingCache():getFiberCommits({
				fiberID = fiberID,
				rootID = rootID,
			})
			if previousFiberCommits ~= nil then
				jestExpect(fiberCommits).toEqual(previousFiberCommits)
			else
				table.insert(allFiberCommits, fiberCommits)
				jestExpect(fiberCommits).toMatchSnapshot(
					string.format("FiberCommits: element %d", fiberID)
				)
			end
		end
		local rootID = store:getRoots()[1]

		for index = 0, store:getNumElements() - 1 do
			local fiberID = store:getElementIDAtIndex(index)
			if fiberID == nil then
				error(
					string.format(
						"Unexpected null ID for element at index %s",
						tostring(index)
					)
				)
			end

			Validator({
				fiberID = fiberID,
				previousFiberCommits = nil,
				rootID = rootID,
			})
		end

		jestExpect(allFiberCommits).toHaveLength(store:getNumElements())
		utils.exportImportHelper(bridge, store)

		--[=[ ROBLOX FIXME: 0-based indexing gets ruined by deserializing
			for index = 0, store:getNumElements() - 1 do
				local fiberID = store:getElementIDAtIndex(index)
				if fiberID == nil then
					error(
						string.format(
							"Unexpected null ID for element at index %s",
							tostring(index)
						)
					)
				end

				Validator({
					fiberID = fiberID,
					previousFiberCommits = allFiberCommits[index],
					rootID = rootID,
				})
			end
			--]=]
	end)
	it("should report every traced interaction", function()
		local MemoizedChild, Child
		local function Parent(props)
			Scheduler.unstable_advanceTime(10)

			local count = props.count
			local children = table.create(count) :: any
			for index = 0, count - 1 do
				children[index + 1] =
					React.createElement(Child, { key = index, duration = index })
			end

			return React.createElement(
				React.Fragment,
				nil,
				children,
				React.createElement(MemoizedChild, { key = -1, duration = 1 })
			)
		end
		function Child(ref)
			local duration = ref.duration
			Scheduler.unstable_advanceTime(duration)
			return nil
		end
		MemoizedChild = React.memo(Child)

		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return SchedulerTracing.unstable_trace(
				"mount: one child",
				Scheduler.unstable_now(),
				function()
					return container:render(React.createElement(Parent, { count = 1 }))
				end
			)
		end)
		act(function()
			return SchedulerTracing.unstable_trace(
				"update: two children",
				Scheduler.unstable_now(),
				function()
					return container:render(React.createElement(Parent, { count = 2 }))
				end
			)
		end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)
		local interactions = nil
		local function Validator(ref)
			local previousInteractions, rootID = ref.previousInteractions, ref.rootID
			interactions =
				store._profilerStore:profilingCache():getInteractionsChartData({
					rootID = rootID,
				}).interactions
			-- ROBLOX FIXME: interactions[0] supposed to have __count=1, but it's 0 once it gets to the ProfilerStore. it's correct in WorkLoop and Tracing.
			if previousInteractions ~= nil then
				jestExpect(interactions).toEqual(previousInteractions)
			else
				jestExpect(interactions).toMatchSnapshot("Interactions")
			end
			return nil
		end
		local rootID = store:getRoots()[1]
		Validator({ previousInteractions = nil, rootID = rootID })

		jestExpect(interactions).never.toBeNull()
		utils.exportImportHelper(bridge, store)

		Validator({ previousInteractions = interactions, rootID = rootID })
	end)
	it("should handle unexpectedly shallow suspense trees", function()
		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return store._profilerStore:startProfiling()
		end)
		act(function()
			return container:render(React.createElement(React.Suspense, nil))
		end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)

		local rootID = store:getRoots()[1]
		local profilingDataForRoot = store._profilerStore:getDataForRoot(rootID)
		jestExpect(profilingDataForRoot).toMatchSnapshot("Empty Suspense node")
	end)

	-- ROBLOX TODO: needs a textContent helper for ReactRoblox renderers
	-- See https://github.com/facebook/react/issues/18831
	xit("should not crash during route transitions with Suspense", function()
		local Router, Switch, Route, About, Home, Link
		local RouterContext = React.createContext(nil)
		local function App()
			return React.createElement(
				Router,
				nil,
				React.createElement(
					Switch,
					nil,
					React.createElement(
						Route,
						{ path = "/" },
						React.createElement(Home, nil)
					),
					React.createElement(
						Route,
						{ path = "/about" },
						React.createElement(About, nil)
					)
				)
			)
		end
		function Home()
			return React.createElement(
				React.Suspense,
				nil,
				React.createElement(
					Link,
					{ path = "/about" },
					React.createElement("TextLabel", { Text = "Home" })
				)
			)
		end
		function About()
			return React.createElement("TextLabel", { Text = "About" })
		end

		-- Mimics https://github.com/ReactTraining/react-router/blob/master/packages/react-router/modules/Router.js
		function Router(ref)
			local children = ref.children
			local path, setPath = React.useState("/")
			return React.createElement(
				RouterContext.Provider,
				{ value = { path = path, setPath = setPath } },
				children
			)
		end

		-- Mimics https://github.com/ReactTraining/react-router/blob/master/packages/react-router/modules/Switch.js
		function Switch(ref)
			local children = ref.children
			return React.createElement(RouterContext.Consumer, nil, function(context)
				local element = nil
				React.Children.forEach(children, function(child: any)
					if context.path == child.props.path then
						element = child.props.children
					end
				end)
				return if element then React.cloneElement(element) else nil
			end)
		end

		-- Mimics https://github.com/ReactTraining/react-router/blob/master/packages/react-router/modules/Route.js
		function Route(ref)
			return nil
		end
		local linkRef = React.createRef()

		-- Mimics https://github.com/ReactTraining/react-router/blob/master/packages/react-router-dom/modules/Link.js
		function Link(ref)
			local children, path = ref.children, ref.path
			return React.createElement(RouterContext.Consumer, nil, function(context)
				return React.createElement("TextButton", {
					ref = linkRef,
					[ReactRoblox.Event.Activated] = function()
						return context:setPath(path)
					end,
				}, children)
			end)
		end
		-- ROBLOX TODO: emulate this and uncomment the expect
		-- local Simulate = require_("react-dom/test-utils").Simulate
		local container = ReactRoblox.createRoot(Instance.new("Frame"))
		act(function()
			return container:render(React.createElement(App))
		end)
		jestExpect(container.textContent).toBe("Home")
		act(function()
			return store._profilerStore:startProfiling()
		end)
		-- act(function()
		-- 	return Simulate:click(linkRef.current)
		-- end)
		act(function()
			return store._profilerStore:stopProfiling()
		end)
		jestExpect(container.textContent).toBe("About")
	end)
end)
