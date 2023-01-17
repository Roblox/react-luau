-- ROBLOX upstream: https://github.com/facebook/react/blob/b61174fb7b09580c1ec2a8f55e73204b706d2935/packages/shared/isValidElementType.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
 ]]
local ReactSymbols = require(script.Parent.ReactSymbols)
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PROFILER_TYPE = ReactSymbols.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_DEBUG_TRACING_MODE_TYPE = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE
local REACT_STRICT_MODE_TYPE = ReactSymbols.REACT_STRICT_MODE_TYPE
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
-- local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_FUNDAMENTAL_TYPE = ReactSymbols.REACT_FUNDAMENTAL_TYPE
-- local REACT_SCOPE_TYPE = ReactSymbols.REACT_SCOPE_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local REACT_SERVER_BLOCK_TYPE = ReactSymbols.REACT_SERVER_BLOCK_TYPE
local REACT_LEGACY_HIDDEN_TYPE = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE

-- local ReactFeatureFlags = require(script.Parent.ReactFeatureFlags)
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI

return function(type)
	local typeofType = typeof(type)
	if typeofType == "string" or typeofType == "function" then
		return true
	end

	-- Note: typeof might be other than 'symbol' or 'number' (e.g. if it's a polyfill).
	if
		type == REACT_FRAGMENT_TYPE
		or type == REACT_PROFILER_TYPE
		or type == REACT_DEBUG_TRACING_MODE_TYPE
		or type == REACT_STRICT_MODE_TYPE
		or type == REACT_SUSPENSE_TYPE
		or type == REACT_LEGACY_HIDDEN_TYPE
		-- ROBLOX performance: eliminate compares that will only be true in React 18
		-- or type == REACT_SUSPENSE_LIST_TYPE
		-- or (enableScopeAPI and type == REACT_SCOPE_TYPE)
	then
		return true
	end

	if typeofType == "table" then
		-- ROBLOX deviation: In React, component classes are of type 'function'; for
		-- us, they're tables with a special value on their metatable
		if type.isReactComponent then
			return true
		end

		if
			type["$$typeof"] == REACT_LAZY_TYPE
			or type["$$typeof"] == REACT_MEMO_TYPE
			or type["$$typeof"] == REACT_PROVIDER_TYPE
			or type["$$typeof"] == REACT_CONTEXT_TYPE
			or type["$$typeof"] == REACT_FORWARD_REF_TYPE
			or type["$$typeof"] == REACT_FUNDAMENTAL_TYPE
			or type["$$typeof"] == REACT_BLOCK_TYPE
			or type[1] == REACT_SERVER_BLOCK_TYPE
		then
			return true
		end
	end

	return false
end
