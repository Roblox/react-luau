return function()
	local Packages = script.Parent.Parent.Parent.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local Type = require(script.Parent.Parent.Parent.Type)

	local Change = require(script.Parent.Parent.Change)

	it("should yield change listener objects when indexed", function()
		jestExpect(Type.of(Change.Text)).toBe(Type.HostChangeEvent)
		jestExpect(Type.of(Change.Selected)).toBe(Type.HostChangeEvent)
	end)

	it("should yield the same object when indexed again", function()
		local a = Change.Text
		local b = Change.Text
		local c = Change.Selected

		jestExpect(a).toBe(b)
		jestExpect(a).never.toBe(c)
	end)
end