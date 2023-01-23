--!strict
local Packages = script.Parent.Parent.Parent
local ReactBaseClasses = require(script.Parent.Parent.ReactBaseClasses)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local Component = ReactBaseClasses.Component
local PureComponent = ReactBaseClasses.Component
local component

describe("Component", function()
	it("should prevent extending a second time", function()
		component = Component:extend("Sheev")

		jestExpect(function()
			(component :: any):extend("Frank")
		end).toThrow()
	end)

	it("should use a given name", function()
		component = Component:extend("FooBar")

		local name = tostring(component)

		jestExpect(name).toEqual(jestExpect.any("string"))
		jestExpect(name).toContain("FooBar")
	end)
end)

describe("PureComponent", function()
	it("should prevent extending a second time", function()
		component = PureComponent:extend("Sheev")

		jestExpect(function()
			(component :: any):extend("Frank")
		end).toThrow()
	end)

	it("should use a given name", function()
		component = PureComponent:extend("FooBar")

		local name = tostring(component)

		jestExpect(name).toEqual(jestExpect.any("string"))
		jestExpect(name).toContain("FooBar")
	end)
end)
