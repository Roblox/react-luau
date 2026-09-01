--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberErrorLogger.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
local inspect = LuauPolyfill.util.inspect
local setTimeout = LuauPolyfill.setTimeout

local Shared = require(Packages.Shared)
local console = Shared.console
local reportGlobalError = Shared.reportGlobalError

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type ErrorInfo = ReactInternalTypes.ErrorInfo
type CaughtErrorInfo = ReactInternalTypes.CaughtErrorInfo
local ReactCapturedValue = require(script.Parent.ReactCapturedValue)
type CapturedValue<T> = ReactCapturedValue.CapturedValue<T>

local ClassComponent = require(script.Parent.ReactWorkTags).ClassComponent
local getComponentName = require(Packages.Shared).getComponentName

local exports = {}

local componentName: string? = nil
local errorBoundaryName: string? = nil

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberErrorLogger.js#L27-L192
exports.defaultOnUncaughtError = function(error_: any, _errorInfo: ErrorInfo)
	reportGlobalError(error_)
	if ReactGlobals.__DEV__ then
		local componentNameMessage = if componentName ~= nil
			then "An error occurred in the <" .. componentName .. "> component."
			else "An error occurred in one of your React components."
		console.warn(
			componentNameMessage
				.. "\n\nConsider adding an error boundary to your tree to customize error handling behavior.\n"
				.. "Visit https://react.dev/link/error-boundaries to learn more about error boundaries."
		)
	end
end

exports.defaultOnCaughtError = function(error_: any, errorInfo: CaughtErrorInfo)
	if ReactGlobals.__DEV__ then
		-- ROBLOX DEVIATION: Retain React 17's testing escape hatch because
		-- React-Luau has no browser error event whose default can be prevented.
		if typeof(error_) == "table" and error_._suppressLogging then
			return
		end
		-- ROBLOX DEVIATION: Retain the React 17 message shape so existing
		-- renderer console contracts keep their component-focused output.
		local componentNameMessage = if componentName ~= nil
			then "The above error occurred in the <" .. componentName .. "> component:"
			else "The above error occurred in one of your React components:"
		local errorBoundaryMessage
		if errorBoundaryName ~= nil then
			errorBoundaryMessage = "React will try to recreate this component tree from scratch "
				.. "using the error boundary you provided, "
				.. errorBoundaryName
				.. "."
		else
			-- ROBLOX DEVIATION: Legacy internal roots also use this formatter, so
			-- retain React 17's no-boundary guidance instead of naming Anonymous.
			errorBoundaryMessage = "Consider adding an error boundary to your tree to customize error handling behavior.\n"
				-- ROBLOX DEVIATION: Retain the React 17 URL as part of the legacy
				-- console message contract used by internal renderer tests.
				.. "Visit https://reactjs.org/link/error-boundaries to learn more about error boundaries."
		end
		-- ROBLOX DEVIATION: React-Luau has no DevTools console wrapper that
		-- appends component stacks, so include the stack in the message.
		console["error"](
			componentNameMessage
				.. "\n"
				.. (errorInfo.componentStack or "")
				.. "\n\n"
				.. errorBoundaryMessage
		)
	else
		-- ROBLOX DEVIATION: Retain React 17's string inspection because the
		-- patched Luau console does not provide a browser-native object display.
		console["error"](inspect(error_))
	end
end

exports.defaultOnRecoverableError = function(error_: any, _errorInfo: ErrorInfo)
	reportGlobalError(error_)
end

local function scheduleRethrow(error_: any)
	-- Error logging must not interrupt React's internal commit state. Surface a
	-- handler failure outside the normal stack as a last resort instead.
	-- https://github.com/facebook/react/issues/13188
	setTimeout(function()
		-- Preserve the original callback error value, matching upstream's throw.
		error(error_, 0)
	end)
end

exports.logUncaughtError = function(root: FiberRoot, errorInfo: CapturedValue<any>)
	local ok, callbackError = pcall(function()
		if ReactGlobals.__DEV__ then
			componentName = if errorInfo.source ~= nil
				then getComponentName(errorInfo.source.type)
				else nil
			errorBoundaryName = nil
		end
		root.onUncaughtError(errorInfo.value, {
			componentStack = errorInfo.stack,
		})
	end)
	if not ok then
		scheduleRethrow(callbackError)
	end
end

exports.logCaughtError = function(
	root: FiberRoot,
	boundary: Fiber,
	errorInfo: CapturedValue<any>
)
	local ok, callbackError = pcall(function()
		if ReactGlobals.__DEV__ then
			componentName = if errorInfo.source ~= nil
				then getComponentName(errorInfo.source.type)
				else nil
			errorBoundaryName = getComponentName(boundary.type)
		end
		root.onCaughtError(errorInfo.value, {
			componentStack = errorInfo.stack,
			errorBoundary = if boundary.tag == ClassComponent
				then boundary.stateNode
				else nil,
		})
	end)
	if not ok then
		scheduleRethrow(callbackError)
	end
end

return exports
