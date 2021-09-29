-- upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactMemo.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local Shared = require(Packages.Shared)
local console = Shared.console
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect

local ReactSymbols = Shared.ReactSymbols
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local isValidElementType = Shared.isValidElementType
local getComponentName = Shared.getComponentName

local exports = {}

-- ROBLOX TODO: use function generics
-- export function memo<Props>(
-- 	type: React$ElementType,
-- 	compare?: (oldProps: Props, newProps: Props) => boolean,
--   ) {
exports.memo = function(type_, compare: ((any, any) -> boolean)?)
	if _G.__DEV__ then
		local validType = isValidElementType(type_)

		-- // We warn in this case but don't throw. We expect the element creation to
		-- // succeed and there will likely be errors in render.
		if not validType then
			local info = ""
			if
				type_ == nil
				or (typeof(type_) == "table" and #Object.keys(type_) == 0)
			then
				info = info
					.. (
						" You likely forgot to export your component from the file "
						.. "it's defined in, or you might have mixed up default and named imports."
					)
			end
			local typeString
			if type_ == nil then
				typeString = "nil"
			elseif Array.isArray(type_) then
				typeString = "array"
			elseif
				type_ ~= nil
				and typeof(type_) == "table"
				and type_["$$typeof"] == REACT_ELEMENT_TYPE
			then
				typeString = ("<%s />"):format(getComponentName(type_.type) or "UNKNOWN")
				info =
					" Did you accidentally export a JSX literal or Element instead of a component?"
			else
				typeString = typeof(type_)
				if type_ ~= nil then
					-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
					info = "\n" .. inspect(type_)
				end
			end
			console.error(
				"memo: The first argument must be a component. Instead received: `%s`.%s",
				typeString,
				info
			)
		end
	end

	local elementType = {
		["$$typeof"] = REACT_MEMO_TYPE,
		type = type_,
		compare = compare or nil,
	}

	if _G.__DEV__ then
		local ownName = nil
		elementType.displayName = function(...)
			if #{ ... } == 0 then
				return ownName
			end

			local name = ({ ... })[1]
			ownName = name

			if type_.displayName == nil then
				type_.displayName = name
			end

			return nil
		end
	end

	return elementType
end

return exports
