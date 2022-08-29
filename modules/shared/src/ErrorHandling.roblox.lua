--!strict
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
local Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect

local DIVIDER = "\n------ Error caught by React ------\n"

--[[
	React does a lot of catching, retrying, and rethrowing errors that would
	typically result in loss of meaningful stack information.

	We use xpcall combined with this error function to capture and rethrow in a
	way that retains some stack information.
]]
local function describeError(e: string | Error): Error
	if typeof(e) == "string" then
		local _, endOfStackFrame = string.find(e, ":[%d]+: ")
		local message = if endOfStackFrame then string.sub(e, endOfStackFrame + 1) else e

		local err = LuauPolyfill.Error.new(message)
		err.stack = debug.traceback(nil, 2)
		return err
	end
	return e :: Error
end

--[[
	Even though Luau can catch and rethrow arbitrary objects, only string errors
	are supported by the ScriptContext.ErrorDetailed signal (the mechanism used
	to catch unhandled errors at the top level).

	This function turns an arbitrary error object into a detailed string message
	to avoid any loss of information.
]]
local function errorToString(error_: Error | Object | string | Array<any>): string
	local errorString
	if typeof(error_) == "table" then
		if (error_ :: Error).message and (error_ :: Error).stack then
			-- Adding these clear dividers helps us split this error back up
			-- into pieces later. We include one at the beginning so that the
			-- final stack frame added by rethrowing can be carved off
			errorString = DIVIDER
				.. (error_ :: Error).message
				.. DIVIDER
				.. tostring((error_ :: Error).stack)
		else
			errorString = inspect(error_)
		end
	else
		errorString = inspect(error_)
	end

	return errorString
end

--[[
	If an error string was generated from an Error object via the errorToString
	function above, it can be easily split back out into an informative error
	object.
]]
local function parseReactError(error_: string): (Error, string)
	local split = string.split(error_, DIVIDER)

	if #split == 3 then
		local rethrow, message, stack = table.unpack(split)

		local newError = Error.new(message)
		newError.stack = stack

		return newError, rethrow
	else
		-- This error was not in the expected format, so we use the whole string
		-- as the 'message' value and nil out the stack (it would be misleading
		-- if we included the one generated here)
		local newError = Error.new(error_)
		newError.stack = nil

		return newError, ""
	end
end

return {
	describeError = describeError,
	errorToString = errorToString,
	parseReactError = parseReactError,
	-- Used only by tests
	__ERROR_DIVIDER = DIVIDER,
}
