--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/41694201988c5e651f0c3bc69921d5c9717be88b/packages/react/src/ReactForwardRef.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactSymbols = require(Packages.Shared).ReactSymbols
local ReactTypes = require(Packages.Shared)
type React_Node = ReactTypes.React_Node
type React_Ref<ElementType> = ReactTypes.React_Ref<ElementType>
type React_AbstractComponent<Config, Instance> = ReactTypes.React_AbstractComponent<
	Config,
	Instance
>
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE

local exports = {}
-- ROBLOX TODO? should return Component's ELementType be REACT_FORWARD_REF_TYPE? probably, right?
exports.forwardRef =
	function<Props, ElementType>(
		render: (props: Props, ref: React_Ref<ElementType>) -> React_Node
	): React_AbstractComponent<Props, ElementType>
		if _G.__DEV__ then
			-- ROBLOX deviation START: Lua functions can't have properties given a table (which we can index to see if it's the Memo type)
			if
				typeof(render :: any) == "table"
				and (render :: any)["$$typeof"] == REACT_MEMO_TYPE
			then
				-- ROBLOX deviation END
				console.error(
					"forwardRef requires a render function but received a `memo` "
						.. "component. Instead of forwardRef(memo(...)), use "
						.. "memo(forwardRef(...))."
				)
			elseif typeof(render) ~= "function" then
				console.error(
					"forwardRef requires a render function but was given %s.",
					typeof(render)
				)
			else
				local argumentCount, _variadic = debug.info(render, "a")
				if argumentCount ~= 0 and argumentCount ~= 2 then
					console.error(
						"forwardRef render functions accept exactly two parameters: props and ref. %s",
						(function()
							if argumentCount == 1 then
								return "Did you forget to use the ref parameter?"
							end
							return "Any additional parameter will be undefined."
						end)()
					)
				end
			end

			-- deviation: in Luau, functions cannot have fields; for now, we don't
			-- support defaultProps and propTypes on function components anyways, so
			-- this check can safely be a no-op

			-- if render ~= null then
			--   if (render.defaultProps != null || render.propTypes != null) {
			--     console.error(
			--       'forwardRef render functions do not support propTypes or defaultProps. ' +
			--         'Did you accidentally pass a React component?',
			--     );
			--   }
			-- }
		end

		local elementType = {
			["$$typeof"] = REACT_FORWARD_REF_TYPE,
			render = render,
		}
		if _G.__DEV__ then
			local ownName
			-- ROBLOX deviation: use metatables to approximate Object.defineProperty logic
			setmetatable(elementType, {
				__index = function(self, key)
					if key == "displayName" then
						return ownName
					end
					return rawget(self, key)
				end,
				__newindex = function(self, key, value)
					if key == "displayName" then
						ownName = value
					-- ROBLOX deviation: render is a function and cannot have properties
					-- if (render.displayName == null) {
					--   render.displayName = name;
					-- }
					else
						rawset(self, key, value)
					end
				end,
			})
		end
		-- ROBLOX FIXME Luau: making us explicitly add nilable (optional) fields: because the former is missing fields 'forceUpdate', 'getChildContext', 'props', 'setState', and 'state
		return (elementType :: any) :: React_AbstractComponent<Props, ElementType>
	end

return exports
