-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberDevToolsHook.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local LuauPolyfill = require(Packages.LuauPolyfill)
type Object = LuauPolyfill.Object
local exports = {}

-- ROBLOX deviation: subset copied here from devtools-shared/backend/types, to have stronger enforcement than 'Object' without circular dep
type DevToolsHook = {
	-- ROBLOX TODO: ideally, ReactRenderer type would be importable from this file so we could use it here
	inject: (Object) -> number | nil,
	supportsFiber: boolean,
	isDisabled: boolean,
	--   ...
}

-- ROBLOX deviation: we use callable tables instead of functions sometimes, so typeof() == "function" isn't enough
local function isCallable(value)
	if typeof(value) == "function" then
		return true
	end
	if typeof(value) == "table" then
		local mt = getmetatable(value)
		if mt and rawget(mt, "__call") then
			return true
		end
		if value._isMockFunction then
			return true
		end
	end
	return false
end

local enableProfilerTimer = require(Packages.Shared).ReactFeatureFlags.enableProfilerTimer

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList

local DidCapture = require(script.Parent.ReactFiberFlags).DidCapture

-- ROBLOX deviation: we'll inject this a different way
-- declare var __REACT_DEVTOOLS_GLOBAL_HOOK__: Object | void

local rendererID = nil
local injectedHook = nil
local hasLoggedError = false

-- ROBLOX deviation: We use a function to handle the hook being changed at runtime
exports.isDevToolsPresent = function()
	return _G.__REACT_DEVTOOLS_GLOBAL_HOOK__ ~= nil
end

exports.injectInternals = function(internals: Object): boolean
	if _G.__REACT_DEVTOOLS_GLOBAL_HOOK__ == nil then
		-- No DevTools
		return false
	end
	local hook: DevToolsHook = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
	if hook.isDisabled then
		-- This isn't a real property on the hook, but it can be set to opt out
		-- of DevTools integration and associated warnings and logs.
		-- http://github.com/facebook/react/issues/3877
		return true
	end
	if not hook.supportsFiber then
		if _G.__DEV__ then
			console.error(
				"The installed version of React DevTools is too old and will not work "
					.. "with the current version of React. Please update React DevTools. "
					.. "https://reactjs.org/link/react-devtools"
			)
		end
		-- DevTools exists, even though it doesn't support Fiber.
		return true
	end
	local ok, err = pcall(function()
		rendererID = hook.inject(internals)
		-- We have successfully injected, so now it is safe to set up hooks.
		injectedHook = hook
	end)

	if not ok then
		-- Catch all errors because it is unsafe to throw during initialization.
		if _G.__DEV__ then
			console.error("React instrumentation encountered an error: %s.", err)
		end
	end
	-- DevTools exists
	return true
end

exports.onScheduleRoot = function(root: FiberRoot, children: ReactNodeList)
	if _G.__DEV__ then
		if
			injectedHook
			-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
			and isCallable(injectedHook.onScheduleFiberRoot)
		then
			local ok, err =
				pcall(injectedHook.onScheduleFiberRoot, rendererID, root, children)

			if not ok then
				if _G.__DEV__ and not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

exports.onCommitRoot = function(root: FiberRoot, priorityLevel: ReactPriorityLevel)
	if
		injectedHook
		-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
		and isCallable(injectedHook.onCommitFiberRoot)
	then
		local ok, err = pcall(function()
			local didError = bit32.band(root.current.flags, DidCapture) == DidCapture
			if enableProfilerTimer then
				injectedHook.onCommitFiberRoot(rendererID, root, priorityLevel, didError)
			else
				injectedHook.onCommitFiberRoot(rendererID, root, nil, didError)
			end
		end)
		if not ok then
			if _G.__DEV__ then
				if not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

exports.onCommitUnmount = function(fiber: Fiber)
	if
		injectedHook
		-- ROBLOX deviation: our mocked functions are tables with __call, since they have fields
		and isCallable(injectedHook.onCommitFiberUnmount)
	then
		local ok, err = pcall(injectedHook.onCommitFiberUnmount, rendererID, fiber)
		if not ok then
			if _G.__DEV__ then
				if not hasLoggedError then
					hasLoggedError = true
					console.error("React instrumentation encountered an error: %s", err)
				end
			end
		end
	end
end

return exports
