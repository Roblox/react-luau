local Packages = script.Parent.Parent.Parent
local React

local ReactNoop
local Scheduler
local JestGlobals = require(Packages.Dev.JestGlobals)
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error

describe("tests propTypes and validateProps behavior", function()
	beforeEach(function()
		jest.resetModules()
		ReactNoop = require(Packages.Dev.ReactNoop)
		Scheduler = require(Packages.Dev.Scheduler)
		React = require(Packages.Dev.React)
	end)
	it("propTypes defined, returns error", function()
		local Foo = React.Component:extend("div")

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				return Error("no no no no no")
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end
		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)
		end).toWarnDev("no no no no no")
	end)
	it("propTypes defined, returns nil", function()
		local Foo = React.Component:extend("Foo")

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				return nil
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end
		ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
		jestExpect(Scheduler).toFlushWithoutYielding()
	end)
	it("validateProps defined, returns false", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return false, "no no no no no"
		end

		function Foo:render()
			return React.createElement("div")
		end
		local function testValidation()
			ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
			jestExpect(Scheduler).toFlushWithoutYielding()
		end
		if _G.__DEV__ then
			-- For legacy compatibility, this test throws as well as warning
			jestExpect(testValidation).toThrow("no no no no no")
		else
			jestExpect(testValidation).never.toThrow()
		end
	end)
	it("validateProps defined, returns true", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return true
		end

		function Foo:render()
			return React.createElement("div")
		end

		ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
		jestExpect(Scheduler).toFlushWithoutYielding()
	end)
	it("warning when both methods are defined", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return true
		end

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				return nil
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end

		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)
		end).toWarnDev(
			"You've defined both propTypes and validateProps on Foo",
			{ withoutStack = true }
		)
	end)
	it("validateProps fails, propTypes fails", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return false, "no no no no no"
		end

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				error(Error("no no no no no"))
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end

		local function testValidation()
			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
					jestExpect(Scheduler).toFlushWithoutYielding()
				end)
			end).toWarnDev(
				"You've defined both propTypes and validateProps on Foo",
				{ withoutStack = 2 }
			)
		end
		if _G.__DEV__ then
			-- For legacy compatibility, this test throws as well as warning
			jestExpect(testValidation).toThrow("no no no no no")
		else
			jestExpect(testValidation).never.toThrow()
		end
	end)
	it("validateProps succeeds, propTypes fails", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return true
		end

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				error(Error("no no no no no"))
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end

		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)
		end).toWarnDev({
			"You've defined both propTypes and validateProps on Foo",
			"no no no no no",
		}, { withoutStack = 1 })
	end)
	it("validateProps fails, propTypes succeeds", function()
		local Foo = React.Component:extend("Foo")

		Foo.validateProps = function(props)
			return false, "no no no no no"
		end

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				return nil
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end

		local function testValidation()
			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
					jestExpect(Scheduler).toFlushWithoutYielding()
				end)
			end).toWarnDev(
				"You've defined both propTypes and validateProps on Foo",
				{ withoutStack = 2 }
			)
		end
		if _G.__DEV__ then
			-- For legacy compatibility, this test throws as well as warning
			jestExpect(testValidation).toThrow("no no no no no")
		else
			jestExpect(testValidation).never.toThrow()
		end
	end)
	it("bad propTypes method", function()
		local Foo = React.Component:extend("Foo")

		Foo.propTypes = {
			myProp = function(prop, propName, componentName)
				return "nil"
			end,
		}

		function Foo:render()
			return React.createElement("div")
		end

		jestExpect(function()
			ReactNoop.act(function()
				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end)
		end).toErrorDev({
			"Foo: type specification of prop"
				.. " `myProp` is invalid; the type checker "
				.. "function must return `nil` or an `Error` but returned a string. "
				.. "You may have forgotten to pass an argument to the type checker "
				.. "creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and "
				.. "shape all require an argument).",
		})
	end)
	it("bad validateProps method", function()
		local Foo = React.Component:extend("Foo")

		function Foo:render()
			return React.createElement("div")
		end

		jestExpect(Scheduler).toFlushWithoutYielding()
		jestExpect(function()
			ReactNoop.act(function()
				Foo.validateProps = "this is a string"

				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
			end)
		end).toErrorDev({
			'validateProps must be a function, but it is a string.\nCheck the definition of the component "Foo".',
		}, { withoutStack = 1 })
	end)

	describe("__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__", function()
		beforeEach(function(context)
			context.oldValidate = _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__
			_G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ = true
		end)

		afterEach(function(context)
			_G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ = context.oldValidate
		end)

		it("validateProps defined, returns false", function()
			local Foo = React.Component:extend("Foo")

			Foo.validateProps = function(props)
				return false, "no no no no no"
			end

			function Foo:render()
				return React.createElement("div")
			end
			local function testValidation()
				ReactNoop.render(React.createElement(Foo, { myProp = "hello" }))
				jestExpect(Scheduler).toFlushWithoutYielding()
			end

			-- For legacy compatibility, this test throws as well as warning
			if _G.__DEV__ then
				jestExpect(testValidation).toThrow("no no no no no")
			else
				jestExpect(testValidation).never.toThrow()
			end
		end)
	end)
end)
