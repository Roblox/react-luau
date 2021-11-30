-- upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactHooks-test.internal.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

local React
local ReactFeatureFlags
local ReactTestRenderer
local Scheduler
-- local ReactDOMServer
local act
return function()
	describe("ReactHooks", function()
		local Packages = script.Parent.Parent.Parent
		local jest = require(Packages.Dev.RobloxJest)
		local jestExpect = require(Packages.Dev.JestGlobals).expect
		local Promise = require(Packages.Promise)
		local LuauPolyfill = require(Packages.LuauPolyfill)
		local Array = LuauPolyfill.Array
		local Error = LuauPolyfill.Error

		beforeEach(function()
			jest.resetModules()
			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			React = require(Packages.React)
			ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
			Scheduler = require(Packages.Scheduler)
			-- ReactDOMServer = require("react-dom/server")
			act = ReactTestRenderer.unstable_concurrentAct
		end)
		if _G.__DEV__ then
			it("useDebugValue throws when used in a class component", function()
				type Example = { render: any } --[[ ROBLOX TODO: replace 'any' type/ add missing ]]
				local Example = React.Component:extend("Example")
				function Example:render()
					React.useDebugValue("abc")
					return nil
				end
				jestExpect(function()
					ReactTestRenderer.create(React.createElement(Example))
				end).toThrow(
					"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen"
						.. " for one of the following reasons:\n"
						.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
						.. "2. You might be breaking the Rules of Hooks\n"
						.. "3. You might have more than one copy of React in the same app\n"
						.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
				)
			end)
		end
		-- ROBLOX FIXME: this fails intermittently across different machines. Mac gets -0 for some of these, Linux gets 0.
		itSKIP("bails out in the render phase if all of the state is the same", function()
			local useState, useLayoutEffect = React.useState, React.useLayoutEffect
			local function Child(props)
				local text = props.text
				Scheduler.unstable_yieldValue("Child: " .. tostring(text))
				return text
			end
			local setCounter1
			local setCounter2
			local function Parent()
				local counter1, _setCounter1 = useState(0)
				setCounter1 = _setCounter1
				local counter2, _setCounter2 = useState(0)
				setCounter2 = _setCounter2
				local text = ("%s, %s"):format(counter1, counter2)
				Scheduler.unstable_yieldValue(("Parent: %s"):format(text))
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue(("Effect: %s"):format(text))
				end)
				return React.createElement(Child, { text = text })
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			root.update(React.createElement(Parent, nil))
			jestExpect(Scheduler).toFlushAndYield({
				"Parent: 0, 0",
				"Child: 0, 0",
				"Effect: 0, 0",
			})
			jestExpect(root).toMatchRenderedOutput("0, 0")
			act(function()
				setCounter1(1)
				setCounter2(1)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Parent: 1, 1",
				"Child: 1, 1",
				"Effect: 1, 1",
			})
			act(function()
				return setCounter1(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Parent: 1, 1" })
			act(function()
				setCounter1(1)
				setCounter2(2)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Parent: 1, 2",
				"Child: 1, 2",
				"Effect: 1, 2",
			})
			act(function()
				setCounter1(9)
				setCounter2(3)
				setCounter1(4)
				setCounter2(7)
				setCounter1(1)
				setCounter2(2)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Parent: 1, 2" })
			act(function()
				setCounter1(0 / -1)
				setCounter2(0 / 0)
			end)
			jestExpect(Scheduler).toHaveYielded({
				-- ROBLOX deviation: use Luau stringified versions of the math
				"Parent: -0, nan",
				"Child: -0, nan",
				"Effect: -0, nan",
			})
			act(function()
				setCounter1(0 / -1)
				setCounter2(0 / 0)
				setCounter2(math.huge)
				setCounter2(0 / 0)
			end)
			-- ROBLOX deviation: use Luau stringified versions of the math
			jestExpect(Scheduler).toHaveYielded({ "Parent: -0, nan" })
			act(function()
				setCounter1(0)
			end)
			jestExpect(Scheduler).toHaveYielded({
				-- ROBLOX deviation: use Luau stringified versions of the math
				"Parent: 0, nan",
				"Child: 0, nan",
				"Effect: 0, nan",
			})
		end)
		it(
			"bails out in render phase if all the state is the same and props bail out with memo",
			function()
				local useState, memo = React.useState, React.memo
				local function Child(props)
					local text = props.text
					Scheduler.unstable_yieldValue("Child: " .. tostring(text))
					return text
				end
				local setCounter1
				local setCounter2
				local function Parent(ref)
					local theme = ref.theme
					local counter1, _setCounter1 = useState(0)
					setCounter1 = _setCounter1
					local counter2, _setCounter2 = useState(0)
					setCounter2 = _setCounter2
					local text = ("%s, %s (%s)"):format(counter1, counter2, theme)
					Scheduler.unstable_yieldValue(("Parent: %s"):format(text))
					return React.createElement(Child, { text = text })
				end
				Parent = memo(Parent)
				local root = ReactTestRenderer.create(
					nil,
					{ unstable_isConcurrent = true }
				)
				root.update(React.createElement(Parent, { theme = "light" }))
				jestExpect(Scheduler).toFlushAndYield({
					"Parent: 0, 0 (light)",
					"Child: 0, 0 (light)",
				})
				jestExpect(root).toMatchRenderedOutput("0, 0 (light)")
				act(function()
					setCounter1(1)
					setCounter2(1)
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 1, 1 (light)",
					"Child: 1, 1 (light)",
				})
				act(function()
					return setCounter1(1)
				end)
				jestExpect(Scheduler).toHaveYielded({ "Parent: 1, 1 (light)" })
				act(function()
					setCounter1(1)
					setCounter2(2)
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 1, 2 (light)",
					"Child: 1, 2 (light)",
				})
				act(function()
					setCounter1(1)
					setCounter2(2)
					root.update(React.createElement(Parent, { theme = "dark" }))
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 1, 2 (dark)",
					"Child: 1, 2 (dark)",
				})
				act(function()
					setCounter1(1)
					setCounter2(2)
					root.update(React.createElement(Parent, { theme = "dark" }))
				end)
				jestExpect(Scheduler).toHaveYielded({ "Parent: 1, 2 (dark)" })
			end
		)
		it("warns about setState second argument", function()
			local useState = React.useState
			local setCounter
			local function Counter()
				local counter, _setCounter = useState(0)
				setCounter = _setCounter
				Scheduler.unstable_yieldValue(("Count: %s"):format(counter))
				return counter
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			root.update(React.createElement(Counter, nil))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(root).toMatchRenderedOutput("0")
			jestExpect(function()
				act(function()
					return setCounter(1, function()
						error(Error.new("Expected to ignore the callback."))
					end)
				end)
			end).toErrorDev(
				"State updates from the useState() and useReducer() Hooks "
					.. "don't support the second callback argument. "
					.. "To execute a side effect after rendering, "
					.. "declare it in the component body with useEffect().",
				{ withoutStack = true }
			)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(root).toMatchRenderedOutput("1")
		end)

		it("warns about dispatch second argument", function()
			local useReducer = React.useReducer
			local dispatch
			local function Counter()
				local counter, _dispatch = useReducer(function(s, a)
					return a
				end, 0)
				dispatch = _dispatch
				Scheduler.unstable_yieldValue(("Count: %s"):format(counter))
				return counter
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			root.update(React.createElement(Counter, nil))
			jestExpect(Scheduler).toFlushAndYield({ "Count: 0" })
			jestExpect(root).toMatchRenderedOutput("0")
			jestExpect(function()
				act(function()
					return dispatch(1, function()
						error(Error.new("Expected to ignore the callback."))
					end)
				end)
			end).toErrorDev(
				"State updates from the useState() and useReducer() Hooks "
					.. "don't support the second callback argument. "
					.. "To execute a side effect after rendering, "
					.. "declare it in the component body with useEffect().",
				{ withoutStack = true }
			)
			jestExpect(Scheduler).toHaveYielded({ "Count: 1" })
			jestExpect(root).toMatchRenderedOutput("1")
		end)
		it("never bails out if context has changed", function()
			local useState, useLayoutEffect, useContext =
				React.useState, React.useLayoutEffect, React.useContext
			local ThemeContext = React.createContext("light")
			local setTheme
			local function ThemeProvider(props)
				local children = props.children
				local theme, _setTheme = useState("light")
				Scheduler.unstable_yieldValue("Theme: " .. tostring(theme))
				setTheme = _setTheme
				return React.createElement(
					ThemeContext.Provider,
					{ value = theme },
					children
				)
			end
			local function Child(ref)
				local text = ref.text
				Scheduler.unstable_yieldValue("Child: " .. tostring(text))
				return text
			end
			local setCounter
			local function Parent()
				local counter, _setCounter = useState(0)
				setCounter = _setCounter
				local theme = useContext(ThemeContext)
				local text = ("%s (%s)"):format(counter, theme)
				Scheduler.unstable_yieldValue(("Parent: %s"):format(text))
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue(("Effect: %s"):format(text))
				end)
				return React.createElement(Child, { text = text })
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			act(function()
				root.update(
					React.createElement(
						ThemeProvider,
						nil,
						React.createElement(Parent, nil)
					)
				)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Theme: light",
				"Parent: 0 (light)",
				"Child: 0 (light)",
				"Effect: 0 (light)",
			})
			jestExpect(root).toMatchRenderedOutput("0 (light)")
			setTheme("light")
			jestExpect(Scheduler).toFlushAndYield({})
			jestExpect(root).toMatchRenderedOutput("0 (light)")
			act(function()
				return setCounter(1)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Parent: 1 (light)",
				"Child: 1 (light)",
				"Effect: 1 (light)",
			})
			jestExpect(root).toMatchRenderedOutput("1 (light)")
			act(function()
				return setCounter(1)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Parent: 1 (light)" })
			jestExpect(root).toMatchRenderedOutput("1 (light)")
			act(function()
				setCounter(1)
				setTheme("dark")
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Theme: dark",
				"Parent: 1 (dark)",
				"Child: 1 (dark)",
				"Effect: 1 (dark)",
			})
			jestExpect(root).toMatchRenderedOutput("1 (dark)")
		end)
		it(
			"can bail out without calling render phase (as an optimization) if queue is known to be empty",
			function()
				local useState, useLayoutEffect = React.useState, React.useLayoutEffect
				local function Child(ref)
					local text = ref.text
					Scheduler.unstable_yieldValue("Child: " .. tostring(text))
					return text
				end
				local setCounter
				local function Parent()
					local counter, _setCounter = useState(0)
					setCounter = _setCounter
					Scheduler.unstable_yieldValue("Parent: " .. tostring(counter))
					useLayoutEffect(function()
						Scheduler.unstable_yieldValue("Effect: " .. tostring(counter))
					end)
					return React.createElement(Child, { text = counter })
				end
				local root = ReactTestRenderer.create(
					nil,
					{ unstable_isConcurrent = true }
				)
				root.update(React.createElement(Parent, nil))
				jestExpect(Scheduler).toFlushAndYield({
					"Parent: 0",
					"Child: 0",
					"Effect: 0",
				})
				jestExpect(root).toMatchRenderedOutput("0")
				act(function()
					return setCounter(1)
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 1",
					"Child: 1",
					"Effect: 1",
				})
				jestExpect(root).toMatchRenderedOutput("1")
				act(function()
					return setCounter(1)
				end)
				jestExpect(Scheduler).toHaveYielded({ "Parent: 1" })
				jestExpect(root).toMatchRenderedOutput("1")
				act(function()
					return setCounter(1)
				end)
				jestExpect(Scheduler).toFlushAndYield({})
				jestExpect(root).toMatchRenderedOutput("1")
				act(function()
					return setCounter(2)
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 2",
					"Child: 2",
					"Effect: 2",
				})
				jestExpect(root).toMatchRenderedOutput("2")
				act(function()
					setCounter(0)
				end)
				jestExpect(Scheduler).toHaveYielded({
					"Parent: 0",
					"Child: 0",
					"Effect: 0",
				})
				jestExpect(root).toMatchRenderedOutput("0")
				act(function()
					setCounter(0)
				end)
				jestExpect(Scheduler).toHaveYielded({ "Parent: 0" })
				jestExpect(root).toMatchRenderedOutput("0")
				act(function()
					setCounter(0)
				end)
				jestExpect(Scheduler).toFlushAndYield({})
				jestExpect(root).toMatchRenderedOutput("0")
				act(function()
					setCounter(0 / -1)
				end)
				-- ROBLOX deviation: use Luau stringified versions of the math
				jestExpect(Scheduler).toHaveYielded({
					"Parent: -0",
					"Child: -0",
					"Effect: -0",
				})
				jestExpect(root).toMatchRenderedOutput("-0")
			end
		)
		it("bails out multiple times in a row without entering render phase", function()
			local useState = React.useState
			local function Child(ref)
				local text = ref.text
				Scheduler.unstable_yieldValue("Child: " .. tostring(text))
				return text
			end
			local setCounter
			local function Parent()
				local counter, _setCounter = useState(0)
				setCounter = _setCounter
				Scheduler.unstable_yieldValue("Parent: " .. tostring(counter))
				return React.createElement(Child, { text = counter })
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			root.update(React.createElement(Parent, nil))
			jestExpect(Scheduler).toFlushAndYield({ "Parent: 0", "Child: 0" })
			jestExpect(root).toMatchRenderedOutput("0")
			local function update(value)
				setCounter(function(previous)
					Scheduler.unstable_yieldValue(
						("Compute state (%s -> %s)"):format(previous, value)
					)
					return value
				end)
			end
			ReactTestRenderer.unstable_batchedUpdates(function()
				update(0)
				update(0)
				update(0)
				update(1)
				update(2)
				update(3)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Compute state (0 -> 0)",
				"Compute state (0 -> 0)",
				"Compute state (0 -> 0)",
				"Compute state (0 -> 1)",
			})
			jestExpect(Scheduler).toFlushAndYield({
				"Compute state (1 -> 2)",
				"Compute state (2 -> 3)",
				"Parent: 3",
				"Child: 3",
			})
			jestExpect(root).toMatchRenderedOutput("3")
		end)
		it("can rebase on top of a previously skipped update", function()
			local useState = React.useState
			local function Child(ref)
				local text = ref.text
				Scheduler.unstable_yieldValue("Child: " .. tostring(text))
				return text
			end
			local setCounter
			local function Parent()
				local counter, _setCounter = useState(1)
				setCounter = _setCounter
				Scheduler.unstable_yieldValue("Parent: " .. tostring(counter))
				return React.createElement(Child, { text = counter })
			end
			local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })
			root.update(React.createElement(Parent, nil))
			jestExpect(Scheduler).toFlushAndYield({ "Parent: 1", "Child: 1" })
			jestExpect(root).toMatchRenderedOutput("1")
			local function update(compute)
				setCounter(function(previous)
					local value = compute(previous)
					Scheduler.unstable_yieldValue(
						("Compute state (%s -> %s)"):format(previous, value)
					)
					return value
				end)
			end
			ReactTestRenderer.unstable_batchedUpdates(function()
				return update(function(n)
					return n * 100
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({ "Compute state (1 -> 100)" })
			root.unstable_flushSync(function()
				update(function(n)
					return n + 5
				end)
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Compute state (1 -> 6)",
				"Parent: 6",
				"Child: 6",
			})
			jestExpect(root).toMatchRenderedOutput("6")
			jestExpect(Scheduler).toFlushAndYield({
				"Compute state (100 -> 105)",
				"Parent: 105",
				"Child: 105",
			})
			jestExpect(root).toMatchRenderedOutput("105")
		end)
		it("warns about variable number of dependencies", function()
			local useLayoutEffect = React.useLayoutEffect
			local function App(props)
				useLayoutEffect(function()
					Scheduler.unstable_yieldValue(
						"Did commit: " .. tostring(Array.join(props.dependencies, ", "))
					)
				end, props.dependencies)
				return props.dependencies
			end
			local root = ReactTestRenderer.create(
				React.createElement(App, { dependencies = { "A" } })
			)
			jestExpect(Scheduler).toHaveYielded({ "Did commit: A" })
			jestExpect(function()
				root.update(React.createElement(App, { dependencies = { "A", "B" } }))
			end).toErrorDev({
				"Warning: The final argument passed to useLayoutEffect changed size "
					.. "between renders. The order and size of this array must remain "
					.. "constant.\n\n"
					.. "Previous: [\"A\"]\n"
					.. "Incoming: [\"A\", \"B\"]\n",
			})
		end)
		it("warns if switching from dependencies to no dependencies", function()
			local useMemo = React.useMemo
			local function App(ref)
				local text, hasDeps = ref.text, ref.hasDeps
				local resolvedText = useMemo(
					function()
						Scheduler.unstable_yieldValue("Compute")
						-- ROBLOX TODO: add String.toUpperCase to polyfill
						return string.upper(text)
					end,
					(function()
						if hasDeps then
							return nil
						else
							return { text }
						end
					end)()
				)
				return resolvedText
			end
			local root = ReactTestRenderer.create(nil)
			root.update(React.createElement(App, { text = "Hello", hasDeps = true }))
			jestExpect(Scheduler).toHaveYielded({ "Compute" })
			jestExpect(root).toMatchRenderedOutput("HELLO")
			jestExpect(function()
				root.update(React.createElement(App, { text = "Hello", hasDeps = false }))
			end).toErrorDev({
				"Warning: useMemo received a final argument during this render, but "
					.. "not during the previous render. Even though the final argument is "
					.. "optional, its type cannot change between renders.",
			})
		end)
		it("warns if deps is not an array", function()
			local useEffect, useLayoutEffect, useMemo, useCallback =
				React.useEffect, React.useLayoutEffect, React.useMemo, React.useCallback
			local function App(props)
				useEffect(function() end, props.deps)
				useLayoutEffect(function() end, props.deps)
				useMemo(function() end, props.deps)
				useCallback(function() end, props.deps)
				return nil
			end
			jestExpect(function()
				act(function()
					ReactTestRenderer.create(React.createElement(App, { deps = "hello" }))
				end)
			end).toErrorDev({
				"Warning: useEffect received a final argument that is not an array (instead, received `string`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useLayoutEffect received a final argument that is not an array (instead, received `string`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useMemo received a final argument that is not an array (instead, received `string`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useCallback received a final argument that is not an array (instead, received `string`). "
					.. "When specified, the final argument must be an array.",
			})
			jestExpect(function()
				act(function()
					ReactTestRenderer.create(React.createElement(App, { deps = 100500 }))
				end)
			end).toErrorDev({
				"Warning: useEffect received a final argument that is not an array (instead, received `number`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useLayoutEffect received a final argument that is not an array (instead, received `number`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useMemo received a final argument that is not an array (instead, received `number`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useCallback received a final argument that is not an array (instead, received `number`). "
					.. "When specified, the final argument must be an array.",
			})
			jestExpect(function()
				act(function()
					-- ROBLOX deviation: empty table isn't distinguishable from an array
					ReactTestRenderer.create(
						React.createElement(App, { deps = { notempty = true } })
					)
				end)
			end).toErrorDev({
				-- ROBLOX deviation: table type instead of object
				"Warning: useEffect received a final argument that is not an array (instead, received `table`). " .. "When specified, the final argument must be an array.",
				"Warning: useLayoutEffect received a final argument that is not an array (instead, received `table`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useMemo received a final argument that is not an array (instead, received `table`). "
					.. "When specified, the final argument must be an array.",
				"Warning: useCallback received a final argument that is not an array (instead, received `table`). "
					.. "When specified, the final argument must be an array.",
			})
			act(function()
				ReactTestRenderer.create(React.createElement(App, { deps = {} }))
				ReactTestRenderer.create(React.createElement(App, { deps = nil }))
				ReactTestRenderer.create(React.createElement(App, { deps = nil }))
			end)
		end)
		-- ROBLOX FIXME: doesn't seem to get the string "hello"
		it("warns if deps is not an array for useImperativeHandle", function()
			local useImperativeHandle = React.useImperativeHandle
			local App = React.forwardRef(function(props, ref)
				useImperativeHandle(ref, function() end, props.deps)
				return nil
			end)
			jestExpect(function()
				ReactTestRenderer.create(React.createElement(App, { deps = "hello" }))
			end).toErrorDev({
				"Warning: useImperativeHandle received a final argument that is not an array (instead, received `string`). "
					.. "When specified, the final argument must be an array.",
			}, { withoutStack = true }) -- ROBLOX FIXME: upstream doesn't need withoutStack = true
			ReactTestRenderer.create(React.createElement(App, { deps = {} }))
			ReactTestRenderer.create(React.createElement(App, { deps = nil }))
			ReactTestRenderer.create(React.createElement(App, { deps = nil }))
		end)
		it("does not forget render phase useState updates inside an effect", function()
			local useState, useEffect = React.useState, React.useEffect
			local function Counter()
				local counter, setCounter = useState(0)
				if counter == 0 then
					setCounter(function(x)
						return x + 1
					end)
					setCounter(function(x)
						return x + 1
					end)
				end
				useEffect(function()
					setCounter(function(x)
						return x + 1
					end)
					setCounter(function(x)
						return x + 1
					end)
				end, {})
				return counter
			end
			local root = ReactTestRenderer.create(nil)
			act(function()
				root.update(React.createElement(Counter, nil))
			end)
			jestExpect(root).toMatchRenderedOutput("4")
		end)
		it(
			"does not forget render phase useReducer updates inside an effect with hoisted reducer",
			function()
				local useReducer, useEffect = React.useReducer, React.useEffect
				local function reducer(x)
					return x + 1
				end
				local function Counter()
					local counter, increment = useReducer(reducer, 0)
					if counter == 0 then
						increment()
						increment()
					end
					useEffect(function()
						increment()
						increment()
					end, {})
					return counter
				end
				local root = ReactTestRenderer.create(nil)
				act(function()
					root.update(React.createElement(Counter, nil))
				end)
				jestExpect(root).toMatchRenderedOutput("4")
			end
		)
		it(
			"does not forget render phase useReducer updates inside an effect with inline reducer",
			function()
				local useReducer, useEffect = React.useReducer, React.useEffect
				local function Counter()
					local counter, increment = useReducer(function(x)
						return x + 1
					end, 0)
					if counter == 0 then
						increment()
						increment()
					end
					useEffect(function()
						increment()
						increment()
					end, {})
					return counter
				end
				local root = ReactTestRenderer.create(nil)
				act(function()
					root.update(React.createElement(Counter, nil))
				end)
				jestExpect(root).toMatchRenderedOutput("4")
			end
		)
		it("warns for bad useImperativeHandle first arg", function()
			local useImperativeHandle = React.useImperativeHandle
			local function App()
				useImperativeHandle({ focus = function(self) end })
				return nil
			end
			jestExpect(function()
				jestExpect(function()
					ReactTestRenderer.create(React.createElement(App, nil))
					-- ROBLOX deviation: Lua has different error when trying to call a nil
				end).toThrow("attempt to call a nil value")
			end).toErrorDev({
				"Expected useImperativeHandle() first argument to either be a "
					.. "ref callback or React.createRef() object. "
					.. "Instead received: an object with keys {focus}.",
				"Warning: Expected useImperativeHandle() second argument to be a function "
					-- ROBLOX deviation: nil instead of undefined
					.. "that creates a handle. Instead received: nil.",
			})
		end)
		it("warns for bad useImperativeHandle second arg", function()
			local useImperativeHandle = React.useImperativeHandle
			local App = React.forwardRef(function(props, ref)
				useImperativeHandle(ref, { focus = function(self) end })
				return nil
			end)
			jestExpect(function()
				ReactTestRenderer.create(React.createElement(App, nil))
			end).toErrorDev({
				-- ROBLOX deviation: Lua says `table` instead of `object`
				"Expected useImperativeHandle() second argument to be a function " .. "that creates a handle. Instead received: table.",
				-- ROBLOX FIXME? we seem to require withoutStack=true, but upstream doesn't
			}, { withoutStack = true })
		end)
		-- 	it("works with ReactDOMServer calls inside a component", function()
		-- 		local useState = React.useState
		-- 		local function App(props)
		-- 			local markup1 = ReactDOMServer:renderToString(
		-- 				React.createElement("p", nil, "hello")
		-- 			)
		-- 			local markup2 = ReactDOMServer:renderToStaticMarkup(
		-- 				React.createElement("p", nil, "bye")
		-- 			)
		-- 			local counter = useState(0)
		-- 			return markup1 + counter + markup2
		-- 		end
		-- 		local root = ReactTestRenderer.create(React.createElement(App, nil))
		-- 		jestExpect(root.toJSON()).toMatchSnapshot()
		-- 	end)
		it("throws when calling hooks inside .memo's compare function", function()
			local useState = React.useState
			local function App()
				useState(0)
				return nil
			end
			local MemoApp = React.memo(App, function()
				useState(0)
				return false
			end)
			local root = ReactTestRenderer.create(React.createElement(MemoApp, nil))
			jestExpect(function()
				return root.update(React.createElement(MemoApp, nil))
			end).toThrow(
				"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
					.. " one of the following reasons:\n"
					.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
					.. "2. You might be breaking the Rules of Hooks\n"
					.. "3. You might have more than one copy of React in the same app\n"
					.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
			)
			jestExpect(function()
				return root.update(React.createElement(MemoApp, nil))
			end).never.toThrow(
				"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
					.. " one of the following reasons:\n"
					.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
					.. "2. You might be breaking the Rules of Hooks\n"
					.. "3. You might have more than one copy of React in the same app\n"
					.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
			)
			jestExpect(function()
				return root.update(React.createElement(MemoApp, nil))
			end).toThrow(
				"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen for"
					.. " one of the following reasons:\n"
					.. "1. You might have mismatching versions of React and the renderer (such as React DOM)\n"
					.. "2. You might be breaking the Rules of Hooks\n"
					.. "3. You might have more than one copy of React in the same app\n"
					.. "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
			)
		end)
		it("warns when calling hooks inside useMemo", function()
			local useMemo, useState = React.useMemo, React.useState
			local function App()
				useMemo(function()
					useState(0)
				end)
				return nil
			end
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(App, nil))
			end).toErrorDev(
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks."
			)
		end)
		it("warns when reading context inside useMemo", function()
			local useMemo, createContext = React.useMemo, React.createContext
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local ThemeContext = createContext("light")
			local function App()
				return useMemo(function()
					return ReactCurrentDispatcher.current:readContext(ThemeContext)
				end, {})
			end
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(App, nil))
			end).toErrorDev("Context can only be read while React is rendering")
		end)
		it(
			"warns when reading context inside useMemo after reading outside it",
			function()
				local useMemo, createContext = React.useMemo, React.createContext
				local ReactCurrentDispatcher =
					React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
				local ThemeContext = createContext("light")
				local firstRead, secondRead
				local function App()
					firstRead = ReactCurrentDispatcher.current.readContext(ThemeContext)
					useMemo(function() end)
					secondRead = ReactCurrentDispatcher.current.readContext(ThemeContext)
					return useMemo(function()
						return ReactCurrentDispatcher.current.readContext(ThemeContext)
					end, {})
				end
				jestExpect(function()
					return ReactTestRenderer.create(React.createElement(App, nil))
				end).toErrorDev("Context can only be read while React is rendering")
				jestExpect(firstRead).toBe("light")
				jestExpect(secondRead).toBe("light")
			end
		)
		-- ROBLOX FIXME: throw happens in ReactFiberHooks, but error doesn't propagate
		xit("throws when reading context inside useEffect", function()
			local useEffect, createContext = React.useEffect, React.createContext
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local ThemeContext = createContext("light")
			local function App()
				useEffect(function()
					ReactCurrentDispatcher.current.readContext(ThemeContext)
				end)
				return nil
			end
			jestExpect(function()
				act(function()
					ReactTestRenderer.create(React.createElement(App, nil))
				end)
			end).toThrow("Context can only be read while React is rendering")
		end)
		it("throws when reading context inside useLayoutEffect", function()
			local useLayoutEffect, createContext =
				React.useLayoutEffect, React.createContext
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local ThemeContext = createContext("light")
			local function App()
				useLayoutEffect(function()
					ReactCurrentDispatcher.current:readContext(ThemeContext)
				end)
				return nil
			end
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(App, nil))
			end).toThrow("Context can only be read while React is rendering")
		end)
		it("warns when reading context inside useReducer", function()
			local useReducer, createContext = React.useReducer, React.createContext
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local ThemeContext = createContext("light")
			local function App()
				local state, dispatch = useReducer(function(s, action)
					ReactCurrentDispatcher.current:readContext(ThemeContext)
					return action
				end, 0)
				if state == 0 then
					dispatch(1)
				end
				return nil
			end
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(App, nil))
			end).toErrorDev({ "Context can only be read while React is rendering" })
		end)
		it("warns when reading context inside eager useReducer", function()
			local useState, createContext = React.useState, React.createContext
			local ThemeContext = createContext("light")
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local _setState
			local function Fn()
				local _, setState = useState(0)
				_setState = setState
				return nil
			end
			local Cls = React.Component:extend("Cls")
			function Cls:render()
				_setState(function()
					return ReactCurrentDispatcher.current:readContext(ThemeContext)
				end)
				return nil
			end
			jestExpect(function()
				return ReactTestRenderer.create(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(Fn, nil),
						React.createElement(Cls, nil)
					)
				)
			end).toErrorDev({
				"Context can only be read while React is rendering",
				"Cannot update a component (`Fn`) while rendering a different component (`Cls`).",
			})
		end)
		it("warns when calling hooks inside useReducer", function()
			local useReducer, useState, useRef =
				React.useReducer, React.useState, React.useRef
			local function App()
				local value, dispatch = useReducer(function(state, action)
					useRef(0)
					return state + 1
				end, 0)
				if value == 0 then
					dispatch("foo")
				end
				useState()
				return value
			end
			jestExpect(function()
				jestExpect(function()
					ReactTestRenderer.create(React.createElement(App, nil))
				end).toThrow("Rendered more hooks than during the previous render.")
			end).toErrorDev({
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
				"Warning: React has detected a change in the order of Hooks called by App. "
					.. "This will lead to bugs and errors if not fixed. For more information, "
					.. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
					.. "   Previous render            Next render\n"
					.. "   ------------------------------------------------------\n"
					.. "1. useReducer                 useReducer\n"
					.. "2. useState                   useRef\n"
					.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n",
			})
		end)
		it("warns when calling hooks inside useState's initialize function", function()
			local useState, useRef = React.useState, React.useRef
			local function App()
				useState(function()
					useRef(0)
					return 0
				end)
				return nil
			end
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(App, nil))
			end).toErrorDev(
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks."
			)
		end)
		it("resets warning internal state when interrupted by an error", function()
			local ReactCurrentDispatcher =
				React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher
			local ThemeContext = React.createContext("light")
			local function App()
				React.useMemo(function()
					ReactCurrentDispatcher.current:readContext(ThemeContext)
					React.useRef()
					error(Error.new("No."))
				end, {})
			end
			type Boundary = { state: any, render: any } --[[ ROBLOX TODO: replace 'any' type/ add missing ]]
			local Boundary = React.Component:extend("Boundary")
			function Boundary.getDerivedStateFromError(error_)
				return { err = true }
			end
			function Boundary:render()
				if self.state.err then
					return "Oops"
				end
				return self.props.children
			end
			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(Boundary, nil, React.createElement(App, nil))
				)
			end).toErrorDev({
				"Context can only be read while React is rendering",
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
				"Context can only be read while React is rendering",
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
			})
			local function Valid()
				React.useState()
				React.useMemo(function() end)
				React.useReducer(function() end)
				React.useEffect(function() end)
				React.useLayoutEffect(function() end)
				React.useCallback(function() end)
				React.useRef()
				React.useImperativeHandle(function() end, function() end)
				if _G.__DEV__ then
					React.useDebugValue()
				end
				return nil
			end
			act(function()
				ReactTestRenderer.create(React.createElement(Valid, nil))
			end)
			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(Boundary, nil, React.createElement(App, nil))
				)
			end).toErrorDev({
				"Context can only be read while React is rendering",
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
				"Context can only be read while React is rendering",
				"Do not call Hooks inside useEffect(...), useMemo(...), or other built-in Hooks",
			})
		end)
		-- ROBLOX deviation: upstream has 2 tests with same name, which TestEZ doesn't allow
		it("double-invokes components with Hooks in Strict Mode", function()
			ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = true
			local useState, StrictMode = React.useState, React.StrictMode
			local renderCount = 0
			local function NoHooks()
				renderCount += 1
				return React.createElement("div", nil)
			end
			local function HasHooks()
				useState(0)
				renderCount += 1
				return React.createElement("div", nil)
			end
			local FwdRef = React.forwardRef(function(props, ref)
				renderCount += 1
				return React.createElement("div", nil)
			end)
			local FwdRefHasHooks = React.forwardRef(function(props, ref)
				useState(0)
				renderCount += 1
				return React.createElement("div", nil)
			end)
			local Memo = React.memo(function(props)
				renderCount += 1
				return React.createElement("div", nil)
			end)
			local MemoHasHooks = React.memo(function(props)
				useState(0)
				renderCount += 1
				return React.createElement("div", nil)
			end)
			local function Factory()
				return {
					state = {},
					render = function(self)
						renderCount += 1
						return React.createElement("div", nil)
					end,
				}
			end
			local renderer = ReactTestRenderer.create(nil)
			renderCount = 0
			renderer.update(React.createElement(NoHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(NoHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(NoHooks, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(NoHooks, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(React.createElement(FwdRef, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(FwdRef, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(FwdRef, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(FwdRef, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(React.createElement(Memo, { arg = 1 }))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(Memo, { arg = 2 }))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(Memo, { arg = 1 })
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(Memo, { arg = 2 })
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			if not ReactFeatureFlags.disableModulePatternComponents then
				renderCount = 0
				jestExpect(function()
					return renderer.update(React.createElement(Factory, nil))
				end).toErrorDev(
					"Warning: The <Factory /> component appears to be a function component that returns a class instance. "
						.. "Change Factory to a class that extends React.Component instead. "
					-- ROBLOX deviation: we exclude this JS specific advice
					-- .. "If you can't use a class try assigning the prototype on the function as a workaround. "
					-- .. "`Factory.prototype = React.Component.prototype`. "
					-- .. "Don't use an arrow function since it cannot be called with `new` by React."
				)
				jestExpect(renderCount).toBe(1)
				renderCount = 0
				renderer.update(React.createElement(Factory, nil))
				jestExpect(renderCount).toBe(1)
				renderCount = 0
				renderer.update(
					React.createElement(
						StrictMode,
						nil,
						React.createElement(Factory, nil)
					)
				)
				jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
				renderCount = 0
				renderer.update(
					React.createElement(
						StrictMode,
						nil,
						React.createElement(Factory, nil)
					)
				)
				jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			end
			renderCount = 0
			renderer.update(React.createElement(HasHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(HasHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(HasHooks, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(StrictMode, nil, React.createElement(HasHooks, nil))
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(React.createElement(FwdRefHasHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(FwdRefHasHooks, nil))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(FwdRefHasHooks, nil)
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(FwdRefHasHooks, nil)
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(React.createElement(MemoHasHooks, { arg = 1 }))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(React.createElement(MemoHasHooks, { arg = 2 }))
			jestExpect(renderCount).toBe(1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(MemoHasHooks, { arg = 1 })
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			renderCount = 0
			renderer.update(
				React.createElement(
					StrictMode,
					nil,
					React.createElement(MemoHasHooks, { arg = 2 })
				)
			)
			jestExpect(renderCount).toBe(_G.__DEV__ and 2 or 1)
			ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false
		end)
		it("double-invokes useMemo in DEV StrictMode despite []", function()
			ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = true
			local useMemo, StrictMode = React.useMemo, React.StrictMode
			local useMemoCount = 0
			local function BadUseMemo()
				useMemo(function()
					(function()
						local result = useMemoCount
						useMemoCount += 1
						return result
					end)()
				end, {})
				return React.createElement("div", nil)
			end
			useMemoCount = 0
			ReactTestRenderer.create(
				React.createElement(StrictMode, nil, React.createElement(BadUseMemo, nil))
			)
			jestExpect(useMemoCount).toBe(_G.__DEV__ and 2 or 1)
			ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false
		end)
		describe("hook ordering", function()
			local function useCallbackHelper()
				return React.useCallback(function() end, {})
			end
			local function useContextHelper()
				return React.useContext(React.createContext())
			end
			local function useDebugValueHelper()
				return React.useDebugValue("abc")
			end
			local function useEffectHelper()
				return React.useEffect(function()
					return function() end
				end, {})
			end
			local function useImperativeHandleHelper()
				React.useImperativeHandle({ current = nil }, function()
					return {}
				end, {})
			end
			local function useLayoutEffectHelper()
				return React.useLayoutEffect(function()
					return function() end
				end, {})
			end
			local function useMemoHelper()
				return React.useMemo(function()
					return 123
				end, {})
			end
			local function useReducerHelper()
				return React.useReducer(function(s, a)
					return a
				end, 0)
			end
			local function useRefHelper()
				return React.useRef(nil)
			end
			local function useStateHelper()
				return React.useState(0)
			end
			local orderedHooks = {
				useCallbackHelper,
				useContextHelper,
				useDebugValueHelper,
				useEffectHelper,
				useLayoutEffectHelper,
				useMemoHelper,
				useReducerHelper,
				useRefHelper,
				useStateHelper,
			}
			local hooksInList = {
				useCallbackHelper,
				useEffectHelper,
				useImperativeHandleHelper,
				useLayoutEffectHelper,
				useMemoHelper,
				useReducerHelper,
				useRefHelper,
				useStateHelper,
			}
			-- ROBLOX TODO: unflag this when we implement useTransition and useDeferredValueHelper
			if _G.__EXPERIMENTAL__ then
				local function useTransitionHelper()
					return React.useTransition()
				end
				local function useDeferredValueHelper()
					return React.useDeferredValue(0, { timeoutMs = 1000 })
				end
				Array.push(orderedHooks, useTransitionHelper)
				Array.push(orderedHooks, useDeferredValueHelper)
				Array.push(hooksInList, useTransitionHelper)
				Array.push(hooksInList, useDeferredValueHelper)
			end
			local function formatHookNamesToMatchErrorMessage(hookNameA, hookNameB)
				return ("use%s%s%s"):format(
					hookNameA,
					string.rep(" ", 24 - string.len(hookNameA)),
					(function()
						if hookNameB then
							return ("use%s"):format(hookNameB)
						else
							return nil
						end
					end)()
				)
			end
			Array.forEach(orderedHooks, function(firstHelper, index)
				local secondHelper = (function()
					if
						index
						> 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
					then
						return orderedHooks[index]
					else
						return orderedHooks[#orderedHooks]
					end
				end)()
				-- ROBLOX deviation: functions can't have fields in Lua
				-- local hookNameA = firstHelper.name
				local hookNameA = debug.info(firstHelper, "n")
					:gsub("use", "")
					:gsub("Helper", "")
				-- ROBLOX deviation: functions can't have fields in Lua
				-- local hookNameB = secondHelper.name
				local hookNameB = debug.info(secondHelper, "n")
					:gsub("use", "")
					:gsub("Helper", "")
				-- ROBLOX FIXME: gives error about fewer hooks than expected instead
				xit(
					(
						"warns on using differently ordered hooks (%s, %s) on subsequent renders"
					):format(hookNameA, hookNameB),
					function()
						local function App(props)
							if props.update then
								secondHelper()
								firstHelper()
							else
								firstHelper()
								secondHelper()
							end
							useRefHelper()
							return nil
						end
						local root
						act (function()
							root = ReactTestRenderer.create(
								React.createElement(App, { update = false })
							)
						end)
						jestExpect(function()
							xpcall(function()
								act(function()
									root.update(
										React.createElement(App, { update = true })
									)
								end)
							end, function(error_) end)
						end).toErrorDev({
							"Warning: React has detected a change in the order of Hooks called by App. "
								.. "This will lead to bugs and errors if not fixed. For more information, "
								.. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
								.. "   Previous render            Next render\n"
								.. "   ------------------------------------------------------\n"
								.. ("1. %s\n"):format(
									formatHookNamesToMatchErrorMessage(
										hookNameA,
										hookNameB
									)
								)
								.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n"
								.. "    in App (at **)",
						})
						xpcall(function()
							act(function()
								root.update(React.createElement(App, { update = false }))
							end)
						end, function(error_) end)
					end
				)
				it(
					("warns when more hooks (%s, %s) are used during update than mount"):format(
						hookNameA,
						hookNameB
					),
					function()
						local function App(props)
							if props.update then
								firstHelper()
								secondHelper()
							else
								firstHelper()
							end
							return nil
						end
						local root
						act(function()
							root = ReactTestRenderer.create(
								React.createElement(App, { update = false })
							)
						end)
						jestExpect(function()
							xpcall(function()
								act(function()
									root.update(
										React.createElement(App, { update = true })
									)
								end)
							end, function(error_) end)
						end).toErrorDev({
							"Warning: React has detected a change in the order of Hooks called by App. "
								.. "This will lead to bugs and errors if not fixed. For more information, "
								.. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
								.. "   Previous render            Next render\n"
								.. "   ------------------------------------------------------\n"
								.. ("1. %s\n"):format(
									formatHookNamesToMatchErrorMessage(
										hookNameA,
										hookNameA
									)
								)
								.. (
									"2. undefined                  use%s\n"
								):format(hookNameB)
								.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n"
								.. "    in App (at **)",
						})
					end
				)
			end)
			Array.forEach(hooksInList, function(firstHelper, index)
				local secondHelper = (function()
					if
						index
						> 0 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
					then
						return hooksInList[index]
					else
						return hooksInList[#hooksInList]
					end
				end)()
				-- ROBLOX deviation: functions can't have fields in Lua
				-- local hookNameA = firstHelper.name
				local hookNameA = debug.info(firstHelper, "n")
					:gsub("use", "")
					:gsub("Helper", "")
				-- ROBLOX deviation: functions can't have fields in Lua
				-- local hookNameB = secondHelper.name
				local hookNameB = debug.info(secondHelper, "n")
					:gsub("use", "")
					:gsub("Helper", "")
				-- ROBLOX FIXME: it is throwing the error, but toThrowError isn't unpacking the Error object?
				xit(
					("warns when fewer hooks (%s, %s) are used during update than mount"):format(
						hookNameA,
						hookNameB
					),
					function()
						local function App(props)
							if props.update then
								firstHelper()
							else
								firstHelper()
								secondHelper()
							end
							return nil
						end
						local root
						act(function()
							root = ReactTestRenderer.create(
								React.createElement(App, { update = false })
							)
						end)
						jestExpect(function()
							act(function()
								root.update(React.createElement(App, { update = true }))
							end)
						end).toThrow("Rendered fewer hooks than expected.")
					end
				)
			end)
			-- ROBLOX FIXME: gives fewer hooks rendered error instead
			xit(
				"warns on using differently ordered hooks "
					.. "(useImperativeHandleHelper, useMemoHelper) on subsequent renders",
				function()
					local function App(props)
						if props.update then
							useMemoHelper()
							useImperativeHandleHelper()
						else
							useImperativeHandleHelper()
							useMemoHelper()
						end
						useRefHelper()
						return nil
					end
					local root = ReactTestRenderer.create(
						React.createElement(App, { update = false })
					)
					jestExpect(function()
						xpcall(function()
							root.update(React.createElement(App, { update = true }))
						end, function(error_) end)
					end).toErrorDev({
						-- ROBLOX deviation: we put 'Warning' on the front of this for some reason
						"Warning: React has detected a change in the order of Hooks called by App. "
							.. "This will lead to bugs and errors if not fixed. For more information, "
							.. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
							.. "   Previous render            Next render\n"
							.. "   ------------------------------------------------------\n"
							.. ("1. %s\n"):format(
								formatHookNamesToMatchErrorMessage(
									"ImperativeHandle",
									"Memo"
								)
							)
							.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n"
							.. "    in App (at **)",
					})
					root.update(React.createElement(App, { update = false }))
				end
			)
			it("detects a bad hook order even if the component throws", function()
				local useState, useReducer = React.useState, React.useReducer
				local function useCustomHook()
					useState(0)
				end
				local function App(props)
					if props.update then
						useCustomHook()
						useReducer(function(s, a)
							return a
						end, 0)
						error(Error.new("custom error"))
					else
						useReducer(function(s, a)
							return a
						end, 0)
						useCustomHook()
					end
					return nil
				end
				local root = ReactTestRenderer.create(
					React.createElement(App, { update = false })
				)
				jestExpect(function()
					jestExpect(function()
						return root.update(React.createElement(App, { update = true }))
					end).toThrow("custom error")
				end).toErrorDev({
					"Warning: React has detected a change in the order of Hooks called by App. "
						.. "This will lead to bugs and errors if not fixed. For more information, "
						.. "read the Rules of Hooks: https://reactjs.org/link/rules-of-hooks\n\n"
						.. "   Previous render            Next render\n"
						.. "   ------------------------------------------------------\n"
						.. "1. useReducer                 useState\n"
						.. "   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n",
				})
			end)
		end)
		it(
			"does not swallow original error when updating another component in render phase",
			function()
				local useState = React.useState
				local _setState
				local function A()
					local _, setState = useState(0)
					_setState = setState
					return nil
				end
				local function B()
					_setState(function()
						error(Error.new("Hello"))
					end)
					return nil
				end
				jestExpect(function()
					act(function()
						ReactTestRenderer.unstable_batchedUpdates(function()
							ReactTestRenderer.create(
								React.createElement(
									React.Fragment,
									nil,
									React.createElement(A, nil),
									React.createElement(B, nil)
								)
							)
							jestExpect(function()
								Scheduler.unstable_flushAll()
							end).toThrow("Hello")
						end)
					end)
					-- ROBLOX deviation: use toErrorDev instead of spyOn(console, 'error')
				end).toErrorDev(
					"Warning: Cannot update a component (`A`) while rendering "
						.. "a different component (`B`)."
				)
			end
		)
		it(
			"does not fire a false positive warning when previous effect unmounts the component",
			function()
				local A, B, C
				local useState, useEffect = React.useState, React.useEffect
				local globalListener
				function A()
					local show, setShow = useState(true)
					local function hideMe()
						setShow(false)
					end
					return (function()
						if show then
							return React.createElement(B, { hideMe = hideMe })
						else
							return nil
						end
					end)()
				end
				function B(props)
					return React.createElement(C, props)
				end
				function C(ref)
					local hideMe = ref.hideMe
					local _, setState = useState()
					useEffect(function()
						local isStale = false
						globalListener = function()
							if not isStale then
								setState("hello")
							end
						end
						return function()
							isStale = true
							hideMe()
						end
					end)
					return nil
				end
				act(function()
					ReactTestRenderer.create(React.createElement(A, nil))
				end)
				jestExpect(function()
					globalListener()
					globalListener()
				end).toErrorDev({
					"An update to C inside a test was not wrapped in act",
					"An update to C inside a test was not wrapped in act",
				})
			end
		)
		it("does not fire a false positive warning when suspending memo", function()
			local Suspense, useState = React.Suspense, React.useState
			local wasSuspended = false
			local function trySuspend()
				if not wasSuspended then
					error(Promise.delay(0):andThen(function(resolve)
						wasSuspended = true
						resolve()
					end))
				end
			end
			local function Child()
				useState()
				trySuspend()
				return "hello"
			end
			local Wrapper = React.memo(Child)
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = "loading" },
					React.createElement(Wrapper, nil)
				)
			)
			jestExpect(root).toMatchRenderedOutput("loading")
			Promise.delay(0):await()
			Scheduler.unstable_flushAll()
			jestExpect(root).toMatchRenderedOutput("hello")
		end)
		it("does not fire a false positive warning when suspending forwardRef", function()
			local Suspense, useState = React.Suspense, React.useState
			local wasSuspended = false
			local function trySuspend()
				if not wasSuspended then
					error(Promise.delay(0):andThen(function(resolve)
						wasSuspended = true
						resolve()
					end))
				end
			end
			local function render(props, ref)
				useState()
				trySuspend()
				return "hello"
			end
			local Wrapper = React.forwardRef(render)
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = "loading" },
					React.createElement(Wrapper, nil)
				)
			)
			jestExpect(root).toMatchRenderedOutput("loading")
			Promise.delay(0):await()
			Scheduler.unstable_flushAll()
			jestExpect(root).toMatchRenderedOutput("hello")
		end)
		it(
			"does not fire a false positive warning when suspending memo(forwardRef)",
			function()
				local Suspense, useState = React.Suspense, React.useState
				local wasSuspended = false
				local function trySuspend()
					if not wasSuspended then
						error(Promise.delay(0):andThen(function(resolve)
							wasSuspended = true
							resolve()
						end))
					end
				end
				local function render(props, ref)
					useState()
					trySuspend()
					return "hello"
				end
				local Wrapper = React.memo(React.forwardRef(render))
				local root = ReactTestRenderer.create(
					React.createElement(
						Suspense,
						{ fallback = "loading" },
						React.createElement(Wrapper, nil)
					)
				)
				jestExpect(root).toMatchRenderedOutput("loading")
				Promise.delay(0):await()
				Scheduler.unstable_flushAll()
				jestExpect(root).toMatchRenderedOutput("hello")
			end
		)
		it(
			"resets hooks when an error is thrown in the middle of a list of hooks",
			function()
				local useEffect, useState = React.useEffect, React.useState
				-- ROBLOX deviation: hoist
				local function Wrapper(props)
					local children = props.children
					return children
				end
				local ErrorBoundary = React.Component:extend("ErrorBoundary")
				function ErrorBoundary.getDerivedStateFromError()
					return { hasError = true }
				end
				function ErrorBoundary:render()
					return React.createElement(
						Wrapper,
						nil,
						self.state.hasError and "Error!" or self.props.children
					)
				end
				local setShouldThrow
				local function Thrower()
					local shouldThrow, _setShouldThrow = useState(false)
					setShouldThrow = _setShouldThrow
					if shouldThrow then
						error(Error.new("Throw!"))
					end
					useEffect(function() end, {})
					return "Throw!"
				end
				local root
				act(function()
					root = ReactTestRenderer.create(
						React.createElement(
							ErrorBoundary,
							nil,
							React.createElement(Thrower, nil)
						)
					)
				end)
				jestExpect(root).toMatchRenderedOutput("Throw!")
				act(function()
					return setShouldThrow(true)
				end)
				jestExpect(root).toMatchRenderedOutput("Error!")
			end
		)
	end)
end
