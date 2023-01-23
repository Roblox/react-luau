-- ROBLOX: tests deviant logic for Roblox react which permits use of setState() in component constructor

local Packages = script.Parent.Parent.Parent
local React, Shared, ReactNoop
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach

beforeEach(function()
	jest.resetModules()
	ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	React = require(script.Parent.Parent)
	Shared = require(Packages.Shared)
end)

local function initTests(defineInitMethod: (any, string | number, any) -> (), name)
	it("has correct state populated in render w/ " .. name, function()
		local Component = React.Component:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState

		function Component:render()
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component))
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
		})
	end)

	it("has derived state populated in render w/ " .. name, function()
		local Component = React.Component:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState

		function Component:render()
			capturedState = self.state
		end

		function Component.getDerivedStateFromProps(props, state)
			return {
				name = state.name,
				surname = props.surname,
			}
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component, { surname = "Smith" }))
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
			surname = "Smith",
		})
	end)

	it("respects React.None in derived state w/ " .. name, function()
		local Component = React.Component:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState

		function Component:render()
			capturedState = self.state
		end

		function Component.getDerivedStateFromProps(props, state)
			return {
				name = React.None,
				surname = props.surname,
			}
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component, { surname = "Smith" }))
		end)

		jestExpect(capturedState).toEqual({
			surname = "Smith",
		})
	end)

	it("updates state correctly w/ " .. name, function()
		local Component = React.Component:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState
		local capturedSetState

		function Component:render()
			capturedSetState = function(...)
				self:setState(...)
			end
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component))
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
		})

		ReactNoop.act(function()
			capturedSetState({
				surname = "Smith",
			})
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
			surname = "Smith",
		})
	end)

	it("updates state correctly with functional setState w/ " .. name, function()
		local Component = React.Component:extend("Component")

		defineInitMethod(Component, "count", 0)

		local capturedState
		local capturedSetState

		function Component:render()
			capturedSetState = function(...)
				self:setState(...)
			end
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component))
		end)

		jestExpect(capturedState).toEqual({
			count = 0,
		})

		ReactNoop.act(function()
			capturedSetState(function(state, props)
				return {
					count = state.count + 1,
				}
			end)
		end)

		jestExpect(capturedState).toEqual({
			count = 1,
		})
	end)
	it("updates a pure component when state changes w/ " .. name, function()
		local Component = React.PureComponent:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState
		local capturedSetState
		local renderCount = 0

		function Component:render()
			capturedSetState = function(...)
				self:setState(...)
			end
			capturedState = self.state
			renderCount += 1
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component))
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
		})

		local renderCountAfterFirst = renderCount

		ReactNoop.act(function()
			capturedSetState({
				name = "Bob",
			})
		end)

		jestExpect(capturedState).toEqual({
			name = "Bob",
		})

		jestExpect(renderCountAfterFirst < renderCount).toEqual(true)
	end)
	it("does not update a pure component with a no-op setState w/ " .. name, function()
		local Component = React.PureComponent:extend("Component")

		defineInitMethod(Component, "name", "Mike")

		local capturedState
		local capturedSetState
		local renderCount = 0

		function Component:render()
			capturedSetState = function(...)
				self:setState(...)
			end
			capturedState = self.state
			renderCount += 1
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(Component))
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
		})

		local renderCountAfterFirst = renderCount

		ReactNoop.act(function()
			capturedSetState({
				name = "Mike",
			})
		end)

		jestExpect(capturedState).toEqual({
			name = "Mike",
		})

		jestExpect(renderCountAfterFirst).toEqual(renderCount)
	end)
end

-- runs tests using setState in constructor
initTests(function(component, key, value)
	function component:init()
		self:setState({
			[key] = value,
		})
	end
end, "setState in constructor")

-- runs tests using self.state in constructor
initTests(function(component, key, value)
	function component:init()
		self.state = {
			[key] = value,
		}
	end
end, "self.state in constructor")

describe("setState-specific behavior", function()
	it("allows multiple setStates in sequence during init", function()
		local MyComponent = React.Component:extend("MyComponent")
		local capturedState
		function MyComponent:init()
			self:setState({ value = 1 })
			self:setState({ otherValue = 2 })
		end
		function MyComponent:render()
			return nil
		end
		function MyComponent:componentDidMount()
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(MyComponent))
		end)

		jestExpect(capturedState).toEqual({ value = 1, otherValue = 2 })
	end)

	it("accounts for `None` values", function()
		local MyComponent = React.Component:extend("MyComponent")
		local capturedState
		function MyComponent:init()
			self:setState({ a = 1, b = 2 })
			self:setState({ a = React.None })
		end
		function MyComponent:render()
			return nil
		end
		function MyComponent:componentDidMount()
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(MyComponent))
		end)

		jestExpect(capturedState).toEqual({ b = 2 })
	end)

	it("provides an empty table to functional setState on first run", function()
		local MyComponent = React.Component:extend("MyComponent")
		local capturedState, capturedPrevState
		function MyComponent:init()
			self:setState(function(prevState)
				capturedPrevState = prevState
				return { value = 1 }
			end)
		end
		function MyComponent:render()
			return nil
		end
		function MyComponent:componentDidMount()
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(MyComponent))
		end)

		-- The UninitializedState object uses a metatable to emit warnings
		-- when read from, so this expectation ends up being noisy due to
		-- jest poking around:
		-- jestExpect(capturedPrevState).toEqual(Shared.UninitializedState)

		-- Instead, use a simple assert:
		assert(
			capturedPrevState == Shared.UninitializedState,
			"captured previous state differs from UninitializedState placeholder"
		)
		jestExpect(capturedState).toEqual({ value = 1 })
	end)

	it("warns on accessing the initial empty state table", function()
		local MyComponent = React.Component:extend("MyComponent")
		function MyComponent:init()
			self:setState(function(prevState)
				return { value = (prevState.value or 0) + 1 }
			end)
		end
		function MyComponent:render()
			return nil
		end

		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(MyComponent))
			end)
		end).toWarnDev(
			"Attempted to access uninitialized state. Use setState to initialize state"
		)
	end)

	it("allows functional setState", function()
		local MyComponent = React.Component:extend("MyComponent")
		local capturedState
		function MyComponent:init()
			self:setState({ value = 1 })
			self:setState(function(prevState)
				return { value = prevState.value + 1 }
			end)
		end
		function MyComponent:render()
			return nil
		end
		function MyComponent:componentDidMount()
			capturedState = self.state
		end

		ReactNoop.act(function()
			ReactNoop.render(React.createElement(MyComponent))
		end)

		jestExpect(capturedState).toEqual({ value = 2 })
	end)

	it("warns when given a `callback` argument", function()
		local MyComponent = React.Component:extend("MyComponent")
		function MyComponent:init()
			self:setState({ value = 1 }, function() end)
		end
		function MyComponent:render()
			return nil
		end

		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(MyComponent))
			end)
		end).toWarnDev(
			"Received a `callback` argument to `setState` during "
				.. 'initialization of "MyComponent". The callback behavior '
				.. "is not supported when using `setState` in `init`.\n\n"
				.. "Consider defining similar behavior in a "
				.. "`compontentDidMount` method instead."
		)
	end)

	it("throws when given an invalid state payload", function()
		local MyComponent = React.Component:extend("MyComponent")
		function MyComponent:init()
			self:setState(true)
		end
		function MyComponent:render()
			return nil
		end

		jestExpect(function()
			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(MyComponent))
				end)
			end).toErrorDev("The above error occurred in the <MyComponent> component")
		end).toThrow(
			"setState(...): takes an object of state variables to update "
				.. "or a function which returns an object of state variables."
		)
	end)
end)
