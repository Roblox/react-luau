--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/bc6b7b6b16f771bfc8048fe15e211ac777253b64/packages/react/src/ReactElementValidator.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
type Array<T> = LuauPolyfill.Array<T>
local Boolean = LuauPolyfill.Boolean
local Object = LuauPolyfill.Object
type Object = LuauPolyfill.Object
local console = require(Packages.Shared).console
local inspect = LuauPolyfill.util.inspect
type Function = (...any) -> ...any

-- ROBLOX deviation START: import extra types
local ReactTypes = require(Packages.Shared)
type React_StatelessFunctionalComponent<P> = ReactTypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_Element<ElementType> = ReactTypes.React_Element<ElementType>
type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
type ReactElement<P, T> = ReactTypes.ReactElement<P, T>
type React_Node = ReactTypes.React_Node
type Source = ReactTypes.Source
-- ROBLOX deviation END

local isValidElementType = require(Packages.Shared).isValidElementType
local getComponentName = require(Packages.Shared).getComponentName
local ReactSymbols = require(Packages.Shared).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local _REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local _REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE

local warnAboutSpreadingKeyToJSX =
	require(Packages.Shared).ReactFeatureFlags.warnAboutSpreadingKeyToJSX
local checkPropTypes = require(Packages.Shared).checkPropTypes
local ReactCurrentOwner = require(Packages.Shared).ReactSharedInternals.ReactCurrentOwner

local ReactElement = require(script.Parent.ReactElement)
local isValidElement = ReactElement.isValidElement
local createElement = ReactElement.createElement
local cloneElement = ReactElement.cloneElement
local jsxDEV = ReactElement.jsxDEV

local setExtraStackFrame =
	require(Packages.Shared).ReactSharedInternals.ReactDebugCurrentFrame.setExtraStackFrame
local describeUnknownElementTypeFrameInDEV =
	require(Packages.Shared).ReactComponentStackFrame.describeUnknownElementTypeFrameInDEV

local exports = {}

-- ROBLOX FIXME Luau: annotation shouldn't be necessary
local function setCurrentlyValidatingElement(element: ReactElement<any, any> | nil)
	if _G.__DEV__ then
		if element then
			local owner = element._owner
			local ownerArgument = nil
			if owner then
				ownerArgument = owner.type
			end
			local stack = describeUnknownElementTypeFrameInDEV(
				element.type,
				element._source,
				ownerArgument
			);
			-- ROBLOX FIXME Luau: needs normalization: Cannot call non-function (() -> ()) | ((string?) -> (...any))
			(setExtraStackFrame :: (...any) -> ())(stack)
		else
			-- ROBLOX FIXME Luau: needs normalization: Cannot call non-function (() -> ()) | ((string?) -> (...any))
			(setExtraStackFrame :: (...any) -> ())(nil)
		end
	end
end

local propTypesMisspellWarningShown

if _G.__DEV__ then
	propTypesMisspellWarningShown = false
end

local function hasOwnProperty(object, key)
	return object[key] ~= nil
end

local function getDeclarationErrorAddendum(): string
	if ReactCurrentOwner.current then
		local name = getComponentName(ReactCurrentOwner.current.type)
		if name then
			return "\n\nCheck the render method of `" .. name .. "`."
		end
	end
	return ""
end

-- ROBLOX FIXME Luau: annotation shouldn't be necessary
local function getSourceInfoErrorAddendum(source: Source | nil): string
	if source ~= nil then
		local fileName = string.gsub(source.fileName, "^.*[\\/]", "")
		local lineNumber = source.lineNumber
		return "\n\nCheck your code at " .. fileName .. ":" .. lineNumber .. "."
	end
	return ""
end

-- ROBLOX FIXME Luau: needs explicit annotation, even though call site and nil check should be enough
local function getSourceInfoErrorAddendumForProps(
	elementProps: React_ElementProps<any>?
): string
	if elementProps ~= nil then
		return getSourceInfoErrorAddendum(elementProps.__source)
	end
	return ""
end

-- /**
--  * Warn if there's no key explicitly set on dynamic arrays of children or
--  * object keys are not valid. This allows us to keep track of children between
--  * updates.
--  */
local ownerHasKeyUseWarning = {}

-- ROBLOX FIXME Luau: shouldn't need this annotation on parentType
local function getCurrentComponentErrorInfo(
	parentType: React_ComponentType<any> | string | Function
): string
	local info = getDeclarationErrorAddendum()

	if not Boolean.toJSBoolean(info) then
		local parentName = if typeof(parentType) == "string"
			then parentType
			else if typeof(parentType) == "table"
				then parentType.displayName or parentType.name
				else nil

		-- ROBLOX deviation: Lua doesn't store fields on functions, so try and get the name via reflection
		if not parentName and typeof(parentType) == "function" then
			local functionName = debug.info(parentType, "n")
			-- ROBLOX note: unlike other places, upstream doesn't default the component name string in this message
			parentName = if functionName ~= "" then functionName else nil
		end

		if parentName then
			info = string.format(
				"\n\nCheck the top-level render call using <%s>.",
				parentName
			)
		end
	end
	return info
end

-- /**
--  * Warn if the element doesn't have an explicit key assigned to it.
--  * This element is in an array. The array could grow and shrink or be
--  * reordered. All children that haven't already been validated are required to
--  * have a "key" property assigned to it. Error statuses are cached so a warning
--  * will only be shown once.
--  *
--  * @internal
--  * @param {ReactElement} element Element that requires a key.
--  * @param {*} parentType element's parent's type.
--  * @param {*} tableKey ROBLOX deviation: key provided by the children table
--  */
-- ROBLOX deviation START: add explicit optional table key parameter, move key check to after we mark it validated, since we may not have an explicit key (and will use tableKey to validate)
local function validateExplicitKey<P>(
	element: ReactElement<P, any>,
	parentType,
	tableKey: any?
)
	if element._store == nil or element._store.validated then
		return
	end
	-- ROBLOX FIXME Luau: doesn't narrow based on branch above
	(element._store :: any).validated = true
	-- ROBLOX note: Consider this element valid if only _one_ key is
	-- present, otherwise proceed and check for error states
	if (element.key ~= nil) ~= (tableKey ~= nil) then
		return
	end
	-- ROBLOX deviation END
	local currentComponentErrorInfo = getCurrentComponentErrorInfo(parentType)
	if ownerHasKeyUseWarning[currentComponentErrorInfo] then
		return
	end
	ownerHasKeyUseWarning[currentComponentErrorInfo] = true

	-- // Usually the current owner is the offender, but if it accepts children as a
	-- // property, it may be the creator of the child that's responsible for
	-- // assigning it a key.
	local childOwner = ""
	if element and element._owner and element._owner ~= ReactCurrentOwner.current then
		-- // Give the component that originally created this child.
		childOwner = string.format(
			" It was passed a child from %s.",
			tostring(getComponentName(element._owner.type))
		)
	end

	if _G.__DEV__ then
		setCurrentlyValidatingElement(element)
		-- ROBLOX deviation START: Account for conflict between "key" prop and deviated table key behavior (in addition to missing key warnings)
		-- Both forms of key were provided
		if element.key ~= nil and tableKey ~= nil then
			-- ROBLOX TODO: Link to special Roact documentation that accounts
			-- for deviation instead of react docs
			console.error(
				'Child element received a "key" prop ("%s") in addition to a key in '
					.. 'the "children" table of its parent ("%s"). Please provide only '
					.. 'one key definition. When both are present, the "key" prop '
					.. "will take precedence."
					.. "%s%s See https://reactjs.org/link/warning-keys for more information.",
				tostring(element.key),
				tostring(tableKey),
				currentComponentErrorInfo,
				childOwner
			)
		-- No key was provided at all
		else
			console.error(
				'Each child in a list should have a unique "key" prop.'
					.. "%s%s See https://reactjs.org/link/warning-keys for more information.",
				currentComponentErrorInfo,
				childOwner
			)
		end
		-- ROBLOX deviation END
		setCurrentlyValidatingElement(nil)
	end
end

-- /**
--  * Ensure that every element either is passed in a static location, in an
--  * array with an explicit keys property defined, or in an object literal
--  * with valid key property.
--  *
--  * @internal
--  * @param {ReactNode} node Statically passed child of any type.
--  * @param {*} parentType node's parent's type.
--  */
local function validateChildKeys(node, parentType)
	if typeof(node) ~= "table" then
		return
	end

	if Array.isArray(node) then
		for i = 1, #node do
			local child = node[i]
			if isValidElement(child) then
				validateExplicitKey(child :: ReactElement<any, any>, parentType)
			end
		end
	elseif isValidElement(node) then
		-- // This element was passed in a valid location.
		if node._store then
			node._store.validated = true
		end
	elseif node then
		local iteratorFn = getIteratorFn(node)
		if typeof(iteratorFn) == "function" then
			-- // Entry iterators used to provide implicit keys,
			-- // but now we print a separate warning for them later.
			if iteratorFn ~= node.entries then
				local iterator = iteratorFn(node)
				local step = iterator.next()
				while not step.done do
					if isValidElement(step.value) then
						validateExplicitKey(step.value, parentType, step.key)
					end

					step = iterator.next()
				end
			end
		end
	end
end

-- /**
--  * Given an element, validate that its props follow the propTypes definition,
--  * provided by the type.
--  *
--  * @param {ReactElement} element
--  */
local function validatePropTypes<P>(element: ReactElement<P, any>)
	if _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ then
		local type = element.type
		if type == nil or typeof(type) == "string" then
			return
		end

		local propTypes
		local validateProps
		if typeof(type) == "function" then
			-- deviation: function components can't have propTypes in Lua
			-- propTypes = type.propTypes
			return
		elseif typeof(type) == "table" then
			propTypes = type.propTypes
			validateProps = type.validateProps
		else
			return
		end

		if propTypes or validateProps then
			-- Intentionally inside to avoid triggering lazy initializers:
			local name = getComponentName(type)
			-- ROBLOX deviation: adds support for legacy Roact's validateProps()
			checkPropTypes(propTypes, validateProps, element.props, "prop", name, element)
			-- ROBLOX TODO: upstream this any, PropTypes is a bogus key check on purpose
		elseif (type :: any).PropTypes ~= nil and not propTypesMisspellWarningShown then
			propTypesMisspellWarningShown = true
			-- Intentionally inside to avoid triggering lazy initializers:
			local name = getComponentName(type)
			console.error(
				"Component %s declared `PropTypes` instead of `propTypes`. Did you misspell the property assignment?",
				name or "Unknown"
			)
		end
		-- ROBLOX TODO: upstream this any, PropTypes is a bogus key check on purpose
		-- ROBLOX deviation: we simplify this check since we never supported this in the first place
		if (type :: any).getDefaultProps ~= nil then
			console.error(
				"getDefaultProps is only used on classic React.createClass "
					.. "definitions. Use a static property named `defaultProps` instead."
			)
		end
	end
end

-- /**
--  * Given a fragment, validate that it can only be provided with fragment props
--  * @param {ReactElement} fragment
--  */
local function validateFragmentProps<P>(fragment: ReactElement<P & Object, any>)
	if _G.__DEV__ then
		local keys = Object.keys(fragment.props)
		for i = 1, #keys do
			local key = keys[i]
			if key ~= "children" and key ~= "key" then
				setCurrentlyValidatingElement(fragment)
				console.error(
					"Invalid prop `%s` supplied to `React.Fragment`. "
						.. "React.Fragment can only have `key` and `children` props.",
					key
				)
				setCurrentlyValidatingElement(nil)
				break
			end
		end

		if fragment.ref ~= nil then
			setCurrentlyValidatingElement(fragment)
			console.error("Invalid attribute `ref` supplied to `React.Fragment`.")
			setCurrentlyValidatingElement(nil)
		end
	end
end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
local function jsxWithValidation<P, T>(
	type: T,
	props: P & React_ElementProps<T>,
	key: string | number,
	isStaticChildren,
	source: Source?,
	self: any?
)
	-- ROBLOX deviation END
	local validType = isValidElementType(type)

	-- // We warn in this case but don't throw. We expect the element creation to
	-- // succeed and there will likely be errors in render.
	if not validType then
		local info = ""
		if type == nil or (typeof(type) == "table" and #Object.keys(type) == 0) then
			info ..= (" You likely forgot to export your component from the file " .. "it's defined in, or you might have mixed up default and named imports.")
		end

		local sourceInfo = getSourceInfoErrorAddendum(source)
		if sourceInfo then
			info ..= sourceInfo
		else
			info ..= getDeclarationErrorAddendum()
		end

		local typeString
		if type == nil then
			typeString = "nil"
		elseif Array.isArray(type) then
			typeString = "array"
		elseif typeof(type) == "table" and type["$$typeof"] == REACT_ELEMENT_TYPE then
			typeString = string.format("<%s />", getComponentName(type.type) or "Unknown")
			info ..= " Did you accidentally export a JSX literal or Element instead of a component?"
		else
			typeString = typeof(type)
			info ..= "\n" .. inspect(type)
		end

		if _G.__DEV__ then
			console.error(
				"React.jsx: type is invalid -- expected a string (for "
					.. "built-in components) or a class/function (for composite "
					.. "components) but got: %s.%s",
				typeString,
				info
			)
		end
	end

	local element = jsxDEV(type, props, key, source, self)

	-- // The result can be nullish if a mock or a custom function is used.
	-- // TODO: Drop this when these are no longer allowed as the type argument.
	if element == nil then
		return element
	end

	-- // Skip key warning if the type isn't valid since our key validation logic
	-- // doesn't expect a non-string/function type and can throw confusing errors.
	-- // We don't want exception behavior to differ between dev and prod.
	-- // (Rendering will throw with a helpful message and as soon as the type is
	-- // fixed, the key warnings will appear.)

	if validType then
		local children = props.children
		if children ~= nil then
			if isStaticChildren then
				if Array.isArray(children) then
					for i = 1, #children do
						-- ROBLOX FIXME Luau: needs normalization
						validateChildKeys(children[i], type :: any)
					end

					-- deviation: Object.freeze always exist
					-- if Object.freeze then
					Object.freeze(children)
					-- end
				else
					if _G.__DEV__ then
						console.error(
							"React.jsx: Static children should always be an array. "
								.. "You are likely explicitly calling React.jsxs or React.jsxDEV. "
								.. "Use the Babel transform instead."
						)
					end
				end
			else
				-- ROBLOX FIXME Luau: needs normalization
				validateChildKeys(children, type :: any)
			end
		end
	end

	if _G.__DEV__ then
		if warnAboutSpreadingKeyToJSX then
			if hasOwnProperty(props, "key") then
				console.error(
					"React.jsx: Spreading a key to JSX is a deprecated pattern. "
						.. "Explicitly pass a key after spreading props in your JSX call. "
						.. "E.g. <%s {...props} key={key} />",
					getComponentName(type) or "ComponentName"
				)
			end
		end
	end

	if type == REACT_FRAGMENT_TYPE then
		-- ROBLOX FIXME Luau: luau doesn't understand narrowing of above branch
		validateFragmentProps((element :: any) :: ReactElement<any, any>)
	else
		validatePropTypes((element :: any) :: ReactElement<any, any>)
	end

	return element
end
exports.jsxWithValidation = jsxWithValidation

-- // These two functions exist to still get child warnings in dev
-- // even with the prod transform. This means that jsxDEV is purely
-- // opt-in behavior for better messages but that we won't stop
-- // giving you warnings if you use production apis.
exports.jsxWithValidationStatic = function(type, props, key)
	return jsxWithValidation(type, props, key, true)
end

exports.jsxWithValidationDynamic = function(type, props, key)
	return jsxWithValidation(type, props, key, false)
end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
local function createElementWithValidation<P, T>(
	type_: React_StatelessFunctionalComponent<
		P
	> | React_ComponentType<P> | string,
	props: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation END
	local validType = isValidElementType(type_)

	-- // We warn in this case but don't throw. We expect the element creation to
	-- // succeed and there will likely be errors in render.
	if not validType then
		local info = ""
		if type_ == nil or (typeof(type_) == "table" and #Object.keys(type_) == 0) then
			info ..= (" You likely forgot to export your component from the file " .. "it's defined in, or you might have mixed up default and named imports.")
		end

		local sourceInfo = getSourceInfoErrorAddendumForProps(props)
		if sourceInfo then
			info ..= sourceInfo
		else
			info ..= getDeclarationErrorAddendum()
		end

		local typeString
		if type_ == nil then
			typeString = "nil"
		elseif Array.isArray(type_) then
			typeString = "array"
		elseif
			type_ ~= nil
			and typeof(type_) == "table"
			and type_["$$typeof"] == REACT_ELEMENT_TYPE
		then
			typeString = string.format(
				"<%s />",
				getComponentName((type_ :: any).type) or "Unknown"
			)
			info ..= " Did you accidentally export a JSX literal or Element instead of a component?"
		else
			typeString = typeof(type_)
			if type_ ~= nil then
				-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
				info ..= "\n" .. inspect(type_)
			end
		end

		if _G.__DEV__ then
			console.error(
				"React.createElement: type is invalid -- expected a string (for "
					.. "built-in components) or a class/function (for composite "
					.. "components) but got: %s.%s",
				typeString,
				info
			)
		end
	end

	-- ROBLOX FIXME Luau: hard cast to any, needs normalization to avoid 'React_ComponentType<P>' could not be converted into 'React_ComponentType<P>'
	local element = createElement(type_ :: any, props, ...)

	-- // The result can be nullish if a mock or a custom function is used.
	-- // TODO: Drop this when these are no longer allowed as the type argument.
	if element == nil then
		return element
	end

	-- // Skip key warning if the type isn't valid since our key validation logic
	-- // doesn't expect a non-string/function type and can throw confusing errors.
	-- // We don't want exception behavior to differ between dev and prod.
	-- // (Rendering will throw with a helpful message and as soon as the type is
	-- // fixed, the key warnings will appear.)
	if validType then
		-- ROBLOX deviation: skips (1) type and (2) props - starts from 3 to the end varargs (iterate through children)
		for i = 1, select("#", ...) do
			-- ROBLOX deviation: selects the ith child from this function's arguments to validate
			-- ROBLOX FIXME Luau: hard cast to any, needs normalization to avoid 'React_ComponentType<P>' could not be converted into 'React_ComponentType<P>'
			validateChildKeys(select(i, ...), type_ :: any)
		end
	end

	if type_ == REACT_FRAGMENT_TYPE then
		validateFragmentProps(element)
	else
		validatePropTypes(element)
	end

	return element
end
exports.createElementWithValidation = createElementWithValidation

-- devitation: createFactory is deprecated and will be removed
-- local didWarnAboutDeprecatedCreateFactory = false

-- exports.createFactoryWithValidation = function(type)
-- 	local validatedFactory = function(...)
-- 		createElementWithValidation(type, ...)
-- 	end
-- 	-- deviation: Lua can't assign fields to functions. The 'type'
-- 	-- property is deprecated so there is no need to port this over.
-- 	-- validatedFactory.type = type

-- 	if _G.__DEV__ then
-- 		if not didWarnAboutDeprecatedCreateFactory then
-- 			didWarnAboutDeprecatedCreateFactory = true
-- 			console.warn(
-- 				"React.createFactory() is deprecated and will be removed in " ..
-- 					"a future major release. Consider using JSX " ..
-- 					"or use React.createElement() directly instead."
-- 			)
-- 		end
-- 		-- // Legacy hook: remove it
-- 		-- deviation: no porting this behavior because it is deprecated
-- 		-- Object.defineProperty(validatedFactory, "type", {
-- 		-- 	enumerable = false,
-- 		-- 	get = function()
-- 		-- 		console.warn(
-- 		-- 			"Factory.type is deprecated. Access the class directly " ..
-- 		-- 				"before passing it to createFactory."
-- 		-- 		)
-- 		-- 		Object.defineProperty(this, "type", {
-- 		-- 			value = type,
-- 		-- 		})
-- 		-- 		return type
-- 		-- 	end,
-- 		-- })
-- 	end

-- 	return validatedFactory
-- end

-- ROBLOX deviation START: add strong types based on definitely-typed approach on createElement
exports.cloneElementWithValidation = function<P, T>(
	element: ReactElement<P, T>,
	props: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation END
	local arguments = { element, props, ... } :: Array<any>
	local newElement = cloneElement(element, props, ...)
	for i = 3, #arguments do
		validateChildKeys(arguments[i], newElement.type)
	end
	validatePropTypes(newElement)
	return newElement
end

return exports
