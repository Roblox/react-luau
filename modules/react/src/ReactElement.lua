--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react/src/ReactElement.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
local __DEV__ = _G.__DEV__ :: boolean
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local ReactTypes = require(Packages.Shared)
type React_StatelessFunctionalComponent<P> = ReactTypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_AbstractComponent<P, T> = ReactTypes.React_AbstractComponent<P, T>
type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
type React_Node = ReactTypes.React_Node
type ReactElement<P = Object, T = any> = ReactTypes.ReactElement<P, T>
type ReactContext<T> = ReactTypes.ReactContext<T>
type Source = ReactTypes.Source

local ReactLazy = require(script.Parent.ReactLazy)
type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

local getComponentName = require(Packages.Shared).getComponentName
-- ROBLOX deviation START: we eliminate invariant like in React 18 to avoid string formatting and function call overhead
-- local invariant = require(Packages.Shared).invariant
-- ROBLOX deviation END
local REACT_ELEMENT_TYPE = require(Packages.Shared).ReactSymbols.REACT_ELEMENT_TYPE
local ReactCurrentOwner = require(Packages.Shared).ReactSharedInternals.ReactCurrentOwner
--local hasOwnProperty = Object.prototype.hasOwnProperty
-- ROBLOX deviation START: upstream iterates over this table, but we manually unroll those loops for hot path performance
-- IF THIS TABLE UPDATES, YOU MUST UPDATE THE UNROLLED LOOPS AS WELL
local RESERVED_PROPS = {
	key = true,
	ref = true,
	__self = true,
	__source = true,
}
-- ROBLOX deviation END

local specialPropKeyWarningShown, specialPropRefWarningShown, didWarnAboutStringRefs

if __DEV__ then
	didWarnAboutStringRefs = {}
end

local exports = {}

local function hasValidRef(config)
	if __DEV__ then
		-- ROBLOX DEVIATION: instead of getters, use `__index` metamethod to
		-- detect if it's a warning object
		if config.ref ~= nil and type(config.ref) == "table" then
			if (config.ref :: any).isReactWarning then
				return false
			end
		end
	end

	return config.ref ~= nil
end

local function hasValidKey(config)
	if __DEV__ then
		-- ROBLOX DEVIATION: instead of getters, use `__index` metamethod to
		-- detect if it's a warning object
		if config.key ~= nil and type(config.key) == "table" then
			if (config.key :: any).isReactWarning then
				return false
			end
		end
	end

	return config.key ~= nil
end

local reactWarning = { isReactWarning = true }

-- ROBLOX FIXME: These two warning 'getter' definitions both override the
-- metatable, and won't both work at the same time. The easy solution is to
-- define one metatable that does both instead of overwriting
local function defineKeyPropWarningGetter(props, displayName: string)
	local warnAboutAccessingKey = function()
		if __DEV__ then
			if not specialPropKeyWarningShown then
				specialPropKeyWarningShown = true
				console.error(
					"%s: `key` is not a prop. Trying to access it will result "
						.. "in `nil` being returned. If you need to access the same "
						.. "value within the child component, you should pass it as a different "
						.. "prop. (https://reactjs.org/link/special-props)",
					displayName
				)
			end
		end
	end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.key = nil
	setmetatable(props, {
		__index = function(t, k)
			if k == "key" then
				warnAboutAccessingKey()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			-- ROBLOX FIXME Luau: needs deferred constraint resolution
			return nil :: any
		end,
	})
end

local function defineRefPropWarningGetter(props, displayName: string)
	-- deviation: Use a __call metamethod here to make this function-like, but
	-- still able to have the `isReactWarning` flag defined on it
	local warnAboutAccessingRef = function()
		if __DEV__ then
			if not specialPropRefWarningShown then
				specialPropRefWarningShown = true
				console.error(
					"%s: `ref` is not a prop. Trying to access it will result "
						.. "in `nil` being returned. If you need to access the same "
						.. "value within the child component, you should pass it as a different "
						.. "prop. (https://reactjs.org/link/special-props)",
					displayName
				)
			end
		end
	end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.ref = nil
	setmetatable(props :: any, {
		__index = function(t, k)
			if k == "ref" then
				warnAboutAccessingRef()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			-- ROBLOX FIXME Luau: needs deferred constraint resolution
			return nil :: any
		end,
	})
end

local function warnIfStringRefCannotBeAutoConverted(config)
	if __DEV__ then
		if
			-- ROBLOX deviation: We removed support for string refs, so all stringrefs cannot be auto-converted regardless
			type(config.ref) == "string" and ReactCurrentOwner.current
			-- and config.__self
			-- and ReactCurrentOwner.current.stateNode ~= config.__self
		then
			local componentName = getComponentName(ReactCurrentOwner.current.type)

			-- ROBLOX deviation: we don't support string refs and hard error instead of warn
			if not didWarnAboutStringRefs[componentName] then
				error(
					string.format(
						'Component "%s" contains the string ref "%s". '
							.. "Support for string refs has been removed. "
							.. "We recommend using useRef() or createRef() instead. "
							.. "Learn more about using refs safely here: "
							.. "https://reactjs.org/link/strict-mode-string-ref",
						componentName or "Unknown",
						config.ref
					)
				)
				-- didWarnAboutStringRefs[componentName] = true
			end
		end
	end
end

--[[*
 * Factory method to create a new React element. This no longer adheres to
 * the class pattern, so do not use new to call it. Also, instanceof check
 * will not work. Instead test $$typeof field against Symbol.for('react.element') to check
 * if something is a React Element.
 *
 * @param *} type
 * @param *} props
 * @param *} key
 * @param string|object} ref
 * @param *} owner
 * @param *} self A *temporary* helper to detect places where `this` is
 * different from the `owner` when React.createElement is called, so that we
 * can warn. We want to get rid of owner and replace string `ref`s with arrow
 * functions, and as long as `this` and owner are the same, there will be no
 * change in behavior.
 * @param *} source An annotation object (added by a transpiler or otherwise)
 * indicating filename, line number, and/or other information.
 * @internal
 ]]

-- ROBLOX deviation BEGIN: extra annotations here inspired by TS and flowtype to facilitate prop checking at analyze-time
local function ReactElement<P, T>(
	type_: T,
	key,
	ref,
	self,
	source: Source?,
	owner,
	props: P
): ReactElement<P, T>
	-- ROBLOX deviation END
	local element = {
		-- Built-in properties that belong on the element
		type = type_,
		key = key,
		ref = ref,
		props = props,
		-- Record the component responsible for creating this element.
		_owner = owner,
	}

	-- This tag allows us to uniquely identify this as a React Element
	element["$$typeof"] = REACT_ELEMENT_TYPE

	if __DEV__ then
		-- The validation flag is currently mutative. We put it on
		-- an external backing store so that we can freeze the whole object.
		-- This can be replaced with a WeakMap once they are implemented in
		-- commonly used development environments.
		local nonEnumerable = {
			validated = false,
		}
		element._store = setmetatable({}, {
			-- To make comparing ReactElements easier for testing purposes, we
			-- make the validation flag non-enumerable (where possible, which
			-- should include every environment we run tests in), so the test
			-- framework ignores it.
			__index = nonEnumerable,
			__newindex = function(table, key, value)
				if key == "validated" then
					nonEnumerable.validated = value
				else
					rawset(table, key, value)
				end
			end,
		})
		-- self and source are DEV only properties.
		setmetatable(element, {
			__index = {
				_self = self,
				-- Two elements created in two different places should be considered
				-- equal for testing purposes and therefore we hide it from enumeration.
				_source = source,
			},
		})
	end

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return element :: any
end

----[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
--
exports.jsx = function(type, config, maybeKey)
	-- ROBLOX deviation START: skipping JSX for now, as it may never apply to Roblox
	error("JSX is currently unsupported")
	--  local propName; -- Reserved names are extracted
	--
	--  local props = }
	--  local key = nil
	--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
	--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
	--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
	--  -- but as an intermediary step, we will use jsxDEV for everything except
	--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
	--  -- key is explicitly declared to be nil or not.
	--
	--  if maybeKey ~= nil)
	--    key = '' .. maybeKey
	--  end
	--
	--  if hasValidKey(config))
	--    key = '' .. config.key
	--  end
	--
	--  if hasValidRef(config))
	--    ref = config.ref
	--  } -- Remaining properties are added to a new props object
	--
	--
	--  for (propName in config)
	--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
	--      props[propName] = config[propName]
	--    end
	--  } -- Resolve default props
	--
	--
	--  if type and type.defaultProps)
	--    local defaultProps = type.defaultProps
	--
	--    for (propName in defaultProps)
	--      if props[propName] == nil)
	--        props[propName] = defaultProps[propName]
	--      end
	--    end
	-- end
	--
	--  return ReactElement(type, key, ref, nil, nil, ReactCurrentOwner.current, props)
	-- ROBLOX deviation END
end

--[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
exports.jsxDEV = function(type, config, maybeKey, source, self)
	-- ROBLOX deviation START: we may never support JSX
	error("JSX is currently unsupported")
	--  local propName; -- Reserved names are extracted
	--
	--  local props = }
	--  local key = nil
	--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
	--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
	--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
	--  -- but as an intermediary step, we will use jsxDEV for everything except
	--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
	--  -- key is explicitly declared to be nil or not.
	--
	--  if maybeKey ~= nil)
	--    key = '' .. maybeKey
	--  end
	--
	--  if hasValidKey(config))
	--    key = '' .. config.key
	--  end
	--
	--  if hasValidRef(config))
	--    ref = config.ref
	--    warnIfStringRefCannotBeAutoConverted(config)
	--  } -- Remaining properties are added to a new props object
	--
	--
	--  for (propName in config)
	--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
	--      props[propName] = config[propName]
	--    end
	--  } -- Resolve default props
	--
	--
	--  if type and type.defaultProps)
	--    local defaultProps = type.defaultProps
	--
	--    for (propName in defaultProps)
	--      if props[propName] == nil)
	--        props[propName] = defaultProps[propName]
	--      end
	--    end
	--  end
	--
	--  if key or ref)
	--    local displayName = function ()
	--      if typeof type == 'function')
	--        return type.displayName or type.name or 'Unknown'
	--      end
	--
	--      return type
	--    }()
	--
	--    if key)
	--      defineKeyPropWarningGetter(props, displayName)
	--    end
	--
	--    if ref)
	--      defineRefPropWarningGetter(props, displayName)
	--    end
	--
	--  return ReactElement(type, key, ref, self, source, ReactCurrentOwner.current, props)
	return nil
	-- ROBLOX deviation END
end

--[[*
 * Create and return a new ReactElement of the given type.
 * See https://reactjs.org/docs/react-api.html#createelement
 ]]
-- ROBLOX deviation: this is TypeScript-derived annotation, but using flowtypes
--  function createElement<P extends {}>(
-- 	type: FunctionComponent<P> | ComponentClass<P> | string,
-- 	props?: Attributes & P | null,
-- 	...children: ReactNode[]): ReactElement<P>;
local function createElement<P, T>(
	type_: React_StatelessFunctionalComponent<P> | React_ComponentType<P> | React_AbstractComponent<P, T> | ReactContext<any> | LazyComponent<T, P> | ReactProviderType<any> | string,
	config: P?,
	...: React_Node | (...any) -> React_Node
): ReactElement<P, T>
	-- ROBLOX deviation START: extreme hot path, so manually unroll RESERVED_PROPS loop and use table.clone
	local props = if config ~= nil then table.clone(config :: any) :: any else {}
	-- ROBLOX deviation END
	local key: (string | number)? = nil
	local ref = nil
	local self = nil
	local source: Source? = nil

	if config ~= nil then
		-- ROBLOX deviation START: inline hasValidRef and hasValidKey success in hot path, still call in error case for warning
		-- ROBLOX FIXME Luau: needs normalization: Type 'P & React_ElementProps<T>' could not be converted into 'React_ElementProps<T>'; none of the intersection parts are compatible
		if hasValidRef(config :: any) then
			ref = ((config :: any) :: React_ElementProps<T>).ref

			if __DEV__ then
				warnIfStringRefCannotBeAutoConverted(
					(config :: any) :: React_ElementProps<T>
				)
			end
		end

		-- ROBLOX FIXME Luau: when configKey is inline: Type 'P & React_ElementProps<T>' could not be converted into 'React_ElementProps<T>'; none of the intersection parts are compatible
		if hasValidKey(config :: any) then
			local configKey = (config :: any).key
			-- ROBLOX deviation: call tostring instead of concatenating with an
			-- empty string, which can throw in luau. If the string is a number,
			-- then do not use tostring
			if type(configKey) == "number" then
				key = configKey
			else
				-- ROBLOX FIXME Luau: narrowing bug: Type 'string' could not be converted into 'number'
				key = tostring(configKey :: any)
			end
		end
		-- ROBLOX deviation END

		-- ROBLOX deviation START: seemingly only used for string ref warnings, which we don't support
		-- self = if config.__self == nil then nil else config.__self
		-- ROBLOX deviation END

		source = if ((config :: any) :: React_ElementProps<T>).__source == nil
			then nil
			else ((config :: any) :: React_ElementProps<T>).__source

		-- Remaining properties are added to a new props object
		-- ROBLOX deviation START: extreme hot path, so manually unroll RESERVED_PROPS loop and use table.clone
		if props.key ~= nil then
			props.key = nil
		end
		if props.ref ~= nil then
			props.ref = nil
		end
		if props.__self ~= nil then
			props.__self = nil
		end
		if props.__source ~= nil then
			props.__source = nil
		end
		-- ROBLOX deviation END
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	-- ROBLOX deviation START: we have a shortcut for capturing varargs into an array in Lua, which is more performant
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	elseif childrenLength > 1 then
		-- ROBLOX TODO: there's a snapshot difference in storeOwners where key is 2 instead of 1 if we do `{...}`. does it matter?
		-- local childArray = {...}
		local childArray = table.create(childrenLength)
		for i = 1, childrenLength do
			local toInsert = select(i, ...)
			table.insert(childArray, toInsert)
		end

		-- ROBLOX deviation END

		if __DEV__ then
			table.freeze(childArray)
		end

		props.children = childArray
	end

	-- Resolve default props
	-- ROBLOX deviation START: Lua can't index defaultProps on a function
	-- ROBLOX FIXME Luau: should know this can be a table due to type_ intersection with React_ComponentType<>. needs normalization?
	if
		type(type_ :: any) == "table"
		and (type_ :: T & React_ComponentType<P>).defaultProps
	then
		-- ROBLOX deviation END
		-- ROBLOX FIXME Luau: defaultProps isn't narrowed by the guard above
		local defaultProps = (type_ :: T & React_ComponentType<P>).defaultProps :: P

		-- ROBLOX Luau TODO: defaultProps isn't known to be a table, since Luau doesn't allow us to do `<P extends {}>` yet
		for propName, _ in (defaultProps :: any) :: Object do
			if props[propName] == nil then
				props[propName] = ((defaultProps :: any) :: Object)[propName]
			end
		end
	end

	if __DEV__ then
		if key or ref then
			-- ROBLOX deviation START: Lua can't store fields like displayName on functions
			local displayName

			if type(type_) == "function" then
				-- displayName = (type_.displayName or type_.name) or "Unknown"
				displayName = debug.info(type_, "n") or "<function>"
			elseif type(type_) == "table" then
				displayName = (
					(type_ :: T & React_ComponentType<P>).displayName
					or (type_ :: T & React_ComponentType<P>).name
				) or "Unknown"
			else
				-- ROBLOX Luau FIXME: Luau should have narrowed type_ to string based on this above branches
				displayName = type_ :: string
			end
			-- ROBLOX deviation END

			if key then
				defineKeyPropWarningGetter(props, displayName)
			end

			if ref then
				defineRefPropWarningGetter(props, displayName)
			end
		end

		-- ROBLOX deviation START: In upstream, JSX transformation is what
		-- produces the `__source` field, so we'll just simulate it here for now
		if source == nil then
			-- go up one more because of ReactElementValidator indirection
			source = {
				fileName = debug.info(3, "s"),
				lineNumber = debug.info(3, "l"),
			}
		end
		-- ROBLOX deviation END
	end

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return ReactElement(
		type_,
		key,
		ref,
		self,
		source,
		ReactCurrentOwner.current,
		props
	) :: any
end
exports.createElement = createElement

----[[*
-- * Return a function that produces ReactElements of a given type.
-- * See https://reactjs.org/docs/react-api.html#createfactory
-- ]]
--
--export function createFactory(type)
--  local factory = createElement.bind(null, type); -- Expose the type on the factory and the prototype so that it can be
--  -- easily accessed on elements. E.g. `<Foo />.type == Foo`.
--  -- This should not be named `constructor` since this may not be the function
--  -- that created the element, and it may not even be a constructor.
--  -- Legacy hook: remove it
--
--  factory.type = type
--  return factory
--end
exports.cloneAndReplaceKey =
	function<P, T>(oldElement: ReactElement<P, T>, newKey: any): ReactElement<P, T>
		local newElement = ReactElement(
			oldElement.type,
			newKey,
			oldElement.ref,
			oldElement._self,
			oldElement._source,
			oldElement._owner,
			oldElement.props
		)
		return newElement
	end

--[[*
* Clone and return a new ReactElement using element as the starting point.
* See https://reactjs.org/docs/react-api.html#cloneelement
]]

exports.cloneElement = function<P, T>(
	element: ReactElement<P, T>,
	config: (P & React_ElementProps<T>)?,
	...: React_Node
): ReactElement<P, T>
	-- ROBLOX deviation START: use if instead of variant to avoid error message formatting even when there's no problem
	if element == nil then
		error(
			Error.new(
				"React.cloneElement(...): The argument must be a React element, but you passed "
					.. tostring(element)
			)
		)
	end

	-- Original props are copied
	local elementProps = element.props
	local props: P & React_ElementProps<T> = if elementProps ~= nil
		then table.clone(elementProps :: P & React_ElementProps<T>) :: any
		else {} :: P & React_ElementProps<T>

	-- Reserved names are extracted
	local key = element.key
	local ref = element.ref

	-- Self is preserved since the owner is preserved.
	-- ROBLOX deviation: _self field only used for string ref checking
	-- local self = element._self

	-- Source is preserved since cloneElement is unlikely to be targeted by a
	-- transpiler, and the original source is probably a better indicator of the
	-- true owner.
	local source = element._source

	-- Owner will be preserved, unless ref is overridden
	local owner = element._owner

	if config ~= nil then
		-- ROBLOX deviation START: inline hasValidRef and hasValidKey success in hot path, still call in error case for warning
		local configRef = config.ref
		if configRef ~= nil then
			-- Silently steal the ref from the parent.
			ref = configRef
			owner = ReactCurrentOwner.current
		else
			hasValidRef(config)
		end

		local configKey = config.key
		-- ROBLOX FIXME Luau: needs normalization, generic subtype escaping scope
		if configKey ~= nil then
			if type(configKey) == "number" then
				key = configKey
			else
				-- ROBLOX FIXME Luau: narrowing bug: Type 'string' could not be converted into 'number'
				key = configKey :: any or "nil"
			end
		else
			hasValidKey((config :: any) :: React_ElementProps<T>)
		end
		-- ROBLOX deviation END
	end

	-- Remaining properties override existing props
	local elementType = element.type
	local defaultProps: P? = if type(elementType) == "table"
		then elementType.defaultProps
		else nil

	-- ROBLOX deviation: cannot call pairs on nil the way you can use `for...in`
	-- on nil in JS, so we check for nil before iterating
	if config ~= nil then
		for propName, _ in config :: any do
			if (config :: any)[propName] ~= nil and not RESERVED_PROPS[propName] then
				if (config :: any)[propName] == nil and defaultProps ~= nil then
					-- Resolve default props
					-- ROBLOX FIXME Luau: force-cast required to avoid TypeError: Expected type table, got 'P' instead
					(props :: any)[propName] = (defaultProps :: any)[propName]
				else
					(props :: any)[propName] = (config :: any)[propName]
				end
			end
		end
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	-- ROBLOX deviation START: we have a shortcut for capturing varargs into an array in Lua, which is more performant
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	elseif childrenLength > 1 then
		(props :: any).children = { ... }
	end
	-- ROBLOX deviation END

	-- ROBLOX FIXME Luau: this cast is needed until normalization lands
	return ReactElement(
		element.type,
		key,
		ref,
		nil,
		source,
		owner,
		(props :: any) :: P & React_ElementProps<T>
	) :: any
end
--[[*
 * Verifies the object is a ReactElement.
 * See https://reactjs.org/docs/react-api.html#isvalidelement
 * @param ?object} object
 * @return boolean} True if `object` is a ReactElement.
 * @final
 ]]

exports.isValidElement = function(object)
	return type(object) == "table" and object["$$typeof"] == REACT_ELEMENT_TYPE
end

return exports
