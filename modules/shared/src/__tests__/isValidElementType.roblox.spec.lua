local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local isValidElementType = require(Packages.Shared).isValidElementType
local ReactSymbols = require(Packages.Shared).ReactSymbols
local element

describe("accept element primitives", function()
	it("from strings", function()
		element = "TextLabel"
		jestExpect(isValidElementType(element)).toBe(true)
	end)

	it("from functions", function()
		element = function() end
		jestExpect(isValidElementType(element)).toBe(true)
	end)

	it("from tables", function()
		element = {}
		element["$$typeof"] = ReactSymbols.REACT_CONTEXT_TYPE
		jestExpect(isValidElementType(element)).toBe(true)
	end)
end)

describe("does not accept", function()
	it("REACT_ELEMENT_TYPE", function()
		element = {}
		element["$$typeof"] = ReactSymbols.REACT_ELEMENT_TYPE
		jestExpect(isValidElementType(element)).toBe(false)
	end)
end)
