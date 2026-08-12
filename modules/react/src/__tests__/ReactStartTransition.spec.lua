--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react/src/__tests__/ReactStartTransition-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]

local Packages = script.Parent.Parent.Parent

local React
local ReactTestRenderer
local act
local useState
local useTransition

local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it

local SUSPICIOUS_NUMBER_OF_FIBERS_UPDATED = 10

describe("ReactStartTransition", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
		act = ReactTestRenderer.unstable_concurrentAct
		useState = React.useState
		useTransition = React.useTransition
	end)

	it(
		"Warns if a suspicious number of fibers are updated inside startTransition",
		function()
			local subs = Set.new()
			local function useUserSpaceSubscription()
				local _, setState = useState(0)
				subs:add(setState)
			end

			local triggerHookTransition
			local Component
			Component = function(props)
				useUserSpaceSubscription()
				if props.level == 0 then
					local _, start = useTransition()
					triggerHookTransition = start
				end
				if props.level < SUSPICIOUS_NUMBER_OF_FIBERS_UPDATED then
					return React.createElement(Component, { level = props.level + 1 })
				end
				return nil
			end

			act(function()
				ReactTestRenderer.create(React.createElement(Component, { level = 0 }), {
					unstable_isConcurrent = true,
				})
			end)

			local warning = "Detected a large number of updates inside startTransition. "
				.. "If this is due to a subscription please re-write it to use React provided hooks. "
				.. "Otherwise concurrent mode guarantees are off the table."

			jestExpect(function()
				act(function()
					React.startTransition(function()
						subs:forEach(function(setState)
							setState(function(state)
								return state + 1
							end)
						end)
					end)
				end)
			end).toWarnDev({ warning }, { withoutStack = true })

			jestExpect(function()
				act(function()
					triggerHookTransition(function()
						subs:forEach(function(setState)
							setState(function(state)
								return state + 1
							end)
						end)
					end)
				end)
			end).toWarnDev({ warning }, { withoutStack = true })
		end
	)

	it("preserves errors thrown by transition callbacks", function()
		local globalSucceeded, globalError = pcall(function()
			React.startTransition(function()
				error("global transition failure", 0)
			end)
		end)
		jestExpect(globalSucceeded).toBe(false)
		jestExpect(globalError).toBe("global transition failure")

		local triggerHookTransition
		local function Component()
			local _, start = useTransition()
			triggerHookTransition = start
			return nil
		end

		act(function()
			ReactTestRenderer.create(React.createElement(Component), {
				unstable_isConcurrent = true,
			})
		end)

		local hookSucceeded, hookError = pcall(function()
			act(function()
				triggerHookTransition(function()
					error("hook transition failure", 0)
				end)
			end)
		end)
		jestExpect(hookSucceeded).toBe(false)
		jestExpect(hookError).toBe("hook transition failure")
	end)
end)
