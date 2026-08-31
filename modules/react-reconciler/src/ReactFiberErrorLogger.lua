--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-reconciler/src/ReactFiberErrorLogger.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local setTimeout = LuauPolyfill.setTimeout

local Shared = require(Packages.Shared)
local console = Shared.console
local errorToString = Shared.errorToString
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

-- ROBLOX upstream: https://github.com/facebook/react/blob/861811347b8fa936b4a114fc022db9b8253b3d86/packages/react-reconciler/src/ReactFiberErrorLogger.js#L27-L128
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
		if typeof(error_) == "table" and error_._suppressLogging then
			return
		end
		local componentNameMessage = if componentName ~= nil
			then "The above error occurred in the <" .. componentName .. "> component:"
			else "The above error occurred in one of your React components:"
		local errorBoundaryMessage = if errorBoundaryName ~= nil
			then "React will try to recreate this component tree from scratch "
				.. "using the error boundary you provided, "
				.. errorBoundaryName
				.. "."
			else "Consider adding an error boundary to your tree to customize error handling behavior.\n"
				.. "Visit https://reactjs.org/link/error-boundaries to learn more about error boundaries."
		console["error"](
			componentNameMessage
				.. "\n"
				.. (errorInfo.componentStack or "")
				.. "\n\n"
				.. errorBoundaryMessage
		)
	else
		console["error"](inspect(error_))
	end
end

exports.defaultOnRecoverableError = function(error_: any, _errorInfo: ErrorInfo)
	reportGlobalError(error_)
end

local function scheduleRethrow(error_: any)
	setTimeout(function()
		error(errorToString(error_), 0)
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
