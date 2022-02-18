-- upstream: https://github.com/facebook/react/blob/99cae887f3a8bde760a111516d254c1225242edf/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

--[[ eslint-disable no-func-assign ]]
local Packages = script.Parent.Parent.Parent
local React

local LuauPolyfill
local clearTimeout
local setTimeout
local Array
local Promise


-- local textCache
-- local readText
-- local resolveText
local ReactNoop
local Scheduler
-- local SchedulerTracing
local Suspense
local useState
local useReducer
local useEffect
local useLayoutEffect
local useCallback
local useMemo
local useRef
local useImperativeHandle
-- local useTransition
-- local useDeferredValue
local forwardRef
local memo
local act

return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	beforeEach(function()
		RobloxJest.resetModules()
 		RobloxJest.useFakeTimers()
		LuauPolyfill = require(Packages.LuauPolyfill)
		clearTimeout = LuauPolyfill.clearTimeout
		setTimeout = LuauPolyfill.setTimeout
		Array = LuauPolyfill.Array
		Promise = require(Packages.Promise)

		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		-- SchedulerTracing = require(Scheduler.tracing)
		useState = React.useState
		useReducer = React.useReducer
		useEffect = React.useEffect
		useLayoutEffect = React.useLayoutEffect
		useCallback = React.useCallback
		useMemo = React.useMemo
		useRef = React.useRef
		useImperativeHandle = React.useImperativeHandle
		forwardRef = React.forwardRef
		memo = React.memo
		--   useTransition = React.unstable_useTransition
		--   useDeferredValue = React.unstable_useDeferredValue
		Suspense = React.Suspense
		act = ReactNoop.act

		--   textCache = new Map()

		--   readText = text => {
		--     local record = textCache.get(text)
		--     if record ~= undefined)
		--       switch (record.status)
		--         case 'pending':
		--           throw record.promise
		--         case 'rejected':
		--           throw Error('Failed to load: ' .. text)
		--         case 'resolved':
		--           return text
		--       end
		--     } else {
		--       local ping
		--       local promise = new Promise(resolve => (ping = resolve))
		--       local newRecord = {
		--         status: 'pending',
		--         ping: ping,
		--         promise,
		--       end
		--       textCache.set(text, newRecord)
		--       throw promise
		--     end
		--   end

		--   resolveText = text => {
		--     local record = textCache.get(text)
		--     if record ~= undefined)
		--       if record.status == 'pending')
		--         Scheduler.unstable_yieldValue(`Promise resolved [${text}]`)
		--         record.ping()
		--         record.ping = nil
		--         record.status = 'resolved'
		--         clearTimeout(record.promise._timer)
		--         record.promise = nil
		--       end
		--     } else {
		--       local newRecord = {
		--         ping: nil,
		--         status: 'resolved',
		--         promise: nil,
		--       end
		--       textCache.set(text, newRecord)
		--     end
		--   end
	end)

	local function span(prop)
		return { type = "span", hidden = false, children = {}, prop = prop }
	end

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return React.createElement("span", {
			prop = props.text,
		})
	end

	-- function AsyncText(props)
	--   local text = props.text
	--   try {
	--     readText(text)
	--     Scheduler.unstable_yieldValue(text)
	--     return <span prop={text} />
	--   } catch (promise)
	--     if typeof promise.then == 'function')
	--       Scheduler.unstable_yieldValue(`Suspend! [${text}]`)
	--       if typeof props.ms == 'number' and promise._timer == undefined)
	--         promise._timer = setTimeout(function()
	--           resolveText(text)
	--         }, props.ms)
	--       end
	--     } else {
	--       Scheduler.unstable_yieldValue(`Error! [${text}]`)
	--     end
	--     throw promise
	--   end
	-- end

	-- function advanceTimers(ms)
	--   -- Note: This advances Jest's virtual time but not React's. Use
	--   -- ReactNoop.expire for that.
	--   if typeof ms ~= 'number')
	--     throw new Error('Must specify ms')
	--   end
	--   jest.advanceTimersByTime(ms)
	--   -- Wait until the end of the current tick
	--   -- We cannot use a timer since we're faking them
	--   return Promise.resolve().then(function()})
	-- end

	it("resumes after an interruption", function()
		local function Counter(props, ref)
			local count, updateCount = useState(0)
			useImperativeHandle(ref, function()
				return { updateCount = updateCount }
			end)
			return React.createElement(Text, { text = tostring(props.label) .. ": " .. count })
		end
		Counter = forwardRef(Counter)

		-- Initial mount
		local counter = React.createRef(nil)
		ReactNoop.render(React.createElement(Counter, { label = "Count", ref = counter }))
		jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

		-- Schedule some updates
		ReactNoop.batchedUpdates(function()
			counter.current.updateCount(1)
			counter.current.updateCount(function(count: number)
				return count + 10
			end)
		end)

		-- Partially flush without committing
		jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 11" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

		-- Interrupt with a high priority update
		ReactNoop.flushSync(function()
			ReactNoop.render(React.createElement(Counter, { label = "Total" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Total: 0" })

		-- Resume rendering
		jestExpect(Scheduler).toFlushAndYield({ "Total: 11" })
		jestExpect(ReactNoop.getChildren()).toEqual({ span("Total: 11") })
	end)

	it("throws inside class components", function()
		local BadCounter = React.Component:extend("BadCounter")
		function BadCounter:render()
			local count = useState(0)
			return React.createElement(Text, { text = self.props.label + ": " .. count })
		end
		ReactNoop.render(React.createElement(BadCounter))

		jestExpect(Scheduler).toFlushAndThrow(
			"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
				.. " one of the following reasons:\n"
				.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
				.. "2. You might be breaking the Rules of Hooks\n"
				.. "3. You might have more than one copy of React in the same app\n"
				.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
		)

		-- Confirm that a subsequent hook works properly.
		local function GoodCounter(props, ref)
			local count = useState(props.initialCount)
			return React.createElement(Text, { text = count })
		end
		ReactNoop.render(React.createElement(GoodCounter, { initialCount = 10 }))
		jestExpect(Scheduler).toFlushAndYield({ 10 })
	end)

	-- if !require('shared/ReactFeatureFlags').disableModulePatternComponents)
	--   it('throws inside module-style components', function()
	--     function Counter()
	--       return {
	--         render()
	--           local [count] = useState(0)
	--           return <Text text={this.props.label + ': ' .. count} />
	--         },
	--       end
	--     end
	--     ReactNoop.render(<Counter />)
	--     jestExpect(function()
	--       jestExpect(Scheduler).toFlushAndThrow(
	--         'Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen ' ..
	--           'for one of the following reasons:\n' ..
	--           '1. You might have mismatching versions of React and the renderer (such as React DOM)\n' ..
	--           '2. You might be breaking the Rules of Hooks\n' ..
	--           '3. You might have more than one copy of React in the same app\n' ..
	--           'See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.',
	--       ),
	--     ).toErrorDev(
	--       'Warning: The <Counter /> component appears to be a function component that returns a class instance. ' ..
	--         'Change Counter to a class that extends React.Component instead. ' ..
	--         "If you can't use a class try assigning the prototype on the function as a workaround. " ..
	--         '`Counter.prototype = React.Component.prototype`. ' ..
	--         "Don't use an arrow function since it cannot be called with `new` by React.",
	--     )

	--     -- Confirm that a subsequent hook works properly.
	--     function GoodCounter(props)
	--       local [count] = useState(props.initialCount)
	--       return <Text text={count} />
	--     end
	--     ReactNoop.render(<GoodCounter initialCount={10} />)
	--     jestExpect(Scheduler).toFlushAndYield([10])
	--   })
	-- end

	-- ROBLOX note: test aligned to React 18 so we get a hot path optimization in upstream
	it("throws when called outside the render phase", function()
		jestExpect(function()
			jestExpect(function()
				useState(0)
			end).toThrow(
				-- ROBLOX deviation: Lua-specific error on nil deref
				"attempt to index nil with 'useState'"
			)
		end).toErrorDev(
			"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
				.. " one of the following reasons:\n"
				.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
				.. "2. You might be breaking the Rules of Hooks\n"
				.. "3. You might have more than one copy of React in the same app\n"
				.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem.",
				{ withoutStack = true }
		)
	end)

	describe("useState", function()
		it("simple mount and update", function()
			local function Counter(props, ref)
				local count, updateCount = useState(0)
				useImperativeHandle(ref, function()
					return { updateCount = updateCount }
				end)
				return React.createElement(Text, { text = "Count: " .. count })
			end
			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, { ref = counter }))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			act(function()
				return counter.current.updateCount(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })

			act(function()
				return counter.current.updateCount(function(count_)
					return count_ + 10
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 11" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 11") })
		end)

		it("lazy state initializer", function()
			local function Counter(props, ref)
				local count, updateCount = useState(function()
					Scheduler.unstable_yieldValue("getInitialState")
					return props.initialState
				end)
				useImperativeHandle(ref, function()
					return { updateCount = updateCount }
				end)
				return React.createElement(Text, { text = "Count: " .. count })
			end
			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, { initialState = 42, ref = counter }))
			jestExpect(Scheduler).toFlushAndYield({ "getInitialState", "Count: 42" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 42") })

			act(function()
				return counter.current.updateCount(7)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 7" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 7") })
		end)

		it("multiple states", function()
			local function Counter(props, ref)
				local count, updateCount = useState(0)
				local label, updateLabel = useState("Count")
				useImperativeHandle(ref, function()
					return {
						updateCount = updateCount,
						updateLabel = updateLabel,
					}
				end)
				return React.createElement(Text, { text = label .. ": " .. count })
			end
			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, { ref = counter }))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			act(function()
				return counter.current.updateCount(7)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 7" })

			act(function()
				return counter.current.updateLabel("Total")
			end)
			jestExpect(Scheduler).toHaveYielded({ "Total: 7" })
		end)

		it("returns the same updater function every time", function()
			local updater = nil
			local function Counter()
				local count, updateCount = useState(0)
				updater = updateCount
				return React.createElement(Text, { text = "Count: " .. count })
			end
			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			local firstUpdater = updater

			act(function()
				return firstUpdater(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })

			local secondUpdater = updater

			act(function()
				return firstUpdater(function(count)
					return count + 10
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 11" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 11") })

			jestExpect(firstUpdater).toEqual(secondUpdater)
		end)

		it("does not warn on set after unmount", function()
			local updateCount
			local function Counter(props, ref)
				_, updateCount = useState(0)
				return nil
			end

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushWithoutYielding()
			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushWithoutYielding()
			act(function()
				updateCount(1)
			end)
		end)

		it("works with memo", function()
			local count, updateCount
			local function Counter()
				count, updateCount = useState(0)
				return React.createElement(Text, { text = "Count: " .. count })
			end
			Counter = memo(Counter)

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({})
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			act(function()
				return updateCount(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
		end)
	end)

	describe("updates during the render phase", function()
		it("restarts the render function and applies the new updates on top", function()
			local function ScrollView(props)
				local newRow = props.row
				local isScrollingDown, setIsScrollingDown = useState(false)
				local row, setRow = useState(nil)

				if row ~= newRow then
					-- Row changed since last render. Update isScrollingDown.
					setIsScrollingDown(row ~= nil and newRow > row)
					setRow(newRow)
				end

				return React.createElement(Text, { text = ("Scrolling down: %s"):format(tostring(isScrollingDown)) })
			end

			ReactNoop.render(React.createElement(ScrollView, { row = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: false" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: false") })

			ReactNoop.render(React.createElement(ScrollView, { row = 5 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: true" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: true") })

			ReactNoop.render(React.createElement(ScrollView, { row = 5 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: true" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: true") })

			ReactNoop.render(React.createElement(ScrollView, { row = 10 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: true" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: true") })

			ReactNoop.render(React.createElement(ScrollView, { row = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: false" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: false") })

			ReactNoop.render(React.createElement(ScrollView, { row = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "Scrolling down: false" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Scrolling down: false") })
		end)

		-- ROBLOX TODO: this test uses await, need to figure that out
		--   it('warns about render phase update on a different component', async function()
		--     local setStep
		--     function Foo()
		--       local [step, _setStep] = useState(0)
		--       setStep = _setStep
		--       return <Text text={`Foo [${step}]`} />
		--     end

		--     function Bar({triggerUpdate})
		--       if triggerUpdate)
		--         setStep(x => x + 1)
		--       end
		--       return <Text text="Bar" />
		--     end

		--     local root = ReactNoop.createRoot()

		--     await ReactNoop.act(async function()
		--       root.render(
		--         <>
		--           <Foo />
		--           <Bar />
		--         </>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded(['Foo [0]', 'Bar'])

		--     -- Bar will update Foo during its render phase. React should warn.
		--     await ReactNoop.act(async function()
		--       root.render(
		--         <>
		--           <Foo />
		--           <Bar triggerUpdate={true} />
		--         </>,
		--       )
		--       jestExpect(function()
		--         jestExpect(Scheduler).toFlushAndYield(
		--           __DEV__
		--             ? ['Foo [0]', 'Bar', 'Foo [2]']
		--             : ['Foo [0]', 'Bar', 'Foo [1]'],
		--         ),
		--       ).toErrorDev([
		--         'Cannot update a component (`Foo`) while rendering a ' ..
		--           'different component (`Bar`). To locate the bad setState() call inside `Bar`',
		--       ])
		--     })

		--     -- It should not warn again (deduplication).
		--     await ReactNoop.act(async function()
		--       root.render(
		--         <>
		--           <Foo />
		--           <Bar triggerUpdate={true} />
		--         </>,
		--       )
		--       jestExpect(Scheduler).toFlushAndYield(
		--         __DEV__
		--           ? ['Foo [2]', 'Bar', 'Foo [4]']
		--           : ['Foo [1]', 'Bar', 'Foo [2]'],
		--       )
		--     })
		--   })

		it("keeps restarting until there are no more new updates", function()
			local function Counter()
				local count, setCount = useState(0)
				if count < 3 then
					setCount(count + 1)
				end
				Scheduler.unstable_yieldValue("Render: " .. count)
				return React.createElement(Text, { text = count })
			end

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({
				"Render: 0",
				"Render: 1",
				"Render: 2",
				"Render: 3",
				3,
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(3) })
		end)

		it("updates multiple times within same render function", function()
			local function Counter()
				local count, setCount = useState(0)
				if count < 12 then
					setCount(function(c)
						return c + 1
					end)
					setCount(function(c)
						return c + 1
					end)
					setCount(function(c)
						return c + 1
					end)
				end
				Scheduler.unstable_yieldValue("Render: " .. count)
				return React.createElement(Text, { text = count })
			end

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({
				-- Should increase by three each time
				"Render: 0",
				"Render: 3",
				"Render: 6",
				"Render: 9",
				"Render: 12",
				12,
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(12) })
		end)

		it("throws after too many iterations", function()
			local function Counter()
				local count, setCount = useState(0)
				setCount(count + 1)
				Scheduler.unstable_yieldValue("Render: " .. count)
				return React.createElement(Text, { text = count })
			end
			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndThrow(
				"Too many re-renders. React limits the number of renders to prevent " .. "an infinite loop."
			)
		end)

		it("works with useReducer", function()
			local function reducer(state, action)
				local returnVal = state
				if action == "increment" then
					returnVal = state + 1
				end
				return returnVal
			end
			local function Counter(props)
				local count, dispatch = useReducer(reducer, 0)
				if count < 3 then
					dispatch("increment")
				end
				Scheduler.unstable_yieldValue("Render: " .. count)
				return React.createElement(Text, { text = count })
			end

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({
				"Render: 0",
				"Render: 1",
				"Render: 2",
				"Render: 3",
				3,
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(3) })
		end)

		it("uses reducer passed at time of render, not time of dispatch", function()
			-- This test is a bit contrived but it demonstrates a subtle edge case.

			-- Reducer A increments by 1. Reducer B increments by 10.
			local function reducerA(state, action)
				if action == "increment" then
					return state + 1
				elseif action == "reset" then
					return 0
				else
					return
				end
			end

			local function reducerB(state, action)
				if action == "increment" then
					return state + 10
				elseif action == "reset" then
					return 0
				else
					return
				end
			end

			local function Counter(props, ref)
				local reducer_, setReducer = useState(function()
					return reducerA
				end)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					return { dispatch = dispatch }
				end)
				if count < 20 then
					dispatch("increment")
					-- Swap reducers each time we increment
					if reducer_ == reducerA then
						setReducer(function()
							return reducerB
						end)
					else
						setReducer(function()
							return reducerA
						end)
					end
				end
				Scheduler.unstable_yieldValue("Render: " .. count)
				return React.createElement(Text, { text = count })
			end

			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, { ref = counter }))
			jestExpect(Scheduler).toFlushAndYield({
				-- The count should increase by alternating amounts of 10 and 1
				-- until we reach 21.
				"Render: 0",
				"Render: 10",
				"Render: 11",
				"Render: 21",
				21,
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(21) })

			-- Test that it works on update, too. This time the log is a bit different
			-- because we started with reducerB instead of reducerA.
			ReactNoop.act(function()
				counter.current.dispatch("reset")
			end)
			ReactNoop.render(React.createElement(Counter, { ref = counter }))
			jestExpect(Scheduler).toHaveYielded({
				"Render: 0",
				"Render: 1",
				"Render: 11",
				"Render: 12",
				"Render: 22",
				22,
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(22) })
		end)
		it('discards render phase updates if something suspends', function()
		    local thenable = {andThen = function() end}
			local Bar

		    local function Foo(props)
				local signal = props.signal
		    	return React.createElement(Suspense, {fallback="Loading..."}, React.createElement(Bar, {signal=signal}))
		    end

		    function Bar(props)
			  local newSignal = props.signal
		      local counter, setCounter = useState(0)
		      local signal, setSignal = useState(true)

		      -- Increment a counter every time the signal changes
		      if signal ~= newSignal then
		        setCounter(function(c)
					return c + 1
				end)
		        setSignal(newSignal)
		        if counter == 0 then
		          -- We're suspending during a render that includes render phase
		          -- updates. Those updates should not persist to the next render.
		          Scheduler.unstable_yieldValue('Suspend!')
		          error(thenable)
		        end
		      end

		      return React.createElement(Text, {text=counter})
		    end

		    local root = ReactNoop.createRoot()
		    root.render(React.createElement(Foo, {signal=true}))

		    jestExpect(Scheduler).toFlushAndYield({0})
		    jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop=0}))


		    root.render(React.createElement(Foo, {signal=false}))
		    jestExpect(Scheduler).toFlushAndYield({'Suspend!'})
		    jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop=0}))

		    -- Rendering again should suspend again.
		    root.render(React.createElement(Foo, {signal=false}))
		    jestExpect(Scheduler).toFlushAndYield({'Suspend!'})
		end)
		it('discards render phase updates if something suspends, but not other updates in the same component', function()
		    local thenable = {andThen = function() end}
			local Bar

		    local function Foo(props)
				local signal = props.signal
		    	return React.createElement(Suspense, {fallback="Loading..."}, React.createElement(Bar, {signal=signal}))
		    end

		    local setLabel

			function Bar(props)
			  local newSignal = props.signal
		      local counter, setCounter = useState(0)

		      if counter == 1 then
		        -- We're suspending during a render that includes render phase
		        -- updates. Those updates should not persist to the next render.
		        Scheduler.unstable_yieldValue('Suspend!')
		        error(thenable)
		      end

		      local signal, setSignal = useState(true)

		      -- Increment a counter every time the signal changes
		      if signal ~= newSignal then
		        setCounter(function(c)
					return c + 1
				end)
		        setSignal(newSignal)
		      end

		      local label, _setLabel = useState('A')
		      setLabel = _setLabel

		      return React.createElement(Text,
			    {text = label .. ":" .. tostring(counter) }
			  )
		    end

		    local root = ReactNoop.createRoot()
		    root.render(React.createElement(Foo, {signal=true}))

		    jestExpect(Scheduler).toFlushAndYield({'A:0'})
		    jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop="A:0"}))

		    ReactNoop.act(function()
		      root.render(React.createElement(Foo, {signal=false}))
		      setLabel('B')

		      jestExpect(Scheduler).toFlushAndYield({'Suspend!'})
		      jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop="A:0"}))

		      -- Rendering again should suspend again.
		      root.render(React.createElement(Foo, {signal=false}))
		      jestExpect(Scheduler).toFlushAndYield({'Suspend!'})

		      -- Flip the signal back to "cancel" the update. However, the update to
		      -- label should still proceed. It shouldn't have been dropped.
		      root.render(React.createElement(Foo, {signal=true}))
		      jestExpect(Scheduler).toFlushAndYield({'B:0'})
		      jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop="B:0"}))
			  return Promise.resolve()
			end)
		end)

		it("regression: render phase updates cause lower pri work to be dropped", function()
		  local setRow
		  local function ScrollView()
		    local row, _setRow = useState(10)
		    setRow = _setRow

		    local scrollDirection, setScrollDirection = useState("Up")
		    local prevRow, setPrevRow = useState(nil)

		    if prevRow ~= row then
				local direction = "Up"
				if prevRow ~= nil and row > prevRow then
					direction = "Down"
				end
				setScrollDirection(direction)
				setPrevRow(row)
		    end

			return React.createElement(Text, {text = scrollDirection})
		  end

		  local root = ReactNoop.createRoot()

		  act(function()
		    	root.render(React.createElement(ScrollView, {row = 10}))
			end)
		  jestExpect(Scheduler).toHaveYielded({"Up"})
		  jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop="Up"}))

		  act(function()
				ReactNoop.discreteUpdates(function()
					setRow(5)
				end)
				setRow(20)
			end)
		  jestExpect(Scheduler).toHaveYielded({"Up", "Down"})
		  jestExpect(root).toMatchRenderedOutput(React.createElement("span", {prop="Down"}))
		end)

		--   -- TODO: This should probably warn
		--   -- @gate experimental
		--   it('calling startTransition inside render phase', async function()
		--     local startTransition
		--     function App()
		--       local [counter, setCounter] = useState(0)
		--       local [_startTransition] = useTransition()
		--       startTransition = _startTransition

		--       if counter == 0)
		--         startTransition(function()
		--           setCounter(c => c + 1)
		--         })
		--       end

		--       return <Text text={counter} />
		--     end

		--     local root = ReactNoop.createRoot()
		--     root.render(<App />)
		--     jestExpect(Scheduler).toFlushAndYield([1])
		--     jestExpect(root).toMatchRenderedOutput(<span prop={1} />)
		--   })
	end)

	describe("useReducer", function()
		it("simple mount and update", function()
			local INCREMENT = "INCREMENT"
			local DECREMENT = "DECREMENT"

			local function reducer_(state, action)
				if action == "INCREMENT" then
					return state + 1
				elseif action == "DECREMENT" then
					return state - 1
				else
					return state
				end
			end

			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					return { dispatch = dispatch }
				end)
				return React.createElement(Text, {
					text = "Count: " .. count,
				})
			end
			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, {
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			act(function()
				return counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			act(function()
				counter.current.dispatch(DECREMENT)
				counter.current.dispatch(DECREMENT)
				counter.current.dispatch(DECREMENT)
			end)

			jestExpect(Scheduler).toHaveYielded({ "Count: -2" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: -2") })
		end)

		it("lazy init", function()
			local INCREMENT = "INCREMENT"
			local DECREMENT = "DECREMENT"

			local function reducer_(state, action)
				if action == "INCREMENT" then
					return state + 1
				elseif action == "DECREMENT" then
					return state - 1
				else
					return state
				end
			end

			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, props, function(p)
					Scheduler.unstable_yieldValue("Init")
					return p.initialCount
				end)
				useImperativeHandle(ref, function()
					return { dispatch = dispatch }
				end)
				return React.createElement(Text, {
					text = "Count: " .. count,
				})
			end
			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, {
				initialCount = 10,
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Init", "Count: 10" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 10") })

			act(function()
				return counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 11" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 11") })

			act(function()
				counter.current.dispatch(DECREMENT)
				counter.current.dispatch(DECREMENT)
				counter.current.dispatch(DECREMENT)
			end)

			jestExpect(Scheduler).toHaveYielded({ "Count: 8" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 8") })
		end)

		-- Regression test for https://github.com/facebook/react/issues/14360
		it("handles dispatches with mixed priorities", function()
			local INCREMENT = "INCREMENT"

			local function reducer_(state, action)
				if action == INCREMENT then
					return state + 1
				else
					return state
				end
			end
			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					return { dispatch = dispatch }
				end)

				return React.createElement(Text, {
					text = "Count: " .. count,
				})
			end

			Counter = forwardRef(Counter)

			local counter = React.createRef(nil)

			ReactNoop.render(React.createElement(Counter, { ref = counter }))
			jestExpect(Scheduler).toFlushAndYield({
				"Count: 0",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 0"),
			})
			ReactNoop.batchedUpdates(function()
				counter.current.dispatch(INCREMENT)
				counter.current.dispatch(INCREMENT)
				counter.current.dispatch(INCREMENT)
			end)
			ReactNoop.flushSync(function()
				counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Count: 1",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 1"),
			})
			jestExpect(Scheduler).toFlushAndYield({
				"Count: 4",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 4"),
			})
		end)
	end)

	describe("useEffect", function()
		it("simple mount and update", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Passive effect [%d]"):format(props.count))
				end)
				return React.createElement(Text, {
					text = "Count: " .. props.count,
				})
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, {
					count = 0,
				}), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
				-- Effects are deferred until after the commit
				jestExpect(Scheduler).toFlushAndYield({ "Passive effect [0]" })
			end)

			act(function()
				ReactNoop.render(React.createElement(Counter, {
					count = 1,
				}), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
				-- Effects are deferred until after the commit
				jestExpect(Scheduler).toFlushAndYield({ "Passive effect [1]" })
			end)
		end)

		it("flushes passive effects even with sibling deletions", function()
			local function LayoutEffect(props)
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Layout effect")
				end)
				return React.createElement(Text, { text = "Layout" })
			end
			local function PassiveEffect(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Passive effect")
				end, {})
				return React.createElement(Text, { text = "Passive" })
			end
			local passive = React.createElement(PassiveEffect, { key = "p" })
			act(function()
				ReactNoop.render({ React.createElement(LayoutEffect, { key = "l" }), passive })
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Layout",
					"Passive",
					"Layout effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Layout"),
					span("Passive"),
				})
				-- Destroying the first child shouldn't prevent the passive effect from
				-- being executed
				ReactNoop.render({ passive })
				jestExpect(Scheduler).toFlushAndYield({ "Passive effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Passive") })
			end)
			-- exiting act calls flushPassiveEffects(), but there are none left to flush.
			jestExpect(Scheduler).toHaveYielded({})
		end)

		it("flushes passive effects even if siblings schedule an update", function()
			local function PassiveEffect(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Passive effect")
				end)
				return React.createElement(Text, { text = "Passive" })
			end
			local function LayoutEffect(props)
				local count, setCount = useState(0)
				useLayoutEffect(function()
					-- Scheduling work shouldn't interfere with the queued passive effect
					if count == 0 then
						setCount(1)
					end
					Scheduler.unstable_yieldValue("Layout effect " .. count)
				end)
				return React.createElement(Text, { text = "Layout" })
			end

			ReactNoop.render({
				React.createElement(PassiveEffect, { key = "p" }),
				React.createElement(LayoutEffect, { key = "l" }),
			})

			act(function()
				jestExpect(Scheduler).toFlushAndYield({
					"Passive",
					"Layout",
					"Layout effect 0",
					"Passive effect",
					"Layout",
					"Layout effect 1",
				})
			end)

			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Passive"),
				span("Layout"),
			})
		end)

		it("flushes passive effects even if siblings schedule a new root", function()
			local function PassiveEffect(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Passive effect")
				end, {})
				return React.createElement(Text, { text = "Passive" })
			end
			local function LayoutEffect(props)
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Layout effect")
					-- Scheduling work shouldn't interfere with the queued passive effect
					ReactNoop.renderToRootWithID(React.createElement(Text, { text = "New Root" }), "root2")
				end)
				return React.createElement(Text, { text = "Layout" })
			end
			act(function()
				ReactNoop.render({
					React.createElement(PassiveEffect, { key = "p" }),
					React.createElement(LayoutEffect, { key = "l" }),
				})
				jestExpect(Scheduler).toFlushAndYield({
					"Passive",
					"Layout",
					"Layout effect",
					"Passive effect",
					"New Root",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Passive"),
					span("Layout"),
				})
			end)
		end)

		it(
			"flushes effects serially by flushing old effects before flushing "
				.. "new ones, if they haven't already fired",
			function()
				local function getCommittedText()
					local children = ReactNoop.getChildren()
					if children == nil then
						return nil
					end
					return children[1].prop
				end

				local function Counter(props)
					useEffect(function()
						Scheduler.unstable_yieldValue(
							"Committed state when effect was fired: " .. tostring(getCommittedText())
						)
					end)
					return React.createElement(Text, { text = props.count })
				end
				act(function()
					ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
						Scheduler.unstable_yieldValue("Sync effect")
					end)
					jestExpect(Scheduler).toFlushAndYieldThrough({ 0, "Sync effect" })
					jestExpect(ReactNoop.getChildren()).toEqual({ span(0) })
					-- Before the effects have a chance to flush, schedule another update
					ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
						Scheduler.unstable_yieldValue("Sync effect")
					end)
					jestExpect(Scheduler).toFlushAndYieldThrough({
						-- The previous effect flushes before the reconciliation
						"Committed state when effect was fired: 0",
						1,
						"Sync effect",
					})
					jestExpect(ReactNoop.getChildren()).toEqual({ span(1) })
				end)

				jestExpect(Scheduler).toHaveYielded({
					"Committed state when effect was fired: 1",
				})
			end
		)

		it("defers passive effect destroy functions during unmount", function()
			local function Child(props)
				local bar = props.bar
				local foo = props.foo
				React.useEffect(function()
					Scheduler.unstable_yieldValue("passive bar create")
					return function()
						Scheduler.unstable_yieldValue("passive bar destroy")
					end
				end, {
					bar,
				})
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("layout bar create")
					return function()
						Scheduler.unstable_yieldValue("layout bar destroy")
					end
				end, {
					bar,
				})
				React.useEffect(function()
					Scheduler.unstable_yieldValue("passive foo create")
					return function()
						Scheduler.unstable_yieldValue("passive foo destroy")
					end
				end, {
					foo,
				})
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("layout foo create")
					return function()
						Scheduler.unstable_yieldValue("layout foo destroy")
					end
				end, {
					foo,
				})
				Scheduler.unstable_yieldValue("render")
				return nil
			end

			act(function()
				ReactNoop.render(React.createElement(Child, { bar = 1, foo = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"render",
					"layout bar create",
					"layout foo create",
					"Sync effect",
				})
				-- Effects are deferred until after the commit
				jestExpect(Scheduler).toFlushAndYield({
					"passive bar create",
					"passive foo create",
				})
			end)

			-- This update is exists to test an internal implementation detail:
			-- Effects without updating dependencies lose their layout/passive tag during an update.
			act(function()
				ReactNoop.render(React.createElement(Child, { bar = 1, foo = 2 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"render",
					"layout foo destroy",
					"layout foo create",
					"Sync effect",
				})
				-- Effects are deferred until after the commit
				jestExpect(Scheduler).toFlushAndYield({
					"passive foo destroy",
					"passive foo create",
				})
			end)

			-- Unmount the component and verify that passive destroy functions are deferred until post-commit.
			act(function()
				ReactNoop.render(nil, function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"layout bar destroy",
					"layout foo destroy",
					"Sync effect",
				})
				-- Effects are deferred until after the commit
				jestExpect(Scheduler).toFlushAndYield({
					"passive bar destroy",
					"passive foo destroy",
				})
			end)
		end)

		it("does not warn about state updates for unmounted components with pending passive unmounts", function()
			local completePendingRequest = nil
			local function Component()
				Scheduler.unstable_yieldValue("Component")
				local didLoad, setDidLoad = React.useState(false)
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("layout create")
					return function()
						Scheduler.unstable_yieldValue("layout destroy")
					end
				end, {})
				React.useEffect(function()
					Scheduler.unstable_yieldValue("passive create")
					-- Mimic an XHR request with a complete handler that updates state.
					completePendingRequest = function()
						setDidLoad(true)
					end
					return function()
						Scheduler.unstable_yieldValue("passive destroy")
					end
				end, {})
				return didLoad
			end

			act(function()
				ReactNoop.renderToRootWithID(React.createElement(Component), "root", function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Component",
					"layout create",
					"Sync effect",
				})
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({ "passive create" })

				-- Unmount but don't process pending passive destroy function
				ReactNoop.unmountRootWithID("root")
				jestExpect(Scheduler).toFlushAndYieldThrough({ "layout destroy" })

				-- Simulate an XHR completing, which will cause a state update-
				-- but should not log a warning.
				completePendingRequest()

				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({ "passive destroy" })
			end)
		end)

		it(
			"does not warn about state updates for unmounted components with pending passive unmounts for alternates",
			function()
				local setParentState = nil
				local setChildStates = {}

				-- deviation: reordered so Parent function could reference Child
				local function Child(props)
					-- deviation: list deconstruction doesn't work in Lua
					local label = props.label
					local state, setState = useState(0)
					useLayoutEffect(function()
						Scheduler.unstable_yieldValue("Child " .. label .. " commit")
					end)
					useEffect(function()
						table.insert(setChildStates, setState)
						Scheduler.unstable_yieldValue("Child " .. label .. " passive create")
						return function()
							Scheduler.unstable_yieldValue("Child " .. label .. " passive destroy")
						end
					end, {})
					Scheduler.unstable_yieldValue("Child " .. label .. " render")
					return state
				end

				local function Parent()
					local state, setState = useState(true)
					setParentState = setState
					Scheduler.unstable_yieldValue("Parent " .. tostring(state) .. " render")
					useLayoutEffect(function()
						Scheduler.unstable_yieldValue("Parent " .. tostring(state) .. " commit")
					end)
					if state then
						return React.createElement(
							React.Fragment,
							nil,
							React.createElement(Child, { label = "one" }),
							React.createElement(Child, { label = "two" })
						)
					else
						return nil
					end
				end

				-- Schedule debounced state update for child (prob a no-op for this test)
				-- later tick: schedule unmount for parent
				-- start process unmount (but don't flush passive effectS)
				-- State update on child
				act(function()
					ReactNoop.render(React.createElement(Parent))
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Parent true render",
						"Child one render",
						"Child two render",
						"Child one commit",
						"Child two commit",
						"Parent true commit",
						"Child one passive create",
						"Child two passive create",
					})

					-- Update children.
					-- deviation: forEach() translated using Array.map
					Array.map(setChildStates, function(setChildState)
						return setChildState(1)
					end)

					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Child one render",
						"Child two render",
						"Child one commit",
						"Child two commit",
					})

					-- Schedule another update for children, and partially process it.
					-- deviation: forEach() translated using Array.map

					Array.map(setChildStates, function(setChildState)
						return setChildState(2)
					end)

					jestExpect(Scheduler).toFlushAndYieldThrough({ "Child one render" })

					-- Schedule unmount for the parent that unmounts children with pending update.
					Scheduler.unstable_runWithPriority(Scheduler.unstable_UserBlockingPriority, function()
						return setParentState(false)
					end)
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Parent false render",
						"Parent false commit",
					})

					-- Schedule updates for children too (which should be ignored)
					-- deviation: forEach() translated using Array.map
					Array.map(setChildStates, function(setChildState)
						return setChildState(2)
					end)

					jestExpect(Scheduler).toFlushAndYield({
						"Child one passive destroy",
						"Child two passive destroy",
					})
				end)
			end
		)

		it("does not warn about state updates for unmounted components with no pending passive unmounts", function()
			local completePendingRequest = nil
			local function Component()
				Scheduler.unstable_yieldValue("Component")
				local didLoad, setDidLoad = React.useState(false)
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("layout create")
					-- Mimic an XHR request with a complete handler that updates state.
					completePendingRequest = function()
						setDidLoad(true)
					end
					return function()
						Scheduler.unstable_yieldValue("layout destroy")
					end
				end, {})
				return didLoad
			end

			act(function()
				ReactNoop.renderToRootWithID(React.createElement(Component), "root", function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Component",
					"layout create",
					"Sync effect",
				})

				-- Unmount but don't process pending passive destroy function
				ReactNoop.unmountRootWithID("root")
				jestExpect(Scheduler).toFlushAndYieldThrough({ "layout destroy" })

				-- Simulate an XHR completing.
				completePendingRequest()
			end)
		end)

		it("does not warn if there are pending passive unmount effects but not for the current fiber", function()
			local completePendingRequest = nil
			local function ComponentWithXHR()
				Scheduler.unstable_yieldValue("Component")
				local didLoad, setDidLoad = React.useState(false)
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("a:layout create")
					return function()
						Scheduler.unstable_yieldValue("a:layout destroy")
					end
				end, {})
				React.useEffect(function()
					Scheduler.unstable_yieldValue("a:passive create")
					-- Mimic an XHR request with a complete handler that updates state.
					completePendingRequest = function()
						setDidLoad(true)
					end
				end, {})
				return didLoad
			end

			local function ComponentWithPendingPassiveUnmount()
				React.useEffect(function()
					Scheduler.unstable_yieldValue("b:passive create")
					return function()
						Scheduler.unstable_yieldValue("b:passive destroy")
					end
				end, {})
				return nil
			end

			act(function()
				ReactNoop.renderToRootWithID(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(ComponentWithXHR),
						React.createElement(ComponentWithPendingPassiveUnmount)
					),
					"root",
					function()
						return Scheduler.unstable_yieldValue("Sync effect")
					end
				)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Component",
					"a:layout create",
					"Sync effect",
				})
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({
					"a:passive create",
					"b:passive create",
				})

				-- Unmount but don't process pending passive destroy function
				ReactNoop.unmountRootWithID("root")
				jestExpect(Scheduler).toFlushAndYieldThrough({ "a:layout destroy" })

				-- Simulate an XHR completing in the component without a pending passive effect..
				completePendingRequest()
			end)
		end)

		it("does not warn if there are updates after pending passive unmount effects have been flushed", function()
			local updaterFunction

			local function Component()
				Scheduler.unstable_yieldValue("Component")
				local state, setState = React.useState(false)
				updaterFunction = setState
				React.useEffect(function()
					Scheduler.unstable_yieldValue("passive create")
					return function()
						Scheduler.unstable_yieldValue("passive destroy")
					end
				end, {})
				return state
			end

			act(function()
				ReactNoop.renderToRootWithID(React.createElement(Component), "root", function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Component",
				"Sync effect",
				"passive create",
			})

			ReactNoop.unmountRootWithID("root")
			jestExpect(Scheduler).toFlushAndYield({ "passive destroy" })

			act(function()
				updaterFunction(true)
			end)
		end)

		it(
			"does not show a warning when a component updates its own state from within passive unmount function",
			function()
				local function Component()
					Scheduler.unstable_yieldValue("Component")
					local didLoad, setDidLoad = React.useState(false)
					React.useEffect(function()
						Scheduler.unstable_yieldValue("passive create")
						return function()
							setDidLoad(true)
							Scheduler.unstable_yieldValue("passive destroy")
						end
					end, {})
					return didLoad
				end

				act(function()
					ReactNoop.renderToRootWithID(React.createElement(Component), "root", function()
						Scheduler.unstable_yieldValue("Sync effect")
					end)
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Component",
						"Sync effect",
						"passive create",
					})

					-- Unmount but don't process pending passive destroy function
					ReactNoop.unmountRootWithID("root")
					jestExpect(Scheduler).toFlushAndYield({ "passive destroy" })
				end)
			end
		)

		it(
			"does not show a warning when a component updates a childs state from within passive unmount function",
			function()
				local Child
				local function Parent()
					Scheduler.unstable_yieldValue("Parent")
					local updaterRef = React.useRef(nil)
					React.useEffect(function()
						Scheduler.unstable_yieldValue("Parent passive create")
						return function()
							updaterRef.current(true)
							Scheduler.unstable_yieldValue("Parent passive destroy")
						end
					end, {})
					return React.createElement(Child, { updaterRef = updaterRef })
				end

				function Child(props)
					local updaterRef = props.updaterRef
					Scheduler.unstable_yieldValue("Child")
					local state, setState = React.useState(false)
					React.useEffect(function()
						Scheduler.unstable_yieldValue("Child passive create")
						-- ROBLOX FIXME: Assigning to ref.current like this is
						-- not allowed in legacy Roact, and it appears that it
						-- was previously disallowed in React as well. There was
						-- quite a bit of discussion about it here:
						-- https://github.com/DefinitelyTyped/DefinitelyTyped/issues/31065

						-- For now, we've relaxed this restriction to maximize
						-- compatibility. We should consider using a binding
						-- here, which would be the idiomatic approach in legacy
						-- Roact, and re-introducing the restriction.
						updaterRef.current = setState
					end, {})
					return state
				end

				act(function()
					ReactNoop.renderToRootWithID(React.createElement(Parent), "root")
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Parent",
						"Child",
						"Child passive create",
						"Parent passive create",
					})

					-- Unmount but don't process pending passive destroy function
					ReactNoop.unmountRootWithID("root")
					jestExpect(Scheduler).toFlushAndYield({ "Parent passive destroy" })
				end)
			end
		)

		it(
			"does not show a warning when a component updates a parents state from within passive unmount function",
			function()
				local Child
				local function Parent()
					local state, setState = React.useState(false)
					Scheduler.unstable_yieldValue("Parent")
					return React.createElement(Child, { setState = setState, state = state })
				end

				function Child(props)
					local state = props.state
					local setState = props.setState
					Scheduler.unstable_yieldValue("Child")
					React.useEffect(function()
						Scheduler.unstable_yieldValue("Child passive create")
						return function()
							Scheduler.unstable_yieldValue("Child passive destroy")
							setState(true)
						end
					end, {})
					return state
				end

				act(function()
					ReactNoop.renderToRootWithID(React.createElement(Parent), "root")
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Parent",
						"Child",
						"Child passive create",
					})

					-- Unmount but don't process pending passive destroy function
					ReactNoop.unmountRootWithID("root")
					jestExpect(Scheduler).toFlushAndYield({ "Child passive destroy" })
				end)
			end
		)

		it("updates have async priority", function()
			local function Counter(props)
				local count, updateCount = useState("(empty)")
				useEffect(function()
					Scheduler.unstable_yieldValue(("Schedule update {%s}"):format(props.count))
					updateCount(props.count)
				end, {
					props.count,
				})
				return React.createElement(Text, { text = "Count: " .. count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: (empty)",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: (empty)") })
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({ "Schedule update {0}" })
				jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			end)

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({ "Schedule update {1}" })
				jestExpect(Scheduler).toFlushAndYield({ "Count: 1" })
			end)
		end)

		it("updates have async priority even if effects are flushed early", function()
			local function Counter(props)
				local count, updateCount = useState("(empty)")
				useEffect(function()
					Scheduler.unstable_yieldValue(("Schedule update {%s}"):format(props.count))
					updateCount(props.count)
				end, {
					props.count,
				})
				return React.createElement(Text, { text = "Count: " .. count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: (empty)",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: (empty)") })

				-- Rendering again should flush the previous commit's effects
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Schedule update {0}",
					"Count: 0",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: (empty)") })

				jestExpect(Scheduler).toFlushAndYieldThrough({ "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({ "Schedule update {1}" })
				jestExpect(Scheduler).toFlushAndYield({ "Count: 1" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)
		end)

		it("does not flush non-discrete passive effects when flushing sync", function()
			local _updateCount
			local function Counter(props)
				local count, updateCount = useState(0)
				_updateCount = updateCount
				useEffect(function()
					Scheduler.unstable_yieldValue("Will set count to 1")
					updateCount(1)
				end, {})
				return React.createElement(Text, { text = "Count: " .. tostring(count) })
			end

			-- we explicitly wait for missing act() warnings here since
			-- it's a lot harder to simulate this condition inside an act scope
			-- jestExpect(function()
			ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
				Scheduler.unstable_yieldValue("Sync effect")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			-- end).toErrorDev({'An update to Counter ran an effect'})

			-- A flush sync doesn't cause the passive effects to fire.
			-- So we haven't added the other update yet.
			act(function()
				ReactNoop.flushSync(function()
					_updateCount(2)
				end)
			end)

			-- As a result we, somewhat surprisingly, commit them in the opposite order.
			-- This should be fine because any non-discrete set of work doesn't guarantee order
			-- and easily could've happened slightly later too.
			jestExpect(Scheduler).toHaveYielded({
				"Will set count to 1",
				"Count: 2",
				"Count: 1",
			})

			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
		end)

		-- ROBLOX TODO: schedulerTracing
		-- @gate enableSchedulerTracing
		--   it('does not flush non-discrete passive effects when flushing sync (with tracing)', function()
		--     local onInteractionScheduledWorkCompleted = jest.fn()
		--     local onWorkCanceled = jest.fn()

		--     SchedulerTracing.unstable_subscribe({
		--         onInteractionScheduledWorkCompleted = onInteractionScheduledWorkCompleted,
		--         onInteractionTraced = jest.fn(),
		--         onWorkCanceled = onWorkCanceled,
		--         onWorkScheduled = jest.fn(),
		--         onWorkStarted = jest.fn(),
		--         onWorkStopped = jest.fn(),
		--     })

		--     local _updateCount

		--     local function Counter(props)
		--         local _useState, _useState2, count, updateCount = useState(0), _slicedToArray(_useState, 2), _useState2[0], _useState2[1]

		--         _updateCount = updateCount

		--         useEffect(function()
		--             jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({tracingEvent})
		--             Scheduler.unstable_yieldValue('Will set count to 1')
		--             updateCount(1)
		--         end, {})

		--         return React.createElement(Text, {
		--             text = 'Count: ' + count,
		--         })
		--     end

		--     local tracingEvent = {
		--         id = 0,
		--         name = 'hello',
		--         timestamp = 0,
		--     }

		--     jestExpect(function()
		--         SchedulerTracing.unstable_trace(tracingEvent.name, tracingEvent.timestamp, function()
		--             ReactNoop.render(React.createElement(Counter, {count = 0}), function()
		--                 return Scheduler.unstable_yieldValue('Sync effect')
		--             end)
		--         end)
		--         jestExpect(Scheduler).toFlushAndYieldThrough({
		--             'Count: 0',
		--             'Sync effect',
		--         })
		--         jestExpect(ReactNoop.getChildren()).toEqual({
		--             span('Count: 0'),
		--         })
		--     end).toErrorDev({
		--         'An update to Counter ran an effect',
		--     })
		--     jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(0)
		--     act(function()
		--         ReactNoop.flushSync(function()
		--             _updateCount(2)
		--         end)
		--     end)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Will set count to 1',
		--         'Count: 2',
		--         'Count: 1',
		--     })
		--     jestExpect(ReactNoop.getChildren()).toEqual({
		--         span('Count: 1'),
		--     })
		--     jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
		--     jestExpect(onWorkCanceled).toHaveBeenCalledTimes(0)
		-- end)

		it(
			"in legacy mode, useEffect is deferred and updates finish synchronously (in a single batch)",
			function()
				local function Counter(props)
					local count, updateCount = useState("(empty)")

					useEffect(function()
						-- Update multiple times. These should all be batched together in
						-- a single render.
						updateCount(props.count)
						updateCount(props.count)
						updateCount(props.count)
						updateCount(props.count)
						updateCount(props.count)
						updateCount(props.count)
					end, {
						props.count,
					})

					return React.createElement(Text, {
						text = "Count: " .. count,
					})
				end

				act(function()
					ReactNoop.renderLegacySyncRoot(React.createElement(Counter, { count = 0 }))
					-- Even in legacy mode, effects are deferred until after paint
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Count: (empty)",
					})
					jestExpect(ReactNoop.getChildren()).toEqual({
						span("Count: (empty)"),
					})
				end)
				-- effects get forced on exiting act()
				-- There were multiple updates, but there should only be a
				-- single render
				jestExpect(Scheduler).toHaveYielded({
					"Count: 0",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 0"),
				})
			end
		)

		it("flushSync is not allowed", function()
			local function Counter(props)
				local count, updateCount = useState("(empty)")

				useEffect(function()
					Scheduler.unstable_yieldValue(("Schedule update [%s]"):format(props.count))
					ReactNoop.flushSync(function()
						updateCount(props.count)
					end)
					jestExpect(ReactNoop.getChildren()).never.toEqual({
						span("Count: " .. props.count),
					})
				end, {
					props.count,
				})

				return React.createElement(Text, {
					text = "Count: " .. count,
				})
			end

			jestExpect(function()
				return act(function()
					ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
						return Scheduler.unstable_yieldValue("Sync effect")
					end)
					jestExpect(Scheduler).toFlushAndYieldThrough({
						"Count: (empty)",
						"Sync effect",
					})
					jestExpect(ReactNoop.getChildren()).toEqual({
						span("Count: (empty)"),
					})
				end)
			end).toErrorDev("flushSync was called from inside a lifecycle method")
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 0"),
			})
		end)

		it("unmounts previous effect", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Did create [" .. tostring(props.count) .. "]")
					return function()
						Scheduler.unstable_yieldValue("Did destroy [" .. tostring(props.count) .. "]")
					end
				end)
				return React.createElement(Text, { text = "Count: " .. props.count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did create [0]" })

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did destroy [0]", "Did create [1]" })
		end)

		it("unmounts on deletion", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Did create [" .. tostring(props.count) .. "]")
					return function()
						Scheduler.unstable_yieldValue("Did destroy [" .. tostring(props.count) .. "]")
					end
				end)
				return React.createElement(Text, { text = "Count: " .. tostring(props.count) })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did create [0]" })

			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushAndYield({ "Did destroy [0]" })
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)

		it("unmounts on deletion after skipped effect", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Did create [%d]"):format(props.count))
					return function()
						Scheduler.unstable_yieldValue(("Did destroy [%d]"):format(props.count))
					end
				end, {})
				return React.createElement(Text, { text = "Count: " .. props.count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did create [0]" })

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)

			jestExpect(Scheduler).toHaveYielded({})

			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushAndYield({ "Did destroy [0]" })
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)

		it("always fires effects if no dependencies are provided", function()
			local function effect()
				Scheduler.unstable_yieldValue("Did create")
				return function()
					Scheduler.unstable_yieldValue("Did destroy")
				end
			end
			local function Counter(props)
				useEffect(effect)
				return React.createElement(Text, { text = "Count: " .. props.count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did create" })

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did destroy", "Did create" })

			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushAndYield({ "Did destroy" })
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)

		it("skips effect if inputs have not changed", function()
			local function Counter(props)
				local text = tostring(props.label) .. ": " .. tostring(props.count)
				useEffect(function()
					Scheduler.unstable_yieldValue("Did create [" .. text .. "]")
					return function()
						Scheduler.unstable_yieldValue("Did destroy [" .. text .. "]")
					end
				end, {
					props.label,
					props.count,
				})
				return React.createElement(Text, { text = text })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { label = "Count", count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did create [Count: 0]" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })

			act(function()
				ReactNoop.render(React.createElement(Counter, { label = "Count", count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				-- Count changed
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)

			jestExpect(Scheduler).toHaveYielded({
				"Did destroy [Count: 0]",
				"Did create [Count: 1]",
			})

			act(function()
				ReactNoop.render(React.createElement(Counter, { label = "Count", count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				-- Nothing changed, so no effect should have fired
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
			end)

			jestExpect(Scheduler).toHaveYielded({})
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })

			act(function()
				ReactNoop.render(React.createElement(Counter, { label = "Total", count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				-- Label changed
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Total: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Total: 1") })
			end)

			jestExpect(Scheduler).toHaveYielded({
				"Did destroy [Count: 1]",
				"Did create [Total: 1]",
			})
		end)

		it("multiple effects", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Did commit 1 [" .. tostring(props.count) .. "]")
				end)
				useEffect(function()
					Scheduler.unstable_yieldValue("Did commit 2 [" .. tostring(props.count) .. "]")
				end)
				return React.createElement(Text, { text = "Count: " .. tostring(props.count) })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Did commit 1 [0]", "Did commit 2 [0]" })

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)
			jestExpect(Scheduler).toHaveYielded({ "Did commit 1 [1]", "Did commit 2 [1]" })
		end)

		it("unmounts all previous effects before creating any new ones", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Mount A [" .. props.count .. "]")
					return function()
						Scheduler.unstable_yieldValue("Unmount A [" .. props.count .. "]")
					end
				end)
				useEffect(function()
					Scheduler.unstable_yieldValue("Mount B [" .. props.count .. "]")
					return function()
						Scheduler.unstable_yieldValue("Unmount B [" .. props.count .. "]")
					end
				end)
				return React.createElement(Text, { text = "Count: " .. props.count })
			end
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 0", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Mount A [0]", "Mount B [0]" })

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Count: 1", "Sync effect" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Unmount A [0]",
				"Unmount B [0]",
				"Mount A [1]",
				"Mount B [1]",
			})
		end)

		it("unmounts all previous effects between siblings before creating any new ones", function()
			local function Counter(props)
				local count, label = props.count, props.label

				useEffect(function()
					Scheduler.unstable_yieldValue(("Mount %s [%s]"):format(label, count))

					return function()
						Scheduler.unstable_yieldValue(("Unmount %s [%s]"):format(label, count))
					end
				end)

				return React.createElement(Text, {
					text = ("%s %s"):format(label, count),
				})
			end

			act(function()
				ReactNoop.render(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(Counter, {
							label = "A",
							count = 0,
						}),
						React.createElement(Counter, {
							label = "B",
							count = 0,
						})
					),
					function()
						return Scheduler.unstable_yieldValue("Sync effect")
					end
				)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"A 0",
					"B 0",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("A 0"),
					span("B 0"),
				})
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Mount A [0]",
				"Mount B [0]",
			})
			act(function()
				ReactNoop.render(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(Counter, {
							label = "A",
							count = 1,
						}),
						React.createElement(Counter, {
							label = "B",
							count = 1,
						})
					),
					function()
						return Scheduler.unstable_yieldValue("Sync effect")
					end
				)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"A 1",
					"B 1",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("A 1"),
					span("B 1"),
				})
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Unmount A [0]",
				"Unmount B [0]",
				"Mount A [1]",
				"Mount B [1]",
			})
			act(function()
				ReactNoop.render(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(Counter, {
							label = "B",
							count = 2,
						}),
						React.createElement(Counter, {
							label = "C",
							count = 0,
						})
					),
					function()
						return Scheduler.unstable_yieldValue("Sync effect")
					end
				)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"B 2",
					"C 0",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("B 2"),
					span("C 0"),
				})
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Unmount A [1]",
				"Unmount B [1]",
				"Mount B [2]",
				"Mount C [0]",
			})
		end)
		it("handles errors in create on mount", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Mount A [%s]"):format(props.count))

					return function()
						Scheduler.unstable_yieldValue(("Unmount A [%s]"):format(props.count))
					end
				end)
				useEffect(function()
					Scheduler.unstable_yieldValue("Oops!")
					error("Oops!")
					-- deviation: upstream notes that following code is unreachable.
					-- Scheduler.unstable_yieldValue(('Mount B [%s]'):format(props.count))
					-- return function()
					--     Scheduler.unstable_yieldValue(('Unmount B [%s]'):format(props.count))
					-- end
				end)

				return React.createElement(Text, {
					text = "Count: " .. props.count,
				})
			end

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: 0",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 0"),
				})
				jestExpect(function()
					return ReactNoop.flushPassiveEffects()
				end).toThrow("Oops")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Mount A [0]",
				"Oops!",
				"Unmount A [0]",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)
		it("handles errors in create on update", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Mount A [%s]"):format(props.count))

					return function()
						Scheduler.unstable_yieldValue(("Unmount A [%s]"):format(props.count))
					end
				end)
				useEffect(function()
					if props.count == 1 then
						Scheduler.unstable_yieldValue("Oops!")
						error("Oops!")
					end

					Scheduler.unstable_yieldValue(("Mount B [%s]"):format(props.count))

					return function()
						Scheduler.unstable_yieldValue(("Unmount B [%s]"):format(props.count))
					end
				end)

				return React.createElement(Text, {
					text = "Count: " .. props.count,
				})
			end

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: 0",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 0"),
				})
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({
					"Mount A [0]",
					"Mount B [0]",
				})
			end)
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: 1",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 1"),
				})
				jestExpect(function()
					return ReactNoop.flushPassiveEffects()
				end).toThrow("Oops")

				jestExpect(Scheduler).toHaveYielded({
					"Unmount A [0]",
					"Unmount B [0]",
					"Mount A [1]",
					"Oops!",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({})
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Unmount A [1]",
			})
		end)
		it("handles errors in destroy on update", function()
			local function Counter(props)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Mount A [%s]"):format(props.count))

					return function()
						Scheduler.unstable_yieldValue("Oops!")

						if props.count == 0 then
							error("Oops!")
						end
					end
				end)
				useEffect(function()
					Scheduler.unstable_yieldValue(("Mount B [%s]"):format(props.count))

					return function()
						Scheduler.unstable_yieldValue(("Unmount B [%s]"):format(props.count))
					end
				end)

				return React.createElement(Text, {
					text = "Count: " .. props.count,
				})
			end

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: 0",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 0"),
				})
				ReactNoop.flushPassiveEffects()
				jestExpect(Scheduler).toHaveYielded({
					"Mount A [0]",
					"Mount B [0]",
				})
			end)
			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Count: 1",
					"Sync effect",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Count: 1"),
				})
				jestExpect(function()
					return ReactNoop.flushPassiveEffects()
				end).toThrow("Oops")
				jestExpect(Scheduler).toHaveYielded({
					"Oops!",
					"Unmount B [0]",
					"Mount A [1]",
					"Mount B [1]",
				})
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Oops!",
				"Unmount B [1]",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)

		it("works with memo", function()
			local function Counter(props)
				local count = props.count

				useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Mount: " .. count)

					return function()
						return Scheduler.unstable_yieldValue("Unmount: " .. count)
					end
				end)

				return React.createElement(Text, {
					text = "Count: " .. count,
				})
			end

			Counter = memo(Counter)

			ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
				return Scheduler.unstable_yieldValue("Sync effect")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Count: 0",
				"Mount: 0",
				"Sync effect",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 0"),
			})
			ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
				return Scheduler.unstable_yieldValue("Sync effect")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Count: 1",
				"Unmount: 0",
				"Mount: 1",
				"Sync effect",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Count: 1"),
			})
			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Unmount: 1",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({})
		end)

		-- ROBLOX FIXME: Error Boundaries are implemented now, most of these should now pass
		--   describe('errors thrown in passive destroy function within unmounted trees', function()
		--     local BrokenUseEffectCleanup
		--     local ErrorBoundary
		--     local DerivedStateOnlyErrorBoundary
		--     local LogOnlyErrorBoundary

		--     beforeEach(function()
		--       BrokenUseEffectCleanup = function()
		--         useEffect(function()
		--           Scheduler.unstable_yieldValue('BrokenUseEffectCleanup useEffect')
		--           return function()
		--             Scheduler.unstable_yieldValue(
		--               'BrokenUseEffectCleanup useEffect destroy',
		--             )
		--             throw new Error('Expected error')
		--           end
		--         }, [])

		--         return 'inner child'
		--       end

		--       ErrorBoundary = class extends React.Component {
		--         state = {error: nil}
		--         static getDerivedStateFromError(error)
		--           Scheduler.unstable_yieldValue(
		--             `ErrorBoundary static getDerivedStateFromError`,
		--           )
		--           return {error}
		--         end
		--         componentDidCatch(error, info)
		--           Scheduler.unstable_yieldValue(`ErrorBoundary componentDidCatch`)
		--         end
		--         render()
		--           if this.state.error)
		--             Scheduler.unstable_yieldValue('ErrorBoundary render error')
		--             return <span prop="ErrorBoundary fallback" />
		--           end
		--           Scheduler.unstable_yieldValue('ErrorBoundary render success')
		--           return this.props.children or nil
		--         end
		--       end

		--       DerivedStateOnlyErrorBoundary = class extends React.Component {
		--         state = {error: nil}
		--         static getDerivedStateFromError(error)
		--           Scheduler.unstable_yieldValue(
		--             `DerivedStateOnlyErrorBoundary static getDerivedStateFromError`,
		--           )
		--           return {error}
		--         end
		--         render()
		--           if this.state.error)
		--             Scheduler.unstable_yieldValue(
		--               'DerivedStateOnlyErrorBoundary render error',
		--             )
		--             return <span prop="DerivedStateOnlyErrorBoundary fallback" />
		--           end
		--           Scheduler.unstable_yieldValue(
		--             'DerivedStateOnlyErrorBoundary render success',
		--           )
		--           return this.props.children or nil
		--         end
		--       end

		--       LogOnlyErrorBoundary = class extends React.Component {
		--         componentDidCatch(error, info)
		--           Scheduler.unstable_yieldValue(
		--             `LogOnlyErrorBoundary componentDidCatch`,
		--           )
		--         end
		--         render()
		--           Scheduler.unstable_yieldValue(`LogOnlyErrorBoundary render`)
		--           return this.props.children or nil
		--         end
		--       end
		--     })

		--     -- @gate old
		--     it('should call componentDidCatch() for the nearest unmounted log-only boundary', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <LogOnlyErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </LogOnlyErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={true} />
		--           </ErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'LogOnlyErrorBoundary render',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={false} />
		--           </ErrorBoundary>,
		--         )
		--         jestExpect(Scheduler).toFlushAndYieldThrough([
		--           'ErrorBoundary render success',
		--         ])
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'LogOnlyErrorBoundary componentDidCatch',
		--       ])
		--     })

		--     -- @gate old
		--     it('should call componentDidCatch() for the nearest unmounted logging-capable boundary', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <ErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </ErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={true} />
		--           </ErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={false} />
		--           </ErrorBoundary>,
		--         )
		--         jestExpect(Scheduler).toFlushAndYieldThrough([
		--           'ErrorBoundary render success',
		--         ])
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'ErrorBoundary componentDidCatch',
		--       ])
		--     })

		--     -- @gate old
		--     it('should not call getDerivedStateFromError for unmounted error boundaries', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <ErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </ErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(<Conditional showChildren={true} />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(<Conditional showChildren={false} />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'ErrorBoundary componentDidCatch',
		--       ])
		--     })

		--     -- @gate old
		--     it('should not throw if there are no unmounted logging-capable boundaries to call', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <DerivedStateOnlyErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </DerivedStateOnlyErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(<Conditional showChildren={true} />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'DerivedStateOnlyErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(<Conditional showChildren={false} />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'BrokenUseEffectCleanup useEffect destroy',
		--       ])
		--     })

		--     -- @gate new
		--     it('should use the nearest still-mounted boundary if there are no unmounted boundaries', function()
		--       act(function()
		--         ReactNoop.render(
		--           <LogOnlyErrorBoundary>
		--             <BrokenUseEffectCleanup />
		--           </LogOnlyErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'LogOnlyErrorBoundary render',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(<LogOnlyErrorBoundary />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'LogOnlyErrorBoundary render',
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'LogOnlyErrorBoundary componentDidCatch',
		--       ])
		--     })

		--     -- @gate new
		--     it('should skip unmounted boundaries and use the nearest still-mounted boundary', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <ErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </ErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(
		--           <LogOnlyErrorBoundary>
		--             <Conditional showChildren={true} />
		--           </LogOnlyErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'LogOnlyErrorBoundary render',
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(
		--           <LogOnlyErrorBoundary>
		--             <Conditional showChildren={false} />
		--           </LogOnlyErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'LogOnlyErrorBoundary render',
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'LogOnlyErrorBoundary componentDidCatch',
		--       ])
		--     })

		--     -- @gate new
		--     it('should call getDerivedStateFromError in the nearest still-mounted boundary', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return <BrokenUseEffectCleanup />
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={true} />
		--           </ErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       act(function()
		--         ReactNoop.render(
		--           <ErrorBoundary>
		--             <Conditional showChildren={false} />
		--           </ErrorBoundary>,
		--         )
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect destroy',
		--         'ErrorBoundary static getDerivedStateFromError',
		--         'ErrorBoundary render error',
		--         'ErrorBoundary componentDidCatch',
		--       ])

		--       jestExpect(ReactNoop.getChildren()).toEqual([
		--         span('ErrorBoundary fallback'),
		--       ])
		--     })

		--     -- @gate new
		--     it('should rethrow error if there are no still-mounted boundaries', function()
		--       function Conditional({showChildren})
		--         if showChildren)
		--           return (
		--             <ErrorBoundary>
		--               <BrokenUseEffectCleanup />
		--             </ErrorBoundary>
		--           )
		--         } else {
		--           return nil
		--         end
		--       end

		--       act(function()
		--         ReactNoop.render(<Conditional showChildren={true} />)
		--       })

		--       jestExpect(Scheduler).toHaveYielded([
		--         'ErrorBoundary render success',
		--         'BrokenUseEffectCleanup useEffect',
		--       ])

		--       jestExpect(function()
		--         act(function()
		--           ReactNoop.render(<Conditional showChildren={false} />)
		--         })
		--       }).toThrow('Expected error')

		--       jestExpect(Scheduler).toHaveYielded([
		--         'BrokenUseEffectCleanup useEffect destroy',
		--       ])

		--       jestExpect(ReactNoop.getChildren()).toEqual([])
		--     })
		--   })

		--   it('calls passive effect destroy functions for memoized components', function()
		--     local Wrapper = ({children}) => children
		--     function Child()
		--       React.useEffect(function()
		--         Scheduler.unstable_yieldValue('passive create')
		--         return function()
		--           Scheduler.unstable_yieldValue('passive destroy')
		--         end
		--       }, [])
		--       React.useLayoutEffect(function()
		--         Scheduler.unstable_yieldValue('layout create')
		--         return function()
		--           Scheduler.unstable_yieldValue('layout destroy')
		--         end
		--       }, [])
		--       Scheduler.unstable_yieldValue('render')
		--       return nil
		--     end

		--     local isEqual = (prevProps, nextProps) =>
		--       prevProps.prop == nextProps.prop
		--     local MemoizedChild = React.memo(Child, isEqual)

		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={1} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([
		--       'render',
		--       'layout create',
		--       'passive create',
		--     ])

		--     -- Include at least one no-op (memoized) update to trigger original bug.
		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={1} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([])

		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={2} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([
		--       'render',
		--       'layout destroy',
		--       'layout create',
		--       'passive destroy',
		--       'passive create',
		--     ])

		--     act(function()
		--       ReactNoop.render(null)
		--     })
		--     jestExpect(Scheduler).toHaveYielded(['layout destroy', 'passive destroy'])
		--   })

		--   it('calls passive effect destroy functions for descendants of memoized components', function()
		--     local Wrapper = ({children}) => children
		--     function Child()
		--       return <Grandchild />
		--     end

		--     function Grandchild()
		--       React.useEffect(function()
		--         Scheduler.unstable_yieldValue('passive create')
		--         return function()
		--           Scheduler.unstable_yieldValue('passive destroy')
		--         end
		--       }, [])
		--       React.useLayoutEffect(function()
		--         Scheduler.unstable_yieldValue('layout create')
		--         return function()
		--           Scheduler.unstable_yieldValue('layout destroy')
		--         end
		--       }, [])
		--       Scheduler.unstable_yieldValue('render')
		--       return nil
		--     end

		--     local isEqual = (prevProps, nextProps) =>
		--       prevProps.prop == nextProps.prop
		--     local MemoizedChild = React.memo(Child, isEqual)

		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={1} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([
		--       'render',
		--       'layout create',
		--       'passive create',
		--     ])

		--     -- Include at least one no-op (memoized) update to trigger original bug.
		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={1} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([])

		--     act(function()
		--       ReactNoop.render(
		--         <Wrapper>
		--           <MemoizedChild key={2} />
		--         </Wrapper>,
		--       )
		--     })
		--     jestExpect(Scheduler).toHaveYielded([
		--       'render',
		--       'layout destroy',
		--       'layout create',
		--       'passive destroy',
		--       'passive create',
		--     ])

		--     act(function()
		--       ReactNoop.render(null)
		--     })
		--     jestExpect(Scheduler).toHaveYielded(['layout destroy', 'passive destroy'])
		--   })
	end)

	describe("useLayoutEffect", function()
		it("fires layout effects after the host has been mutated", function()
			local function getCommittedText()
				local yields = Scheduler.unstable_clearYields()
				local children = ReactNoop.getChildren()
				Scheduler.unstable_yieldValue(yields)
				if children == nil then
					return nil
				end
				return children[1].prop
			end

			local function Counter(props)
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue("Current: " .. getCommittedText())
				end)
				return React.createElement(Text, { text = props.count })
			end

			ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
				Scheduler.unstable_yieldValue("Sync effect")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				{ 0 },
				"Current: 0",
				"Sync effect",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(0) })

			ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
				Scheduler.unstable_yieldValue("Sync effect")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				{ 1 },
				"Current: 1",
				"Sync effect",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span(1) })
		end)

		it("force flushes passive effects before firing new layout effects", function()
			local committedText = "(empty)"

			local function Counter(props)
				useLayoutEffect(function()
					-- Normally this would go in a mutation effect, but this test
					-- intentionally omits a mutation effect.
					committedText = props.count .. ""

					Scheduler.unstable_yieldValue("Mount layout [current: " .. committedText .. "]")
					return function()
						Scheduler.unstable_yieldValue("Unmount layout [current: " .. committedText .. "]")
					end
				end)
				useEffect(function()
					Scheduler.unstable_yieldValue("Mount normal [current: " .. committedText .. "]")
					return function()
						Scheduler.unstable_yieldValue("Unmount normal [current: " .. committedText .. "]")
					end
				end)
				return nil
			end

			act(function()
				ReactNoop.render(React.createElement(Counter, { count = 0 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Mount layout [current: 0]",
					"Sync effect",
				})
				jestExpect(committedText).toEqual("0")
				ReactNoop.render(React.createElement(Counter, { count = 1 }), function()
					return Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({
					"Mount normal [current: 0]",
					"Unmount layout [current: 0]",
					"Mount layout [current: 1]",
					"Sync effect",
				})
				jestExpect(committedText).toEqual("1")
			end)

			jestExpect(Scheduler).toHaveYielded({
				"Unmount normal [current: 1]",
				"Mount normal [current: 1]",
			})
		end)

		-- ROBLOX TODO: this failing, but is it a bug? or this gate not enabled in our config?
		-- @gate skipUnmountedBoundaries
		xit("catches errors thrown in useLayoutEffect", function()
			local ErrorBoundary = React.Component:extend("ErrorBoundary")
			function ErrorBoundary:init()
				self.state = { error = nil }
			end

			function ErrorBoundary.getDerivedStateFromError(errorMsg)
				Scheduler.unstable_yieldValue("ErrorBoundary static getDerivedStateFromError")
				return { errorMsg }
			end

			-- deviation: raised to be above where its used
			local function Component(props)
				local id = props.id
				Scheduler.unstable_yieldValue("Component render " .. id)
				return React.createElement(span, { prop = id })
			end

			function ErrorBoundary:render()
				local children = self.props.children
				local id = self.props.id
				local fallbackID = self.props.fallbackID
				local errorMsg = self.state.error
				if errorMsg then
					Scheduler.unstable_yieldValue(id .. " render error")
					return React.createElement(Component, { id = fallbackID })
				end
				Scheduler.unstable_yieldValue(id .. " render success")

				-- deviation: or nil not necessary in Lua
				return children
			end

			local function BrokenLayoutEffectDestroy()
				useLayoutEffect(function()
					return function()
						Scheduler.unstable_yieldValue("BrokenLayoutEffectDestroy useLayoutEffect destroy")
						error("Expected")
					end
				end, {})

				Scheduler.unstable_yieldValue("BrokenLayoutEffectDestroy render")
				return React.createElement(span, { prop = "broken" })
			end

			ReactNoop.render(React.createElement(ErrorBoundary, { id = "OuterBoundary", fallbackID = "OuterFallback" }, {
				React.createElement(Component, { id = "sibling" }),
				React.createElement(
					ErrorBoundary,
					{ id = "InnerBoundary", fallbackID = "InnerFallback" },
					React.createElement(BrokenLayoutEffectDestroy)
				),
			}))

			jestExpect(Scheduler).toFlushAndYield({
				"OuterBoundary render success",
				"Component render sibling",
				"InnerBoundary render success",
				"BrokenLayoutEffectDestroy render",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				React.createElement(span, { id = "sibling" }),
				React.createElement(span, { id = "broken" }),
			})

			ReactNoop.render(React.createElement(
				ErrorBoundary,
				{ id = "OuterBoundary", fallbackID = "OuterFallback" },
				React.createElement(Component, { id = "sibling" })
			))

			-- React should skip over the unmounting boundary and find the nearest still-mounted boundary.
			jestExpect(Scheduler).toFlushAndYield({
				"OuterBoundary render success",
				"Component render sibling",
				"BrokenLayoutEffectDestroy useLayoutEffect destroy",
				"ErrorBoundary static getDerivedStateFromError",
				"OuterBoundary render error",
				"Component render OuterFallback",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span("OuterFallback") })
		end)
	end)

	describe("useCallback", function()
		it("memoizes callback by comparing inputs", function()
			-- ROBLOX deviation: hoist local
			local button = React.createRef(nil)
			local IncrementButton = React.PureComponent:extend("IncrementButton")
			function IncrementButton:increment()
				self.props.increment()
			end
			function IncrementButton:render()
				return React.createElement(Text, { text = "Increment" })
			end

			-- ROBLOX deviation: we need to hold the instance so we can pass it as an explicit self argument, since Lua doesn't have function bindings
			local incrementButtonInstance

			local function Counter(props)
				local incrementBy = props.incrementBy
				local count, updateCount = useState(0)
				local increment = useCallback(function()
					return updateCount(function(c)
						return c + incrementBy
					end)
				end, {
					incrementBy,
				})
				-- ROBLOX deviation: we need to hold the instance so we can pass it as an explicit self argument, since Lua doesn't have function bindings
				-- ROBLOX deviation: we also assign explicit keys to quiet a warning in DEV mode
				incrementButtonInstance = React.createElement(
					IncrementButton,
					{ key = "1", increment = increment, ref = button }
				)
				return React.createElement(React.Fragment, {}, {
					incrementButtonInstance,
					React.createElement(Text, { key = "2", text = "Count: " .. count }),
				})
			end

			ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Increment", "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Increment"),
				span("Count: 0"),
			})

			-- ROBLOX deviation: call ref increment() with an explicit self argument
			act(function()
				button.current.increment(incrementButtonInstance)
			end)
			jestExpect(Scheduler).toHaveYielded({
				-- Button should not re-render, because its props haven't changed
				-- 'Increment',
				"Count: 1",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Increment"),
				span("Count: 1"),
			})

			-- Increase the increment amount
			ReactNoop.render(React.createElement(Counter, { incrementBy = 10 }))
			jestExpect(Scheduler).toFlushAndYield({
				-- Inputs did change this time
				"Increment",
				"Count: 1",
			})
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Increment"),
				span("Count: 1"),
			})

			-- Callback should have updated
			-- ROBLOX deviation: call ref increment() with an explicit self argument
			act(function()
				button.current.increment(incrementButtonInstance)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 11" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Increment"),
				span("Count: 11"),
			})
		end)
	end)

	describe("useMemo", function()
		it("memoizes value by comparing to previous inputs", function()
			local function CapitalizedText(props)
				local text = props.text
				local capitalizedText = useMemo(function()
					Scheduler.unstable_yieldValue("Capitalize '" .. text .. "'")
					return text:upper()
				end, {
					text,
				})
				return React.createElement(Text, { text = capitalizedText })
			end

			ReactNoop.render(React.createElement(CapitalizedText, { text = "hello" }))
			jestExpect(Scheduler).toFlushAndYield({ "Capitalize 'hello'", "HELLO" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("HELLO") })

			ReactNoop.render(React.createElement(CapitalizedText, { text = "hi" }))
			jestExpect(Scheduler).toFlushAndYield({ "Capitalize 'hi'", "HI" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("HI") })

			ReactNoop.render(React.createElement(CapitalizedText, { text = "hi" }))
			jestExpect(Scheduler).toFlushAndYield({ "HI" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("HI") })

			ReactNoop.render(React.createElement(CapitalizedText, { text = "goodbye" }))
			jestExpect(Scheduler).toFlushAndYield({ "Capitalize 'goodbye'", "GOODBYE" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("GOODBYE") })
		end)

		it("returns multiple input values", function()
			local function Doubler(props)
				local x = props.x
				local y = props.y
				local xMinusY, xPlusY = useMemo(function()
					local a = x - y
					local b = x + y
					Scheduler.unstable_yieldValue("x - y = " .. tostring(a) .. ", x + y = " .. tostring(b))
					return a, b
				end, {
					x, y
				})
				return React.createElement(Text, { text = tostring(xMinusY) .. tostring(xPlusY) })
			end

			ReactNoop.render(React.createElement(Doubler, { x = 1, y = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "x - y = -1, x + y = 3", "-13" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("-13") })

			ReactNoop.render(React.createElement(Doubler, { x = 4, y = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "x - y = 2, x + y = 6", "26" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("26") })

			ReactNoop.render(React.createElement(Doubler, { x = 4, y = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "26" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("26") })

			ReactNoop.render(React.createElement(Doubler, { x = 8, y = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "x - y = 6, x + y = 10", "610" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("610") })
		end)

		it("always re-computes if no inputs are provided", function()
			local function LazyCompute(props)
				local computed = useMemo(props.compute)
				return React.createElement(Text, { text = computed })
			end

			local function computeA()
				Scheduler.unstable_yieldValue("compute A")
				return "A"
			end

			local function computeB()
				Scheduler.unstable_yieldValue("compute B")
				return "B"
			end

			ReactNoop.render(React.createElement(LazyCompute, { compute = computeA }))
			jestExpect(Scheduler).toFlushAndYield({ "compute A", "A" })

			ReactNoop.render(React.createElement(LazyCompute, { compute = computeA }))
			jestExpect(Scheduler).toFlushAndYield({ "compute A", "A" })

			ReactNoop.render(React.createElement(LazyCompute, { compute = computeA }))
			jestExpect(Scheduler).toFlushAndYield({ "compute A", "A" })

			ReactNoop.render(React.createElement(LazyCompute, { compute = computeB }))
			jestExpect(Scheduler).toFlushAndYield({ "compute B", "B" })
		end)

		it("should not invoke memoized function during re-renders unless inputs change", function()
			local function LazyCompute(props)
				local computed = useMemo(function()
					return props.compute(props.input)
				end, { props.input })
				local count, setCount = useState(0)
				if count < 3 then
					setCount(count + 1)
				end
				return React.createElement(Text, { text = computed })
			end

			local function compute(val)
				Scheduler.unstable_yieldValue("compute " .. val)
				return val
			end

			ReactNoop.render(React.createElement(LazyCompute, { compute = compute, input = "A" }))
			jestExpect(Scheduler).toFlushAndYield({ "compute A", "A" })

			ReactNoop.render(React.createElement(LazyCompute, { compute = compute, input = "A" }))
			jestExpect(Scheduler).toFlushAndYield({ "A" })

			ReactNoop.render(React.createElement(LazyCompute, { compute = compute, input = "B" }))
			jestExpect(Scheduler).toFlushAndYield({ "compute B", "B" })
		end)
	end)

	describe("useRef", function()
		-- ROBLOX TODO: clearTimeout: attempt to index number with userdata (LUAFDN-293)
		it("creates a ref object initialized with the provided value", function()
			local jest = RobloxJest

			local function useDebouncedCallback(callback, ms, inputs)
				local timeoutID = useRef(-1)
				useEffect(function()
					return function()
						if typeof(timeoutID.current) == "table" then
							clearTimeout(timeoutID.current)
						end
					end
				end, {})
				local debouncedCallback = useCallback(function(...)
					if typeof(timeoutID.current) == "table" then
						clearTimeout(timeoutID.current)
					end
					timeoutID.current = setTimeout(callback, ms, ...)
				end, {
					callback,
					ms,
				})
				return useCallback(debouncedCallback, inputs)
			end

			local ping
			local function App()
				ping = useDebouncedCallback(function(value)
					Scheduler.unstable_yieldValue("ping: " .. value)
				end, 100, {})
				return nil
			end

			act(function()
				ReactNoop.render(React.createElement(App))
			end)
			jestExpect(Scheduler).toHaveYielded({})

			ping(1)
			ping(2)
			ping(3)

			jestExpect(Scheduler).toHaveYielded({})

			jest.advanceTimersByTime(100)

			jestExpect(Scheduler).toHaveYielded({ "ping: 3" })

			ping(4)
			jest.advanceTimersByTime(20)
			jestExpect(Scheduler).toHaveYielded({})
			ping(5)
			jestExpect(Scheduler).toHaveYielded({})
			ping(6)
			jestExpect(Scheduler).toHaveYielded({})
			jest.advanceTimersByTime(80)

			jestExpect(Scheduler).toHaveYielded({})

			jest.advanceTimersByTime(20)
			jestExpect(Scheduler).toHaveYielded({ "ping: 6" })
		end)

		it("should return the same ref during re-renders", function()
			local function Counter()
				local ref = useRef("val")
				local count, setCount = useState(0)
				local firstRef = useState(ref)

				if firstRef ~= ref then
					error("should never change")
				end

				if count < 3 then
					setCount(count + 1)
				end

				return React.createElement(Text, { text = ref.current })
			end

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({ "val" })

			ReactNoop.render(React.createElement(Counter))
			jestExpect(Scheduler).toFlushAndYield({ "val" })
		end)
	end)

	describe("useImperativeHandle", function()
		it("does not update when deps are the same", function()
			local INCREMENT = "INCREMENT"

			local function reducer_(state, action)
				if action == INCREMENT then
					return state + 1
				else
					return state
				end
			end

			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					return { count = count, dispatch = dispatch }
				end, {})
				return React.createElement(Text, { text = "Count: " .. count })
			end

			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, {
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			jestExpect(counter.current.count).toEqual(0)

			act(function()
				counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			-- Intentionally not updated because of [] deps:
			jestExpect(counter.current.count).toEqual(0)
		end)

		-- Regression test for https://github.com/facebook/react/issues/14782
		it("automatically updates when deps are not specified", function()
			local INCREMENT = "INCREMENT"

			local function reducer_(state, action)
				if action == INCREMENT then
					return state + 1
				else
					return state
				end
			end

			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					return { count = count, dispatch = dispatch }
				end)
				return React.createElement(Text, { text = "Count: " .. count })
			end

			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, {
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			jestExpect(counter.current.count).toEqual(0)

			act(function()
				counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			jestExpect(counter.current.count).toEqual(1)
		end)

		it("updates when deps are different", function()
			local INCREMENT = "INCREMENT"

			local function reducer_(state, action)
				if action == INCREMENT then
					return state + 1
				else
					return state
				end
			end

			local totalRefUpdates = 0
			local function Counter(props, ref)
				local count, dispatch = useReducer(reducer_, 0)
				useImperativeHandle(ref, function()
					totalRefUpdates = totalRefUpdates + 1
					return { count = count, dispatch = dispatch }
				end, {
					count,
				})
				return React.createElement(Text, { text = "Count: " .. count })
			end

			Counter = forwardRef(Counter)
			local counter = React.createRef(nil)
			ReactNoop.render(React.createElement(Counter, {
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 0") })
			jestExpect(counter.current.count).toEqual(0)
			jestExpect(totalRefUpdates).toEqual(1)

			act(function()
				counter.current.dispatch(INCREMENT)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			jestExpect(counter.current.count).toEqual(1)
			jestExpect(totalRefUpdates).toEqual(2)

			-- Update that doesn't change the ref dependencies
			ReactNoop.render(React.createElement(Counter, {
				ref = counter,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Count: 1") })
			jestExpect(counter.current.count).toEqual(1)
			jestExpect(totalRefUpdates).toEqual(2) -- Should not increase since last time
		end)
	end)
	-- describe('useTransition', function()
	--   -- @gate experimental
	--   it('delays showing loading state until after timeout', async function()
	--     local transition
	--     function App()
	--       local [show, setShow] = useState(false)
	--       local [startTransition, isPending] = useTransition({
	--         timeoutMs: 1000,
	--       })
	--       transition = function()
	--         startTransition(function()
	--           setShow(true)
	--         })
	--       end
	--       return (
	--         <Suspense
	--           fallback={<Text text={`Loading... Pending: ${isPending}`} />}>
	--           {show ? (
	--             <AsyncText text={`After... Pending: ${isPending}`} />
	--           ) : (
	--             <Text text={`Before... Pending: ${isPending}`} />
	--           )}
	--         </Suspense>
	--       )
	--     end
	--     ReactNoop.render(<App />)
	--     jestExpect(Scheduler).toFlushAndYield(['Before... Pending: false'])
	--     jestExpect(ReactNoop.getChildren()).toEqual([
	--       span('Before... Pending: false'),
	--     ])

	--     await act(async function()
	--       Scheduler.unstable_runWithPriority(
	--         Scheduler.unstable_UserBlockingPriority,
	--         transition,
	--       )

	--       jestExpect(Scheduler).toFlushAndYield([
	--         'Before... Pending: true',
	--         'Suspend! [After... Pending: false]',
	--         'Loading... Pending: false',
	--       ])
	--       jestExpect(ReactNoop.getChildren()).toEqual([
	--         span('Before... Pending: true'),
	--       ])
	--       Scheduler.unstable_advanceTime(500)
	--       await advanceTimers(500)

	--       -- Even after a long amount of time, we still don't show a placeholder.
	--       Scheduler.unstable_advanceTime(100000)
	--       await advanceTimers(100000)
	--       jestExpect(ReactNoop.getChildren()).toEqual([
	--         span('Before... Pending: true'),
	--       ])

	--       await resolveText('After... Pending: false')
	--       jestExpect(Scheduler).toHaveYielded([
	--         'Promise resolved [After... Pending: false]',
	--       ])
	--       jestExpect(Scheduler).toFlushAndYield(['After... Pending: false'])
	--       jestExpect(ReactNoop.getChildren()).toEqual([
	--         span('After... Pending: false'),
	--       ])
	--     })
	--   })
	-- })

	-- describe('useDeferredValue', function()
	--   -- @gate experimental
	--   it('defers text value', async function()
	--     function TextBox({text})
	--       return <AsyncText text={text} />
	--     end

	--     local _setText
	--     function App()
	--       local [text, setText] = useState('A')
	--       local deferredText = useDeferredValue(text, {
	--         timeoutMs: 500,
	--       })
	--       _setText = setText
	--       return (
	--         <>
	--           <Text text={text} />
	--           <Suspense fallback={<Text text={'Loading'} />}>
	--             <TextBox text={deferredText} />
	--           </Suspense>
	--         </>
	--       )
	--     end

	--     act(function()
	--       ReactNoop.render(<App />)
	--     })

	--     jestExpect(Scheduler).toHaveYielded(['A', 'Suspend! [A]', 'Loading'])
	--     jestExpect(ReactNoop.getChildren()).toEqual([span('A'), span('Loading')])

	--     await resolveText('A')
	--     jestExpect(Scheduler).toHaveYielded(['Promise resolved [A]'])
	--     jestExpect(Scheduler).toFlushAndYield(['A'])
	--     jestExpect(ReactNoop.getChildren()).toEqual([span('A'), span('A')])

	--     await act(async function()
	--       _setText('B')
	--       jestExpect(Scheduler).toFlushAndYield([
	--         'B',
	--         'A',
	--         'B',
	--         'Suspend! [B]',
	--         'Loading',
	--       ])
	--       jestExpect(Scheduler).toFlushAndYield([])
	--       jestExpect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])
	--     })

	--     await act(async function()
	--       Scheduler.unstable_advanceTime(250)
	--       await advanceTimers(250)
	--     })
	--     jestExpect(Scheduler).toHaveYielded([])
	--     jestExpect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])

	--     -- Even after a long amount of time, we don't show a fallback
	--     Scheduler.unstable_advanceTime(100000)
	--     await advanceTimers(100000)
	--     jestExpect(Scheduler).toFlushAndYield([])
	--     jestExpect(ReactNoop.getChildren()).toEqual([span('B'), span('A')])

	--     await act(async function()
	--       await resolveText('B')
	--     })
	--     jestExpect(Scheduler).toHaveYielded(['Promise resolved [B]', 'B', 'B'])
	--     jestExpect(ReactNoop.getChildren()).toEqual([span('B'), span('B')])
	--   })
	-- })

	describe("progressive enhancement (not supported)", function()
		it("mount additional state", function()
			local updateA
			local updateB
			-- local updateC

			local function App(props)
				local A, _updateA = useState(0)
				local B, _updateB = useState(0)
				updateA = _updateA
				updateB = _updateB

				local C
				if props.loadC then
					useState(0)
				else
					C = "[not loaded]"
				end

				return React.createElement(Text, {
					text = ("A: %s, B: %s, C: %s"):format(A, B, C),
				})
			end

			ReactNoop.render(React.createElement(App, { loadC = false }))
			jestExpect(Scheduler).toFlushAndYield({ "A: 0, B: 0, C: [not loaded]" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("A: 0, B: 0, C: [not loaded]"),
			})

			act(function()
				updateA(2)
				updateB(3)
			end)

			jestExpect(Scheduler).toHaveYielded({ "A: 2, B: 3, C: [not loaded]" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("A: 2, B: 3, C: [not loaded]"),
			})

			ReactNoop.render(React.createElement(App, { loadC = true }))
			jestExpect(function()
				jestExpect(function()
					jestExpect(Scheduler).toFlushAndYield({ "A: 2, B: 3, C: 0" })
				end).toThrow("Rendered more hooks than during the previous render")
			end).toErrorDev({
				"Warning: React has detected a change in the order of Hooks called by App. " .. "This will lead to bugs and errors if not fixed. For more information, " .. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n" .. "   Previous render            Next render\n" .. "   ------------------------------------------------------\n" .. "1. useState                   useState\n" .. "2. useState                   useState\n" .. "3. undefined                  useState\n" .. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n",
			})

			-- Uncomment if/when we support this again
			-- jestExpect(ReactNoop.getChildren()).toEqual([span('A: 2, B: 3, C: 0')])

			-- updateC(4)
			-- jestExpect(Scheduler).toFlushAndYield(['A: 2, B: 3, C: 4'])
			-- jestExpect(ReactNoop.getChildren()).toEqual([span('A: 2, B: 3, C: 4')])
		end)

		it("unmount state", function()
			local updateA
			local updateB
			local updateC

			local function App(props)
				local A, _updateA = useState(0)
				local B, _updateB = useState(0)
				updateA = _updateA
				updateB = _updateB

				local C
				if props.loadC then
					local _C, _updateC = useState(0)
					C = _C
					updateC = _updateC
				else
					C = "[not loaded]"
				end

				return React.createElement(Text, {
					text = ("A: %s, B: %s, C: %s"):format(A, B, C),
				})
			end

			ReactNoop.render(React.createElement(App, { loadC = true }))
			jestExpect(Scheduler).toFlushAndYield({ "A: 0, B: 0, C: 0" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("A: 0, B: 0, C: 0") })
			act(function()
				updateA(2)
				updateB(3)
				updateC(4)
			end)
			jestExpect(Scheduler).toHaveYielded({ "A: 2, B: 3, C: 4" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("A: 2, B: 3, C: 4") })
			ReactNoop.render(React.createElement(App, { loadC = false }))
			jestExpect(Scheduler).toFlushAndThrow(
				"Rendered fewer hooks than expected. This may be caused by an " .. "accidental early return statement."
			)
		end)

		it("unmount effects", function()
			local function App(props)
				useEffect(function()
					Scheduler.unstable_yieldValue("Mount A")
					return function()
						Scheduler.unstable_yieldValue("Unmount A")
					end
				end, {})

				if props.showMore then
					useEffect(function()
						Scheduler.unstable_yieldValue("Mount B")
						return function()
							Scheduler.unstable_yieldValue("Unmount B")
						end
					end, {})
				end

				return nil
			end

			act(function()
				ReactNoop.render(React.createElement(App, { showMore = false }), function()
					Scheduler.unstable_yieldValue("Sync effect")
				end)
				jestExpect(Scheduler).toFlushAndYieldThrough({ "Sync effect" })
			end)

			jestExpect(Scheduler).toHaveYielded({ "Mount A" })

			act(function()
				ReactNoop.render(React.createElement(App, { showMore = true }))
				jestExpect(function()
					jestExpect(function()
						jestExpect(Scheduler).toFlushAndYield({})
					end).toThrow("Rendered more hooks than during the previous render")
				end).toErrorDev({
					"Warning: React has detected a change in the order of Hooks called by App. " .. "This will lead to bugs and errors if not fixed. For more information, " .. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n" .. "   Previous render            Next render\n" .. "   ------------------------------------------------------\n" .. "1. useEffect                  useEffect\n" .. "2. undefined                  useEffect\n" .. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n",
				})
			end)

			-- Uncomment if/when we support this again
			-- ReactNoop.flushPassiveEffects()
			-- jestExpect(Scheduler).toHaveYielded(['Mount B'])

			-- ReactNoop.render(<App showMore={false} />)
			-- jestExpect(Scheduler).toFlushAndThrow(
			--   'Rendered fewer hooks than expected. This may be caused by an ' ..
			--     'accidental early return statement.',
			-- )
		end)
	end)

	it("eager bailout optimization should always compare to latest rendered reducer", function()
		-- Edge case based on a bug report
		local counter, setCounter

		local function Component(props)
			-- ROBLOX deviation: can't destructure list in Lua function arguments
			local count = props.count
			local state, dispatch = useReducer(function()
				-- This reducer closes over a value from props. If the reducer is not
				-- properly updated, the eager reducer will compare to an old value
				-- and bail out incorrectly.
				Scheduler.unstable_yieldValue("Reducer: " .. count)
				return count
			end, -1)
			useEffect(function()
				Scheduler.unstable_yieldValue("Effect: " .. count)
				dispatch()
			end, {
				count,
			})
			Scheduler.unstable_yieldValue("Render: " .. state)
			return count
		end

		local function App()
			counter, setCounter = useState(1)
			return React.createElement(Component, { count = counter })
		end

		act(function()
			ReactNoop.render(React.createElement(App))
			jestExpect(Scheduler).toFlushAndYield({
				"Render: -1",
				"Effect: 1",
				"Reducer: 1",
				"Reducer: 1",
				"Render: 1",
			})

			jestExpect(ReactNoop).toMatchRenderedOutput("1")
		end)

		act(function()
			setCounter(2)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Render: 1",
			"Effect: 2",
			"Reducer: 2",
			"Reducer: 2",
			"Render: 2",
		})

		jestExpect(ReactNoop).toMatchRenderedOutput("2")
	end)

	-- ROBLOX FIXME: this test needs to be enabled
	-- -- Regression test. Covers a case where an internal state variable
	-- -- (`didReceiveUpdate`) is not reset properly.
	-- it('state bail out edge case (#16359)', async function()
	--   local setCounterA
	--   local setCounterB

	--   function CounterA()
	--     local [counter, setCounter] = useState(0)
	--     setCounterA = setCounter
	--     Scheduler.unstable_yieldValue('Render A: ' .. counter)
	--     useEffect(function()
	--       Scheduler.unstable_yieldValue('Commit A: ' .. counter)
	--     })
	--     return counter
	--   end

	--   function CounterB()
	--     local [counter, setCounter] = useState(0)
	--     setCounterB = setCounter
	--     Scheduler.unstable_yieldValue('Render B: ' .. counter)
	--     useEffect(function()
	--       Scheduler.unstable_yieldValue('Commit B: ' .. counter)
	--     })
	--     return counter
	--   end

	--   local root = ReactNoop.createRoot(null)
	--   await ReactNoop.act(async function()
	--     root.render(
	--       <>
	--         <CounterA />
	--         <CounterB />
	--       </>,
	--     )
	--   })
	--   jestExpect(Scheduler).toHaveYielded([
	--     'Render A: 0',
	--     'Render B: 0',
	--     'Commit A: 0',
	--     'Commit B: 0',
	--   ])

	--   await ReactNoop.act(async function()
	--     setCounterA(1)

	--     -- In the same batch, update B twice. To trigger the condition we're
	--     -- testing, the first update is necessary to bypass the early
	--     -- bailout optimization.
	--     setCounterB(1)
	--     setCounterB(0)
	--   })
	--   jestExpect(Scheduler).toHaveYielded([
	--     'Render A: 1',
	--     'Render B: 0',
	--     'Commit A: 1',
	--     -- B should not fire an effect because the update bailed out
	--     -- 'Commit B: 0',
	--   ])
	-- })

	it("should update latest rendered reducer when a preceding state receives a render phase update", function()
		-- Similar to previous test, except using a preceding render phase update
		-- instead of new props.
		local shadow, dispatch
		local function App()
			local step, setStep = useState(0)
			shadow, dispatch = useReducer(function()
				return step
			end, step)

			if step < 5 then
				setStep(step + 1)
			end

			Scheduler.unstable_yieldValue("Step: " .. step .. ", Shadow: " .. shadow)
			return shadow
		end

		ReactNoop.render(React.createElement(App))
		jestExpect(Scheduler).toFlushAndYield({
			"Step: 0, Shadow: 0",
			"Step: 1, Shadow: 0",
			"Step: 2, Shadow: 0",
			"Step: 3, Shadow: 0",
			"Step: 4, Shadow: 0",
			"Step: 5, Shadow: 0",
		})

		jestExpect(ReactNoop).toMatchRenderedOutput("0")

		act(function()
			return dispatch()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Step: 5, Shadow: 5" })
		jestExpect(ReactNoop).toMatchRenderedOutput("5")
	end)

	it("should process the rest pending updates after a render phase update", function()
		-- Similar to previous test, except using a preceding render phase update
		-- instead of new props.
		local updateA
		local updateC
		local function App()
			local a, setA = useState(false)
			local b, setB = useState(false)
			if a ~= b then
				setB(a)
			end
			-- Even though we called setB above,
			-- we should still apply the changes to C,
			-- during this render pass.
			local c, setC = useState(false)
			updateA = setA
			updateC = setC
			return ("%s%s%s"):format(a and "A" or "a", b and "B" or "b", c and "C" or "c")
		end

		act(function()
			ReactNoop.render(React.createElement(App))
		end)
		jestExpect(ReactNoop).toMatchRenderedOutput("abc")

		act(function()
			updateA(true)
			-- This update should not get dropped.
			updateC(true)
		end)
		jestExpect(ReactNoop).toMatchRenderedOutput("ABC")
	end)

	it("regression test: don't unmount effects on siblings of deleted nodes", function()
		local root = ReactNoop.createRoot()

		local function Child(props)
			local label = props.label
			useLayoutEffect(function()
				Scheduler.unstable_yieldValue('Mount layout ' .. label)
				return function()
					Scheduler.unstable_yieldValue('Unmount layout ' .. label)
				end
			end, {label})
			useEffect(function()
				Scheduler.unstable_yieldValue('Mount passive ' .. label)
				return function()
					Scheduler.unstable_yieldValue('Unmount passive ' .. label)
				end
			end, {label})
			return label
		end

		act(function()
			root.render(
				React.createElement(React.Fragment, nil,
					React.createElement(Child, {key = "A", label = "A"}),
					React.createElement(Child, {key = "B", label = "B"})
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({
			'Mount layout A',
			'Mount layout B',
			'Mount passive A',
			'Mount passive B',
		})

		-- Delete A. This should only unmount the effect on A. In the regression,
		-- B's effect would also unmount.
		act(function()
			root.render(
				React.createElement(React.Fragment, nil,
					React.createElement(Child, {key = "B", label = "B"})
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({'Unmount layout A', 'Unmount passive A'})

		-- Now delete and unmount B.
		act(function()
			root.render(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({'Unmount layout B', 'Unmount passive B'})
	end)

	it("regression: deleting a tree and unmounting its effects after a reorder", function()
		local root = ReactNoop.createRoot()

		local function Child(props)
			local label = props.label
			useEffect(function()
				Scheduler.unstable_yieldValue('Mount ' .. label)
				return function()
					Scheduler.unstable_yieldValue('Unmount ' .. label)
				end
			end, {label})
			return label
		end

		act(function()
			root.render(
				React.createElement(React.Fragment, nil,
					React.createElement(Child, {key = "A", label = "A"}),
					React.createElement(Child, {key = "B", label = "B"})
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({
			'Mount A',
			'Mount B',
		})

		act(function()
			root.render(
				React.createElement(React.Fragment, nil,
					React.createElement(Child, {key = "B", label = "B"}),
					React.createElement(Child, {key = "A", label = "A"})
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({})

		act(function()
			root.render(nil)
		end)
		jestExpect(Scheduler).toHaveYielded({
			'Unmount B',
			-- In the regression, the reorder would cause Child A to "forget" that it
			-- contains passive effects. Then when we deleted the tree, A's unmount
			-- effect would not fire.
			'Unmount A'})
	end)

	it("effect dependencies are persisted after a render phase update", function()
		local handleClick
		local function Test()
			local count, setCount = useState(0)
			useEffect(function()
				Scheduler.unstable_yieldValue('Effect: ' .. count)
			end, {count})

			if count > 0 then
				setCount(0)
			end

			handleClick = function()
				return setCount(2)
			end

			return React.createElement(Text, {text=string.format("Render: %d", count)})
		end

		act(function()
			ReactNoop.render(React.createElement(Test))
		end)

		jestExpect(Scheduler).toHaveYielded({'Render: 0', 'Effect: 0'})

		act(function()
			handleClick()
		end)

		jestExpect(Scheduler).toHaveYielded({'Render: 0'})

		act(function()
			handleClick()
		end)

		jestExpect(Scheduler).toHaveYielded({'Render: 0'})

		act(function()
			handleClick()
		end)

		jestExpect(Scheduler).toHaveYielded({'Render: 0'})
	end)
end
