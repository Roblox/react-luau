--!strict
-- upstream: https://github.com/facebook/react/blob/60ba723bf78b9a28f60dce854e88e206fab52301/packages/react-is/src/ReactIs.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 *
 ]]

local Packages = script.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local ReactSymbols = require(Packages.Shared).ReactSymbols
local isValidElementType = require(Packages.Shared).isValidElementType

local exports = {}

exports.typeOf = function(object: any)
	if typeof(object) == "table" and object ~= nil then
		local __typeof = object["$$typeof"]

		if __typeof == ReactSymbols.REACT_ELEMENT_TYPE then
			local __type = object.type

			if
				__type == ReactSymbols.REACT_FRAGMENT_TYPE
				or __type == ReactSymbols.REACT_PROFILER_TYPE
				or __type == ReactSymbols.REACT_STRICT_MODE_TYPE
				or __type == ReactSymbols.REACT_SUSPENSE_TYPE
				or __type == ReactSymbols.REACT_SUSPENSE_LIST_TYPE
			then
				return __type
			else
				-- deviation: We need to check that __type is a table before we
				-- index into it, or Luau will throw errors
				local __typeofType = __type
					and typeof(__type) == "table"
					and __type["$$typeof"]

				if
					__typeofType == ReactSymbols.REACT_CONTEXT_TYPE
					or __typeofType == ReactSymbols.REACT_FORWARD_REF_TYPE
					or __typeofType == ReactSymbols.REACT_LAZY_TYPE
					or __typeofType == ReactSymbols.REACT_MEMO_TYPE
					or __typeofType == ReactSymbols.REACT_PROVIDER_TYPE
				then
					return __typeofType
				else
					return __typeof
				end
			end
		elseif
			__typeof == ReactSymbols.REACT_PORTAL_TYPE
			-- ROBLOX deviation: Bindings are a feature migrated from Roact
			or __typeof == ReactSymbols.REACT_BINDING_TYPE
		then
			return __typeof
		end
	end

	return nil
end

exports.ContextConsumer = ReactSymbols.REACT_CONTEXT_TYPE
exports.ContextProvider = ReactSymbols.REACT_PROVIDER_TYPE
exports.Element = ReactSymbols.REACT_ELEMENT_TYPE
exports.ForwardRef = ReactSymbols.REACT_FORWARD_REF_TYPE
exports.Fragment = ReactSymbols.REACT_FRAGMENT_TYPE
exports.Lazy = ReactSymbols.REACT_LAZY_TYPE
exports.Memo = ReactSymbols.REACT_MEMO_TYPE
exports.Portal = ReactSymbols.REACT_PORTAL_TYPE
exports.Profiler = ReactSymbols.REACT_PROFILER_TYPE
exports.StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE
exports.Suspense = ReactSymbols.REACT_SUSPENSE_TYPE
exports.Binding = ReactSymbols.REACT_BINDING_TYPE
exports.isValidElementType = isValidElementType
local hasWarnedAboutDeprecatedIsAsyncMode = false
local hasWarnedAboutDeprecatedIsConcurrentMode = false -- AsyncMode should be deprecated
exports.isAsyncMode = function(object: any)
	if _G.__DEV__ then
		if not hasWarnedAboutDeprecatedIsAsyncMode then
			hasWarnedAboutDeprecatedIsAsyncMode = true
			-- Using console['warn'] to evade Babel and ESLint

			console["warn"](
				"The ReactIs.isAsyncMode() alias has been deprecated, "
					.. "and will be removed in React 18+."
			)
		end
	end

	return false
end

exports.isConcurrentMode = function(object: any)
	if _G.__DEV__ then
		if not hasWarnedAboutDeprecatedIsConcurrentMode then
			hasWarnedAboutDeprecatedIsConcurrentMode = true
			-- Using console['warn'] to evade Babel and ESLint

			console["warn"](
				"The ReactIs.isConcurrentMode() alias has been deprecated, "
					.. "and will be removed in React 18+."
			)
		end
	end

	return false
end

exports.isContextConsumer = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_CONTEXT_TYPE
end
exports.isContextProvider = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_PROVIDER_TYPE
end
exports.isElement = function(object: any)
	return (
			(typeof(object) == "table" and object ~= nil)
			and object["$$typeof"] == ReactSymbols.REACT_ELEMENT_TYPE
		)
end
exports.isForwardRef = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_FORWARD_REF_TYPE
end
exports.isFragment = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_FRAGMENT_TYPE
end
exports.isLazy = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_LAZY_TYPE
end
exports.isMemo = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_MEMO_TYPE
end
exports.isPortal = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_PORTAL_TYPE
end
exports.isProfiler = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_PROFILER_TYPE
end
exports.isStrictMode = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_STRICT_MODE_TYPE
end
exports.isSuspense = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_SUSPENSE_TYPE
end
-- ROBLOX deviation: Bindings are a feature migrated from Roact
exports.isBinding = function(object: any)
	return exports.typeOf(object) == ReactSymbols.REACT_BINDING_TYPE
end

return exports
