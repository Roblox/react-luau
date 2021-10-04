-- awaiting pull request: https://github.com/facebook/react/pull/20155
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local ReactFiberDevToolsHook

	beforeEach(function()
		RobloxJest.resetModules()

		ReactFiberDevToolsHook = require(script.Parent.Parent["ReactFiberDevToolsHook.new"])
	end)

	describe("DevTools hook detection", function()
		local originalDevtoolsState
		beforeAll(function()
			originalDevtoolsState = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
		end)

		afterAll(function()
			_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = originalDevtoolsState
		end)

		if _G.__DEV__ then
			it("should log an error when fibers aren't supported", function()
				_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
					isDisabled = false,
					supportsHooks = false,
				}
				jestExpect(function()
					local result = ReactFiberDevToolsHook.injectInternals({})
					-- expect logs to include error
					jestExpect(result).toBe(true)
				-- ROBLOX deviation: assert the console error, upstream doesn't
				end).toErrorDev(
					"The installed version of React DevTools is too old",
					{withoutStack = true}
				)
			end)
		end
	end)
end
