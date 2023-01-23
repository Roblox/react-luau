local createSignal = require(script.Parent.Parent["createSignal.roblox"])

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest

local it = JestGlobals.it

it("should fire subscribers and disconnect them", function()
	local subscribe, fire = createSignal()

	local spy = jest.fn()
	local disconnect = subscribe(function(...)
		spy(...)
	end)

	jestExpect(spy).never.toBeCalled()

	local a = 1
	local b = {}
	local c = "hello"
	fire(a, b, c)

	jestExpect(spy).toBeCalledTimes(1)
	jestExpect(spy).toBeCalledWith(a, b, c)

	disconnect()

	fire()

	jestExpect(spy).toBeCalledTimes(1)
end)

it("should handle multiple subscribers", function()
	local subscribe, fire = createSignal()

	local spyA = jest.fn()
	local spyB = jest.fn()

	local disconnectA = subscribe(function(...)
		spyA(...)
	end)
	local disconnectB = subscribe(function(...)
		spyB(...)
	end)

	jestExpect(spyA).never.toBeCalled()
	jestExpect(spyB).never.toBeCalled()

	local a = {}
	local b = 67
	fire(a, b)

	jestExpect(spyA).toBeCalledTimes(1)
	jestExpect(spyA).toBeCalledWith(a, b)

	jestExpect(spyB).toBeCalledTimes(1)
	jestExpect(spyB).toBeCalledWith(a, b)

	disconnectA()

	fire(b, a)

	jestExpect(spyA).toBeCalledTimes(1)

	jestExpect(spyB).toBeCalledTimes(2)
	jestExpect(spyB).toBeCalledWith(b, a)

	disconnectB()
end)

it("should stop firing a connection if disconnected mid-fire", function()
	local subscribe, fire = createSignal()

	-- In this test, we'll connect two listeners that each try to disconnect
	-- the other. Because the order of listeners firing isn't defined, we
	-- have to be careful to handle either case.

	local disconnectA
	local disconnectB

	local spyA = jest.fn(function()
		disconnectB()
	end)

	local spyB = jest.fn(function()
		disconnectA()
	end)

	disconnectA = subscribe(function(...)
		spyA(...)
	end)
	disconnectB = subscribe(function(...)
		spyB(...)
	end)

	fire()

	jestExpect(#spyA.mock.calls + #spyB.mock.calls).toBe(1)
end)
