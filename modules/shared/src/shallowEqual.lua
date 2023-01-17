-- ROBLOX upstream: https://github.com/facebook/react/blob/a9b035b0c2b8235405835beca0c4db2cc37f18d0/packages/shared/shallowEqual.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
]]
local is = require(script.Parent.objectIs)

--[[*
 * Performs equality by iterating through keys on an object and returning false
 * when any key has values which are not strictly equal between the arguments.
 * Returns true when the values of all keys are strictly equal.
]]
local function shallowEqual(objA, objB)
	if is(objA, objB) then
		return true
	end

	if
		typeof(objA) ~= "table"
		or objA == nil
		or typeof(objB) ~= "table"
		or objB == nil
	then
		return false
	end

	-- deviation: `Object.keys` does not have an equivalent in Lua, so we
	-- iterate through each table instead
	for key, value in objA do
		if not is(objB[key], value) then
			return false
		end
	end

	for key, value in objB do
		if not is(objA[key], value) then
			return false
		end
	end

	return true
end

return shallowEqual
