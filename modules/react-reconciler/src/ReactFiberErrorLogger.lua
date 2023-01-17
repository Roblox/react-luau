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
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local setTimeout = LuauPolyfill.setTimeout

local Shared = require(Packages.Shared)
local console = Shared.console
local errorToString = Shared.errorToString

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactCapturedValue = require(script.Parent.ReactCapturedValue)
type CapturedValue<T> = ReactCapturedValue.CapturedValue<T>

local showErrorDialog = require(script.Parent.ReactFiberErrorDialog).showErrorDialog
local ClassComponent = require(script.Parent.ReactWorkTags).ClassComponent
local getComponentName = require(Packages.Shared).getComponentName

local exports = {}

exports.logCapturedError = function(boundary: Fiber, errorInfo: CapturedValue<any>)
	local ok, e = pcall(function()
		local logError = showErrorDialog(boundary, errorInfo)

		-- Allow injected showErrorDialog() to prevent default console.error logging.
		-- This enables renderers like ReactNative to better manage redbox behavior.
		if logError == false then
			-- ROBLOX Luau FIXME: needs void return Luau bugfix
			return nil
		end

		local error_ = errorInfo.value
		if _G.__DEV__ then
			local source = errorInfo.source
			local stack = errorInfo.stack
			local componentStack = stack or ""
			-- Browsers support silencing uncaught errors by calling
			-- `preventDefault()` in window `error` handler.
			-- We record this information as an expando on the error.
			if error_ ~= nil and error_._suppressLogging then
				if boundary.tag == ClassComponent then
					-- The error is recoverable and was silenced.
					-- Ignore it and don't print the stack addendum.
					-- This is handy for testing error boundaries without noise.
					return
				end
				-- The error is fatal. Since the silencing might have
				-- been accidental, we'll surface it anyway.
				-- However, the browser would have silenced the original error
				-- so we'll print it first, and then print the stack addendum.
				console["error"](error_) -- Don't transform to our wrapper
				-- For a more detailed description of this block, see:
				-- https://github.com/facebook/react/pull/13384
			end

			local componentName
			if source ~= nil then
				componentName = getComponentName(source.type)
			else
				componentName = nil
			end

			local componentNameMessage
			if componentName then
				componentNameMessage = "The above error occurred in the <"
					.. tostring(componentName)
					.. "> component:"
			else
				componentNameMessage =
					"The above error occurred in one of your React components:"
			end

			local errorBoundaryMessage
			local errorBoundaryName = getComponentName(boundary.type)
			if errorBoundaryName then
				errorBoundaryMessage = "React will try to recreate this component tree from scratch "
					.. "using the error boundary you provided, "
					.. errorBoundaryName
					.. "."
			else
				errorBoundaryMessage = "Consider adding an error boundary to your tree to customize error handling behavior.\n"
					.. "Visit https://reactjs.org/link/error-boundaries to learn more about error boundaries."
			end
			local combinedMessage = componentNameMessage
				.. "\n"
				.. componentStack
				.. "\n\n"
				.. errorBoundaryMessage

			-- In development, we provide our own message with just the component stack.
			-- We don't include the original error message and JS stack because the browser
			-- has already printed it. Even if the application swallows the error, it is still
			-- displayed by the browser thanks to the DEV-only fake event trick in ReactErrorUtils.
			console["error"](combinedMessage) -- Don't transform to our wrapper
		else
			-- In production, we print the error directly.
			-- This will include the message, the JS stack, and anything the browser wants to show.
			-- We pass the error object instead of custom message so that the browser displays the error natively.
			console["error"](inspect(error_)) -- Don't transform to our wrapper
		end

		-- ROBLOX Luau FIXME: needs void return Luau bugfix
		return nil
	end)

	if not ok then
		warn("failed to error with error: " .. inspect(e))
		-- ROBLOX TODO: we may need to think about this more deeply and do something different
		-- This method must not throw, or React internal state will get messed up.
		-- If console.error is overridden, or logCapturedError() shows a dialog that throws,
		-- we want to report this error outside of the normal stack as a last resort.
		-- https://github.com/facebook/react/issues/13188
		setTimeout(function()
			-- ROBLOX FIXME: the top-level Luau VM handler doesn't deal with non-string errors, so massage it until VM support lands
			error(errorToString(e :: any))
		end)
	end
end

return exports
