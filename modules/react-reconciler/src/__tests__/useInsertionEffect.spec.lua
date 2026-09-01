--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L2691-L3093
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
local Promise = require(Packages.Promise)
local React
local ReactNoop
local Scheduler
local act
local LegacyHidden
local useEffect
local useInsertionEffect
local useLayoutEffect
local useMemo

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()

	React = require(Packages.React)
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	Scheduler = require(Packages.Scheduler)

	act = ReactNoop.act
	LegacyHidden = React.unstable_LegacyHidden
	useEffect = React.useEffect
	useInsertionEffect = React.useInsertionEffect
	useLayoutEffect = React.useLayoutEffect
	useMemo = React.useMemo
end)

local function span(prop, hidden)
	return React.createElement(
		"span",
		if hidden == true then { prop = prop, hidden = true } else { prop = prop }
	)
end

local function Text(props)
	Scheduler.unstable_yieldValue(props.text)
	return React.createElement("span", { prop = props.text })
end

describe("useInsertionEffect", function()
	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L2692-L2749
	it("fires insertion effects after snapshots on update", function()
		local function CounterA()
			useInsertionEffect(function()
				Scheduler.unstable_yieldValue("Create insertion")
				return function()
					Scheduler.unstable_yieldValue("Destroy insertion")
				end
			end)
			return nil
		end

		local CounterB = React.Component:extend("CounterB")

		function CounterB:getSnapshotBeforeUpdate()
			Scheduler.unstable_yieldValue("Get Snapshot")
			return nil
		end

		function CounterB:componentDidUpdate() end

		function CounterB:render()
			return nil
		end

		local function renderCounters()
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(CounterA),
				React.createElement(CounterB)
			)
		end

		act(function()
			ReactNoop.render(renderCounters())
			jestExpect(Scheduler).toFlushAndYield({ "Create insertion" })
		end)

		act(function()
			ReactNoop.render(renderCounters())
			jestExpect(Scheduler).toFlushAndYield({
				"Get Snapshot",
				"Destroy insertion",
				"Create insertion",
			})
		end)

		act(function()
			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushAndYield({ "Destroy insertion" })
		end)
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L2751-L2811
	it("fires insertion effects before layout effects", function()
		local committedText = "(empty)"

		local function Counter(props)
			useInsertionEffect(function()
				Scheduler.unstable_yieldValue(
					"Create insertion [current: " .. committedText .. "]"
				)
				committedText = tostring(props.count)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy insertion [current: " .. committedText .. "]"
					)
				end
			end)
			useLayoutEffect(function()
				Scheduler.unstable_yieldValue(
					"Create layout [current: " .. committedText .. "]"
				)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy layout [current: " .. committedText .. "]"
					)
				end
			end)
			useEffect(function()
				Scheduler.unstable_yieldValue(
					"Create passive [current: " .. committedText .. "]"
				)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy passive [current: " .. committedText .. "]"
					)
				end
			end)
			return nil
		end

		act(function()
			ReactNoop.render(React.createElement(Counter, { count = 0 }))
			jestExpect(Scheduler).toFlushUntilNextPaint({
				"Create insertion [current: (empty)]",
				"Create layout [current: 0]",
			})
			jestExpect(committedText).toEqual("0")
		end)

		jestExpect(Scheduler).toHaveYielded({ "Create passive [current: 0]" })

		act(function()
			ReactNoop.render(nil)
			jestExpect(Scheduler).toFlushUntilNextPaint({
				"Destroy insertion [current: 0]",
				"Destroy layout [current: 0]",
			})
		end)

		jestExpect(Scheduler).toHaveYielded({ "Destroy passive [current: 0]" })
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L2813-L2878
	it("force flushes passive effects before firing new insertion effects", function()
		local committedText = "(empty)"
		local root = ReactNoop.createRoot()

		local function Counter(props)
			useInsertionEffect(function()
				Scheduler.unstable_yieldValue(
					"Create insertion [current: " .. committedText .. "]"
				)
				committedText = tostring(props.count)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy insertion [current: " .. committedText .. "]"
					)
				end
			end)
			useLayoutEffect(function()
				Scheduler.unstable_yieldValue(
					"Create layout [current: " .. committedText .. "]"
				)
				committedText = tostring(props.count)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy layout [current: " .. committedText .. "]"
					)
				end
			end)
			useEffect(function()
				Scheduler.unstable_yieldValue(
					"Create passive [current: " .. committedText .. "]"
				)
				return function()
					Scheduler.unstable_yieldValue(
						"Destroy passive [current: " .. committedText .. "]"
					)
				end
			end)
			return nil
		end

		act(function()
			-- ROBLOX DEVIATION: A concurrent root supplies the asynchronous update
			-- window that upstream creates with startTransition, which is a separate
			-- React-Luau backport.
			root.render(React.createElement(Counter, { count = 0 }))
			jestExpect(Scheduler).toFlushUntilNextPaint({
				"Create insertion [current: (empty)]",
				"Create layout [current: 0]",
			})
			jestExpect(committedText).toEqual("0")

			root.render(React.createElement(Counter, { count = 1 }))
			jestExpect(Scheduler).toFlushUntilNextPaint({
				"Create passive [current: 0]",
				"Destroy insertion [current: 0]",
				"Create insertion [current: 0]",
				"Destroy layout [current: 1]",
				"Create layout [current: 1]",
			})
			jestExpect(committedText).toEqual("1")
		end)

		jestExpect(Scheduler).toHaveYielded({
			"Destroy passive [current: 1]",
			"Create passive [current: 1]",
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L2880-L3044
	it(
		"fires all insertion effects (interleaved) before firing any layout effects",
		function()
			local committedA = "(empty)"
			local committedB = "(empty)"

			-- ROBLOX DEVIATION: This helper translates upstream template literals.
			local function logState(message)
				Scheduler.unstable_yieldValue(
					message .. " [A: " .. committedA .. ", B: " .. committedB .. "]"
				)
			end

			local function CounterA(props)
				useInsertionEffect(function()
					logState("Create Insertion 1 for Component A")
					committedA = tostring(props.count)
					return function()
						logState("Destroy Insertion 1 for Component A")
					end
				end)
				useInsertionEffect(function()
					logState("Create Insertion 2 for Component A")
					committedA = tostring(props.count)
					return function()
						logState("Destroy Insertion 2 for Component A")
					end
				end)
				useLayoutEffect(function()
					logState("Create Layout 1 for Component A")
					return function()
						logState("Destroy Layout 1 for Component A")
					end
				end)
				useLayoutEffect(function()
					logState("Create Layout 2 for Component A")
					return function()
						logState("Destroy Layout 2 for Component A")
					end
				end)
				return nil
			end

			local function CounterB(props)
				useInsertionEffect(function()
					logState("Create Insertion 1 for Component B")
					committedB = tostring(props.count)
					return function()
						logState("Destroy Insertion 1 for Component B")
					end
				end)
				useInsertionEffect(function()
					logState("Create Insertion 2 for Component B")
					committedB = tostring(props.count)
					return function()
						logState("Destroy Insertion 2 for Component B")
					end
				end)
				useLayoutEffect(function()
					logState("Create Layout 1 for Component B")
					return function()
						logState("Destroy Layout 1 for Component B")
					end
				end)
				useLayoutEffect(function()
					logState("Create Layout 2 for Component B")
					return function()
						logState("Destroy Layout 2 for Component B")
					end
				end)
				return nil
			end

			local function renderCounters(count)
				return React.createElement(
					React.Fragment,
					nil,
					React.createElement(CounterA, { count = count }),
					React.createElement(CounterB, { count = count })
				)
			end

			act(function()
				ReactNoop.render(renderCounters(0))
				jestExpect(Scheduler).toFlushAndYield({
					"Create Insertion 1 for Component A [A: (empty), B: (empty)]",
					"Create Insertion 2 for Component A [A: 0, B: (empty)]",
					"Create Insertion 1 for Component B [A: 0, B: (empty)]",
					"Create Insertion 2 for Component B [A: 0, B: 0]",
					"Create Layout 1 for Component A [A: 0, B: 0]",
					"Create Layout 2 for Component A [A: 0, B: 0]",
					"Create Layout 1 for Component B [A: 0, B: 0]",
					"Create Layout 2 for Component B [A: 0, B: 0]",
				})
				jestExpect({ committedA, committedB }).toEqual({ "0", "0" })
			end)

			act(function()
				ReactNoop.render(renderCounters(1))
				jestExpect(Scheduler).toFlushAndYield({
					"Destroy Insertion 1 for Component A [A: 0, B: 0]",
					"Destroy Insertion 2 for Component A [A: 0, B: 0]",
					"Create Insertion 1 for Component A [A: 0, B: 0]",
					"Create Insertion 2 for Component A [A: 1, B: 0]",
					"Destroy Layout 1 for Component A [A: 1, B: 0]",
					"Destroy Layout 2 for Component A [A: 1, B: 0]",
					"Destroy Insertion 1 for Component B [A: 1, B: 0]",
					"Destroy Insertion 2 for Component B [A: 1, B: 0]",
					"Create Insertion 1 for Component B [A: 1, B: 0]",
					"Create Insertion 2 for Component B [A: 1, B: 1]",
					"Destroy Layout 1 for Component B [A: 1, B: 1]",
					"Destroy Layout 2 for Component B [A: 1, B: 1]",
					"Create Layout 1 for Component A [A: 1, B: 1]",
					"Create Layout 2 for Component A [A: 1, B: 1]",
					"Create Layout 1 for Component B [A: 1, B: 1]",
					"Create Layout 2 for Component B [A: 1, B: 1]",
				})
				jestExpect({ committedA, committedB }).toEqual({ "1", "1" })

				act(function()
					ReactNoop.render(nil)
					jestExpect(Scheduler).toFlushAndYield({
						"Destroy Insertion 1 for Component A [A: 1, B: 1]",
						"Destroy Insertion 2 for Component A [A: 1, B: 1]",
						"Destroy Layout 1 for Component A [A: 1, B: 1]",
						"Destroy Layout 2 for Component A [A: 1, B: 1]",
						"Destroy Insertion 1 for Component B [A: 1, B: 1]",
						"Destroy Insertion 2 for Component B [A: 1, B: 1]",
						"Destroy Layout 1 for Component B [A: 1, B: 1]",
						"Destroy Layout 2 for Component B [A: 1, B: 1]",
					})
				end)
			end)
		end
	)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooksWithNoopRenderer-test.js#L3046-L3092
	it(
		"assumes insertion effect destroy function is either a function or undefined",
		function()
			local function App(props)
				useInsertionEffect(function()
					return props.returnValue
				end)
				return nil
			end

			local root1 = ReactNoop.createRoot()
			jestExpect(function()
				act(function()
					root1.render(React.createElement(App, { returnValue = 17 }))
				end)
			end).toErrorDev(
				"useInsertionEffect must not return anything besides a function, "
					.. "which is used for clean-up. You returned: 17"
			)

			-- ROBLOX DEVIATION: Luau cannot distinguish an omitted return value from
			-- an explicit nil return, so upstream's null-only warning is unrepresentable.

			local root3 = ReactNoop.createRoot()
			-- ROBLOX DEVIATION: Luau Promises and their diagnostic examples use
			-- Promise.new/andThen instead of JavaScript async functions/thenables.
			jestExpect(function()
				act(function()
					root3.render(
						React.createElement(App, { returnValue = Promise.resolve() })
					)
				end)
			end).toErrorDev(
				"useInsertionEffect must not return anything besides a function, "
					.. "which is used for clean-up.\n\n"
					.. "It looks like you wrote useInsertionEffect(Promise.new(function() --[[...]] end) "
					.. "or returned a Promise."
			)

			-- ROBLOX DEVIATION: React-Luau passes cleanup directly to xpcall. Roblox
			-- reports a non-function cleanup as "attempt to call a nil value" instead
			-- of JavaScript's "is not a function".
			jestExpect(function()
				act(function()
					root3.unmount()
				end)
			end).toThrow("attempt to call a nil value")
		end
	)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/ReactFiberHooks.new.js#L2571-L2579
	-- ROBLOX upstream test pattern: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/__tests__/ReactHooks-test.internal.js#L650-L709
	-- ROBLOX DEVIATION: Upstream requires useInsertionEffect to share the mount-time
	-- validation but does not include it in the generic public-hook regression.
	it("warns if deps is not an array", function()
		local function App()
			useInsertionEffect(function() end, "not-an-array" :: any)
			return nil
		end

		jestExpect(function()
			act(function()
				ReactNoop.render(React.createElement(App))
			end)
		end).toErrorDev(
			"Warning: useInsertionEffect received a final argument that is not an array "
				.. "(instead, received `string`). When specified, the final argument "
				.. "must be an array."
		)
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/Activity-test.js#L1428-L1482
	it("insertion effects are not disconnected when the visibility changes", function()
		local function Child(props)
			local step = props.step
			useInsertionEffect(function()
				Scheduler.unstable_yieldValue("Commit mount [" .. step .. "]")
				return function()
					Scheduler.unstable_yieldValue("Commit unmount [" .. step .. "]")
				end
			end, { step })
			return React.createElement(Text, { text = step })
		end

		local function App(props)
			-- ROBLOX DEVIATION: React-Luau does not expose Activity. LegacyHidden
			-- uses the same Offscreen visibility update exercised by this test.
			return React.createElement(
				LegacyHidden,
				{ mode = if props.show then "visible" else "hidden" },
				useMemo(function()
					return React.createElement(Child, { step = props.step })
				end, { props.step })
			)
		end

		local root = ReactNoop.createRoot()
		act(function()
			root.render(React.createElement(App, { show = true, step = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ 1, "Commit mount [1]" })
		jestExpect(root).toMatchRenderedOutput(span(1))

		act(function()
			root.render(React.createElement(App, { show = false, step = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({})
		jestExpect(root).toMatchRenderedOutput(span(1, true))

		act(function()
			root.render(React.createElement(App, { show = false, step = 2 }))
		end)
		jestExpect(Scheduler).toHaveYielded({
			2,
			"Commit unmount [1]",
			"Commit mount [2]",
		})
		-- ROBLOX DEVIATION: LegacyHidden does not retain hidden host output when
		-- its deferred children commit an update. Activity retains it upstream.
		jestExpect(root).toMatchRenderedOutput(span(2))

		act(function()
			root.render(React.createElement(App, { show = true, step = 2 }))
		end)
		jestExpect(Scheduler).toHaveYielded({})
		jestExpect(root).toMatchRenderedOutput(span(2))
	end)
end)
