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
local ReactGlobals = require(Packages.ReactGlobals)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local beforeAll = JestGlobals.beforeAll
local afterAll = JestGlobals.afterAll
local it = JestGlobals.it

local Map = require(Packages.LuauPolyfill).Map

local ReactFiberDevToolsHook, ReactDevtoolsShared

beforeEach(function()
	jest.resetModules()

	ReactFiberDevToolsHook = require(script.Parent.Parent["ReactFiberDevToolsHook.new"])
	ReactDevtoolsShared = require(Packages.Dev.ReactDevtoolsShared)
end)

describe("DevTools hook detection", function()
	local originalDevtoolsState
	beforeAll(function()
		originalDevtoolsState = ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__
	end)

	afterAll(function()
		ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__ = originalDevtoolsState
	end)

	local itIfDev = if ReactGlobals.__DEV__ then it else it.skip :: any
	itIfDev("should log an error when fibers aren't supported", function()
		ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__ = {
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

	-- ROBLOX deviation START: verify that renderers are attached correctly
	it("attaches renderers", function()
		local renderer123 = {
			findFiberByHostInstance = function() end,
		}
		local renderer456 = {
			findFiberByHostInstance = function() end,
		}
		local hook = {
			renderers = Map.new({
				{ 123, renderer123 },
				{ 456, renderer456 },
			}),
			rendererInterfaces = Map.new(),
			emit = jest.fn(),
			sub = jest.fn(),
		}
		local agent = {
			addListener = jest.fn(),
		}
		ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__ = hook

		ReactDevtoolsShared.backend.initBackend(hook, agent, {})

		jestExpect(hook.emit).toHaveBeenCalledTimes(3)

		jestExpect(hook.emit).toHaveBeenNthCalledWith(1, "renderer-attached", {
			id = 123,
			renderer = renderer123,
			rendererInterface = jestExpect.anything(),
		})
		jestExpect(hook.emit).toHaveBeenNthCalledWith(2, "renderer-attached", {
			id = 456,
			renderer = renderer456,
			rendererInterface = jestExpect.anything(),
		})
		jestExpect(hook.emit).toHaveBeenNthCalledWith(3, "react-devtools", agent)
	end)
	-- ROBLOX deviation END
end)
