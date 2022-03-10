-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-reconciler/src/__tests__/ReactNewContext-test.js
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
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error

local React
local useContext
local ReactNoop
local Scheduler
-- local gen

return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	beforeEach(function()
		RobloxJest.resetModules()
		RobloxJest.useFakeTimers()

		React = require(Packages.React)
		useContext = React.useContext
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Scheduler)
		-- gen = nil -- require('random-seed')
	end)

	local function span(prop)
		return { type = "span", prop = prop, children = {}, hidden = false }
	end

	local function Text(props)
		Scheduler.unstable_yieldValue(props.text)
		return React.createElement("span", {
			prop = props.text,
		})
	end

	local function readContext(Context, observedBits)
		local dispatcher = React.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentDispatcher.current
		return dispatcher.readContext(Context, observedBits)
	end

	-- Note: This is based on a similar component we use in www. We can delete
	-- once the extra div wrapper is no longer necessary.
	local function LegacyHiddenDiv(props)
		local children, mode = props.children, props.mode

		return React.createElement("div", {
			hidden = mode == "hidden",
		}, React.createElement(
			React.unstable_LegacyHidden,
			{
				mode = (function()
					if mode == "hidden" then
						return "unstable-defer-without-hiding"
					end

					return mode
				end)(),
			},
			children
		))
	end

	local function sharedContextTests(label, getConsumer)
		describe("reading context with " .. label, function()
			it("simple mount and update", function()
				local Context = React.createContext(1)
				local Consumer = getConsumer(Context)

				local Indirection = React.Fragment

				local function App(props)
					return React.createElement(
						Context.Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer, nil, function(value)
								return React.createElement("span", { prop = "Result: " .. tostring(value) })
							end))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 3") })
			end)

			it("propagates through shouldComponentUpdate false", function()
				local Context = React.createContext(1)
				local ContextConsumer = getConsumer(Context)

				local function Provider(props)
					Scheduler.unstable_yieldValue("Provider")
					return React.createElement(Context.Provider, { value = props.value }, props.children)
				end

				local function Consumer(props)
					Scheduler.unstable_yieldValue("Consumer")
					return React.createElement(ContextConsumer, nil, function(value)
						Scheduler.unstable_yieldValue("Consumer render prop")
						return React.createElement("span", { prop = "Result: " .. tostring(value) })
					end)
				end

				local Indirection = React.Component:extend("Indirection")

				function Indirection:shouldComponentUpdate()
					return false
				end
				function Indirection:render()
					Scheduler.unstable_yieldValue("Indirection")
					return self.props.children
				end

				local function App(props)
					Scheduler.unstable_yieldValue("App")
					return React.createElement(
						Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Indirection",
					"Indirection",
					"Consumer",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 3") })
			end)

			it("consumers bail out if context value is the same", function()
				local Context = React.createContext(1)
				local ContextConsumer = getConsumer(Context)

				local function Provider(props)
					Scheduler.unstable_yieldValue("Provider")
					return React.createElement(Context.Provider, { value = props.value }, props.children)
				end

				local function Consumer(props)
					Scheduler.unstable_yieldValue("Consumer")
					return React.createElement(ContextConsumer, nil, function(value)
						Scheduler.unstable_yieldValue("Consumer render prop")
						return React.createElement("span", { prop = "Result: " .. tostring(value) })
					end)
				end

				local Indirection = React.Component:extend("Indirection")

				function Indirection:shouldComponentUpdate()
					return false
				end
				function Indirection:render()
					Scheduler.unstable_yieldValue("Indirection")
					return self.props.children
				end

				local function App(props)
					Scheduler.unstable_yieldValue("App")
					return React.createElement(
						Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Indirection",
					"Indirection",
					"Consumer",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })

				-- Update with the same context value
				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					-- Don't call render prop again
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })
			end)

			it("nested providers", function()
				local Context = React.createContext(1)
				local Consumer = getConsumer(Context)

				local function Provider(props)
					return React.createElement(Consumer, nil, function(contextValue: number)
						-- Multiply previous context value by 2, unless prop overrides
						return React.createElement(
							Context.Provider,
							{ value = props.value or contextValue * 2 },
							props.children
						)
					end)
				end

				local Indirection = React.Component:extend("Indirection")

				function Indirection:shouldComponentUpdate()
					return false
				end
				function Indirection:render()
					return self.props.children
				end

				local function App(props)
					return React.createElement(
						Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(
								Provider,
								nil,
								React.createElement(
									Indirection,
									nil,
									React.createElement(
										Provider,
										nil,
										React.createElement(
											Indirection,
											nil,
											React.createElement(Consumer, nil, function(value)
												return React.createElement(
													"span",
													{ prop = "Result: " .. tostring(value) }
												)
											end)
										)
									)
								)
							)
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 8") })

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 12") })
			end)

			it("should provide the correct (default) values to consumers outside of a provider", function()
				local FooContext = React.createContext({ value = "foo-initial" })
				local BarContext = React.createContext({ value = "bar-initial" })
				local FooConsumer = getConsumer(FooContext)
				local BarConsumer = getConsumer(BarContext)

				local function Verify(props)
					local actual, expected = props[1], props[2]
					jestExpect(expected).toBe(actual)
					return nil
				end

				ReactNoop.render({
					React.createElement(
						BarContext.Provider,
						{ value = { value = "bar-updated" } },
						React.createElement(BarConsumer, nil, function(value)
							return React.createElement(Verify, { actual = value, expected = "bar-updated" })
						end),
						React.createElement(
							FooContext.Provider,
							{ value = { value = "foo-updated" } },
							React.createElement(FooConsumer, nil, function(value)
								return React.createElement(Verify, { actual = value, expected = "foo-updated" })
							end)
						)
					),
					React.createElement(FooConsumer, nil, function(value)
						return React.createElement(Verify, { actual = value, expected = "foo-initial" })
					end),
					React.createElement(BarConsumer, nil, function(value)
						return React.createElement(Verify, { actual = value, expected = "bar-initial" })
					end),
				})
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)

			it("multiple consumers in different branches", function()
				local Context = React.createContext(1)
				local Consumer = getConsumer(Context)

				local function Provider(props)
					return React.createElement(Context.Consumer, nil, function(contextValue: number)
						-- Multiply previous context value by 2, unless prop overrides
						return React.createElement(
							Context.Provider,
							{ value = props.value or contextValue * 2 },
							props.children
						)
					end)
				end

				local Indirection = React.Component:extend("Indirection")
				function Indirection:shouldComponentUpdate()
					return false
				end
				function Indirection:render()
					return self.props.children
				end

				local function App(props)
					return React.createElement(
						Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(
								Indirection,
								nil,
								React.createElement(Provider, nil, React.createElement(Consumer, nil, function(value)
									return React.createElement("span", { prop = "Result: " .. value })
								end))
							),
							React.createElement(Indirection, nil, React.createElement(Consumer, nil, function(value)
								return React.createElement("span", { prop = "Result: " .. value })
							end))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Result: 4"),
					span("Result: 2"),
				})

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Result: 6"),
					span("Result: 3"),
				})

				-- Another update
				ReactNoop.render(React.createElement(App, { value = 4 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("Result: 8"),
					span("Result: 4"),
				})
			end)

			it("compares context values with Object.is semantics", function()
				local Context = React.createContext(1)
				local ContextConsumer = getConsumer(Context)

				local function Provider(props)
					Scheduler.unstable_yieldValue("Provider")
					return React.createElement(Context.Provider, {
						value = props.value,
					}, props.children)
				end

				local function Consumer(props)
					Scheduler.unstable_yieldValue("Consumer")
					return React.createElement(ContextConsumer, nil, function(value)
						Scheduler.unstable_yieldValue("Consumer render prop")
						return React.createElement("span", {
							prop = "Result: " .. value,
						})
					end)
				end

				local Indirection = React.Component:extend("Indirection")

				function Indirection:shouldComponentUpdate()
					return false
				end

				function Indirection:render()
					Scheduler.unstable_yieldValue("Indirection")
					return self.props.children
				end

				local function App(props)
					Scheduler.unstable_yieldValue("App")
					return React.createElement(
						Provider,
						{
							value = props.value,
						},
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer))
						)
					)
				end

				ReactNoop.render(React.createElement(App, {
					-- deviation: string NaN in place of NaN
					value = "NaN",
				}))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Indirection",
					"Indirection",
					"Consumer",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: NaN") })

				-- Update
				ReactNoop.render(React.createElement(App, {
					-- deviation: string NaN in place of NaN
					value = "NaN",
				}))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					-- Consumer should not re-render again
					-- 'Consumer render prop',
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: NaN") })
			end)

			it("context unwinds when interrupted", function()
				local Context = React.createContext("Default")
				local ContextConsumer = getConsumer(Context)

				local function Consumer(props)
					return React.createElement(ContextConsumer, nil, function(value)
						return React.createElement("span", {
							prop = "Result: " .. value,
						})
					end)
				end

				local function BadRender()
					error(Error.new("Bad render"))
				end

				local ErrorBoundary = React.Component:extend("ErrorBoundary")

				-- deviation: Lua nil values in table don't result in entry
				-- deviation: error is a Lua reserved word, converted to error_
				function ErrorBoundary:init()
					self.state = { error_ = "" }
				end

				function ErrorBoundary:componentDidCatch(error_)
					self.setState({
						-- deviation: error is a Lua reserved word, converted to error_
						error_ = error_,
					})
				end

				function ErrorBoundary:render()
					if self.state.error_ then
						return nil
					end

					return self.props.children
				end
				local function App(props)
					return React.createElement(React.Fragment, nil, React.createElement(Context.Provider, {
						value = "Does not unwind",
					}, React.createElement(
						ErrorBoundary,
						nil,
						React.createElement(Context.Provider, {
							value = "Unwinds after BadRender throws",
						}, React.createElement(
							BadRender,
							nil
						))
					), React.createElement(
						Consumer,
						nil
					)))
				end

				ReactNoop.render(React.createElement(App, {
					value = "A",
				}))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({
					-- The second provider should use the default value.
					span("Result: Does not unwind"),
				})
			end)

			-- ROBLOX note: deleted two tests relating to unstable_observedBits, which is removed in React 18

			it("does not re-render if there's an update in a child", function()
				local Context = React.createContext(0)
				local Consumer = getConsumer(Context)
				local child

				local Child = React.Component:extend("Child")
				function Child:init()
					self.state = {
						step = 0,
					}
				end

				function Child:render()
					Scheduler.unstable_yieldValue("Child")
					return React.createElement("span", {
						prop = "Context: " .. tostring(self.props.context) .. ", Step: " .. tostring(self.state.step),
					})
				end

				local function App(props)
					return React.createElement(Context.Provider, {
						value = props.value,
					}, React.createElement(
						Consumer,
						nil,
						function(value)
							Scheduler.unstable_yieldValue("Consumer render prop")
							return React.createElement(Child, {
								ref = function(inst)
									child = inst
									return child
								end,
								context = value,
							})
						end
					))
				end

				-- Initial mount
				ReactNoop.render(React.createElement(App, {
					value = 1,
				}))
				jestExpect(Scheduler).toFlushAndYield({ "Consumer render prop", "Child" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Context: 1, Step: 0") })
				child:setState({
					step = 1,
				})
				jestExpect(Scheduler).toFlushAndYield({ "Child" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Context: 1, Step: 1") })
			end)

			it("consumer bails out if value is unchanged and something above bailed out", function()
				local Context = React.createContext(0)
				local Consumer = getConsumer(Context)

				local function renderChildValue(value)
					Scheduler.unstable_yieldValue("Consumer")
					return React.createElement("span", {
						prop = value,
					})
				end

				local function ChildWithInlineRenderCallback()
					Scheduler.unstable_yieldValue("ChildWithInlineRenderCallback")
					-- Note: we are intentionally passing an inline arrow. Don't refactor.
					return React.createElement(Consumer, nil, function(value)
						return renderChildValue(value)
					end)
				end

				local function ChildWithCachedRenderCallback()
					Scheduler.unstable_yieldValue("ChildWithCachedRenderCallback")
					return React.createElement(Consumer, nil, renderChildValue)
				end

				local PureIndirection = React.PureComponent:extend("PureIndirection")
				function PureIndirection:render()
					Scheduler.unstable_yieldValue("PureIndirection")
					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(ChildWithInlineRenderCallback),
						React.createElement(ChildWithCachedRenderCallback)
					)
				end

				local App = React.Component:extend("App")
				function App:render()
					Scheduler.unstable_yieldValue("App")
					return React.createElement(Context.Provider, {
						value = self.props.value,
					}, React.createElement(
						PureIndirection,
						nil
					))
				end

				-- Initial mount
				ReactNoop.render(React.createElement(App, {
					value = 1,
				}))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"PureIndirection",
					"ChildWithInlineRenderCallback",
					"Consumer",
					"ChildWithCachedRenderCallback",
					"Consumer",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span(1), span(1) })

				-- Update (bailout)
				ReactNoop.render(React.createElement(App, {
					value = 1,
				}))
				jestExpect(Scheduler).toFlushAndYield({ "App" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span(1), span(1) })

				-- Update (no bailout)
				ReactNoop.render(React.createElement(App, {
					value = 2,
				}))
				jestExpect(Scheduler).toFlushAndYield({ "App", "Consumer", "Consumer" })
				jestExpect(ReactNoop.getChildren()).toEqual({ span(2), span(2) })
			end)

			-- @gate experimental || www
			it("context consumer doesn't bail out inside hidden subtree", function()
				local Context = React.createContext("dark")
				local Consumer = getConsumer(Context)

				local function App(ref)
					local theme = ref.theme
					return React.createElement(Context.Provider, {
						value = theme,
					}, React.createElement(
						LegacyHiddenDiv,
						{
							mode = "hidden",
						},
						React.createElement(Consumer, nil, function(value)
							return React.createElement(Text, {
								text = value,
							})
						end)
					))
				end

				ReactNoop.render(React.createElement(App, {
					theme = "dark",
				}))
				jestExpect(Scheduler).toFlushAndYield({ "dark" })
				-- ROBLOX deviation: noop children are in a different format
				jestExpect(ReactNoop.getChildren()[1].children[1]).toEqual(span("dark"))
				ReactNoop.render(React.createElement(App, {
					theme = "light",
				}))
				jestExpect(Scheduler).toFlushAndYield({ "light" })
				jestExpect(ReactNoop.getChildren()[1].children[1]).toEqual(span("light"))
			end)

			-- This is a regression case for https://github.com/facebook/react/issues/12389.
			it("does not run into an infinite loop", function()
				local Context = React.createContext(nil)
				local Consumer = getConsumer(Context)

				local App = React.Component:extend("App")
				function App:renderItem(id)
					return React.createElement("span", { key = id }, React.createElement(Consumer, nil, function()
						return React.createElement("span", nil, "inner")
					end), React.createElement(
						"span",
						nil,
						"outer"
					))
				end
				function App:renderList()
					local list = Array.map({ 1, 2 }, function(id)
						return self.renderItem(id)
					end)
					if self.props.reverse then
						Array.reverse(list)
					end
					return list
				end
				function App:render()
					return React.createElement(Context.Provider, { value = {} }, self:renderList())
				end

				ReactNoop.render(React.createElement(App, { reverse = false }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				ReactNoop.render(React.createElement(App, { reverse = true }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				ReactNoop.render(React.createElement(App, { reverse = false }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)

			-- This is a regression case for https://github.com/facebook/react/issues/12686
			it("does not skip some siblings", function()
				local StaticContent, Indirection
				local Context = React.createContext(0)
				local ContextConsumer = getConsumer(Context)

				local App = React.Component:extend("App")
				function App:init()
					self.state = { step = 0 }
				end

				function App:render()
					Scheduler.unstable_yieldValue("App")
					return React.createElement(
						Context.Provider,
						{ value = self.state.step },
						React.createElement(StaticContent),
						self.state.step > 0 and React.createElement(Indirection)
					)
				end

				StaticContent = React.PureComponent:extend("StaticContent")
				function StaticContent:render()
					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(
							React.Fragment,
							nil,
							React.createElement("span", { prop = "static 1" }),
							React.createElement("span", { prop = "static 2" })
						)
					)
				end

				Indirection = React.PureComponent:extend("Indirection")
				function Indirection:render()
					return (React.createElement(ContextConsumer, nil, function(value)
						Scheduler.unstable_yieldValue("Consumer")
						return React.createElement("span", { prop = value })
					end))
				end

				-- Initial mount
				local inst
				ReactNoop.render(React.createElement(App, {
					ref = function(ref)
						inst = ref
					end,
				}))
				jestExpect(Scheduler).toFlushAndYield({ "App" })
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("static 1"),
					span("static 2"),
				})
				-- Update the first time
				inst:setState({ step = 1 })
				jestExpect(Scheduler).toFlushAndYield({ "App", "Consumer" })
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("static 1"),
					span("static 2"),
					span(1),
				})
				-- Update the second time
				inst:setState({ step = 2 })
				jestExpect(Scheduler).toFlushAndYield({ "App", "Consumer" })
				jestExpect(ReactNoop.getChildren()).toEqual({
					span("static 1"),
					span("static 2"),
					span(2),
				})
			end)
		end)

		-- ROBLOX deviation: tests for our temporary compatibility with old Roact's ability to use props = {render = <func>}
		describe("Compatibility with old Roact's Context Consumer API", function()
			it("simple mount and update", function()
				local Context = React.createContext(1)
				local Consumer = Context.Consumer

				local Indirection = React.Fragment

				local function App(props)
					return React.createElement(
						Context.Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer, {render = function(value)
								return React.createElement("span", { prop = "Result: " .. tostring(value) })
							end}))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushWithoutYielding()
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 3") })
			end)

			it("propagates through shouldComponentUpdate false", function()
				local Context = React.createContext(1)
				local ContextConsumer = Context.Consumer

				local function Provider(props)
					Scheduler.unstable_yieldValue("Provider")
					return React.createElement(Context.Provider, { value = props.value }, props.children)
				end

				local function Consumer(props)
					Scheduler.unstable_yieldValue("Consumer")
					return React.createElement(ContextConsumer, {render = function(value)
						Scheduler.unstable_yieldValue("Consumer render prop")
						return React.createElement("span", { prop = "Result: " .. tostring(value) })
					end})
				end

				local Indirection = React.Component:extend("Indirection")

				function Indirection:shouldComponentUpdate()
					return false
				end
				function Indirection:render()
					Scheduler.unstable_yieldValue("Indirection")
					return self.props.children
				end

				local function App(props)
					Scheduler.unstable_yieldValue("App")
					return React.createElement(
						Provider,
						{ value = props.value },
						React.createElement(
							Indirection,
							nil,
							React.createElement(Indirection, nil, React.createElement(Consumer))
						)
					)
				end

				ReactNoop.render(React.createElement(App, { value = 2 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Indirection",
					"Indirection",
					"Consumer",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 2") })

				-- Update
				ReactNoop.render(React.createElement(App, { value = 3 }))
				jestExpect(Scheduler).toFlushAndYield({
					"App",
					"Provider",
					"Consumer render prop",
				})
				jestExpect(ReactNoop.getChildren()).toEqual({ span("Result: 3") })
			end)
		end)
	end

	-- We have several ways of reading from context. sharedContextTests runs
	-- a suite of tests for a given context consumer implementation.
	sharedContextTests("Context.Consumer", function(Context)
		return Context.Consumer
	end)
	sharedContextTests("useContext inside function component", function(Context)
		return function(props)
			local contextValue = useContext(Context)
			local render = props.children
			return render(contextValue)
		end
	end)
	sharedContextTests("useContext inside forwardRef component", function(Context)
		return React.forwardRef(function(props, ref)
			local contextValue = useContext(Context)
			local render = props.children
			return render(contextValue)
		end)
	end)

	sharedContextTests("useContext inside memoized function component", function(Context)
		return React.memo(function(props)
			local contextValue = useContext(Context)
			local render = props.children
			return render(contextValue)
		end)
	end)
	sharedContextTests("readContext(Context) inside class component", function(Context)
		local Consumer = React.Component:extend("Consumer")

		function Consumer:render()
			local contextValue = readContext(Context)
			local render = self.props.children
			return render(contextValue)
		end
		return Consumer
	end)
	sharedContextTests("readContext(Context) inside pure class component", function(Context)
		local Consumer = React.PureComponent:extend("Consumer")

		function Consumer:render()
			local contextValue = readContext(Context)
			local render = self.props.children
			return render(contextValue)
		end
		return Consumer
	end)

	describe("Context.Provider", function()
		it("warns if no value prop provided", function()
			local Context = React.createContext()

			ReactNoop.render(
				React.createElement(Context.Provider, { anyPropNameOtherThanValue = "value could be anything" })
			)

			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev(
				"The `value` prop is required for the `<Context.Provider>`. Did you misspell it or forget to pass it?",
				{
					withoutStack = true,
				}
			)
		end)

		it("warns if multiple renderers concurrently render the same context", function()
			local Context = React.createContext(0)

			local function Foo(props)
				Scheduler.unstable_yieldValue("Foo")
				return nil
			end

			local function App(props)
				return (React.createElement(Context.Provider, { value = props.value }, {
					-- ROBLOX deviation: add key prop so we get the correct warning
					React.createElement(Foo, {key = 1}),
					React.createElement(Foo, {key = 2}),
				}))
			end

			ReactNoop.render(React.createElement(App, { value = 1 }))
			-- Render past the Provider, but don't commit yet
			jestExpect(Scheduler).toFlushAndYieldThrough({ "Foo" })

			-- Get a new copy of ReactNoop
			RobloxJest.resetModules()

			React = require(Packages.React)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)
			Scheduler = require(Packages.Scheduler)

			-- Render the provider again using a different renderer
			ReactNoop.render(React.createElement(App, { value = 1 }))

			-- ROBLOX deviation: use toErrorDev
			jestExpect(function()
				jestExpect(Scheduler).toFlushAndYield({ "Foo", "Foo" })
			end).toErrorDev(
				"Detected multiple renderers concurrently rendering the same "
					.. "context provider. This is currently unsupported"
			)
		end)

		it("provider bails out if children and value are unchanged (like sCU)", function()
			local Context = React.createContext(0)

			local function Child()
				Scheduler.unstable_yieldValue("Child")
				return React.createElement("span", { prop = "Child" })
			end

			local children = React.createElement(Child)

			local function App(props)
				Scheduler.unstable_yieldValue("App")
				return React.createElement(Context.Provider, { value = props.value }, children)
			end

			-- Initial mount
			ReactNoop.render(React.createElement(App, { value = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "App", "Child" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })

			-- Update
			ReactNoop.render(React.createElement(App, { value = 1 }))
			jestExpect(Scheduler).toFlushAndYield({
				"App",
				-- Child does not re-render
			})
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })
		end)

		it("provider does not bail out if legacy context changed above", function()
			local Context = React.createContext(0)

			local function Child()
				Scheduler.unstable_yieldValue("Child")
				return React.createElement("span", { prop = "Child" })
			end

			local children = React.createElement(Child)

			local LegacyProvider = React.Component:extend("LegacyProvider")
			LegacyProvider.childContextTypes = {
				legacyValue = function()
					return {}
				end,
			}
			function LegacyProvider:init()
				self.state = { legacyValue = 1 }
			end
			function LegacyProvider:getChildContext()
				return { legacyValue = self.state.legacyValue }
			end
			function LegacyProvider:render()
				Scheduler.unstable_yieldValue("LegacyProvider")
				return self.props.children
			end

			local App = React.Component:extend("App")
			function App:init()
				self.state = { value = 1 }
			end
			function App:render()
				Scheduler.unstable_yieldValue("App")
				return React.createElement(Context.Provider, { value = self.state.value }, self.props.children)
			end

			local legacyProviderRef = React.createRef()
			local appRef = React.createRef()

			-- Initial mount
			ReactNoop.render(
				React.createElement(
					LegacyProvider,
					{ ref = legacyProviderRef },
					React.createElement(App, { ref = appRef, value = 1 }, children)
				)
			)
			jestExpect(function()
				jestExpect(Scheduler).toFlushAndYield({ "LegacyProvider", "App", "Child" })
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: LegacyProvider"
			)
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })

			-- Update App with same value (should bail out)
			appRef.current:setState({ value = 1 })
			jestExpect(Scheduler).toFlushAndYield({ "App" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })

			-- Update LegacyProvider (should not bail out)
			legacyProviderRef.current:setState({ value = 1 })
			jestExpect(Scheduler).toFlushAndYield({ "LegacyProvider", "App", "Child" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })

			-- Update App with same value (should bail out)
			appRef.current:setState({ value = 1 })
			jestExpect(Scheduler).toFlushAndYield({ "App" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Child") })
		end)
	end)

	describe("Context.Consumer", function()
		it("warns if child is not a function", function()
			-- spyOnDev(console, 'error')
			local Context = React.createContext(0)
			ReactNoop.render(React.createElement(Context.Consumer))
			-- deviation: This line is relying on a default JS error message
			-- containing "is not a function"; for us, the relevant error message is
			-- "attempt to call a nil value"
			jestExpect(Scheduler).toFlushAndThrow("attempt to call a nil value")
			-- ROBLOX TODO: Warning is logged (verified in debugger), but toErrorDev doesn't match
			-- if _G.__DEV__ then
			-- 	jestExpect(console.error.calls.argsFor(0)({ 0 })).toContain(
			-- 		"A context consumer was rendered with multiple children, or a child " .. "that isn't a function"
			-- 	)
			-- end
		end)

		it("can read other contexts inside consumer render prop", function()
			local FooContext = React.createContext(0)
			local BarContext = React.createContext(0)

			local function FooAndBar()
				return React.createElement(FooContext.Consumer, nil, function(foo)
					local bar = readContext(BarContext)
					return React.createElement(Text, { text = "Foo: " .. tostring(foo) .. ", Bar: " .. tostring(bar) })
				end)
			end

			local Indirection = React.Component:extend("Indirection")
			function Indirection:shouldComponentUpdate()
				return false
			end
			function Indirection:render()
				return self.props.children
			end

			local function App(props)
				return React.createElement(
					FooContext.Provider,
					{ value = props.foo },
					React.createElement(
						BarContext.Provider,
						{ value = props.bar },
						React.createElement(Indirection, nil, React.createElement(FooAndBar))
					)
				)
			end

			ReactNoop.render(React.createElement(App, { foo = 1, bar = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 1, Bar: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Foo: 1, Bar: 1") })

			-- Update foo
			ReactNoop.render(React.createElement(App, { foo = 2, bar = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 2, Bar: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Foo: 2, Bar: 1") })

			-- Update bar
			ReactNoop.render(React.createElement(App, { foo = 2, bar = 2 }))
			-- ROBLOX FIXME: Fails here; update doesn't trigger the inner consumer
			-- that's using `readContext`
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 2, Bar: 2" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("Foo: 2, Bar: 2") })
		end)

		-- Context consumer bails out on propagating "deep" updates when `value` hasn't changed.
		-- However, it doesn't bail out from rendering if the component above it re-rendered anyway.
		-- If we bailed out on referential equality, it would be confusing that you
		-- can call this.setState(), but an autobound render callback "blocked" the update.
		-- https://github.com/facebook/react/pull/12470#issuecomment-376917711
		it("consumer does not bail out if there were no bailouts above it", function()
			local Context = React.createContext(0)
			local Consumer = Context.Consumer

			local App = React.Component:extend("App")
			function App:init()
				self.state = {
					text = "hello",
				}
			end

			function App:renderConsumer(context)
				Scheduler.unstable_yieldValue("App#renderConsumer")
				return React.createElement("span", { prop = self.state.text })
			end

			function App:render()
				Scheduler.unstable_yieldValue("App")
				return React.createElement(
					Context.Provider,
					{ value = self.props.value },
					React.createElement(Consumer, nil, function(context)
						return self:renderConsumer(context)
					end)
				)
			end

			-- Initial mount
			local inst
			ReactNoop.render(React.createElement(App, {
				value = 1,
				ref = function(ref)
					inst = ref
				end,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("hello") })

			-- Update
			inst:setState({ text = "goodbye" })
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("goodbye") })
		end)

		-- ROBLOX deviation: tests legacy Roact compatibility feature
		it("warns once if using legacy Roact render prop", function()
			local Context = React.createContext()

			local function renderContext()
				ReactNoop.render(
					React.createElement(
							Context.Provider,
							{ value = 1 },
							React.createElement(Context.Consumer, {render = function(value)
									return React.createElement("span", { prop = "Result: " .. tostring(value) })
							end}))
				)
			end

			renderContext()
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toWarnDev("Warning: Your Context.Consumer component is using legacy Roact syntax, which won't be supported in future versions of Roact. \n" ..
				"Please provide no props and supply the 'render' function as a child (the 3rd argument of createElement). For example: \n" ..
				"       createElement(ContextConsumer, {render = function(...) end})\n" ..
				"becomes:\n" ..
				"       createElement(ContextConsumer, nil, function(...) end)\n" ..
				"For more info, reference the React documentation here: \n" ..
				"https://reactjs.org/docs/context.html#contextconsumer", {withoutStack = true})
				ReactNoop.render(
					React.createElement(
							Context.Provider,
							{ value = 1 },
							React.createElement(Context.Consumer, {render = function(value)
									return React.createElement("span", { prop = "Result: " .. tostring(value) })
							end}))
				)

			-- Does not warn a second time
			renderContext()
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toWarnDev({})
		end)

	end)

	describe("readContext", function()
		-- Unstable changedBits API was removed. Port this test to context selectors
		-- once that exists.
		-- @gate FIXME
		itSKIP("can read the same context multiple times in the same function", function()
			local Context = React.createContext({foo = 0, bar = 0, baz = 0}, function(a, b)
				local result = 0
				if a.foo ~= b.foo then
					result = bit32.bor(result, 0b001)
				end
				if a.bar ~= b.bar then
					result = bit32.bor(result, 0b010)
				end
				if a.baz ~= b.baz then
					result = bit32.bor(result, 0b100)
				end
				return result
			end)

			local function Provider(props)
				return React.createElement(Context.Provider,
					{ value = {foo = props.foo, bar = props.bar, baz = props.baz} },
					props.children
				)
			end

			local function FooAndBar()
				local values = readContext(Context, 0b001)
				local foo = values.foo
				values = readContext(Context, 0b010)
				local bar = values.bar
				return React.createElement(Text,
					{ text = "Foo: " .. tostring(foo) .. ", Bar: " .. tostring(bar) }
				)
			end

			local function Baz()
				local values = readContext(Context, 0b001)
				local baz = values.baz
				return React.createElement(Text,
					{ text = "Baz: " .. tostring(baz) }
				)
			end

			local Indirection = React.Component:extend("Indirection")
			function Indirection:shouldComponentUpdate()
				return false
			end
			function Indirection:render()
				return self.props.children
			end

			local function App(props)
				return React.createElement(
					Provider,
					{ foo = props.foo, bar = props.bar, baz = props.baz, },
					React.createElement(Indirection, nil,
						React.createElement(Indirection, nil,
							React.createElement(FooAndBar)
						),
						React.createElement(Indirection, nil,
							React.createElement(Baz)
						)
					)
				)
			end

			ReactNoop.render(React.createElement(App, { foo = 1, bar = 1, baz = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 1, Bar: 1", "Baz: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Foo: 1, Bar: 1"),
				span("Baz: 1")
			})

			-- Update only foo
			ReactNoop.render(React.createElement(App, { foo = 2, bar = 1, baz = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 2, Bar: 1" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Foo: 2, Bar: 1"),
				span("Baz: 1")
			})

			-- Update only bar
			ReactNoop.render(React.createElement(App, { foo = 2, bar = 2, baz = 1 }))
			jestExpect(Scheduler).toFlushAndYield({ "Foo: 2, Bar: 2" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Foo: 2, Bar: 2"),
				span("Baz: 1")
			})

			-- Update only baz
			ReactNoop.render(React.createElement(App, { foo = 2, bar = 2, baz = 2 }))
			jestExpect(Scheduler).toFlushAndYield({ "Baz: 2" })
			jestExpect(ReactNoop.getChildren()).toEqual({
				span("Foo: 2, Bar: 2"),
				span("Baz: 2")
			})
		end)

		-- Context consumer bails out on propagating "deep" updates when `value` hasn't changed.
		-- However, it doesn't bail out from rendering if the component above it re-rendered anyway.
		-- If we bailed out on referential equality, it would be confusing that you
		-- can call this.setState(), but an autobound render callback "blocked" the update.
		-- https://github.com/facebook/react/pull/12470#issuecomment-376917711
		it("does not bail out if there were no bailouts above it", function()
			local Context = React.createContext(0)
			local Consumer = React.Component:extend("Consumer")
			function Consumer:render()
				local contextValue = readContext(Context)
				return self.props.children(contextValue)
			end

			local App = React.Component:extend("App")

			function App:init()
				self.state = {
					text = "hello",
				}
			end

			function App:renderConsumer(context)
				Scheduler.unstable_yieldValue("App#renderConsumer")
				return React.createElement("span", { prop = self.state.text })
			end

			function App:render()
				Scheduler.unstable_yieldValue("App")
				return React.createElement(
					Context.Provider,
					{ value = self.props.value },
					React.createElement(Consumer, nil, function(context)
						return self:renderConsumer(context)
					end)
				)
			end

			-- Initial mount
			local inst
			ReactNoop.render(React.createElement(App, {
				value = 1,
				ref = function(ref)
					inst = ref
				end,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("hello") })

			-- Update
			inst:setState({ text = "goodbye" })
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("goodbye") })
		end)


		it("warns when reading context inside render phase class setState updater", function()
			local ThemeContext = React.createContext("light")

			local Cls = React.Component:extend("Cls")
			function Cls:init()
				self.state = {}
			end

			function Cls:render()
				self:setState(function()
					readContext(ThemeContext)
				end)
				return nil
			end

			ReactNoop.render(React.createElement(Cls))
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev({
				"Context can only be read while React is rendering",
				-- A second warning comes from to setStates being added to the queue.
				"Context can only be read while React is rendering",
				"Cannot update during an existing state transition",
			})
		end)
	end)

	describe("useContext", function()
		it("throws when used in a class component", function()
			local Context = React.createContext(0)
			local Foo = React.Component:extend("Foo")
			function Foo:render()
				return useContext(Context)
			end

			ReactNoop.render(React.createElement(Foo))
			jestExpect(Scheduler).toFlushAndThrow(
				"Invalid hook call. Hooks can only be called inside of the body of a function component. This could happen" ..
					" for one of the following reasons:\n" ..
					"1. You might have mismatching versions of React and the renderer (such as React DOM)\n" ..
					"2. You might be breaking the Rules of Hooks\n" ..
					"3. You might have more than one copy of React in the same app\n" ..
					"See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem."
			)
		end)

		it("warns when passed a consumer", function()
			local Context = React.createContext(0)
			local function Foo()
				return useContext(Context.Consumer)
			end

			ReactNoop.render(React.createElement(Foo))
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev(
				"Calling useContext(Context.Consumer) is not supported, may cause bugs, " ..
				"and will be removed in a future major release. " ..
				"Did you mean to call useContext(Context) instead?"
			)
		end)

		it("warns when passed a provider", function()
			local Context = React.createContext(0)
			local function Foo()
				useContext(Context.Provider)
				return nil
			end

			ReactNoop.render(React.createElement(Foo))
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev(
				"Calling useContext(Context.Provider) is not supported. " ..
				"Did you mean to call useContext(Context) instead?"
			)
		end)

		-- Context consumer bails out on propagating "deep" updates when `value` hasn't changed.
		-- However, it doesn't bail out from rendering if the component above it re-rendered anyway.
		-- If we bailed out on referential equality, it would be confusing that you
		-- can call this.setState(), but an autobound render callback "blocked" the update.
		-- https://github.com/facebook/react/pull/12470#issuecomment-376917711
		it("does not bail out if there were no bailouts above it", function()
			local Context = React.createContext(0)

			local function Consumer(props)
				local children = props.children
				local contextValue = useContext(Context)
				return children(contextValue)
			end

			local App = React.Component:extend("App")

			function App:init()
				self.state = {
					text = "hello",
				}
			end

			function App:renderConsumer(context)
				Scheduler.unstable_yieldValue("App#renderConsumer")
				return React.createElement("span", { prop = self.state.text })
			end

			function App:render()
				Scheduler.unstable_yieldValue("App")
				return React.createElement(
					Context.Provider,
					{ value = self.props.value },
					React.createElement(Consumer, nil, function(context)
						return self:renderConsumer(context)
					end)
				)
			end

			-- Initial mount
			local inst
			ReactNoop.render(React.createElement(App, {
				value = 1,
				ref = function(ref)
					inst = ref
				end,
			}))
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("hello") })

			-- Update
			inst:setState({ text = "goodbye" })
			jestExpect(Scheduler).toFlushAndYield({ "App", "App#renderConsumer" })
			jestExpect(ReactNoop.getChildren()).toEqual({ span("goodbye") })
		end)

		-- ROBLOX TODO: figure out how to render an invalid element to make this test pass
		-- it('unwinds after errors in complete phase', () => {
	end)


	-- ROBLOX TODO: add this test fixture
	-- describe('fuzz test', () => {


	it("should warn with an error message when using context as a consumer in DEV", function()
		local BarContext = React.createContext({value = "bar-initial"})
		local BarConsumer = BarContext

		local function Component()
			return React.createElement(React.Fragment, nil,
				React.createElement(BarContext.Provider,
					{ value = "bar-updated" },
					React.createElement(BarConsumer,
						nil,
						function(value)
							return React.createElement("div",
								{ actual = value, expected = "bar-updated" }
							)
						end
					)
				)
			)
		end

		jestExpect(function()
			ReactNoop.render(React.createElement(Component))
			jestExpect(Scheduler).toFlushWithoutYielding()
		end).toErrorDev(
			"Warning: " .. -- ROBLOX FIXME: remove the Warning: prefix in consoleWithStackDev
			"Rendering <Context> directly is not supported and will be removed in " ..
			"a future major release. Did you mean to render <Context.Consumer> instead?"
		)
	end)

	-- ROBLOX deviation: we don't implement this property at all
	-- it('should warn with an error message when using nested context consumers in DEV', () => {
end
