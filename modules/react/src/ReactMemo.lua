--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactMemo.js
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
type React_StatelessFunctionalComponent<Props> = Shared.React_StatelessFunctionalComponent<
	Props
>
type React_ElementType = Shared.React_ElementType
type React_Component<Props, State> = Shared.React_Component<Props, State>
type React_ComponentType<Props> = Shared.React_ComponentType<Props>
type React_AbstractComponent<Config, Instance> = Shared.React_AbstractComponent<
	Config,
	Instance
>

local ReactSymbols = Shared.ReactSymbols
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local isValidElementType = Shared.isValidElementType
local getComponentName = Shared.getComponentName

local exports = {}

exports.memo = function<Props, T>(
	-- ROBLOX deviation START: expanded type pulled from definitelytyped, not sure why upstream doesn't accept function component types
	-- ROBLOX TODO Luau: React_Component<Props, any> gave me  Type 'React_Component<any, any>' could not be converted into '((any, any) -> (Array<(Array<<CYCLE>> | React_Element<any> | boolean | number | string)?> | React_Element<any> | boolean | number | string)?) | string'; none of the union options are compatible
	type_: React_StatelessFunctionalComponent<Props> | React_AbstractComponent<Props, T> | string,
	-- ROBLOX deviation END
	compare: ((oldProps: Props, newProps: Props) -> boolean)?
): React_AbstractComponent<Props, any>
	if _G.__DEV__ then
		local validType = isValidElementType(type_)

		-- We warn in this case but don't throw. We expect the element creation to
		-- succeed and there will likely be errors in render.
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
				and (type_)["$$typeof"] == REACT_ELEMENT_TYPE
			then
				typeString = string.format(
					"<%s />",
					getComponentName((type_ :: any).type) or "UNKNOWN"
				)
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
		local name
		-- ROBLOX deviation: use metatables to approximate Object.defineProperty logic
		setmetatable(elementType, {
			__index = function(self, key)
				if key == "displayName" then
					return name
				end
				return rawget(self, key)
			end,
			__newindex = function(self, key, value)
				if key == "displayName" then
					name = value
					-- ROBLOX deviation: render is a function and cannot have properties
					if
						typeof(type_) == "table"
						and (type_ :: React_AbstractComponent<Props, T>).displayName
							== nil
					then
						(type_ :: React_AbstractComponent<Props, T>).displayName = name
					end
				else
					rawset(self, key, value)
				end
			end,
		})
	end

	return elementType
end

return exports
