-- Upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-test-renderer/src/__tests__/ReactTestRenderer-test.internal.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

-- !strict
local Packages = script.Parent.Parent.Parent
local ReactFeatureFlags

local React
local ReactTestRenderer
-- local prettyFormat = require('pretty-format')

local RobloxJest

-- Isolate noop renderer
-- local ReactNoop = require(Packages.ReactNoopRenderer)
-- local Scheduler = require(Packages.Scheduler)

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Symbol = LuauPolyfill.Symbol

-- Kind of hacky, but we nullify all the instances to test the tree structure
-- with jasmine's deep equality function, and test the instances separate. We
-- also delete children props because testing them is more annoying and not
-- really important to verify.
local function cleanNodeOrArray(node)
	if not node then
		return
	end
	if Array.isArray(node) then
		-- ROBLOX deviation: for loop in place of forEach()
		for _, v in node do
			cleanNodeOrArray(v)
		end
		return
	end
	if node and node.instance then
		node.instance = nil
	end
	if node and node.props and node.props.children then
		-- eslint-disable-next-line no-unused-vars
		node.props["children"] = nil
	end
	if Array.isArray(node.rendered) then
		-- ROBLOX deviation: for loop in place of forEach()
		for _, v in node.rendered do
			cleanNodeOrArray(v)
		end
	elseif typeof(node.rendered) == "table" then
		cleanNodeOrArray(node.rendered)
	end
end

return function()
	RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	describe("ReactTestRenderer", function()
		beforeEach(function()
			RobloxJest.resetModules()

			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false

			React = require(Packages.React)
			ReactTestRenderer = require(Packages.ReactTestRenderer)
			-- local prettyFormat = require('pretty-format')
		end)
		it("renders a simple component", function()
			local function Link()
				return React.createElement("a", {
					role = "link",
				})
			end

			local renderer = ReactTestRenderer.create(React.createElement(Link))

			jestExpect(renderer.toJSON()).toEqual({
				type = "a",
				props = {
					role = "link",
				},
				children = nil,
			})
		end)
		it("renders a top-level empty component", function()
			local function Empty()
				return nil
			end

			local renderer = ReactTestRenderer.create(React.createElement(Empty))

			jestExpect(renderer.toJSON()).toEqual(nil)
		end)
		it("exposes a type flag", function()
			local function Link()
				return React.createElement("a", {
					role = "link",
				})
			end

			local renderer = ReactTestRenderer.create(React.createElement(Link))
			local object = renderer.toJSON()
			-- ROBLOX FIXME: needs to stringify $$typeof because Symbol module is reset. Un-stringify once we've found a solution.
			jestExpect(tostring(object["$$typeof"])).toEqual(
				tostring(Symbol.for_("react.test.json"))
			)

			-- $$typeof should not be enumerable.
			for key, _ in object do
				jestExpect(key).never.toEqual("$$typeof")
			end
		end)
		it("can render a composite component", function()
			local Component = React.Component:extend("Component")

			local Child = function()
				return React.createElement("moo")
			end

			function Component:render()
				return React.createElement("div", {
					className = "purple",
				}, React.createElement(Child, nil))
			end

			local renderer = ReactTestRenderer.create(React.createElement(Component))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {
					className = "purple",
				},
				children = {
					{
						type = "moo",
						props = {},
						children = nil,
					},
				},
			})
		end)
		it("renders some basics with an update", function()
			local renders = 0
			local Component = React.Component:extend("Component")

			local Child = function()
				renders = renders + 1

				return React.createElement("moo")
			end
			local Null = function()
				renders = renders + 1
				return nil
			end

			function Component:init()
				self.state = { x = 3 }
				return
			end
			function Component:render()
				renders = renders + 1

				return React.createElement("div", {
					className = "purple",
				}, self.state.x, React.createElement(Child), React.createElement(Null))
			end
			function Component:componentDidMount()
				self:setState({ x = 7 })
			end

			local renderer = ReactTestRenderer.create(React.createElement(Component))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {
					className = "purple",
				},
				children = {
					"7",
					{
						type = "moo",
						props = {},
						children = nil,
					},
				},
			})
			jestExpect(renders).toEqual(6)
		end)
		it("exposes the instance", function()
			local Mouse = React.Component:extend("Mouse")

			function Mouse:init()
				self.state = {
					mouse = "mouse",
				}
			end
			function Mouse:handleMoose()
				self:setState({
					mouse = "moose",
				})
			end
			function Mouse:render()
				return React.createElement("div", nil, self.state.mouse)
			end

			local renderer = ReactTestRenderer.create(React.createElement(Mouse))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {},
				children = {
					"mouse",
				},
			})

			local mouse = renderer.getInstance()

			mouse:handleMoose()
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					"moose",
				},
				props = {},
			})
		end)
		it("updates types", function()
			local renderer =
				ReactTestRenderer.create(React.createElement("div", nil, "mouse"))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {},
				children = {
					"mouse",
				},
			})
			renderer.update(React.createElement("span", nil, "mice"))
			jestExpect(renderer.toJSON()).toEqual({
				type = "span",
				props = {},
				children = {
					"mice",
				},
			})
		end)
		it("updates children", function()
			local renderer = ReactTestRenderer.create(
				React.createElement(
					"div",
					nil,
					React.createElement("span", {
						key = "a",
					}, "A"),
					React.createElement("span", {
						key = "b",
					}, "B"),
					React.createElement("span", {
						key = "c",
					}, "C")
				)
			)

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {},
				children = {
					{
						type = "span",
						props = {},
						children = {
							"A",
						},
					},
					{
						type = "span",
						props = {},
						children = {
							"B",
						},
					},
					{
						type = "span",
						props = {},
						children = {
							"C",
						},
					},
				},
			})
			renderer.update(React.createElement(
				"div",
				nil,
				React.createElement("span", {
					key = "d",
				}, "D"),
				React.createElement("span", {
					key = "c",
				}, "C"),
				React.createElement("span", {
					key = "b",
				}, "B")
			))
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {},
				children = {
					{
						type = "span",
						props = {},
						children = {
							"D",
						},
					},
					{
						type = "span",
						props = {},
						children = {
							"C",
						},
					},
					{
						type = "span",
						props = {},
						children = {
							"B",
						},
					},
				},
			})
		end)
		it("does the full lifecycle", function()
			local log = {}
			local Log = React.Component:extend("Log")

			function Log:render()
				table.insert(log, "render " .. self.props.name)
				return React.createElement("div")
			end
			function Log:componentDidMount()
				table.insert(log, "mount " .. self.props.name)
			end
			function Log:componentWillUnmount()
				table.insert(log, "unmount " .. self.props.name)
			end

			local renderer = ReactTestRenderer.create(React.createElement(Log, {
				key = "foo",
				name = "Foo",
			}))

			renderer.update(React.createElement(Log, {
				key = "bar",
				name = "Bar",
			}))
			renderer.unmount()
			jestExpect(log).toEqual({
				"render Foo",
				"mount Foo",
				"render Bar",
				"unmount Foo",
				"mount Bar",
				"unmount Bar",
			})
		end)
		it("gives a ref to native components", function()
			local log = {}

			ReactTestRenderer.create(React.createElement("div", {
				ref = function(r)
					return table.insert(log, r)
				end,
			}))
			jestExpect(log).toEqual({ nil })
		end)
		it("warns correctly for refs on SFCs", function()
			local function Bar()
				return React.createElement("div", nil, "Hello, world")
			end

			local Foo = React.Component:extend("Foo")

			function Foo:render()
				return React.createElement(Bar, {
					ref = React.createRef(),
				})
			end

			local Baz = React.Component:extend("Baz")

			function Baz:render()
				return React.createElement("div", {
					ref = React.createRef(),
				})
			end

			ReactTestRenderer.create(React.createElement(Baz))
			jestExpect(function()
				return ReactTestRenderer.create(React.createElement(Foo))
			end).toErrorDev(
				"Warning: Function components cannot be given refs. Attempts "
					.. "to access this ref will fail. "
					.. "Did you mean to use React.forwardRef()?\n\n"
					.. "Check the render method of `Foo`.\n"
					.. "    in Bar (at **)\n"
					.. "    in Foo (at **)"
			)
		end)
		it("allows an optional createNodeMock function", function()
			local mockDivInstance = {
				appendChild = function() end,
			}
			local mockInputInstance = {
				focus = function() end,
			}
			local mockListItemInstance = {
				click = function() end,
			}
			local mockAnchorInstance = {
				hover = function() end,
			}
			local log = {}

			-- ROBLOX deviation: using createRef in place of string refs
			local bar = React.createRef()
			local Foo = React.Component:extend("Foo")

			function Foo:componentDidMount()
				table.insert(log, bar.current)
			end
			function Foo:render()
				return React.createElement("a", {
					ref = bar,
				}, "Hello, world")
			end

			local function createNodeMock(element)
				if element.type == "div" then
					return mockDivInstance
				elseif element.type == "input" then
					return mockInputInstance
				elseif element.type == "li" then
					return mockListItemInstance
				elseif element.type == "a" then
					return mockAnchorInstance
				else
					return {}
				end
			end

			ReactTestRenderer.create(
				React.createElement("div", {
					ref = function(r)
						return table.insert(log, r)
					end,
				}),
				{ createNodeMock = createNodeMock }
			)
			ReactTestRenderer.create(
				React.createElement("input", {
					ref = function(r)
						return table.insert(log, r)
					end,
				}),
				{ createNodeMock = createNodeMock }
			)
			ReactTestRenderer.create(
				React.createElement(
					"div",
					nil,
					React.createElement(
						"span",
						nil,
						React.createElement(
							"ul",
							nil,
							React.createElement("li", {
								ref = function(r)
									return table.insert(log, r)
								end,
							})
						),
						React.createElement(
							"ul",
							nil,
							React.createElement("li", {
								ref = function(r)
									return table.insert(log, r)
								end,
							}),
							React.createElement("li", {
								ref = function(r)
									return table.insert(log, r)
								end,
							})
						)
					)
				),
				{
					createNodeMock = createNodeMock,
					foobar = true,
				}
			)
			ReactTestRenderer.create(
				React.createElement(Foo),
				{ createNodeMock = createNodeMock }
			)
			ReactTestRenderer.create(React.createElement("div", {
				ref = function(r)
					return table.insert(log, r)
				end,
			}))
			ReactTestRenderer.create(
				React.createElement("div", {
					ref = function(r)
						return table.insert(log, r)
					end,
				}),
				{}
			)
			jestExpect(log).toEqual({
				mockDivInstance,
				mockInputInstance,
				mockListItemInstance,
				mockListItemInstance,
				mockListItemInstance,
				mockAnchorInstance,
			})
		end)
		it("supports unmounting when using refs", function()
			local Foo = React.Component:extend("Foo")

			-- ROBLOX deviation: using createRef in place of string refs
			local foo = React.createRef()

			function Foo:render()
				return React.createElement("div", {
					ref = foo,
				})
			end

			local inst = ReactTestRenderer.create(React.createElement(Foo), {
				createNodeMock = function()
					return foo.current
				end,
			})

			jestExpect(function()
				return inst.unmount()
			end).never.toThrow()
		end)
		it("supports unmounting inner instances", function()
			local count = 0
			local Foo = React.Component:extend("Foo")

			function Foo:componentWillUnmount()
				count = count + 1
			end
			function Foo:render()
				return React.createElement("div")
			end

			local inst = ReactTestRenderer.create(
				React.createElement("div", nil, React.createElement(Foo)),
				{
					createNodeMock = function()
						return "foo"
					end,
				}
			)

			jestExpect(function()
				return inst.unmount()
			end).never.toThrow()
			jestExpect(count).toEqual(1)
		end)
		it("supports updates when using refs", function()
			local log = {}
			local createNodeMock = function(element)
				table.insert(log, element.type)
				return element.type
			end
			local Foo = React.Component:extend("Foo")

			function Foo:render()
				return (function()
					if self.props.useDiv then
						return React.createElement("div", {
							ref = React.createRef(),
						})
					end

					return React.createElement("span", {
						ref = React.createRef(),
					})
				end)()
			end

			local inst = ReactTestRenderer.create(
				React.createElement(Foo, { useDiv = true }),
				{ createNodeMock = createNodeMock }
			)

			inst.update(React.createElement(Foo, { useDiv = false }))
			jestExpect(log).toEqual({
				"div",
				"span",
			})
		end)
		it("supports error boundaries", function()
			local log = {}
			local Angry = React.Component:extend("Angry")

			function Angry:render()
				table.insert(log, "Angry render")
				error("Please, do not render me.")
			end
			function Angry:componentDidMount()
				table.insert(log, "Angry componentDidMount")
			end
			function Angry:componentWillUnmount()
				table.insert(log, "Angry componentWillUnmount")
			end

			local Boundary = React.Component:extend("Boundary")

			function Boundary:init(props)
				self.state = { error = false }
			end
			function Boundary:render()
				table.insert(log, "Boundary render")

				if not self.state.error then
					return React.createElement(
						"div",
						nil,
						React.createElement("button", {
							onClick = self.onClick,
						}, "ClickMe"),
						React.createElement(Angry)
					)
				else
					return React.createElement("div", nil, "Happy Birthday!")
				end
			end
			function Boundary:componentDidMount()
				table.insert(log, "Boundary componentDidMount")
			end
			function Boundary:componentWillUnmount()
				table.insert(log, "Boundary componentWillUnmount")
			end
			function Boundary:onClick()
				-- do nothing
				return
			end
			function Boundary:componentDidCatch()
				table.insert(log, "Boundary componentDidCatch")
				self:setState({ error = true })
			end

			-- ROBLOX Test Noise: jest setup config makes this hide error
			-- boundary warnings in upstream (scripts/jest/setupTests.js:72)
			local renderer = ReactTestRenderer.create(React.createElement(Boundary))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				props = {},
				children = {
					"Happy Birthday!",
				},
			})
			jestExpect(log).toEqual({
				"Boundary render",
				"Angry render",
				"Boundary componentDidMount",
				"Boundary componentDidCatch",
				"Boundary render",
			})
		end)
		it("can update text nodes", function()
			local Component = React.Component:extend("Component")

			function Component:render()
				return React.createElement("div", nil, self.props.children)
			end

			local renderer =
				ReactTestRenderer.create(React.createElement(Component, nil, "Hi"))

			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					"Hi",
				},
				props = {},
			})
			renderer.update(React.createElement(Component, nil, {
				"Hi",
				"Bye",
			}))
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					"Hi",
					"Bye",
				},
				props = {},
			})
			renderer.update(React.createElement(Component, nil, "Bye"))
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					"Bye",
				},
				props = {},
			})
			renderer.update(React.createElement(Component, nil, 42))
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					"42",
				},
				props = {},
			})
			renderer.update(
				React.createElement(Component, nil, React.createElement("div"))
			)
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = {
					{
						type = "div",
						children = nil,
						props = {},
					},
				},
				props = {},
			})
		end)
		it("toTree() renders simple components returning host components", function()
			local Qoo = function()
				return React.createElement("span", {
					className = "Qoo",
				}, "Hello World!")
			end
			local renderer = ReactTestRenderer.create(React.createElement(Qoo))
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)

			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				nodeType = "component",
				type = Qoo,
				props = {},
				instance = nil,
				rendered = {
					nodeType = "host",
					type = "span",
					props = {
						className = "Qoo",
					},
					instance = nil,
					rendered = {
						"Hello World!",
					},
				},
			})
		end)
		it("toTree() handles nested Fragments", function()
			local Foo = function()
				return React.createElement(
					React.Fragment,
					nil,
					React.createElement(React.Fragment, nil, "foo")
				)
			end
			local renderer = ReactTestRenderer.create(React.createElement(Foo))
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)

			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				nodeType = "component",
				type = Foo,
				instance = nil,
				props = {},
				rendered = "foo",
			})
		end)
		it("toTree() handles null rendering components", function()
			local Foo = React.Component:extend("Foo")

			function Foo:render()
				return nil
			end

			local renderer = ReactTestRenderer.create(React.createElement(Foo))
			local tree = renderer.toTree()

			-- ROBLOX deviation: toBeInstanceOf not yet implemented, workaround by checking elementType
			jestExpect(tree.instance._reactInternals.elementType.__componentName).toEqual(
				"Foo"
			)
			cleanNodeOrArray(tree)

			jestExpect(tree).toEqual({
				type = Foo,
				nodeType = "component",
				props = {},
				instance = nil,
				rendered = nil,
			})
		end)
		it("toTree() handles simple components that return arrays", function()
			local Foo = function(_ref)
				local children = _ref.children

				return children
			end
			local renderer = ReactTestRenderer.create(
				React.createElement(
					Foo,
					nil,
					React.createElement("div", nil, "One"),
					React.createElement("div", nil, "Two")
				)
			)
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)

			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				type = Foo,
				nodeType = "component",
				props = {},
				instance = nil,
				rendered = {
					{
						instance = nil,
						nodeType = "host",
						props = {},
						rendered = {
							"One",
						},
						type = "div",
					},
					{
						instance = nil,
						nodeType = "host",
						props = {},
						rendered = {
							"Two",
						},
						type = "div",
					},
				},
			})
		end)
		it("toTree() handles complicated tree of arrays", function()
			local Foo = React.Component:extend("Foo")

			function Foo:render()
				return self.props.children
			end

			local renderer = ReactTestRenderer.create(
				React.createElement(
					"div",
					nil,
					React.createElement(
						Foo,
						nil,
						React.createElement("div", nil, "One"),
						React.createElement("div", nil, "Two"),
						React.createElement(
							Foo,
							nil,
							React.createElement("div", nil, "Three")
						)
					),
					React.createElement("div", nil, "Four")
				)
			)
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)

			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				type = "div",
				instance = nil,
				nodeType = "host",
				props = {},
				rendered = {
					{
						type = Foo,
						nodeType = "component",
						props = {},
						instance = nil,
						rendered = {
							{
								type = "div",
								nodeType = "host",
								props = {},
								instance = nil,
								rendered = {
									"One",
								},
							},
							{
								type = "div",
								nodeType = "host",
								props = {},
								instance = nil,
								rendered = {
									"Two",
								},
							},
							{
								type = Foo,
								nodeType = "component",
								props = {},
								instance = nil,
								rendered = {
									type = "div",
									nodeType = "host",
									props = {},
									instance = nil,
									rendered = {
										"Three",
									},
								},
							},
						},
					},
					{
						type = "div",
						nodeType = "host",
						props = {},
						instance = nil,
						rendered = {
							"Four",
						},
					},
				},
			})
		end)
		it("toTree() handles complicated tree of fragments", function()
			local renderer = ReactTestRenderer.create(
				React.createElement(
					React.Fragment,
					nil,
					React.createElement(
						React.Fragment,
						nil,
						React.createElement("div", nil, "One"),
						React.createElement("div", nil, "Two"),
						React.createElement(
							React.Fragment,
							nil,
							React.createElement("div", nil, "Three")
						)
					),
					React.createElement("div", nil, "Four")
				)
			)
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)
			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				{
					type = "div",
					nodeType = "host",
					props = {},
					instance = nil,
					rendered = {
						"One",
					},
				},
				{
					type = "div",
					nodeType = "host",
					props = {},
					instance = nil,
					rendered = {
						"Two",
					},
				},
				{
					type = "div",
					nodeType = "host",
					props = {},
					instance = nil,
					rendered = {
						"Three",
					},
				},
				{
					type = "div",
					nodeType = "host",
					props = {},
					instance = nil,
					rendered = {
						"Four",
					},
				},
			})
		end)
		it("root instance and createNodeMock ref return the same value", function()
			local createNodeMock = function(ref)
				return { node = ref }
			end
			local refInst = nil
			local renderer = ReactTestRenderer.create(
				React.createElement("div", {
					ref = function(ref)
						refInst = ref
						return
					end,
				}),
				{ createNodeMock = createNodeMock }
			)
			local root = renderer.getInstance()

			jestExpect(root).toEqual(refInst)
		end)
		it("toTree() renders complicated trees of composites and hosts", function()
			-- SFC returning host. no children props.
			local Qoo = function()
				return React.createElement("span", {
					className = "Qoo",
				}, "Hello World!")
			end

			-- SFC returning host. passes through children.
			local Foo = function(props)
				local className, children = props.className, props.children

				return React.createElement(
					"div",
					{
						className = "Foo " .. className,
					},
					React.createElement("span", {
						className = "Foo2",
					}, "Literal"),
					children
				)
			end

			-- class composite returning composite. passes through children.
			local Bar = React.Component:extend("Bar")
			function Bar:render()
				local children = self.props.children
				local special = self.props.special

				return React.createElement(Foo, {
					className = (function()
						if special then
							return "special"
						end

						return "normal"
					end)(),
				}, children)
			end

			-- class composite return composite. no children props.
			local Bam = React.Component:extend("Bam")

			function Bam:render()
				return React.createElement(
					Bar,
					{ special = true },
					React.createElement(Qoo)
				)
			end

			local renderer = ReactTestRenderer.create(React.createElement(Bam))
			local tree = renderer.toTree()

			-- we test for the presence of instances before nulling them out
			-- ROBLOX deviation: toBeInstanceOf not yet implemented, workaround by checking elementType
			jestExpect(tree.instance._reactInternals.elementType.__componentName).toEqual(
				"Bam"
			)
			jestExpect(tree.rendered.instance._reactInternals.elementType.__componentName).toEqual(
				"Bar"
			)

			cleanNodeOrArray(tree)

			jestExpect(tree).toEqual({
				type = Bam,
				nodeType = "component",
				props = {},
				instance = nil,
				rendered = {
					type = Bar,
					nodeType = "component",
					props = { special = true },
					instance = nil,
					rendered = {
						type = Foo,
						nodeType = "component",
						props = {
							className = "special",
						},
						instance = nil,
						rendered = {
							type = "div",
							nodeType = "host",
							props = {
								className = "Foo special",
							},
							instance = nil,
							rendered = {
								{
									type = "span",
									nodeType = "host",
									props = {
										className = "Foo2",
									},
									instance = nil,
									rendered = {
										"Literal",
									},
								},
								{
									type = Qoo,
									nodeType = "component",
									props = {},
									instance = nil,
									rendered = {
										type = "span",
										nodeType = "host",
										props = {
											className = "Qoo",
										},
										instance = nil,
										rendered = {
											"Hello World!",
										},
									},
								},
							},
						},
					},
				},
			})
		end)
		it("can update text nodes when rendered as root", function()
			local renderer = ReactTestRenderer.create({
				"Hello",
				"world",
			})

			jestExpect(renderer.toJSON()).toEqual({
				"Hello",
				"world",
			})
			renderer.update(42)
			jestExpect(renderer.toJSON()).toEqual("42")
			renderer.update({
				42,
				"world",
			})
			jestExpect(renderer.toJSON()).toEqual({
				"42",
				"world",
			})
		end)
		it("can render and update root fragments", function()
			local Component = function(props)
				return props.children
			end
			local renderer = ReactTestRenderer.create({
				React.createElement(Component, {
					key = "a",
				}, "Hi"),
				React.createElement(Component, {
					key = "b",
				}, "Bye"),
			})

			jestExpect(renderer.toJSON()).toEqual({
				"Hi",
				"Bye",
			})
			renderer.update(React.createElement("div"))
			jestExpect(renderer.toJSON()).toEqual({
				type = "div",
				children = nil,
				props = {},
			})
			renderer.update({
				React.createElement("div", {
					key = "a",
				}, "goodbye"),
				"world",
			})
			jestExpect(renderer.toJSON()).toEqual({
				{
					type = "div",
					children = {
						"goodbye",
					},
					props = {},
				},
				"world",
			})
		end)
		it("supports context providers and consumers", function()
			local context = React.createContext("a")
			local Consumer = context.Consumer
			local Provider = context.Provider

			local function Child(props)
				return props.value
			end
			local function App()
				return React.createElement(
					Provider,
					{
						value = "b",
					},
					React.createElement(Consumer, nil, function(value)
						return React.createElement(Child, { value = value })
					end)
				)
			end

			local renderer = ReactTestRenderer.create(React.createElement(App))
			local child = renderer.root:findByType(Child)

			jestExpect(child.children).toEqual({
				"b",
			})
			-- ROBLOX deviation: no need to pretty format
			jestExpect(renderer.toTree()).toEqual({
				instance = nil,
				nodeType = "component",
				props = {},
				rendered = {
					instance = nil,
					nodeType = "component",
					props = {
						value = "b",
					},
					rendered = "b",
					type = Child,
				},
				type = App,
			})
		end)
		it("supports modes", function()
			local function Child(props)
				return props.value
			end
			local function App(props)
				return React.createElement(
					React.StrictMode,
					nil,
					React.createElement(Child, {
						value = props.value,
					})
				)
			end

			local renderer = ReactTestRenderer.create(React.createElement(App, {
				value = "a",
			}))
			local child = renderer.root:findByType(Child)

			jestExpect(child.children).toEqual({
				"a",
			})
			-- ROBLOX deviation: no need to pretty format
			jestExpect(renderer.toTree()).toEqual({
				instance = nil,
				nodeType = "component",
				props = {
					value = "a",
				},
				rendered = {
					instance = nil,
					nodeType = "component",
					props = {
						value = "a",
					},
					rendered = "a",
					type = Child,
				},
				type = App,
			})
		end)
		it("supports forwardRef", function()
			local InnerRefed = React.forwardRef(function(props, ref)
				return React.createElement(
					"div",
					nil,
					React.createElement("span", { ref = ref })
				)
			end)
			local App = React.Component:extend("App")

			function App:render()
				return React.createElement(InnerRefed, {
					ref = function(r)
						self.ref = r
						return
					end,
				})
			end

			local renderer = ReactTestRenderer.create(React.createElement(App))
			local tree = renderer.toTree()

			cleanNodeOrArray(tree)

			-- ROBLOX deviation: no need to pretty format
			jestExpect(tree).toEqual({
				instance = nil,
				nodeType = "component",
				props = {},
				rendered = {
					instance = nil,
					nodeType = "host",
					props = {},
					rendered = {
						{
							instance = nil,
							nodeType = "host",
							props = {},
							rendered = {},
							type = "span",
						},
					},
					type = "div",
				},
				type = App,
			})
		end)
		-- ROBLOX TODO: set up React Noop in this file
		-- xit('can concurrently render context with a "primary" renderer', function()
		--     local Context = React.createContext(nil)
		--     local Indirection = React.Fragment
		--     local App = function()
		--         return React.createElement(Context.Provider, {value = nil}, React.createElement(Indirection, nil, React.createElement(Context.Consumer, nil, function(
		--         )
		--             return nil
		--         end)))
		--     end

		--     ReactNoop.render(React.createElement(App))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     ReactTestRenderer.create(React.createElement(App))
		-- end)
		it(
			'calling findByType() with an invalid component will fall back to "Unknown" for component name',
			function()
				local App = function()
					return nil
				end
				local renderer = ReactTestRenderer.create(React.createElement(App))
				local NonComponent = {}
				jestExpect(function()
					renderer.root:findByType(NonComponent)
				end).toThrow('No instances found with node type: "Unknown"')
			end
		)
	end)
end
