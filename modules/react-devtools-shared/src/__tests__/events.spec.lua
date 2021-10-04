-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/events-test.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  *
--  * LICENSE file in the root directory of this source tree.
--  * @flow
--  */

return function()
	local Packages = script.Parent.Parent.Parent
	local Error = require(Packages.LuauPolyfill).Error
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect
	local jest = JestGlobals.jest
	local RobloxJest = require(Packages.Dev.RobloxJest)

	describe("events", function()
		local dispatcher
		beforeEach(function()
			RobloxJest.resetModules()
			local EventEmitter = require(script.Parent.Parent.events)
			dispatcher = EventEmitter.new()
		end)

		it("can dispatch an event with no listeners", function()
			dispatcher:emit("event", 123)
		end)

		it("handles a listener being attached multiple times", function()
			local callback = jest.fn()
			dispatcher:addListener("event", callback)
			dispatcher:addListener("event", callback)
			dispatcher:emit("event", 123)
			jestExpect(callback).toHaveBeenCalledTimes(1)
			jestExpect(callback).toHaveBeenCalledWith(123)
		end)

		it("notifies all attached listeners of events", function()
			local callback1 = jest.fn()
			local callback2 = jest.fn()
			local callback3 = jest.fn()
			dispatcher:addListener("event", callback1)
			dispatcher:addListener("event", callback2)
			dispatcher:addListener("other-event", callback3)
			dispatcher:emit("event", 123)
			jestExpect(callback1).toHaveBeenCalledTimes(1)
			jestExpect(callback1).toHaveBeenCalledWith(123)
			jestExpect(callback2).toHaveBeenCalledTimes(1)
			jestExpect(callback2).toHaveBeenCalledWith(123)
			jestExpect(callback3).never.toHaveBeenCalled()
		end)

		it("calls later listeners before re-throwing if an earlier one throws", function()
			local callbackThatThrows = jest.fn(function()
				error(Error.new("expected"))
			end)
			local callback = jest.fn()
			dispatcher:addListener("event", callbackThatThrows)
			dispatcher:addListener("event", callback)
			jestExpect(function()
				dispatcher:emit("event", 123)
			end).toThrow("expected")
			jestExpect(callbackThatThrows).toHaveBeenCalledTimes(1)
			jestExpect(callbackThatThrows).toHaveBeenCalledWith(123)
			jestExpect(callback).toHaveBeenCalledTimes(1)
			jestExpect(callback).toHaveBeenCalledWith(123)
		end)

		it("removes attached listeners", function()
			local callback1 = jest.fn()
			local callback2 = jest.fn()
			dispatcher:addListener("event", callback1)
			dispatcher:addListener("other-event", callback2)
			dispatcher:removeListener("event", callback1)
			dispatcher:emit("event", 123)
			jestExpect(callback1).never.toHaveBeenCalled()
			dispatcher:emit("other-event", 123)
			jestExpect(callback2).toHaveBeenCalledTimes(1)
			jestExpect(callback2).toHaveBeenCalledWith(123)
		end)

		it("removes all listeners", function()
			local callback1 = jest.fn()
			local callback2 = jest.fn()
			local callback3 = jest.fn()
			dispatcher:addListener("event", callback1)
			dispatcher:addListener("event", callback2)
			dispatcher:addListener("other-event", callback3)
			dispatcher:removeAllListeners()
			dispatcher:emit("event", 123)
			dispatcher:emit("other-event", 123)
			jestExpect(callback1).never.toHaveBeenCalled()
			jestExpect(callback2).never.toHaveBeenCalled()
			jestExpect(callback3).never.toHaveBeenCalled()
		end)

		it(
			"should call the initial listeners even if others are added or removed during a dispatch",
			function()
				local callback2, callback3
				local callback1 = jest.fn(function()
					dispatcher:removeListener("event", callback2)
					dispatcher:addListener("event", callback3)
				end)
				callback2 = jest.fn()
				callback3 = jest.fn()
				dispatcher:addListener("event", callback1)
				dispatcher:addListener("event", callback2)
				dispatcher:emit("event", 123)
				jestExpect(callback1).toHaveBeenCalledTimes(1)
				jestExpect(callback1).toHaveBeenCalledWith(123)
				jestExpect(callback2).toHaveBeenCalledTimes(1)
				jestExpect(callback2).toHaveBeenCalledWith(123)
				jestExpect(callback3).never.toHaveBeenCalled()
				dispatcher:emit("event", 456)
				jestExpect(callback1).toHaveBeenCalledTimes(2)
				jestExpect(callback1).toHaveBeenCalledWith(456)
				jestExpect(callback2).toHaveBeenCalledTimes(1)
				jestExpect(callback3).toHaveBeenCalledTimes(1)
				jestExpect(callback3).toHaveBeenCalledWith(456)
			end
		)
	end)
end
