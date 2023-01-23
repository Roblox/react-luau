-- ROBLOX upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/__tests__/ReactChildren-test.js
--!nonstrict
--[[
	**
	* Copyright (c) Facebook, Inc. and its affiliates.
	*
	* This source code is licensed under the MIT license found in the
	* LICENSE file in the root directory of this source tree.
	*
	* @emails react-core
]]
local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local React
local ReactTestUtils
local ReactRoblox
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local xit = JestGlobals.xit

describe("ReactChildren", function()
	beforeEach(function()
		jest.resetModules()
		React = require(script.Parent.Parent)
		ReactRoblox = require(Packages.Dev.ReactRoblox)
		ReactTestUtils = {
			renderIntoDocument = function(element)
				local instance = Instance.new("Folder")
				local root = ReactRoblox.createLegacyRoot(instance)
				root:render(element)
				return root
			end,
		}
	end)

	it("should support identity for simple", function()
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid, index)
			-- ROBLOX DEVIATION: no "this" in luau
			-- expect(self).toBe(context)
			return kid
		end)
		local simpleKid = React.createElement("span", { key = "simple" }) -- First pass children into a component to fully simulate what happens when
		-- using structures that arrive from transforms.
		local instance = React.createElement("span", nil, simpleKid)
		React.Children.forEach(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		callback.mockClear()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		expect(mappedChildren[1]).toEqual(
			React.createElement("span", { key = ".$simple" })
		)
	end)

	it("should support Portal components", function()
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid, index)
			-- expect(self).toBe(context)
			return kid
		end)
		-- local ReactDOM = require("react-dom")
		local portalContainer = Instance.new("Folder")
		local simpleChild = React.createElement("Frame", { key = "simple" })
		local reactPortal = ReactRoblox.createPortal(simpleChild, portalContainer)
		local parentInstance = React.createElement("Frame", nil, reactPortal)
		React.Children.forEach(parentInstance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(reactPortal, 1)
		callback.mockClear()
		local mappedChildren =
			React.Children.map(parentInstance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(reactPortal, 1)
		expect(mappedChildren[1]).toEqual(reactPortal)
	end)

	it("should treat single arrayless child as being in array", function()
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid, index)
			-- expect(self).toBe(context)
			return kid
		end)
		local simpleKid = React.createElement("span", nil)
		local instance = React.createElement("div", nil, simpleKid)
		React.Children.forEach(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		callback.mockClear()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		expect(mappedChildren[1]).toEqual(React.createElement("span", { key = ".1" }))
	end)

	it("should treat single child in array as expected", function()
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid, index)
			-- expect(self).toBe(context)
			return kid
		end)
		local simpleKid = React.createElement("span", { key = "simple" })
		local instance = React.createElement("div", nil, { simpleKid })
		React.Children.forEach(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		callback.mockClear()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		expect(callback).toHaveBeenCalledWith(simpleKid, 1)
		expect(mappedChildren[1]).toEqual(
			React.createElement("span", { key = ".$simple" })
		)
	end)

	it("should be called for each child", function()
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local instance = React.createElement("div", nil, zero, one, two, three, four)
		local function assertCalls()
			-- ROBLOX DEVIATION: React.None children will be passed as nil to callback
			expect(callback).toHaveBeenCalledTimes(5)
			expect(callback).toHaveBeenCalledWith(zero, 1)
			expect(callback).toHaveBeenCalledWith(nil, 2)
			expect(callback).toHaveBeenCalledWith(two, 3)
			expect(callback).toHaveBeenCalledWith(nil, 4)
			expect(callback).toHaveBeenCalledWith(four, 5)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".$keyZero" }),
			React.createElement("div", { key = ".$keyTwo" }),
			React.createElement("div", { key = ".$keyFour" }),
		})
	end)

	it("should traverse children of different kinds", function()
		local div = React.createElement("div", { key = "divNode" })
		local span = React.createElement("span", { key = "spanNode" })
		local a = React.createElement("a", { key = "aNode" })
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local instance = React.createElement(
			"div",
			nil,
			div,
			{ { span } },
			{ a },
			"string",
			1234,
			true,
			false,
			-- Include nil children as React.None
			React.None,
			React.None
		)
		local function assertCalls()
			expect(callback).toHaveBeenCalledTimes(9)
			expect(callback).toHaveBeenCalledWith(div, 1)
			expect(callback).toHaveBeenCalledWith(span, 2)
			expect(callback).toHaveBeenCalledWith(a, 3)
			expect(callback).toHaveBeenCalledWith("string", 4)
			expect(callback).toHaveBeenCalledWith(1234, 5)
			expect(callback).toHaveBeenCalledWith(nil, 6)
			expect(callback).toHaveBeenCalledWith(nil, 7)
			expect(callback).toHaveBeenCalledWith(nil, 8)
			expect(callback).toHaveBeenCalledWith(nil, 9)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".$divNode" }),
			React.createElement("span", { key = ".2:1:$spanNode" }),
			React.createElement("a", { key = ".3:$aNode" }),
			"string",
			1234,
		})
	end)

	it("should be called for each child in nested structure", function()
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local five = React.createElement("div", { key = "keyFive" })
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			return kid
		end)
		local instance =
			React.createElement("div", nil, { { zero, one, two }, { three, four }, five })
		local function assertCalls()
			-- ROBLOX DEVIATION: React.None children are interpreted as nil in callbacks
			expect(callback).toHaveBeenCalledTimes(6)
			expect(callback).toHaveBeenCalledWith(zero, 1)
			expect(callback).toHaveBeenCalledWith(nil, 2)
			expect(callback).toHaveBeenCalledWith(two, 3)
			expect(callback).toHaveBeenCalledWith(nil, 4)
			expect(callback).toHaveBeenCalledWith(four, 5)
			expect(callback).toHaveBeenCalledWith(five, 6)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".1:$keyZero" }),
			React.createElement("div", { key = ".1:$keyTwo" }),
			React.createElement("div", { key = ".2:$keyFour" }),
			React.createElement("div", { key = ".$keyFive" }),
		})
	end)

	it("should retain key across two mappings", function()
		local zeroForceKey = React.createElement("div", { key = "keyZero" })
		local oneForceKey = React.createElement("div", { key = "keyOne" })
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local forcedKeys = React.createElement("div", nil, zeroForceKey, oneForceKey)
		local function assertCalls()
			expect(callback).toHaveBeenCalledWith(zeroForceKey, 1)
			expect(callback).toHaveBeenCalledWith(oneForceKey, 2)
			callback.mockClear()
		end
		React.Children.forEach(forcedKeys.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(forcedKeys.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".$keyZero" }),
			React.createElement("div", { key = ".$keyOne" }),
		})
	end)

	-- ROBLOX DEVIATION: Iterators are not supported by default in Roblox
	xit("should be called for each child in an iterable without keys", function()
		local threeDivIterable = {
			["@@iterator"] = function(self)
				local i = 0
				return {
					next = function(self)
						if
							(function()
								local result = i
								i += 1
								return result
							end)()
							< 3 --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
						then
							return {
								value = React.createElement("div", nil),
								done = false,
							}
						else
							return { value = nil, done = true }
						end
					end,
				}
			end,
		}
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local instance
		expect(function()
			instance = React.createElement("div", nil, threeDivIterable)
			return instance
		end).toErrorDev(
			'Warning: Each child in a list should have a unique "key" prop.'
		)
		local function assertCalls()
			expect(callback).toHaveBeenCalledTimes(3)
			expect(callback).toHaveBeenCalledWith(React.createElement("div", nil), 0)
			expect(callback).toHaveBeenCalledWith(React.createElement("div", nil), 1)
			expect(callback).toHaveBeenCalledWith(React.createElement("div", nil), 2)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".0" }),
			React.createElement("div", { key = ".1" }),
			React.createElement("div", { key = ".2" }),
		})
	end)

	-- ROBLOX DEVIATION: no @@iterator in Luau
	xit("should be called for each child in an iterable with keys", function()
		local threeDivIterable = {
			["@@iterator"] = function(self)
				local i = 0
				return {
					next = function(self)
						if
							(function()
								local result = i
								i += 1
								return result
							end)()
							< 3 --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
						then
							return {
								value = React.createElement(
									"div",
									{ key = "#" .. tostring(i) }
								),
								done = false,
							}
						else
							return { value = nil, done = true }
						end
					end,
				}
			end,
		}
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local instance = React.createElement("div", nil, threeDivIterable)
		local function assertCalls()
			expect(callback).toHaveBeenCalledTimes(3)
			expect(callback).toHaveBeenCalledWith(
				React.createElement("div", { key = "#1" }),
				0
			)
			expect(callback).toHaveBeenCalledWith(
				React.createElement("div", { key = "#2" }),
				1
			)
			expect(callback).toHaveBeenCalledWith(
				React.createElement("div", { key = "#3" }),
				2
			)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".$#1" }),
			React.createElement("div", { key = ".$#2" }),
			React.createElement("div", { key = ".$#3" }),
		})
	end)

	-- ROBLOX DEVIATION: Number prototype and iterables not relevant in luau
	-- it("should not enumerate enumerable numbers (#4776)", function()
	-- 	--[[eslint-disable no-extend-native ]]
	-- 	-- Number.prototype["@@iterator"] = function()
	-- 	-- 	error(Error.new("number iterator called"))
	-- 	-- end
	-- 	--[[eslint-enable no-extend-native ]]
	-- 	do --[[ ROBLOX COMMENT: try-finally block conversion ]]
	-- 		local ok, result, hasReturned = pcall(function()
	-- 			local instance = React.createElement("div", nil, 5, 12, 13)
	-- 			local context = {}
	-- 			local callback = jest.fn().mockImplementation(function(kid)
	-- 				-- expect(self).toBe(context)
	-- 				return kid
	-- 			end)
	-- 			local function assertCalls()
	-- 				expect(callback).toHaveBeenCalledTimes(3)
	-- 				expect(callback).toHaveBeenCalledWith(5, 0)
	-- 				expect(callback).toHaveBeenCalledWith(12, 1)
	-- 				expect(callback).toHaveBeenCalledWith(13, 2)
	-- 				callback.mockClear()
	-- 			end
	-- 			React.Children.forEach(instance.props.children, callback, context)
	-- 			assertCalls()
	-- 			local mappedChildren = React.Children.map(
	-- 				instance.props.children,
	-- 				callback,
	-- 				context
	-- 			)
	-- 			assertCalls()
	-- 			expect(mappedChildren).toEqual({ 5, 12, 13 })
	-- 		end)
	-- 		do
	-- 			-- Number.prototype["@@iterator"] = nil
	-- 		end
	-- 		if hasReturned then
	-- 			return result
	-- 		end
	-- 		if not ok then
	-- 			error(result)
	-- 		end
	-- 	end
	-- end)

	--ROBLOX NOTE: This test passes, but is not needed
	it("should allow extension of native prototypes", function()
		--[[eslint-disable no-extend-native ]]
		-- String.prototype.key = "react"
		-- Number.prototype.key = "rocks"
		--[[eslint-enable no-extend-native ]]
		local instance = React.createElement("div", nil, "a", 13)
		local context = {}
		local callback = jest.fn().mockImplementation(function(kid)
			-- expect(self).toBe(context)
			return kid
		end)
		local function assertCalls()
			expect(callback).toHaveBeenCalledTimes(2, 0)
			expect(callback).toHaveBeenCalledWith("a", 1)
			expect(callback).toHaveBeenCalledWith(13, 2)
			callback.mockClear()
		end
		React.Children.forEach(instance.props.children, callback, context)
		assertCalls()
		local mappedChildren =
			React.Children.map(instance.props.children, callback, context)
		assertCalls()
		expect(mappedChildren).toEqual({ "a", 13 })
		-- String.prototype.key = nil
		-- Number.prototype.key = nil
	end)

	it("should pass key to returned component", function()
		local function mapFn(kid, index)
			return React.createElement("div", nil, kid)
		end
		local simpleKid = React.createElement("span", { key = "simple" })
		local instance = React.createElement("div", nil, simpleKid)
		local mappedChildren = React.Children.map(instance.props.children, mapFn)
		expect(React.Children.count(mappedChildren)).toBe(1)
		expect(mappedChildren[1]).never.toBe(simpleKid)
		expect(((mappedChildren[1]).props).children).toBe(simpleKid)
		expect((mappedChildren[1]).key).toBe(".$simple")
	end)

	-- ROBLOX DEVIATION: no "this" in luau, ignore context passed to callback
	-- it("should invoke callback with the right context", function()
	-- 	local lastContext
	-- 	local function callback(kid, index)
	-- 		-- lastContext = self
	-- 		-- return self
	-- 	end -- TODO: Use an object to test, after non-object fragments has fully landed.
	-- 	local scopeTester = "scope tester"
	-- 	local simpleKid = React.createElement("span", { key = "simple" })
	-- 	local instance = React.createElement("div", nil, simpleKid)
	-- 	React.Children.forEach(instance.props.children, callback, scopeTester)
	-- 	expect(lastContext).toBe(scopeTester)
	-- 	local mappedChildren = React.Children.map(
	-- 		instance.props.children,
	-- 		callback,
	-- 		scopeTester
	-- 	)
	-- 	expect(React.Children.count(mappedChildren)).toBe(1)
	-- 	expect(mappedChildren[1]).toBe(scopeTester)
	-- end)

	it("should be called for each child 2", function()
		-- ROBLOX DEVIATION: Use React.None instead of nil
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local mapped = {
			React.createElement("div", { key = "giraffe" }), -- Key should be joined to obj key
			nil, -- Key should be added even if we don't supply it!
			React.createElement("div", nil), -- Key should be added even if not supplied!
			React.createElement("span", nil), -- Map from null to something.
			React.createElement("div", { key = "keyFour" }),
		}
		local callback = jest.fn().mockImplementation(function(kid, index)
			return mapped[index]
		end)
		local instance = React.createElement("div", nil, zero, one, two, three, four)
		React.Children.forEach(instance.props.children, callback)
		expect(callback).toHaveBeenCalledWith(zero, 1)
		-- ROBLOX DEVIATION: React.None gets treated as nil for callback
		expect(callback).toHaveBeenCalledWith(nil, 2)
		expect(callback).toHaveBeenCalledWith(two, 3)
		expect(callback).toHaveBeenCalledWith(nil, 4)
		expect(callback).toHaveBeenCalledWith(four, 5)
		callback.mockClear()
		local mappedChildren = React.Children.map(instance.props.children, callback)
		expect(callback).toHaveBeenCalledTimes(5)
		expect(React.Children.count(mappedChildren)).toBe(4) -- Keys default to indices.
		expect({
			mappedChildren[1].key,
			mappedChildren[2].key,
			mappedChildren[3].key,
			mappedChildren[4].key,
		}).toEqual({ "giraffe/.$keyZero", ".$keyTwo", ".4", ".$keyFour" })
		expect(callback).toHaveBeenCalledWith(zero, 1)
		-- ROBLOX DEVIATION: React.None gets treated as nil for callback
		expect(callback).toHaveBeenCalledWith(nil, 2)
		expect(callback).toHaveBeenCalledWith(two, 3)
		expect(callback).toHaveBeenCalledWith(nil, 4)
		expect(callback).toHaveBeenCalledWith(four, 5)
		expect(mappedChildren[1]).toEqual(
			React.createElement("div", { key = "giraffe/.$keyZero" })
		)
		expect(mappedChildren[2]).toEqual(
			React.createElement("div", { key = ".$keyTwo" })
		)
		expect(mappedChildren[3]).toEqual(React.createElement("span", { key = ".4" }))
		expect(mappedChildren[4]).toEqual(
			React.createElement("div", { key = ".$keyFour" })
		)
	end)

	it("should be called for each child in nested structure 2", function()
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local five = React.createElement("div", { key = "keyFive" })
		local zeroMapped = React.createElement("div", { key = "giraffe" }) -- Key should be overridden
		local twoMapped = React.createElement("div", nil) -- Key should be added even if not supplied!
		local fourMapped = React.createElement("div", { key = "keyFour" })
		local fiveMapped = React.createElement("div", nil)
		local callback = jest.fn().mockImplementation(function(kid)
			repeat --[[ ROBLOX comment: switch statement conversion ]]
				local entered_, break_ = false, false
				local condition_ = kid
				for _, v in { zero, two, four, five } do
					if condition_ == v then
						if v == zero then
							entered_ = true
							return zeroMapped
						end
						if v == two or entered_ then
							entered_ = true
							return twoMapped
						end
						if v == four or entered_ then
							entered_ = true
							return fourMapped
						end
						if v == five or entered_ then
							entered_ = true
							return fiveMapped
						end
					end
				end
				if not break_ then
					return kid
				end
			until true
			return
		end)
		local frag = { { zero, one, two }, { three, four }, five }
		local instance = React.createElement("div", nil, { frag })
		React.Children.forEach(instance.props.children, callback)
		expect(callback).toHaveBeenCalledTimes(6)
		expect(callback).toHaveBeenCalledWith(zero, 1)
		-- ROBLOX DEVIATION: React.None gets treated as nil for callback
		expect(callback).toHaveBeenCalledWith(nil, 2)
		expect(callback).toHaveBeenCalledWith(two, 3)
		expect(callback).toHaveBeenCalledWith(nil, 4)
		expect(callback).toHaveBeenCalledWith(four, 5)
		expect(callback).toHaveBeenCalledWith(five, 6)
		callback.mockClear()
		local mappedChildren = React.Children.map(instance.props.children, callback)
		expect(callback).toHaveBeenCalledTimes(6)
		expect(callback).toHaveBeenCalledWith(zero, 1)
		-- ROBLOX DEVIATION: React.None gets treated as nil for callback
		expect(callback).toHaveBeenCalledWith(nil, 2)
		expect(callback).toHaveBeenCalledWith(two, 3)
		expect(callback).toHaveBeenCalledWith(nil, 4)
		expect(callback).toHaveBeenCalledWith(four, 5)
		expect(callback).toHaveBeenCalledWith(five, 6)
		expect(React.Children.count(mappedChildren)).toBe(4) -- Keys default to indices.
		expect({
			mappedChildren[1].key,
			mappedChildren[2].key,
			mappedChildren[3].key,
			mappedChildren[4].key,
		}).toEqual({
			"giraffe/.1:1:$keyZero",
			".1:1:$keyTwo",
			".1:2:$keyFour",
			".1:$keyFive",
		})
		expect(mappedChildren[1]).toEqual(
			React.createElement("div", { key = "giraffe/.1:1:$keyZero" })
		)
		expect(mappedChildren[2]).toEqual(
			React.createElement("div", { key = ".1:1:$keyTwo" })
		)
		expect(mappedChildren[3]).toEqual(
			React.createElement("div", { key = ".1:2:$keyFour" })
		)
		expect(mappedChildren[4]).toEqual(
			React.createElement("div", { key = ".1:$keyFive" })
		)
	end)

	it("should retain key across two mappings 2", function()
		local zeroForceKey = React.createElement("div", { key = "keyZero" })
		local oneForceKey = React.createElement("div", { key = "keyOne" }) -- Key should be joined to object key
		local zeroForceKeyMapped = React.createElement("div", { key = "giraffe" }) -- Key should be added even if we don't supply it!
		local oneForceKeyMapped = React.createElement("div", nil)
		local function mapFn(kid, index)
			return (function()
				if index == 1 then
					return zeroForceKeyMapped
				else
					return oneForceKeyMapped
				end
			end)()
		end
		local forcedKeys = React.createElement("div", nil, zeroForceKey, oneForceKey)
		local expectedForcedKeys = { "giraffe/.$keyZero", ".$keyOne" }
		local mappedChildrenForcedKeys =
			React.Children.map(forcedKeys.props.children, mapFn)
		local mappedForcedKeys = Array.map(mappedChildrenForcedKeys, function(c)
			return c.key
		end)
		expect(mappedForcedKeys).toEqual(expectedForcedKeys)
		local expectedRemappedForcedKeys = {
			"giraffe/.$giraffe/.$keyZero",
			".$.$keyOne",
		}
		local remappedChildrenForcedKeys =
			React.Children.map(mappedChildrenForcedKeys, mapFn)
		expect(Array.map(remappedChildrenForcedKeys, function(c)
			return c.key
		end)).toEqual(expectedRemappedForcedKeys)
	end)

	it("should not throw if key provided is a dupe with array key", function()
		local zero = React.createElement("div", nil)
		local one = React.createElement("div", { key = "0" })
		local function mapFn()
			return nil
		end
		local instance = React.createElement("div", nil, zero, one)
		expect(function()
			React.Children.map(instance.props.children, mapFn)
		end).never.toThrow()
	end)

	it("should use the same key for a cloned element", function()
		local instance = React.createElement("div", nil, React.createElement("div", nil))
		local mapped = React.Children.map(instance.props.children, function(element)
			return element
		end)
		local mappedWithClone = React.Children.map(
			instance.props.children,
			function(element)
				return React.cloneElement(element)
			end
		)
		expect(mapped[1].key).toBe(mappedWithClone[1].key)
	end)

	it("should use the same key for a cloned element with key", function()
		local instance = React.createElement(
			"div",
			nil,
			React.createElement("div", { key = "unique" })
		)
		local mapped = React.Children.map(instance.props.children, function(element)
			return element
		end)
		local mappedWithClone = React.Children.map(
			instance.props.children,
			function(element)
				return React.cloneElement(element, { key = "unique" })
			end
		)
		expect(mapped[1].key).toBe(mappedWithClone[1].key)
	end)

	it("should return 0 for null children", function()
		local numberOfChildren = React.Children.count(nil)
		expect(numberOfChildren).toBe(0)
	end)

	-- ROBLOX DEVIATION: This test doesn't make sense in luau, as there is no undefined
	-- it("should return 0 for undefined children", function()
	-- 	local numberOfChildren = React.Children.count(nil)
	-- 	expect(numberOfChildren).toBe(0)
	-- end)

	it("should return 1 for single child", function()
		local simpleKid = React.createElement("span", { key = "simple" })
		local instance = React.createElement("div", nil, simpleKid)
		local numberOfChildren = React.Children.count(instance.props.children)
		expect(numberOfChildren).toBe(1)
	end)

	it("should count the number of children in flat structure", function()
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local instance = React.createElement("div", nil, zero, one, two, three, four)
		local numberOfChildren = React.Children.count(instance.props.children)
		expect(numberOfChildren).toBe(5)
	end)

	it("should count the number of children in nested structure", function()
		local zero = React.createElement("div", { key = "keyZero" })
		local one = React.None
		local two = React.createElement("div", { key = "keyTwo" })
		local three = React.None
		local four = React.createElement("div", { key = "keyFour" })
		local five = React.createElement("div", { key = "keyFive" })
		local instance = React.createElement(
			"div",
			nil,
			{ { { zero, one, two }, { three, four }, five }, React.None }
		)
		local numberOfChildren = React.Children.count(instance.props.children)
		expect(numberOfChildren).toBe(7)
	end)

	it("should flatten children to an array", function()
		expect(React.Children.toArray(nil)).toEqual({})
		-- ROBLOX DEVIATION: React.None is omitted
		expect(React.Children.toArray(React.None)).toEqual({})
		expect(#(React.Children.toArray(React.createElement("div", nil)))).toBe(1)
		expect(#(React.Children.toArray({ React.createElement("div", nil) }))).toBe(1)
		expect((React.Children.toArray(React.createElement("div", nil)))[1].key).toBe(
			(React.Children.toArray({ React.createElement("div", nil) }))[1].key
		)
		local flattened = React.Children.toArray({
			{
				React.createElement("div", { key = "apple" }),
				React.createElement("div", { key = "banana" }),
				React.createElement("div", { key = "camel" }),
			},
			{
				React.createElement("div", { key = "banana" }),
				React.createElement("div", { key = "camel" }),
				React.createElement("div", { key = "deli" }),
			},
		})
		expect(#flattened).toBe(6)
		expect(flattened[2].key).toContain("banana")
		expect(flattened[4].key).toContain("banana")
		expect(flattened[2].key).never.toBe(flattened[4].key)
		local reversed = React.Children.toArray({
			{
				React.createElement("div", { key = "camel" }),
				React.createElement("div", { key = "banana" }),
				React.createElement("div", { key = "apple" }),
			},
			{
				React.createElement("div", { key = "deli" }),
				React.createElement("div", { key = "camel" }),
				React.createElement("div", { key = "banana" }),
			},
		})
		expect(flattened[1].key).toBe(reversed[3].key)
		expect(flattened[2].key).toBe(reversed[2].key)
		expect(flattened[3].key).toBe(reversed[1].key)
		expect(flattened[4].key).toBe(reversed[6].key)
		expect(flattened[5].key).toBe(reversed[5].key)
		expect(flattened[6].key).toBe(reversed[4].key)
		-- null/undefined/bool are all omitted
		-- ROBLOX DEVIATION: React.None is omitted
		expect(React.Children.toArray({ 1, "two", nil, React.None, true })).toEqual({
			1,
			"two",
		})
	end)

	it("should escape keys", function()
		local zero = React.createElement("div", { key = "1" })
		local one = React.createElement("div", { key = "1=::=2" })
		local instance = React.createElement("div", nil, zero, one)
		local mappedChildren = React.Children.map(instance.props.children, function(kid)
			return kid
		end)
		expect(mappedChildren).toEqual({
			React.createElement("div", { key = ".$1" }),
			React.createElement("div", { key = ".$1=0=2=2=02" }),
		})
	end)

	it("should combine keys when map returns an array", function()
		local instance = React.createElement(
			"div",
			nil,
			React.createElement("div", { key = "a" }),
			false,
			React.createElement("div", { key = "b" }),
			React.createElement("p", nil)
		)
		local mappedChildren = React.Children.map(
			instance.props.children,
			-- Try a few things: keyed, unkeyed, hole, and a cloned element.
			function(kid)
				return {
					React.createElement("span", { key = "x" }),
					React.None,
					React.createElement("span", { key = "y" }),
					-- ROBLOX DEVIATION: use React.None instead of nil
					kid or React.None,
					if kid and kid ~= React.None
						then React.cloneElement(kid, { key = "z" })
						else React.None,
					React.createElement("hr", nil),
				}
			end
		)
		expect(#mappedChildren).toBe(18)
		-- <div key="a">
		expect(mappedChildren[1].type).toBe("span")
		expect(mappedChildren[1].key).toBe(".$a/.$x")
		expect(mappedChildren[2].type).toBe("span")
		expect(mappedChildren[2].key).toBe(".$a/.$y")
		expect(mappedChildren[3].type).toBe("div")
		expect(mappedChildren[3].key).toBe(".$a/.$a")
		expect(mappedChildren[4].type).toBe("div")
		expect(mappedChildren[4].key).toBe(".$a/.$z")
		expect(mappedChildren[5].type).toBe("hr")
		expect(mappedChildren[5].key).toBe(".$a/.6")
		-- false
		expect(mappedChildren[6].type).toBe("span")
		expect(mappedChildren[6].key).toBe(".2/.$x")
		expect(mappedChildren[7].type).toBe("span")
		expect(mappedChildren[7].key).toBe(".2/.$y")
		expect(mappedChildren[8].type).toBe("hr")
		expect(mappedChildren[8].key).toBe(".2/.6")
		-- <div key="b">
		expect(mappedChildren[9].type).toBe("span")
		expect(mappedChildren[9].key).toBe(".$b/.$x")
		expect(mappedChildren[10].type).toBe("span")
		expect(mappedChildren[10].key).toBe(".$b/.$y")
		expect(mappedChildren[11].type).toBe("div")
		expect(mappedChildren[11].key).toBe(".$b/.$b")
		expect(mappedChildren[12].type).toBe("div")
		expect(mappedChildren[12].key).toBe(".$b/.$z")
		expect(mappedChildren[13].type).toBe("hr")
		expect(mappedChildren[13].key).toBe(".$b/.6")
		-- <p>
		expect(mappedChildren[14].type).toBe("span")
		expect(mappedChildren[14].key).toBe(".4/.$x")
		expect(mappedChildren[15].type).toBe("span")
		expect(mappedChildren[15].key).toBe(".4/.$y")
		expect(mappedChildren[16].type).toBe("p")
		expect(mappedChildren[16].key).toBe(".4/.4")
		expect(mappedChildren[17].type).toBe("p")
		expect(mappedChildren[17].key).toBe(".4/.$z")
		expect(mappedChildren[18].type).toBe("hr")
		expect(mappedChildren[18].key).toBe(".4/.6")
	end)

	-- ROBLOX DEVIATION: objects are treated as iterables in Roact, this will not throw
	-- it("should throw on object", function()
	-- 	expect(function()
	-- 		React.Children.forEach({ a = 1, b = 2 }, function() end, nil)
	-- 	end).toThrowError(
	-- 		"Objects are not valid as a React child (found: object with keys "
	-- 			.. "{a, b})."
	-- 			.. (if _G.__DEV__
	-- 				then " If you meant to render a collection of children, use an array instead."
	-- 				else "")
	-- 	)
	-- end)

	-- ROBLOX DEVIATION: no equivalent to this regex in luau
	-- it("should throw on regex", function()
	-- 	-- Really, we care about dates (#4840) but those have nondeterministic
	-- 	-- serialization (timezones) so let's test a regex instead:
	-- 	expect(function()
	-- 		React.Children.forEach(
	-- 			error("not implemented"), --[[ ROBLOX TODO: Unhandled node for type: RegExpLiteral ]] --[[ /abc/ ]]
	-- 			function() end,
	-- 			nil
	-- 		) --[[ ROBLOX CHECK: check if 'React.Children' is an Array ]]
	-- 	end).toThrowError(
	-- 		"Objects are not valid as a React child (found: /abc/)."
	-- 			.. 	if _G.__DEV__
	-- 				then " If you meant to render a collection of children, use an array instead."
	-- 				else ""
	-- 	)
	-- end)

	--ROBLOX DEVIATION START: Tables with keys should work with React.Children
	describe("with children as a keyed table", function()
		it("should flatten to an array", function()
			-- ROBLOX TODO: should we keep the original keys?
			expect(React.Children.toArray({
				a = React.createElement("div", nil),
				b = React.createElement("div", nil),
			})).toEqual({
				React.createElement("div", { key = ".1" }),
				React.createElement("div", { key = ".2" }),
			})

			expect(React.Children.toArray({
				a = React.createElement("div", nil),
				b = {
					c = React.createElement("div", nil),
					d = React.createElement("div", nil),
				},
			})).toEqual({
				React.createElement("div", { key = ".1" }),
				React.createElement("div", { key = ".2:1" }),
				React.createElement("div", { key = ".2:2" }),
			})
		end)

		it("should count children correctly", function()
			expect(React.Children.count({
				a = React.createElement("div", nil),
				b = React.createElement("div", nil),
				c = React.createElement("div", nil),
			})).toBe(3)

			expect(React.Children.count({
				a = React.createElement("div", nil),
				b = {
					c = React.createElement("div", nil),
					d = React.createElement("div", nil),
				},
				e = {
					React.createElement("div", nil),
					React.createElement("div", nil),
				},
			})).toEqual(5)
		end)

		it("should apply function to each child with forEach", function()
			local callback = jest.fn().mockImplementation(function(kid, idx)
				return kid
			end)

			local a = React.createElement("div")
			local b = React.createElement("span")
			local c = React.createElement("p")

			local instance = React.createElement("div", nil, {
				a = a,
				b = b,
				c = c,
			})

			React.Children.forEach(instance.props.children, callback, {})
			local function assertCalls()
				expect(callback).toHaveBeenCalledTimes(3)
				-- ROBLOX DEVIATION: order is not guaranteed
				-- expect(callback).toHaveBeenCalledWith(a, 1)
				-- expect(callback).toHaveBeenCalledWith(c, 2)
				-- expect(callback).toHaveBeenCalledWith(b, 3)
				callback.mockClear()
			end
			assertCalls()
		end)

		it("should map each child with map", function()
			local callback = jest.fn().mockImplementation(function(kid, idx)
				return kid.type
			end)

			local a = React.createElement("div")
			local b = React.createElement("span")
			local c = React.createElement("p")

			local instance = React.createElement("div", nil, {
				a = a,
				b = b,
				c = c,
			})

			local mappedChildren =
				React.Children.map(instance.props.children, callback, {})
			local function assertCalls()
				expect(callback).toHaveBeenCalledTimes(3)
				expect(#mappedChildren).toEqual(3)
				expect(table.find(mappedChildren, "div")).toBeDefined()
				expect(table.find(mappedChildren, "span")).toBeDefined()
				expect(table.find(mappedChildren, "p")).toBeDefined()
				callback.mockClear()
			end
			assertCalls()
		end)
	end)
	--ROBLOX DEVIATION END: Tables with keys should work with React.Children

	describe("with fragments enabled", function()
		it("warns for keys for arrays of elements in a fragment", function()
			local ComponentReturningArray =
				React.Component:extend("ComponentReturningArray")
			function ComponentReturningArray:render()
				return {
					React.createElement("Frame", nil),
					React.createElement("Frame", nil),
				}
			end
			expect(function()
				return ReactTestUtils.renderIntoDocument(
					React.createElement(ComponentReturningArray, nil)
				)
			end).toErrorDev(
				"Warning: "
					.. 'Each child in a list should have a unique "key" prop.'
					.. " See https://reactjs.org/link/warning-keys for more information."
					.. "\n    in ComponentReturningArray (at **)"
			)
		end)

		it("does not warn when there are keys on  elements in a fragment", function()
			local ComponentReturningArray =
				React.Component:extend("ComponentReturningArray")

			function ComponentReturningArray:render()
				return {
					React.createElement("Frame", { key = "foo" }),
					React.createElement("Frame", { key = "bar" }),
				}
			end
			ReactTestUtils.renderIntoDocument(
				React.createElement(ComponentReturningArray, nil)
			)
		end)

		it("warns for keys for arrays at the top level", function()
			expect(function()
				return ReactTestUtils.renderIntoDocument({
					React.createElement("Frame", nil),
					React.createElement("Frame", nil),
				})
			end).toErrorDev(
				"Warning: "
					.. 'Each child in a list should have a unique "key" prop.'
					.. " See https://reactjs.org/link/warning-keys for more information.",
				{ withoutStack = true } -- There's nothing on the stack
			)
		end)
	end)
end)
