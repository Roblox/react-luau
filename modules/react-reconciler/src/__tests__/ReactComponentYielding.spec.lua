-- ROBLOX note: no upstream
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

local ReactGlobals = require(Packages.ReactGlobals)
local React
local ReactFeatureFlags
local ReactNoop
local Scheduler

local JestGlobals = require(Packages.Dev.JestGlobals)
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local jest = JestGlobals.jest

describe("ReactComponentYielding", function()
	local function NoYieldingComponent()
		return React.createElement("div")
	end

	local function YieldingComponent()
		task.wait()
		return React.createElement("div")
	end

	local function NoYieldingHook()
		React.useEffect(function()
			-- no yield
		end, {})
		return React.createElement("div")
	end

	local function YieldingHook()
		React.useEffect(function()
			task.wait()
		end, {})
		return React.createElement("div")
	end

	-- Yield catching only works in DEV mode
	if ReactGlobals.__DEV__ then
		describe("when yield catching enabled", function()
			beforeEach(function()
				jest.resetModules()

				ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
				ReactFeatureFlags.catchYieldingInDEV = true

				React = require(Packages.React)
				ReactNoop = require(Packages.Dev.ReactNoopRenderer)
				Scheduler = require(Packages.Scheduler)
			end)

			it("throws if a component yields", function()
				ReactNoop.render(React.createElement(YieldingComponent))
				expect(function()
					expect(Scheduler).toFlushAndYield({})
				end).toThrow("Yielding is not currently supported")
			end)

			it("does not throw if a component does not yield", function()
				ReactNoop.render(React.createElement(NoYieldingComponent))
				expect(function()
					expect(Scheduler).toFlushAndYield({})
				end).never.toThrow()
			end)

			it("throws if a hook yields", function()
				ReactNoop.render(React.createElement(YieldingHook))
				expect(function()
					expect(Scheduler).toFlushAndYield({})
				end).toThrow("Yielding is not currently supported")
			end)

			it("does not throw if a hook does not yield", function()
				ReactNoop.render(React.createElement(NoYieldingHook))
				expect(function()
					expect(Scheduler).toFlushAndYield({})
				end).never.toThrow()
			end)
		end)
	end

	describe("when yield catching disabled", function()
		beforeEach(function()
			jest.resetModules()

			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.catchYieldingInDEV = false

			React = require(Packages.React)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)
			Scheduler = require(Packages.Scheduler)
		end)

		it("does not throw if a component yields", function()
			ReactNoop.render(React.createElement(YieldingComponent))
			expect(function()
				expect(Scheduler).toFlushAndYield({})
			end).never.toThrow()
		end)

		it("does not throw if a component does not yield", function()
			ReactNoop.render(React.createElement(NoYieldingComponent))
			expect(function()
				expect(Scheduler).toFlushAndYield({})
			end).never.toThrow()
		end)

		it("does not throw if a hook yields", function()
			ReactNoop.render(React.createElement(YieldingHook))
			expect(function()
				expect(Scheduler).toFlushAndYield({})
			end).never.toThrow()
		end)

		it("does not throw if a hook does not yield", function()
			ReactNoop.render(React.createElement(NoYieldingHook))
			expect(function()
				expect(Scheduler).toFlushAndYield({})
			end).never.toThrow()
		end)
	end)
end)
