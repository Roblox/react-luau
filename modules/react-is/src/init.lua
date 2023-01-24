--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-is/src/ReactIs.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local Packages = script.Parent
-- ROBLOX deviation START: not used
-- local LuauPolyfill = require(Packages.LuauPolyfill)
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
-- ROBLOX deviation START: use patched console from shared
-- local console = LuauPolyfill.console
local console = require(Packages.Shared).console
-- ROBLOX deviation END
local exports = {}
-- ROBLOX deviation START: fix import
-- local sharedReactSymbolsModule = require(Packages.shared.ReactSymbols)
local sharedReactSymbolsModule = require(Packages.Shared).ReactSymbols
-- ROBLOX deviation END
local REACT_CONTEXT_TYPE = sharedReactSymbolsModule.REACT_CONTEXT_TYPE
local REACT_ELEMENT_TYPE = sharedReactSymbolsModule.REACT_ELEMENT_TYPE
local REACT_FORWARD_REF_TYPE = sharedReactSymbolsModule.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = sharedReactSymbolsModule.REACT_FRAGMENT_TYPE
local REACT_LAZY_TYPE = sharedReactSymbolsModule.REACT_LAZY_TYPE
local REACT_MEMO_TYPE = sharedReactSymbolsModule.REACT_MEMO_TYPE
local REACT_PORTAL_TYPE = sharedReactSymbolsModule.REACT_PORTAL_TYPE
local REACT_PROFILER_TYPE = sharedReactSymbolsModule.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = sharedReactSymbolsModule.REACT_PROVIDER_TYPE
local REACT_STRICT_MODE_TYPE = sharedReactSymbolsModule.REACT_STRICT_MODE_TYPE
local REACT_SUSPENSE_TYPE = sharedReactSymbolsModule.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = sharedReactSymbolsModule.REACT_SUSPENSE_LIST_TYPE
-- ROBLOX deviation START: fix import
-- local isValidElementType = require(Packages.shared.isValidElementType).default
local isValidElementType = require(Packages.Shared).isValidElementType
-- ROBLOX deviation END
-- ROBLOX deviation START: additional imports
local REACT_BINDING_TYPE = sharedReactSymbolsModule.REACT_BINDING_TYPE
-- ROBLOX deviation END
local function typeOf(object: any)
	if typeof(object) == "table" and object ~= nil then
		local __typeof --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeof ]] =
			object["$$typeof"]
		-- ROBLOX deviation START: simplified switch statement conversion, adds Binding type check
		-- repeat --[[ ROBLOX comment: switch statement conversion ]]
		-- 	local entered_, break_ = false, false
		-- 	local condition_ = __typeof --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeof ]]
		-- 	for _, v in ipairs({ REACT_ELEMENT_TYPE, REACT_PORTAL_TYPE }) do
		-- 		if condition_ == v then
		-- 			if v == REACT_ELEMENT_TYPE then
		-- 				entered_ = true
		-- 				local type_ = object.type
		-- 				local condition_ = type_
		-- 				if
		-- 					condition_ == REACT_FRAGMENT_TYPE
		-- 					or condition_ == REACT_PROFILER_TYPE
		-- 					or condition_ == REACT_STRICT_MODE_TYPE
		-- 					or condition_ == REACT_SUSPENSE_TYPE
		-- 					or condition_ == REACT_SUSPENSE_LIST_TYPE
		-- 				then
		-- 					return type_
		-- 				else
		-- 					local __typeofType --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeofType ]] = if Boolean.toJSBoolean(
		-- 							type_
		-- 						)
		-- 						then type_["$$typeof"]
		-- 						else type_
		-- 					local condition_ = __typeofType --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeofType ]]
		-- 					if
		-- 						condition_ == REACT_CONTEXT_TYPE
		-- 						or condition_ == REACT_FORWARD_REF_TYPE
		-- 						or condition_ == REACT_LAZY_TYPE
		-- 						or condition_ == REACT_MEMO_TYPE
		-- 						or condition_ == REACT_PROVIDER_TYPE
		-- 					then
		-- 						return __typeofType --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeofType ]]
		-- 					else
		-- 						return __typeof --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeof ]]
		-- 					end
		-- 				end
		-- 			end
		-- 			if v == REACT_PORTAL_TYPE or entered_ then
		-- 				entered_ = true
		-- 				return __typeof --[[ ROBLOX CHECK: replaced unhandled characters in identifier. Original identifier: $$typeof ]]
		-- 			end
		-- 		end
		-- 	end
		-- until true
		if __typeof == REACT_ELEMENT_TYPE then
			local __type = object.type

			if
				__type == REACT_FRAGMENT_TYPE
				or __type == REACT_PROFILER_TYPE
				or __type == REACT_STRICT_MODE_TYPE
				or __type == REACT_SUSPENSE_TYPE
				or __type == REACT_SUSPENSE_LIST_TYPE
			then
				return __type
			else
				-- ROBLOX note: We need to check that __type is a table before we
				-- index into it, or Luau will throw errors
				local __typeofType = __type
					and typeof(__type) == "table"
					and __type["$$typeof"]

				if
					__typeofType == REACT_CONTEXT_TYPE
					or __typeofType == REACT_FORWARD_REF_TYPE
					or __typeofType == REACT_LAZY_TYPE
					or __typeofType == REACT_MEMO_TYPE
					or __typeofType == REACT_PROVIDER_TYPE
				then
					return __typeofType
				else
					return __typeof
				end
			end
		elseif
			__typeof == REACT_PORTAL_TYPE
			-- ROBLOX note: Bindings are a feature migrated from Roact
			or __typeof == REACT_BINDING_TYPE
		then
			return __typeof
		end
		-- ROBLOX deviation END
	end
	return nil
end
exports.typeOf = typeOf
local ContextConsumer = REACT_CONTEXT_TYPE
exports.ContextConsumer = ContextConsumer
local ContextProvider = REACT_PROVIDER_TYPE
exports.ContextProvider = ContextProvider
local Element = REACT_ELEMENT_TYPE
exports.Element = Element
local ForwardRef = REACT_FORWARD_REF_TYPE
exports.ForwardRef = ForwardRef
local Fragment = REACT_FRAGMENT_TYPE
exports.Fragment = Fragment
local Lazy = REACT_LAZY_TYPE
exports.Lazy = Lazy
local Memo = REACT_MEMO_TYPE
exports.Memo = Memo
local Portal = REACT_PORTAL_TYPE
exports.Portal = Portal
local Profiler = REACT_PROFILER_TYPE
exports.Profiler = Profiler
local StrictMode = REACT_STRICT_MODE_TYPE
exports.StrictMode = StrictMode
local Suspense = REACT_SUSPENSE_TYPE
exports.Suspense = Suspense
-- ROBLOX deviation START: export Roblox Only type
exports.Binding = sharedReactSymbolsModule.REACT_BINDING_TYPE
-- ROBLOX deviation END
exports.isValidElementType = isValidElementType
local hasWarnedAboutDeprecatedIsAsyncMode = false
local hasWarnedAboutDeprecatedIsConcurrentMode = false -- AsyncMode should be deprecated
local function isAsyncMode(object: any)
	-- ROBLOX deviation START: remove toJSBoolean, use _G.__DEV__
	-- if Boolean.toJSBoolean(__DEV__) then
	-- 	if not Boolean.toJSBoolean(hasWarnedAboutDeprecatedIsAsyncMode) then
	if _G.__DEV__ then
		if not hasWarnedAboutDeprecatedIsAsyncMode then
			-- ROBLOX deviation END
			hasWarnedAboutDeprecatedIsAsyncMode = true -- Using console['warn'] to evade Babel and ESLint
			console["warn"](
				"The ReactIs.isAsyncMode() alias has been deprecated, "
					.. "and will be removed in React 18+."
			)
		end
	end
	return false
end
exports.isAsyncMode = isAsyncMode
local function isConcurrentMode(object: any)
	-- ROBLOX deviation START: remove toJSBoolean, use _G.__DEV__
	-- if Boolean.toJSBoolean(__DEV__) then
	-- 	if not Boolean.toJSBoolean(hasWarnedAboutDeprecatedIsConcurrentMode) then
	if _G.__DEV__ then
		if not hasWarnedAboutDeprecatedIsConcurrentMode then
			-- ROBLOX deviation END
			hasWarnedAboutDeprecatedIsConcurrentMode = true -- Using console['warn'] to evade Babel and ESLint
			console["warn"](
				"The ReactIs.isConcurrentMode() alias has been deprecated, "
					.. "and will be removed in React 18+."
			)
		end
	end
	return false
end
exports.isConcurrentMode = isConcurrentMode
local function isContextConsumer(object: any)
	return typeOf(object) == REACT_CONTEXT_TYPE
end
exports.isContextConsumer = isContextConsumer
local function isContextProvider(object: any)
	return typeOf(object) == REACT_PROVIDER_TYPE
end
exports.isContextProvider = isContextProvider
local function isElement(object: any)
	return typeof(object) == "table"
		and object ~= nil
		and object["$$typeof"] == REACT_ELEMENT_TYPE
end
exports.isElement = isElement
local function isForwardRef(object: any)
	return typeOf(object) == REACT_FORWARD_REF_TYPE
end
exports.isForwardRef = isForwardRef
local function isFragment(object: any)
	return typeOf(object) == REACT_FRAGMENT_TYPE
end
exports.isFragment = isFragment
local function isLazy(object: any)
	return typeOf(object) == REACT_LAZY_TYPE
end
exports.isLazy = isLazy
local function isMemo(object: any)
	return typeOf(object) == REACT_MEMO_TYPE
end
exports.isMemo = isMemo
local function isPortal(object: any)
	return typeOf(object) == REACT_PORTAL_TYPE
end
exports.isPortal = isPortal
local function isProfiler(object: any)
	return typeOf(object) == REACT_PROFILER_TYPE
end
exports.isProfiler = isProfiler
local function isStrictMode(object: any)
	return typeOf(object) == REACT_STRICT_MODE_TYPE
end
exports.isStrictMode = isStrictMode
local function isSuspense(object: any)
	return typeOf(object) == REACT_SUSPENSE_TYPE
end
exports.isSuspense = isSuspense
-- ROBLOX deviation START: Bindings are a feature migrated from Roact
exports.isBinding = function(object: any)
	return typeOf(object) == REACT_BINDING_TYPE
end
-- ROBLOX deviation END
return exports
