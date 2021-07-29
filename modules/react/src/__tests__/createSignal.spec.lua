return function()
	local createSignal = require(script.Parent.Parent["createSignal.roblox"])

	local Packages = script.Parent.Parent.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect
	local jest = jestModule.Globals.jest

	it("should fire subscribers and disconnect them", function()
		local signal = createSignal()

		local spy = jest:fn()
		local disconnect = signal:subscribe(
			function(...) spy(...) end
		)

		jestExpect(spy).never.toBeCalled()

		local a = 1
		local b = {}
		local c = "hello"
		signal:fire(a, b, c)

		jestExpect(spy).toBeCalledTimes(1)
		jestExpect(spy).toBeCalledWith(a, b, c)

		disconnect()

		signal:fire()

		jestExpect(spy).toBeCalledTimes(1)
	end)

	it("should handle multiple subscribers", function()
		local signal = createSignal()

		local spyA = jest:fn()
		local spyB = jest:fn()

		local disconnectA = signal:subscribe(
			function(...) spyA(...) end
		)
		local disconnectB = signal:subscribe(
			function(...) spyB(...) end
		)

		jestExpect(spyA).never.toBeCalled()
		jestExpect(spyB).never.toBeCalled()

		local a = {}
		local b = 67
		signal:fire(a, b)

		jestExpect(spyA).toBeCalledTimes(1)
		jestExpect(spyA).toBeCalledWith(a, b)

		jestExpect(spyB).toBeCalledTimes(1)
		jestExpect(spyB).toBeCalledWith(a, b)

		disconnectA()

		signal:fire(b, a)

		jestExpect(spyA).toBeCalledTimes(1)

		jestExpect(spyB).toBeCalledTimes(2)
		jestExpect(spyB).toBeCalledWith(b, a)

		disconnectB()
	end)

	it("should stop firing a connection if disconnected mid-fire", function()
		local signal = createSignal()

		-- In this test, we'll connect two listeners that each try to disconnect
		-- the other. Because the order of listeners firing isn't defined, we
		-- have to be careful to handle either case.

		local disconnectA
		local disconnectB

		local spyA = jest:fn(function()
			disconnectB()
		end)

		local spyB = jest:fn(function()
			disconnectA()
		end)

		disconnectA = signal:subscribe(
			function(...) spyA(...) end
		)
		disconnectB = signal:subscribe(
			function(...) spyB(...) end
		)

		signal:fire()

		jestExpect(#spyA.mock.calls + #spyB.mock.calls).toBe(1)

	end)
end