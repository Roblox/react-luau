--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local RoactCompat

describe("production mode", function()
	local prevMockScheduler
	beforeEach(function()
		prevMockScheduler = _G.__ROACT_17_MOCK_SCHEDULER__
		_G.__ROACT_17_MOCK_SCHEDULER__ = nil
		jest.resetModules()
		RoactCompat = require(script.Parent.Parent)
	end)

	it("disallows use of 'act'", function()
		jest.resetModules()
		RoactCompat = require(script.Parent.Parent)

		jestExpect(function()
			RoactCompat.act(function()
				RoactCompat.mount(RoactCompat.createElement("TextLabel"))
			end)
		end).toThrow(
			"ReactRoblox.act is only available in testing environments, "
				.. "not production. Enable the `__ROACT_17_MOCK_SCHEDULER__` "
				.. "global in your test configuration in order to use `act`."
		)
	end)

	afterEach(function()
		_G.__ROACT_17_MOCK_SCHEDULER__ = prevMockScheduler
	end)
end)

describe("test mode", function()
	local prevMockScheduler
	beforeEach(function()
		prevMockScheduler = _G.__ROACT_17_MOCK_SCHEDULER__
		_G.__ROACT_17_MOCK_SCHEDULER__ = true
		jest.resetModules()
		RoactCompat = require(script.Parent.Parent)
	end)

	it("allows use of 'act'", function()
		jest.resetModules()
		RoactCompat = require(script.Parent.Parent)

		local parent = Instance.new("Folder")
		local tree
		jestExpect(function()
			jestExpect(function()
				RoactCompat.act(function()
					tree =
						RoactCompat.mount(RoactCompat.createElement("TextLabel"), parent)
				end)
			end).toWarnDev("'mount' is deprecated", { withoutStack = true })
		end).never.toThrow()

		jestExpect(parent:FindFirstChildWhichIsA("TextLabel")).toBeDefined()
		jestExpect(function()
			jestExpect(function()
				RoactCompat.act(function()
					RoactCompat.unmount(tree)
				end)
			end).toWarnDev("'unmount' is deprecated", { withoutStack = true })
		end).never.toThrow()

		jestExpect(parent:FindFirstChildWhichIsA("TextLabel")).toBeNil()
	end)

	afterEach(function()
		_G.__ROACT_17_MOCK_SCHEDULER__ = prevMockScheduler
	end)
end)
