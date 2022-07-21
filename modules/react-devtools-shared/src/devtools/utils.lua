-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/devtools/utils.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
local Object = LuauPolyfill.Object
-- ROBLOX deviation: Use HttpService for JSON
local JSON = game:GetService("HttpService")

local exports = {}

local ViewsComponentsTypes = require(script.Parent.views.Components.types)
type Element = ViewsComponentsTypes.Element
local Store = require(script.Parent.store)
type Store = Store.Store

exports.printElement = function(element: Element, includeWeight: boolean?)
	includeWeight = includeWeight or false
	local prefix = " "

	if #element.children > 0 then
		prefix = element.isCollapsed and "▸" or "▾"
	end

	local key = ""

	if element.key ~= nil and element.key ~= "" then
		key = (' key="%s"'):format(tostring(element.key))
	end

	local hocDisplayNames = nil

	if element.hocDisplayNames ~= nil then
		hocDisplayNames = Object.assign({}, element.hocDisplayNames)
	end

	local hocs = hocDisplayNames and (" [%s]"):format(table.concat(hocDisplayNames, "]["))
		or ""
	local suffix = ""

	if includeWeight then
		suffix = (" (%s)"):format(element.isCollapsed and "1" or tostring(element.weight))
	end
	return ("%s%s <%s%s>%s%s"):format(
		("  "):rep(element.depth + 1),
		prefix,
		element.displayName or "null",
		key,
		hocs,
		suffix
	)
end

exports.printOwnersList = function(elements: Array<Element>, includeWeight: boolean)
	includeWeight = includeWeight or false
	return table.concat(
		Array.map(elements, function(element)
			return exports.printElement(element, includeWeight)
		end),
		"\n"
	)
end

exports.printStore = function(store: Store, includeWeight: boolean?)
	includeWeight = includeWeight or false
	local snapshotLines: Array<string> = {}
	local rootWeight = 0

	for _, rootID in store:getRoots() do
		local rootElement: Element? = store:getElementByID(rootID)
		local weight = (rootElement :: Element).weight

		table.insert(
			snapshotLines,
			"[root]" .. (includeWeight and (" (%d)"):format(weight) or "")
		)
		for i = rootWeight, rootWeight + weight - 1 do
			local element: Element? = store:getElementAtIndex(i)

			if element == nil then
				error(("Could not find element at index %d"):format(i))
			end

			table.insert(
				snapshotLines,
				exports.printElement(element :: Element, includeWeight :: boolean)
			)
		end
		rootWeight += weight
	end

	-- Make sure the pretty-printed test align with the Store's reported number of total rows.
	if rootWeight ~= store:getNumElements() then
		error(
			(
				"Inconsistent Store state. Individual root weights (%s) do not match total weight (%s)"
			):format(tostring(rootWeight), tostring(store:getNumElements()))
		)
	end

	-- If roots have been unmounted, verify that they've been removed from maps.
	-- This helps ensure the Store doesn't leak memory.
	store:assertExpectedRootMapSizes()

	return table.concat(snapshotLines, "\n")
end

-- We use JSON.parse to parse string values
-- e.g. 'foo' is not valid JSON but it is a valid string
-- so this method replaces e.g. 'foo' with "foo"
exports.sanitizeForParse = function(value)
	if typeof(value) == "string" then
		if #value >= 2 and value:sub(1, 1) == "'" and value:sub(#value) == "'" then
			return '"' .. value:sub(1, #value - 2) .. '"'
		end
	end
	return value
end

exports.smartParse = function(value): number?
	if value == "Infinity" then
		return math.huge
	elseif value == "NaN" then
		-- ROBLOX deviation: no NaN
		return 0
	elseif value == "undefined" then
		return nil
	else
		return JSON:JSONDecode(exports.sanitizeForParse(value))
	end
end

exports.smartStringify = function(value)
	if typeof(value) == "number" then
		-- ROBLOX deviation: these numbers don't exist
		-- if Number.isNaN(value) then
		-- 	return'NaN'
		-- elseif not Number.isFinite(value) then
		-- 	return'Infinity'
		-- end
	elseif value == nil then
		return "undefined"
	end

	return JSON:JSONEncode(value)
end

return exports
