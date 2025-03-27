-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/events-test.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local xit = JestGlobals.xit
local beforeEach = JestGlobals.beforeEach
local LuauPolyfill = require(Packages.LuauPolyfill)
local Symbol = LuauPolyfill.Symbol

local utils = require(script.Parent.Parent.utils)
local getDisplayName = utils.getDisplayName
local getDisplayNameForReactElement = utils.getDisplayNameForReactElement
local SuspenseList, StrictMode
local createElement

beforeEach(function()
	local ReactSymbols = require(Packages.Shared).ReactSymbols
	SuspenseList = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE
	local React = require(Packages.React)
	createElement = React.createElement
end)

describe("utils", function()
	describe("getDisplayName", function()
		it("should return a function name", function()
			local function FauxComponent() end

			jestExpect(getDisplayName(FauxComponent)).toEqual("FauxComponent")
		end)

		it("should return a displayName name if specified", function()
			local FauxComponent = {}

			FauxComponent.__componentName = "OverrideDisplayName"

			jestExpect(getDisplayName(FauxComponent)).toEqual("OverrideDisplayName")
		end)

		it("should return the fallback for invalid type", function()
			jestExpect(getDisplayName(100, "Fallback")).toEqual("Fallback")
		end)

		it(
			"should return fileName:lineNumber for anonymous functions without a fallback",
			function()
				jestExpect(getDisplayName(function() end)).toMatch("utils.spec:[0-9]*")
			end
		)

		-- Simulate a reported bug:
		-- https://github.com/facebook/react/issues/16685
		it("should return a fallback when the name prop is not a string", function()
			local FauxComponent = { name = {} }
			jestExpect(getDisplayName(FauxComponent, "Fallback")).toEqual("Fallback")
		end)
	end)
	describe("getDisplayNameForReactElement", function()
		-- ROBLOX deviation: Lua can't put fields on functions
		xit(
			"should return correct display name for an element with function type",
			function()
				local function FauxComponent() end

				-- FauxComponent.displayName = 'OverrideDisplayName'

				local element = createElement(FauxComponent)

				jestExpect(getDisplayNameForReactElement(element)).toEqual(
					"OverrideDisplayName"
				)
			end
		)

		it(
			"should return correct display name for an element with a type of StrictMode",
			function()
				local element = createElement(StrictMode)

				jestExpect(getDisplayNameForReactElement(element)).toEqual("StrictMode")
			end
		)

		it(
			"should return correct display name for an element with a type of SuspenseList",
			function()
				local element
				-- ROBLOX Test Noise: This warning shouldn't be triggered
				jestExpect(function()
					element = createElement(SuspenseList)
				end).toErrorDev("type is invalid", { withoutStack = true })

				jestExpect(getDisplayNameForReactElement(element)).toEqual("SuspenseList")
			end
		)

		it(
			"should return NotImplementedInDevtools for an element with invalid symbol type",
			function()
				local element
				-- ROBLOX Test Noise: This warning isn't captured in
				-- upstream, so it may rely on test setup to suppress it
				jestExpect(function()
					element = (createElement :: any)(Symbol("foo"))
				end).toErrorDev("type is invalid", { withoutStack = true })

				jestExpect(getDisplayNameForReactElement(element)).toEqual(
					"NotImplementedInDevtools"
				)
			end
		)

		it(
			"should return NotImplementedInDevtools for an element with invalid type",
			function()
				local element
				-- ROBLOX Test Noise: This warning isn't captured in
				-- upstream, so it may rely on test setup to suppress it
				jestExpect(function()
					element = (createElement :: any)(true)
				end).toErrorDev("type is invalid", { withoutStack = true })

				jestExpect(getDisplayNameForReactElement(element)).toEqual(
					"NotImplementedInDevtools"
				)
			end
		)

		it("should return Element for null type", function()
			local element
			-- ROBLOX Test Noise: This warning isn't captured in
			-- upstream, so it may rely on test setup to suppress it
			jestExpect(function()
				element = (createElement :: any)()
			end).toErrorDev("type is invalid", { withoutStack = true })

			jestExpect(getDisplayNameForReactElement(element)).toEqual("Element")
		end)
	end)
end)
