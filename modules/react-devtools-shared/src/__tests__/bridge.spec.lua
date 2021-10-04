-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/bridge-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect
	local jest = JestGlobals.jest

	describe("bridge", function()
		local Bridge

		beforeEach(function()
			RobloxJest.resetModules()
			RobloxJest.useFakeTimers()
			Bridge = require(script.Parent.Parent.bridge)
		end)

		it("should shutdown properly", function()
			local wall = {
				listen = jest.fn(function()
					return function() end
				end),
				send = jest.fn(),
			}
			local bridge = Bridge.new(wall)

			-- Check that we're wired up correctly.
			bridge:send("reloadAppForProfiling")
			RobloxJest.runAllTimers()
			jestExpect(wall.send).toHaveBeenCalledWith("reloadAppForProfiling")

			-- Should flush pending messages and then shut down.
			wall.send.mockClear()
			bridge:send("update", "1")
			bridge:send("update", "2")
			bridge:shutdown()
			RobloxJest.runAllTimers()
			jestExpect(wall.send).toHaveBeenCalledWith("update", "1")
			jestExpect(wall.send).toHaveBeenCalledWith("update", "2")
			jestExpect(wall.send).toHaveBeenCalledWith("shutdown")

			-- Verify that the Bridge doesn't send messages after shutdown.

			wall.send.mockClear()
			-- ROBLOX deviation: instead of spying on console, use toWarnDev matcher
			jestExpect(function()
				bridge:send("should not send")
			end).toWarnDev(
				'Cannot send message "should not send" through a Bridge that has been shutdown.',
				{ withoutStack = true }
			)
			RobloxJest.runAllTimers()
			jestExpect(wall.send).never.toHaveBeenCalled()
		end)
	end)
end
