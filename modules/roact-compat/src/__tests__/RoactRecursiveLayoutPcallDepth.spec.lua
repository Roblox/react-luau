--!strict
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
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local React
local ReactRoblox
local RoactCompat
local Scheduler

beforeEach(function()
	jest.resetModules()
	RoactCompat = require(script.Parent.Parent)
	ReactRoblox = require(Packages.ReactRoblox)
	Scheduler = require(Packages.Dev.Scheduler)
	React = require(Packages.React)
end)

describe("pcall depth", function()
	-- ROBLOX: we no longer warn, but this test is a good way to programmaitcally create a complex tree
	it("should render even when pcall depth limit is hit", function()
		local function LayoutEffect(props)
			React.useLayoutEffect(function()
				Scheduler.unstable_yieldValue("Layout Effect")
			end)
			return RoactCompat.createElement("TextLabel", { Text = "Layout" })
		end

		local function constructDeepTree(n)
			local constructTreeTable = {
				[1] = function()
					return RoactCompat.createElement(LayoutEffect)
				end,
			}
			for i = 2, 500 do
				constructTreeTable[i] = function()
					return RoactCompat.createElement(constructTreeTable[i - 1])
				end
			end
			return constructTreeTable[n]
		end

		local DeepTree = RoactCompat.createElement(
			"Frame",
			nil,
			RoactCompat.createElement(constructDeepTree(500))
		)

		local instance = Instance.new("Folder")
		local root = ReactRoblox.createRoot(instance)
		jestExpect(function()
			root:render(DeepTree)
			Scheduler.unstable_flushAllWithoutAsserting()
		end).toWarnDev({})
		local children = instance:GetChildren()

		jestExpect(#children).toBe(1)
	end)
end)
