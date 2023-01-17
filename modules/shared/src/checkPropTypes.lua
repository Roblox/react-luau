--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/55cb0b7eeb0e539d89858b8ed69beabf7fe2fb46/packages/shared/checkPropTypes.js
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
local Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object
type Function = (...any) -> ...any

-- ROBLOX: use patched console from shared
local console = require(script.Parent.console)

local loggedTypeFailures = {}

local ReactComponentStackFrame = require(script.Parent.ReactComponentStackFrame)
local describeUnknownElementTypeFrameInDEV =
	ReactComponentStackFrame.describeUnknownElementTypeFrameInDEV

local ReactSharedInternals = require(script.Parent.ReactSharedInternals)

local describeError = require(script.Parent["ErrorHandling.roblox"]).describeError

local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

-- ROBLOX FIXME Luau: doesn't see `if element` as nilable table, so we get TypeError: Type 'any?' could not be converted into '{| _owner: {| type: nil |}, _source: Source?, type: any |}'
local function setCurrentlyValidatingElement(element: any?)
	if _G.__DEV__ then
		if element then
			local owner = element._owner
			local stack = describeUnknownElementTypeFrameInDEV(
				element.type,
				element._source,
				if owner ~= nil then owner.type else nil
			);
			-- ROBLOX FIXME Luau: Cannot call non-function ((string?) -> ()) | ((string?) -> ())
			(ReactDebugCurrentFrame.setExtraStackFrame :: any)(stack)
		else
			(ReactDebugCurrentFrame.setExtraStackFrame :: any)(nil)
		end
	end
end

local function checkPropTypes<P>(
	-- ROBLOX deviation START: also checks validateProps if present
	propTypes: Object?,
	validateProps: (P) -> (boolean, string?)?,
	props: P,
	-- ROBLOX deviation END
	location: string,
	componentName: string?,
	element: any?
): ()
	if _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		-- deviation: hasOwnProperty shouldn't be relevant to lua objects
		-- $FlowFixMe This is okay but Flow doesn't know it.
		-- local has = Function.call.bind(Object.prototype.hasOwnProperty)

		-- ROBLOX deviation: warns if both propType and validateProps defined.
		if propTypes and validateProps then
			console.warn(
				"You've defined both propTypes and validateProps on "
					.. (componentName or "a component")
			)
		end

		-- ROBLOX deviation: also checks validateProps if present
		if validateProps then
			if typeof(validateProps) ~= "function" then
				console.error(
					("validateProps must be a function, but it is a %s.\nCheck the definition of the component %q."):format(
						typeof(validateProps),
						componentName or ""
					)
				)
			else
				local success, failureReason = validateProps(props)

				if not success then
					failureReason = failureReason
						or "<Validator function did not supply a message>"
					local message = string.format(
						"validateProps failed on a %s type in %s: %s",
						location,
						componentName or "<UNKNOWN Component>",
						tostring(failureReason)
					)
					-- ROBLOX deviation: In legacy Roact, prop validation
					-- failures throw. We replicate that behavior, even though
					-- it differs from propTypes (which only warns)
					-- ROBLOX FIXME: align with upstream behavior during React 18 Lua transition
					error(message)
				end
			end
		end

		if propTypes then
			-- ROBLOX deviation: since we can't constrain the generic, we assert so Luau knows propTypes is a table
			assert(typeof(propTypes) == "table", "propTypes needs to be a table")
			for typeSpecName, _ in propTypes do
				-- deviation: since our loop won't hit metatable members, we don't
				-- need to worry about encountering inherited properties here
				-- if has(propTypes, typeSpecName) then

				-- Prop type validation may throw. In case they do, we don't want to
				-- fail the render phase where it didn't fail before. So we log it.
				-- After these have been cleaned up, we'll local them throw.
				local _, result = xpcall(function()
					-- This is intentionally an invariant that gets caught. It's the same
					-- behavior as without this statement except with a better message.
					if typeof(propTypes[typeSpecName]) ~= "function" then
						local err = Error.new(
							(componentName or "React class")
								.. ": "
								.. location
								.. " type `"
								.. typeSpecName
								.. "` is invalid; "
								.. "it must be a function, usually from the `prop-types` package, but received `"
								.. typeof(propTypes[typeSpecName])
								.. "`."
								.. "This often happens because of typos such as `PropTypes.function` instead of `PropTypes.func`."
						)
						err.name = "Invariant Violation"
						error(err)
					end

					return (propTypes[typeSpecName] :: Function)(
						props,
						typeSpecName,
						componentName,
						location,
						nil,
						"SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED"
					)
				end, describeError)

				-- ROBLOX deviation: FIXME: Can we expose something from JSPolyfill that
				-- will let us verify that this is specifically the Error object
				-- defined there? if we check for result.message ~= nil, ReactNewContext.spec:1368 fails
				local isErrorObject = typeof(result) == "table"
				if result ~= nil and not isErrorObject then
					setCurrentlyValidatingElement(element)
					console.error(string.format(
						-- ROBLOX deviation: s/null/nil
						"%s: type specification of %s"
							.. " `%s` is invalid; the type checker "
							.. "function must return `nil` or an `Error` but returned a %s. "
							.. "You may have forgotten to pass an argument to the type checker "
							.. "creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and "
							.. "shape all require an argument).",
						componentName or "React class",
						location,
						typeSpecName,
						typeof(result)
					))
					setCurrentlyValidatingElement(nil)
				end

				-- ROBLOX FIXME: Luau analyze doesn't understand isErrorObject's effect as a predicate meaning result ~= nil
				if
					isErrorObject
					and loggedTypeFailures[(result :: any).message] == nil
				then
					-- Only monitor this failure once because there tends to be a lot of the
					-- same error.
					loggedTypeFailures[tostring((result :: any).message)] = true
					setCurrentlyValidatingElement(element)
					console.warn(
						string.format(
							"Failed %s type: %s",
							location,
							tostring((result :: any).message)
						)
					)
					setCurrentlyValidatingElement(nil)
				end
			end
		end
	end
end

return checkPropTypes
