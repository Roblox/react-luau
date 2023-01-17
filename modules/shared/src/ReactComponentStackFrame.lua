--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/shared/ReactComponentStackFrame.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

type Object = { [string]: any }
type Function = (...any) -> ...any

local ReactElementType = require(script.Parent.ReactElementType)
type Source = ReactElementType.Source

-- ROBLOX deviation: Needed to properly type class components
local flowtypes = require(script.Parent["flowtypes.roblox"])
type React_StatelessFunctionalComponent<P> = flowtypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = flowtypes.React_ComponentType<P>
type ReactComponent<P> = React_StatelessFunctionalComponent<P> | React_ComponentType<P>

-- ROBLOX DEVIATION: Ignore enableComponentStackLocations
-- local ReactFeatureFlags = require(script.Parent.ReactFeatureFlags)
-- local enableComponentStackLocations = ReactFeatureFlags.enableComponentStackLocations

local ReactSymbols = require(script.Parent.ReactSymbols)
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE

local ConsolePatchingDev = require(script.Parent["ConsolePatchingDev.roblox"])
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
local ReactCurrentDispatcher = ReactSharedInternals.ReactCurrentDispatcher

-- ROBLOX deviation: the prefix is constant because the console prints the stack
-- frames the same way on every platform.
local prefix = "    in "

-- ROBLOX deviation: declare these now because of scoping differences between in
-- Lua and JS
local describeComponentFrame
local describeFunctionComponentFrame

-- ROBLOX deviation: since owner could be a function or a class component, we
-- need to do additional handling to get its name. It's easier to make this a
-- reusable function
local function describeOwner(owner: nil | ReactComponent<any>): string?
	if type(owner) == "function" then
		return debug.info(owner :: (any) -> any, "n")
	elseif type(owner) == "table" then
		return tostring(owner)
	end
	return nil
end

local function describeBuiltInComponentFrame(
	name: string,
	source: Source | nil,
	-- ROBLOX deviation: owner could be a class component
	owner: nil | ReactComponent<any>
): string
	-- ROBLOX deviation START: for built-in components, we can provide the full
	-- description regardless of `enableStackLocations` since we don't actually
	-- need to do any callstack trickery to get it

	-- if enableComponentStackLocations then
	-- 	if prefix == nil then
	-- 		-- Extract the VM specific prefix used by each line.
	-- 		local _, x = pcall(error, debug.traceback())

	-- 		local match = x.stack.trim().match("\n00:00:00.000 - ")
	-- 		if match then
	-- 			prefix = match[1]
	-- 		else
	-- 			prefix = ''
	-- 		end
	-- 	end
	-- 	-- We use the prefix to ensure our stacks line up with native stack frames.
	-- 	return "\n" .. prefix .. name
	-- else
	-- 	local ownerName = nil
	-- 	if _G.__DEV__ and owner then
	-- 		ownerName = describeOwner(owner)
	-- 	end

	-- 	return describeComponentFrame(name, source, ownerName)
	-- end
	local ownerName = nil
	if _G.__DEV__ and owner then
		ownerName = describeOwner(owner)
	end

	return describeComponentFrame(name, source, ownerName)
	-- ROBLOX deviation END
end

local reentry = false
local componentFrameCache = nil
if _G.__DEV__ then
	componentFrameCache = setmetatable({}, { __mode = "k" })
end

local function describeNativeComponentFrame(
	fn: nil | ReactComponent<any>, -- ROBLOX TODO: only accept tables with __tostring metamethod overridden
	construct: boolean
): string
	-- // If something asked for a stack inside a fake render, it should get ignored.
	if not fn or reentry then
		return ""
	end

	if _G.__DEV__ then
		local frame = componentFrameCache[fn]

		if frame ~= nil then
			return frame
		end
	end

	local control
	reentry = true

	-- deviation: Error.prepareStackTrace is not implemented
	-- local previousPrepareStackTrace = Error.prepareStackTrace
	-- Error.prepareStackTrace = undefined
	local previousDispatcher

	if _G.__DEV__ then
		previousDispatcher = ReactCurrentDispatcher.current
		-- Set the dispatcher in DEV because this might be call in the render
		-- function for warnings.
		ReactCurrentDispatcher.current = nil
		disableLogs()
	end

	-- // This should throw.
	-- deviation: Lua does not have stack traces with errors, so we
	-- use xpcall to convert the error and append a stack trace.
	-- This will change the theorical stack trace we want, because of
	-- the function where we call 'debug.traceback()', but the control
	-- stack will have the same added frame.
	local traceback
	local _, sample = xpcall(function()
		if construct then
			-- deviation: since we can't have a meaningful stack trace when
			-- constructing from a component class (because it does not locate
			-- component definition), we skip this case.
		else
			local _, x = pcall(function()
				traceback = debug.traceback()
				error({
					stack = traceback,
				})
			end)
			control = x;
			-- ROBLOX FIXME: Luau flow analysis bug workaround
			(fn :: (...any) -> ...any)()
		end
	end, function(message)
		return {
			message = message,
			stack = traceback,
		}
	end)

	-- deviation: Lua does not have a structure that works like a try-catch-finally
	-- so we a variable to know if the catch block returns a value. If it returns,
	-- 'earlyOutValue' will be set and we can return its value after running the
	-- instructions in the finally block.
	local earlyOutValue = nil

	if sample and control and type(sample.stack) == "string" then
		-- // This extracts the first frame from the sample that isn't also in the control.
		-- // Skipping one frame that we assume is the frame that calls the two.
		local sampleLines = string.split(sample.stack, "\n")
		local controlLines = string.split(control.stack, "\n")
		-- deviation: remove one because our array of lines contains an empty string
		-- at the end
		local sampleIndex = #sampleLines - 1
		local controlIndex = #controlLines - 1

		while
			sampleIndex >= 2
			and controlIndex >= 0
			and sampleLines[sampleIndex] ~= controlLines[controlIndex]
		do
			-- // We expect at least one stack frame to be shared.
			-- // Typically this will be the root most one. However, stack frames may be
			-- // cut off due to maximum stack limits. In this case, one maybe cut off
			-- // earlier than the other. We assume that the sample is longer or the same
			-- // and there for cut off earlier. So we should find the root most frame in
			-- // the sample somewhere in the control.
			controlIndex = controlIndex - 1
		end

		while sampleIndex >= 3 and controlIndex >= 1 do
			sampleIndex = sampleIndex - 1
			controlIndex = controlIndex - 1
			-- // Next we find the first one that isn't the same which should be the
			-- // frame that called our sample function and the control.
			if sampleLines[sampleIndex] ~= controlLines[controlIndex] then
				-- // In V8, the first line is describing the message but other VMs don't.
				-- // If we're about to return the first line, and the control is also on the same
				-- // line, that'sampleIndex a pretty good indicator that our sample threw at same line as
				-- // the control. I.e. before we entered the sample frame. So we ignore this result.
				-- // This can happen if you passed a class to function component, or non-function.
				if sampleIndex ~= 1 or controlIndex ~= 1 then
					repeat
						sampleIndex = sampleIndex - 1
						controlIndex = controlIndex - 1
						-- // We may still have similar intermediate frames from the construct call.
						-- // The next one that isn't the same should be our match though.
						if
							controlIndex < 0
							or sampleLines[sampleIndex] ~= controlLines[controlIndex]
						then
							-- deviation: add the '    in ' prefix to format the component stack
							-- similar to React
							local frame = "\n" .. prefix .. sampleLines[sampleIndex]

							if _G.__DEV__ then
								componentFrameCache[fn] = frame
							end
							-- // Return the line we found.
							-- deviation: to mimic the behavior of the try-catch-finally
							-- we cannot return the value here.
							earlyOutValue = frame
						end
					until not (sampleIndex >= 3 and controlIndex >= 1)
				end

				break
			end
		end
	end

	reentry = false
	if _G.__DEV__ then
		ReactCurrentDispatcher.current = previousDispatcher
		reenableLogs()
	end

	-- deviation: Error.prepareStackTrace is not implemented
	-- Error.prepareStackTrace = previousPrepareStackTrace

	-- deviation: return here to micmic the end of the finally block
	if earlyOutValue ~= nil then
		return earlyOutValue
	end

	-- Fallback to just using the name if we couldn't make it throw.
	-- ROBLOX deviation START: Can't get displayName for functions, since fn can be a class, we can get the class name here
	local name = if type(fn) == "function"
		then debug.info(fn :: Function, "n")
		-- ROBLOX deviation :
		else if type(fn) == "table" then tostring(fn) else ""

	local syntheticFrame = ""
	if name ~= nil and name ~= "" then
		syntheticFrame = describeBuiltInComponentFrame(name)
	end

	if _G.__DEV__ then
		componentFrameCache[fn] = syntheticFrame
	end

	return syntheticFrame
end

-- ROBLOX deviation: Lua's patterns work slightly differently than regexes
local BEFORE_SLASH_PATTERN = "^(.*)[\\/]"

function describeComponentFrame(
	name: string | nil,
	source: Source | nil,
	ownerName: string | nil
): string
	local sourceInfo = ""

	if _G.__DEV__ and source then
		local path = source.fileName
		local fileName = string.gsub(path, BEFORE_SLASH_PATTERN, "")

		-- // In DEV, include code for a common special case:
		-- // prefer "folder/index.js" instead of just "index.js".
		-- ROBLOX deviation: instead of having a special case for 'index.',
		-- we use 'init.'
		if string.match(fileName, "^init%.") then
			-- deviation: finding matching strings works differently in Lua
			local pathBeforeSlash = string.match(path, BEFORE_SLASH_PATTERN)

			if pathBeforeSlash and #pathBeforeSlash ~= 0 then
				local folderName = string.gsub(pathBeforeSlash, BEFORE_SLASH_PATTERN, "")
				fileName = folderName .. "/" .. fileName
			end
		end

		sourceInfo = " (at " .. fileName .. ":" .. source.lineNumber .. ")"
	elseif ownerName then
		sourceInfo = " (created by " .. ownerName .. ")"
	end

	return "\n    in " .. (name or "Unknown") .. sourceInfo
end

local function describeClassComponentFrame(
	-- ROBLOX deviation: React.Component<any>
	ctor: any,
	source: nil | Source,
	-- ROBLOX deviation: this could be a class component OR a function component
	owner: nil | ReactComponent<any>
): string
	-- ROBLOX deviation START: In Roact, class components are tables, so we
	-- jump directly to using the basic component description.

	-- if enableComponentStackLocations then
	-- 	return describeNativeComponentFrame(componentClass, true)
	-- else
	-- 	return describeFunctionComponentFrame(ctor, source, ownerFn);
	-- end
	local name = tostring(ctor)
	local ownerName = nil
	if _G.__DEV__ and owner then
		ownerName = describeOwner(owner)
	end
	return describeComponentFrame(name, source, ownerName)
	-- ROBLOX deviation END
end

function describeFunctionComponentFrame(
	-- ROBLOX TODO: this annotation is incorrect upstream, we fix it here
	fn: nil | Function,
	source: nil | Source,
	-- ROBLOX deviation: this could be a class component OR a function component
	ownerFn: nil | ReactComponent<any>
): string
	-- ROBLOX DEVIATION Jump directly to using basic component description:
	-- if enableComponentStackLocations then
	-- 	return describeNativeComponentFrame(fn, false)
	-- else
	-- 	if not fn then
	-- 		return ""
	-- 	end
	-- 	-- ROBLOX deviation: use debug.info to discover function names
	-- 	local name = debug.info(fn :: Function, "n")
	-- 	local ownerName = nil
	-- 	if _G.__DEV__ and ownerFn then
	-- 		-- ROBLOX deviation: owner may be a function or a table
	-- 		ownerName = describeOwner(ownerFn)
	-- 	end
	-- 	return describeComponentFrame(name, source, ownerName)
	-- end
	if not fn then
		return ""
	end
	-- ROBLOX deviation: use debug.info to discover function names
	-- ROBLOX FIXME: find out how non-functions are getting into here, they pollute test output
	local name = if type(fn) == "function"
		then debug.info(fn :: Function, "n")
		else tostring(fn)
	local ownerName = nil
	if _G.__DEV__ and ownerFn then
		-- ROBLOX deviation: owner may be a function or a table
		ownerName = describeOwner(ownerFn)
	end
	return describeComponentFrame(name, source, ownerName)
end

-- ROBLOX deviation: because of deviations in other functions, this function is
-- not needed. If we need to bring it, it should return true if Component is a
-- class component, and false if a function component
-- local function shouldConstruct(Component)
-- 	local prototype = Component.prototype
-- 	return not not (prototype and prototype.isReactComponent)
-- end

local function describeUnknownElementTypeFrameInDEV(
	type_: any,
	source: nil | Source,
	-- ROBLOX deviation: owner could be a class component
	ownerFn: nil | ReactComponent<any>
): string
	if not _G.__DEV__ then
		return ""
	end
	if type_ == nil then
		return ""
	end

	-- ROBLOX deviation: in JavaScript, if `type` contains a class, typeof will
	-- return "function". We need to specifically check for the class.
	if type(type_) == "table" and type(type_.__ctor) == "function" then
		-- ROBLOX deviation: since Roact class components are tables, we can't
		-- count on describeClassComponent being a thin wrapper for
		-- describeFunctionComponent like upstream does implicitly
		return describeClassComponentFrame(type_, source, ownerFn)
	end

	if type(type_) == "function" then
		-- ROBLOX DEVIATION: ignore enableComponentStackLocations
		-- if enableComponentStackLocations then
		-- 	-- ROBLOX deviation: since functions and classes have different
		-- 	-- types in Lua, we already know that shouldConstruct would return
		-- 	-- false
		-- 	return describeNativeComponentFrame(type, false)
		-- else
		-- 	return describeFunctionComponentFrame(type, source, ownerFn)
		-- end
		return describeFunctionComponentFrame(type_, source, ownerFn)
	end

	if type(type_) == "string" then
		return describeBuiltInComponentFrame(type_, source, ownerFn)
	end

	if type_ == REACT_SUSPENSE_TYPE then
		return describeBuiltInComponentFrame("Suspense", source, ownerFn)
	elseif type_ == REACT_SUSPENSE_LIST_TYPE then
		return describeBuiltInComponentFrame("SuspenseList", source, ownerFn)
	end

	if type(type_) == "table" then
		local typeProp = type_["$$typeof"]
		if typeProp == REACT_FORWARD_REF_TYPE then
			return describeFunctionComponentFrame(type_.render, source, ownerFn)
		elseif typeProp == REACT_MEMO_TYPE then
			-- // Memo may contain any component type so we recursively resolve it.
			return describeUnknownElementTypeFrameInDEV(type_.type, source, ownerFn)
		elseif typeProp == REACT_BLOCK_TYPE then
			return describeFunctionComponentFrame(type_._render, source, ownerFn)
		elseif typeProp == REACT_LAZY_TYPE then
			local lazyComponent = type_
			local payload = lazyComponent._payload
			local init = lazyComponent._init

			local ok, result = pcall(function()
				describeUnknownElementTypeFrameInDEV(
					-- // Lazy may contain any component type so we recursively resolve it.
					init(payload),
					source,
					ownerFn
				)
			end)

			if ok then
				return result
			end
		end
	end

	return ""
end

return {
	-- deviation: ReactShallowRenderer depends on this, but the upstream `react`
	-- repo doesn't expose it; instead, the shallow-renderer's copies of shared
	-- modules do so. Since we opted to reuse the shared modules in this repo
	-- instead of duplicating, we need to have them include this field
	describeComponentFrame = describeComponentFrame,

	describeBuiltInComponentFrame = describeBuiltInComponentFrame,
	describeNativeComponentFrame = describeNativeComponentFrame,
	describeClassComponentFrame = describeClassComponentFrame,
	describeFunctionComponentFrame = describeFunctionComponentFrame,
	describeUnknownElementTypeFrameInDEV = describeUnknownElementTypeFrameInDEV,
}
