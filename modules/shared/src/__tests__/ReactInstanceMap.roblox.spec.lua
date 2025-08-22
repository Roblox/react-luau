-- ROBLOX deviation: we have a crash in production this deviant logic will help catch
-- ROBLOX TODO: make this only pass in __DEV__

local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local ReactInstanceMap = require(Packages.Shared).ReactInstanceMap

local __DEV__ = ReactGlobals.__DEV__ :: boolean
local SafeFlags = require(Packages.SafeFlags)
local GetFFlagReactInstanceMapDisableErrorChecking =
	SafeFlags.createGetFFlag("ReactInstanceMapDisableErrorChecking")
local FFlagReactInstanceMapDisableErrorChecking =
	GetFFlagReactInstanceMapDisableErrorChecking()

local errorsEnabled = not FFlagReactInstanceMapDisableErrorChecking or __DEV__

describe("get", function()
	it("with invalid fiber", function()
		local elementWithBadFiber = {
			_reactInternals = {
				tag = 0,
				-- missing key fields of Fiber
			},
		}
		if errorsEnabled then
			jestExpect(function()
				ReactInstanceMap.get(elementWithBadFiber)
			end).toThrow(
				"invalid fiber in UNNAMED Component during get from ReactInstanceMap!"
			)
		else
			jestExpect(function()
				ReactInstanceMap.get(elementWithBadFiber)
			end).never.toThrow(
				"invalid fiber in UNNAMED Component during get from ReactInstanceMap!"
			)
		end
	end)
	it("with valid fiber that has invalid alternate", function()
		local elementWithGoodFiberBadAlternate = {
			_reactInternals = {
				tag = 0,
				subtreeFlags = 0,
				lanes = 0,
				childLanes = 0,
				alternate = {
					tag = 1,
					-- missing key fields of Fiber
				},
			},
		}
		if errorsEnabled then
			jestExpect(function()
				ReactInstanceMap.get(elementWithGoodFiberBadAlternate)
			end).toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component during get from ReactInstanceMap!"
			)
		else
			jestExpect(function()
				ReactInstanceMap.get(elementWithGoodFiberBadAlternate)
			end).never.toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component during get from ReactInstanceMap!"
			)
		end
	end)
end)
describe("set", function()
	it("with invalid fiber", function()
		local badFiber = {
			tag = 0,
			-- missing key fields of Fiber
		}
		if errorsEnabled then
			jestExpect(function()
				ReactInstanceMap.set({ displayName = "MyComponent" }, badFiber)
			end).toThrow("invalid fiber in MyComponent being set in ReactInstanceMap!")
		else
			jestExpect(function()
				ReactInstanceMap.set({ displayName = "MyComponent" }, badFiber)
			end).never.toThrow(
				"invalid fiber in MyComponent being set in ReactInstanceMap!"
			)
		end
	end)
	it("with valid fiber with no return that has invalid alternate", function()
		local goodFiberBadAlternate = {
			tag = 0,
			subtreeFlags = 0,
			lanes = 0,
			childLanes = 0,
			alternate = {
				tag = 1,
				-- missing key fields of Fiber
			},
		}
		if errorsEnabled then
			jestExpect(function()
				ReactInstanceMap.set({}, goodFiberBadAlternate)
			end).toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component being set in ReactInstanceMap!"
			)
		else
			jestExpect(function()
				ReactInstanceMap.set({}, goodFiberBadAlternate)
			end).never.toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component being set in ReactInstanceMap!"
			)
		end
	end)
	it("with valid fiber with a valid return_ that has invalid alternate", function()
		local goodFiberGoodReturnBadAlternate = {
			tag = 0,
			subtreeFlags = 0,
			lanes = 0,
			childLanes = 0,
			alternate = {
				tag = 1,
				subtreeFlags = 1,
				lanes = 1,
				childLanes = 1,
			},
			return_ = {
				tag = 2,
				subtreeFlags = 2,
				lanes = 2,
				childLanes = 2,
				alternate = {
					tag = 3,
					-- missing key fields of Fiber
				},
			},
		}
		if errorsEnabled then
			jestExpect(function()
				ReactInstanceMap.set({}, goodFiberGoodReturnBadAlternate)
			end).toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component being set in ReactInstanceMap! { tag: 3 }\n (from original fiber UNNAMED Component)"
			)
		else
			jestExpect(function()
				ReactInstanceMap.set({}, goodFiberGoodReturnBadAlternate)
			end).never.toThrow(
				"invalid alternate fiber (UNNAMED alternate) in UNNAMED Component being set in ReactInstanceMap! { tag: 3 }\n (from original fiber UNNAMED Component)"
			)
		end
	end)
end)
