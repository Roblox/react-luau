-- ROBLOX upstream: https://github.com/facebook/react/blob/e0f89aa056de95afc4c23909fce3d91fefb7dec7/packages/jest-react/src/JestReact.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *]]

local Packages = script.Parent.Parent
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local invariant = require(Packages.Shared).invariant
local LuauPolyfill = require(Packages.LuauPolyfill)
local jestExpect = require(Packages.JestGlobals).expect

local function captureAssertion(fn)
	-- Trick to use a TestEZ expectation matcher inside another Jest
	-- matcher. `fn` contains an assertion; if it throws, we capture the
	-- error and return it, so the stack trace presented to the user points
	-- to the original assertion in the test file.
	local ok, result = pcall(fn)

	if not ok then
		-- deviation: The message here will be a string with some extra info
		-- that's not helpful, so we trim it down a bit
		local stringResult = tostring(result)
		local subMessageIndex = string.find(stringResult, " ")
		local message = string.sub(stringResult, subMessageIndex + 1)

		return {
			pass = false,
			message = function()
				return message
			end,
		}
	end

	return { pass = true }
end

local function assertYieldsWereCleared(root)
	local Scheduler = root._Scheduler
	local actualYields = Scheduler.unstable_clearYields()

	invariant(
		#actualYields == 0,
		"Log of yielded values is not empty. "
			.. "Call expect(ReactTestRenderer).unstable_toHaveYielded(...) first."
	)
end

local jsonChildrenToJSXChildren

local function jsonChildToJSXChild(jsonChild)
	if jsonChild == nil or typeof(jsonChild) == "string" then
		return jsonChild
	else
		local jsxChildren = jsonChildrenToJSXChildren(jsonChild.children)

		return {
			["$$typeof"] = REACT_ELEMENT_TYPE,
			type = jsonChild.type,
			key = nil,
			ref = nil,
			props = (function()
				if jsxChildren == nil then
					return jsonChild.props
				end
				return LuauPolyfill.Object.assign(
					{ children = jsxChildren },
					jsonChild.props
				)
			end)(),
			_owner = nil,
			_store = (function()
				if _G.__DEV__ then
					return {}
				end

				return nil
			end)(),
		}
	end
end

jsonChildrenToJSXChildren = function(jsonChildren)
	if jsonChildren ~= nil then
		if #jsonChildren == 1 then
			return jsonChildToJSXChild(jsonChildren[1])
		elseif #jsonChildren > 1 then
			local jsxChildren = {}
			local allJSXChildrenAreStrings = true
			local jsxChildrenString = ""

			for _, jsonChild in jsonChildren do
				local jsxChild = jsonChildToJSXChild(jsonChild)

				table.insert(jsxChildren, jsxChild)

				if allJSXChildrenAreStrings then
					if typeof(jsxChild) == "string" then
						jsxChildrenString = jsxChildrenString .. jsxChild
					elseif jsxChild ~= nil then
						allJSXChildrenAreStrings = false
					end
				end
			end

			if allJSXChildrenAreStrings then
				return jsxChildrenString
			end

			return jsxChildren
		end
	end

	return nil
end

local function unstable_toMatchRenderedOutput(root, expectedJSX)
	assertYieldsWereCleared(root)

	local actualJSON = root.toJSON()
	local actualJSX

	if actualJSON == nil or typeof(actualJSON) == "string" then
		actualJSX = actualJSON
	elseif LuauPolyfill.Array.isArray(actualJSON) then
		if #actualJSON == 0 then
			actualJSX = nil
		elseif #actualJSON == 1 then
			actualJSX = jsonChildToJSXChild(actualJSON[1])
		else
			local actualJSXChildren = jsonChildrenToJSXChildren(actualJSON)

			if actualJSXChildren == nil or typeof(actualJSXChildren) == "string" then
				actualJSX = actualJSXChildren
			else
				actualJSX = {
					["$$typeof"] = REACT_ELEMENT_TYPE,
					type = REACT_FRAGMENT_TYPE,
					key = nil,
					ref = nil,
					props = { children = actualJSXChildren },
					_owner = nil,
					_store = (function()
						if _G.__DEV__ then
							return {}
						end

						return nil
					end)(),
				}
			end
		end
	else
		actualJSX = jsonChildToJSXChild(actualJSON)
	end

	return captureAssertion(function()
		jestExpect(actualJSX).toEqual(expectedJSX)
	end)
end

return {
	unstable_toMatchRenderedOutput = unstable_toMatchRenderedOutput,
}
