--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local xit = JestGlobals.xit

local React
local ReactRoblox
local ReactFeatureFlags
-- ROBLOX deviation: the tests using these are currently SKIPped
local PropTypes = nil
-- ROBLOX deviation: This function is a misnomer even in upstream; here, we
-- just render it into an orphaned root
local ReactTestUtils = {
	renderIntoDocument = function(element)
		local instance = Instance.new("Folder")
		local root = ReactRoblox.createLegacyRoot(instance)
		root:render(element)
		return root
	end,
}

describe("ReactElementValidator", function()
	local ComponentClass

	beforeEach(function()
		jest.resetModules()

		-- PropTypes = require("prop-types")
		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
		React = require(script.Parent.Parent)
		ReactRoblox = require(Packages.Dev.ReactRoblox)
		-- ReactTestUtils = require("react-dom/test-utils")
		ComponentClass = React.Component:extend("ComponentClass")
		function ComponentClass:render()
			return React.createElement("Frame")
		end
	end)

	it("warns for keys for arrays of elements in rest args", function()
		jestExpect(function()
			React.createElement(ComponentClass, nil, {
				React.createElement(ComponentClass),
				React.createElement(ComponentClass),
			})
		end).toErrorDev('Each child in a list should have a unique "key" prop.')
	end)

	it("warns for keys for arrays of elements with owner info", function()
		local InnerClass = React.Component:extend("InnerClass")
		function InnerClass:render()
			return React.createElement(ComponentClass, nil, self.props.childSet)
		end

		local ComponentWrapper = React.Component:extend("ComponentWrapper")
		function ComponentWrapper:render()
			return React.createElement(InnerClass, {
				childSet = {
					React.createElement(ComponentClass),
					React.createElement(ComponentClass),
				},
			})
		end

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(ComponentWrapper))
		end).toErrorDev(
			'Each child in a list should have a unique "key" prop.'
				.. "\n\nCheck the render method of `InnerClass`. "
				.. "It was passed a child from ComponentWrapper. "
		)
	end)

	it("warns for keys for arrays with no owner or parent info", function()
		-- ROBLOX deviation: we can't nil out the function's name, so use a real anonymous function
		-- local function Anonymous()
		-- 	return React.createElement("Frame")
		-- end
		-- Object.defineProperty(Anonymous, "name", {value = nil})

		local divs = {
			React.createElement("Frame"),
			React.createElement("Frame"),
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(function()
				return React.createElement("Frame")
			end, nil, divs))
		end).toErrorDev(
			"Warning: Each child in a list should have a unique "
				.. '"key" prop. See https://reactjs.org/link/warning-keys for more information.\n'
				.. "    in Frame (at **)"
		)
	end)

	it("warns for keys for arrays of elements with no owner info", function()
		local divs = {
			React.createElement("Frame"),
			React.createElement("Frame"),
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement("Frame", nil, divs))
		end).toErrorDev(
			"Warning: Each child in a list should have a unique "
				.. '"key" prop.\n\nCheck the top-level render call using <Frame>. See '
				.. "https://reactjs.org/link/warning-keys for more information.\n"
				.. "    in Frame (at **)"
		)
	end)

	it("warns for keys with component stack info", function()
		local function Component()
			return React.createElement("Frame", nil, {
				React.createElement("Frame"),
				React.createElement("Frame"),
			})
		end
		local function Parent(props)
			return React.cloneElement(props.child)
		end
		local function GrandParent()
			return React.createElement(Parent, {
				child = React.createElement(Component),
			})
		end

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(GrandParent))
		end).toErrorDev(
			"Warning: Each child in a list should have a unique "
				.. '"key" prop.\n\nCheck the render method of `Component`. See '
				.. "https://reactjs.org/link/warning-keys for more information.\n"
				.. "    in Frame (at **)\n"
				.. "    in Component (at **)\n"
				.. "    in Parent (at **)\n"
				.. "    in GrandParent (at **)"
		)
	end)

	it("does not warn for keys when passing children down", function()
		local function Wrapper(props)
			return React.createElement(
				"Frame",
				nil,
				props.children,
				React.createElement("Frame")
			)
		end

		-- ROBLOX deviation: Add expectation to make sure we get _no_ errors
		jestExpect(function()
			ReactTestUtils.renderIntoDocument(
				React.createElement(
					Wrapper,
					nil,
					React.createElement("Frame"),
					React.createElement("Frame")
				)
			)
		end).toErrorDev({})
	end)

	-- ROBLOX deviation: This test is unique to roblox; we allow children to
	-- be passed as a table, and use the keys as stable keys for the
	-- equivalent children
	it("does not warn for keys when providing keys via children tables", function()
		-- ROBLOX FIXME: Expect coercion
		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement("Frame", nil, {
				ChildA = React.createElement("Frame"),
				ChildB = React.createElement("Frame"),
			}))
		end).toErrorDev({})
	end)

	-- ROBLOX deviation: no @@iterator in Lua
	xit("warns for keys for iterables of elements in rest args", function()
		local iterable = {
			["@@iterator"] = function()
				local i = 0
				return {
					next = function()
						i = i + 1
						local done = i > 2
						local value
						if not done then
							value = React.createElement(ComponentClass)
						end
						return {
							value = value,
							done = done,
						}
					end,
				}
			end,
		}

		jestExpect(function()
			return React.createElement(ComponentClass, nil, iterable)
		end).toErrorDev('Each child in a list should have a unique "key" prop.')
	end)

	it("does not warns for arrays of elements with keys", function()
		React.createElement(ComponentClass, nil, {
			React.createElement(ComponentClass, { key = "#1" }),
			React.createElement(ComponentClass, { key = "#2" }),
		})
	end)

	-- ROBLOX deviation: no @@iterator in Lua
	xit("does not warns for iterable elements with keys", function()
		local iterable = {
			["@@iterator"] = function()
				local i = 0
				return {
					next = function()
						i = i + 1
						local done = i > 2
						return {
							value = not done and React.createElement(
								ComponentClass,
								{ key = "#" .. i }
							) or nil,
							done = done,
						}
					end,
				}
			end,
		}

		React.createElement(ComponentClass, nil, iterable)
	end)

	it("does not warn when the element is directly in rest args", function()
		React.createElement(
			ComponentClass,
			nil,
			React.createElement(ComponentClass),
			React.createElement(ComponentClass)
		)
	end)

	it("does not warn when the array contains a non-element", function()
		React.createElement(ComponentClass, nil, { {}, {} })
	end)

	-- ROBLOX TODO: implement PropTypes support
	xit("should give context for PropType errors in nested components.", function()
		-- // In this test, we're making sure that if a proptype error is found in a
		-- // component, we give a small hint as to which parent instantiated that
		-- // component as per warnings about key usage in ReactElementValidator.
		local MyComp = React.Component:extend("MyComp")
		function MyComp:render()
			return React.createElement("Frame", nil, "My color is " .. self.props.color)
		end
		MyComp.propTypes = {
			color = PropTypes.string,
		}
		local function ParentComp()
			return React.createElement(MyComp, { color = 123 })
		end

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(ParentComp))
		end).toErrorDev(
			"Warning: Failed prop type: "
				.. "Invalid prop `color` of type `number` supplied to `MyComp`, "
				.. "expected `string`.\n"
				.. "    in MyComp (at **)\n"
				.. "    in ParentComp (at **)"
		)
	end)

	it("gives a helpful error when passing invalid types", function()
		local function Foo() end

		jestExpect(function()
			React.createElement(nil)
			React.createElement(true)
			React.createElement({ x = 17 })
			React.createElement({})
			React.createElement(React.createElement("Frame"))
			React.createElement(React.createElement(Foo))
			React.createElement(React.createElement(React.createContext().Consumer))
			React.createElement({ ["$$typeof"] = "non-react-thing" })
		end).toErrorDev({
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: nil.",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: boolean.",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: table.",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: array. You likely forgot to export your "
				.. "component from the file it's defined in, or you might have mixed up "
				.. "default and named imports.",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: <Frame />. Did you accidentally export a JSX literal "
				.. "or Element instead of a component?",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: <Foo />. Did you accidentally export a JSX literal "
				.. "or Element instead of a component?",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: <Context.Consumer />. Did you accidentally "
				.. "export a JSX literal or Element instead of a component?",
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: table.\n{",
		}, { withoutStack = true })

		-- // Should not log any additional warnings
		React.createElement("Frame")
	end)

	it(
		"includes the owner name when passing null, undefined, boolean, or number",
		function()
			local function ParentComp()
				-- ROBLOX DEVIATION: The test says "null, undefined, boolean, or
				-- number", but uses `null`, which it treats differently from
				-- `undefined`. Here, we're passing a number, which should have
				-- behavior identical to upstream
				return React.createElement(1)
			end

			jestExpect(function()
				jestExpect(function()
					ReactTestUtils.renderIntoDocument(React.createElement(ParentComp))
				end).toThrowError(
					"Element type is invalid: expected a string (for built-in components) "
						.. "or a class/function (for composite components) but got: number."
						.. (
							_G.__DEV__
								and "\n\nCheck the render method of `ParentComp`."
							or ""
						)
				)
			end).toErrorDev(
				"Warning: React.createElement: type is invalid -- expected a string "
					.. "(for built-in components) or a class/function (for composite "
					.. "components) but got: number."
				-- ROBLOX FIXME: Error output differs
				-- "\n\nCheck the render method of `ParentComp`.\n    in ParentComp",
			)
		end
	)

	-- ROBLOX deviation: Regression test for error output issue
	it("includes the owner name of a PureComponent", function()
		local ParentPureComp = React.PureComponent:extend("ParentPureComp")
		function ParentPureComp:render()
			return React.createElement(1)
		end

		jestExpect(function()
			jestExpect(function()
				ReactTestUtils.renderIntoDocument(React.createElement(ParentPureComp))
			end).toThrowError(
				"Element type is invalid: expected a string (for built-in components) "
					.. "or a class/function (for composite components) but got: number."
					.. (
						_G.__DEV__
							and "\n\nCheck the render method of `ParentPureComp`."
						or ""
					)
			)
		end).toErrorDev(
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: number."
			-- ROBLOX FIXME: Error output differs
			-- "\n\nCheck the render method of `ParentPureComp`.\n    in ParentPureComp"
		)
	end)

	-- ROBLOX TODO: implement PropTypes
	it.skip("should check default prop values", function()
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement("Frame", nil, self.props.prop)
		end
		Component.propTypes = {
			prop = PropTypes.string.isRequired,
		}
		Component.defaultProps = { prop = nil }

		jestExpect(function()
			return ReactTestUtils.renderIntoDocument(React.createElement(Component))
		end).toErrorDev(
			"Warning: Failed prop type: The prop `prop` is marked as required in "
				.. "`Component`, but its value is `null`.\n"
				.. "    in Component"
		)
	end)

	-- ROBLOX TODO: implement PropTypes
	it.skip("should not check the default for explicit null", function()
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement("Frame", nil, self.props.prop)
		end
		Component.propTypes = {
			prop = PropTypes.string.isRequired,
		}
		Component.defaultProps = {
			prop = "text",
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(
				React.createElement(Component, { prop = nil })
			)
		end).toErrorDev(
			"Warning: Failed prop type: The prop `prop` is marked as required in "
				.. "`Component`, but its value is `null`.\n"
				.. "    in Component"
		)
	end)

	-- ROBLOX TODO: implement PropTypes
	it.skip("should check declared prop types", function()
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement("Frame", nil, self.props.prop)
		end
		Component.propTypes = {
			prop = PropTypes.string.isRequired,
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(Component))
			ReactTestUtils.renderIntoDocument(
				React.createElement(Component, { prop = 42 })
			)
		end).toErrorDev({
			"Warning: Failed prop type: "
				.. "The prop `prop` is marked as required in `Component`, but its value "
				.. "is `undefined`.\n"
				.. "    in Component",
			"Warning: Failed prop type: "
				.. "Invalid prop `prop` of type `number` supplied to "
				.. "`Component`, expected `string`.\n"
				.. "    in Component",
		})

		-- // Should not error for strings
		ReactTestUtils.renderIntoDocument(React.createElement(Component, {
			prop = "string",
		}))
	end)

	-- ROBLOX TODO: implement PropTypes
	it.skip("should warn if a PropType creator is used as a PropType", function()
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement("Frame", nil, self.props.myProp.value)
		end
		Component.propTypes = {
			myProp = PropTypes.shape,
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(
				React.createElement(Component, { myProp = { value = "hi" } })
			)
		end).toErrorDev(
			"Warning: Component: type specification of prop `myProp` is invalid; "
				.. "the type checker function must return `null` or an `Error` but "
				.. "returned a function. You may have forgotten to pass an argument to "
				.. "the type checker creator (arrayOf, instanceOf, objectOf, oneOf, "
				.. "oneOfType, and shape all require an argument)."
		)
	end)

	-- ROBLOX TODO: implement PropTypes
	it.skip("should warn if component declares PropTypes instead of propTypes", function()
		local MisspelledPropTypesComponent =
			React.Component:extend("MisspelledPropTypesComponent")
		function MisspelledPropTypesComponent:render()
			return React.createElement("Frame", nil, self.props.prop)
		end
		MisspelledPropTypesComponent.PropTypes = {
			prop = PropTypes.string,
		}

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(
				React.createElement(MisspelledPropTypesComponent, { prop = "Hi" })
			)
		end).toErrorDev(
			"Warning: Component MisspelledPropTypesComponent declared `PropTypes` "
				.. "instead of `propTypes`. Did you misspell the property assignment?",
			{ withoutStack = true }
		)
	end)

	it("warns for fragments with illegal attributes", function()
		local Foo = React.Component:extend("Foo")
		function Foo:render()
			-- ROBLOX deviation: Use an actual child element instead of a
			-- text instance, which is unsupported in ReactRoblox
			return React.createElement(
				React.Fragment,
				{ a = 1 },
				React.createElement("Frame")
			)
		end
		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(Foo))
		end).toErrorDev(
			"Invalid prop `a` supplied to `React.Fragment`. React.Fragment "
				.. "can only have `key` and `children` props."
		)
	end)

	if not _G.__EXPERIMENTAL__ then
		-- ROBLOX deviation: createFactory is deprecated in React so it is removed in
		-- the Lua version
		it.skip("should warn when accessing .type on an element factory", function()
			local function TestComponent()
				return React.createElement("Frame")
			end

			local TestFactory

			jestExpect(function()
				TestFactory = React.createFactory(TestComponent)
			end).toWarnDev(
				"Warning: React.createFactory() is deprecated and will be removed in a "
					.. "future major release. Consider using JSX or use React.createElement() "
					.. "directly instead.",
				{ withoutStack = true }
			)
			jestExpect(function()
				return TestFactory.type
			end).toWarnDev(
				"Warning: Factory.type is deprecated. Access the class directly before "
					.. "passing it to createFactory.",
				{ withoutStack = true }
			)

			-- // Warn once, not again
			jestExpect(TestFactory.type).toBe(TestComponent)
		end)
	end

	-- ROBLOX deviation: usage of web browser document global
	it.skip("does not warn when using DOM node as children", function()
		-- local DOMContainer = React.Component:extend("DOMContainer")
		-- function DOMContainer:render()
		-- 	return React.createElement("Frame")
		-- end
		-- function DOMContainer:componentDidMount()
		-- 	ReactDOM.findDOMNode(self).appendChild(self.props.children);
		-- end

		-- local node = document.createElement("Frame")
		-- -- // This shouldn't cause a stack overflow or any other problems (#3883)
		-- ReactTestUtils.renderIntoDocument(
		-- 	React.createElement(DOMContainer, nil, node)
		-- )
	end)

	-- ROBLOX deviation: not applicable in Lua
	it.skip("should not enumerate enumerable numbers (#4776)", function()
		-- Number.prototype['@@iterator'] = function()
		-- 	error("number iterator called")
		-- end
	end)

	it("does not blow up with inlined children", function()
		-- // We don't suggest this since it silences all sorts of warnings, but we
		-- // shouldn't blow up either.

		local child = {
			["$$typeof"] = React.createElement("Frame")["$$typeof"],
			type = "Frame",
			key = nil,
			ref = nil,
			props = {},
			_owner = nil,
		}

		React.createElement("Frame", nil, { child })
	end)

	it("does not blow up on key warning with undefined type", function()
		local Foo = nil

		jestExpect(function()
			React.createElement(Foo, {
				__source = {
					fileName = "fileName.lua",
					lineNumber = 100,
				},
			}, { React.createElement("Frame") })
		end).toErrorDev(
			"Warning: React.createElement: type is invalid -- expected a string "
				.. "(for built-in components) or a class/function (for composite "
				.. "components) but got: nil. You likely forgot to export your "
				.. "component from the file it's defined in, or you might have mixed up "
				.. "default and named imports.\n\nCheck your code at **.",
			{ withoutStack = true }
		)
	end)

	it("does not call lazy initializers eagerly", function()
		local didCall = false
		local Lazy = React.lazy(function()
			didCall = true
			return { andThen = function() end }
		end)
		React.createElement(Lazy)
		jestExpect(didCall).toBe(false)
	end)

	-- ROBLOX deviation: validate extra warning when using table keys as the
	-- keys provided to child elements
	it("warns when keys are provided via both the 'key' prop AND table keys", function()
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement("Frame", nil, {
				a1 = React.createElement("Frame", { key = "a2" }),
				b = React.createElement("Frame", { key = "b" }),
			})
		end

		jestExpect(function()
			ReactTestUtils.renderIntoDocument(React.createElement(Component))
		end).toErrorDev(
			'Child element received a "key" prop ("a2") in addition to a key in '
				.. 'the "children" table of its parent ("a1"). Please provide only '
				.. 'one key definition. When both are present, the "key" prop '
				.. "will take precedence.\n\nCheck the render method of `Component`. "
				.. "See https://reactjs.org/link/warning-keys for more information.\n"
				.. "    in Frame (at **)\n"
				.. "    in Component (at **)"
		)
	end)
end)
