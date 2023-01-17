--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/42c3c967d1e4ca4731b47866f2090bc34caa086c/packages/shared/invariant.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
]]

--[[*
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
]]
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error

local function invariant(condition, format, ...)
	-- ROBLOX TODO: we should encapsulate all formatting compatibility here,
	-- rather than spreading workarounds throughout the codebase, eg this
	-- should print an array without the need for a table.concat on the consumer side
	if not condition then
		error(Error(string.format(format, ...)))
	end
end

return invariant
