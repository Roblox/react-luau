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

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local beforeAll = JestGlobals.beforeAll
local afterAll = JestGlobals.afterAll
local it = JestGlobals.it

local ReactFiberDevToolsHook

beforeEach(function()
	jest.resetModules()

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

	local itIfDev = _G.DEV and it or it.skip :: any
	itIfDev("should log an error when fibers aren't supported", function()
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
			{ withoutStack = true }
		)
	end)
end)
