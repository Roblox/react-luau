local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local React

local getComponentName
local function MyComponent() end
local anonymous = function() end

beforeEach(function()
	React = require(Packages.Dev.React)

	getComponentName = require(Packages.Shared).getComponentName
end)

describe("function components", function()
	it("gets name from non-anonymous function", function()
		jestExpect(getComponentName(MyComponent)).toBe("MyComponent")
	end)
	it("gets nil from anonymous function", function()
		local anonymous = function() end
		jestExpect(getComponentName(anonymous)).toBe(nil)
	end)
end)
describe("Lazy components", function()
	it("gets name from lazy-wrapped non-anonymous function", function()
		local lazyMyComponent = React.lazy(function()
			return {
				andThen = function(self, resolve)
					resolve({ default = MyComponent })
				end,
			}
		end)
		jestExpect(getComponentName(lazyMyComponent)).toBe("MyComponent")
	end)
	it("gets nil from lazy-wrapped anonymous function", function()
		local lazyAnonymous = React.lazy(function()
			return {
				andThen = function(self, resolve)
					resolve({ default = anonymous })
				end,
			}
		end)
		jestExpect(getComponentName(lazyAnonymous)).toBe(nil)
	end)
end)
