-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/jest-react/src/JestReact.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
-- ROBLOX deviation START: not used
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
local Object = LuauPolyfill.Object
local exports = {}
-- ROBLOX deviation START: fix import
-- local JestGlobals = require(Packages.Dev.JestGlobals)
local JestGlobals = require(Packages.JestGlobals)
local expect = JestGlobals.expect
-- ROBLOX deviation END
-- ROBLOX deviation START: fix import
-- local sharedReactSymbolsModule = require(Packages.shared.ReactSymbols)
local sharedReactSymbolsModule = require(Packages.Shared).ReactSymbols
-- ROBLOX deviation END
local REACT_ELEMENT_TYPE = sharedReactSymbolsModule.REACT_ELEMENT_TYPE
local REACT_FRAGMENT_TYPE = sharedReactSymbolsModule.REACT_FRAGMENT_TYPE
-- ROBLOX deviation START: fix import
-- local invariant = require(Packages.shared.invariant).default
local invariant = require(Packages.Shared).invariant
-- ROBLOX deviation END
-- ROBLOX deviation START: predeclare variables
local jsonChildToJSXChild, jsonChildrenToJSXChildren
-- ROBLOX deviation END
local function captureAssertion(fn)
	-- Trick to use a Jest matcher inside another Jest matcher. `fn` contains an
	-- assertion; if it throws, we capture the error and return it, so the stack
	-- trace presented to the user points to the original assertion in the
	-- test file.
	do --[[ ROBLOX COMMENT: try-catch block conversion ]]
		-- ROBLOX deviation START: use pcall, format message
		-- local ok, result, hasReturned = xpcall(function()
		-- 	fn()
		-- end, function(error_)
		-- 	return {
		-- 		pass = false,
		-- 		message = function()
		-- 			return error_.message
		-- 		end,
		-- 	},
		-- 		true
		-- end)
		-- if hasReturned then
		-- 	return result
		-- end
		local ok, result = pcall(fn)

		if not ok then
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
		-- ROBLOX deviation END
	end
	return { pass = true }
end
local function assertYieldsWereCleared(root)
	local Scheduler = root._Scheduler
	-- ROBLOX deviation START: use dot notation
	-- local actualYields = Scheduler:unstable_clearYields()
	local actualYields = Scheduler.unstable_clearYields()
	-- ROBLOX deviation END
	invariant(
		-- ROBLOX deviation START: fix .length
		-- actualYields.length == 0,
		#actualYields == 0,
		-- ROBLOX deviation END
		"Log of yielded values is not empty. "
			.. "Call expect(ReactTestRenderer).unstable_toHaveYielded(...) first."
	)
end
local function unstable_toMatchRenderedOutput(root, expectedJSX)
	assertYieldsWereCleared(root)
	-- ROBLOX deviation START: use dot notation
	-- local actualJSON = root:toJSON()
	local actualJSON = root.toJSON()
	-- ROBLOX deviation END
	local actualJSX
	if actualJSON == nil or typeof(actualJSON) == "string" then
		actualJSX = actualJSON
		-- ROBLOX deviation START: remove toJSBoolean
		-- elseif Boolean.toJSBoolean(Array.isArray(actualJSON)) then
	elseif Array.isArray(actualJSON) then
		-- ROBLOX deviation END
		-- ROBLOX deviation START: fix .length
		-- if actualJSON.length == 0 then
		if #actualJSON == 0 then
			-- ROBLOX deviation END
			actualJSX = nil
		-- ROBLOX deviation START: fix .length
		-- elseif actualJSON.length == 1 then
		elseif #actualJSON == 1 then
			-- ROBLOX deviation END
			actualJSX = jsonChildToJSXChild(actualJSON[
				1 --[[ ROBLOX adaptation: added 1 to array index ]]
			])
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
					-- ROBLOX deviation START: remove toJSBoolean, use _G.__DEV__
					-- _store = if Boolean.toJSBoolean(__DEV__) then {} else nil,
					_store = if _G.__DEV__ then {} else nil,
					-- ROBLOX deviation END
				}
			end
		end
	else
		actualJSX = jsonChildToJSXChild(actualJSON)
	end
	return captureAssertion(function()
		expect(actualJSX).toEqual(expectedJSX)
	end)
end
exports.unstable_toMatchRenderedOutput = unstable_toMatchRenderedOutput
-- ROBLOX deviation START: predeclared function
-- local function jsonChildToJSXChild(jsonChild)
function jsonChildToJSXChild(jsonChild)
	-- ROBLOX deviation END
	if jsonChild == nil or typeof(jsonChild) == "string" then
		return jsonChild
	else
		local jsxChildren = jsonChildrenToJSXChildren(jsonChild.children)
		return {
			["$$typeof"] = REACT_ELEMENT_TYPE,
			type = jsonChild.type,
			key = nil,
			ref = nil,
			props = if jsxChildren == nil
				then jsonChild.props
				else Object.assign({}, jsonChild.props, { children = jsxChildren }),
			_owner = nil,
			-- ROBLOX deviation START: remove toJSBoolean, use _G.__DEV__
			-- _store = if Boolean.toJSBoolean(__DEV__) then {} else nil,
			_store = if _G.__DEV__ then {} else nil,
			-- ROBLOX deviation END
		}
	end
end
-- ROBLOX deviation START: predeclared function
-- local function jsonChildrenToJSXChildren(jsonChildren)
function jsonChildrenToJSXChildren(jsonChildren)
	-- ROBLOX deviation END
	if jsonChildren ~= nil then
		-- ROBLOX deviation START: fix .length
		-- if jsonChildren.length == 1 then
		if #jsonChildren == 1 then
			-- ROBLOX deviation END
			return jsonChildToJSXChild(jsonChildren[
				1 --[[ ROBLOX adaptation: added 1 to array index ]]
			])
		elseif
			-- ROBLOX deviation START: fix .length
			-- jsonChildren.length
			#jsonChildren
			-- ROBLOX deviation END
			> 1 --[[ ROBLOX CHECK: operator '>' works only if either both arguments are strings or both are a number ]]
		then
			local jsxChildren = {}
			local allJSXChildrenAreStrings = true
			local jsxChildrenString = ""
			-- ROBLOX deviation START: use in loop instead of while loop
			-- do
			-- 	local i = 0
			-- 	while
			-- 		i
			-- 		< jsonChildren.length --[[ ROBLOX CHECK: operator '<' works only if either both arguments are strings or both are a number ]]
			-- 	do
			-- 		local jsxChild = jsonChildToJSXChild(jsonChildren[tostring(i)])
			-- 		table.insert(jsxChildren, jsxChild) --[[ ROBLOX CHECK: check if 'jsxChildren' is an Array ]]
			-- 		if Boolean.toJSBoolean(allJSXChildrenAreStrings) then
			-- 			if typeof(jsxChild) == "string" then
			-- 				jsxChildrenString += jsxChild
			-- 			elseif jsxChild ~= nil then
			-- 				allJSXChildrenAreStrings = false
			-- 			end
			-- 		end
			-- 		i += 1
			-- 	end
			-- end
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
			-- ROBLOX deviation END
			-- ROBLOX deviation START: remove toJSBoolean
			-- return if Boolean.toJSBoolean(allJSXChildrenAreStrings)
			return if allJSXChildrenAreStrings
				-- ROBLOX deviation END
				then jsxChildrenString
				else jsxChildren
		end
	end
	return nil
end
return exports
