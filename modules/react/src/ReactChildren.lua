--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/ReactChildren.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList
type React_Node = ReactTypes.React_Node
type ReactElement<P, T> = ReactTypes.ReactElement<P, T>

local invariant = require(Packages.Shared).invariant

local ReactSymbols = require(Packages.Shared).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
-- local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local ReactElement = require(script.Parent.ReactElement)
local isValidElement = ReactElement.isValidElement
local cloneAndReplaceKey = ReactElement.cloneAndReplaceKey

local SEPARATOR = "."
local SUBSEPARATOR = ":"

-- --[[*
--  * Escape and wrap key so it is safe to use as a reactid
--  *
--  * @param {string} key to be escaped.
--  * @return {string} the escaped key.
--  ]]
--ROBLOX DEVIATION: use gsub instead of RegEx
local function escape(key: string): string
	local escapedString = string.gsub(key, "=", "=0")
	escapedString = string.gsub(escapedString, ":", "=2")
	return "$" .. escapedString
end

-- --[[*
--  * TODO: Test that a single child and an array with one item have the same key
--  * pattern.
--  ]]

-- ROBLOX DEVIATION: There is currently no good way to warn about maps
-- local didWarnAboutMaps = false

-- local userProvidedKeyEscapeRegex = '/\\/+/g'
local function escapeUserProvidedKey(text: string): string
	-- ROBLOX DEVIATION: just return the original string
	-- return text.replace(userProvidedKeyEscapeRegex, '$&/')
	return text
end

-- --[[*
--  * Generate a key string that identifies a element within a set.
--  *
--  * @param {*} element A element that could contain a manual key.
--  * @param {number} index Index that is used if a manual key is not provided.
--  * @return {string}
--  ]]
local function getElementKey(element: any, index: number): string
	-- Do some typechecking here since we call this blindly. We want to ensure
	-- that we don't block potential future ES APIs.
	if typeof(element) == "table" and element ~= nil and element.key ~= nil then
		-- Explicit key
		return escape(tostring(element.key))
	end
	-- Implicit key determined by the index in the set
	-- ROBLOX DEVIATION: unsupported radix arg in tostring(number)
	-- return index.toString(36)
	return tostring(index)
end

local function mapIntoArray(
	children: ReactNodeList?,
	array: Array<React_Node>,
	escapedPrefix: string,
	nameSoFar: string,
	callback: (React_Node?) -> ReactNodeList?
): number
	local type = typeof(children)

	--[[
		ROBLOX DEVIATION: userdata type corresponds to React.None, which is perceived as nil. All
		userdata is treated as nil when passed as a child.
	]]
	if type == "nil" or type == "boolean" or type == "userdata" then
		-- All of the above are perceived as nil.
		children = nil
	end

	local invokeCallback = false

	if children == nil then
		invokeCallback = true
	else
		if type == "string" or type == "number" then
			invokeCallback = true
		elseif type == "table" then
			local childrenType = (children :: any)["$$typeof"]
			if
				childrenType == REACT_ELEMENT_TYPE
				or childrenType == REACT_PORTAL_TYPE
			then
				invokeCallback = true
			end
		end
	end

	if invokeCallback then
		local child = children
		local mappedChild = callback(child)
		-- If it's the only child, treat the name as if it was wrapped in an array
		-- so that it's consistent if the number of children grows:
		local childKey = if nameSoFar == ""
			then SEPARATOR .. getElementKey(child, 1)
			else nameSoFar
		if Array.isArray(mappedChild) then
			local escapedChildKey = ""
			if childKey ~= nil then
				escapedChildKey = escapeUserProvidedKey(childKey) .. "/"
			end
			mapIntoArray(mappedChild, array, escapedChildKey, "", function(c)
				return c
			end)
		elseif mappedChild ~= nil then
			if isValidElement(mappedChild :: any) then
				local mappedChildKey = (mappedChild :: ReactElement<Object, any>).key
				mappedChild = cloneAndReplaceKey(
					mappedChild :: ReactElement<Object, any>,
					-- Keep both the (mapped) and old keys if they differ, just as
					-- traverseAllChildren used to do for objects as children
					escapedPrefix
						-- $FlowFixMe Flow incorrectly thinks React.Portal doesn't have a key
						.. (
							if mappedChildKey
									and (
										not child
										or (child :: ReactElement<Object, any>).key
											~= mappedChildKey
									)
								-- $FlowFixMe Flow incorrectly thinks existing element's key can be a number
								then escapeUserProvidedKey(tostring(mappedChildKey)) .. "/"
								else ""
						)
						.. childKey
				)
			end
			table.insert(array, mappedChild)
		end
		return 1
	end

	local child
	local nextName
	local subtreeCount = 0 -- Count of children found in the current subtree.
	local nextNamePrefix = if nameSoFar == ""
		then SEPARATOR
		else nameSoFar .. SUBSEPARATOR

	if Array.isArray(children) then
		-- ROBLOX FIXME: Luau doesn't recognize this as non-nil without the `or {}`
		for i = 1, #(children :: Array<React_Node>) do
			child = (children :: Array<React_Node>)[i]
			nextName = nextNamePrefix .. getElementKey(child, i)
			subtreeCount += mapIntoArray(child, array, escapedPrefix, nextName, callback)
		end
	else
		local iteratorFn = getIteratorFn(children)
		if typeof(iteratorFn) == "function" then
			local iterableChildren: Object & {
				entries: any,
			} = children :: any

			-- ROBLOX DEVIATION: No equivalent for checking if iterableChildren is a Map
			-- if _G.__DEV__ then
			-- 	-- Warn about using Maps as children
			-- 	if iteratorFn == iterableChildren.entries then
			-- 		if not didWarnAboutMaps then
			-- 			console.warn(
			-- 				"Using Maps as children is not supported. "
			-- 					.. "Use an array of keyed ReactElements instead."
			-- 			)
			-- 		end
			-- 		didWarnAboutMaps = true
			-- 	end
			-- end

			local iterator = iteratorFn(iterableChildren)
			local step
			local ii = 1
			step = iterator.next()
			while not step.done do
				child = step.value
				nextName = nextNamePrefix .. getElementKey(child, ii)
				ii += 1
				subtreeCount += mapIntoArray(
					child,
					array,
					escapedPrefix,
					nextName,
					callback
				)
				step = iterator.next()
			end
			--[[ ROBLOX DEVIATION: this condition will never be met with Roact iterator logic.
				getIteratorFn will always return a function when "children" is a table
			]]
			-- elseif type == 'table' then
			--   local childrenString = '' .. tostring(children)
			--   invariant(
			--     false,
			--     'Objects are not valid as a React child (found: %s). ' ..
			--       'If you meant to render a collection of children, use an array ' ..
			--       'instead.',
			--        if childrenString == '[object Object]'
			--          then 'object with keys {' .. Object.keys(children :: any).join(', ') .. '}'
			--          else childrenString
			--   )
		end
	end

	return subtreeCount
end

type MapFunc = (child: React_Node?, index: number) -> ReactNodeList?

--[[
	* Maps children that are typically specified as `props.children`.
	*
	* See https://reactjs.org/docs/react-api.html#reactchildrenmap
	*
	* The provided mapFunction(child, index) will be called for each
	* leaf child.
	*
	* @param {?*} children Children tree container.
	* @param {function(*, int)} func The map function.
	* @param {*} context Context for mapFunction.
	* @return {object} Object containing the ordered map of results.
]]
local function mapChildren(
	children: ReactNodeList?,
	func: MapFunc,
	context: any
): Array<React_Node>?
	if children == nil then
		return nil
	end
	local result = {}
	local count = 1
	mapIntoArray(children, result, "", "", function(child)
		-- ROBLOX DEVIATION: don't use context argument
		local mapFuncResult = func(child, count)
		count += 1
		return mapFuncResult
	end)
	return result
end

-- --[[*
--  * Count the number of children that are typically specified as
--  * `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrencount
--  *
--  * @param {?*} children Children tree container.
--  * @return {number} The number of children.
--  ]]
local function countChildren(children: ReactNodeList?): number
	local n = 0
	mapChildren(children, function()
		n += 1
		-- Don't return anything
		return
	end)
	return n
end

type ForEachFunc = (child: React_Node?, index: number) -> ()

-- --[[*
--  * Iterates through children that are typically specified as `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrenforeach
--  *
--  * The provided forEachFunc(child, index) will be called for each
--  * leaf child.
--  *
--  * @param {?*} children Children tree container.
--  * @param {function(*, int)} forEachFunc
--  * @param {*} forEachContext Context for forEachContext.
--  ]]
local function forEachChildren(
	children: ReactNodeList?,
	forEachFunc: ForEachFunc,
	forEachContext: any
)
	mapChildren(children, function(...)
		-- ROBLOX DEVIATION: Don't use javascript apply
		forEachFunc(...)
		-- Don't return anything.
		return
	end, forEachContext)
end

-- --[[*
--  * Flatten a children object (typically specified as `props.children`) and
--  * return an array with appropriately re-keyed children.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrentoarray
--  ]]
local function toArray(children: ReactNodeList?): Array<React_Node>
	return mapChildren(children, function(child)
		return child
	end) or {}
end

--[[*
 * Returns the first child in a collection of children and verifies that there
 * is only one child in the collection.
 *
 * See https://reactjs.org/docs/react-api.html#reactchildrenonly
 *
 * The current implementation of this function assumes that a single child gets
 * passed without a wrapper, but the purpose of this helper function is to
 * abstract away the particular structure of children.
 *
 * @param {?object} children Child collection structure.
 * @return {ReactElement} The first and only `ReactElement` contained in the
 * structure.
]]
-- ROBLOX deviation START: we skip generics here, because we can't explicitly constrain them. no annotation works as passthrough.
local function onlyChild(children)
	-- ROBLOX deviation END
	invariant(
		isValidElement(children),
		"React.Children.only expected to receive a single React element child."
	)
	return children
end

return {
	forEach = forEachChildren,
	map = mapChildren,
	count = countChildren,
	only = onlyChild,
	toArray = toArray,
}
