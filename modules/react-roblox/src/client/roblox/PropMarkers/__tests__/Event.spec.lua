return function()
	local Packages = script.Parent.Parent.Parent.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local Type = require(script.Parent.Parent.Parent.Type)

	local Event = require(script.Parent.Parent.Event)

	it("should yield event objects when indexed", function()
		jestExpect(Type.of(Event.MouseButton1Click)).toBe(Type.HostEvent)
		jestExpect(Type.of(Event.Touched)).toBe(Type.HostEvent)
	end)

	it("should yield the same object when indexed again", function()
		local a = Event.MouseButton1Click
		local b = Event.MouseButton1Click
		local c = Event.Touched

		jestExpect(a).toBe(b)
		jestExpect(a).never.toBe(c)
	end)
end