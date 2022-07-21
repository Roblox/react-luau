--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

return function()
	-- local Dependencies = script.Parent.Parent.Parent.Parent.Packages
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array
	local Error = LuauPolyfill.Error
	local UninitializedState = require(Packages.Shared).UninitializedState
	-- local PropTypes = require(Dependencies.PropTypes)
	local React = require(Packages.React)
	local ReactShallowRenderer = require(script.Parent.Parent)

	local createRenderer = ReactShallowRenderer.createRenderer

	local function validateElement(element)
		if _G.__DEV__ then
			element._store.validated = true
		end
		return element
	end

	local function validate(list)
		if _G.__DEV__ then
			for _, element in list do
				validateElement(element)
			end
		end
		return list
	end

	it("should call all of the legacy lifecycle hooks", function()
		local logs = {}
		local logger = function(message)
			return function()
				table.insert(logs, message)
				return true
			end
		end

		local SomeComponent = React.Component:extend("SomeComponent")
		SomeComponent.UNSAFE_componentWillMount = logger("componentWillMount")
		SomeComponent.componentDidMount = logger("componentDidMount")
		SomeComponent.UNSAFE_componentWillReceiveProps = logger(
			"componentWillReceiveProps"
		)
		SomeComponent.shouldComponentUpdate = logger("shouldComponentUpdate")
		SomeComponent.UNSAFE_componentWillUpdate = logger("componentWillUpdate")
		SomeComponent.componentDidUpdate = logger("componentDidUpdate")
		SomeComponent.componentWillUnmount = logger("componentWillUnmount")
		function SomeComponent:render()
			return React.createElement("Frame")
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SomeComponent, {
			foo = 1,
		}))

		-- Calling cDU might lead to problems with host component references.
		-- Since our components aren't really mounted, refs won't be available.
		jestExpect(logs).toEqual({ "componentWillMount" })

		Array.splice(logs, 1)

		local instance = shallowRenderer:getMountedInstance()
		instance:setState({})

		jestExpect(logs).toEqual({ "shouldComponentUpdate", "componentWillUpdate" })

		Array.splice(logs, 1)

		shallowRenderer:render(React.createElement(SomeComponent, {
			foo = 2,
		}))

		-- The previous shallow renderer did not trigger cDU for props changes.
		jestExpect(logs).toEqual({
			"componentWillReceiveProps",
			"shouldComponentUpdate",
			"componentWillUpdate",
		})
	end)

	it("should call all of the new lifecycle hooks", function()
		local logs = {}
		local logger = function(message)
			return function()
				table.insert(logs, message)
				return true
			end
		end

		local SomeComponent = React.Component:extend("SomeComponent")
		SomeComponent.getDerivedStateFromProps = logger("getDerivedStateFromProps")
		SomeComponent.componentDidMount = logger("componentDidMount")
		SomeComponent.shouldComponentUpdate = logger("shouldComponentUpdate")
		SomeComponent.componentDidUpdate = logger("componentDidUpdate")
		SomeComponent.componentWillUnmount = logger("componentWillUnmount")
		function SomeComponent:init()
			self.state = {}
		end
		function SomeComponent:render()
			return React.createElement("Frame")
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SomeComponent, {
			foo = 1,
		}))

		-- Calling cDU might lead to problems with host component references.
		-- Since our components aren't really mounted, refs won't be available.
		jestExpect(logs).toEqual({ "getDerivedStateFromProps" })

		Array.splice(logs, 1)

		local instance = shallowRenderer:getMountedInstance()
		instance:setState({})

		jestExpect(logs).toEqual({ "getDerivedStateFromProps", "shouldComponentUpdate" })

		Array.splice(logs, 1)

		shallowRenderer:render(React.createElement(SomeComponent, {
			foo = 2,
		}))

		-- The previous shallow renderer did not trigger cDU for props changes.
		jestExpect(logs).toEqual({ "getDerivedStateFromProps", "shouldComponentUpdate" })
	end)

	it(
		"should not invoke deprecated lifecycles (cWM/cWRP/cWU) if new static gDSFP is present",
		function()
			local Component = React.Component:extend("Component")
			function Component:init()
				self.state = {}
			end
			function Component.getDerivedStateFromProps()
				return nil
			end
			function Component:componentWillMount()
				error(Error("unexpected"))
			end
			function Component:componentWillReceiveProps()
				error(Error("unexpected"))
			end
			function Component:componentWillUpdate()
				error(Error("unexpected"))
			end
			function Component:render()
				return nil
			end

			local shallowRenderer = createRenderer()
			jestExpect(function()
				shallowRenderer:render(React.createElement(Component))
			end).never.toThrow()
		end
	)

	it(
		"should not invoke deprecated lifecycles (cWM/cWRP/cWU) if new getSnapshotBeforeUpdate is present",
		function()
			local Component = React.Component:extend("Component")
			function Component:getSnapshotBeforeUpdate()
				return nil
			end
			function Component:componentWillMount()
				error(Error("unexpected"))
			end
			function Component:componentWillReceiveProps()
				error(Error("unexpected"))
			end
			function Component:componentWillUpdate()
				error(Error("unexpected"))
			end
			function Component:render()
				return nil
			end

			local shallowRenderer = createRenderer()
			jestExpect(function()
				shallowRenderer:render(React.createElement(Component, { value = 1 }))
			end).never.toThrow()
			jestExpect(function()
				shallowRenderer:render(React.createElement(Component, { value = 2 }))
			end).never.toThrow()
		end
	)

	it(
		"should not call getSnapshotBeforeUpdate or componentDidUpdate when updating since refs wont exist",
		function()
			local Component = React.Component:extend("Component")
			function Component:getSnapshotBeforeUpdate()
				error(Error("unexpected"))
			end
			function Component:componentDidUpdate()
				error(Error("unexpected"))
			end
			function Component:render()
				return nil
			end

			local shallowRenderer = createRenderer()
			jestExpect(function()
				shallowRenderer:render(React.createElement(Component, { value = 1 }))
			end).never.toThrow()
			jestExpect(function()
				shallowRenderer:render(React.createElement(Component, { value = 2 }))
			end).never.toThrow()
		end
	)

	it("should only render 1 level deep", function()
		local function Child()
			error(Error("This component should not render"))
		end

		local function Parent()
			return React.createElement("Frame", nil, {
				Child = React.createElement(Child),
			})
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Parent))
	end)

	it("should have shallow rendering", function()
		local SomeComponent = React.Component:extend("Component")
		function SomeComponent:render()
			return React.createElement(
				"Frame",
				nil,
				React.createElement("TextLabel", { Text = "child1" }),
				React.createElement("TextLabel", { Text = "child2" })
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SomeComponent))

		jestExpect(result.type).toEqual("Frame")
		jestExpect(result.props.children).toEqual(validate({
			React.createElement("TextLabel", { Text = "child1" }),
			React.createElement("TextLabel", { Text = "child2" }),
		}))
	end)

	it("should handle ForwardRef", function()
		local testRef = React.createRef()
		local SomeComponent = React.forwardRef(function(props, ref)
			jestExpect(ref).toEqual(testRef)
			return React.createElement(
				"Frame",
				nil,
				React.createElement("TextLabel", { Text = "child1" }),
				React.createElement("TextLabel", { Text = "child2" })
			)
		end)

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SomeComponent, {
			ref = testRef,
		}))

		jestExpect(result.type).toEqual("Frame")
		jestExpect(result.props.children).toEqual(validate({
			React.createElement("TextLabel", { Text = "child1" }),
			React.createElement("TextLabel", { Text = "child2" }),
		}))
	end)

	it("should handle Profiler", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:render()
			return React.createElement(
				React.Profiler,
				{ id = "test", onRender = function() end },
				React.createElement(
					"Text",
					nil,
					React.createElement("Frame", { className = "child1" }),
					React.createElement("Frame", { className = "child2" })
				)
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SomeComponent))

		jestExpect(result.type).toEqual(React.Profiler)
		jestExpect(result.props.children).toEqual(
			validateElement(
				React.createElement(
					"Text",
					nil,
					React.createElement("Frame", { className = "child1" }),
					React.createElement("Frame", { className = "child2" })
				)
			)
		)
	end)

	it("should enable shouldComponentUpdate to prevent a re-render", function()
		local renderCounter = 0
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { update = false }
		end
		function SimpleComponent:shouldComponentUpdate(nextProps, nextState)
			return self.state.update ~= nextState.update
		end
		function SimpleComponent:render()
			renderCounter += 1
			return React.createElement("TextLabel", { Text = renderCounter })
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		local instance = shallowRenderer:getMountedInstance()
		instance:setState({ update = false })
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		instance:setState({ update = true })
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 2 })
		)
	end)

	it("should enable PureComponent to prevent a re-render", function()
		local renderCounter = 0
		local SimpleComponent = React.PureComponent:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { update = false }
		end
		function SimpleComponent:render()
			renderCounter += 1
			return React.createElement("TextLabel", { Text = renderCounter })
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		local instance = shallowRenderer:getMountedInstance()
		instance:setState({ update = false })
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		instance:setState({ update = true })
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 2 })
		)
	end)

	it("should not run shouldComponentUpdate during forced update", function()
		local scuCounter = 0
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { count = 1 }
		end
		function SimpleComponent:shouldComponentUpdate()
			scuCounter += 1
			return false
		end
		function SimpleComponent:render()
			return React.createElement("TextLabel", { Text = self.state.count })
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(scuCounter).toEqual(0)
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		-- Force update the initial state. sCU should not fire.
		local instance = shallowRenderer:getMountedInstance()
		instance:forceUpdate()
		jestExpect(scuCounter).toEqual(0)
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		-- Setting state updates the instance, but doesn't re-render
		-- because sCU returned false.
		instance:setState(function(state)
			return { count = state.count + 1 }
		end)
		jestExpect(scuCounter).toEqual(1)
		jestExpect(instance.state.count).toEqual(2)
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 1 })
		)

		-- A force update updates the render output, but doesn't call sCU.
		instance:forceUpdate()
		jestExpect(scuCounter).toEqual(1)
		jestExpect(instance.state.count).toEqual(2)
		jestExpect(shallowRenderer:getRenderOutput()).toEqual(
			React.createElement("TextLabel", { Text = 2 })
		)
	end)

	it("should rerender when calling forceUpdate", function()
		local renderCounter = 0
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:render()
			renderCounter += 1
			return React.createElement("TextLabel")
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(renderCounter).toEqual(1)

		local instance = shallowRenderer:getMountedInstance()
		instance:forceUpdate()
		jestExpect(renderCounter).toEqual(2)
	end)

	it("should shallow render a function component", function()
		local SomeComponent = function(props, context)
			return (React.createElement("Frame", nil, {
				ChildFoo = React.createElement("TextLabel", { Text = props.foo }),
				ChildBar = React.createElement("TextLabel", { Text = context.bar }),
				Child1 = React.createElement("Frame", { Value = "child1" }),
				Child2 = React.createElement("Frame", { Value = "child2" }),
			}))
		end
		-- ROBLOX deviation: we don't support contextTypes on function components
		--     SomeComponent.contextTypes = {
		--       bar = PropTypes.string
		--     }

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(
			React.createElement(SomeComponent, { foo = "FOO" }),
			{ bar = "BAR" }
		)

		jestExpect(result.type).toEqual("Frame")
		jestExpect(result.props.children).toEqual(validate({
			ChildFoo = React.createElement("TextLabel", { Text = "FOO" }),
			ChildBar = React.createElement("TextLabel", { Text = "BAR" }),
			Child1 = React.createElement("Frame", { Value = "child1" }),
			Child2 = React.createElement("Frame", { Value = "child2" }),
		}))
	end)

	it(
		"should shallow render a component returning strings directly from render",
		function()
			local Text = function(props)
				return props.value
			end

			local shallowRenderer = createRenderer()
			local result = shallowRenderer:render(
				React.createElement(Text, { value = "foo" })
			)
			jestExpect(result).toEqual("foo")
		end
	)

	it(
		"should shallow render a component returning numbers directly from render",
		function()
			local Text = function(props)
				return props.value
			end

			local shallowRenderer = createRenderer()
			local result = shallowRenderer:render(
				React.createElement(Text, { value = 10 })
			)
			jestExpect(result).toEqual(10)
		end
	)

	it("should shallow render a fragment", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:render()
			return React.createElement("TextLabel")
		end

		local Fragment = React.Component:extend("Fragment")
		function Fragment:render()
			return {
				ChildA = React.createElement("TextLabel", { Text = "a" }),
				ChildB = React.createElement("Frame", { Value = "b" }),
				ChildC = React.createElement(SomeComponent),
			}
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(Fragment))
		jestExpect(result.ChildA).toEqual(
			React.createElement("TextLabel", { Text = "a" })
		)
		jestExpect(result.ChildB).toEqual(React.createElement("Frame", { Value = "b" }))
		jestExpect(result.ChildC).toEqual(React.createElement(SomeComponent))
		jestExpect(result).toEqual({
			ChildC = React.createElement(SomeComponent),
			ChildA = React.createElement("TextLabel", { Text = "a" }),
			ChildB = React.createElement("Frame", { Value = "b" }),
		})
	end)

	it("should shallow render a React.Fragment", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:render()
			return React.createElement("TextLabel")
		end

		local Fragment = React.Component:extend("Fragment")
		function Fragment:render()
			return React.createElement(React.Fragment, nil, {
				React.createElement("Text"),
				React.createElement("Frame"),
				React.createElement(SomeComponent),
			})
		end
		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(Fragment))
		jestExpect(result.type).toEqual(React.Fragment)

		jestExpect(#result.props.children).toEqual(3)
		jestExpect(result.props.children[1]).toEqual(
			validateElement(React.createElement("Text"))
		)
		jestExpect(result.props.children[2]).toEqual(
			validateElement(React.createElement("Frame"))
		)
		React.createElement(React.Fragment, nil, {
			React.createElement("Text"),
			React.createElement("Frame"),
			React.createElement(SomeComponent),
		})
	end)

	it("should throw for invalid elements", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:render()
			return React.createElement("TextLabel")
		end

		local shallowRenderer = createRenderer()
		jestExpect(function()
			shallowRenderer:render(SomeComponent)
		end).toThrow(
			"ReactShallowRenderer render(): Invalid component element. Instead of "
				.. "passing a component class, make sure to instantiate it by passing it "
				.. "to React.createElement."
		)
		jestExpect(function()
			shallowRenderer:render(React.createElement("div"))
		end).toThrow(
			"ReactShallowRenderer render(): Shallow rendering works only with "
				.. "custom components, not primitives (div). Instead of calling "
				.. "`.render(el)` and inspecting the rendered output, look at `el.props` "
				.. "directly instead."
		)
	end)

	it("should have shallow unmounting", function()
		local willUnmountWasCalled = false
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:componentWillUnmount()
			willUnmountWasCalled = true
		end

		function SomeComponent:render()
			return React.createElement("TextLabel")
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SomeComponent))
		shallowRenderer:unmount()

		jestExpect(willUnmountWasCalled).toEqual(true)
	end)

	it("can shallow render to nil", function()
		local SomeComponent = React.Component:extend("Component")
		function SomeComponent:render()
			return nil
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SomeComponent))

		jestExpect(result).toEqual(nil)
	end)

	it("can shallow render with a ref", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:render()
			return React.createElement("TestLabel", { ref = "hello" })
		end

		local shallowRenderer = createRenderer()
		-- Shouldn't crash.
		jestExpect(function()
			shallowRenderer:render(React.createElement(SomeComponent))
		end).never.toThrow()
	end)

	it("lets you update shallowly rendered components", function()
		local SomeComponent = React.Component:extend("SomeComponent")
		function SomeComponent:init()
			self.state = { clicked = false }
		end

		function SomeComponent:onClick()
			self:setState({ clicked = true })
		end

		function SomeComponent:render()
			local className
			if self.state.clicked then
				className = "was-clicked"
			else
				className = ""
			end

			if self.props.aNew == "prop" then
				return React.createElement("Button", {
					onClick = function()
						self:onClick()
					end,
					className = className,
				})
			else
				return React.createElement("TextLabel", nil, {
					React.createElement("Frame", { className = "child1" }),
					React.createElement("Frame", { className = "child2" }),
				})
			end
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SomeComponent))
		jestExpect(result.type).toEqual("TextLabel")
		jestExpect(result.props.children).toEqual(validate({
			React.createElement("Frame", { className = "child1" }),
			React.createElement("Frame", { className = "child2" }),
		}))

		local updatedResult = shallowRenderer:render(
			React.createElement(SomeComponent, { aNew = "prop" })
		)
		jestExpect(updatedResult.type).toEqual("Button")

		updatedResult.props:onClick()

		local updatedResultCausedByClick = shallowRenderer:getRenderOutput()
		jestExpect(updatedResultCausedByClick.type).toEqual("Button")
		jestExpect(updatedResultCausedByClick.props.className).toEqual("was-clicked")
	end)

	it("can access the mounted component instance", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:someMethod()
			return self.props.n
		end

		function SimpleComponent:render()
			return React.createElement("TextLabel", { Text = self.props.n })
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent, { n = 5 }))
		jestExpect(shallowRenderer:getMountedInstance():someMethod()).toEqual(5)
	end)

	it("can shallowly render components with contextTypes", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		SimpleComponent.contextTypes = {
			name = "string", -- ROBLOX TODO: missing PropTypes.string
		}

		function SimpleComponent:render()
			return React.createElement("TextLabel")
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result).toEqual(React.createElement("TextLabel"))
	end)

	it("passes expected params to legacy component lifecycle methods", function()
		local componentDidUpdateParams = {}
		local componentWillReceivePropsParams = {}
		local componentWillUpdateParams = {}
		local setStateParams = {}
		local shouldComponentUpdateParams = {}

		local initialProp = { prop = "init prop" }
		local initialState = { state = "init state" }
		local initialContext = { context = "init context" }
		local updatedState = { state = "updated state" }
		local updatedProp = { prop = "updated prop" }
		local updatedContext = { context = "updated context" }

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init(props, context)
			self.state = initialState
		end

		SimpleComponent.contextTypes = {
			context = "PropTypes.string",
		}

		function SimpleComponent:componentDidUpdate(...)
			table.insert(componentDidUpdateParams, { ... })
		end
		function SimpleComponent:UNSAFE_componentWillReceiveProps(...)
			table.insert(componentWillReceivePropsParams, { ... })
			self:setState(function(...)
				table.insert(setStateParams, { ... })
				return updatedState
			end)
		end
		function SimpleComponent:UNSAFE_componentWillUpdate(...)
			table.insert(componentWillUpdateParams, { ... })
		end
		function SimpleComponent:shouldComponentUpdate(...)
			table.insert(shouldComponentUpdateParams, { ... })
			return true
		end
		function SimpleComponent:render()
			return nil
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(
			React.createElement(SimpleComponent, initialProp),
			initialContext
		)
		jestExpect(componentDidUpdateParams).toEqual({})
		jestExpect(componentWillReceivePropsParams).toEqual({})
		jestExpect(componentWillUpdateParams).toEqual({})
		jestExpect(setStateParams).toEqual({})
		jestExpect(shouldComponentUpdateParams).toEqual({})

		-- Lifecycle hooks should be invoked with the correct prev/next params on update.
		shallowRenderer:render(
			React.createElement(SimpleComponent, updatedProp),
			updatedContext
		)

		jestExpect(componentWillReceivePropsParams).toEqual({
			{ updatedProp, updatedContext },
		})
		jestExpect(setStateParams).toEqual({
			{ initialState, initialProp },
		})
		jestExpect(shouldComponentUpdateParams).toEqual({
			{ updatedProp, updatedState, updatedContext },
		})
		jestExpect(componentWillUpdateParams).toEqual({
			{ updatedProp, updatedState, updatedContext },
		})
		jestExpect(componentDidUpdateParams).toEqual({})
	end)

	it("passes expected params to new component lifecycle methods", function()
		local componentDidUpdateParams = {}
		local getDerivedStateFromPropsParams = {}
		local shouldComponentUpdateParams = {}

		local initialProp = { prop = "init prop" }
		local initialState = { state = "init state" }
		local initialContext = { context = "init context" }
		local updatedProp = { prop = "updated prop" }
		local updatedContext = { context = "updated context" }

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init(props, context)
			self.state = initialState
		end

		SimpleComponent.contextTypes = {
			context = "PropTypes.string",
		}

		function SimpleComponent:componentDidUpdate(...)
			table.insert(componentDidUpdateParams, { ... })
		end

		function SimpleComponent.getDerivedStateFromProps(...)
			table.insert(getDerivedStateFromPropsParams, { ... })
			return nil
		end

		function SimpleComponent:shouldComponentUpdate(...)
			table.insert(shouldComponentUpdateParams, { ... })
			return true
		end

		function SimpleComponent:render()
			return nil
		end

		local shallowRenderer = createRenderer()

		-- The only lifecycle hook that should be invoked on initial render
		-- Is the static getDerivedStateFromProps() methods
		shallowRenderer:render(
			React.createElement(SimpleComponent, initialProp),
			initialContext
		)
		jestExpect(getDerivedStateFromPropsParams).toEqual({
			{
				initialProp,
				initialState,
			},
		})
		jestExpect(componentDidUpdateParams).toEqual({})
		jestExpect(shouldComponentUpdateParams).toEqual({})

		-- Lifecycle hooks should be invoked with the correct prev/next params on update.
		shallowRenderer:render(
			React.createElement(SimpleComponent, updatedProp),
			updatedContext
		)

		jestExpect(getDerivedStateFromPropsParams).toEqual({
			{ initialProp, initialState },
			{ updatedProp, initialState },
		})
		jestExpect(shouldComponentUpdateParams).toEqual({
			{
				updatedProp,
				initialState,
				updatedContext,
			},
		})
		jestExpect(componentDidUpdateParams).toEqual({})
	end)

	it("can shallowly render components with ref as function", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { clicked = false }
		end

		function SimpleComponent:handleUserClick()
			self:setState({ clicked = true })
		end

		function SimpleComponent:render()
			local wasClicked
			if self.state.clicked then
				wasClicked = "clicked"
			else
				wasClicked = ""
			end

			return React.createElement(SimpleComponent, {
				ref = function() end,
				onClick = function()
					self:handleUserClick()
				end,
				className = wasClicked,
			})
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent))
		local result = shallowRenderer:getRenderOutput()
		-- jestExpect(result.type).toEqual('div')
		jestExpect(result.props.className).toEqual("")
		result.props.onClick()

		result = shallowRenderer:getRenderOutput()
		-- jestExpect(result.type).toEqual('div')
		jestExpect(result.props.className).toEqual("clicked")
	end)

	it("can initialize state via static getDerivedStateFromProps", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = {
				count = 1,
			}
		end

		function SimpleComponent.getDerivedStateFromProps(props, prevState)
			return {
				count = prevState.count + props.incrementBy,
				other = "foobar",
			}
		end

		function SimpleComponent:render()
			return React.createElement(
				"TextLabel",
				nil,
				"count:" .. self.state.count .. ", other:" .. self.state.other
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(
			React.createElement(SimpleComponent, { incrementBy = 2 })
		)
		jestExpect(result).toEqual(
			React.createElement("TextLabel", nil, "count:3, other:foobar")
		)
	end)

	it("can setState in componentWillMount when shallow rendering", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:UNSAFE_componentWillMount()
			self:setState({ groovy = "doovy" })
		end

		function SimpleComponent:render()
			return React.createElement("TextLabel", { Text = self.state.groovy })
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result).toEqual(React.createElement("TextLabel", { Text = "doovy" }))
	end)

	it("can setState in componentWillMount repeatedly when shallow rendering", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { separator = "-" }
		end

		function SimpleComponent:UNSAFE_componentWillMount()
			self:setState({ groovy = "doovy" })
			self:setState({ doovy = "groovy" })
		end

		function SimpleComponent:render()
			local groovy = self.state.groovy
			local doovy = self.state.doovy
			local separator = self.state.separator

			return React.createElement(
				"TextLabel",
				{ Text = groovy .. separator .. doovy }
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result).toEqual(
			React.createElement("TextLabel", { Text = "doovy-groovy" })
		)
	end)

	it(
		"can setState in componentWillMount with an updater function repeatedly when shallow rendering",
		function()
			local SimpleComponent = React.Component:extend("SimpleComponent")
			function SimpleComponent:init()
				self.state = { separator = "-" }
			end

			function SimpleComponent:UNSAFE_componentWillMount()
				self:setState(function(state)
					return { groovy = "doovy" }
				end)
				self:setState(function(state)
					return { doovy = state.groovy }
				end)
			end

			function SimpleComponent:render()
				local groovy = self.state.groovy
				local doovy = self.state.doovy
				local separator = self.state.separator

				return React.createElement(
					"TextLabel",
					nil,
					{ groovy .. separator .. doovy }
				)
			end

			local shallowRenderer = createRenderer()
			local result = shallowRenderer:render(React.createElement(SimpleComponent))
			jestExpect(result.props.children[1]).toEqual("doovy-doovy")
		end
	)

	it("can setState in componentWillReceiveProps when shallow rendering", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { count = 0 }
		end

		function SimpleComponent:UNSAFE_componentWillReceiveProps(nextProps)
			if nextProps.updateState then
				self:setState({ count = 1 })
			end
		end

		function SimpleComponent:render()
			return React.createElement("TextLabel", nil, self.state.count)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(
			React.createElement(SimpleComponent, { updateState = false })
		)

		jestExpect(result.props.children).toEqual(0)

		result = shallowRenderer:render(
			React.createElement(SimpleComponent, { updateState = true })
		)

		jestExpect(result.props.children).toEqual(1)
	end)

	it(
		"can update state with static getDerivedStateFromProps when shallow rendering",
		function()
			local SimpleComponent = React.Component:extend("SimpleComponent")
			function SimpleComponent:init()
				self.state = { count = 1 }
			end

			function SimpleComponent.getDerivedStateFromProps(nextProps, prevState)
				if nextProps.updateState then
					return { count = nextProps.incrementBy + prevState.count }
				end

				return nil
			end

			function SimpleComponent:render()
				return React.createElement("TextLabel", nil, self.state.count)
			end

			local shallowRenderer = createRenderer()
			local result = shallowRenderer:render(
				React.createElement(
					SimpleComponent,
					{ updateState = false, incrementBy = 0 }
				)
			)

			jestExpect(result.props.children).toEqual(1)

			result = shallowRenderer:render(
				React.createElement(
					SimpleComponent,
					{ updateState = true, incrementBy = 2 }
				)
			)
			jestExpect(result.props.children).toEqual(3)

			result = shallowRenderer:render(
				React.createElement(
					SimpleComponent,
					{ updateState = false, incrementBy = 2 }
				)
			)

			jestExpect(result.props.children).toEqual(3)
		end
	)

	it(
		"should not override state with stale values if prevState is spread within getDerivedStateFromProps",
		function()
			local SimpleComponent = React.Component:extend("SimpleComponent")
			function SimpleComponent:init()
				self.state = { value = 0 }
			end

			function SimpleComponent.getDerivedStateFromProps(nextProps, prevState)
				return { table.unpack(prevState) }
			end

			function SimpleComponent:updateState()
				self:setState(function(state)
					return { value = state.value + 1 }
				end)
			end

			function SimpleComponent:render()
				return React.createElement("TextLabel", nil, "value:" .. self.state.value)
			end

			local shallowRenderer = createRenderer()
			local result = shallowRenderer:render(React.createElement(SimpleComponent))
			jestExpect(result).toEqual(React.createElement("TextLabel", nil, "value:0"))

			local instance = shallowRenderer:getMountedInstance()
			instance:updateState()
			result = shallowRenderer:getRenderOutput()
			jestExpect(result).toEqual(React.createElement("TextLabel", nil, "value:1"))
		end
	)

	it(
		"should pass previous state to shouldComponentUpdate even with getDerivedStateFromProps",
		function()
			local SimpleComponent = React.Component:extend("SimpleComponent")
			function SimpleComponent:init()
				self.state = {
					value = self.props.value,
				}
			end

			function SimpleComponent.getDerivedStateFromProps(nextProps, prevState)
				if nextProps.value == prevState.value then
					return nil
				end

				return { value = nextProps.value }
			end

			function SimpleComponent:shouldComponentUpdate(nextProps, nextState)
				return nextState.value ~= self.state.value
			end

			function SimpleComponent:render()
				return React.createElement(
					"TextLabel",
					{ Text = "value:" .. self.state.value }
				)
			end

			local shallowRenderer = createRenderer()
			local initialResult = shallowRenderer:render(
				React.createElement(SimpleComponent, { value = "initial" })
			)
			jestExpect(initialResult).toEqual(
				React.createElement("TextLabel", { Text = "value:initial" })
			)
			local updatedResult = shallowRenderer:render(
				React.createElement(SimpleComponent, { value = "updated" })
			)
			jestExpect(updatedResult).toEqual(
				React.createElement("TextLabel", { Text = "value:updated" })
			)
		end
	)

	it("can setState with an updater function", function()
		local instance

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = {
				counter = 0,
			}
		end

		function SimpleComponent:render()
			instance = self
			return (React.createElement("Button", nil, self.state.counter))
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(
			React.createElement(SimpleComponent, { defaultCount = 1 })
		)
		jestExpect(result.props.children).toEqual(0)

		instance:setState(function(state, props)
			return { counter = instance.props.defaultCount + 1 }
		end)

		result = shallowRenderer:getRenderOutput()
		jestExpect(result.props.children).toEqual(2)
	end)

	-- ROBLOX deviation: Lua doesn't have a good way to bind to the correct closure for this pattern
	-- it's okay, since it doesn't work in leacy Roact and should be okay with the useState() hook
	itSKIP("can access component instance from setState updater function", function()
		local instance

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = { something = "here" }
		end
		function SimpleComponent:render()
			instance = self
			return nil
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SimpleComponent, { myProp = 31337 }))

		local updaterWasCalled = false
		instance:setState(function(state, props)
			-- ROBLOX deviation: we deviate here. legacy Roact doesn't support this, and is moot with useState() hook
			-- jestExpect(self).toEqual(instance)
			jestExpect(state).toEqual({ something = "here" })
			jestExpect(props).toEqual({ myProp = 31337 })
			updaterWasCalled = true
		end)
		jestExpect(updaterWasCalled).toEqual(true)
	end)

	it("can setState with a callback", function()
		local instance

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = {
				counter = 0,
			}
		end
		function SimpleComponent:render()
			instance = self
			return React.createElement("Text", nil, self.state.counter)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result.props.children).toEqual(0)

		local callbackHasBeenCalled = false
		local callback = function(self)
			callbackHasBeenCalled = true
			jestExpect(self).toEqual(instance)
		end

		instance:setState({ counter = 1 }, callback)

		local updated = shallowRenderer:getRenderOutput()
		jestExpect(updated.props.children).toEqual(1)
		jestExpect(callbackHasBeenCalled).toEqual(true)
	end)

	it("can replaceState with a callback", function()
		local instance

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = {
				counter = 0,
			}
		end
		function SimpleComponent:render()
			instance = self
			return React.createElement("Text", nil, self.state.counter)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result.props.children).toEqual(0)

		local callbackHasBeenCalled = false
		local callback = function(self)
			callbackHasBeenCalled = true
			jestExpect(self).toEqual(instance)
		end

		-- No longer a public API, but we can test that it works internally by
		-- reaching into the updater.
		shallowRenderer._updater.enqueueReplaceState(instance, { counter = 1 }, callback)

		local updated = shallowRenderer:getRenderOutput()
		jestExpect(updated.props.children).toEqual(1)
		jestExpect(callbackHasBeenCalled).toEqual(true)
	end)

	it("can forceUpdate with a callback", function()
		local instance

		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init()
			self.state = {
				counter = 0,
			}
		end
		function SimpleComponent:render()
			instance = self
			return React.createElement("Text", nil, self.state.counter)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent))
		jestExpect(result.props.children).toEqual(0)

		local callbackHasBeenCalled = false
		local callback = function(self)
			callbackHasBeenCalled = true
			jestExpect(self).toEqual(instance)
		end

		instance:forceUpdate(callback)

		local updated = shallowRenderer:getRenderOutput()
		jestExpect(updated.props.children).toEqual(0)
		jestExpect(callbackHasBeenCalled).toEqual(true)
	end)

	it("can pass context when shallowly rendering", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		SimpleComponent.contextTypes = {
			name = "string",
		}

		function SimpleComponent:render()
			return React.createElement("Text", nil, self.context.name)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent), {
			name = "foo",
		})
		jestExpect(result).toEqual(React.createElement("Text", nil, "foo"))
	end)

	it("should track context across updates", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		SimpleComponent.contextTypes = {
			foo = "string",
		}

		function SimpleComponent:init()
			self.state = {
				bar = "bar",
			}
		end

		function SimpleComponent:render()
			return React.createElement(
				"Text",
				nil,
				self.context.foo .. ":" .. self.state.bar
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent), {
			foo = "foo",
		})
		jestExpect(result.props.children).toEqual("foo:bar")

		local instance = shallowRenderer:getMountedInstance()
		instance:setState({ bar = "baz" })

		result = shallowRenderer:getRenderOutput()
		jestExpect(result.props.children).toEqual("foo:baz")
	end)

	it("should filter context by contextTypes", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		SimpleComponent.contextTypes = {
			foo = "string",
		}
		function SimpleComponent:render()
			return React.createElement(
				"Text",
				nil,
				self.context.foo .. ":" .. tostring(self.context.bar)
			)
		end

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(React.createElement(SimpleComponent), {
			foo = "foo",
			bar = "bar",
		})
		jestExpect(result.props.children).toEqual("foo:nil")
	end)

	-- ROBLOX TODO: we'll need prop-types ported for this to pass
	itSKIP("can fail context when shallowly rendering", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		SimpleComponent.contextTypes = {
			name = "PropTypes.string.isRequired",
		}

		function SimpleComponent:render()
			return React.createElement("Text", nil, self.context.name)
		end

		local shallowRenderer = createRenderer()
		jestExpect(function()
			shallowRenderer:render(React.createElement(SimpleComponent))
		end).toThrow(
			"Warning: Failed context type: The context `name` is marked as "
				.. "required in `SimpleComponent`, but its value is `undefined`.\n"
				.. "    in SimpleComponent (at **)"
		)
	end)

	-- ROBLOX TODO: we'll need prop-types ported for this to pass
	itSKIP("should warn about propTypes (but only once)", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:render()
			return React.createElement("Text", nil, self.props.name)
		end

		SimpleComponent.propTypes = {
			name = "PropTypes.string.isRequired",
		}

		local shallowRenderer = createRenderer()
		jestExpect(function()
			shallowRenderer:render(React.createElement(SimpleComponent, { name = 123 }))
		end).toThrow()
		-- ROBLOX TODO: port toErrorDev to jest-roblox matchers
		-- ).toErrorDev(
		--   'Warning: Failed prop type: Invalid prop `name` of type `number` ' +
		--     'supplied to `SimpleComponent`, expected `string`.\n' +
		--     '    in SimpleComponent',
		-- )
	end)

	it("should enable rendering of cloned element", function()
		local SimpleComponent = React.Component:extend("SimpleComponent")
		function SimpleComponent:init(props)
			self.state = {
				bar = "bar",
			}
		end

		function SimpleComponent:render()
			return React.createElement(
				"Text",
				nil,
				self.props.foo .. ":" .. self.state.bar
			)
		end

		local shallowRenderer = createRenderer()
		local el = React.createElement(SimpleComponent, { foo = "foo" })
		local result = shallowRenderer:render(el)
		jestExpect(result.props.children).toEqual("foo:bar")

		local cloned = React.cloneElement(el, { foo = "baz" })
		result = shallowRenderer:render(cloned)
		jestExpect(result.props.children).toEqual("baz:bar")
	end)

	it(
		"self.state should be updated on setState callback inside componentWillMount",
		function()
			local stateSuccessfullyUpdated = false

			local MyComponent = React.Component:extend("Component")
			function MyComponent:init(props, context)
				self.state = {
					hasUpdatedState = false,
				}
			end

			function MyComponent:UNSAFE_componentWillMount()
				self:setState({ hasUpdatedState = true }, function()
					stateSuccessfullyUpdated = self.state.hasUpdatedState
				end)
			end

			function MyComponent:render()
				return React.createElement("Text", nil, self.props.children)
			end

			local shallowRenderer = createRenderer()
			shallowRenderer:render(React.createElement(MyComponent))
			jestExpect(stateSuccessfullyUpdated).toEqual(true)
		end
	)

	it("should handle multiple callbacks", function()
		local mockCalledTimes = 0
		local mockFn = function()
			mockCalledTimes += 1
		end
		local shallowRenderer = createRenderer()

		local Component = React.Component:extend("Component")
		function Component:init(props, context)
			self.state = {
				foo = "foo",
			}
		end

		function Component:UNSAFE_componentWillMount()
			self:setState({ foo = "bar" }, mockFn)
			self:setState({ foo = "foobar" }, mockFn)
		end

		function Component:render()
			return React.createElement("Text", nil, self.state.foo)
		end

		shallowRenderer:render(React.createElement(Component))

		jestExpect(mockCalledTimes).toEqual(2)

		-- Ensure the callback queue is cleared after the callbacks are invoked
		local mountedInstance = shallowRenderer:getMountedInstance()
		mountedInstance:setState({ foo = "bar" }, function()
			mockFn()
		end)
		jestExpect(mockCalledTimes).toEqual(3)
	end)

	it(
		"should call the setState callback even if shouldComponentUpdate = false",
		function()
			local mockCalledTimes = 0
			local mockFn = function()
				mockCalledTimes += 1
				return false
			end

			local Component = React.Component:extend("Component")
			function Component:init(props, context)
				self.state = {
					hasUpdatedState = false,
				}
			end

			function Component:shouldComponentUpdate()
				return mockFn()
			end

			function Component:render()
				return React.createElement("Text", nil, self.state.hasUpdatedState)
			end

			local shallowRenderer = createRenderer()
			shallowRenderer:render(React.createElement(Component))

			local callbackWasCalled = false
			local mountedInstance = shallowRenderer:getMountedInstance()
			mountedInstance:setState({ hasUpdatedState = true }, function()
				jestExpect(mockCalledTimes).toEqual(1)
				jestExpect(mountedInstance.state.hasUpdatedState).toEqual(true)
				callbackWasCalled = true
			end)
			jestExpect(callbackWasCalled).toEqual(true)
		end
	)

	it("throws usefully when rendering badly-typed elements", function()
		local shallowRenderer = createRenderer()

		local renderAndVerifyWarningAndError = function(Component, typeString)
			jestExpect(function()
				-- jestExpect(function()
				shallowRenderer:render(React.createElement(Component))
				-- end)
				-- ROBLOX TODO: port toErrorDev matcher to jest
				-- .toErrorDev(
				--   'React.createElement: type is invalid -- expected a string ' ..
				--     '(for built-in components) or a class/function (for composite components) ' ..
				--     'but got: ' .. typeString .. '.'
				-- )
			end).toThrow(
				"ReactShallowRenderer render(): Shallow rendering works only with custom "
					.. "components, but the provided element type was `"
					.. typeString
					.. "`."
			)
		end

		-- ROBLOX deviation: no undefined in Lua, only nil
		-- renderAndVerifyWarningAndError(undefined, 'undefined')
		renderAndVerifyWarningAndError(nil, "nil")
		renderAndVerifyWarningAndError({}, "array")
	end)

	-- ROBLOX DEVIATION: We initialize state to a singleton for compatibility
	it("should have initial state of UninitializedState if not defined", function()
		local SomeComponent = React.Component:extend("Component")
		function SomeComponent:render()
			return React.createElement("Text")
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(SomeComponent))

		jestExpect(shallowRenderer:getMountedInstance().state).toBe(UninitializedState)
	end)

	it("should invoke both deprecated and new lifecycles if both are present", function()
		local logs = {}
		local logger = function(message)
			return function()
				table.insert(logs, message)
				return true
			end
		end

		local Component = React.Component:extend("Component")
		Component.componentWillMount = logger("componentWillMount")

		Component.componentWillReceiveProps = logger("componentWillReceiveProps")
		Component.componentWillUpdate = logger("componentWillUpdate")
		Component.UNSAFE_componentWillMount = logger("UNSAFE_componentWillMount")
		Component.UNSAFE_componentWillReceiveProps = logger(
			"UNSAFE_componentWillReceiveProps"
		)
		Component.UNSAFE_componentWillUpdate = logger("UNSAFE_componentWillUpdate")

		function Component:render()
			return React.createElement("Text")
		end

		local shallowRenderer = createRenderer()
		jestExpect(logs).toEqual({})
		shallowRenderer:render(React.createElement(Component, { foo = "bar" }))
		jestExpect(logs).toEqual({ "componentWillMount", "UNSAFE_componentWillMount" })

		Array.splice(logs, 1)

		shallowRenderer:render(React.createElement(Component, { foo = "baz" }))
		jestExpect(logs).toEqual({
			"componentWillReceiveProps",
			"UNSAFE_componentWillReceiveProps",
			"componentWillUpdate",
			"UNSAFE_componentWillUpdate",
		})
	end)

	it("should stop the update when setState returns nil or undefined", function()
		local logs = {}
		local instance
		local Component = React.Component:extend("Component")
		function Component:init(props)
			self.state = {
				count = 0,
			}
		end
		function Component:render()
			table.insert(logs, "render")
			instance = self
			return nil
		end
		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Component))
		Array.splice(logs, 1)
		instance:setState(function()
			return nil
		end)
		-- ROBLOX deviation: no undefined in Lua, no different than nil
		-- instance:setState(() => undefined)
		instance:setState(nil)
		-- ROBLOX deviation: no undefined in Lua, no different than nil
		-- instance:setState(undefined)
		jestExpect(logs).toEqual({})
		instance:setState(function(state)
			return { count = state.count + 1 }
		end)
		jestExpect(logs).toEqual({ "render" })
	end)

	it("should not get this in a function component", function()
		local logs = {}
		local self = nil
		local Foo = function()
			table.insert(logs, self)
			return React.createElement("Text", nil, "foo")
		end
		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Foo, { foo = "bar" }))
		jestExpect(logs).toEqual({ nil })
	end)

	it("should handle memo", function()
		local Foo = function()
			return React.createElement("Text")
		end
		local MemoFoo = React.memo(Foo)
		local shallowRenderer = createRenderer()
		local renderOutput = shallowRenderer:render(React.createElement(MemoFoo))
		jestExpect(renderOutput).toEqual(React.createElement("Text"))
	end)

	it("should enable React.memo to prevent a re-render", function()
		local logs = {}
		local Foo = React.memo(function(props)
			table.insert(logs, "Foo: " .. props.count)
			return React.createElement("Text", nil, props.count)
		end)
		local Bar = React.memo(function(props)
			table.insert(logs, "Bar: " .. props.count)
			return React.createElement("Text", nil, props.count)
		end)
		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Foo, { count = 1 }))
		jestExpect(logs).toEqual({ "Foo: 1" })
		Array.splice(logs, 1)
		-- Rendering the same element with the same props should be prevented
		shallowRenderer:render(React.createElement(Foo, { count = 1 }))
		jestExpect(logs).toEqual({})
		-- A different element with the same props should cause a re-render
		shallowRenderer:render(React.createElement(Bar, { count = 1 }))
		jestExpect(logs).toEqual({ "Bar: 1" })
	end)

	it("should respect a custom comparison function with React.memo", function()
		local renderCount = 0
		local areEqual = function(props, nextProps)
			return props.foo == nextProps.foo
		end
		local Foo = React.memo(function(props)
			renderCount += 1
			return React.createElement(
				"Text",
				nil,
				tostring(props.foo) .. tostring(props.bar)
			)
		end, areEqual)

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Foo, { foo = 1, bar = 1 }))
		jestExpect(renderCount).toEqual(1)
		-- Change a prop that the comparison funciton ignores
		shallowRenderer:render(React.createElement(Foo, { foo = 1, bar = 2 }))
		jestExpect(renderCount).toEqual(1)
		shallowRenderer:render(React.createElement(Foo, { foo = 2, bar = 2 }))
		jestExpect(renderCount).toEqual(2)
	end)

	it(
		"should not call the comparison function with React.memo on the initial render",
		function()
			local comparisonWasCalled = false
			local areEqual = function()
				comparisonWasCalled = true
				return false
			end
			local SomeComponent = React.memo(function(props)
				return React.createElement("Text", nil, props.foo)
			end, areEqual)
			local shallowRenderer = createRenderer()
			shallowRenderer:render(React.createElement(SomeComponent, { foo = 1 }))
			jestExpect(comparisonWasCalled).toEqual(false)
			jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual(1)
		end
	)

	it("should handle memo(forwardRef())", function()
		local testRef = React.createRef()
		local SomeComponent = React.forwardRef(function(props, ref)
			jestExpect(ref).toEqual(testRef)
			return React.createElement("Frame", nil, {
				React.createElement("Text", { className = "child1" }),
				React.createElement("Text", { className = "child2" }),
			})
		end)

		local SomeMemoComponent = React.memo(SomeComponent)

		local shallowRenderer = createRenderer()
		local result = shallowRenderer:render(
			React.createElement(SomeMemoComponent, { ref = testRef })
		)

		jestExpect(result.type).toEqual("Frame")
		jestExpect(result.props.children).toEqual(validate({
			React.createElement("Text", { className = "child1" }),
			React.createElement("Text", { className = "child2" }),
		}))
	end)

	it("should warn for forwardRef(memo())", function()
		local testRef = React.createRef()
		local SomeMemoComponent = React.memo(function(props)
			return React.createElement("Text", nil, props.foo)
		end)
		local shallowRenderer = createRenderer()
		jestExpect(function()
			-- jestExpect(function()
			local SomeComponent = React.forwardRef(SomeMemoComponent)
			shallowRenderer:render(React.createElement(SomeComponent, { ref = testRef }))
			-- ROBLOX TODO: port toErrorDev to jest-roblox matchers
			-- end).toErrorDev(
			--   'Warning: forwardRef requires a render function but received ' +
			--     'a `memo` component. Instead of forwardRef(memo(...)), use ' +
			--     'memo(forwardRef(...))',
			--   {withoutStack = true}
			-- )
		end).toThrow(
			-- ROBLOX deviaton: we say table instead of object due to typeof
			"forwardRef requires a render function but was given table."
		)
	end)

	it("should let you change type", function()
		local Foo = function(props)
			return React.createElement("Text", nil, "Foo " .. props.prop)
		end
		local Bar = function(props)
			return React.createElement("Text", nil, "Bar " .. props.prop)
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Foo, { prop = "foo1" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Foo foo1")
		shallowRenderer:render(React.createElement(Foo, { prop = "foo2" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Foo foo2")
		shallowRenderer:render(React.createElement(Bar, { prop = "bar1" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Bar bar1")
		shallowRenderer:render(React.createElement(Bar, { prop = "bar2" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Bar bar2")
	end)

	it("should local you change class type", function()
		local Foo = React.Component:extend("Component")
		function Foo:render()
			return React.createElement("Text", nil, "Foo " .. self.props.prop)
		end

		local Bar = React.Component:extend("Component")
		function Bar:render()
			return React.createElement("Text", nil, "Bar " .. self.props.prop)
		end

		local shallowRenderer = createRenderer()
		shallowRenderer:render(React.createElement(Foo, { prop = "foo1" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Foo foo1")
		shallowRenderer:render(React.createElement(Foo, { prop = "foo2" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Foo foo2")
		shallowRenderer:render(React.createElement(Bar, { prop = "bar1" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Bar bar1")
		shallowRenderer:render(React.createElement(Bar, { prop = "bar2" }))
		jestExpect(shallowRenderer:getRenderOutput().props.children).toEqual("Bar bar2")
	end)
end
