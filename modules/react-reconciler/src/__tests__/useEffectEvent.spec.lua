--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js
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
local LuauPolyfill
local clearTimeout
local setTimeout
local ReactNoop
local Scheduler
local act
local useEffectEvent
local useEffect
local useInsertionEffect
local useLayoutEffect
local useState

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()

	LuauPolyfill = require(Packages.LuauPolyfill)
	clearTimeout = LuauPolyfill.clearTimeout
	setTimeout = LuauPolyfill.setTimeout
	React = require(Packages.React)
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	Scheduler = require(Packages.Scheduler)

	act = ReactNoop.act
	useEffectEvent = React.useEffectEvent
	useEffect = React.useEffect
	useInsertionEffect = React.useInsertionEffect
	useLayoutEffect = React.useLayoutEffect
	useState = React.useState
end)

local function span(prop)
	return { type = "span", hidden = false, children = {}, prop = prop }
end

local function Text(props)
	Scheduler.unstable_yieldValue(props.text)
	return React.createElement("span", { prop = props.text })
end

describe("useEffectEvent", function()
	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L56-L130
	it("memoizes basic case correctly", function()
		local button = React.createRef()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:render()
			return React.createElement(Text, { text = "Increment" })
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, updateCount = useState(0)
			local onClick = useEffectEvent(function()
				updateCount(function(currentCount)
					return currentCount + incrementBy
				end)
			end)

			return React.createElement(React.Fragment, nil, {
				React.createElement(IncrementButton, {
					key = "button",
					onClick = function()
						onClick()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "count",
					text = "Count: " .. count,
				}),
			})
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
		jestExpect(Scheduler).toFlushAndYield({ "Increment", "Count: 0" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 0"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 1" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 1"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 2" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 2"),
		})

		ReactNoop.render(React.createElement(Counter, { incrementBy = 10 }))
		jestExpect(Scheduler).toFlushAndYield({ "Increment", "Count: 2" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 2"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 12" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 12"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L132-L192
	it("can be defined more than once", function()
		local button = React.createRef()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:multiply()
			self.props.onMouseEnter()
		end

		function IncrementButton:render()
			return React.createElement(Text, { text = "Increment" })
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, updateCount = useState(0)
			local onClick = useEffectEvent(function()
				updateCount(function(currentCount)
					return currentCount + incrementBy
				end)
			end)
			local onMouseEnter = useEffectEvent(function()
				updateCount(function(currentCount)
					return currentCount * incrementBy
				end)
			end)

			return React.createElement(React.Fragment, nil, {
				React.createElement(IncrementButton, {
					key = "button",
					onClick = function()
						onClick()
					end,
					onMouseEnter = function()
						onMouseEnter()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "count",
					text = "Count: " .. count,
				}),
			})
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 5 }))
		jestExpect(Scheduler).toFlushAndYield({ "Increment", "Count: 0" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 0"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 5" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 5"),
		})

		act(function()
			button.current:multiply()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 25" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 25"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L194-L242
	it("does not preserve `this` in event functions", function()
		local button = React.createRef()
		local GreetButton = React.PureComponent:extend("GreetButton")

		function GreetButton:greet()
			self.props.onClick()
		end

		function GreetButton:render()
			return React.createElement(Text, { text = "Say " .. self.props.hello })
		end

		local function Greeter(props)
			local hello = props.hello
			local greeting, updateGreeting = useState("Seb says " .. hello)
			local person = setmetatable({
				greet = function(self)
					updateGreeting(tostring(self) .. " says " .. hello)
				end,
			}, {
				__tostring = function()
					return "Jane"
				end,
			})
			local onClick = useEffectEvent(person.greet)

			return React.createElement(React.Fragment, nil, {
				React.createElement(GreetButton, {
					key = "button",
					hello = hello,
					onClick = function()
						onClick()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "greeting",
					text = "Greeting: " .. greeting,
				}),
			})
		end

		ReactNoop.render(React.createElement(Greeter, { hello = "hej" }))
		jestExpect(Scheduler).toFlushAndYield({ "Say hej", "Greeting: Seb says hej" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Say hej"),
			span("Greeting: Seb says hej"),
		})

		act(function()
			button.current:greet()
		end)
		-- ROBLOX deviation: Luau's receiver-less value is nil rather than JavaScript's undefined.
		jestExpect(Scheduler).toHaveYielded({ "Say hej", "Greeting: nil says hej" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Say hej"),
			span("Greeting: nil says hej"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L244-L276
	it("throws when called in render", function()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:render()
			self.props.onClick()
			return React.createElement(Text, { text = "Increment" })
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, updateCount = useState(0)
			local onClick = useEffectEvent(function()
				updateCount(function(currentCount)
					return currentCount + incrementBy
				end)
			end)

			return React.createElement(
				React.Fragment,
				nil,
				React.createElement(IncrementButton, {
					onClick = function()
						onClick()
					end,
				}),
				React.createElement(Text, { text = "Count: " .. count })
			)
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
		jestExpect(Scheduler).toFlushAndThrow(
			"A function wrapped in useEffectEvent can't be called during rendering."
		)
		-- ROBLOX DEVIATION: React-Luau's React 17 recovery renders the sibling
		-- during the concurrent attempt and synchronous retry before surfacing
		-- the uncaught root error.
		jestExpect(Scheduler).toHaveYielded({ "Count: 0", "Count: 0" })
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L278-L376
	it("useLayoutEffect shouldn't re-fire when event handlers change", function()
		local button = React.createRef()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:render()
			return React.createElement(Text, { text = "Increment" })
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, updateCount = useState(0)
			local increment = useEffectEvent(function(amount)
				updateCount(function(currentCount)
					local resolvedAmount = if amount == nil or amount == 0
						then incrementBy
						else amount
					return currentCount + resolvedAmount
				end)
			end)

			useLayoutEffect(function()
				Scheduler.unstable_yieldValue("Effect: by " .. incrementBy * 2)
				increment(incrementBy * 2)
			end, { incrementBy })

			return React.createElement(React.Fragment, nil, {
				React.createElement(IncrementButton, {
					key = "button",
					onClick = function()
						increment()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "count",
					text = "Count: " .. count,
				}),
			})
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 0",
			"Effect: by 2",
			"Increment",
			"Count: 2",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 2"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 3" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 3"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 4" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 4"),
		})

		ReactNoop.render(React.createElement(Counter, { incrementBy = 10 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 4",
			"Effect: by 20",
			"Increment",
			"Count: 24",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 24"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 34" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 34"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L378-L475
	it("useEffect shouldn't re-fire when event handlers change", function()
		local button = React.createRef()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:render()
			return React.createElement(Text, { text = "Increment" })
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, updateCount = useState(0)
			local increment = useEffectEvent(function(amount)
				updateCount(function(currentCount)
					local resolvedAmount = if amount == nil or amount == 0
						then incrementBy
						else amount
					return currentCount + resolvedAmount
				end)
			end)

			useEffect(function()
				Scheduler.unstable_yieldValue("Effect: by " .. incrementBy * 2)
				increment(incrementBy * 2)
			end, { incrementBy })

			return React.createElement(React.Fragment, nil, {
				React.createElement(IncrementButton, {
					key = "button",
					onClick = function()
						increment()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "count",
					text = "Count: " .. count,
				}),
			})
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 0",
			"Effect: by 2",
			"Increment",
			"Count: 2",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 2"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 3" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 3"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 4" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 4"),
		})

		ReactNoop.render(React.createElement(Counter, { incrementBy = 10 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 4",
			"Effect: by 20",
			"Increment",
			"Count: 24",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 24"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 34" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 34"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L477-L580
	it("is stable in a custom hook", function()
		local button = React.createRef()
		local IncrementButton = React.PureComponent:extend("IncrementButton")

		function IncrementButton:increment()
			self.props.onClick()
		end

		function IncrementButton:render()
			return React.createElement(Text, { text = "Increment" })
		end

		local function useCount(incrementBy)
			local count, updateCount = useState(0)
			local increment = useEffectEvent(function(amount)
				updateCount(function(currentCount)
					local resolvedAmount = if amount == nil or amount == 0
						then incrementBy
						else amount
					return currentCount + resolvedAmount
				end)
			end)
			return count, increment
		end

		local function Counter(props)
			local incrementBy = props.incrementBy
			local count, increment = useCount(incrementBy)

			useEffect(function()
				Scheduler.unstable_yieldValue("Effect: by " .. incrementBy * 2)
				increment(incrementBy * 2)
			end, { incrementBy })

			return React.createElement(React.Fragment, nil, {
				React.createElement(IncrementButton, {
					key = "button",
					onClick = function()
						increment()
					end,
					ref = button,
				}),
				React.createElement(Text, {
					key = "count",
					text = "Count: " .. count,
				}),
			})
		end

		ReactNoop.render(React.createElement(Counter, { incrementBy = 1 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 0",
			"Effect: by 2",
			"Increment",
			"Count: 2",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 2"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 3" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 3"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 4" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 4"),
		})

		ReactNoop.render(React.createElement(Counter, { incrementBy = 10 }))
		jestExpect(Scheduler).toFlushAndYield({
			"Increment",
			"Count: 4",
			"Effect: by 20",
			"Increment",
			"Count: 24",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 24"),
		})

		act(function()
			button.current:increment()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Increment", "Count: 34" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Increment"),
			span("Count: 34"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L582-L604
	it("is mutated before all other effects", function()
		local function Counter(props)
			local increment
			useInsertionEffect(function()
				Scheduler.unstable_yieldValue("Effect value: " .. props.value)
				increment()
			end, { props.value })

			increment = useEffectEvent(function()
				Scheduler.unstable_yieldValue("Event value: " .. props.value)
			end)

			return React.createElement(React.Fragment)
		end

		ReactNoop.render(React.createElement(Counter, { value = 1 }))
		jestExpect(Scheduler).toFlushAndYield({ "Effect value: 1", "Event value: 1" })

		act(function()
			ReactNoop.render(React.createElement(Counter, { value = 2 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Effect value: 2", "Event value: 2" })
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L606-L643
	it("doesn't provide a stable identity", function()
		local function Counter(props)
			local onClick = useEffectEvent(function()
				Scheduler.unstable_yieldValue(
					"onClick, shouldRender="
						.. tostring(props.shouldRender)
						.. ", value="
						.. props.value
				)
			end)

			useEffect(function()
				onClick()
			end, { onClick })

			useEffect(function()
				onClick()
			end, { props.shouldRender })

			return React.createElement(React.Fragment)
		end

		ReactNoop.render(React.createElement(Counter, { shouldRender = true, value = 0 }))
		jestExpect(Scheduler).toFlushAndYield({
			"onClick, shouldRender=true, value=0",
			"onClick, shouldRender=true, value=0",
		})

		ReactNoop.render(React.createElement(Counter, { shouldRender = true, value = 1 }))
		jestExpect(Scheduler).toFlushAndYield({ "onClick, shouldRender=true, value=1" })

		ReactNoop.render(
			React.createElement(Counter, { shouldRender = false, value = 2 })
		)
		jestExpect(Scheduler).toFlushAndYield({
			"onClick, shouldRender=false, value=2",
			"onClick, shouldRender=false, value=2",
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L645-L693
	it("event handlers always see the latest committed value", function()
		local committedEventHandler

		local function App(props)
			local event = useEffectEvent(function()
				return "Value seen by useEffectEvent: " .. props.value
			end)

			useEffect(function()
				Scheduler.unstable_yieldValue("Commit new event handler")
				committedEventHandler = event
				return function()
					committedEventHandler = nil
				end
			end, {})
			return "Latest rendered value " .. props.value
		end

		local root = ReactNoop.createRoot()
		act(function()
			root.render(React.createElement(App, { value = 1 }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "Commit new event handler" })
		jestExpect(root).toMatchRenderedOutput("Latest rendered value 1")
		jestExpect(committedEventHandler()).toBe("Value seen by useEffectEvent: 1")

		act(function()
			root.render(React.createElement(App, { value = 2 }))
		end)
		jestExpect(Scheduler).toHaveYielded({})
		jestExpect(root).toMatchRenderedOutput("Latest rendered value 2")
		jestExpect(committedEventHandler()).toBe("Value seen by useEffectEvent: 2")
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L695-L782
	it("integration: implements docs chat room example", function()
		local function createConnection()
			local connectedCallback
			local timeout
			return {
				connect = function()
					timeout = setTimeout(function()
						if connectedCallback ~= nil then
							connectedCallback()
						end
					end, 100)
				end,
				on = function(event, callback)
					if connectedCallback ~= nil then
						error("Cannot add the handler twice.")
					end
					if event ~= "connected" then
						error('Only "connected" event is supported.')
					end
					connectedCallback = callback
				end,
				disconnect = function()
					clearTimeout(timeout)
				end,
			}
		end

		local function ChatRoom(props)
			local onConnected = useEffectEvent(function()
				Scheduler.unstable_yieldValue("Connected! theme: " .. props.theme)
			end)

			useEffect(function()
				local connection = createConnection()
				connection.on("connected", function()
					onConnected()
				end)
				connection.connect()
				return function()
					connection.disconnect()
				end
			end, { props.roomId })

			return React.createElement(Text, {
				text = "Welcome to the " .. props.roomId .. " room!",
			})
		end

		act(function()
			ReactNoop.render(React.createElement(ChatRoom, {
				roomId = "general",
				theme = "light",
			}))
		end)
		jest.advanceTimersByTime(100)
		jestExpect(Scheduler).toHaveYielded({
			"Welcome to the general room!",
			"Connected! theme: light",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Welcome to the general room!"),
		})

		act(function()
			ReactNoop.render(React.createElement(ChatRoom, {
				roomId = "music",
				theme = "light",
			}))
		end)
		jest.advanceTimersByTime(100)
		jestExpect(Scheduler).toHaveYielded({
			"Welcome to the music room!",
			"Connected! theme: light",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Welcome to the music room!"),
		})

		act(function()
			ReactNoop.render(React.createElement(ChatRoom, {
				roomId = "music",
				theme = "dark",
			}))
		end)
		jest.advanceTimersByTime(100)
		jestExpect(Scheduler).toHaveYielded({ "Welcome to the music room!" })
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Welcome to the music room!"),
		})

		act(function()
			ReactNoop.render(React.createElement(ChatRoom, {
				roomId = "travel",
				theme = "dark",
			}))
		end)
		jest.advanceTimersByTime(100)
		jestExpect(Scheduler).toHaveYielded({
			"Welcome to the travel room!",
			"Connected! theme: dark",
		})
		jestExpect(ReactNoop.getChildren()).toEqual({
			span("Welcome to the travel room!"),
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L784-L852
	it("integration: implements the docs logVisit example", function()
		local button = React.createRef()
		local AddToCartButton = React.PureComponent:extend("AddToCartButton")

		function AddToCartButton:addToCart()
			self.props.onClick()
		end

		function AddToCartButton:render()
			return React.createElement(Text, { text = "Add to cart" })
		end

		local ShoppingCartContext = React.createContext(nil)

		local function AppShell(props)
			local items, updateItems = useState({})
			local value = React.useMemo(function()
				return { items = items, updateItems = updateItems }
			end, { items, updateItems })

			return React.createElement(
				ShoppingCartContext.Provider,
				{ value = value },
				props.children
			)
		end

		local function Page(props)
			local cart = React.useContext(ShoppingCartContext)
			local items = cart.items
			local updateItems = cart.updateItems
			local onClick = useEffectEvent(function()
				local nextItems = table.clone(items)
				table.insert(nextItems, 1)
				updateItems(nextItems)
			end)
			local numberOfItems = #items

			local onVisit = useEffectEvent(function(visitedUrl)
				Scheduler.unstable_yieldValue(
					"url: " .. visitedUrl .. ", numberOfItems: " .. numberOfItems
				)
			end)

			useEffect(function()
				onVisit(props.url)
			end, { props.url })

			return React.createElement(AddToCartButton, {
				onClick = function()
					onClick()
				end,
				ref = button,
			})
		end

		act(function()
			ReactNoop.render(
				React.createElement(
					AppShell,
					nil,
					React.createElement(Page, { url = "/shop/1" })
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Add to cart",
			"url: /shop/1, numberOfItems: 0",
		})

		act(function()
			button.current:addToCart()
		end)
		jestExpect(Scheduler).toHaveYielded({ "Add to cart" })

		act(function()
			ReactNoop.render(
				React.createElement(
					AppShell,
					nil,
					React.createElement(Page, { url = "/shop/2" })
				)
			)
		end)
		jestExpect(Scheduler).toHaveYielded({
			"Add to cart",
			"url: /shop/2, numberOfItems: 1",
		})
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/6bec011b407fe8a2d4babb363289ccce4bc8fcf3/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L854-L891
	it("reads the latest context value in memo Components", function()
		local MyContext = React.createContext("default")
		local logContextValue
		local ContextReader = React.memo(function()
			local value = React.useContext(MyContext)
			Scheduler.unstable_yieldValue("ContextReader: " .. value)
			local fireLogContextValue = useEffectEvent(function()
				Scheduler.unstable_yieldValue("ContextReader (Effect event): " .. value)
			end)
			useEffect(function()
				logContextValue = fireLogContextValue
			end, {})
			return nil
		end)

		local function App(props)
			return React.createElement(
				MyContext.Provider,
				{ value = props.value },
				React.createElement(ContextReader)
			)
		end

		local root = ReactNoop.createRoot()
		act(function()
			root.render(React.createElement(App, { value = "first" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "ContextReader: first" })

		logContextValue()
		jestExpect(Scheduler).toHaveYielded({ "ContextReader (Effect event): first" })

		act(function()
			root.render(React.createElement(App, { value = "second" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "ContextReader: second" })

		logContextValue()
		jestExpect(Scheduler).toHaveYielded({ "ContextReader (Effect event): second" })
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/6bec011b407fe8a2d4babb363289ccce4bc8fcf3/packages/react-reconciler/src/__tests__/useEffectEvent-test.js#L893-L930
	it("reads the latest context value in forwardRef Components", function()
		local MyContext = React.createContext("default")
		local logContextValue
		local ContextReader = React.forwardRef(function(_props, _ref)
			local value = React.useContext(MyContext)
			Scheduler.unstable_yieldValue("ContextReader: " .. value)
			local fireLogContextValue = useEffectEvent(function()
				Scheduler.unstable_yieldValue("ContextReader (Effect event): " .. value)
			end)
			useEffect(function()
				logContextValue = fireLogContextValue
			end, {})
			return nil
		end)

		local function App(props)
			return React.createElement(
				MyContext.Provider,
				{ value = props.value },
				React.createElement(ContextReader)
			)
		end

		local root = ReactNoop.createRoot()
		act(function()
			root.render(React.createElement(App, { value = "first" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "ContextReader: first" })

		logContextValue()
		jestExpect(Scheduler).toHaveYielded({ "ContextReader (Effect event): first" })

		act(function()
			root.render(React.createElement(App, { value = "second" }))
		end)
		jestExpect(Scheduler).toHaveYielded({ "ContextReader: second" })

		logContextValue()
		jestExpect(Scheduler).toHaveYielded({ "ContextReader (Effect event): second" })
	end)
end)
